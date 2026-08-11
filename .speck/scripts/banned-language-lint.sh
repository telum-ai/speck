#!/usr/bin/env bash
# banned-language-lint.sh — Enforce product-contract.md banned language across the codebase
#
# Reads banned terms from `specs/projects/<id>/product-contract.md` Section 7 (Banned Language)
# and greps user-visible surfaces for any matches.
#
# Usage:
#   .speck/scripts/banned-language-lint.sh [--staged] [--exclude-glob GLOB]... [PROJECT_DIR] [TARGET_PATHS...]
#
# Flags:
#   --staged            Scan only git-staged files (for pre-commit).
#   --exclude-glob G    Skip files matching G. Repeatable. ADDITIVE on top of the defaults
#                       and on top of `banned_language.exclude` in .speck/project.json.
#   --advisory-parse-defects
#                       Report an unmatchable §7 term but exit 0. Implied by --staged; passed
#                       explicitly by the lint-staged wrapper, which hands us file paths and
#                       so does NOT take the --staged path. Pre-commit advises, CI enforces.
#   --no-strings-only   Scan WHOLE files, the pre-v10 way. The escape hatch for a codebase
#                       whose user-visible copy lives somewhere the lexer cannot see it.
#
# Config (.speck/project.json, all optional):
#   { "banned_language": {
#       "exclude": ["**/legacy/**"],       # ADDITIVE with the built-in defaults
#       "exclude_defaults": true,          # false → drop the built-ins, own the list outright
#       "scope": "any-depth",              # "any-depth" (default) | "legacy-root"
#       "strings_only": true               # true (default) | false → scan whole files
#   } }
#
# SCOPE MODES
#   any-depth    A directory whose NAME is a product surface is in scope wherever it sits,
#                so a monorepo's `frontend/src/**` and `apps/mobile/src/**` are reached.
#                DEFAULT since v10 (see #98.1 below for why it took a major).
#   legacy-root  Product surfaces are recognised only at the repo ROOT: `src/**`, `app/**`,
#                … exactly as Speck ≤9.5 resolved them. Opt back in via banned_language.scope.
#
# WHAT IS SCANNED INSIDE A FILE (--strings-only, the v10 default)
#   filter-forbidding-context.py builds a per-file VISIBILITY MASK and a hit only counts if
#   the term survives in it: locale VALUES (never keys), string literals, template literals
#   and markup text nodes — never identifiers, imports, comments or type names. Markdown and
#   plain text are user-visible in full and stay whole-file. A file the lexer cannot handle
#   is scanned WHOLE (pre-v10 behaviour, so the mode can never create a blind spot) and
#   counted in SPECK_GATE_UNPARSED, because silently scanning it whole — or silently
#   skipping it — is the failure this whole release is about. A JSX text run the
#   heuristic declines (it holds `; = ( )` outside any `{…}` container) is the third
#   path: neither revealed nor scanned whole. Those are counted per file and published
#   as SPECK_GATE_TEXT_RUNS_REJECTED (#111) — a residual you can see, not a blind spot.
#
# If PROJECT_DIR is omitted, walks up from cwd. If TARGET_PATHS is omitted, the scope mode
# decides which product-surface directories are scanned.
#
# Exit codes:
#   0 = no violations
#   1 = violations found, or (full-scan only) a §7 term that can never match (PARSE DEFECT)
#   2 = invocation error (no product-contract.md, etc.)
#
# THE SCARS THIS FILE CARRIES
#
# #90 — the §7 extractor split column 1 on /[\/,]/ with no paren awareness, so
#       `"sett" (Norwegian for rep/set)` became `sett (Norwegian for rep` + `set)`. Both
#       fragments are unmatchable, the ban silently never fired, and the junk fragment
#       `Safety` convicted 276 unrelated lines. 12 of 64 terms were dead on one project
#       and NOTHING SAID SO — a dead term and a satisfied term produced identical output.
#       Splitting now goes through sp_split_toplevel, and an unmatchable term is a
#       PARSE DEFECT (non-green), not a silent zero.
#
# #98.1 — the --staged branch filtered staged paths against globs anchored at the repo
#       ROOT (src/*|app/*|…), so a monorepo laying out frontend/src/** matched ZERO files
#       and exited 0 green: 0 of 1194 files in one repo, 0 of 590 in another, on a gate
#       wired into every commit. Scope is now matched by PATH SEGMENT and derived ONCE,
#       and every exit path publishes what it actually inspected (SPECK_GATE_*), so a
#       consumer never has to re-derive scope from a second hardcoded list — that
#       duplication is what gave the gate and its own liveness canary a CORRELATED blind
#       spot.
#
#       …and why any-depth was OPT-IN for one minor, and is the DEFAULT from v10. The
#       resolution was always right; what blocked the flip was the OTHER half of the gate.
#       Speck's own product-contract-template.md §7 ships
#           - ❌ Technical architecture language ("our backend", "API", "database")
#       and the phrase-class extractor pulls each quoted phrase, scanned -i -w -F against
#       WHOLE FILES. `frontend/src/lib/client.ts` holding `import { createClient } from
#       "./api"` went from exit 0 to ❌ "API" — 4 hit(s), exit 1. A gate that was green in
#       a downstream repo must not go red on code nobody touched, so v9.6 shipped the
#       resolver opt-in and deferred the flip.
#
#       v10 removes the CAUSE rather than the reach: `--strings-only` filters every hit
#       through a per-file visibility mask, so an import specifier, an identifier and a
#       comment are no longer copy. With the false-conviction class gone, the remaining
#       defect is the more serious one — 0 of 1194 files scanned in one repo and 0 of 590
#       in another, on a gate wired into every commit — so the default flips. Downstream
#       sees it in a diff, not by surprise: the `v10-banned-language-scope-any-depth`
#       migration writes the resolution into .speck/project.json on upgrade day, and a
#       team that needs the old blindness edits one word.
#
# #85 (second cut) — `rg --files` honours .gitignore and `find` does not, so the SAME tree
#       scored SUBJECT=1/exit 0 with ripgrep installed and SUBJECT=2/exit 1 without it. The
#       verdict of a gate must not depend on which binary is on PATH. The fallback is now
#       aligned UP to rg's semantics rather than rg down to find's — that direction can only
#       ever REMOVE files from a scan, so an upgrade cannot turn a green repo red.
#
# The pairing that makes the broadened scope safe: an exclusion mechanism. Reaching
# frontend/src/** also reaches the vocabulary guard whose own regex literals ARE the
# banned words. A gate that convicts its own guard gets disabled, and a disabled gate
# protects nothing. That guard is not a JS/TS thing — Speck ships django-htmx,
# go-templ-htmx, expo-fastapi and react-fastapi-postgres recipes — so the defaults are
# spelled language-agnostically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/lib/text.sh"

