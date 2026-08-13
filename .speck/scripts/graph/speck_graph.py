#!/usr/bin/env python3
"""speck_graph.py — the Speck Witness Graph (design: docs/graph/witness-graph-design.md).

A DERIVED, tamper-evident graph of everything Speck traces. It is compiled from the authored
markdown (and, in later phases, test/coverage data); it is regenerated, never hand-edited, and
content-hashed so its own freshness is COMPUTED, never asserted. Markdown stays the single source
of truth — this file is a compile artifact, like a binary.

Design invariants (see docs/graph/witness-graph-design.md §6):
  1. Derived + disposable. No one edits witness.json. Dirty-vs-HEAD → gates fail.
  2. The arc RETIRES bespoke parsers; it does not add a parallel truth.
  3. STRUCTURAL edges only. Fidelity / taste / completeness stay with /speck-audit + the canaries.
     This module can prove `traceable · complete · fresh`. It CANNOT prove `faithful · good`.
  4. Caps, never raises: GRAPH_CAP is a ceiling on claimable readiness, never a grant.

Phase 1 subcommands: `build` (emit the graph) and `lint-refs` (the dangling-reference gate).
Later phases add `check` (orphan/phantom/unjudged gates), `query`, and `context`.

Portable: Python 3.8+, standard library only (Speck ships static files and runs zero daemons).
"""

import hashlib
import json
import os
import re
import subprocess
import sys

SCHEMA_VERSION = "1.0"

# ---------------------------------------------------------------------------
# Identity model (docs/graph/witness-graph-design.md §5)
#
# The canonical EPIC id is the epic directory basename as it exists on disk — e.g.
# `004-ai-core-workout-gen` (field reality; NOT a fictional `E004`). Cross-references may be
# written three ways, all resolved by MEMBERSHIP against the epics actually present:
#   • bare, within the owning epic:      S038, AC-2, PRM-016
#   • ordinal shorthand, cross-epic:     004/S038         (humans write this in prose)
#   • full dir, cross-epic:              004-ai-core-workout-gen/S038
# Canonical (qualified) node ids the graph stores:
#   epic          004-ai-core-workout-gen               (project-global)
#   story         004-ai-core-workout-gen/S038          bare S038 within its own epic
#   ac            004-ai-core-workout-gen/S038/AC-2      bare AC-2 within its own story
#   prm           004-ai-core-workout-gen/PRM-016        bare PRM-016 within its own epic
#   magic-moment  MM-3     job JOB-2     dec DEC-0207    requirement FR-...-014 / NFR-003
#   differentiator DIF-1   (§3 pillars, #108 — §3a anti-differentiators are constraints, never nodes)
# ---------------------------------------------------------------------------

RE_STORY_BARE = re.compile(r"^S\d{2,}$")
RE_AC_BARE = re.compile(r"^AC-\d+[a-z]?$")            # sub-lettered ACs (AC-1a) are real
RE_PRM_BARE = re.compile(r"^PRM-\d+$")
RE_MM = re.compile(r"^MM-\d+[a-z]?$")           # sub-lettered MMs (MM-5a) are real, like AC-1a
RE_JOB = re.compile(r"^JOB-\d+$")
RE_DEC = re.compile(r"^DEC-\d+$")
RE_DIF = re.compile(r"^DIF-\d+[a-z]?$")   # §3 differentiator pillars (#108)
RE_FR = re.compile(r"^FR-[A-Za-z0-9-]+-\d+$")         # tolerate hyphenated middles (FR-auth-svc-014)
RE_NFR = re.compile(r"^NFR-\d+$")
RE_EPIC_ORDINAL = re.compile(r"^(\d{2,}|E\d{2,})")  # leading ordinal token of an epic basename

# One story reference, optionally epic-qualified (ordinal or full dir) and/or AC-suffixed:
#   S012 · 004/S012 · 004-beta/S012 · S012/AC-1 · 004/S012/AC-1a
RE_STORY_REF = re.compile(
    r"(?:(?P<epic>[A-Za-z0-9][A-Za-z0-9-]*)/)?(?P<story>S\d{2,})(?:\s*/\s*(?P<ac>AC-\d+[a-z]?))?")


def content_lines(text, skip_frontmatter=False):
    """Yield (file_lineno, line) for every CONTENT line — fenced code and HTML comments dropped.

    The line number is 1-based IN THE FILE, which is the whole point: a finding that says
    "this id is mentioned but claims nothing" is only actionable if it can hand a human a
    `path:line` to open. Carrying the number here (rather than re-deriving it from a stripped
    string later) is what keeps the hint honest across fences, comments and frontmatter.
    """
    out = []
    in_fence = False
    in_comment = False
    in_fm = False
    lines = text.splitlines()
    for idx, line in enumerate(lines):
        lineno = idx + 1
        s = line.strip()
        if skip_frontmatter:
            if idx == 0 and s == "---":
                in_fm = True
                continue
            if in_fm:
                if s == "---":
                    in_fm = False
                continue
        if not in_fence and "<!--" in line and "-->" not in line:
            in_comment = True
            continue
        if in_comment:
            if "-->" in line:
                in_comment = False
            continue
        if s.startswith("```") or s.startswith("~~~"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        # single-line <!-- ... --> comment
        out.append((lineno, re.sub(r"<!--.*?-->", "", line)))
    return out


def strip_noncontent(text):
    """Remove fenced code blocks and HTML comments so id scans don't harvest example ids.

    parse_tables already does this for tables; the free-text id scans (MM/JOB/DEC/FR) must too,
    or a `DEC-9999` inside ``` or <!-- --> pollutes kind_counts and flips a ref's P3→P1 tier.
    """
    return "\n".join(line for _lineno, line in content_lines(text))


def story_refs(raw):
    """Yield reconstructed, resolver-ready reference strings from a cell/value.

    Preserves the epic qualifier (ordinal or full dir) and any AC suffix — the single-match
    extraction this replaces silently dropped every target but the first and stripped qualifiers.
    """
    refs = []
    for m in RE_STORY_REF.finditer(raw):
        epic, story, ac = m.group("epic"), m.group("story"), m.group("ac")
        # a leading token that is itself a story id (e.g. the "S001" in "S001/AC-1") is not an epic
        if epic and RE_STORY_BARE.match(epic):
            epic = None
        ref = (epic + "/" if epic else "") + story + ("/" + ac if ac else "")
        refs.append(ref)
    return refs


def build_epic_index(epic_ids):
    """Map every way an epic can be referenced → its canonical id (the dir basename)."""
    ordinals = {}
    for eid in epic_ids:
        m = RE_EPIC_ORDINAL.match(eid)
        if m:
            ordinals.setdefault(m.group(1), eid)
    return {"ids": set(epic_ids), "ordinals": ordinals}


def canonicalize_epic(head, epic_index):
    """Resolve an epic token (full dir, ordinal, or E-number) to its canonical id, or None."""
    if head in epic_index["ids"]:
        return head
    if head in epic_index["ordinals"]:
        return epic_index["ordinals"][head]
    m = re.match(r"^(\d{2,}|E\d{2,})$", head)
    if m and m.group(1) in epic_index["ordinals"]:
        return epic_index["ordinals"][m.group(1)]
    return None


class Node:
    __slots__ = ("id", "kind", "scope", "title", "source_file", "anchor", "content_hash", "attrs")

    def __init__(self, id, kind, scope=None, title="", source_file="", anchor="", content_hash="", attrs=None):
        self.id = id
        self.kind = kind
        self.scope = scope
        self.title = title
        self.source_file = source_file
        self.anchor = anchor
        self.content_hash = content_hash
        self.attrs = attrs or {}

    def to_dict(self):
        return {
            "id": self.id, "kind": self.kind, "scope": self.scope, "title": self.title,
            "source_file": self.source_file, "anchor": self.anchor,
            "content_hash": self.content_hash, "attrs": self.attrs,
        }


class Edge:
    __slots__ = ("src", "kind", "dst_ref", "dst", "source_file", "attrs")

    def __init__(self, src, kind, dst_ref, dst=None, source_file="", attrs=None):
        self.src = src
        self.kind = kind
        self.dst_ref = dst_ref  # raw reference text as authored
        self.dst = dst          # resolved canonical id, or None if unresolvable
        self.source_file = source_file
        self.attrs = attrs or {}

    def to_dict(self):
        return {
            "src": self.src, "kind": self.kind, "dst_ref": self.dst_ref, "dst": self.dst,
            "source_file": self.source_file, "attrs": self.attrs,
        }


# ---------------------------------------------------------------------------
# Markdown parsing primitives — the shared parse layer (retires per-validator regex).
# Tables are parsed BY HEADER NAME, never by column position: inserting a column can no
# longer break extraction (the #83/#85 scar class).
# ---------------------------------------------------------------------------

def read_text(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return fh.read()
    except (OSError, UnicodeDecodeError):
        return ""


def strip_frontmatter(text):
    """Return (frontmatter_dict, body). Frontmatter is a leading '---' fenced block."""
    if not text.startswith("---"):
        return {}, text
    end = text.find("\n---", 3)
    if end == -1:
        return {}, text
    fm_raw = text[3:end].strip("\n")
    body = text[end + 4:]
    fm = {}
    for line in fm_raw.splitlines():
        if ":" in line and not line.lstrip().startswith("#"):
            k, _, v = line.partition(":")
            v = re.sub(r"\s+#.*$", "", v)  # drop inline YAML comments (` # ...`) — they leaked tokens
            fm[k.strip()] = v.strip()
    return fm, body


def _split_row(line):
    """Split a markdown table row into trimmed cells, tolerating leading/trailing and escaped pipes."""
    s = line.strip()
    s = s.replace("\\|", "\x00")  # protect escaped pipes so they don't shift columns
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return [c.strip().replace("\x00", "|") for c in s.split("|")]


def _is_divider(cells):
    return bool(cells) and all(re.fullmatch(r":?-+:?", c.strip()) for c in cells if c.strip() != "")


def parse_tables(text):
    """Parse every GFM table into {headers: [...], rows: [{header: cell}]}.

    Header-keyed so column reordering/insertion is non-breaking. HTML-comment and fenced-code
    regions are skipped so example tables inside <!-- --> or ``` do not pollute extraction.
    """
    tables = []
    lines = text.splitlines()
    in_comment = False
    in_fence = False
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        stripped = line.strip()
        if not in_fence and "<!--" in line and "-->" not in line:
            in_comment = True
        if in_comment:
            if "-->" in line:
                in_comment = False
            i += 1
            continue
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_fence = not in_fence
            i += 1
            continue
        if in_fence:
            i += 1
            continue
        # a table = header row, divider row, then data rows
        if "|" in line and i + 1 < n and "|" in lines[i + 1] and _is_divider(_split_row(lines[i + 1])):
            headers = _split_row(line)
            rows = []
            j = i + 2
            while j < n and "|" in lines[j] and lines[j].strip():
                cells = _split_row(lines[j])
                if _is_divider(cells):
                    j += 1
                    continue
                row = {}
                for idx, h in enumerate(headers):
                    row[h] = cells[idx] if idx < len(cells) else ""
                rows.append(row)
                j += 1
            tables.append({"headers": headers, "rows": rows})
            i = j
            continue
        i += 1
    return tables


def find_header(headers, *needles):
    """Return the actual header string whose lowercased text contains any needle, else None."""
    for h in headers:
        hl = h.lower()
        for needle in needles:
            if needle in hl:
                return h
    return None


def content_hash(text):
    return hashlib.sha256(text.encode("utf-8", "replace")).hexdigest()[:12]


def _norm_status(raw):
    """Normalize a Status cell to its bare enum: '**discharged** (UX-RC)' → 'discharged'."""
    s = re.sub(r"[*`_]", "", raw or "").strip().lower()
    s = s.split("(")[0].strip()          # drop trailing "(UX-RC — …)"
    return s.split()[0] if s.split() else ""


def git_head_sha(root):
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "rev-parse", "--short", "HEAD"],
            stderr=subprocess.DEVNULL,
        )
        return out.decode().strip()
    except (subprocess.CalledProcessError, OSError):
        return ""


# ---------------------------------------------------------------------------
# Reference resolution
# ---------------------------------------------------------------------------

def resolve_ref(raw, epic_scope=None, story_scope=None, epic_index=None):
    """Resolve a raw reference to a canonical id, using the scope it was authored in.

    epic_scope: canonical id of the epic the reference lives in (for bare S###, PRM-###, NFR-###).
    story_scope: canonical id of the story the reference lives in (for bare AC-###).
    epic_index: build_epic_index(...) — lets a cross-epic token (ordinal or full dir) resolve.
    Returns the canonical id string; project-global ids pass through. Returns None for input
    that is not a recognizable id token (prose, not a reference).
    """
    if raw is None:
        return None
    r = raw.strip().strip("`*").strip()
    if not r or r in ("—", "-", "N/A", "n/a", "TBD"):
        return None
    r = r.replace(" ", "")  # tolerate "S012 / AC-3" → "S012/AC-3"

    # cross-epic qualified forms: <epic>/rest where <epic> is an ordinal or full dir
    if "/" in r:
        head, rest = r.split("/", 1)
        epic = canonicalize_epic(head, epic_index) if epic_index else (head if head == epic_scope else None)
        if epic:
            m = re.match(r"^(S\d{2,})/(AC-\d+[a-z]?)$", rest)
            if m:
                return "%s/%s/%s" % (epic, m.group(1), m.group(2))
            return "%s/%s" % (epic, rest)
        # <story>/AC-N inside the current epic (e.g. "S012/AC-3")
        m = re.match(r"^(S\d{2,})/(AC-\d+[a-z]?)$", r)
        if m and epic_scope:
            return "%s/%s/%s" % (epic_scope, m.group(1), m.group(2))
        # looked like an epic-qualified ref but the epic doesn't resolve → a typo, not prose
        if re.match(r"^[A-Za-z0-9][A-Za-z0-9-]*/S\d{2,}", r):
            return "?epic/" + rest  # unresolved-epic sentinel; lint-refs reports it as dangling
        return None

    # project-global ids
    if RE_MM.match(r) or RE_JOB.match(r) or RE_DEC.match(r) or RE_FR.match(r):
        return r
    # bare, scope-local ids
    if RE_STORY_BARE.match(r) or RE_PRM_BARE.match(r):
        return "%s/%s" % (epic_scope, r) if epic_scope else r
    if RE_NFR.match(r):
        return "%s/%s" % (epic_scope, r) if epic_scope else r
    if RE_AC_BARE.match(r):
        return "%s/%s" % (story_scope, r) if story_scope else r
    return None


# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------

def project_id_of(project_dir):
    return os.path.basename(os.path.normpath(project_dir))


RE_MM_HEADING = re.compile(r"^#{2,4}\s+(MM-\d+[a-z]?)\b")
RE_MM_SECTION = re.compile(r"^##\s+\d*\.?\s*.*magic\s+moment", re.IGNORECASE)


def _heterogeneous_mm_headings(text, contract):
    """§5 headings that name a moment the schema still cannot node-ify → founder-visible drops.

    Only reported once the contract HAS adopted the `MM-N` scheme: in a free-text-era contract
    every §5 heading is un-node-ifiable and `GRAPH_UNMIGRATED` already says so. Here the census
    disagrees with the contract's own heading count and NOTHING said so — Streb's read 9/10 against
    a contract declaring 10, which is exactly the silence a witness graph exists to break.
    """
    lines = content_lines(text)
    if not any(RE_MM_HEADING.match(l) for _n, l in lines):
        return []
    out = []
    in_mm_section = False
    for lineno, line in lines:
        if line.startswith("## "):
            in_mm_section = bool(RE_MM_SECTION.match(line))
            continue
        if not in_mm_section:
            continue
        m = re.match(r"^#{3,4}\s+(.+?)\s*$", line)
        if m and not RE_MM_HEADING.match(line):
            out.append({"heading": m.group(1), "source_file": contract, "line": lineno})
    return out


def extract(project_dir):
    """Walk a project's specs tree → (nodes: dict[id]->Node, edges: list[Edge], meta: dict)."""
    nodes = {}
    edges = []
    meta = {"project_id": project_id_of(project_dir), "missing_sources": [],
            "heterogeneous_ids": []}

    def add_node(node):
        # First definition wins; a genuine duplicate id is recorded for the resolver to flag.
        if node.id in nodes:
            nodes[node.id].attrs.setdefault("duplicate_definitions", []).append(node.source_file)
        else:
            nodes[node.id] = node

    # --- product-contract.md → MM-N, JOB-N (project-global) ---
    contract = os.path.join(project_dir, "product-contract.md")
    if os.path.isfile(contract):
        text = strip_noncontent(read_text(contract))
        # MM heading, title optional: "### MM-1 — Name", "### MM-1", "#### MM-2: Name",
        # "### MM-5a — Name". Sub-lettered ids node-ify (scar: Streb renamed a founder-facing
        # promise across 19 files — MM-5a → MM-10 — because this pattern pinned `MM-\d+` while the
        # AC parser five lines away already accepted `AC-1a`. The tool set the product vocabulary.)
        for m in re.finditer(r"^#{2,4}\s+(MM-\d+[a-z]?)\b\s*(?:[—\-:]\s*(.*))?$", text, re.MULTILINE):
            add_node(Node(m.group(1), "magic-moment", None, (m.group(2) or "").strip(),
                          contract, m.group(1), content_hash(m.group(0))))
        # DIF heading — the §3 differentiator pillars (#108). Same grammar as MM-N on purpose:
        # the number is the machine key, sub-letters node-ify, the title is optional.
        #
        # WHY THIS EXISTS. v10.3 made promise coverage a hard gate, but it could only reach MM-N and
        # JOB-N, so it emitted an honest "pillars: not evaluated" line — §3 was one free-prose
        # sentence with no id to compare a coverage matrix against, and a gate over prose would have
        # claimed a verdict it could not compute.
        #
        # ONLY §3 PILLARS, never §3a. An anti-differentiator ("We are NOT a generic workout
        # generator") is a CONSTRAINT, not a promise — no epic "covers" it, and nothing delivers it.
        # Gating it would demand a delivery path for a statement whose whole content is that nothing
        # should be delivered, which is how a coverage gate starts producing findings that can only
        # be closed by deleting the claim.
        #
        # ADOPTION GRADIENT, and it is what makes this safe to land on a minor: no contract on disk
        # carries a `### DIF-N` heading, so this loop emits nothing for every existing project, the
        # node set is unchanged, and `_graph_signature` — which hashes nodes + edges — is therefore
        # byte-identical. No project reads GRAPH_STALE on upgrade day and no witness rebuild is
        # needed. A project becomes subject to pillar coverage the moment it declares its first
        # pillar, and not before. Asserted by a test, not by this comment.
        for m in re.finditer(r"^#{2,4}\s+(DIF-\d+[a-z]?)\b\s*(?:[—\-:]\s*(.*))?$", text, re.MULTILINE):
            add_node(Node(m.group(1), "differentiator", None, (m.group(2) or "").strip(),
                          contract, m.group(1), content_hash(m.group(0))))
        meta["heterogeneous_ids"] = _heterogeneous_mm_headings(read_text(contract), contract)
        for m in re.finditer(r"(JOB-\d+)", text):
            if m.group(1) not in nodes:
                add_node(Node(m.group(1), "job", None, "", contract, m.group(1), content_hash(m.group(1))))
    else:
        meta["missing_sources"].append("product-contract.md")

    # --- project-decisions-log.md → DEC-#### (project-global) ---
    declog = os.path.join(project_dir, "project-decisions-log.md")
    if os.path.isfile(declog):
        text = strip_noncontent(read_text(declog))
        for m in re.finditer(r"(DEC-\d+)", text):
            if m.group(1) not in nodes:
                add_node(Node(m.group(1), "dec", None, "", declog, m.group(1), content_hash(m.group(1))))

    # --- epics/*/ ---
    epics_dir = os.path.join(project_dir, "epics")
    if os.path.isdir(epics_dir):
        for epic_name in sorted(os.listdir(epics_dir)):
            epic_path = os.path.join(epics_dir, epic_name)
            if not os.path.isdir(epic_path):
                continue
            em = re.match(r"^(E\d{2,})", epic_name)
            epic_id = em.group(1) if em else epic_name
            add_node(Node(epic_id, "epic", None, epic_name, epic_path, epic_id, content_hash(epic_name)))
            _extract_epic(epic_path, epic_id, nodes, edges, add_node)

    # resolve every edge's dst now that all epics (and thus the epic index) are known
    epic_index = build_epic_index([n.id for n in nodes.values() if n.kind == "epic"])
    for e in edges:
        if e.dst is None and e.dst_ref:
            e.dst = resolve_ref(e.dst_ref, e.attrs.get("epic_scope"), e.attrs.get("story_scope"), epic_index)

    return nodes, edges, meta


