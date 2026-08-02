#!/usr/bin/env python3
"""Reduce banned-language grep hits to the ones a USER could actually read.

TWO JOBS, ONE FILE
------------------
1. FORBIDDING CONTEXT (since v7.x) — a hit inside a "NOT This" / "Banned" / "Avoid"
   table column, or inside a forbidding blockquote, is the document TEACHING the ban,
   not violating it.
2. USER-VISIBLE STRINGS (v10, `--strings-only`) — a hit outside a string literal,
   a locale VALUE, or a markup text node is not copy at all. It is an identifier, an
   import specifier, a comment or a type name.

WHY (2) HAD TO EXIST BEFORE THE any-depth SCOPE DEFAULT COULD FLIP
------------------------------------------------------------------
banned-language-lint.sh scans §7 terms `-i -w -F` against WHOLE FILES. Speck's own
shipped product-contract-template.md §7 carries

    - ❌ Technical architecture language ("our backend", "API", "database")

and the phrase-class extractor pulls each quoted phrase. So the moment the resolver
reached a monorepo's `frontend/src/**`, this ordinary line

    import { createClient } from "./api";

produced `❌ "API" — 4 hit(s)` and turned a green repo red on code nobody wrote that
week. That single false-conviction class is why v9.6 had to ship `any-depth` opt-in.
Filtering to user-visible text is the precondition for the flip, not a nicety.

WHAT THIS IS AND IS NOT
-----------------------
It is a LEXER, not a parser. It classifies every byte of a file as visible or not by
scanning for comments, string literals, module specifiers and markup text. It knows
nothing about scope, types, or macros.

Where it cannot lex a file it says so — `--parse-report` prints a per-file status and
the lint publishes the count as `SPECK_GATE_UNPARSED`. An unlexable file is scanned
WHOLE (the pre-v10 behaviour, so the flip can never create a new blind spot), and the
telemetry names how many files that was. Silently scanning it whole, or silently
skipping it, are the two things this codebase exists to stop.

KNOWN LIMITS, stated rather than hidden:
  * Python/Ruby triple-quoted blocks are treated as DOCUMENTATION, not user copy.
    User-facing prose held in a docstring is missed.
  * Heredocs (`<<~EOS`, PHP `<<<EOT`) are not recognised; their body reads as code.
  * A `'` in C-family code that does not close on its own line is read as an
    apostrophe, not a string opener — that is what makes `<p>It's here</p>` work
    inside .tsx, and it means a genuine multi-line `'` string is missed.
  * JSX/HTML text nodes are recovered by a conservative `>`…`<` rule; a text run
    holding `; { } = ( )` is rejected rather than risk re-convicting code.
"""

import os
import re
import sys

# ─────────────────────────────────────────────────────────────────────────────
# Job 1 — forbidding context (unchanged behaviour)
# ─────────────────────────────────────────────────────────────────────────────

FORBIDDING_HEADER = re.compile(
    r"not\s+this|banned|avoid|negative|what we explicitly do not|❌",
    re.I,
)
FORBIDDING_BLOCKQUOTE = re.compile(
    r"\b(not this|banned|avoid|do not|we are not)\b",
    re.I,
)


def split_cells(row: str) -> list:
    row = row.strip()
    if row.startswith("|"):
        row = row[1:]
    if row.endswith("|"):
        row = row[:-1]
    return [c.strip() for c in row.split("|")]


def table_forbidding_columns(lines: list, idx: int) -> set:
    start = idx
    while start > 0 and "|" in lines[start - 1]:
        start -= 1
    header_idx = None
    for i in range(start, idx + 1):
        line = lines[i].strip()
        if "|" not in line:
            continue
        if re.match(r"^\|[\s\-:|]+\|$", line):
            continue
        header_idx = i
        break
    if header_idx is None:
        return set()
    headers = split_cells(lines[header_idx])
    return {i for i, h in enumerate(headers) if FORBIDDING_HEADER.search(h)}