# ── Gate output contract (#98 §4) ────────────────────────────────────────────────────
# Three lines, on EVERY exit path including the early ones. PREDICATES is the load-bearing
# one: this gate's vacuity is a dead PREDICATE set, not an empty subject set — it can scan
# 180 files with 12 unmatchable terms and look perfectly healthy.
GATE_SCOPE=""
GATE_SUBJECT=0
GATE_PREDICATES=0
# The two v10 additions. FILTER says which reading of a file produced the verdict;
# UNPARSED is the honesty counter that keeps `strings-only` from being a silent claim —
# it is the number of subject files the lexer could NOT read, which were therefore
# scanned whole. A caller comparing SUBJECT to UNPARSED can see how much of a green
# result rests on the mask and how much on the old whole-file scan.
GATE_FILTER="whole-file"
GATE_UNPARSED=0
# The v10.5 addition (#111). UNPARSED counts files the lexer could not read AT ALL — those are
# scanned whole, so they are covered, just not narrowed. TEXT_RUNS_REJECTED counts something
# UNPARSED structurally could not: a markup text run inside a file that lexed FINE, which the
# JSX heuristic declined to read and which was therefore neither revealed nor scanned whole.
# That third path took neither honest option, and a clean file and an unread one printed the
# same thing. A non-zero value here is a live residual: N runs of user-visible copy that this
# run did not look at.
GATE_TEXT_RUNS_REJECTED=0
TELEMETRY_EMITTED=false
TMP_TERMS=""
TMP_CELLS=""
TMP_LIVE=""
TMP_FILES=""
TMP_FILTER_ERR=""

emit_telemetry() {
  [[ "$TELEMETRY_EMITTED" == true ]] && return 0
  TELEMETRY_EMITTED=true
  echo "SPECK_GATE_SCOPE=$GATE_SCOPE"
  echo "SPECK_GATE_SUBJECT=$GATE_SUBJECT"
  echo "SPECK_GATE_PREDICATES=$GATE_PREDICATES"
  echo "SPECK_GATE_FILTER=$GATE_FILTER"
  echo "SPECK_GATE_UNPARSED=$GATE_UNPARSED"
  echo "SPECK_GATE_TEXT_RUNS_REJECTED=$GATE_TEXT_RUNS_REJECTED"
}

on_exit() {
  emit_telemetry
  local f
  for f in "$TMP_TERMS" "$TMP_CELLS" "$TMP_LIVE" "$TMP_FILES" "$TMP_FILTER_ERR"; do
    [[ -n "$f" ]] && rm -f "$f"
  done
  return 0
}
trap on_exit EXIT

STAGED_MODE=false
ADVISORY_PARSE_DEFECTS=false
PROJECT_DIR=""
EXTRA_ARGS=()
CLI_EXCLUDES=()
STRINGS_ONLY=true
STRINGS_ONLY_CLI=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged)
      STAGED_MODE=true
      ADVISORY_PARSE_DEFECTS=true
      shift
      ;;
    --strings-only)
      STRINGS_ONLY_CLI=true
      shift
      ;;
    --no-strings-only)
      STRINGS_ONLY_CLI=false
      shift
      ;;
    --advisory-parse-defects)
      ADVISORY_PARSE_DEFECTS=true
      shift
      ;;
    --exclude-glob)
      [[ $# -ge 2 ]] || { echo "ERROR: --exclude-glob needs a value" >&2; exit 2; }
      CLI_EXCLUDES+=("$2")
      shift 2
      ;;
    --exclude-glob=*)
      CLI_EXCLUDES+=("${1#--exclude-glob=}")
      shift
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# bash 3.2 + set -u: empty EXTRA_ARGS must not expand as "${EXTRA_ARGS[@]}"
set -- ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}