def _extract_epic(epic_path, epic_id, nodes, edges, add_node):
    # conservation applies only once epic-breakdown.md exists (pre-breakdown, open rows are allowed)
    if epic_id in nodes:
        nodes[epic_id].attrs["has_breakdown"] = os.path.isfile(os.path.join(epic_path, "epic-breakdown.md"))
    # epic.md → FR-/NFR- requirement nodes
    epic_md = os.path.join(epic_path, "epic.md")
    if os.path.isfile(epic_md):
        text = strip_noncontent(read_text(epic_md))
        for m in re.finditer(r"(FR-[A-Za-z0-9-]+-\d+|NFR-\d+)", text):
            rid = m.group(1)
            cid = rid if rid.startswith("FR-") else "%s/%s" % (epic_id, rid)
            if cid not in nodes:
                add_node(Node(cid, "requirement", epic_id, "", epic_md, rid, content_hash(rid)))

    # traceability-matrix.md → PRM nodes + sources/discharges/descoped-by edges
    matrix = os.path.join(epic_path, "traceability-matrix.md")
    if os.path.isfile(matrix):
        _extract_matrix(matrix, epic_id, nodes, edges, add_node)

    # stories/*/spec.md → story + AC nodes, MM/JOB/persona/depends-on edges
    stories_dir = os.path.join(epic_path, "stories")
    if os.path.isdir(stories_dir):
        for story_name in sorted(os.listdir(stories_dir)):
            story_path = os.path.join(stories_dir, story_name)
            if not os.path.isdir(story_path):
                continue
            sm = re.match(r"^(S\d{2,})", story_name)
            if not sm:
                continue
            story_qual = "%s/%s" % (epic_id, sm.group(1))
            spec = os.path.join(story_path, "spec.md")
            _extract_story(spec, story_path, epic_id, story_qual, nodes, edges, add_node)


def _cell(row, header):
    """A table cell by header key, trimmed and un-backticked. Absent header → ''.

    An em-dash / en-dash / bare hyphen is the matrix's own "nothing here" glyph, so it reads as
    ABSENT rather than as a value — otherwise `| — |` would satisfy a presence check. A bare `n/a`
    is deliberately NOT stripped here: it flows into _wiring_claim so the author gets the one
    instructive message ("name the kind") from a single classifier, rather than two different
    verdicts for the same intent depending on which artifact carried the cell.
    """
    if not header:
        return ""
    v = (row.get(header, "") or "").strip().strip("`").strip()
    return "" if v in ("", "-", "—", "–") else v


def _extract_matrix(matrix, epic_id, nodes, edges, add_node):
    text = read_text(matrix)
    for table in parse_tables(text):
        headers = table["headers"]
        h_prm = find_header(headers, "prm-id", "prm id", "prm")
        h_src = find_header(headers, "source")
        h_dis = find_header(headers, "discharge")
        h_dec = find_header(headers, "dec")
        h_status = find_header(headers, "status")
        h_grain = find_header(headers, "grain")
        # v10.1 (issue #96 finding 4) — OPTIONAL wiring columns. Header-keyed, so a matrix that
        # predates them parses exactly as before and the gate below degrades to un-adopted.
        h_entry = find_header(headers, "entry point", "entry_point", "entry-point")
        h_witness = find_header(headers, "wiring witness", "wiring_witness", "wiring-witness")
        if not h_prm:
            continue
        for row in table["rows"]:
            raw_prm = row.get(h_prm, "").strip().strip("`")
            pm = re.match(r"^(PRM-\d+)$", raw_prm)
            if not pm:
                continue
            prm_id = "%s/%s" % (epic_id, pm.group(1))
            status = _norm_status(row.get(h_status, "")) if h_status else ""
            grain = (row.get(h_grain, "") or "").strip() if h_grain else ""
            add_node(Node(prm_id, "prm", epic_id, (row.get(h_src, "") or "").strip(),
                          matrix, pm.group(1), content_hash(json.dumps(row, sort_keys=True)),
                          {"status": status, "grain": grain,
                           "entry_point": _cell(row, h_entry),
                           "wiring_witness": _cell(row, h_witness)}))
            # sources edge — the Source cell may name MM-N / JOB-N / FR-... / screen ids
            if h_src:
                # `MM-\d+[a-z]?` here too, or a Source cell naming MM-5a matches the prefix `MM-5`
                # and mints a DANGLING_REF.P1 at a node that never existed.
                for tok in re.findall(r"(MM-\d+[a-z]?|JOB-\d+|FR-[A-Za-z0-9-]+-\d+|NFR-\d+)",
                                      row.get(h_src, "")):
                    edges.append(Edge(prm_id, "sources", tok, source_file=matrix,
                                      attrs={"epic_scope": epic_id}))
            # discharge edges — a cell may list SEVERAL story/AC targets (multi-target discharge)
            if h_dis:
                for tgt in story_refs(row.get(h_dis, "") or ""):
                    edges.append(Edge(prm_id, "discharges", tgt, source_file=matrix,
                                      attrs={"epic_scope": epic_id}))
            # descoped-by edge — a DEC
            if h_dec:
                for tok in re.findall(r"(DEC-\d+)", row.get(h_dec, "")):
                    edges.append(Edge(prm_id, "descoped-by", tok, source_file=matrix,
                                      attrs={"epic_scope": epic_id}))


# ---------------------------------------------------------------------------
# Delivery claims (issue #97) — `serves` derives from a STRUCTURED SLOT, never from prose.
#
# THE SCAR. `serves` used to be `re.findall(r"(MM-\d+|JOB-\d+)", body)` over the whole story spec,
# so naming an id WAS claiming it. In one committed graph 10 of 15 distinct MM serves edges were
# false and 8 came from lines reading "None claimed" or "MM-1 and MM-2 are not claimed here." —
# a disclaimer read as an assertion. Two workarounds had already grown in product artifacts: one
# spec documented the bug inside itself ("its id is deliberately not written out here"), and another
# repo wrote ids hyphen-less (`MM8`) in 209 places to dodge the matcher. The product's vocabulary was
# deforming around a regex.
#
# WHY A SLOT AND NOT A BETTER REGEX. A delivery claim is irreducibly the author's own statement, so
# there is no unauthorable medium to switch to — the repair is to give the claim a NAMED PLACE.
# A slot can be empty (`serves: []` means "this story claims nothing", and is honoured as such);
# a rule over free text is satisfiable by accident by every sentence in the repo. The same file
# already works this way one function up: `sources` reads a named Source CELL, `depends_on`/`blocks`
# read frontmatter. `serves` was the one edge kind that guessed.
#
# PRECEDENCE, and why the fallback exists:
#   1. frontmatter `serves: [MM-2, JOB-1]` — the single source of truth. PRESENT-BUT-EMPTY is an
#      explicit "none" and stops here; it never falls through.
#   2. else the §1d checklist line the story template emits — `- [x] Magic Moment: MM-2 — Name`.
#      The id must be the FIRST token after the label, so "None claimed. MM-1 and MM-2 are …"
#      claims nothing. This is the migration-era bridge: in the field every genuine claim already
#      sat on this line, so a repo that has not run `migrate --lift-serves` yet stays wired.
# ---------------------------------------------------------------------------

# A leading boundary that is neither alphanumeric NOR a hyphen: `YYYY-MM-01` in a date format is
# not a magic moment, and it used to mint a hard `DANGLING_REF.P1` BLOCK out of a table placeholder.
RE_PROMISE_ID = re.compile(r"(?<![A-Za-z0-9-])(MM-\d+[a-z]?|JOB-\d+)\b")
RE_CODE_SPAN = re.compile(r"`[^`]*`")

# The §1d claim line. The id sits IMMEDIATELY after the label — that adjacency is the claim.
RE_SERVES_CHECKLIST = re.compile(
    r"^\s*[-*+]\s*\[[ xX]\]\s*(?:\*\*)?Magic\s+Moment(?:\*\*)?\s*:\s*\**\s*(MM-\d+[a-z]?|JOB-\d+)\b")


def _dedup(seq):
    """Order-preserving dedup. A claim is a SET — an id named three times is one promise, not
    three edges (the old extractor appended per occurrence: 122 of one repo's 800 edges were
    duplicate serves rows, and those counts got quoted onward as graph size)."""
    seen = set()
    out = []
    for x in seq:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out


def promise_refs(raw):
    """MM/JOB ids out of a structured frontmatter value: `serves: [MM-2, JOB-1]`."""
    return _dedup(RE_PROMISE_ID.findall(raw or ""))


def story_promise_claims(fm, text):
    """Return (claimed_ids, source) for one story spec. See the precedence note above."""
    if "serves" in fm:
        return promise_refs(fm.get("serves", "")), "frontmatter"
    claims = []
    for _lineno, line in content_lines(text, skip_frontmatter=True):
        m = RE_SERVES_CHECKLIST.match(line)
        if m:
            claims.append(m.group(1))
    return _dedup(claims), "checklist"


def unclaimed_promise_mentions(text, claimed):
    """Bare id mentions in prose that no structured claim covers → [{id, line, text}].

    Reported as `UNCLAIMED_MM_REF.P3` — a located hint, NEVER a finding. Specs legitimately discuss
    ids: cross-references, epic narrative, explicit non-claims, retro prose, decision logs. A gate
    that convicted a spec for EXPLAINING where a promise lives would teach authors to delete the
    explanation, which is the failure direction this whole repair exists to avoid.
    """
    out = []
    claimed_set = set(claimed)
    for lineno, line in content_lines(text, skip_frontmatter=True):
        if RE_SERVES_CHECKLIST.match(line):
            continue
        scan = RE_CODE_SPAN.sub(" ", line)  # an id inside `backticks` is an example, not a mention
        for tok in _dedup(RE_PROMISE_ID.findall(scan)):
            if tok in claimed_set:
                continue
            out.append({"id": tok, "line": lineno, "text": line.strip()[:120]})
    return out


def _extract_story(spec, story_path, epic_id, story_qual, nodes, edges, add_node):
    title = os.path.basename(story_path)
    if not os.path.isfile(spec):
        # a story dir with no spec.md is itself a finding surface; record the node so
        # discharge edges pointing at it still resolve, flagged as spec-less.
        add_node(Node(story_qual, "story", epic_id, title, story_path, "",
                      content_hash(title), {"no_spec": True}))
        return
    text = read_text(spec)
    fm, body = strip_frontmatter(text)
    body = strip_noncontent(body)  # don't harvest MM/AC refs from fenced examples
    add_node(Node(story_qual, "story", epic_id, title, spec, "", content_hash(text),
                  {"readiness_state_verified": fm.get("readiness_state_verified", ""),
                   "lifecycle_state": fm.get("lifecycle_state", ""),
                   # v10.1 (issue #96 finding 4): the wiring claim for a story that serves a
                   # promise DIRECTLY (no PRM row to carry the cells). Same two fields, same rules.
                   "entry_point": (fm.get("entry_point", "") or "").strip().strip("`").strip(),
                   "wiring_witness": (fm.get("wiring_witness", "") or "").strip().strip("`").strip()}))
    # AC-N nodes from §2b headings: "#### AC-1 — ...", incl. sub-lettered "#### AC-1a: ..."
    for m in re.finditer(r"^#{2,4}\s+(AC-\d+[a-z]?)\b\s*(?:[—\-:]\s*(.*))?$", body, re.MULTILINE):
        ac_id = "%s/%s" % (story_qual, m.group(1))
        add_node(Node(ac_id, "ac", epic_id, (m.group(2) or "").strip(), spec, m.group(1),
                      content_hash(m.group(0))))
    # --- serves edges: a DELIVERY CLAIM, and a claim needs a SLOT, not a sentence ---
    claims, claim_source = story_promise_claims(fm, text)
    for tok in claims:
        edges.append(Edge(story_qual, "serves", tok, source_file=spec,
                          attrs={"epic_scope": epic_id, "story_scope": story_qual,
                                 "claim_source": claim_source}))
    # every OTHER id occurrence is prose: recorded with path:line as a hint, never as an edge
    unclaimed = unclaimed_promise_mentions(text, claims)
    if unclaimed:
        nodes[story_qual].attrs["unclaimed_promise_refs"] = unclaimed
    # depends_on / blocks from frontmatter — story_refs preserves ordinal/full-dir qualifiers
    for key, kind in (("depends_on", "depends-on"), ("blocks", "blocks")):
        for tok in story_refs(fm.get(key, "")):
            edges.append(Edge(story_qual, kind, tok, source_file=spec,
                              attrs={"epic_scope": epic_id, "story_scope": story_qual}))

    # verdict extraction (v9.4): scan this story's validation artifacts for RECORDED MM verdicts →
    # `judges` edges. The graph proves a verdict was recorded (the excellence machinery RAN), NOT that
    # it is honest — that stays with /speck-audit. So an agent can't dodge UNJUDGED by writing a bare token
    # without the /speck-audit adversary catching a fabricated one.
    _extract_verdicts(story_path, story_qual, epic_id, nodes, edges, add_node)


# ---------------------------------------------------------------------------
# Verdicts (v9.4, repaired for issue #97) — a `judges` edge needs an EXPLICIT, machine-readable line.
#
# THE SCAR. The old matcher took an MM id within 80 characters of GOOD|PASS|judged|scored — and a
# negation sits well inside 80 characters. A validation report reading
#     `MM-1 was NOT judged in this story — no LARP has run`
# minted a `judges` edge, cleared `UNJUDGED_SURFACE` and lifted `GRAPH_CAP` from INTEGRATION-GREEN
# to SHIP. The sentence that says the machinery did not run is not evidence that it did.
#
# The canonical form the skills write and this reads:
#     - **VERDICT** MM-1 = GOOD — pixel-anchored, connoisseur Job B
# or, in the report's own frontmatter:
#     mm_verdicts: MM-1=GOOD, MM-2=BAD
# The old loose pattern survives as a HINT ONLY (`UNPARSED_VERDICT.P3`): verdict-shaped prose with
# no machine-readable line is surfaced so the author can convert it — it can no longer clear a gate.
# As before, the graph proves a verdict was RECORDED, never that it is honest; that stays with /speck-audit.
# ---------------------------------------------------------------------------

VERDICT_WORDS = r"GOOD|BAD|PASS|FAIL|CONDITIONAL[ _-]?PASS"

RE_VERDICT_LINE = re.compile(
    r"^\s*(?:[-*+]\s*)?(?:\*\*|`)?VERDICT(?:\*\*|`)?\s*:?\s*"
    r"(?:\*\*)?(MM-\d+[a-z]?)(?:\*\*)?\s*(?:=|:|—|–|-)\s*(?:\*\*|`)?(" + VERDICT_WORDS + r")\b",
    re.IGNORECASE)

RE_FM_VERDICT = re.compile(r"(MM-\d+[a-z]?)\s*[=:]\s*(" + VERDICT_WORDS + r")\b", re.IGNORECASE)

# Verdict-SHAPED prose. Kept only to tell an author "this looks like a verdict but proves nothing".
RE_MM_VERDICT = re.compile(
    r"(MM-?\d+[a-z]?)\b(?:(?!MM-?\d).){0,80}?(GOOD|BAD|PASS|FAIL|CONDITIONAL[_ ]?PASS|✅|❌|judged|scored)",
    re.IGNORECASE)


def _norm_mm(mm):
    return mm if mm.upper().startswith("MM-") else "MM-" + mm[2:]  # normalize MM3 → MM-3


def _structured_verdicts(text):
    """Every machine-readable verdict in one artifact → [(mm_id, verdict, lineno)]."""
    out = []
    fm, _body = strip_frontmatter(text)
    for mm, verdict in RE_FM_VERDICT.findall(fm.get("mm_verdicts", "") or ""):
        out.append((_norm_mm(mm), verdict.upper(), 0))
    for lineno, line in content_lines(text, skip_frontmatter=True):
        m = RE_VERDICT_LINE.match(line)
        if m:
            out.append((_norm_mm(m.group(1)), m.group(2).upper(), lineno))
    return out


def _extract_verdicts(story_path, story_qual, epic_id, nodes, edges, add_node):
    artifacts = [os.path.join(story_path, "validation-report.md"),
                 os.path.join(story_path, "connoisseur-critique.md")]
    lrp = os.path.join(story_path, "larp-recordings")
    if os.path.isdir(lrp):
        for f in sorted(os.listdir(lrp)):
            if f.endswith(".md") and ("finding" in f or "critique" in f or "larp" in f):
                artifacts.append(os.path.join(lrp, f))
    seen = set()
    hints = []
    for art in artifacts:
        if not os.path.isfile(art):
            continue
        raw = read_text(art)
        structured = _structured_verdicts(raw)
        recorded = set(mm for mm, _v, _ln in structured)
        for mm_id, verdict, lineno in structured:
            key = (mm_id, art)
            if key in seen:
                continue
            seen.add(key)
            vnode = "verdict:%s@%s" % (mm_id, story_qual)
            add_node(Node(vnode, "verdict", epic_id, verdict, art, mm_id,
                          content_hash("%s=%s" % (mm_id, verdict))))
            edges.append(Edge(vnode, "judges", mm_id, dst=mm_id, source_file=art,
                              attrs={"line": lineno}))
        # verdict-shaped prose with no machine-readable line behind it: a hint, never an edge
        for lineno, line in content_lines(raw, skip_frontmatter=True):
            if RE_VERDICT_LINE.match(line):
                continue
            for m in RE_MM_VERDICT.finditer(line):
                mm_id = _norm_mm(m.group(1))
                if mm_id in recorded:
                    continue
                hints.append({"mm": mm_id, "source_file": art, "line": lineno,
                              "text": line.strip()[:120]})
                break
    if hints and story_qual in nodes:
        nodes[story_qual].attrs["unparsed_verdicts"] = hints


# ---------------------------------------------------------------------------
# Graph object + serialization
# ---------------------------------------------------------------------------

def build_graph(project_dir):
    nodes, edges, meta = extract(project_dir)
    root = _repo_root(project_dir)
    completeness = "complete"
    if meta["missing_sources"]:
        completeness = "partial"
    graph = {
        "schema_version": SCHEMA_VERSION,
        "project_id": meta["project_id"],
        "built_against_sha": git_head_sha(root) if root else "",
        "generator_completeness": completeness,
        "missing_sources": meta["missing_sources"],
        "counts": {
            "nodes": len(nodes),
            "edges": len(edges),
            "by_kind": _count_by(nodes.values(), lambda n: n.kind),
        },
        "nodes": [nodes[k].to_dict() for k in sorted(nodes.keys())],
        "edges": [e.to_dict() for e in edges],
        # extractor observations that are NOT graph facts (a §5 heading with no id has no node to
        # hang off). Deliberately outside the nodes/edges signature `_sig` compares, so adding them
        # can never read as staleness in an otherwise-fresh committed witness.
        "extractor_notes": {"heterogeneous_ids": meta.get("heterogeneous_ids", [])},
    }
    return graph, nodes, edges