def should_skip(file_path: str, line_no: int, term_lc: str) -> bool:
    lines = read_lines(file_path)
    if lines is None:
        return False
    idx = line_no - 1
    if idx < 0 or idx >= len(lines):
        return False
    line = lines[idx]

    stripped = line.lstrip()
    if stripped.startswith(">"):
        if FORBIDDING_BLOCKQUOTE.search(stripped):
            return True

    if "|" in line and term_lc in line.lower():
        forbidding_cols = table_forbidding_columns(lines, idx)
        if forbidding_cols:
            cells = split_cells(line)
            hit_cols = [i for i, c in enumerate(cells) if term_lc in c.lower()]
            if hit_cols and all(i in forbidding_cols for i in hit_cols):
                return True
    return False


# ─────────────────────────────────────────────────────────────────────────────
# Job 2 — the visibility mask
#
# For each file we build a MASK: a character-for-character copy in which every byte
# a user cannot read has been replaced with a space, and newlines are preserved. A
# hit on line N is then a real hit only if the term still matches in mask line N.
# Positions are preserved, so nothing has to be tracked across the two passes.
# ─────────────────────────────────────────────────────────────────────────────

PROSE_EXT = {".md", ".markdown", ".mdx", ".txt", ".text", ".rst", ".adoc", ".asciidoc"}
JSONISH_EXT = {".json", ".arb", ".jsonc", ".json5", ".webmanifest"}
YAML_EXT = {".yaml", ".yml"}
PO_EXT = {".po", ".pot"}
KEYVAL_EXT = {".strings", ".properties", ".toml", ".ini", ".cfg", ".conf", ".env"}

MARKUP_EXT = {
    ".html", ".htm", ".xhtml", ".vue", ".svelte", ".astro", ".erb", ".ejs",
    ".hbs", ".handlebars", ".njk", ".twig", ".jinja", ".jinja2", ".j2",
    ".templ", ".liquid", ".blade", ".xml", ".svg", ".resx",
    # PHP is markup FIRST — everything outside <?php … ?> is emitted verbatim to the
    # browser. Lexing it as pure source made `<p>Welcome</p>` invisible, which is the
    # opposite of the truth: it is the most user-visible line in the file.
    ".php", ".php4", ".phtml",
}

C_LIKE_EXT = {
    ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".mts", ".cts",
    ".java", ".kt", ".kts", ".swift", ".dart", ".go", ".rs", ".cs", ".scala",
    ".c", ".h", ".cpp", ".hpp", ".cc", ".hh", ".m", ".mm",
    ".groovy", ".gradle", ".css", ".scss", ".sass", ".less",
}
HASH_LIKE_EXT = {
    ".py", ".pyi", ".rb", ".rake", ".sh", ".bash", ".zsh", ".fish",
    ".pl", ".pm", ".ex", ".exs", ".r", ".jl", ".nim", ".cr", ".tf",
}
SOURCE_EXT = C_LIKE_EXT | HASH_LIKE_EXT

# JS-family: needs regex-literal skipping, because `/[^']/` otherwise opens a string.
JS_EXT = {".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs", ".mts", ".cts"}
# Files whose CODE regions may legitimately hold JSX/HTML text nodes.
JSX_EXT = {".js", ".jsx", ".tsx", ".mjs"}

# Attributes whose value is rendered to a human. Everything else in a tag (href, src,
# class, id, data-*) is machinery.
VISIBLE_ATTRS = {
    "alt", "title", "placeholder", "label", "aria-label", "aria-description",
    "aria-placeholder", "aria-roledescription", "content", "summary", "value",
    "tooltip", "data-tooltip", "caption", "legend",
}

# A string with no whitespace that carries a path/scope separator is a module path, a
# URL, a route, a CSS selector or a handle — never a sentence. `"revolutionize"` has
# neither and stays visible; `"./api"` and `"/api/users"` do not.
_TECHNICAL_TOKEN = re.compile(r"[/@#]")

_SPECIFIER_WORDS = {
    "from", "import", "require", "include", "require_once", "include_once",
    "use", "importscripts", "mock", "url", "@import", "sourcefrom",
}

_REGEX_PREV_CHARS = set("([{,;:=!&|?+-*%~^<>")
_REGEX_PREV_WORDS = {
    "return", "typeof", "case", "in", "of", "do", "else", "yield", "await",
    "delete", "void", "instanceof", "new",
}