# Locate project dir
if [[ -z "${1:-}" ]] || [[ "${1:-}" == -* ]]; then
  cur="$(pwd)"
  while [[ "$cur" != "/" ]]; do
    if compgen -G "$cur/specs/projects/*/product-contract.md" >/dev/null 2>&1; then
      PROJECT_DIR="$(echo "$cur"/specs/projects/*/ | head -n1)"
      PROJECT_DIR="${PROJECT_DIR%/}"
      WORKSPACE_ROOT="$cur"
      break
    fi
    cur="$(dirname "$cur")"
  done
  # The lint-staged wrapper calls us as `"" file1 file2 …`: an empty placeholder for the
  # auto-located project dir. Drop it, or it lands in TARGETS and rg/grep is handed "".
  [[ "${1:-}" == "" && $# -gt 0 ]] && shift
else
  PROJECT_DIR="$1"
  shift
  WORKSPACE_ROOT="$(cd "$PROJECT_DIR" && cd ../.. && pwd)"
fi

if [[ -z "${PROJECT_DIR:-}" ]] || [[ ! -d "$PROJECT_DIR" ]]; then
  if [[ "$STAGED_MODE" == true ]]; then
    GATE_SCOPE="not-applicable:no-product-contract"
    echo "✅ No product-contract.md is declared; staged banned-language lint is not applicable."
    exit 0
  fi
  echo "ERROR: Could not locate project directory with product-contract.md." >&2
  exit 2
fi

PRODUCT_CONTRACT="$PROJECT_DIR/product-contract.md"

if [[ ! -f "$PRODUCT_CONTRACT" ]]; then
  echo "ERROR: product-contract.md not found at $PRODUCT_CONTRACT" >&2
  exit 2
fi

# ── Scope, derived ONCE (#98.1) ──────────────────────────────────────────────────────
# One list, consumed by BOTH the --staged filter and the full-scan resolver. The old code
# spelled it twice (:131 and :146) and the two copies had already drifted apart from the
# canary's third copy. Matching is by PATH SEGMENT, so `frontend/src/**` and
# `apps/mobile/src/**` are in scope exactly as `src/**` is.
SCOPE_SEGMENTS=(src app pages components public locales i18n)

# How those segments are matched. "any-depth" is the monorepo-correct resolution and the
# v10 default; "legacy-root" reproduces Speck ≤9.5 byte for byte and is opted back into via
# banned_language.scope. The flip is safe only because --strings-only removed the false
# convictions that made a broadened reach unusable — see #98.1 above.
SCOPE_MODE="any-depth"

# Never scanned, at any depth. `.speck` and `specs` are Speck's own machinery and truth
# docs: §7 legitimately LISTS the banned terms, decision logs discuss them, and templates
# are written about them. Pointing the fallback scan at the workspace root without this
# reported 4025 hits for "plan" on one repo, top hits being story-retro-template.md and
# AGENTS.md — Speck's own artifacts convicting the project. The gate must not convict its
# own guard.
#
# The vendored half of the same rule: .venv / Pods / target / DerivedData carry third-party
# `src` directories full of other people's prose. Once the resolver walks at any depth it
# finds them, and Speck starts linting a dependency's marketing copy as if the team wrote it.
#
# `.cxx` is named here for SPEED, not for correctness — the general rule is the
# dot-directory clause in path_denied below, and that is what a mutation has to break.
# Listing it keeps `find` from descending thousands of CMake object files on every run of
# the gate in any React-Native repo.
DENY_SEGMENTS=(node_modules .git .speck .cursor specs dist build .next out .cache vendor
               .venv venv .tox Pods target .build DerivedData .gradle coverage .cxx)

# Default exclusions (#90 secondary). Test files hold two things this gate cannot tell
# apart from a violation: assertions that a banned word is ABSENT, and a vocabulary guard
# whose regex literals ARE the banned words.
#
# Spelled language-agnostically. The JS/TS-only list ('**/__tests__/**', '**/*.test.*',
# '**/*.spec.*') meant the self-conviction it exists to prevent was live for every other
# language Speck ships a recipe for: app/tests.py, app/test_views.py, src/foo_test.go,
# src/FooTest.java, src/x_spec.rb, src/__mocks__/api.ts and app/e2e/flow.ts were all newly
# scanned the moment v9.6 broadened what the gate reaches.
DEFAULT_EXCLUDES=(
  '**/__tests__/**' '**/*.test.*' '**/*.spec.*'
  '**/test_*.py' '**/tests.py'
  '**/*_test.*' '**/*Test.*' '**/*_spec.*'
  '**/tests/**' '**/test/**' '**/spec/**'
  '**/__mocks__/**' '**/e2e/**'
)

# --- .speck/project.json (walk up from the project dir) -------------------------------
PROJECT_JSON=""
cur="$PROJECT_DIR"
while [[ "$cur" != "/" ]]; do
  if [[ -f "$cur/.speck/project.json" ]]; then
    PROJECT_JSON="$cur/.speck/project.json"
    break
  fi
  cur="$(dirname "$cur")"
done

# One reader, one stream: sentinel lines carry the non-glob settings so the whole
# banned_language block is parsed in a single python3 invocation.
read_config() {
  [[ -n "$PROJECT_JSON" ]] || return 0
  python3 - "$PROJECT_JSON" <<'PY' 2>/dev/null || true
import json, sys
try:
    cfg = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
bl = cfg.get("banned_language") or {}
scope = bl.get("scope")
if isinstance(scope, str) and scope.strip():
    print("__SPECK_SCOPE__" + scope.strip())
if bl.get("strings_only") is False:
    print("__SPECK_WHOLE_FILE__")
if bl.get("exclude_defaults") is False:
    print("__SPECK_DROP_DEFAULTS__")
for g in (bl.get("exclude") or []):
    if isinstance(g, str) and g.strip():
        print(g.strip())
PY
}

EXCLUDE_GLOBS=()
KEEP_DEFAULTS=true
while IFS= read -r g; do
  [[ -z "$g" ]] && continue
  if [[ "$g" == "__SPECK_DROP_DEFAULTS__" ]]; then
    KEEP_DEFAULTS=false
    continue
  fi
  if [[ "$g" == "__SPECK_WHOLE_FILE__" ]]; then
    STRINGS_ONLY=false
    continue
  fi
  if [[ "$g" == __SPECK_SCOPE__* ]]; then
    SCOPE_MODE="${g#__SPECK_SCOPE__}"
    continue
  fi
  EXCLUDE_GLOBS+=("$g")
done < <(read_config)

# The flag is the last word, over config and over the default.
[[ -n "$STRINGS_ONLY_CLI" ]] && STRINGS_ONLY="$STRINGS_ONLY_CLI"

# The mask is built by filter-forbidding-context.py. Without python3 there is no mask —
# and the honest response is to say so and scan whole files, not to quietly report the
# green that an empty filter would produce.
if command -v python3 >/dev/null 2>&1; then
  HAVE_PY3=true
else
  HAVE_PY3=false
  if [[ "$STRINGS_ONLY" == true ]]; then
    echo "⚠️  python3 not found — --strings-only cannot build a visibility mask. Scanning WHOLE files (pre-v10 behaviour); expect hits on identifiers and imports." >&2
    STRINGS_ONLY=false
  fi
fi
FILTER_ARGS=()
if [[ "$STRINGS_ONLY" == true ]]; then
  GATE_FILTER="strings-only"
  FILTER_ARGS=(--strings-only)
else
  GATE_FILTER="whole-file"
fi

# A typo'd scope must not silently pick a mode — that is the same class of hole as a §7 term
# that can never match. Warn loudly and keep the default; failing here would turn a green
# repo red over a config typo, which is exactly what this release is avoiding.
case "$SCOPE_MODE" in
  legacy-root|any-depth) ;;
  *)
    echo "⚠️  banned_language.scope=\"$SCOPE_MODE\" is not recognised (legacy-root|any-depth) — using legacy-root." >&2
    SCOPE_MODE="legacy-root"
    ;;