def _count_by(items, keyfn):
    out = {}
    for it in items:
        k = keyfn(it)
        out[k] = out.get(k, 0) + 1
    return out


def _repo_root(start):
    cur = os.path.abspath(start)
    while cur != "/":
        if os.path.isdir(os.path.join(cur, ".speck")) or os.path.isdir(os.path.join(cur, ".git")):
            return cur
        cur = os.path.dirname(cur)
    return None


def graph_path(project_dir):
    return os.path.join(project_dir, "graph", "witness.json")


# ---------------------------------------------------------------------------
# lint-refs — the dangling-reference gate (Phase 1 forcing function)
# ---------------------------------------------------------------------------

def _target_kind(dst):
    """Infer the referenced node kind from a resolved canonical id's shape."""
    if dst.startswith("?epic/"):
        return "unresolved-epic"
    if re.search(r"/AC-\d+[a-z]?$", dst):
        return "ac"
    if RE_MM.match(dst):
        return "magic-moment"
    if RE_JOB.match(dst):
        return "job"
    if RE_DIF.match(dst):
        return "differentiator"
    if RE_DEC.match(dst):
        return "dec"
    if RE_FR.match(dst) or re.search(r"/NFR-\d+$", dst) or RE_NFR.match(dst):
        return "requirement"
    if re.search(r"/PRM-\d+$", dst):
        return "prm"
    if re.search(r"/S\d{2,}$", dst) or RE_STORY_BARE.match(dst):
        return "story"
    return "unknown"


def lint_refs(nodes, edges):
    """Classify every cross-reference as OK, real rot (P1), or an unadopted scheme (P3).

    Migration-aware, mirroring gate-liveness UNVERIFIED-vs-DISARMED: a dangling ref is real rot
    (`DANGLING_REF.P1`) only when its target's id SCHEME is established in the relevant scope —
    the target STORY exists (a missing story is always rot), or the target's kind already has
    defined instances there. When the scheme is simply not yet adopted (a story with zero AC
    anchors, a contract with zero MM/JOB ids), the ref degrades to `GRAPH_UNMIGRATED.P3` — an
    honest cap that says "this project hasn't hardened these ids yet," never a false P1.
    """
    known = set(nodes.keys())
    story_ids = set(n.id for n in nodes.values() if n.kind == "story")
    acs_per_story = {}
    for n in nodes.values():
        if n.kind == "ac":
            parent = n.id.rsplit("/", 1)[0]
            acs_per_story[parent] = acs_per_story.get(parent, 0) + 1
    kind_counts = _count_by(nodes.values(), lambda n: n.kind)

    findings = []
    unmigrated = {}  # kind -> count, aggregated so an un-migrated repo isn't spammed

    def add_p1(code, e, detail):
        findings.append({
            "code": code, "src": e.src, "edge": e.kind, "ref": e.dst_ref,
            "resolved_to": e.dst, "source_file": e.source_file, "detail": detail,
        })

    for e in edges:
        if e.dst is None or e.dst in known:
            continue  # prose (not a ref) or resolves cleanly
        kind = _target_kind(e.dst)
        if kind == "ac":
            story_part = e.dst.rsplit("/", 1)[0]
            if story_part not in story_ids:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : the discharging STORY %s does not exist"
                       % (e.src, e.kind, e.dst, story_part))
            elif acs_per_story.get(story_part, 0) == 0:
                unmigrated["ac"] = unmigrated.get("ac", 0) + 1  # story exists, no AC-N scheme yet
            else:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : story defines AC-N ids but not this one (renumbered?)"
                       % (e.src, e.kind, e.dst))
        elif kind == "story":
            add_p1("DANGLING_REF.P1", e,
                   "%s --%s--> %s : target story does not exist" % (e.src, e.kind, e.dst))
        elif kind in ("magic-moment", "job", "differentiator"):
            if kind_counts.get(kind, 0) == 0:
                unmigrated[kind] = unmigrated.get(kind, 0) + 1  # contract hasn't adopted the id scheme
            else:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : no such %s defined in product-contract"
                       % (e.src, e.kind, e.dst, kind))
        elif kind in ("dec", "requirement", "prm"):
            if kind_counts.get(kind, 0) == 0:
                unmigrated[kind] = unmigrated.get(kind, 0) + 1
            else:
                add_p1("DANGLING_REF.P1", e,
                       "%s --%s--> %s : no such %s defined" % (e.src, e.kind, e.dst, kind))
        elif kind == "unresolved-epic":
            add_p1("DANGLING_REF.P1", e,
                   "%s --%s--> %s : the epic qualifier does not match any epic (typo?)"
                   % (e.src, e.kind, e.dst_ref))
        # kind == "unknown": not a confident id shape — leave it (prose), never a false P1

    for nid, n in nodes.items():
        dups = n.attrs.get("duplicate_definitions")
        if dups:
            findings.append({
                "code": "DUP_ID.P1", "src": nid, "edge": "define", "ref": nid,
                "resolved_to": nid, "source_file": "%s + %s" % (n.source_file, ", ".join(dups)),
                "detail": "id %s defined in more than one place — ambiguous key" % nid,
            })
    return findings, unmigrated


# ---------------------------------------------------------------------------
# Graph index + agent-facing queries (the context-assembly value: one lookup instead of a
# seven-file tree walk — Speck's named failure mode is "not having the right context").
# ---------------------------------------------------------------------------

class Graph:
    def __init__(self, nodes, edges):
        self.nodes = nodes
        self.edges = edges
        self.out = {}  # src id -> [edges]
        self.inc = {}  # dst id -> [edges]
        for e in edges:
            self.out.setdefault(e.src, []).append(e)
            if e.dst:
                self.inc.setdefault(e.dst, []).append(e)

    def node(self, nid):
        return self.nodes.get(nid)

    def resolve_subject(self, raw):
        """Best-effort: accept a canonical id, a bare story/epic id, or a dir-name fragment."""
        if raw in self.nodes:
            return raw
        # try each epic scope for a bare story/prm/ac
        epic_index = build_epic_index([n.id for n in self.nodes.values() if n.kind == "epic"])
        for scope in [n.id for n in self.nodes.values() if n.kind == "epic"]:
            cand = resolve_ref(raw, epic_scope=scope, epic_index=epic_index)
            if cand and cand in self.nodes:
                return cand
        # substring match on ids (e.g. "S038" or "app-shell")
        hits = [nid for nid in self.nodes if raw in nid]
        return hits[0] if len(hits) == 1 else None

    def context_pack(self, story_id):
        """Assemble everything an agent needs to safely work a story — in one query."""
        n = self.nodes.get(story_id)
        if not n or n.kind != "story":
            return None
        epic = n.scope
        pack = {
            "story": story_id,
            "title": n.title,
            "epic": epic,
            "readiness_state_verified": n.attrs.get("readiness_state_verified", ""),
            "acs": sorted(nid for nid, nn in self.nodes.items()
                          if nn.kind == "ac" and nid.startswith(story_id + "/")),
            "serves_promises": [],       # MM / JOB this story delivers
            "discharges": [],            # PRM rows this story discharges (+ their sources)
            "depends_on": [], "blocks": [],
            "constraining_decs": [],     # DECs that descope PRMs in this story's epic
            "guarding_gates": [],        # populated once gate nodes land (P3)
        }
        for e in self.out.get(story_id, []):
            if e.kind == "serves" and e.dst:
                pack["serves_promises"].append(e.dst)
            elif e.kind == "depends-on" and e.dst:
                pack["depends_on"].append(e.dst)
            elif e.kind == "blocks" and e.dst:
                pack["blocks"].append(e.dst)
        # PRMs discharged by this story = discharge edges landing on the story or its ACs
        for e in self.edges:
            if e.kind == "discharges" and e.dst and (e.dst == story_id or e.dst.startswith(story_id + "/")):
                prm = self.nodes.get(e.src)
                sources = [se.dst for se in self.out.get(e.src, []) if se.kind == "sources" and se.dst]
                pack["discharges"].append({
                    "prm": e.src,
                    "ac": e.dst if e.dst != story_id else None,
                    "grain": prm.attrs.get("grain", "") if prm else "",
                    "status": prm.attrs.get("status", "") if prm else "",
                    "sources": sources,
                })
        # DECs in the same epic that descope something (constraints the story lives under)
        decs = set()
        for e in self.edges:
            if e.kind == "descoped-by" and e.dst and self.nodes.get(e.src) and self.nodes[e.src].scope == epic:
                decs.add(e.dst)
        pack["constraining_decs"] = sorted(decs)
        return pack


def cmd_query(project_dir, subject):
    _g, nodes, edges = build_graph(project_dir)
    g = Graph(nodes, edges)
    sid = g.resolve_subject(subject)
    if not sid:
        sys.stderr.write("No unique node matches %r. Try a canonical id (e.g. 004-x/S012, MM-3).\n" % subject)
        return 2
    n = g.nodes[sid]
    out_edges = [(e.kind, e.dst or e.dst_ref) for e in g.out.get(sid, [])]
    in_edges = [(e.src, e.kind) for e in g.inc.get(sid, [])]
    result = {
        "id": sid, "kind": n.kind, "title": n.title, "scope": n.scope,
        "attrs": n.attrs,
        "out_edges": [{"kind": k, "to": d} for k, d in out_edges],
        "in_edges": [{"from": s, "kind": k} for s, k in in_edges],
    }
    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