# Status vocabulary. `prose` and the three parsed classes are HONEST scans; `unparsed`
# and `degraded` both mean "scanned whole, and we are telling you".
STATUS_WHOLE_FILE = {"prose", "unparsed", "degraded"}


def read_text(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except OSError:
        return None


_LINES_CACHE = {}


def read_lines(path):
    if path not in _LINES_CACHE:
        text = read_text(path)
        _LINES_CACHE[path] = None if text is None else text.splitlines(keepends=True)
    return _LINES_CACHE[path]


def _blank_mask(text):
    return ["\n" if ch == "\n" else " " for ch in text]


def _reveal(mask, text, i, j):
    j = min(j, len(text))
    if j > i:
        mask[i:j] = list(text[i:j])


def _line_end(text, i):
    j = text.find("\n", i)
    return len(text) if j < 0 else j


def _is_technical_token(body):
    t = body.strip()
    if not t or re.search(r"\s", t):
        return False
    return t.startswith(".") or bool(_TECHNICAL_TOKEN.search(t))


def _is_module_specifier(text, i):
    """True when the string opening at `i` sits in a module-specifier position.

    This is the rule that makes `import { createClient } from "./api"` invisible —
    the single false conviction that held the any-depth default back through v9.6.
    """
    p = text[max(0, i - 80):i].rstrip()
    while p.endswith("("):
        p = p[:-1].rstrip()
    m = re.search(r"([A-Za-z_@.$]+)$", p)
    if not m:
        return False
    word = m.group(1).split(".")[-1].lower()
    return word in _SPECIFIER_WORDS


def _skip_interpolation(text, i, n, opener):
    """Skip `${...}` / `#{...}`, brace-nesting aware. Returns the index after it."""
    j = i + len(opener)
    depth = 1
    while j < n and depth:
        c = text[j]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        j += 1
    return j


def _consume_string(text, i, n, mask, allow_multiline):
    """Lex the string opening at `i`. Returns (next_index, ok, revealed_body_or_None).

    ok=False means the opener is NOT a string on this line: the caller decides whether
    that is an apostrophe (fine) or a lexer miss (degrade the file).
    """
    quote = text[i]
    body_start = i + 1
    j = body_start
    interp_opener = "${" if quote == "`" else None
    line_limit = n if allow_multiline else _line_end(text, i)
    spans = []
    span_start = body_start
    while j < line_limit:
        c = text[j]
        if c == "\\":
            j += 2
            continue
        if c == quote:
            spans.append((span_start, j))
            return j + 1, True, spans
        if interp_opener and text.startswith(interp_opener, j):
            spans.append((span_start, j))
            j = _skip_interpolation(text, j, line_limit, interp_opener)
            span_start = j
            continue
        j += 1
    return i, False, None


def _consume_regex(text, i, n):
    """Lex a JS regex literal at `i`. Returns the index after it, or -1 if it is division."""
    j = i + 1
    in_class = False
    limit = _line_end(text, i)
    while j < limit:
        c = text[j]
        if c == "\\":
            j += 2
            continue
        if c == "[":
            in_class = True
        elif c == "]":
            in_class = False
        elif c == "/" and not in_class:
            j += 1
            while j < limit and text[j].isalpha():
                j += 1
            return j
        j += 1
    return -1


def _regex_starts_here(text, i):
    k = i - 1
    while k >= 0 and text[k] in " \t\r\n":
        k -= 1
    if k < 0:
        return True
    if text[k] in _REGEX_PREV_CHARS:
        return True
    m = re.search(r"([A-Za-z_$]+)$", text[max(0, k - 14):k + 1])
    return bool(m and m.group(1) in _REGEX_PREV_WORDS)


def lex_source(text, ext, mask, start=0, end=None, force_c_like=False):
    """Reveal user-visible string literals in text[start:end]. Returns True if clean."""
    if end is None:
        end = len(text)
    c_like = force_c_like or ext in C_LIKE_EXT or ext in MARKUP_EXT
    hash_like = ext in HASH_LIKE_EXT
    js_like = ext in JS_EXT or force_c_like
    clean = True
    i = start
    while i < end:
        c = text[i]

        if c_like and text.startswith("//", i):
            i = _line_end(text, i)
            continue
        if c_like and text.startswith("/*", i):
            j = text.find("*/", i + 2)
            if j < 0 or j >= end:
                return False
            i = j + 2
            continue
        if hash_like and c == "#":
            i = _line_end(text, i)
            continue
        if hash_like and (text.startswith('"""', i) or text.startswith("'''", i)):
            # Documentation, not user copy. Stated as a known limit in the header.
            q = text[i:i + 3]
            j = text.find(q, i + 3)
            if j < 0 or j >= end:
                return False
            i = j + 3
            continue
        if js_like and c == "/" and _regex_starts_here(text, i):
            j = _consume_regex(text, i, end)
            if j > 0:
                i = j
                continue

        if c in ('"', "'") or (c == "`" and c_like):
            # A ' or " that does not close on its own line is not a string in any
            # C-family or hash-family language. Backticks and Go raw strings may span.
            allow_multiline = c == "`"
            nxt, ok, spans = _consume_string(text, i, end, mask, allow_multiline)
            if not ok:
                if c == '"':
                    # An unterminated double quote means we mis-lexed something (a
                    # heredoc, a macro, a language we do not model). Say so.
                    clean = False
                i += 1
                continue
            body = "".join(text[a:b] for a, b in spans)
            if not _is_module_specifier(text, i) and not _is_technical_token(body):
                for a, b in spans:
                    _reveal(mask, text, a, b)
            i = nxt
            continue

        i += 1
    return clean


# ── JSX / markup text nodes ──────────────────────────────────────────────────

_TAGGISH = re.compile(r"^<[A-Za-z/>]")
_TEXT_REJECT = re.compile(r"[;{}=()]")


def reveal_jsx_text(text, mask, start=0, end=None):
    """Conservatively reveal `>`…`<` text runs inside CODE regions.

    Deliberately high-precision: a run holding `; { } = ( )` is rejected rather than
    risk re-convicting `if (a > b) { … }`. The opening `>` must also close a tag-like
    `<…>` span, or a bare `a > b < c` comparison would qualify.
    """
    if end is None:
        end = len(text)
    i = start
    while i < end:
        gt = text.find(">", i)
        if gt < 0 or gt >= end:
            return
        lt = text.find("<", gt + 1)
        if lt < 0 or lt > end:
            return
        run = text[gt + 1:lt]
        if _closes_a_tag(text, gt, start) and run.strip() and not _TEXT_REJECT.search(run):
            _reveal(mask, text, gt + 1, lt)
        i = gt + 1


def _closes_a_tag(text, gt, floor):
    k = gt - 1
    while k >= floor:
        c = text[k]
        if c == ">" or c == "\n" and text[k - 1:k] == "\n":
            return False
        if c == "<":
            return bool(_TAGGISH.match(text[k:k + 2]))
        k -= 1
    return False


_ATTR_RE = re.compile(r"([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(\"[^\"]*\"|'[^']*')")


def lex_markup(text, ext, mask):
    """Text nodes + human-readable attributes; script/style bodies lexed as source."""
    n = len(text)
    clean = True

    # Astro frontmatter: a leading `---` fence holding real JS.
    body_start = 0
    if ext == ".astro" and text.startswith("---"):
        close = text.find("\n---", 3)
        if close > 0:
            clean = lex_source(text, ".ts", mask, 3, close, force_c_like=True) and clean
            body_start = close + 4

    i = body_start
    while i < n:
        if text.startswith("<!--", i):
            j = text.find("-->", i + 4)
            i = n if j < 0 else j + 3
            continue
        if text.startswith("<?", i):
            # A processing-instruction / PHP block: code inside markup. Lex it as source so
            # its string literals still count, and so `?>` is not mistaken for a tag close.
            j = text.find("?>", i + 2)
            clean = lex_source(text, ".php", mask, i + 2, n if j < 0 else j, force_c_like=True) and clean
            i = n if j < 0 else j + 2
            continue
        if text[i] == "<":
            m = re.match(r"<\s*(script|style)\b", text[i:i + 10], re.I)
            if m:
                kind = m.group(1).lower()
                open_end = text.find(">", i)
                close = re.search(r"</\s*%s\s*>" % kind, text[open_end + 1:], re.I) if open_end > 0 else None
                if open_end < 0 or close is None:
                    i = n
                    continue
                b0 = open_end + 1
                b1 = b0 + close.start()
                if kind == "script":
                    clean = lex_source(text, ".ts", mask, b0, b1, force_c_like=True) and clean
                i = b0 + close.end()
                continue
            gt = text.find(">", i)
            if gt < 0:
                clean = False
                break
            for am in _ATTR_RE.finditer(text, i, gt):
                if am.group(1).lower() in VISIBLE_ATTRS:
                    v0 = am.start(2) + 1
                    v1 = am.end(2) - 1
                    if not _is_technical_token(text[v0:v1]):
                        _reveal(mask, text, v0, v1)
            i = gt + 1
            continue
        lt = text.find("<", i)
        if lt < 0:
            lt = n
        _reveal(mask, text, i, lt)
        i = lt

    # Interpolation inside a text node is code: {count}, {{ user.name }}.
    for m in re.finditer(r"\{\{?[^{}]*\}?\}", "".join(mask)):
        for k in range(m.start(), m.end()):
            if mask[k] != "\n":
                mask[k] = " "
    return clean


# ── locale / key-value formats ───────────────────────────────────────────────


def lex_jsonish(text, mask):
    """String VALUES only. A string followed by `:` is a key and stays invisible."""
    n = len(text)
    i = 0
    clean = True
    while i < n:
        c = text[i]
        if c != '"':
            i += 1
            continue
        j = i + 1
        while j < n:
            if text[j] == "\\":
                j += 2
                continue
            if text[j] == '"':
                break
            j += 1
        if j >= n:
            clean = False
            break
        k = j + 1
        while k < n and text[k] in " \t\r\n":
            k += 1
        is_key = k < n and text[k] == ":"
        if not is_key and not _is_technical_token(text[i + 1:j]):
            _reveal(mask, text, i + 1, j)
        i = j + 1
    return clean


def lex_yaml(text, mask):
    off = 0
    for line in text.splitlines(keepends=True):
        stripped = line.rstrip("\n")
        cut = _yaml_comment_start(stripped)
        body = stripped[:cut]
        rel = _yaml_value_offset(body)
        if rel is not None and rel < len(body):
            _reveal(mask, text, off + rel, off + len(body))
        off += len(line)
    return True


def _yaml_comment_start(line):
    inq = None
    for idx, ch in enumerate(line):
        if inq:
            if ch == inq:
                inq = None
            continue
        if ch in "\"'":
            inq = ch
        elif ch == "#" and (idx == 0 or line[idx - 1] in " \t"):
            return idx
    return len(line)


def _yaml_value_offset(body):
    """Index at which the VALUE starts, or None when the line carries none."""
    inq = None
    for idx, ch in enumerate(body):
        if inq:
            if ch == inq:
                inq = None
            continue
        if ch in "\"'":
            inq = ch
        elif ch == ":" and (idx + 1 >= len(body) or body[idx + 1] in " \t"):
            return idx + 1
    stripped = body.lstrip()
    if stripped.startswith("- "):
        return len(body) - len(stripped) + 2
    # No key and no list marker: a block-scalar continuation line, i.e. a value.
    return 0 if stripped else None


def lex_keyval(text, mask):
    """`key = value`, `"key" = "value";`, `key: value` — the RHS only."""
    off = 0
    for line in text.splitlines(keepends=True):
        body = line.rstrip("\n")
        s = body.lstrip()
        if s.startswith("#") or s.startswith(";") or s.startswith("//"):
            off += len(line)
            continue
        eq = body.find("=")
        if eq < 0:
            eq = body.find(":")
        if eq >= 0:
            _reveal(mask, text, off + eq + 1, off + len(body))
        off += len(line)
    return True


_PO_RE = re.compile(r'^\s*(?:msgid|msgstr|msgid_plural|msgctxt)?(?:\[\d+\])?\s*(".*")\s*$')


def lex_po(text, mask):
    off = 0
    for line in text.splitlines(keepends=True):
        body = line.rstrip("\n")
        if not body.lstrip().startswith("#"):
            m = _PO_RE.match(body)
            if m:
                _reveal(mask, text, off + m.start(1) + 1, off + m.end(1) - 1)
        off += len(line)
    return True


# ── the classifier ───────────────────────────────────────────────────────────


def classify(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in PROSE_EXT:
        return "prose", ext
    if ext in JSONISH_EXT or ext in YAML_EXT or ext in PO_EXT or ext in KEYVAL_EXT:
        return "i18n", ext
    if ext in MARKUP_EXT:
        return "markup", ext
    if ext in SOURCE_EXT:
        return "strings", ext
    return "unparsed", ext


_MASK_CACHE = {}


def masked_lines(path):
    """(status, lines). status in STATUS_WHOLE_FILE means the caller must scan whole."""
    if path in _MASK_CACHE:
        return _MASK_CACHE[path]
    result = _build_mask(path)
    _MASK_CACHE[path] = result
    return result


def _build_mask(path):
    text = read_text(path)
    if text is None:
        return "unreadable", []
    status, ext = classify(path)
    if status in ("prose", "unparsed"):
        return status, text.splitlines()
    mask = _blank_mask(text)
    try:
        if status == "i18n":
            if ext in JSONISH_EXT:
                clean = lex_jsonish(text, mask)
            elif ext in YAML_EXT:
                clean = lex_yaml(text, mask)
            elif ext in PO_EXT:
                clean = lex_po(text, mask)
            else:
                clean = lex_keyval(text, mask)
        elif status == "markup":
            clean = lex_markup(text, ext, mask)
        else:
            clean = lex_source(text, ext, mask)
            if ext in JSX_EXT:
                reveal_jsx_text(text, mask)
    except Exception:
        # A crash here must degrade ONE file, never fail the gate: the lint would then
        # exit 2 in CI on an input nobody can see. Degraded means "scanned whole, and
        # counted in SPECK_GATE_UNPARSED".
        return "degraded", text.splitlines()
    if not clean:
        return "degraded", text.splitlines()
    return status, "".join(mask).splitlines()


def word_pattern(term):
    """grep -i -w -F, in Python. Word chars are [A-Za-z0-9_], as in grep."""
    if not term:
        return None
    pat = re.escape(term)
    if re.match(r"\w", term[0]):
        pat = r"(?<!\w)" + pat
    if re.search(r"\w$", term):
        pat = pat + r"(?!\w)"
    return re.compile(pat, re.I)


def hit_is_visible(path, line_no, pattern):
    status, lines = masked_lines(path)
    if status in STATUS_WHOLE_FILE:
        return True
    if status == "unreadable":
        return True
    idx = line_no - 1
    if idx < 0 or idx >= len(lines):
        return True
    return bool(pattern.search(lines[idx]))


# ─────────────────────────────────────────────────────────────────────────────


def parse_report(paths):
    for p in paths:
        status, _ = masked_lines(p)
        print("%s\t%s" % (status, p))
    return 0


def main() -> int:
    args = sys.argv[1:]
    strings_only = False
    report = False
    rest = []
    for a in args:
        if a == "--strings-only":
            strings_only = True
        elif a == "--parse-report":
            report = True
        else:
            rest.append(a)

    if report:
        paths = [ln.strip() for ln in sys.stdin.read().splitlines() if ln.strip()]
        return parse_report(paths)

    if not rest:
        return 0
    term = rest[0]
    term_lc = term.lower()
    pattern = word_pattern(term) if strings_only else None
    raw = sys.stdin.read().strip()
    if not raw:
        return 0

    for entry in raw.splitlines():
        if not entry.strip():
            continue
        m = re.match(r"^(.+?):(\d+):(.*)$", entry)
        if not m:
            print(entry)
            continue
        path, line_no = m.group(1), int(m.group(2))
        if should_skip(path, line_no, term_lc):
            continue
        if pattern is not None and not hit_is_visible(path, line_no, pattern):
            continue
        print(entry)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