esac
if [[ "$KEEP_DEFAULTS" == true ]]; then
  EXCLUDE_GLOBS=("${DEFAULT_EXCLUDES[@]}" ${EXCLUDE_GLOBS[@]+"${EXCLUDE_GLOBS[@]}"})
fi
EXCLUDE_GLOBS=(${EXCLUDE_GLOBS[@]+"${EXCLUDE_GLOBS[@]}"} ${CLI_EXCLUDES[@]+"${CLI_EXCLUDES[@]}"})

# scope_glob <segment> — the published form of one scope segment, honest about the mode.
# The telemetry is the only place a consumer can see WHICH resolution ran, so it must not
# print `**/src/**` when the run actually anchored at the root.
scope_glob() {
  if [[ "$SCOPE_MODE" == "any-depth" ]]; then printf '**/%s/**' "$1"; else printf '%s/**' "$1"; fi
}

# path_in_scope <path> — true when the path is a product surface under the active mode.
# Paths arrive repo-relative here (git diff --cached --name-only), so legacy-root anchors
# on the FIRST segment exactly as the pre-9.6 `case "$file" in src/*|app/*|…)` did.
path_in_scope() {
  local p="$1" s
  for s in "${SCOPE_SEGMENTS[@]}"; do
    if [[ "$SCOPE_MODE" == "any-depth" ]]; then
      case "/$p/" in */"$s"/*) return 0 ;; esac
    else
      case "$p" in "$s"/*) return 0 ;; esac
    fi
  done
  return 1
}

# path_denied <path> — true when any SEGMENT is Speck's own machinery, vendored code, or a
# DOT-DIRECTORY. The single chokepoint for "we do not own this": consumed by the scope-root
# resolver AND by both file-filter loops, so a tree that is denied cannot come back as a
# scope root, as a target, or as a subject file.
path_denied() {
  local p="$1" d rel
  for d in "${DENY_SEGMENTS[@]}"; do
    case "/$p/" in */"$d"/*) return 0 ;; esac
  done
  # ── The dot-directory clause (#98.2) ──────────────────────────────────────────────
  # A build cache sitting UNDER a product-surface segment is the general shape, and
  # DENY_SEGMENTS is a list of instances that will always be one name behind. Measured on
  # a real downstream repo: `app` is a scope segment, so `android/app/**` became a scope
  # ROOT under any-depth, and `android/app/.cxx/**` — the CMake object cache — contains
  # directories literally named `src` and `components`, which became scope roots of their
  # own. ~30 of them, 142 compiled `.o` files in the subject set, ❌ "QA" — 58 hit(s),
  # exit 1, on a gate that had been green. Naming `.cxx` fixes that repo; refusing the
  # SHAPE fixes the next one, whatever its cache is called.
  #
  # Relative to WORKSPACE_ROOT, deliberately: a checkout can legitimately LIVE under a
  # dotted path (~/.local/share/…, a `.worktrees/` checkout), and denying a whole tree for
  # where it happens to sit would zero the subject set — the silent vacuity this gate's
  # telemetry exists to make impossible.
  rel="$p"
  case "$rel" in "${WORKSPACE_ROOT:-}"/*) rel="${rel#"${WORKSPACE_ROOT:-}"/}" ;; esac
  # A dot-name is only denied when something follows it: `/src/.eslintrc.js` is a FILE and
  # stays in scope; `/src/.storybook/main.js` sits under a dot-DIRECTORY and does not.
  case "/$rel" in */.[!/]*/*) return 0 ;; esac
  return 1
}

# path_excluded <path> — true when the path matches any configured exclude glob.
# `**` is translated to bash's `*`, which spans "/" inside a `case` pattern; a single `*`
# therefore also spans "/", which is a deliberate over-match in the SAFE direction (a glob
# excludes more, never less, than written).
path_excluded() {
  local p="$1" g pat
  for g in ${EXCLUDE_GLOBS[@]+"${EXCLUDE_GLOBS[@]}"}; do
    pat="${g//\*\*\//*}"
    pat="${pat//\*\*/*}"
    case "$p" in $pat) return 0 ;; esac
  done
  return 1
}