def cmd_context(project_dir, subject):
    _g, nodes, edges = build_graph(project_dir)
    g = Graph(nodes, edges)
    sid = g.resolve_subject(subject)
    if not sid or g.nodes[sid].kind != "story":
        sys.stderr.write("context needs a story id (e.g. 004-ai-core-workout-gen/S008 or S008).\n")
        return 2
    pack = g.context_pack(sid)
    json.dump(pack, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


# ---------------------------------------------------------------------------
# check — the forcing gates. LOUD and structural. Caps or blocks; NEVER grants.
#
# The anti-rubber-stamp law: this proves traceable/complete/fresh. It CANNOT prove
# faithful/good — those stay with /speck-audit + the canaries. Gates that need data not yet in the
# graph (orphan-code needs code nodes from tests-as-join P5; un-judged needs verdict nodes)
# are reported as HONEST pending notes, never as a false pass.
# ---------------------------------------------------------------------------

READINESS_ORDER = ["no-ship", "impl-green", "integration-green", "ux-rc", "api-rc",
                   "operational-rc", "commercial-rc", "ship-rc", "ship"]


def _min_readiness(a, b):
    ia = READINESS_ORDER.index(a) if a in READINESS_ORDER else 0
    ib = READINESS_ORDER.index(b) if b in READINESS_ORDER else 0
    return READINESS_ORDER[min(ia, ib)]


def _find_cycle(adj):
    """Return one cycle as a node list (closed: [a, b, a]) via DFS, or None. Deterministic."""
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {}
    parent = {}
    for start in sorted(adj.keys()):
        if color.get(start, WHITE) != WHITE:
            continue
        stack = [(start, iter(sorted(adj.get(start, []))))]
        color[start] = GRAY
        while stack:
            node, it = stack[-1]
            advanced = False
            for nxt in it:
                c = color.get(nxt, WHITE)
                if c == WHITE:
                    color[nxt] = GRAY
                    parent[nxt] = node
                    stack.append((nxt, iter(sorted(adj.get(nxt, [])))))
                    advanced = True
                    break
                if c == GRAY:  # back-edge → reconstruct the cycle
                    cyc = [nxt, node]
                    p = node
                    while p != nxt and p in parent:
                        p = parent[p]
                        cyc.append(p)
                    cyc.reverse()
                    cyc.append(cyc[0])
                    return cyc
            if not advanced:
                color[node] = BLACK
                stack.pop()
    return None


def cascade_blast(project_dir, dec):
    """Reverse-reachability from a DEC → the discharged PRMs it descopes that are still active.

    The graph form of compute-cascade.sh's core: a still-`discharged` promise under a (superseded)
    DEC is a CASCADE_STALE risk. Informational query; the recheck skill decides supersession.
    """
    _graph, nodes, edges = build_graph(project_dir)
    hits = []
    for e in edges:
        if e.kind == "descoped-by" and e.dst == dec:
            prm = nodes.get(e.src)
            if prm and (prm.attrs.get("status") or "").lower() == "discharged":
                hits.append(prm.id)
    return sorted(set(hits))


# ---------------------------------------------------------------------------
# Reachability witness (v10.1, issue #96 finding 4) — the decidable slice #86 set aside.
#
# Conservation (PHANTOM_PROMISE) asks whether a promise has an OWNER. It never asks whether a user
# gesture REACHES it, because every one of its legs is document-derived: `serves`, `sources`,
# `discharges`. The scar it cannot see: an epic whose matrix was all-`mapped`, `Blocking = 0`,
# `GRAPH_CAP = SHIP` — and whose central promise had never once fired for a real user, because
# nothing in the app ever created the row the whole read side depended on. The gate's verdict did
# not change when that epic went from non-functional to functional. That, not the defect, is why
# this leg exists.
#
# #86 concluded fidelity is not statically decidable and asked only that the success string stop
# over-reading. REACHABILITY is decidable, at one honest altitude below tests-as-join (P5): the
# delivery claim must NAME a production entry point, and must CITE the `<path>:<line>` a
# delete-the-call mutation reddened. Neither field proves the code is good — they prove the claim
# resolves to something, which is #71's law applied one artifact up.
#
# THE BOUND THAT MAKES IT SAFE. Roughly a third of a real matrix promises something whose delivery
# is NOT a call: a schema constraint, an RLS policy, a copy/legal promise, an absence promise
# ("threads introduce no badge, ring, streak or confetti"). Those take `entry_point: n/a — <kind>`
# and are accepted. An unbounded "every promise names a call site" rule would be wrong for all of
# them and would push authors toward naming a fake site — worse than no gate. Note the polarity:
# the authored list is the EXCEPTIONS (the n/a kinds), never the instances. Bare `n/a` does NOT
# discharge; the kind has to be named, because that is the part a reader can disagree with.
#
# It CAPS, never blocks (`mapped-unwitnessed` is a ceiling, same polarity as GRAPH_CAP), and it is
# adoption-gated: a project that carries no `entry_point` anywhere gets a non-capping P3 that names
# the fixing edit, so no existing matrix becomes non-conformant on upgrade.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# The findings registry (v10.1, issue #100 §5) — ONE namespace, and it is this one.
#
# THE QUESTION #100 LEFT OPEN: which artifact owns the severity ranking that decides what the next
# session works on? This module already mints every gate code and every severity suffix. A second,
# project-level registry listing the same findings by hand would be a second namespace — and #87's
# law says a correct judgment that reaches half its artifacts leaves the system LESS coherent than
# before. The measured cost of the hand-kept version was 14 of 20 entries stale, one of them
# advertising the project's highest open severity for eleven fires after it was closed, plus one
# defect carrying three ids across two reports.
#
# THE RESOLUTION: the graph's namespace is AUTHORITATIVE and the project-level view is DERIVED.
# `speck_graph.py findings` recomputes the whole ranked list from the same check_graph() call the
# cap and the road come from, so the ranking is COMPUTED, never typed, and per-epic reports render
# from it. A derived view cannot drift; aliasing cannot arise, because the id is the gate code plus
# the node it fires on — the same defect found twice yields the same key by construction, so
# convergence stays visible instead of minting `COM-02 = F-08 = E003-10`.
#
# WHAT STAYS AUTHORED, AND ITS POLARITY: only `findings-exceptions.md` — and it enumerates
# EXCEPTIONS, never instances. A list of instances rots silently (nothing fires when an entry goes
# stale); a list of exceptions FAILS LOUDLY when the world changes, because an exception whose
# finding no longer fires is a phantom and says so. That is the same both-directions ratchet a
# registry needs to avoid decaying into a list of standing permission slips.
#
# WHAT AN EXCEPTION MAY NOT DO: change the ceiling. Acceptance moves a finding in the WORK ORDER,
# never in GRAPH_CAP — design invariant §6.4 is "caps, never raises", and an exception that lifted
# a cap would be the one authored input able to grant readiness.
# ---------------------------------------------------------------------------

EXCEPTION_POSTURES = ("ACCEPTED", "SUPERSEDED")
# There is nowhere to write "looks fine" — that is the phrase that turned the hand-kept registries
# into decoration. An entry must name what is true, not what someone believes.
EXCEPTION_BELIEF_WORDS = (
    "looks fine", "looks ok", "looks okay", "seems fine", "seems ok", "seems okay",
    "probably", "should be fine", "not a problem", "no issue", "fine for now", "wontfix", "n/a")
EXCEPTION_MIN_WHY = 40
RE_EXCEPTION_KEY = re.compile(r"^[A-Z][A-Z0-9_]+(?:\.P\d)?(?:@\S.*)?$")


def _code_root(code):
    return code.split(".")[0]


def finding_key(code, subject=""):
    """The one id a finding has: `<GATE_CODE>@<node>`, or the bare code for a project-wide cap.

    Minted from the compile, never typed — which is what makes a cross-epic re-find an identical
    key instead of a third alias.
    """
    root = _code_root(code)
    return "%s@%s" % (root, subject) if subject else root


def read_findings_exceptions(project_dir):
    """Parse the authored exceptions registry → [{key, posture, why}]. Absent file → []."""
    path = os.path.join(project_dir, "findings-exceptions.md")
    if not os.path.isfile(path):
        return []
    out = []
    for table in parse_tables(read_text(path)):
        headers = table["headers"]
        h_key = find_header(headers, "finding")
        h_posture = find_header(headers, "posture", "state")
        h_why = find_header(headers, "why", "reason")
        if not h_key:
            continue
        for row in table["rows"]:
            key = (row.get(h_key, "") or "").strip().strip("`").strip()
            if not RE_EXCEPTION_KEY.match(key):
                continue  # template placeholder / prose row — not an entry
            out.append({"key": key,
                        "posture": (row.get(h_posture, "") or "").strip().strip("`").strip().upper(),
                        "why": (row.get(h_why, "") or "").strip()})
    return out


def apply_exceptions(findings, caps, exceptions):
    """Match authored exceptions against the LIVE finding set; annotate matches, report the rest.

    Returns (invalid, accepted_keys): [(code, message)] for every entry that does not hold, and the
    set of finding keys an entry legitimately covers. Annotates each matched FINDING dict with
    `accepted` (caps are strings and carry no slot, hence the key set). It never touches severity:
    see the polarity note above.
    """
    live = {}
    for f in findings:
        for key in (finding_key(f["code"], f.get("ref", "")), finding_key(f["code"])):
            live.setdefault(key, []).append(f)
    for c in caps:
        live.setdefault(finding_key(c.split(":", 1)[0].strip()), []).append(None)

    invalid = []
    accepted_keys = set()
    for ex in exceptions:
        key = finding_key(ex["key"].split("@", 1)[0],
                          ex["key"].split("@", 1)[1] if "@" in ex["key"] else "")
        why = ex["why"]
        low = why.lower()
        if _code_root(ex["key"].split("@", 1)[0]).startswith("EXCEPTION_"):
            invalid.append(("EXCEPTION_UNJUSTIFIED.P2",
                            "`%s` excepts the exception gate itself — a registry that can silence "
                            "its own ratchet is not a ratchet. Delete the row." % ex["key"]))
            continue
        if ex["posture"] not in EXCEPTION_POSTURES:
            invalid.append(("EXCEPTION_UNJUSTIFIED.P2",
                            "`%s` declares posture '%s'; there are exactly two an entry can take — "
                            "ACCEPTED (known, declined, with the reason) or SUPERSEDED (a DEC "
                            "retired it; collapsing that into 'fixed' loses the reason)."
                            % (ex["key"], ex["posture"] or "<blank>")))
            continue
        if len(why) < EXCEPTION_MIN_WHY or any(w in low for w in EXCEPTION_BELIEF_WORDS):
            invalid.append(("EXCEPTION_UNJUSTIFIED.P2",
                            "`%s` says nothing an outsider can check — name the caller, the surface, "
                            "or what the current behaviour costs (>=%d chars, no belief words). "
                            "Got: '%s'" % (ex["key"], EXCEPTION_MIN_WHY, why[:60])))
            continue
        if key not in live:
            invalid.append(("EXCEPTION_PHANTOM.P2",
                            "`%s` excepts a finding that NO LONGER FIRES — good news, it was fixed "
                            "or moved. Delete the row, so the registry keeps describing what "
                            "actually ships rather than becoming a standing permission slip."
                            % ex["key"]))
            continue
        accepted_keys.add(key)
        for f in live[key]:
            if f is not None:
                f["accepted"] = "%s — %s" % (ex["posture"], why)
    return invalid, accepted_keys


RE_ENTRY_POINT = re.compile(r"^[^\s:]+\.[A-Za-z0-9]+:[A-Za-z_][A-Za-z0-9_.]*$")
RE_ENTRY_NA = re.compile(r"^n/?a\s*[—–-]\s*(\S.*)$", re.IGNORECASE)
RE_WITNESS_SITE = re.compile(r"[A-Za-z0-9_@./-]+\.[A-Za-z0-9]+:\d+")


def _wiring_claim(node):
    """Classify one delivery claimant's wiring cells → (state, detail).

    states: `n/a` (bounded escape, accepted) · `sited` (detail is the mutation site) ·
            `absent` · `malformed` · `unproven`.
    """
    ep = (node.attrs.get("entry_point") or "").strip()
    wit = (node.attrs.get("wiring_witness") or "").strip()
    if not ep:
        return "absent", "carries no `entry_point`"
    na = RE_ENTRY_NA.match(ep)
    if na:
        return "n/a", "delivery is not a call — %s" % na.group(1).strip()
    if not RE_ENTRY_POINT.match(ep):
        return "malformed", ("`entry_point: %s` is neither `<path>:<symbol>` nor the bounded escape "
                             "`n/a — <kind>` (schema constraint / RLS policy / copy / absence "
                             "promise). A bare `n/a` does not discharge: name the kind." % ep)
    site = RE_WITNESS_SITE.search(wit)
    if not site:
        return "unproven", ("entry point `%s` names a call site, but no `wiring_witness` cites the "
                            "`<path>:<line>` that a delete-the-call mutation reddened. A control "
                            "that still passes with the call deleted is not a witness." % ep)
    return "sited", site.group(0)


def _witness_cited(site, story_node):
    """True when the DELIVERING story's validation report records that mutation site.

    The join is the load-bearing half. A cell in a matrix is one author's sentence; the same site
    appearing in the story's own report is a claim two artifacts have to agree on — and it is
    exactly the citation shape `mutate-guard.sh --verify-receipt` recomputes against the receipts
    on disk. The graph proves the citation RESOLVES; whether the mutation ran stays with the guard.
    """
    if story_node is None:
        return False
    src = story_node.source_file or ""
    story_dir = src if os.path.isdir(src) else os.path.dirname(src)
    if not story_dir:
        return False
    report = os.path.join(story_dir, "validation-report.md")
    if not os.path.isfile(report):
        return False
    return site in read_text(report)


# The THIRD leg (v10.2, issue #96 finding 4) — the slice where the graph can mechanically
# CONTRADICT a claimed discharge, as opposed to merely noticing that a field is empty.
#
# v10.1 shipped the two absence legs: a delivery claim must NAME a production entry point, and the
# delivering story's own report must RECORD the `<path>:<line>` a delete-the-call mutation reddened.
# Both ask "is the field filled?". Neither ever looked at the tree, so `entry_point:
# lib/ghost.ts:createGhost` — a file that has never existed — read exactly like a true one, and the
# citation pair could be satisfied entirely by two sentences the same author typed.
#
# WHAT IS DECIDABLE, and it is only this: a cited path either exists in this tree or it does not; a
# cited symbol either occurs in that file or it does not; a cited line either exists in that file or
# it does not. Each `no` is a CONTRADICTION — the claim asserts something about the tree that the
# tree refutes — and needs no judgement about whether the code is any good.
#
# WHAT STAYS UNDECIDABLE, stated so nobody reads this leg as more than it is:
#   • whether a user gesture actually REACHES that symbol at runtime (needs code nodes + a call
#     graph — the `ORPHAN_CODE` P5 line the graph already declares NOT evaluated),
#   • whether the mutation was RUN as opposed to recorded (that is `mutate-guard.sh
#     --verify-receipt`, which recomputes the pinned content against the receipts on disk),
#   • whether the code at that entry point is FAITHFUL to the promise (#86's conclusion, unchanged:
#     not statically decidable, and a gate that guessed would be worse than the prose it replaces).
#
# NOT EVALUATED beats a guess. With no repo root there is no base to resolve a relative citation
# against, so the answer is "unevaluable" and nothing fires — the same polarity as the adoption
# gradient. A path carrying a template placeholder (`<path>`, `[file]`, `{sym}`) is unfilled, not
# false; that is the absence leg's business, not this one.
RE_CLAIM_PLACEHOLDER = re.compile(r"[<>\[\]{}]")


def _cited_path(project_dir, raw_path):
    """Resolve a cited path against the tree → (state, abspath).

    states: `resolved` (abspath is real) · `unresolved` (no base contains it) · `unevaluable`.
    Two bases are tried, repo root then project dir, because citations are hand-written in both
    conventions and convicting on convention would be a vendor-brittleness bug, not a finding.
    """
    p = (raw_path or "").strip().strip("`")
    if not p or RE_CLAIM_PLACEHOLDER.search(p):
        return "unevaluable", ""
    root = _repo_root(project_dir)
    if not root:
        return "unevaluable", ""
    for base in (root, project_dir):
        cand = os.path.normpath(os.path.join(base, p))
        if os.path.exists(cand):
            return "resolved", cand
    return "unresolved", ""


def _claim_contradicted(project_dir, node):
    """Does this delivery claim name something this tree refutes? → (bool, detail).

    Checks, in the order an author would fix them: the entry-point PATH, the entry-point SYMBOL
    inside that file, the witness PATH, the witness LINE. A file that cannot be read is unevaluable
    (an unreadable file is not a refutation), and only the first contradiction is reported — the
    rest are usually the same typo.
    """
    ep = (node.attrs.get("entry_point") or "").strip().strip("`")
    if not ep or RE_ENTRY_NA.match(ep) or not RE_ENTRY_POINT.match(ep):
        return False, ""          # absent / bounded escape / malformed — the ABSENCE leg's business
    ep_path, _sep, symbol = ep.rpartition(":")
    state, abspath = _cited_path(project_dir, ep_path)
    if state == "unresolved":
        return True, ("`entry_point: %s` names a path that does not exist in this tree — a claim "
                      "that cites a file nobody can open is not a weaker claim than one that cites "
                      "a real file, it is an unfalsifiable one" % ep)
    if state == "resolved":
        text = read_text(abspath)
        if text and symbol not in text:
            return True, ("`entry_point: %s` names a symbol that does not occur anywhere in %s — "
                          "the file exists, the entry point does not (renamed? moved?)" % (ep, ep_path))
    wit = (node.attrs.get("wiring_witness") or "").strip().strip("`")
    site = RE_WITNESS_SITE.search(wit)
    if site:
        w_path, _c, w_line = site.group(0).rpartition(":")
        w_state, w_abs = _cited_path(project_dir, w_path)
        if w_state == "unresolved":
            return True, ("`wiring_witness: %s` cites a mutation site in a file that does not exist "
                          "in this tree" % site.group(0))
        if w_state == "resolved":
            text = read_text(w_abs)
            if text and w_line.isdigit() and int(w_line) > len(text.splitlines()):
                return True, ("`wiring_witness: %s` cites line %s of a file that has %d line(s) — "
                              "the mutation site is outside the file it names"
                              % (site.group(0), w_line, len(text.splitlines())))
    return False, ""


def _graph_signature(gr):
    """Content signature of a compiled graph: nodes (incl. each content_hash) + edges.

    Deliberately NOT `stamped SHA == HEAD`. Brightstance's committed witness sat 5 commits behind
    HEAD and was byte-identical to a fresh compile, because those 5 commits touched no spec — a
    SHA-equality rule would fire on every non-spec commit in every repo and teach `--no-verify`
    within a day. The predicate has to be about CONTENT or it is about nothing.
    """
    root = _sig_paths(gr)
    return content_hash(json.dumps(
        {"nodes": [_sig_item(n, root) for n in gr.get("nodes", [])],
         "edges": [_sig_item(e, root) for e in gr.get("edges", [])]}, sort_keys=True))


def _sig_paths(gr):
    """Every source_file in the graph, reduced to a tail that is independent of WHERE it was built.

    `source_file` is stored absolute, so a build run inside a git worktree writes
    /…/.claude/worktrees/agent-xxx/… while the canonical tree writes /…/…. The two graphs are
    identical in content — zero node diffs after prefix normalization — but hashing the raw path
    made a worktree-built witness read STALE forever once committed, pinning GRAPH_CAP on every
    later session (#121). Where a build HAPPENED is not a fact about the corpus.

    The prefix is derived from the graph itself (the common root of its own paths) rather than
    passed in, so this needs no caller to know the project dir, and a fresh compile and a saved
    witness each reduce to the same relative tails.
    """
    vals = [i.get("source_file", "") for coll in ("nodes", "edges") for i in gr.get(coll, [])]
    abs_vals = [v for v in vals if isinstance(v, str) and v.startswith("/")]
    if not abs_vals:
        return ""
    root = os.path.commonpath(abs_vals) if len(abs_vals) > 1 else os.path.dirname(abs_vals[0])
    return root


def _sig_item(item, root):
    """One node/edge with its build-location prefix removed (see _sig_paths)."""
    sf = item.get("source_file", "")
    if root and isinstance(sf, str) and sf.startswith(root):
        item = dict(item)
        item["source_file"] = sf[len(root):].lstrip("/")
    return item


# The freshness LEG, isolated so more than one consumer can run it (issue #96 finding 3).
#
# It was inlined in check_graph(), which is the one command no lifecycle hook calls — so `gate`,
# described as "the SCOPED forcing primitive the lifecycle hooks call", could not observe staleness
# at all. Isolating it costs one json.load + two hashes over a graph the caller already compiled,
# which is why it is affordable on the pre-implement path.
#
# PURE READ. It never rebuilds and never writes: making the first pre-implement check a MUTATING
# step would break read-only CI checkouts and every tree-clean assertion (the reason #96 finding 3
# was deferred in v10). There is nothing to gate behind `SPECK_CI=1` because there is no write.
FRESHNESS_DETAIL = {
    "stale": "committed witness.json differs from a fresh compile — regenerate with "
             "`speck_graph.py build` (never hand-edit it)",
    "corrupt": "witness.json is unreadable/corrupt — the tamper-evidence artifact itself is "
               "destroyed; regenerate with `speck_graph.py build`",
    "unbuilt": "no committed witness.json — this project's graph has never been built; run "
               "`speck_graph.py build` (not tampering, so it does not cap)",
    "fresh": "committed witness.json matches a fresh compile",
}


def graph_freshness(project_dir, graph=None):
    """Compare the committed witness.json against a FRESH compile.

    Returns (state, detail); state ∈ {fresh, stale, corrupt, unbuilt}. `graph` is the fresh compile
    when the caller already has one (gate/check both do) — otherwise it is compiled here.
    """
    if graph is None:
        graph, _nodes, _edges = build_graph(project_dir)
    on_disk = graph_path(project_dir)
    if not os.path.isfile(on_disk):
        return "unbuilt", FRESHNESS_DETAIL["unbuilt"]
    try:
        saved = json.load(open(on_disk, encoding="utf-8"))
    except (ValueError, OSError):
        return "corrupt", FRESHNESS_DETAIL["corrupt"]
    # compare full CONTENT (nodes incl. their content_hash, + edges), not just ids/counts — a
    # title/hash change or a repointed edge that keeps the id-set must still read STALE
    # (design invariant §6.1: freshness is computed, never asserted).
    if _graph_signature(graph) != _graph_signature(saved):
        return "stale", FRESHNESS_DETAIL["stale"]
    return "fresh", FRESHNESS_DETAIL["fresh"]


def check_graph(project_dir):
    """Run every structural forcing gate. Returns (findings, caps, pending, cap_state)."""
    graph, nodes, edges = build_graph(project_dir)
    g = Graph(nodes, edges)
    kind_counts = _count_by(nodes.values(), lambda n: n.kind)

    findings, cap_reasons = lint_refs(nodes, edges)  # DANGLING_REF.P1 / DUP_ID.P1 (+ unmigrated caps)
    caps = []
    cap_state = "ship"

    def _rel(p):
        try:
            return os.path.relpath(p, project_dir)
        except ValueError:
            return p

    # UNCLAIMED_MM_REF — bare id mentions in prose. A HINT, and deliberately non-capping (issue #97).
    # This is the exact line where the old bug lived: a mention used to BE a claim. It is now
    # visible instead of authoritative, and it must not move the number — otherwise appending an
    # explanatory sentence to a story would still change the project's readiness ceiling, which is
    # the property the test file pins ("prose changes nothing").
    unclaimed = []
    for n in sorted(nodes.values(), key=lambda x: x.id):
        for h in n.attrs.get("unclaimed_promise_refs", []) or []:
            unclaimed.append("%s:%d %s" % (_rel(n.source_file), h["line"], h["id"]))
    if unclaimed:
        caps.append("UNCLAIMED_MM_REF.P3: %d bare promise id(s) mentioned in prose that claim "
                    "nothing (%s%s) — a mention is not a claim; if a story DOES deliver one, put it "
                    "in that story's `serves:` frontmatter (does not cap)"
                    % (len(unclaimed), ", ".join(unclaimed[:5]),
                       ", …" if len(unclaimed) > 5 else ""))

    # UNPARSED_VERDICT — verdict-shaped prose with no machine-readable line behind it. Also a hint:
    # the prose is not proof, but silently dropping it would hide that someone tried to record one.
    unparsed = []
    for n in sorted(nodes.values(), key=lambda x: x.id):
        for h in n.attrs.get("unparsed_verdicts", []) or []:
            unparsed.append("%s:%d %s" % (_rel(h["source_file"]), h["line"], h["mm"]))
    if unparsed:
        caps.append("UNPARSED_VERDICT.P3: %d verdict-shaped line(s) prove nothing (%s%s) — record "
                    "the judgement as `- **VERDICT** MM-N = GOOD|BAD` (or `mm_verdicts:` in the "
                    "report frontmatter) so the graph can read it (does not cap)"
                    % (len(unparsed), ", ".join(unparsed[:5]), ", …" if len(unparsed) > 5 else ""))

    # HETEROGENEOUS_ID — a §5 heading the schema cannot node-ify. Loud instead of a silent census drop.
    for h in graph.get("extractor_notes", {}).get("heterogeneous_ids", []):
        caps.append("HETEROGENEOUS_ID.P3: product-contract §5 heading '%s' (%s:%d) has no `MM-N` id, "
                    "so it is NOT in the census — give it one (`MM-5a` is accepted) (does not cap)"
                    % (h["heading"], _rel(h["source_file"]), h["line"]))

    # unmigrated schemes cap honestly at integration-green (an un-hardened graph can't back ux-rc)
    if cap_reasons:
        detail = ", ".join("%d %s" % (v, k) for k, v in sorted(cap_reasons.items()))
        caps.append("GRAPH_UNMIGRATED.P3: %s reference(s) to un-adopted id schemes (%s)"
                    % (sum(cap_reasons.values()), detail))
        cap_state = _min_readiness(cap_state, "integration-green")

    # PHANTOM_PROMISE — a promise nobody delivers. Loud CAP (bars ux-rc+), migration-aware.
    # A promise is DELIVERED by either valid path: a story serves it directly (serves edge), OR a
    # DISCHARGED PRM sources it (PRM --sources--> MM/JOB, that PRM discharged by a story). Counting
    # only the first path would false-positive every MM tracked via the matrix. "Adopted" = the
    # project wires promises to delivery by SOME path; if it wires none, degrade to un-migrated.
    served = set(e.dst for e in edges if e.kind == "serves" and e.dst)
    # a PRM genuinely delivers only if it is discharged AND actually points at an existing story
    prms_really_discharged = set()
    for e in edges:
        if e.kind == "discharges" and e.dst:
            story_part = e.dst.rsplit("/", 1)[0] if re.search(r"/AC-\d+[a-z]?$", e.dst) else e.dst
            if story_part in nodes and nodes[story_part].kind == "story":
                prms_really_discharged.add(e.src)
    delivered = set(served)
    for e in edges:
        if e.kind == "sources" and e.dst:
            prm = nodes.get(e.src)
            if (prm and prm.kind == "prm" and prm.attrs.get("status") == "discharged"
                    and e.src in prms_really_discharged):
                delivered.add(e.dst)
    wired_kinds = set()
    for e in edges:
        if e.kind == "serves" and e.dst and nodes.get(e.dst):
            wired_kinds.add(nodes[e.dst].kind)
        if e.kind == "sources" and e.dst and nodes.get(e.dst):
            wired_kinds.add(nodes[e.dst].kind)
    for kind in ("magic-moment", "job", "differentiator"):
        present = [n for n in nodes.values() if n.kind == kind]
        if not present:
            continue
        if kind not in wired_kinds:  # no delivery path wired at all → not yet adopted
            caps.append("GRAPH_UNMIGRATED.P3: %d %s(s) defined but nothing wires to any (no story "
                        "serves them and no discharged PRM sources them yet)" % (len(present), kind))
            cap_state = _min_readiness(cap_state, "integration-green")
            continue
        for n in present:
            if n.id not in delivered:
                findings.append({
                    "code": "PHANTOM_PROMISE.P1", "src": n.id, "edge": "serves", "ref": n.id,
                    "resolved_to": n.id, "source_file": n.source_file,
                    "detail": "%s '%s' is promised in the contract but NO story delivers it — no "
                              "story serves it and no discharged PRM sources it (build the right "
                              "thing). Since v10 a claim lives in a story's `serves:` frontmatter; "
                              "naming the id in prose claims nothing. Carrying pre-v10 claims over: "
                              "`speck_graph.py migrate <PROJECT_DIR> --lift-serves`"
                              % (n.id, n.title),
                })

    # GRAPH_STALE — the on-disk graph must equal a fresh compile (freshness computed, not asserted)
    #
    # Two absences, two different facts — never the same code (scar, issue #96 findings 1-2):
    #   TAMPERED (unreadable, or content ≠ a fresh compile) — the tamper-evidence artifact was
    #     destroyed or hand-edited. Both branches once appended only the cap STRING and skipped
    #     _min_readiness, so `rm graph/witness.json` printed GRAPH_STALE next to GRAPH_CAP = SHIP:
    #     destroying the evidence REMOVED the ceiling it exists to enforce. Caps, always.
    #   UNBUILT (no file at all) — the project simply has not run `build` yet. That is the state of
    #     the entire v8→v9 installed base (migrate.js writes .speck/.v9-graph-needed to every
    #     upgrader), and the engagement gate already blocks feature work there. Capping it too would
    #     drop every such project to INTEGRATION-GREEN on a patch bump and double-punish greenfield.
    #     So: an honest, DISTINCT, non-capping signal (GRAPH_UNBUILT.P3) — never a wall.
    # MAPPED_UNWITNESSED — a promise can have an owner and still never be reached. See the header
    # note above _wiring_claim for why this is decidable where fidelity is not, and what bounds it.
    prm_story = {}          # prm id -> the story node it discharges to (first resolvable)
    for e in edges:
        if e.kind == "discharges" and e.dst:
            sp = e.dst.rsplit("/", 1)[0] if re.search(r"/AC-\d+[a-z]?$", e.dst) else e.dst
            if sp in nodes and nodes[sp].kind == "story" and e.src not in prm_story:
                prm_story[e.src] = nodes[sp]
    claimants = {}          # promise id -> [(claimant node, delivering story node or None)]
    for e in edges:
        if e.kind == "serves" and e.dst and e.src in nodes:
            claimants.setdefault(e.dst, []).append((nodes[e.src], nodes[e.src]))
        elif e.kind == "sources" and e.dst and e.src in prms_really_discharged and e.src in nodes:
            claimants.setdefault(e.dst, []).append((nodes[e.src], prm_story.get(e.src)))
    # ADOPTION IS SCOPED TO THE EPIC, never to the project (v10.1 audit).
    #
    # `wiring_adopted` was `any(entry_point for n in nodes.values())` — one flag over the WHOLE
    # project. So the first single `Entry Point` cell a team filled anywhere flipped the gate on for
    # every delivered promise at once, and a project sitting at SHIP-RC dropped to
    # INTEGRATION-GREEN the moment it started adopting. Upgrade day was safe; the FIRST HONEST STEP
    # was the expensive one. A gate whose entire cost lands on the first honest step is a gate
    # people route around — the same failure direction as a rule that teaches you to delete the
    # comment to get green.
    #
    # The epic is the unit because it is already the unit: `gate` scopes its block-vs-guide split
    # exactly here ("rot in an ADOPTED scope BLOCKS; the identical absence in an un-adopted scope
    # GUIDES"), and an epic is the grain a team actually opts in with. Per-claimant adoption was
    # rejected: it would make an EMPTY cell permanently free and a half-filled one the only thing
    # that ever caps, so filling a cell could only ever hurt you — the same perverse polarity,
    # inverted. A threshold-of-N was rejected as a tunable that decays to N = ∞.
    #
    # Consequence, and it is the point: adopting one row in epic A judges epic A and leaves epic B
    # untouched. Both signals can fire in the same run — a P2 cap for the adopted epics and the
    # non-capping P3 for the rest — so the incremental path is legible instead of a cliff.
    def _adoption_scope(n):
        return n.scope
    adopted_scopes = set(_adoption_scope(n) for n in nodes.values()
                         if n.kind in ("prm", "story")
                         and (n.attrs.get("entry_point") or "").strip())
    delivered_promises = [n for n in sorted(nodes.values(), key=lambda x: x.id)
                          if n.kind in ("magic-moment", "job") and n.id in delivered]
    # The resolution pass runs over EVERY adopted claimant, not only the ones the witness loop
    # happens to reach: a promise with two claimants where one cites a phantom file is still
    # carrying a false citation, and reporting it only when the OTHER claimant also fails would
    # make the finding depend on an unrelated row. Memoised because the witness loop asks again.
    contradicted = {}
    for n in sorted(nodes.values(), key=lambda x: x.id):
        if n.kind not in ("prm", "story") or _adoption_scope(n) not in adopted_scopes:
            continue
        bad, why = _claim_contradicted(project_dir, n)
        if bad:
            contradicted[n.id] = why
    if contradicted:
        caps.append("WIRING_UNRESOLVED.P2: %d delivery claim(s) cite something this tree refutes — "
                    "%s%s. Fix the citation or drop it: an unresolvable citation is the one shape "
                    "that survives every rewrite, because nothing can disagree with it."
                    % (len(contradicted),
                       "; ".join("%s %s" % (k, v) for k, v in sorted(contradicted.items())[:3]),
                       ", …" if len(contradicted) > 3 else ""))
        cap_state = _min_readiness(cap_state, "integration-green")
    unwitnessed = []
    unevaluated = []
    for n in delivered_promises:
        promise_claimants = sorted(claimants.get(n.id, []), key=lambda t: t[0].id)
        # A promise is judged only where somebody adopted. With no adopted scope at all, or with
        # every one of this promise's claimants living in un-adopted scopes, reachability is simply
        # NOT EVALUATED — and says so, rather than reporting a false "reachable" or a false cap.
        judged = [(c, s) for (c, s) in promise_claimants
                  if _adoption_scope(c) in adopted_scopes]
        if not adopted_scopes or (promise_claimants and not judged):
            unevaluated.append(n.id)
            continue
        ok = False
        reasons = []
        for claimant, story in judged:
            state, detail = _wiring_claim(claimant)
            if state == "n/a":
                ok = True
                break
            if state == "sited":
                # A citation the tree REFUTES cannot witness anything, even when the story's report
                # dutifully repeats it — two artifacts agreeing about a file that does not exist is
                # exactly the shape the join was built to catch, one level down.
                if claimant.id in contradicted:
                    reasons.append("%s %s" % (claimant.id, contradicted[claimant.id]))
                    continue
                if _witness_cited(detail, story):
                    ok = True
                    break
                reasons.append("%s cites mutation site %s, but %s's validation-report.md records "
                               "no such site" % (claimant.id, detail,
                                                 story.id if story else "the delivering story"))
            else:
                reasons.append("%s %s" % (claimant.id, detail))
        if not ok:
            unwitnessed.append("%s (%s)" % (n.id, reasons[0] if reasons
                                            else "no delivery claimant carries an `entry_point`"))
    if unevaluated:
        caps.append("GRAPH_UNMIGRATED.P3: reachability is NOT evaluated for %d delivered promise(s) "
                    "(%s%s) — no `entry_point` in any epic that claims them yet, so a promise can "
                    "have an OWNER here and still never be reached by a user gesture. Adoption is "
                    "per-EPIC: turn it on for one epic at a time by adding `Entry Point` + `Wiring "
                    "Witness` columns to that epic's traceability matrix, or `entry_point:` / "
                    "`wiring_witness:` to a serving story's frontmatter (`entry_point: n/a — "
                    "<kind>` for a promise whose delivery is not a call). Adopting one epic leaves "
                    "its siblings on this line (does not cap)"
                    % (len(unevaluated), ", ".join(unevaluated[:5]),
                       ", …" if len(unevaluated) > 5 else ""))
    if unwitnessed:
        caps.append("MAPPED_UNWITNESSED.P2: %d/%d delivered promise(s) in ADOPTED epic(s) are "
                    "mapped but NOT witnessed — %s%s. An owner is not a reachable call; bars ux-rc+ "
                    "until each names its production entry point and cites the delete-the-call "
                    "mutation."
                    % (len(unwitnessed), len(delivered_promises) - len(unevaluated),
                       "; ".join(unwitnessed[:3]), ", …" if len(unwitnessed) > 3 else ""))
        cap_state = _min_readiness(cap_state, "integration-green")

    fresh_state, fresh_detail = graph_freshness(project_dir, graph)
    if fresh_state in ("stale", "corrupt"):
        caps.append("GRAPH_STALE.P2: %s" % fresh_detail)
        cap_state = _min_readiness(cap_state, "integration-green")
    elif fresh_state == "unbuilt":
        caps.append("GRAPH_UNBUILT.P3: %s" % fresh_detail)

    # UNMAPPED_PROMISE — conservation anti-join (the graph form of validate-traceability-matrix.sh's
    # DEFAULT-mode open-row check): once an epic has an epic-breakdown.md, every PRM must RESOLVE —
    # have a discharge edge (story+AC), a descoped-by edge (DEC), or pilot-gated status. Resolution is
    # judged by EDGE PRESENCE, not the status label: a `mapped` row (story+AC assigned, pending
    # validation) IS resolved and is fine here — matching the script, which only flags truly-`open`
    # rows in default mode. Pre-breakdown, open rows are allowed (guide-rail). The stricter
    # everything-must-be-terminal check is /epic-validate's job (see MATRIX grain cap).
    discharged_prms = set(e.src for e in edges if e.kind == "discharges")
    descoped_prms = set(e.src for e in edges if e.kind == "descoped-by")
    for n in sorted(nodes.values(), key=lambda x: x.id):
        if n.kind != "prm":
            continue
        status = (n.attrs.get("status") or "").strip().lower()
        # Resolution is judged by EDGE PRESENCE. `mapped` is not a terminal word but carries a
        # discharge edge → resolved. `pilot-gated` is the one status with no edge to point at.
        has_edge = n.id in discharged_prms or n.id in descoped_prms
        if has_edge or status == "pilot-gated":
            continue
        # A terminal WORD with no edge behind it (issue #97): the status is the author's own text,
        # the edge is the artifact. This used to resolve the row in silence — the same class as
        # prose-as-proof, one function over. It does not become a hard block (no migration can
        # invent the missing discharge, and the row may well be honest), but it stops buying green:
        # it caps, loudly, and the message names the cell to fill.
        if status in ("discharged", "descoped"):
            caps.append("STATUS_WITHOUT_EDGE.P2: PRM %s says '%s' but carries no %s edge — fill the "
                        "%s cell for that row in %s (or correct the status). A status WORD is not "
                        "resolution."
                        % (n.id, status,
                           "discharge" if status == "discharged" else "descoped-by",
                           "Discharge (story-id + AC-ref)" if status == "discharged" else "DEC",
                           _rel(n.source_file)))
            cap_state = _min_readiness(cap_state, "integration-green")
            continue
        epic_node = nodes.get(n.scope)
        has_breakdown = bool(epic_node and epic_node.attrs.get("has_breakdown"))
        if has_breakdown:
            findings.append({
                "code": "UNMAPPED_PROMISE.P1", "src": n.id, "edge": "resolves", "ref": n.id,
                "resolved_to": n.id, "source_file": n.source_file,
                "detail": "open promise (status '%s', no discharge and no DEC) after epic-breakdown "
                          "exists — discharge it (story+AC), descope it (DEC), or pilot-gate it. "
                          "Nothing evaporates." % (status or "<blank>"),
            })
        else:
            caps.append("GRAPH_UNMIGRATED.P3: PRM %s is open but epic %s has no breakdown yet "
                        "(open rows allowed pre-breakdown)" % (n.id.split("/")[-1], n.scope))

    # DEP_CYCLE — a depends-on cycle is unbuildable; detect via DFS over resolved depends-on edges.
    dep_adj = {}
    for e in edges:
        if e.kind == "depends-on" and e.dst:
            dep_adj.setdefault(e.src, []).append(e.dst)
    cycle = _find_cycle(dep_adj)
    if cycle:
        findings.append({
            "code": "DEP_CYCLE.P1", "src": cycle[0], "edge": "depends-on", "ref": " → ".join(cycle),
            "resolved_to": cycle[0], "source_file": nodes[cycle[0]].source_file if cycle[0] in nodes else "",
            "detail": "circular dependency: %s — no valid build order exists; break the cycle"
                      % " → ".join(cycle),
        })

    # UNJUDGED_SURFACE (v9.4) — every promised MM-N must have a RECORDED verdict (the excellence
    # machinery ran). Migration-aware: if NO MM anywhere has a verdict yet, LARP simply hasn't run →
    # honest cap, not a block. Once ANY MM is judged, an unjudged MM is a real gap → caps ux-rc+
    # (the /epic-validate gate blocks the ux-rc transition on it). The graph proves a verdict EXISTS;
    # whether it is honest stays with /speck-audit + LARP (the anti-rubber-stamp line).
    judged = set(e.dst for e in edges if e.kind == "judges" and e.dst)
    mm_nodes = [n for n in nodes.values() if n.kind == "magic-moment"]
    if mm_nodes:
        if not judged:
            caps.append("UNJUDGED_SURFACE.P2: %d magic-moment(s) defined, none judged yet — run "
                        "/speck-larp connoisseur Job B (LARP not yet run; honest cap, not a block)" % len(mm_nodes))
            cap_state = _min_readiness(cap_state, "integration-green")
        else:
            unjudged = [n.id for n in mm_nodes if n.id not in judged]
            if unjudged:
                caps.append("UNJUDGED_SURFACE.P2: %d/%d magic-moment(s) have no recorded verdict (%s) — "
                            "/speck-larp Job B judges them; bars ux-rc+ until then"
                            % (len(unjudged), len(mm_nodes), ", ".join(sorted(unjudged)[:5])))
                cap_state = _min_readiness(cap_state, "integration-green")

    # HONEST pending gates — needed data not yet in the graph; never a false pass
    pending = [
        "ORPHAN_CODE: pending tests-as-join (P5) — needs code nodes to prove every code entity "
        "traces to a promise. NOT evaluated (cannot claim 'no orphan code' yet).",
        # The bound on finding 4's three legs, printed rather than left to be rediscovered. The
        # reachability legs prove a citation RESOLVES — a named entry point, a recorded mutation
        # site, and a path/symbol/line this tree does not refute. They do not prove a user gesture
        # arrives there, that the mutation was RUN (mutate-guard.sh --verify-receipt owns that), or
        # that the code is faithful to the promise (#86: not statically decidable). A gate that
        # guessed at those would be worse than the prose it replaces.
        "PROMISE_FIDELITY: NOT evaluated and not decidable here — the graph proves a delivery claim "
        "RESOLVES (entry point named · mutation site recorded · path/symbol/line not refuted by the "
        "tree), never that the gesture reaches it or that the code keeps the promise. Runtime "
        "reach stays with /speck-larp; mutation execution with `mutate-guard.sh --verify-receipt`.",
    ]

    # The exceptions registry, matched LAST so it sees every live finding and cap this run minted.
    invalid_exceptions, accepted_keys = apply_exceptions(
        findings, caps, read_findings_exceptions(project_dir))
    # apply_exceptions annotates matched FINDINGS in place, but caps are plain strings and carry no
    # slot to annotate — so a legitimately accepted cap read as an unhandled one everywhere caps are
    # printed. Mark them here, in the one place that knows the match (#121). Acceptance moves the
    # work order, never the ceiling: cap_state is untouched.
    for i, c in enumerate(caps):
        if finding_key(c.split(":", 1)[0].strip()) in accepted_keys:
            caps[i] = "%s [ACCEPTED: findings-exceptions.md]" % c
    for code, message in invalid_exceptions:
        caps.append("%s: %s" % (code, message))
        cap_state = _min_readiness(cap_state, "integration-green")

    hard = [f for f in findings if f["code"].endswith(".P1")]
    if hard:
        cap_state = "no-ship"
    return findings, caps, pending, cap_state


def cmd_check(project_dir):
    findings, caps, pending, cap_state = check_graph(project_dir)
    hard = [f for f in findings if f["code"].endswith(".P1")]
    # A stale graph is a REPORT ABOUT A DIFFERENT TREE. Two consequences (issue #96 finding 1):
    #   • exit non-zero — `check` used to return `1 if hard else 0`, so `build && check` chains and
    #     CI both read a 142-commits-behind witness as a pass. GRAPH_UNBUILT deliberately does NOT
    #     land here: exiting non-zero on a never-built graph would brick every greenfield project
    #     before it can run `build` / `/speck-migrate`.
    #   • withhold the cap NUMBER — the number is what gets quoted onward into project-state and
    #     pickups, where it outlives the warning printed beside it (brightstance read `SHIP` off a
    #     road that a fresh compile scored NO-SHIP, 227 nodes out of date). Say STALE instead.
    stale = any(c.startswith("GRAPH_STALE") for c in caps)
    sys.stdout.write("Speck Witness Graph — forcing gates (structural: traceable · complete · fresh)\n")
    sys.stdout.write("(faithful · good · excellent are NOT graph-provable — owned by /speck-audit + LARP)\n\n")
    if hard:
        # An ACCEPTED finding still exists and still caps — acceptance moves it in the WORK ORDER,
        # never in the ceiling. But a reader of `check` alone could not tell N unhandled P1s from N
        # accepted-with-authored-why P1s, because the registry match was only visible in `gap`.
        # Say it here too; exit semantics are deliberately unchanged (#121).
        excepted = [f for f in hard if f.get("accepted")]
        if excepted:
            sys.stdout.write("❌ %d hard finding(s) — BLOCK (%d excepted in findings-exceptions.md; "
                             "acceptance moves the work order, never the ceiling):\n\n"
                             % (len(hard), len(excepted)))
        else:
            sys.stdout.write("❌ %d hard finding(s) — BLOCK:\n\n" % len(hard))
        for f in hard:
            mark = "  [ACCEPTED: findings-exceptions.md]" if f.get("accepted") else ""
            sys.stdout.write("  %s  %s%s\n      %s\n      in %s\n\n"
                             % (f["code"], f["ref"], mark, f["detail"], f["source_file"]))
    if caps:
        sys.stdout.write("⚠️  caps (surfaced loud; fold into MAX-claimable at /epic-validate):\n")
        for c in caps:
            sys.stdout.write("  • %s\n" % c)
        sys.stdout.write("\n")
    sys.stdout.write("ℹ️  not-yet-evaluated (honest — never counted as a pass):\n")
    for p in pending:
        sys.stdout.write("  • %s\n" % p)
    if stale:
        sys.stdout.write("\nGRAPH_CAP = STALE (unknowable until rebuilt — the committed witness "
                         "does not match this tree; rebuild, then re-read)\n")
    else:
        sys.stdout.write("\nGRAPH_CAP = %s  (the ceiling this graph can back; caps never grant)\n"
                         % cap_state.upper())
    return 1 if (hard or stale) else 0


# ---------------------------------------------------------------------------
# gate — the SCOPED forcing primitive the lifecycle hooks call (v9).
#
# "You cannot advance if the graph lacks what it needs" — scoped to the work grain so a clean
# sibling is never blocked by unrelated rot, and a rotted story can't hide behind a fresh project.
# The block-vs-guide split is the id-scheme-adoption signal: rot in an ADOPTED scope BLOCKS (.P1);
# the identical absence in an un-adopted scope GUIDES (cap), never blocks. So greenfield work is
# never bricked — "what it needs" is scoped to what the phase's own adopted scheme makes detectable.
# ---------------------------------------------------------------------------

def _in_scope(finding, scope_prefix):
    if scope_prefix is None:
        return True
    for key in ("src", "resolved_to", "ref"):
        v = finding.get(key) or ""
        if v == scope_prefix or v.startswith(scope_prefix + "/"):
            return True
    return False


def gate_graph(project_dir, story=None, epic=None):
    """Scoped forcing check. Returns (blocking_findings, notes). Empty blocking → advance allowed."""
    graph, nodes, edges = build_graph(project_dir)
    g = Graph(nodes, edges)
    scope = None
    if story:
        scope = g.resolve_subject(story) or story
    elif epic:
        scope = canonicalize_epic(epic, build_epic_index([n.id for n in nodes.values() if n.kind == "epic"])) or epic

    findings, unmigrated = lint_refs(nodes, edges)
    blocking = [f for f in findings if f["code"].endswith(".P1") and _in_scope(f, scope)]
    notes = []

    # story reachability — a story must trace UP to a promise ONCE its epic has adopted promises.
    if story and scope in nodes and nodes[scope].kind == "story":
        epic_id = nodes[scope].scope
        epic_has_promises = any(
            n.kind == "prm" and n.scope == epic_id for n in nodes.values()
        ) or any(e.kind == "serves" and nodes.get(e.src) and nodes[e.src].scope == epic_id for e in edges)
        reaches_promise = any(
            e.kind == "discharges" and e.dst and (e.dst == scope or e.dst.startswith(scope + "/"))
            for e in edges
        ) or any(e.kind == "serves" and e.src == scope and e.dst for e in edges)
        if epic_has_promises and not reaches_promise:
            blocking.append({
                "code": "ORPHAN_STORY.P1", "src": scope, "edge": "reaches", "ref": scope,
                "resolved_to": scope, "source_file": nodes[scope].source_file,
                "detail": "story is specified but wired to NO promise — no PRM discharges to it and it "
                          "serves no MM/JOB. Wire it to what it delivers, or it's building the wrong "
                          "thing: add `serves: [MM-N, JOB-N]` to its frontmatter, or give it a "
                          "traceability-matrix row. Since v10 naming an id in PROSE wires nothing — "
                          "run `speck_graph.py migrate <PROJECT_DIR> --lift-serves` to carry pre-v10 "
                          "claims into the frontmatter slot.",
            })
        elif not epic_has_promises:
            notes.append("GRAPH_UNMIGRATED: epic %s has no promise ledger yet — reachability not "
                         "enforced (guide-rail, not a wall). Fill the traceability matrix to force it."
                         % epic_id)
    if unmigrated:
        notes.append("un-adopted id schemes present (%s) — guidance only, not a block"
                     % ", ".join("%d %s" % (v, k) for k, v in sorted(unmigrated.items())))

    # FRESHNESS (issue #96 finding 3) — the lifecycle hooks' first chance to see a stale graph.
    #
    # Reported, never blocking. A blocking freshness gate on every /story-implement would fire on
    # a graph that is stale for a reason nobody in this story caused, and would teach `--no-verify`
    # inside a day — the same failure the SHA-equality rule was rejected for. Guide-rail, not wall:
    # the note names the one command that fixes it, and the FRESH line is printed too so a green
    # gate is legible as "the leg ran" rather than as "the leg is missing" (a silent pass and an
    # unrun check read identically, which is how this leg went unnoticed for a whole major version).
    #
    # Read-only by construction: it compares a signature, it does not rebuild. `gate` writes nothing
    # to the tree, so a read-only CI checkout and any tree-clean assertion survive it untouched.
    fresh_state, fresh_detail = graph_freshness(project_dir, graph)
    if fresh_state == "fresh":
        notes.append("GRAPH_FRESH: %s (freshness computed, not asserted)" % fresh_detail)
    elif fresh_state == "unbuilt":
        notes.append("GRAPH_UNBUILT: %s" % fresh_detail)
    else:
        notes.append("GRAPH_STALE: %s. This gate REPORTS staleness and never blocks on it, and it "
                     "writes nothing — but every cap and count you read out of the committed graph "
                     "until you rebuild is a report about a different tree." % fresh_detail)
    return blocking, notes


def cmd_gate(project_dir, story=None, epic=None):
    blocking, notes = gate_graph(project_dir, story=story, epic=epic)
    label = ("story " + story) if story else (("epic " + epic) if epic else "project")
    if not blocking:
        sys.stdout.write("✅ graph gate (%s): clear to advance\n" % label)
        for n in notes:
            sys.stdout.write("   ℹ️  %s\n" % n)
        return 0
    sys.stdout.write("⛔ graph gate (%s): %d blocking finding(s) — cannot advance until fixed\n\n"
                     % (label, len(blocking)))
    for f in blocking:
        sys.stdout.write("  %s  %s\n      %s\n" % (f["code"], f["ref"], f["detail"]))
    for n in notes:
        sys.stdout.write("   ℹ️  %s\n" % n)
    return 1


# ---------------------------------------------------------------------------
# gap — the DRIVE surface for native /goal (v9). Speck does NOT reimplement /goal's loop; it
# supplies the three things native /goal cannot compute: the completion CONDITION, the evidence
# SURFACE the evaluator reads (this line), and — via AGENTS.md — the per-turn routing. The
# evaluator judges SURFACED text and runs no tools, so `gap` folds the structural remainder +
# report-frontmatter axes into ONE machine-legible `SPECK-GAP:` line. Historical rationale:
# docs/history/north-stars/v9.md §6.
# ---------------------------------------------------------------------------

def _collect_axes(project_dir):
    """Walk validation-report.md frontmatter → aggregate readiness/felt/taste coverage (best-effort)."""
    felt_uncovered = 0
    taste_open = 0
    reports = 0
    axes_absent = 0
    epics_dir = os.path.join(project_dir, "epics")
    if os.path.isdir(epics_dir):
        for ep in sorted(os.listdir(epics_dir)):
            sdir = os.path.join(epics_dir, ep, "stories")
            if not os.path.isdir(sdir):
                continue
            for st in sorted(os.listdir(sdir)):
                rpt = os.path.join(sdir, st, "validation-report.md")
                if not os.path.isfile(rpt):
                    continue
                reports += 1
                fm, _ = strip_frontmatter(read_text(rpt))
                felt = (fm.get("felt_axis", "") or "").lower()
                taste = (fm.get("taste_axis", "") or "").lower()
                if not felt and not taste:
                    axes_absent += 1
                if felt in ("", "uncovered"):
                    felt_uncovered += 1
                if taste in ("uncovered",) or "forks-open" in taste:
                    taste_open += 1
    return {"reports": reports, "felt_uncovered": felt_uncovered,
            "taste_open": taste_open, "axes_absent": axes_absent}


def compute_gap(project_dir):
    """Return a structured gap state folding structural findings + axis coverage + magic/JTBD."""
    findings, caps, pending, cap_state = check_graph(project_dir)
    _graph, nodes, edges = build_graph(project_dir)
    hard = [f for f in findings if f["code"].endswith(".P1")]
    axes = _collect_axes(project_dir)
    mm_total = sum(1 for n in nodes.values() if n.kind == "magic-moment")
    job_total = sum(1 for n in nodes.values() if n.kind == "job")
    judged = set(e.dst for e in edges if e.kind == "judges" and e.dst)
    mm_judged = sum(1 for n in nodes.values() if n.kind == "magic-moment" and n.id in judged)
    phantom = [f for f in hard if f["code"].startswith("PHANTOM_PROMISE")]
    # The work order is COMPUTED by the same function the derived findings view uses, so the item
    # `gap` puts first and the row `findings` puts first are the same row by construction. Exceptions
    # are applied first: an ACCEPTED finding still exists (and still caps), it just stops being the
    # thing the next session is told to do — acceptance moves a finding in the ORDER, never in the
    # ceiling (design invariant §6.4).
    _invalid, accepted_keys = apply_exceptions(
        findings, caps, read_findings_exceptions(project_dir))
    ranked = _ranked_rows(findings, caps, pending, accepted_keys)
    open_ranked = [r for r in ranked if r["state"] == "OPEN"]
    return {
        "cap_state": cap_state,
        "hard": hard,
        "caps": caps,
        "ranked": ranked,
        "open_ranked": open_ranked,
        "next": open_ranked[0]["key"] if open_ranked else "",
        "felt_uncovered": axes["felt_uncovered"],
        "taste_open": axes["taste_open"],
        "reports": axes["reports"],
        "axes_absent": axes["axes_absent"],
        "mm_total": mm_total,
        "mm_judged": mm_judged,
        "job_total": job_total,
        "jtbd_gap": len(phantom) > 0,
    }


GAP_WINDOW = 6          # how many ranked items the token names before it says "+N more"


def _window(keys, limit=GAP_WINDOW):
    """`a, b, c` — and when the list is longer, SAY SO. A silent truncation reads as a total."""
    shown = list(keys)[:limit]
    rest = len(keys) - len(shown)
    return ", ".join(shown) + (" +%d more" % rest if rest > 0 else "")


def gap_line(project_dir):
    """The single evaluator-legible SPECK-GAP: line. Order = the computed work order, see
    `_ranked_rows`: the leftmost item inside each group is the one to do next, and `NEXT=` names it
    outright so the evaluator never has to infer a ranking from a printed list."""
    g = compute_gap(project_dir)
    parts = []
    if g["hard"]:
        hard_keys = [r["key"].replace("@", " ") for r in g["ranked"]
                     if r["origin"] == "finding" and r["severity"] == "P1"]
        parts.append("%d·P1(%s)" % (len(hard_keys), _window(hard_keys)))
    if g["caps"]:
        cap_keys = [r["key"] for r in g["ranked"] if r["origin"] == "cap"]
        parts.append("%d·cap(%s)" % (len(cap_keys), _window(cap_keys, 3)))
    if g["felt_uncovered"]:
        parts.append("FELT:uncovered(%d)" % g["felt_uncovered"])
    if g["taste_open"]:
        parts.append("TASTE:open(%d)" % g["taste_open"])
    if g["mm_total"]:
        parts.append("MM:%d/%d·judged" % (g["mm_judged"], g["mm_total"]))
    parts.append("JTBD:%s" % ("gap" if g["jtbd_gap"] else "ok"))
    if g["axes_absent"]:
        parts.append("axes-absent:%d-reports" % g["axes_absent"])

    done = (not g["hard"] and not g["caps"] and not g["felt_uncovered"]
            and not g["taste_open"] and not g["jtbd_gap"])
    if done and g["mm_total"] == 0:
        # no promises to judge and nothing structural — but a real product should have MMs; stay honest
        return "SPECK-GAP: none-structural — GRAPH_CAP=%s (no MM/JOB defined; verify this is intended)" % g["cap_state"].upper()
    if done:
        return ("SPECK-GAP: none — GRAPH_CAP=%s · structural clear · MM %d/%d judged · JTBD ok"
                % (g["cap_state"].upper(), g["mm_judged"], g["mm_total"]))
    # NEXT= is the whole point of ranking: /goal's iteration policy says "take the single
    # highest-severity unmet item", and until now the evaluator had to infer which one that was from
    # a list printed in mint order. Now the token names it, and it is the same row `findings` puts
    # at the top, because both come out of `_ranked_rows`.
    return ("SPECK-GAP: " + " | ".join(parts) + " | CAP=%s" % g["cap_state"].upper()
            + " | NEXT=%s" % (g["next"] or "none"))


def emit_goal(project_dir, target=None):
    """Emit the ≤4000-char /goal completion CONDITION (Codex's 6 components), for the user to run."""
    g = compute_gap(project_dir)
    tgt = (target or "ship-rc").lower()
    cond = (
        "Drive this Speck project to %s. "
        "OUTCOME: `speck_graph.py check` and `gap` both report SPECK-GAP with no `.P1` and no caps, "
        "every validation-report declares readiness>=%s with felt_axis and taste_axis non-uncovered "
        "and no forks-open, every MM-N observed firing in LARP Job A and judged good in Job B, every "
        "JOB-N served (no PHANTOM_PROMISE), and /speck-audit reports P0=0 P1=0. "
        "VERIFICATION SURFACE: each turn, re-run and print VERBATIM the stdout of "
        "`python3 .speck/scripts/graph/speck_graph.py check %s` and `... gap %s` — the terminating "
        "token is a literal `SPECK-GAP: none` line, never a hand-typed summary. "
        "CONSTRAINTS: never edit witness.json by hand (GRAPH_STALE will catch it — it is derived + "
        "content-hashed); never delete an MM-N/JOB-N to dodge a phantom; every gate (validate, audit, "
        "larp) stays authoritative. "
        "BOUNDARIES: route each unmet gap item through the owning Speck skill, never reimplement one. "
        "ITERATION POLICY: take the item `gap` names in its `NEXT=` token — it is COMPUTED (severity, "
        "then gate code, then subject), so it is the same item every session and the same row "
        "`findings` ranks first; never re-rank it by hand. Close it (untraced/phantom -> the story "
        "chain; audit P0/P1 -> /harden; uncovered FELT / unjudged MM -> /speck-larp; stale -> build), then "
        "re-check before advancing. "
        "BLOCKED STOP: stop and report for an owner decision at any forks-open TASTE, contract/project "
        "pivot, price lock, or deploy. "
        "Or stop after --max-turns turns."
        % (tgt.upper(), tgt, project_dir, project_dir)
    )
    return cond, g


def cmd_gap(project_dir, emit=False, target=None, punch=False):
    if emit:
        cond, _g = emit_goal(project_dir, target)
        sys.stdout.write("# Copy this into native /goal (Claude Code v2.1.139+ or Codex), then pair with auto mode:\n\n")
        sys.stdout.write("/goal " + cond + "\n\n")
        sys.stdout.write("# Speck supplies the CONDITION (above), the EVIDENCE surface (`gap`), and the\n")
        sys.stdout.write("# per-turn routing (AGENTS.md 'Drive to done'). /goal runs the loop — Speck does not.\n")
        return 0
    sys.stdout.write(gap_line(project_dir) + "\n")
    return 0


# ---------------------------------------------------------------------------
# road — the "perfect road to completion" (v9). DERIVED from the graph, never authored.
#
# Re-projects check_graph() into four ORDERED buckets whose sequence IS the dependency order:
# 🧹 TIDY (messy but correct — make it legible) → 🗑 REMOVE (don't build on orphans) →
# 🔨 BUILD (make something to prove) → 🔬 PROVE (climb grain to the ceiling). Each line is
# {node · source · gate-code · resolving-skill}. Disposable: the GRAPH_STALE law applies to the
# road itself (a road disagreeing with a fresh compile is stale), so it never becomes a 9th
# authored copy. It charts what remains AND (via /speck-migrate) heals the road already walked.
# ---------------------------------------------------------------------------

# gate-code → (bucket, resolving-skill). Buckets are ordered; a code not listed defaults to TIDY.
ROAD_ROUTING = {
    "GRAPH_STALE": ("TIDY", "speck_graph.py build"),
    "GRAPH_UNBUILT": ("TIDY", "speck_graph.py build (first build — or /speck-migrate if migrating)"),
    "GRAPH_UNMIGRATED": ("TIDY", "/speck-migrate (graph stage: harden ids) — or fill the promise ledger"),
    "DANGLING_REF": ("TIDY", "fix the reference (repoint or restore the target)"),
    "DUP_ID": ("TIDY", "rename one of the colliding dirs to a free S-number"),
    "DEP_CYCLE": ("TIDY", "break the circular dependency (drop one depends_on edge)"),
    "UNMAPPED_PROMISE": ("BUILD", "discharge it (story+AC), descope it (DEC), or pilot-gate it — no open rows"),
    "ORPHAN_STORY": ("BUILD", "wire the story to a promise (add its PRM row / MM-serve), or descope it"),
    "PHANTOM_PROMISE": ("BUILD", "/story-specify → … → /story-validate the delivering story"),
    "STATUS_WITHOUT_EDGE": ("TIDY", "fill the row's Discharge (story+AC) or DEC cell — the word is not the edge"),
    "UNCLAIMED_MM_REF": ("TIDY", "if the story delivers it, add `serves: [MM-N]` to its frontmatter — else ignore"),
    "HETEROGENEOUS_ID": ("TIDY", "give the §5 heading an `MM-N —` id (`MM-5a` is accepted)"),
    "ORPHAN_CODE": ("REMOVE", "remove the code no promise asked for (or wire it) — pending tests-as-join P5"),
    "PROMISE_FIDELITY": ("PROVE", "/speck-larp Job A+B and /speck-audit — undecidable in the graph; never gate on a guess"),
    "MAPPED_UNWITNESSED": ("PROVE", "name the production `entry_point` and cite the `<path>:<line>` a delete-the-call mutation reddened"),
    "WIRING_UNRESOLVED": ("TIDY", "repoint the citation at the path/symbol/line that really exists — or delete it"),
    "EXCEPTION_PHANTOM": ("TIDY", "delete the row from findings-exceptions.md — the finding it excepts no longer fires"),
    "EXCEPTION_UNJUSTIFIED": ("TIDY", "give the row a posture (ACCEPTED|SUPERSEDED) and a reason an outsider can check"),
    "UNJUDGED_SURFACE": ("PROVE", "/speck-larp connoisseur Job B — judge this surface (pending verdict extraction)"),
    "UNPARSED_VERDICT": ("PROVE", "record it as `- **VERDICT** MM-N = GOOD|BAD` in the validation report"),
    "PRE_V9_PROOF": ("PROVE", "/speck-migrate — re-earn the claim under current evidence"),
    "GRAIN_DEFICIT": ("PROVE", "collect product-grain evidence (cold-start build-LARP) and re-grade the row"),
}
BUCKET_ORDER = ["TIDY", "REMOVE", "BUILD", "PROVE"]
BUCKET_ICON = {"TIDY": "🧹 TIDY", "REMOVE": "🗑 REMOVE", "BUILD": "🔨 BUILD", "PROVE": "🔬 PROVE"}
BUCKET_BLURB = {
    "TIDY": "messy but correct — make the graph legible first (cheapest wins)",
    "REMOVE": "don't build on orphans — deletion is ALWAYS a separate human-confirmed gesture",
    "BUILD": "make the thing the contract promised — weakest-grain / topological first",
    "PROVE": "climb grain toward the ceiling — closest-to-target first lifts GRAPH_CAP fastest",
}


def road_lines(project_dir):
    """Return (buckets: dict[name]->[line dicts], cap_state, blocking_count)."""
    findings, caps, pending, cap_state = check_graph(project_dir)
    buckets = {b: [] for b in BUCKET_ORDER}

    def route(code, node, source, detail):
        root = _code_root(code)
        bucket, skill = ROAD_ROUTING.get(root, ("TIDY", "review"))
        buckets[bucket].append({"code": code, "node": node, "source": source,
                                "skill": skill, "detail": detail})

    for f in findings:
        route(f["code"], f.get("ref", ""), f.get("source_file", ""), f.get("detail", ""))
    # caps carry their code as a prefix "CODE.Pn: text"
    for c in caps:
        code = c.split(":", 1)[0].strip()
        route(code, "", "", c)
    # pending gates render as honest PROVE/REMOVE lines (never a pass)
    for p in pending:
        code = p.split(":", 1)[0].strip()
        route(code, "", "", p)

    blocking = sum(1 for f in findings if f["code"].endswith(".P1"))
    return buckets, cap_state, blocking


def render_road(project_dir):
    buckets, cap_state, blocking = road_lines(project_dir)
    root = _repo_root(project_dir)
    sha = git_head_sha(root) if root else ""
    total = sum(len(v) for v in buckets.values())
    next_action = "ship — no remaining road" if total == 0 else None
    if not next_action:
        for b in BUCKET_ORDER:
            if buckets[b]:
                nb = buckets[b][0]
                next_action = "%s → %s" % (BUCKET_ICON[b], nb["skill"])
                break

    out = []
    out.append("<!-- DERIVED from graph/witness.json by `speck_graph.py road` — NEVER hand-edit. -->")
    out.append("<!-- The GRAPH_STALE law applies to this file: a road disagreeing with a fresh -->")
    out.append("<!-- compile is stale. Regenerate; do not patch. -->")
    out.append("")
    out.append("# Road to Completion — %s" % project_id_of(project_dir))
    out.append("")
    out.append("**GRAPH_CAP** = `%s` (the ceiling the graph can back; caps never grant readiness)  "
               % cap_state.upper())
    out.append("**Blocking** = %d hard `.P1` finding(s) — %s  "
               % (blocking, "clear to advance" if blocking == 0 else "**cannot advance until fixed**"))
    out.append("**Next action** → %s" % (next_action or "—"))
    out.append("")
    out.append("The four buckets are in dependency order: tidy so it's legible → remove so you don't "
               "build on orphans → build so there's something to prove → prove to climb grain. "
               "The graph proves *traceable · complete · fresh* only — *faithful · good · excellent* "
               "stay owned by `/speck-audit` + the four-axis LARP.")
    out.append("")
    for b in BUCKET_ORDER:
        rows = buckets[b]
        out.append("## %s (%d) — %s" % (BUCKET_ICON[b], len(rows), BUCKET_BLURB[b]))
        out.append("")
        if not rows:
            out.append("_clear._")
            out.append("")
            continue
        out.append("| item | where | gate | resolve with |")
        out.append("|------|-------|------|--------------|")
        for r in rows:
            node = r["node"] or "—"
            src = os.path.relpath(r["source"], project_dir) if r["source"] else "—"
            out.append("| `%s` | %s | `%s` | %s |" % (node, src, r["code"], r["skill"]))
        out.append("")
    out.append("*[as of SHA `%s` | derived — regenerate, never hand-edit | speck v9]*" % (sha or "pending"))
    out.append("")
    return "\n".join(out)


def _write_derived(project_dir, filename, text, command):
    """Write a DERIVED view under graph/, degrading to a named error on an unwritable tree.

    The derived surfaces must survive a read-only checkout (`chmod a-w`, a CI checkout mounted
    read-only, a `git worktree` on a read-only volume). They are not on a hook path and every one
    of them has a `--stdout` mode, so an unwritable tree is DEGRADATION, not incorrectness — and
    degradation gets a message, exactly as `graph_freshness` degrades an unreadable witness.json to
    "corrupt" instead of letting the OSError out. A raw Python stack trace is not a message: it
    names no fix, and the fix here (`--stdout`) already exists one flag away.

    Returns the exit code: 0 on success, 1 with the named error on OSError.
    """
    out = os.path.join(project_dir, "graph", filename)
    try:
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w", encoding="utf-8") as fh:
            fh.write(text)
    except OSError as exc:
        sys.stderr.write(
            "⛔ GRAPH_UNWRITABLE: cannot write %s (%s). This tree is read-only, so the derived "
            "view could not be refreshed — the view itself is fine and was computed. Re-run with "
            "`--stdout` to read it without writing: `speck_graph.py %s <PROJECT_DIR> --stdout`\n"
            % (out, exc.strerror or exc, command))
        return 1
    sys.stderr.write("✅ Wrote %s\n" % out)
    return 0


def road_signature(text):
    """Content signature of a rendered road, EXCLUDING the SHA stamp footer.

    The footer carries HEAD, so comparing whole files would be `stamped SHA == HEAD` wearing a
    disguise: it would fire on every non-spec commit in every repo and teach `--no-verify` inside a
    day. What matters is whether the road's ROUTED CONTENT still matches a fresh compile.
    """
    body = [ln for ln in text.splitlines() if not ln.startswith("*[as of SHA")]
    return content_hash("\n".join(body).strip())


def road_freshness(project_dir):
    """Compare the committed road against a fresh render → (state, detail).

    states: `fresh` · `stale` · `absent` (never rendered — not tampering, so it is not a defect).
    """
    path = os.path.join(project_dir, "graph", "road-to-completion.md")
    if not os.path.isfile(path):
        return "absent", ("no committed road-to-completion.md — run `speck_graph.py build` "
                          "(which renders it in the same call)")
    if road_signature(read_text(path)) != road_signature(render_road(project_dir)):
        return "stale", ("graph/road-to-completion.md disagrees with a fresh compile. A stale road "
                         "CANNOT report its own staleness — it was rendered when the graph was "
                         "fresh, so it contains no GRAPH_STALE line by construction, and it opens "
                         "in bold with a cap value that gets quoted onward. Fix: "
                         "`speck_graph.py build <PROJECT_DIR>`")
    return "fresh", "graph/road-to-completion.md matches a fresh compile"


def cmd_road(project_dir, write=True, check=False):
    if check:
        # The READ-SIDE assert (issue #96 finding 2, repair 2). `build` re-renders the road in the
        # same call, so the two artifacts can no longer be separately WRITTEN — this is the other
        # half: a road that disagrees with a fresh compile can be DETECTED, by anything that cares
        # to look, without rebuilding anything.
        state, detail = road_freshness(project_dir)
        icon = {"fresh": "✅", "stale": "⛔", "absent": "ℹ️ "}[state]
        sys.stdout.write("%s ROAD_%s: %s\n" % (icon, state.upper(), detail))
        return 1 if state == "stale" else 0
    text = render_road(project_dir)
    if write:
        return _write_derived(project_dir, "road-to-completion.md", text, "road")
    sys.stdout.write(text)
    return 0


# ---------------------------------------------------------------------------
# findings — the project-level view, DERIVED. See the registry note above apply_exceptions.
# ---------------------------------------------------------------------------

SEVERITY_RANK = {"P1": 0, "P2": 1, "P3": 2}


def _severity_of(code):
    tail = code.rsplit(".", 1)[-1]
    return tail if tail in SEVERITY_RANK else "P3"


# THE ORDER IS THE CONTENT (v10.2, issue #96 items F/H).
#
# `gap` and `findings` both fold structural findings, caps and honest-pending gates into one
# surface, and BOTH are read to decide what the next session works on — /goal's iteration policy
# says "take the single highest-severity unmet item". So the order is not presentation: it is the
# work order. It was mint order — the sequence the gate blocks happen to appear in inside
# check_graph — which meant appending a gate block silently reprioritised every project's next
# session, and `gap`'s six-item window could hide a whole gate code behind seven instances of
# another. Worse, the window truncated without saying so, so "2 shown of 9" read as "2".
#
# ONE ranking function, two consumers, so a derived view cannot drift from the authoritative one
# (#100's law): (severity rank, gate code, subject). The tiebreak is alphabetical on purpose — it is
# arbitrary but STABLE and printable, and a stable arbitrary order beats an unstable meaningful one
# for a token that gets diffed across sessions.
def _ranked_rows(findings, caps, pending, accepted_keys):
    """findings + caps + pending → ONE list of rows in the computed work order."""
    rows = []
    for f in findings:
        rows.append({"key": finding_key(f["code"], f.get("ref", "")), "code": f["code"],
                     "origin": "finding",
                     "severity": _severity_of(f["code"]), "subject": f.get("ref", "") or "—",
                     "where": f.get("source_file", "") or "—",
                     "state": "ACCEPTED" if f.get("accepted") else "OPEN",
                     "note": f.get("accepted") or f.get("detail", "")})
    for c in caps:
        code = c.split(":", 1)[0].strip()
        key = finding_key(code)
        rows.append({"key": key, "code": code, "origin": "cap",
                     "severity": _severity_of(code),
                     "subject": "—", "where": "—",
                     "state": "ACCEPTED" if key in accepted_keys else "OPEN",
                     "note": c.split(":", 1)[1].strip() if ":" in c else c})
    for p in pending:
        code = p.split(":", 1)[0].strip()
        rows.append({"key": finding_key(code), "code": code, "origin": "pending",
                     "severity": "P3", "subject": "—",
                     "where": "—", "state": "NOT-EVALUATED",
                     "note": p.split(":", 1)[1].strip() if ":" in p else p})
    rows.sort(key=lambda r: (SEVERITY_RANK[r["severity"]], r["code"], r["subject"]))
    return rows


def findings_rows(project_dir):
    """Every live finding + cap as one ranked list of rows. Ranking is COMPUTED, never typed."""
    findings, caps, pending, cap_state = check_graph(project_dir)
    exceptions = read_findings_exceptions(project_dir)
    # annotate for display (idempotent — check_graph already ran the same match to mint its caps)
    _invalid, accepted_keys = apply_exceptions(findings, caps, exceptions)
    return _ranked_rows(findings, caps, pending, accepted_keys), cap_state, exceptions


def render_findings(project_dir):
    rows, cap_state, exceptions = findings_rows(project_dir)
    root = _repo_root(project_dir)
    sha = git_head_sha(root) if root else ""
    top = next((r for r in rows if r["state"] == "OPEN"), None)
    out = []
    out.append("<!-- DERIVED from the witness graph by `speck_graph.py findings` — NEVER hand-edit. -->")
    out.append("<!-- The gate-code namespace in speck_graph.py is AUTHORITATIVE; this file is a -->")
    out.append("<!-- projection of it. Per-epic audit reports render FROM this, so a close cannot -->")
    out.append("<!-- be partial. The ONLY authored artifact is findings-exceptions.md, and it -->")
    out.append("<!-- enumerates EXCEPTIONS, never instances. -->")
    out.append("")
    out.append("# Findings — %s" % project_id_of(project_dir))
    out.append("")
    out.append("**Highest open severity** = `%s`%s  "
               % (top["severity"] if top else "none",
                  (" (`%s`)" % top["key"]) if top else ""))
    out.append("**Open** = %d · **accepted** = %d · **not-evaluated** = %d  "
               % (sum(1 for r in rows if r["state"] == "OPEN"),
                  sum(1 for r in rows if r["state"] == "ACCEPTED"),
                  sum(1 for r in rows if r["state"] == "NOT-EVALUATED")))
    out.append("**GRAPH_CAP** = `%s` — acceptance changes the work ORDER, never the ceiling."
               % cap_state.upper())
    out.append("")
    out.append("| # | finding | severity | subject | where | state | note |")
    out.append("|---|---------|----------|---------|-------|-------|------|")
    for i, r in enumerate(rows, 1):
        where = os.path.relpath(r["where"], project_dir) if r["where"] not in ("", "—") else "—"
        out.append("| %d | `%s` | %s | `%s` | %s | %s | %s |"
                   % (i, r["key"], r["severity"], r["subject"], where, r["state"],
                      r["note"].replace("|", "\\|")[:220]))
    out.append("")
    out.append("_Exceptions registered: %d (authored in `findings-exceptions.md`). An exception "
               "whose finding stops firing is a PHANTOM and caps until the row is deleted._"
               % len(exceptions))
    out.append("")
    out.append("*[as of SHA `%s` | derived — regenerate, never hand-edit]*" % (sha or "pending"))
    out.append("")
    return "\n".join(out)


def cmd_findings(project_dir, write=True):
    text = render_findings(project_dir)
    if write:
        return _write_derived(project_dir, "findings.md", text, "findings")
    sys.stdout.write(text)
    return 0


# ---------------------------------------------------------------------------
# readiness — the project-state Readiness State Map, DERIVED (v10.2, issue #96 item E / finding 3).
#
# project-state.md is the single-page agent first-read, and its Readiness State Map is the table a
# fresh agent quotes onward. Every cell in it was hand-typed, including the Proof cell — so the
# gated party authored the gate's input, which is #93 class 2 by construction. The measured cost:
# two consecutive project-states carried a false magic-moment verdict claim and NOTHING could detect
# it, because the claim resolved to nothing. From the commit that finally caught it: "a claim
# repeated across pickups is not evidence."
#
# So the table is COMPUTED here and pasted there:
#   • the ITEM set comes from the graph (story nodes and their epic scopes) — not from a list
#     someone maintains, so a story cannot be omitted from its own status page;
#   • the CLAIM comes from the claim artifact (a story's `readiness_state_verified` frontmatter);
#   • the PROOF is the validation report that exists on disk, pinned at the SHA that last CHANGED
#     it. No report → `none yet`, which is a fact, where an empty cell reads as "someone checked";
#   • a claim the report CONTRADICTS is printed next to the claim, not in a footnote.
#
# STALENESS IS THE CONTENT PREDICATE, never `stamped SHA == HEAD`. A proof is stale when the thing
# it proves CHANGED AFTER it: the spec's last commit is newer than the report's. A project five
# commits behind whose spec nobody touched is FRESH — that counter-example is exactly why the SHA
# rule was rejected for the witness, and the same argument holds one artifact up. With no git there
# is no answer, so the cell says `unknown`, never `no`.
# ---------------------------------------------------------------------------

_GIT_STAMP_CACHE = {}


def _git_file_stamp(root, path):
    """(short_sha, YYYY-MM-DD, unix_ts) of the last commit that CHANGED `path`.

    ("", "", 0) when there is no git, no repo, or the file has never been committed — all three are
    "unknown", and the caller says so rather than inventing a verdict.
    """
    key = ("stamp", root, path)
    if key in _GIT_STAMP_CACHE:
        return _GIT_STAMP_CACHE[key]
    stamp = ("", "", 0)
    if root and path and os.path.exists(path):
        try:
            out = subprocess.check_output(
                ["git", "-C", root, "log", "-1", "--format=%h|%ad|%ct", "--date=short",
                 "--", path],
                stderr=subprocess.DEVNULL).decode().strip()
            if out and "|" in out:
                sha, date, ts = (out.split("|") + ["", "", ""])[:3]
                stamp = (sha, date, int(ts) if ts.isdigit() else 0)
        except (subprocess.CalledProcessError, OSError, ValueError):
            stamp = ("", "", 0)
    _GIT_STAMP_CACHE[key] = stamp
    return stamp


def _git_changed_since(root, since_sha, path):
    """Did any commit AFTER `since_sha` change `path`? → 'yes'/'no'/'unknown'.

    ANCESTRY, not timestamps. Two commits can share a second — the test that pinned this predicate
    committed the report and then the spec inside the same second, and a `%ct` comparison called the
    proof fresh while its subject had visibly moved. `<sha>..HEAD -- <path>` cannot tie.
    """
    key = ("since", root, since_sha, path)
    if key in _GIT_STAMP_CACHE:
        return _GIT_STAMP_CACHE[key]
    answer = "unknown"
    if root and since_sha and path:
        try:
            out = subprocess.check_output(
                ["git", "-C", root, "rev-list", "--count", "%s..HEAD" % since_sha, "--", path],
                stderr=subprocess.DEVNULL).decode().strip()
            if out.isdigit():
                answer = "yes" if int(out) > 0 else "no"
        except (subprocess.CalledProcessError, OSError):
            answer = "unknown"
    _GIT_STAMP_CACHE[key] = answer
    return answer


READINESS_NO_PROOF = "none yet — no validation report"


def _readiness_row(project_dir, root, level, item, claim_file, report_file, claimed):
    """One derived row: {level,item,claimed,proof,verified,stale,note}. Nothing here is typed."""
    rel = lambda p: os.path.relpath(p, project_dir)
    row = {"level": level, "item": item, "claimed": claimed or "unclaimed",
           "proof": READINESS_NO_PROOF, "verified": "—", "stale": "n/a — no proof yet", "note": ""}
    if not report_file or not os.path.isfile(report_file):
        return row
    fm, _body = strip_frontmatter(read_text(report_file))
    recorded = (fm.get("readiness_state_verified", "") or "").strip()
    r_sha, r_date, r_ts = _git_file_stamp(root, report_file)
    row["proof"] = "%s@%s" % (rel(report_file), r_sha or "uncommitted")
    row["verified"] = r_date or "unknown"
    if recorded and claimed and recorded.upper() != claimed.upper():
        # Two artifacts answering the same question differently is the contradiction the whole
        # Contradictions section exists for — surfaced ON the claim, where a reader cannot skip it.
        row["note"] = ("⚠ contradiction: the claim says `%s`, its own proof records `%s`"
                       % (claimed, recorded))
    elif recorded:
        row["claimed"] = recorded
    if not r_sha:
        row["stale"] = "unknown — proof not committed"
        return row
    moved = _git_changed_since(root, r_sha, claim_file) if claim_file else "unknown"
    if moved == "unknown":
        row["stale"] = "unknown — no git history for the claim artifact"
    elif moved == "yes":
        c_sha, _c_date, _c_ts = _git_file_stamp(root, claim_file)
        row["stale"] = "yes — %s changed at %s, after the proof" % (rel(claim_file), c_sha or "HEAD")
    else:
        row["stale"] = "no"
    return row


def readiness_rows(project_dir):
    """The Readiness State Map, derived: one row per project / epic / story node in the graph."""
    _graph, nodes, _edges = build_graph(project_dir)
    root = _repo_root(project_dir)
    rows = [_readiness_row(
        project_dir, root, "Project", project_id_of(project_dir),
        os.path.join(project_dir, "project.md"),
        os.path.join(project_dir, "project-validation-report.md"),
        (strip_frontmatter(read_text(os.path.join(project_dir, "project.md")))[0]
         .get("readiness_state_verified", "") or "").strip())]
    stories = [n for n in sorted(nodes.values(), key=lambda x: x.id) if n.kind == "story"]
    # Epics come from the graph AND from the tree: an epic with no stories yet is precisely the one
    # a status page must show as unproven, and it has no node to be found by.
    epics_dir = os.path.join(project_dir, "epics")
    on_disk = set(d for d in (os.listdir(epics_dir) if os.path.isdir(epics_dir) else [])
                  if os.path.isdir(os.path.join(epics_dir, d)))
    for epic in sorted(set(n.scope for n in stories if n.scope) | on_disk):
        edir = os.path.join(project_dir, "epics", epic)
        rows.append(_readiness_row(
            project_dir, root, "Epic", epic, os.path.join(edir, "epic.md"),
            os.path.join(edir, "epic-validation-report.md"),
            (strip_frontmatter(read_text(os.path.join(edir, "epic.md")))[0]
             .get("readiness_state_verified", "") or "").strip()))
        for n in stories:
            if n.scope != epic:
                continue
            sdir = n.source_file if os.path.isdir(n.source_file) else os.path.dirname(n.source_file)
            rows.append(_readiness_row(
                project_dir, root, "Story", n.id, n.source_file,
                os.path.join(sdir, "validation-report.md"),
                (n.attrs.get("readiness_state_verified", "") or "").strip()))
    return rows


def render_readiness(project_dir):
    rows = readiness_rows(project_dir)
    root = _repo_root(project_dir)
    sha = git_head_sha(root) if root else ""
    proven = sum(1 for r in rows if r["proof"] != READINESS_NO_PROOF)
    contradicted = sum(1 for r in rows if r["note"])
    out = []
    out.append("<!-- DERIVED from the witness graph by `speck_graph.py readiness` — NEVER hand-edit. -->")
    out.append("<!-- Paste this table into project-state.md's Readiness State Map. A hand-authored -->")
    out.append("<!-- Proof column is the gated party authoring the gate's input (#93 class 2): a -->")
    out.append("<!-- verdict with no resolvable proof is not a weaker claim, it is an unfalsifiable -->")
    out.append("<!-- one, and it survives every rewrite. -->")
    out.append("")
    out.append("# Readiness State Map — %s" % project_id_of(project_dir))
    out.append("")
    out.append("**Rows with a resolvable proof** = %d/%d · **claims their own proof contradicts** = %d  "
               % (proven, len(rows), contradicted))
    out.append("**Staleness** = the CONTENT predicate: a proof is stale when the artifact it proves "
               "changed after it. Never `stamped SHA == HEAD` — a project five commits behind whose "
               "spec nobody touched is fresh.")
    out.append("")
    out.append("| Level | Item | Claimed State | Proof | Last Verified | Stale? |")
    out.append("|-------|------|---------------|-------|---------------|--------|")
    for r in rows:
        claimed = r["claimed"] + ((" %s" % r["note"]) if r["note"] else "")
        proof = ("`%s`" % r["proof"]) if r["proof"] != READINESS_NO_PROOF else r["proof"]
        out.append("| %s | `%s` | %s | %s | %s | %s |"
                   % (r["level"], r["item"], claimed, proof, r["verified"], r["stale"]))
    out.append("")
    out.append("*[as of SHA `%s` | derived — regenerate, never hand-edit]*" % (sha or "pending"))
    out.append("")
    return "\n".join(out)


def cmd_readiness(project_dir, write=True):
    text = render_readiness(project_dir)
    if write:
        return _write_derived(project_dir, "readiness-map.md", text, "readiness")
    sys.stdout.write(text)
    return 0


# ---------------------------------------------------------------------------
# migrate — generic identity hardening for ANY existing Speck project
#
# Non-destructive by design: dry-run is the DEFAULT (reports the diff); only `--apply` writes.
# Confident auto-transform: number acceptance scenarios as AC-N (idempotent — existing AC-N
# headings are respected and continue the count). Heterogeneous surfaces (magic moments, jobs)
# are REPORTED for human review, never blindly rewritten — the honest, safe boundary.
# ---------------------------------------------------------------------------

RE_SCENARIO = re.compile(r"^(#{3,4})\s+Scenario:\s*(.*)$")
RE_AC_HEADING = re.compile(r"^(#{3,4})\s+(AC-\d+)\b")


def migrate_ac_numbering(text):
    """Rewrite acceptance-scenario headings to `#### AC-N — <name>`, scoped to §2.

    Returns (new_text, n_changed). Idempotent: an already-migrated file changes 0 lines.
    Numbering runs in document order within the acceptance section; an existing AC-N heading
    adopts its own number and the counter continues from it.
    """
    lines = text.splitlines(keepends=True)
    out = []
    in_acc = False
    counter = 0
    changed = 0
    for line in lines:
        stripped = line.rstrip("\n")
        # section tracking: §2 is the acceptance section
        if re.match(r"^##\s+2[\.\s]", stripped):
            in_acc = True
        elif re.match(r"^##\s+\d", stripped) and not re.match(r"^##\s+2[\.\s]", stripped):
            in_acc = False
        if in_acc:
            m_ac = RE_AC_HEADING.match(stripped)
            if m_ac:
                counter = int(m_ac.group(2).split("-")[1])
                out.append(line)
                continue
            m_sc = RE_SCENARIO.match(stripped)
            if m_sc:
                counter += 1
                nl = "%s AC-%d — %s\n" % (m_sc.group(1), counter, m_sc.group(2).strip())
                out.append(nl)
                changed += 1
                continue
        out.append(line)
    return "".join(out), changed


def report_missing_ids(project_dir):
    """Report surfaces that still need manual id-hardening (never auto-rewritten)."""
    notes = []
    contract = os.path.join(project_dir, "product-contract.md")
    if os.path.isfile(contract):
        text = read_text(contract)
        if not re.search(r"^#{2,4}\s+MM-\d+\b", text, re.MULTILINE):
            # count §5 heading entries that look like magic moments
            n = len(re.findall(r"^#{3,4}\s+(?:Magic Moment|Milestone)", text, re.MULTILINE))
            notes.append("product-contract §5: %d magic-moment heading(s) need `MM-N —` ids "
                         "(review + add manually; heterogeneous headings are not auto-rewritten)" % n)
        if not re.search(r"\bJOB-\d+\b", text):
            notes.append("product-contract §2/§4: JTBD needs a `JOB-1` id (add manually)")
    return notes


# ---------------------------------------------------------------------------
# migrate --lift-serves — carry the pre-#97 prose-derived claims into the structured slot.
#
# WHY THIS CANNOT BE A HARD FLIP. Before this release EVERY `serves` edge in every repo was
# prose-derived (measured: 11 distinct in one repo, 15 in another, 35 in a third). Landing the
# structured rule alone would turn every wired magic moment into `PHANTOM_PROMISE.P1` and every
# wired story into `ORPHAN_STORY.P1` — and ORPHAN_STORY blocks `/story-implement` through
# check-story-prereqs.sh, so it would stop real work in every project on upgrade day. That is a
# worse failure than the bug. So the switch ships with the lift.
#
# WHY DRY-RUN IS THE DEFAULT AND THE LINE IS PRINTED. The whole point of the repair is that a
# human, not a regex, decides what a story claims. The dry-run prints every edge the old extractor
# would have minted WITH its source line, so the author reads what is about to be asserted on their
# behalf. On the measured numbers that review is ~15 lines and ~10 deletions.
#
# WHAT `--write` LIFTS. §1d checklist claims always (in the field, every genuine claim already sat
# there). Loose prose mentions too — EXCEPT lines that read as disclaimers, which are printed as
# SKIP with the reason and left for a human; `--include-disclaimed` forces them in. Writing 10 known
# -false claims into frontmatter because the old extractor believed them would migrate the bug.
# ---------------------------------------------------------------------------

# Lines whose plain reading is "this story does NOT claim these ids". Every one of these shapes was
# observed minting a false edge in a committed graph.
RE_DISCLAIMER = re.compile(
    r"(\bnot\s+claimed\b|\bnone\s+claimed\b|^\s*(?:[-*+]\s*)?\**None\b|\bno\s+magic\s+moment"
    r"|\bnot\s+delivered\s+here\b|\bdelivered\s+(?:and\s+judged\s+)?(?:by|in)\b"
    r"|\bjudged\s+in\b|\bclaimed\s+(?:by|in)\b|\belsewhere\b|\banother\s+(?:epic|story|project)\b)",
    re.IGNORECASE)


def lift_serves_plan(project_dir):
    """Per story spec: what the OLD prose rule claimed, classified, with `path:line` provenance."""
    plans = []
    epics_dir = os.path.join(project_dir, "epics")
    if not os.path.isdir(epics_dir):
        return plans
    for ep in sorted(os.listdir(epics_dir)):
        sdir = os.path.join(epics_dir, ep, "stories")
        if not os.path.isdir(sdir):
            continue
        for st in sorted(os.listdir(sdir)):
            spec = os.path.join(sdir, st, "spec.md")
            if not os.path.isfile(spec):
                continue
            text = read_text(spec)
            fm, _body = strip_frontmatter(text)
            rows = []
            seen = set()
            for lineno, line in content_lines(text, skip_frontmatter=True):
                m = RE_SERVES_CHECKLIST.match(line)
                scan = RE_CODE_SPAN.sub(" ", line)
                for tok in _dedup(RE_PROMISE_ID.findall(scan)):
                    if tok in seen:
                        continue
                    seen.add(tok)
                    if m and m.group(1) == tok:
                        verdict, why = "LIFT", "§1d claim line"
                    elif RE_DISCLAIMER.search(line):
                        verdict, why = "SKIP", "reads as a disclaimer"
                    else:
                        verdict, why = "LIFT", "prose mention"
                    rows.append({"id": tok, "line": lineno, "text": line.strip()[:100],
                                 "verdict": verdict, "why": why})
            plans.append({"spec": spec, "rel": os.path.relpath(spec, project_dir),
                          "rows": rows, "already": "serves" in fm,
                          "has_frontmatter": text.startswith("---")})
    return plans


def insert_serves_frontmatter(text, ids):
    """Add `serves: [...]` to a spec's frontmatter. Returns (new_text, ok). Never overwrites."""
    if not text.startswith("---"):
        return text, False
    end = text.find("\n---", 3)
    if end == -1:
        return text, False
    line = "serves: [%s]   # structured delivery claim (speck v10) — the ONLY source of a `serves` edge\n" % ", ".join(ids)
    return text[:end + 1] + line + text[end + 1:], True


def cmd_lift_serves(project_dir, write=False, include_disclaimed=False):
    plans = lift_serves_plan(project_dir)
    lifted_files = 0
    lifted_ids = 0
    skipped = 0
    for p in plans:
        if not p["rows"]:
            continue
        sys.stdout.write("\n%s\n" % p["rel"])
        if p["already"]:
            sys.stdout.write("  ALREADY structured (`serves:` present) — left alone\n")
            continue
        take = []
        for r in p["rows"]:
            keep = r["verdict"] == "LIFT" or include_disclaimed
            sys.stdout.write("  %-5s %-7s :%-4d %s\n"
                             % ("LIFT" if keep else "SKIP", r["id"], r["line"], r["text"]))
            if not keep:
                sys.stdout.write("        ↳ %s — decide by hand; `--include-disclaimed` forces it\n" % r["why"])
                skipped += 1
            else:
                take.append(r["id"])
        take = _dedup(take)
        if not take:
            continue
        sys.stdout.write("  → serves: [%s]\n" % ", ".join(take))
        if not p["has_frontmatter"]:
            sys.stdout.write("  ⚠️  no frontmatter block — add the key by hand\n")
            continue
        lifted_files += 1
        lifted_ids += len(take)
        if write:
            new_text, ok = insert_serves_frontmatter(read_text(p["spec"]), take)
            if ok:
                with open(p["spec"], "w", encoding="utf-8") as fh:
                    fh.write(new_text)
    mode = "APPLIED" if write else "DRY-RUN (no files written — pass --write to apply)"
    sys.stdout.write("\n%s: %d claim(s) into %d story frontmatter block(s); %d line(s) left for a human.\n"
                     % (mode, lifted_ids, lifted_files, skipped))
    sys.stdout.write("Read every LIFT line above: before v10 a bare mention WAS a claim, so this list "
                     "is what the old extractor asserted on your behalf. Delete what is not a claim.\n")
    if write:
        sys.stdout.write("Next: `speck_graph.py build %s && speck_graph.py check %s`.\n"
                         % (project_dir, project_dir))
    return 0


def cmd_migrate(project_dir, apply=False):
    story_specs = []
    epics_dir = os.path.join(project_dir, "epics")
    if os.path.isdir(epics_dir):
        for ep in sorted(os.listdir(epics_dir)):
            sdir = os.path.join(epics_dir, ep, "stories")
            if os.path.isdir(sdir):
                for st in sorted(os.listdir(sdir)):
                    spec = os.path.join(sdir, st, "spec.md")
                    if os.path.isfile(spec):
                        story_specs.append(spec)
    total_changed = 0
    files_touched = 0
    for spec in story_specs:
        text = read_text(spec)
        new_text, n = migrate_ac_numbering(text)
        if n > 0:
            files_touched += 1
            total_changed += n
            rel = os.path.relpath(spec, project_dir)
            sys.stdout.write("  %s  %s: %d scenario heading(s) → AC-N\n"
                             % ("APPLIED" if apply else "would change", rel, n))
            if apply:
                with open(spec, "w", encoding="utf-8") as fh:
                    fh.write(new_text)
    mode = "APPLIED" if apply else "DRY-RUN (no files written — pass --apply to write)"
    sys.stdout.write("\n%s: %d AC heading(s) across %d file(s).\n"
                     % (mode, total_changed, files_touched))
    notes = report_missing_ids(project_dir)
    if notes:
        sys.stdout.write("\nManual id-hardening still needed (not auto-rewritten):\n")
        for nt in notes:
            sys.stdout.write("  • %s\n" % nt)
    sys.stdout.write("\nNext: run `speck_graph.py lint-refs %s` to confirm anchors resolve.\n"
                     % project_dir)
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _resolve_project_dir(arg):
    if not arg:
        return None
    if os.path.isdir(arg) and os.path.basename(os.path.normpath(arg)):
        return os.path.abspath(arg)
    return None


def _flag_value(args, flag):
    """Return the value following `flag` in args, or None."""
    if flag in args:
        i = args.index(flag)
        if i + 1 < len(args):
            return args[i + 1]
    return None


def cmd_build(project_dir, write=True):
    graph, nodes, edges = build_graph(project_dir)
    if write:
        out = graph_path(project_dir)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w", encoding="utf-8") as fh:
            json.dump(graph, fh, indent=2, sort_keys=False)
            fh.write("\n")
        c = graph["counts"]
        sys.stderr.write("✅ Wrote %s (%d nodes, %d edges, completeness: %s)\n"
                         % (out, c["nodes"], c["edges"], graph["generator_completeness"]))
        # The road is re-rendered in the SAME call, deliberately (issue #96 finding 2).
        #
        # `build` used to write witness.json and nothing else, while three skills and the AGENTS.md
        # preamble all prescribe `build && check` — so an agent following Speck exactly left the
        # most human-readable derived artifact stale. And a stale road CANNOT report its own
        # staleness: it was rendered when the graph was fresh, so it contains no GRAPH_STALE line
        # by construction. One repo's road sat 256 commits behind HEAD and 87 behind the
        # witness.json it claims to derive from, opening in bold with `GRAPH_CAP = SHIP`,
        # `Blocking = 0`. The two artifacts must not be separately committable.
        #
        # Order is load-bearing: witness.json is written FIRST, so the freshness leg inside
        # render_road compares against the file this call just wrote and the road does not embed a
        # GRAPH_STALE line describing the state one line above it.
        cmd_road(project_dir, write=True)
        # Same law, same call, for the readiness map (v10.2, item E): project-state's Readiness
        # State Map is quoted onward exactly as the road is, so a separately-refreshable copy would
        # go stale exactly as the road did. One call refreshes every derived view or none.
        cmd_readiness(project_dir, write=True)
    else:
        json.dump(graph, sys.stdout, indent=2)
        sys.stdout.write("\n")
    return 0


def cmd_lint_refs(project_dir):
    _graph, nodes, edges = build_graph(project_dir)
    findings, unmigrated = lint_refs(nodes, edges)
    # The road assert rides here because `lint-refs` is what the commit path actually calls, and the
    # moment of commit is the moment a stale road starts being quoted onward. It runs BEFORE the
    # clean-exit branch on purpose: a project whose references all resolve is exactly the project
    # whose road nobody has looked at.
    #
    # ADVISORY, DELIBERATELY, and disclosed rather than implied: v10.2's own routing table adds a row
    # to EVERY project's road, so every road committed under v10.1 disagrees with a fresh render on
    # upgrade day. A blocking check here would make the installed base uncommittable until each repo
    # ran `build` — a gate whose entire cost lands on upgrade day is a gate people route around with
    # `--no-verify`, and then it protects nothing. `speck_graph.py road --check` is the same
    # predicate with a real exit code, for a CI step that opts in.
    road_state, road_detail = road_freshness(project_dir)
    if road_state == "stale":
        sys.stdout.write("⚠️  ROAD_STALE (advisory, does not block): %s\n\n" % road_detail)
    if not findings and not unmigrated:
        sys.stdout.write("✅ lint-refs: all cross-references resolve (%d nodes, %d edges)\n"
                         % (len(nodes), len(edges)))
        return 0
    if findings:
        sys.stdout.write("❌ lint-refs: %d real dangling/ambiguous reference(s) (P1)\n\n" % len(findings))
        for f in findings:
            sys.stdout.write("  %s  %s\n      %s\n      in %s\n\n"
                             % (f["code"], f["ref"], f["detail"], f["source_file"]))
    if unmigrated:
        total = sum(unmigrated.values())
        detail = ", ".join("%d %s" % (v, k) for k, v in sorted(unmigrated.items()))
        sys.stdout.write("⚠️  GRAPH_UNMIGRATED.P3: %d reference(s) to id schemes this project "
                         "hasn't adopted yet (%s).\n    Not rot — run the identity migration "
                         "(`speck-graph-migrate.sh`) to harden these anchors.\n\n" % (total, detail))
    # Real dangling refs BLOCK (exit 1); an unadopted scheme alone degrades to honest (exit 0, capped).
    return 1 if findings else 0


USAGE = """speck_graph.py — the Speck Witness Graph

Usage:
  speck_graph.py build     <PROJECT_DIR> [--stdout]   Compile the graph → graph/witness.json
  speck_graph.py lint-refs <PROJECT_DIR>              Fail on any dangling/ambiguous reference
  speck_graph.py migrate   <PROJECT_DIR> [--apply]    Harden ids (AC-N numbering); dry-run by default
  speck_graph.py migrate   <PROJECT_DIR> --lift-serves [--write] [--include-disclaimed]
                                                      v10: lift pre-#97 prose-derived delivery claims
                                                      into story `serves:` frontmatter. DRY-RUN by
                                                      default; prints every claim with its source line.
  speck_graph.py query     <PROJECT_DIR> <node-id>    Raw in/out edges of a node (story, MM-N, DEC…)
  speck_graph.py context   <PROJECT_DIR> <story-id>   The story's context pack — one lookup, no tree walk
  speck_graph.py check     <PROJECT_DIR>              Forcing gates: dangling/dup BLOCK; phantom/stale CAP
  speck_graph.py gate      <PROJECT_DIR> [--story ID|--epic ID]   Scoped advance-gate (exit 1 = blocked)
  speck_graph.py road      <PROJECT_DIR> [--stdout|--check]   The road to completion:
                                                      TIDY→REMOVE→BUILD→PROVE. `--check` asserts the
                                                      COMMITTED road still matches a fresh compile
                                                      (content, never `stamped SHA == HEAD`) and
                                                      exits 1 when it does not.
  speck_graph.py findings  <PROJECT_DIR> [--stdout]   The DERIVED project-level findings view, ranked
                                                      across every epic. The gate-code namespace here
                                                      is authoritative; the only authored artifact is
                                                      findings-exceptions.md (exceptions, never
                                                      instances).
  speck_graph.py readiness <PROJECT_DIR> [--stdout]   The DERIVED Readiness State Map (claim · proof
                                                      · staleness) for project-state.md. Every Proof
                                                      cell is computed; a hand-typed one is the
                                                      gated party authoring the gate's input.
  speck_graph.py gap       <PROJECT_DIR> [--emit-goal] [--target ship-rc|ship]   Drive surface for native /goal
  speck_graph.py cascade   <PROJECT_DIR> --dec DEC-NNNN    Blast radius: still-discharged promises a DEC descopes

PROJECT_DIR is a specs/projects/<id> directory. The graph is DERIVED — never hand-edit witness.json.
"""


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        sys.stdout.write(USAGE)
        return 0
    cmd = argv[1]
    args = argv[2:]
    project_dir = _resolve_project_dir(args[0]) if args else None
    if cmd == "build":
        if not project_dir:
            sys.stderr.write("ERROR: build requires an existing PROJECT_DIR\n")
            return 2
        return cmd_build(project_dir, write="--stdout" not in args)
    if cmd == "lint-refs":
        if not project_dir:
            sys.stderr.write("ERROR: lint-refs requires an existing PROJECT_DIR\n")
            return 2
        return cmd_lint_refs(project_dir)
    if cmd == "migrate":
        if not project_dir:
            sys.stderr.write("ERROR: migrate requires an existing PROJECT_DIR\n")
            return 2
        if "--lift-serves" in args:
            return cmd_lift_serves(project_dir,
                                   write=("--write" in args or "--apply" in args),
                                   include_disclaimed="--include-disclaimed" in args)
        return cmd_migrate(project_dir, apply="--apply" in args)
    if cmd in ("query", "context"):
        if not project_dir or len(args) < 2:
            sys.stderr.write("ERROR: %s requires <PROJECT_DIR> <node-id>\n" % cmd)
            return 2
        subject = args[1]
        return cmd_query(project_dir, subject) if cmd == "query" else cmd_context(project_dir, subject)
    if cmd == "check":
        if not project_dir:
            sys.stderr.write("ERROR: check requires an existing PROJECT_DIR\n")
            return 2
        return cmd_check(project_dir)
    if cmd == "gate":
        if not project_dir:
            sys.stderr.write("ERROR: gate requires an existing PROJECT_DIR\n")
            return 2
        story = _flag_value(args, "--story")
        epic = _flag_value(args, "--epic")
        return cmd_gate(project_dir, story=story, epic=epic)
    if cmd == "road":
        if not project_dir:
            sys.stderr.write("ERROR: road requires an existing PROJECT_DIR\n")
            return 2
        return cmd_road(project_dir, write="--stdout" not in args, check="--check" in args)
    if cmd == "findings":
        if not project_dir:
            sys.stderr.write("ERROR: findings requires an existing PROJECT_DIR\n")
            return 2
        return cmd_findings(project_dir, write="--stdout" not in args)
    if cmd == "readiness":
        if not project_dir:
            sys.stderr.write("ERROR: readiness requires an existing PROJECT_DIR\n")
            return 2
        return cmd_readiness(project_dir, write="--stdout" not in args)
    if cmd == "gap":
        if not project_dir:
            sys.stderr.write("ERROR: gap requires an existing PROJECT_DIR\n")
            return 2
        return cmd_gap(project_dir, emit="--emit-goal" in args, target=_flag_value(args, "--target"))
    if cmd == "cascade":
        dec = _flag_value(args, "--dec")
        if not project_dir or not dec:
            sys.stderr.write("ERROR: cascade requires <PROJECT_DIR> --dec DEC-NNNN\n")
            return 2
        hits = cascade_blast(project_dir, dec)
        if not hits:
            sys.stdout.write("✅ cascade: no still-discharged promise descoped by %s\n" % dec)
            return 0
        sys.stdout.write("⚠️  CASCADE risk: %s descopes %d still-discharged promise(s): %s\n"
                         % (dec, len(hits), ", ".join(hits)))
        return 1
    sys.stderr.write("Unknown command: %s\n\n%s" % (cmd, USAGE))
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