# find_scope_dirs <root> — the product-surface directories to scan under the active mode.
find_scope_dirs() {
  local root="$1" name_args=() prune_args=() s d
  if [[ "$SCOPE_MODE" != "any-depth" ]]; then
    # legacy-root: root-level surfaces only, and nothing when none exist — the caller then
    # falls back to the workspace exactly as Speck ≤9.5 did.
    for s in "${SCOPE_SEGMENTS[@]}"; do
      [[ -d "$root/$s" ]] && printf '%s\n' "$root/$s"
    done
    return 0
  fi
  for s in "${SCOPE_SEGMENTS[@]}"; do name_args+=(-o -name "$s"); done
  for d in "${DENY_SEGMENTS[@]}"; do prune_args+=(-o -name "$d"); done
  # The -prune list is an OPTIMISATION (do not descend). The verdict on each candidate is
  # path_denied's, the same predicate the file loops use — one chokepoint, so a directory
  # cannot be refused as a subject file yet still be published as a Target. Filtering here
  # rather than adding `-name '.?*'` to -prune also keeps the root itself safe: BSD find
  # tests the starting point, GNU's -mindepth is a global option, and a resolver whose
  # answer depends on which find is installed is #85 all over again.
  find "$root" \
    \( "${prune_args[@]:1}" \) -prune -o \
    -type d \( "${name_args[@]:1}" \) -print 2>/dev/null \
    | { while IFS= read -r d; do path_denied "$d" || printf '%s\n' "$d"; done; } \
    | sort || true
}

# ── Resolve targets + publish the scope actually used ────────────────────────────────
SCOPE_GLOBS=()
if [[ "$STAGED_MODE" == true ]]; then
  for s in "${SCOPE_SEGMENTS[@]}"; do SCOPE_GLOBS+=("$(scope_glob "$s")"); done
  TARGETS=()
elif [[ $# -eq 0 ]]; then
  TARGETS=()
  while IFS= read -r d; do
    [[ -n "$d" ]] && TARGETS+=("$d")
  done < <(find_scope_dirs "$WORKSPACE_ROOT")
  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    # No product surface anywhere: fall back to the workspace, minus DENY_SEGMENTS.
    TARGETS=("$WORKSPACE_ROOT")
    SCOPE_GLOBS=("$WORKSPACE_ROOT/**")
  else
    for s in "${SCOPE_SEGMENTS[@]}"; do SCOPE_GLOBS+=("$(scope_glob "$s")"); done
  fi
else
  TARGETS=("$@")
  SCOPE_GLOBS=("$@")
fi

GATE_SCOPE="$(IFS=,; echo "${SCOPE_GLOBS[*]}")"

if command -v rg >/dev/null 2>&1; then
  HAVE_RG=true
else
  HAVE_RG=false
fi

# drop_vcs_ignored — reads paths on stdin, prints the ones git does NOT ignore.
#
# The last thing dividing the two branches (#85, second cut). `rg --files` honours
# .gitignore; `find` does not, so an identical tree with a gitignored file under a scope
# dir scored SUBJECT=1/exit 0 on the rg branch and SUBJECT=2/exit 1 on the fallback. The
# alignment goes fallback→rg, not the reverse: rg is the branch nearly every run takes and
# the one Speck has always shipped, so matching it can only REMOVE files from a scan — an
# upgrade cannot turn a green repo red. `git check-ignore` consults the index, so a TRACKED
# file is never reported ignored, which is exactly rg's rule.
drop_vcs_ignored() {
  local input ign
  input="$(cat)"
  [[ -z "$input" ]] && return 0
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf '%s\n' "$input"; return 0; }
  ign="$(mktemp)"
  # check-ignore exits 1 when nothing matched — a normal outcome here, never a failure.
  printf '%s\n' "$input" | git check-ignore --stdin > "$ign" 2>/dev/null || true
  if [[ -s "$ign" ]]; then
    printf '%s\n' "$input" | grep -vxF -f "$ign" || true
  else
    printf '%s\n' "$input"
  fi
  rm -f "$ign"
}

# enumerate_files <path>… — every textual file under the paths, before scope/exclude
# filtering. rg auto-skips binaries and honours .gitignore; the find fallback prunes the
# same build/vendor dirs AND drops the same gitignored files, so the two branches agree
# (#85 — they must never disagree, or the gate's verdict depends on what is installed).
enumerate_files() {
  local prune_args=() d
  if [[ "$HAVE_RG" == true ]]; then
    rg --files --hidden --no-messages \
      --glob='!{node_modules,.git,vendor,dist,build,.next,out,.cache}/**' "$@" 2>/dev/null || true
  else
    for d in "${DENY_SEGMENTS[@]}"; do prune_args+=(-o -name "$d"); done
    { find "$@" \( "${prune_args[@]:1}" \) -prune -o -type f -print 2>/dev/null || true; } \
      | drop_vcs_ignored
  fi
}

TMP_FILES=$(mktemp)
TMP_FILTER_ERR=$(mktemp)
if [[ "$STAGED_MODE" == true ]]; then
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    path_in_scope "$file" || continue
    path_denied "$file" && continue
    path_excluded "$file" && continue
    [[ -f "$file" ]] && printf '%s\n' "$file"
  done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true) \
    | sort -u > "$TMP_FILES"
else
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    path_denied "$file" && continue
    path_excluded "$file" && continue
    printf '%s\n' "$file"
  done < <(enumerate_files "${TARGETS[@]}") \
    | sort -u > "$TMP_FILES"
fi

GATE_SUBJECT=$(wc -l < "$TMP_FILES" | tr -d ' ')

# ── Parse status of the subject set (the honesty half of --strings-only) ─────────────
# One pass, one python3 invocation, before any term is scanned. A mode that claims to read
# only user-visible text has to be able to say how many files it could not read — otherwise
# "0 hits" means "0 hits in the files I understood" and nobody can tell which files those
# were. unparsed = extension the lexer does not model; degraded = a known type whose lex
# bailed (an unterminated literal, a heredoc, a language we do not implement). BOTH are
# scanned WHOLE, exactly as pre-v10, so this mode cannot create a blind spot — it can only
# fail to narrow one, and then it says so.
UNPARSED_FILES=""
if [[ "$STRINGS_ONLY" == true && "$GATE_SUBJECT" -gt 0 ]]; then
  set +e
  PARSE_REPORT="$(python3 "$SCRIPT_DIR/filter-forbidding-context.py" --parse-report < "$TMP_FILES" 2>"$TMP_FILTER_ERR")"
  report_rc=$?
  set -e
  if [[ $report_rc -ne 0 ]]; then
    # SPECK_GATE_UNPARSED=0 would be a claim this run cannot support, and the same filter
    # is about to decide every hit. Refuse rather than publish an unbacked number.
    echo "❌ The hit filter (filter-forbidding-context.py) could not report parse status (rc=$report_rc)." >&2
    echo "   Refusing to publish SPECK_GATE_UNPARSED=0 for a scan whose files were never read." >&2
    sed 's/^/   /' < "$TMP_FILTER_ERR" >&2
    exit 2
  fi
  UNPARSED_FILES="$(printf '%s\n' "$PARSE_REPORT" | grep -E '^(unparsed|degraded)	' || true)"
  if [[ -n "$UNPARSED_FILES" ]]; then
    GATE_UNPARSED=$(printf '%s\n' "$UNPARSED_FILES" | wc -l | tr -d ' ')
  fi
  # #111 — text runs the JSX heuristic refused, in files that otherwise lexed fine. Name the
  # files: "N runs somewhere" is not actionable, and this residual's whole point is that it
  # can be looked at.
  REJECTED_RUNS="$(printf '%s\n' "$PARSE_REPORT" | grep -E '^text-runs-rejected	' || true)"
  if [[ -n "$REJECTED_RUNS" ]]; then
    GATE_TEXT_RUNS_REJECTED=$(printf '%s\n' "$REJECTED_RUNS" | awk -F'\t' '{s+=$3} END {print s+0}')
    echo "⚠️  ${GATE_TEXT_RUNS_REJECTED} markup text run(s) were NOT read (JSX heuristic declined them):"
    printf '%s\n' "$REJECTED_RUNS" | awk -F'\t' '{printf "     %s (%s run(s))\n", $2, $3}'
    echo "     These are neither revealed nor scanned whole — a term inside them cannot fire."
    echo "     Rewrite the run so its prose sits outside any ; = ( ) characters, or run with --no-strings-only."
  fi
fi

# ── Extract §7 terms ─────────────────────────────────────────────────────────────────
# awk emits RAW column-1 cells; bash normalises each one through lib/text.sh. The split
# has to be paren-aware and the qualifier strip has to accept the bare `(…)` form, and
# neither is expressible in the one-pass awk this used to be (#90a, #90b).
TMP_CELLS=$(mktemp)
awk '
  /^## 7\. Banned Language/ { in_section=1; next }
  /^## [0-9]/ && in_section { in_section=0 }
  in_section && /^\|/ {
    if ($0 ~ /Banned Term/) next
    if ($0 ~ /^\|[ \t-]+\|/) next
    line=$0
    sub(/^\| */, "", line)      # strip leading "| "
    sub(/ *\|.*/, "", line)     # keep ONLY column 1 (never the "Use instead" column)
    if (line ~ /^\[/) next      # skip placeholder rows
    if (line == "") next
    print line
  }
' "$PRODUCT_CONTRACT" > "$TMP_CELLS"

TMP_TERMS=$(mktemp)
while IFS= read -r cell; do
  [[ -z "$cell" ]] && continue
  # Column 1 often holds several phrases: "exposes" / "reveals", or "best/worst" — but a
  # "/" or "," INSIDE the row's parenthetical belongs to the explanation, not to the list.
  while IFS= read -r part; do
    term="$(sp_normalize_term "$part")"
    [[ -z "$term" ]] && continue
    case "$term" in \[*) continue ;; esac
    printf '%s\n' "$term" >> "$TMP_TERMS"
  done < <(sp_split_toplevel "$cell")
done < "$TMP_CELLS"

awk '
  /^### Banned Phrase Classes/ { in_section=1; next }
  /^### / && in_section { in_section=0 }
  in_section && /^- ❌/ {
    line=$0
    sub(/^- ❌[[:space:]]*/, "", line)
    while (match(line, /"[^"]+"/)) {
      phrase = substr(line, RSTART+1, RLENGTH-2)
      print phrase
      line = substr(line, RSTART + RLENGTH)
    }
  }
' "$PRODUCT_CONTRACT" >> "$TMP_TERMS"

# The phrase-class pass appends with >>, so a term written in BOTH the table and the
# phrase classes was scanned twice and every hit double-counted — +16 on the reported
# total for one project (#90c). Dedup is the whole fix.
sort -u "$TMP_TERMS" -o "$TMP_TERMS"

# ── Split terms into PREDICATES (evaluable) and PARSE DEFECTS (unmatchable) ──────────
# The core ask of #90: a term that can never match is a silent hole in the gate, and its
# zero hits are today indistinguishable from compliance.
TMP_LIVE=$(mktemp)
DEAD_TERMS=()
TOTAL_EXTRACTED=0
while IFS= read -r term; do
  [[ -z "$term" ]] && continue
  TOTAL_EXTRACTED=$((TOTAL_EXTRACTED + 1))
  if sp_parens_balanced "$term"; then
    printf '%s\n' "$term" >> "$TMP_LIVE"
  else
    DEAD_TERMS+=("$term")
  fi
done < "$TMP_TERMS"

GATE_PREDICATES=$(wc -l < "$TMP_LIVE" | tr -d ' ')
DEAD_COUNT=${#DEAD_TERMS[@]}

echo "🔍 Banned-language lint — Project: $PROJECT_DIR"
echo "   Terms to check: $GATE_PREDICATES"
if [[ "$STAGED_MODE" == true ]]; then
  echo "   Mode: --staged (pre-commit scoped)"
fi
echo "   Targets: ${TARGETS[*]-(staged)}"
echo "   Files in scan scope: $GATE_SUBJECT"
if [[ "$STRINGS_ONLY" == true ]]; then
  echo "   Reading: user-visible strings only (locale values, string literals, markup text)"
  if [[ "$GATE_UNPARSED" -gt 0 ]]; then
    echo "   ⚠️  $GATE_UNPARSED of $GATE_SUBJECT file(s) could not be lexed — scanned WHOLE, so hits on identifiers/comments are possible:"
    printf '%s\n' "$UNPARSED_FILES" | sp_head 5 | sed 's/^/      /'
    [[ "$GATE_UNPARSED" -gt 5 ]] && echo "      ... ($((GATE_UNPARSED - 5)) more)"
  fi
else
  echo "   Reading: WHOLE files (--no-strings-only / banned_language.strings_only=false)"
fi

if [[ "$TOTAL_EXTRACTED" -eq 0 ]]; then
  echo "⚠️  No banned terms extracted from product-contract.md Section 7."
  echo "    Either the section is empty, or it uses an unrecognized format."
  exit 0
fi

PARSE_DEFECTS=0
if [[ "$DEAD_COUNT" -gt 0 ]]; then
  PARSE_DEFECTS=1
  echo ""
  echo "🧨 $DEAD_COUNT §7 term(s) can NEVER match — this is a PARSE DEFECT, not compliance:"
  for term in "${DEAD_TERMS[@]}"; do
    echo "   ❌ PARSE DEFECT: \"$term\" — unbalanced parentheses."
  done
  echo "   Fix the §7 row so the term survives extraction. Until then that ban is DARK:"
  echo "   it reports zero hits on every run and no violation can ever be found."
fi
echo ""

ANY_VIOLATIONS=0
TOTAL_HITS=0
FIRED=0
ZERO_HIT_TERMS=()

# scan_term <term> — path:line:content for every whole-word, case-insensitive match.
# -F (fixed string) rather than the old hand-rolled sed escape: §7 terms are LITERAL
# phrases, and a half-escaped BRE turns `C++` or `a|b` into a live regex.
#
# EVERY line this returns carries `path:line:` — enforced, not assumed (#98.2). The
# visibility mask is applied PER LINE and keys on the line number, so a hit that arrives
# without one is unfilterable by construction: it is counted raw, exactly the pre-v10
# whole-file conviction the mask exists to end. rg emits precisely such a line for a
# binary file —
#     …/Props.cpp.o: binary file matches (found "\0" byte around offset 7)
# — and that is how 58 compiled CMake objects convicted a real downstream repo on the term
# "QA" while SPECK_GATE_FILTER reported strings-only. Measured on rg 15.1: `--no-binary`
# does NOT suppress the notice for files named explicitly on the command line, so the
# shape is enforced here instead of trusted to a flag. grep's -I already skips binaries,
# so this also keeps the two branches answering identically (#85) rather than making the
# verdict depend on which binary is on PATH.
scan_term() {
  local term="$1"
  if [[ "$HAVE_RG" == true ]]; then
    tr '\n' '\0' < "$TMP_FILES" \
      | xargs -0 rg --no-messages --no-heading --with-filename --line-number --color=never \
          -i -w -F -e "$term" 2>/dev/null \
      | grep -E '^.+:[0-9]+:' || true
  else
    tr '\n' '\0' < "$TMP_FILES" \
      | xargs -0 grep -IHn -i -w -F -e "$term" 2>/dev/null \
      | grep -E '^.+:[0-9]+:' || true
  fi
}

if [[ "$GATE_SUBJECT" -gt 0 ]]; then
  while IFS= read -r term; do
    [[ -z "$term" ]] && continue
    raw_output="$(scan_term "$term")"

    filtered_output=""
    if [[ -n "$raw_output" ]]; then
      if [[ "$HAVE_PY3" == true ]]; then
        # NOT `2>/dev/null || true`. That swallowed a crashing filter into an EMPTY
        # result, and an empty result reads as "term compliant" — a filter failure
        # rendered the whole gate green. A filter that cannot run is an invocation
        # error (exit 2), which is loud, not a pass.
        set +e
        filtered_output=$(printf '%s\n' "$raw_output" \
          | python3 "$SCRIPT_DIR/filter-forbidding-context.py" ${FILTER_ARGS[@]+"${FILTER_ARGS[@]}"} "$term" 2>"$TMP_FILTER_ERR")
        filter_rc=$?
        set -e
        if [[ $filter_rc -ne 0 ]]; then
          echo "❌ The hit filter (filter-forbidding-context.py) failed on term \"$term\" (rc=$filter_rc)." >&2
          echo "   Refusing to report a verdict from an unfiltered scan." >&2
          sed 's/^/   /' < "$TMP_FILTER_ERR" >&2
          exit 2
        fi
      else
        filtered_output="$raw_output"
      fi
    fi

    if [[ -n "$filtered_output" ]]; then
      hits=$(printf '%s\n' "$filtered_output" | wc -l | tr -d ' ')
      TOTAL_HITS=$((TOTAL_HITS + hits))
      FIRED=$((FIRED + 1))
      ANY_VIOLATIONS=1
      echo "❌ \"$term\" — $hits hit(s)"
      # sp_head, never `| head -n 10`: head exits after 10 lines, SIGPIPEs the producer,
      # and under `set -o pipefail` the pipeline reports 141 — killing the run with every
      # remaining term unscanned and the totals line never printed (#98).
      sp_head 10 "$filtered_output" | sed 's/^/      /'
      if [[ $hits -gt 10 ]]; then
        echo "      ... ($((hits - 10)) more)"
      fi
      echo ""
    else
      ZERO_HIT_TERMS+=("$term")
    fi
  done < "$TMP_LIVE"
fi

# ── Term health: zero hits is only evidence when the term COULD have matched ─────────
echo "📋 Term health — evaluated: $GATE_PREDICATES · fired: $FIRED · zero-hit (compliant): ${#ZERO_HIT_TERMS[@]} · could not match: $DEAD_COUNT"
if [[ ${#ZERO_HIT_TERMS[@]} -gt 0 ]]; then
  echo "   zero-hit (compliant): $(IFS=,; echo "${ZERO_HIT_TERMS[*]}")"
fi
if [[ "$DEAD_COUNT" -gt 0 ]]; then
  echo "   could not match (PARSE DEFECT): $(IFS=,; echo "${DEAD_TERMS[*]}")"
fi

if [[ "$GATE_SUBJECT" -eq 0 ]]; then
  if [[ "$STAGED_MODE" == true ]]; then
    # EMPTY-LEGITIMATE: a diff-scoped gate genuinely has no subject on a docs-only commit.
    # The discriminator against EMPTY-VACUOUS is mechanical and lives in the telemetry —
    # SPECK_GATE_SCOPE resolved against the repo, not against the diff.
    echo "✅ No staged product-surface files to scan (--staged)."
  else
    echo "⚠️  Scanned 0 files under the targets — the banned-language gate is inspecting NOTHING. A green result here is meaningless; check the target paths / globs before trusting it."
  fi
fi

if [[ $ANY_VIOLATIONS -eq 1 ]]; then
  echo ""
  echo "📊 Total banned-language hits: $TOTAL_HITS"
  echo ""
  echo "Each hit should be:"
  echo "  1. Replaced with the term in product-contract.md 'Use instead' column"
  echo "  2. OR added as a legitimate exception (rare — usually in error messages from external libs)"
  echo "  (Hits inside 'NOT This' / 'Banned' / 'Avoid' table columns and forbidding blockquotes are auto-ignored.)"
  echo "  (Test files are excluded by default; add more via --exclude-glob or banned_language.exclude.)"
  exit 1
elif [[ $PARSE_DEFECTS -eq 1 ]]; then
  echo ""
  echo "📊 No banned-language hits — but $DEAD_COUNT term(s) could not be evaluated."
  echo "   A gate that reports zero hits for an unmatchable term is reporting a parse defect as a pass."
  # The exit is MODE-AWARE; the diagnostic above is not, and never should be.
  #
  # PARSE_DEFECTS is computed from the CONTRACT, before a single file is scanned, so it
  # fires identically on a commit that touches zero product files. validation/pre-commit-hook.sh
  # runs this with --staged and rejects the commit on non-zero, which made ONE typo'd §7 row
  # enough to render a whole repo uncommittable — including the commit that would fix the
  # row. One field project measured 12 of 64 rows malformed. A pre-commit hook is the wrong
  # place to enforce a defect in a document this commit did not touch: pre-commit ADVISES,
  # the full-scan / CI invocation ENFORCES.
  if [[ "$ADVISORY_PARSE_DEFECTS" == true ]]; then
    echo "   Advisory at pre-commit — the defect is in product-contract.md §7, not in the files"
    echo "   this commit stages. The full-scan / CI run (no --staged) still fails on it."
    exit 0
  fi
  exit 1
else
  echo "✅ No banned-language violations found."
  exit 0
fi
