#!/usr/bin/env bash
# validate-two-carrier.sh — the mechanical slice of issue #103's two-carrier doctrine.
#
# #103: a change whose two halves ride different clocks is destructive only in the interval
# between the two landings, and that interval is invisible because every gate is green on
# both sides of it. The doctrine's own worked example is Speck's §6a gate registry: the
# TABLE'S SCHEMA (its header row / column set) and the SCRIPTS THAT READ IT ship on different
# clocks — the header can gain a column the moment someone edits the table (or the recipe
# that regenerates it), while a reader that parses rows by hard-coded POSITION keeps working
# right up until that column lands, then silently misreads every cell after it (Canary
# re-mapped to Waiver, #98/#header-keyed-6a). A reader that resolves columns by NAME from the
# header row degrades gracefully across that interval — a column insert changes nothing it
# reads; a positional reader is destructive in exactly the window #103 describes.
#
# WHAT THIS CHECKS (the decidable subset — see "WHAT THIS DOES NOT CHECK" below):
#   A shell script that, within a bounded window (EITHER SIDE) of a markdown-pipe-table row
#   extraction (Speck's own `/^\|/`-style filter, or the shell-grep equivalent), pulls a
#   specific column out of those rows by a HARD-CODED INTEGER POSITION (`awk -F'|' '{print $N}'`,
#   `cut -d'|' -fN`, `IFS='|' read -r a b c …` into named scalars, or a literal `${arr[N]}`
#   index) — AND shows no evidence anywhere in the file of resolving that position from the
#   header row's column NAMES first.
#
# THE CHECK READS CODE, NOT PROSE. Every line is comment-stripped (a whole-line `#` comment
# becomes empty; a trailing ` #…` is cut) before ANY evidence is evaluated. This is load-bearing,
# not hygiene: Evidence C used to be a file-wide, case-insensitive keyword co-occurrence
# ((resolve|find|get) AND (header|column)) that never distinguished code from prose, so a single
# line of commentary — `# NOTE: a future version should resolve the header column by name.` —
# exonerated the file. The most likely file to carry exactly that comment is a file whose author
# KNOWS it reads positionally, i.e. precisely the population this gate exists to catch. Evidence C
# is now restricted to two CODE shapes: (C1) a function DEFINITION whose name binds a resolution
# verb to a header/column noun (`resolve_columns_from_header() {`, `get_col_index() {`), (C2) an
# INVOCATION of such a name at a command position, or (C3) the concrete inline idiom — a cell
# lowercased with `tr '[:upper:]' '[:lower:]'`, `case`-matched, and assigning a `COL*`/`*_index`
# variable from a loop variable — the shape Speck's own header-keyed readers use. Prose cannot
# produce any of the three.
#
# THE WINDOW IS BIDIRECTIONAL (±WINDOW lines), not forward-only. A forward-only window silently
# exempted the most idiomatic bash shape there is: `while IFS= read -r row; do … done < <(… awk
# '/^\|/{print}')` puts the row extractor BELOW the positional pull. That is not hypothetical —
# validate-coverage-matrix.sh in this very repo pulls `$10`/`$11` at lines 45-46 with its `/^\|/`
# extraction at line 59, and the forward-only version reported it as a table reader and CLEARED it.
# It is now a RED fixture in validate-two-carrier.test.sh.
#
# The window (rather than "anywhere in the file") is deliberate: a script can legitimately contain
# an UNRELATED, single-clock, same-file pipe-delimited format elsewhere (its own internal
# producer/consumer protocol, never committed as a standalone artifact) — positional access to
# THAT is not a two-carrier hazard, because both ends of it ship atomically as one file.
#
# WHAT THIS DOES NOT CHECK (disclosed, not silently skipped — #103's own standard: a
# disclosed gap beats a fabricated proof):
#   - "Two deploy paths with different latencies" (a push-triggered job vs. a nightly, a fast
#     app deploy vs. a manual DB step) — #103's OTHER worked shape. Deciding whether such an
#     interval is inert or destructive needs to know what the slow carrier actually DOES with
#     what the fast carrier shipped, which is a semantic/business judgment ("does this deploy
#     target degrade gracefully") no syntactic scanner can make. A check that fired on every
#     two-cadence CI setup would convict routine expand/contract migrations — the exact
#     over-correction #103's bounding exception warns against. Left to the pattern doc's
#     discriminator questions for a human to answer, not mechanized here.
#   - Non-pipe-delimited table formats (CSV/TSV/YAML lists parsed positionally), and row
#     extraction done via sed/perl/python rather than awk/grep. The historical instances this
#     check is grounded in (#98, #header-keyed-6a) are all markdown pipe-tables read by
#     bash/awk — Speck's own idiom family. Widening the surface without a second grounded
#     instance would fall short of the "twice, syntactically decidable" bar
#     `class-gate-not-a-third-fix.md` sets for a new gate.
#   - Whether a header-NAME resolution function is actually CORRECT — only whether one is
#     present at all (Evidence C is presence, not a proof of correctness).
#
# Usage:  validate-two-carrier.sh [--strict] <file-or-dir>
# Exit:   0 = no findings (or findings without --strict); 1 = findings under --strict;
#         2 = invocation error.
#
# Every exit path emits SPECK_GATE_SCOPE / SPECK_GATE_SUBJECT / SPECK_GATE_PREDICATES /
# SPECK_GATE_MODE (the v10 gate-telemetry contract) so a caller can tell "scanned N files, M
# were table-readers, 0 were positional" apart from "scanned nothing."

set -euo pipefail

GATE_SCOPE="none"
FILES_SCANNED=0
TABLE_READERS=0
TELEMETRY_EMITTED=false
emit_gate_telemetry() {
  [[ "$TELEMETRY_EMITTED" == true ]] && return 0
  TELEMETRY_EMITTED=true
  echo "SPECK_GATE_SCOPE=$GATE_SCOPE"
  echo "SPECK_GATE_SUBJECT=$FILES_SCANNED"
  echo "SPECK_GATE_PREDICATES=$TABLE_READERS"
  echo "SPECK_GATE_MODE=static"
}
trap emit_gate_telemetry EXIT

STRICT_MODE=false
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT_MODE=true; shift ;;
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[[ -z "$TARGET" ]] && TARGET="."
if [[ ! -e "$TARGET" ]]; then
  echo -e "\033[0;31mERROR: target '$TARGET' not found.\033[0m" >&2
  exit 2
fi

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

FILELIST=$(mktemp)
SCAN_AWK=$(mktemp)
trap 'rm -f "$FILELIST" "$SCAN_AWK"; emit_gate_telemetry' EXIT

if [[ -f "$TARGET" ]]; then
  GATE_SCOPE="$TARGET"
  printf '%s\n' "$TARGET" > "$FILELIST"
else
  GATE_SCOPE="$TARGET/**/*.sh"
  find "$TARGET" -type d \( -name node_modules -o -name .git -o -name .venv -o -name venv \
                             -o -name dist -o -name build -o -name vendor \) -prune -o \
       -type f -name '*.sh' -print 2>/dev/null | sort > "$FILELIST"
fi
FILES_SCANNED=$(wc -l < "$FILELIST" | tr -d ' ')

# --- the per-file scanner, one awk pass, no shell pipeline/pipefail exposure ----------------
# WHY ONE AWK PASS AND NOT A BASH PIPELINE: an earlier draft strung grep/cut through a bash
# pipeline under `set -o pipefail`; a "no match" (exit 1) from a NON-final stage still makes
# the whole pipeline report non-zero even when the final stage (e.g. `sort`) succeeds — the
# exact trap `.speck/scripts/lib/text.sh` exists to close. A single awk pass has one exit
# status, decided explicitly by this program (always 0 — the verdict is read from STDOUT, not
# from $?), never from an intermediate stage's "found nothing."
#
# STDOUT CONTRACT (first line, always exactly one of):
#   NOT_A_TABLE_READER     — Evidence A never fired. Not counted in SPECK_GATE_PREDICATES.
#   TABLE_READER_CLEAN     — Evidence A fired at least once; no positional pull in-window, or a
#                             positional pull was found but header-name resolution is present.
#   VIOLATION              — Evidence A fired, a positional pull was found in-window, and no
#                             header-name resolution was found anywhere in the file. Remaining
#                             lines are the matched "NR: line" evidence for the report.
cat > "$SCAN_AWK" <<'AWK'
# strip_comment — this check reads CODE, not prose. A whole-line comment becomes empty; a
# trailing comment (a `#` at a word boundary, i.e. preceded by a space or tab) is cut. `$#`
# and `${#a[@]}` survive because the `#` there is preceded by `$`/`{`, never by whitespace.
function strip_comment(s,   i) {
  if (s ~ /^[ \t]*#/) return ""
  i = index(s, " #");  if (i > 0) s = substr(s, 1, i - 1)
  i = index(s, "\t#"); if (i > 0) s = substr(s, 1, i - 1)
  return s
}

# is_resolver_name — does this IDENTIFIER bind a resolution verb to a header/column noun?
# The noun must be a whole segment (end-of-name, or followed by `_`), so `get_color` /
# `getcolor` do NOT qualify while `getcolumn` / `get_col_index` / `column_index` do. An
# identifier is required: prose ("resolve the header column by name") cannot produce one.
function is_resolver_name(s) {
  if (s ~ /^(resolve|find|get|fetch|lookup|locate|detect|map|parse|read)([a-z0-9]*_)*(header|headers|column|columns|col|cols)(_[a-z0-9_]*)?$/) return 1
  if (s ~ /^(header|headers|column|columns|col|cols)([a-z0-9]*_)*_?(index|indices|indexes|idx|resolve|resolver|lookup|map|pos|position|number|num)([a-z0-9_]*)?$/) return 1
  return 0
}

BEGIN {
  # WINDOW bounds how far a positional pull may sit from its table's row extraction, IN EITHER
  # DIRECTION, and still be attributed to it. It is a bounded-blast-radius default, NOT an
  # empirically pinned optimum, and this file does not claim otherwise:
  #   • LOWER bound, earned: the real pre-fix bug (validate-gate-liveness.sh at 0e7ae68^ —
  #     extraction at line 60, positional pulls at 155-158, a gap of 95) must fall INSIDE.
  #     Test 1 of the test suite is that file, fetched from git, and is RED.
  #   • UPPER bound, NOT earned by any in-repo negative control. The obvious candidate —
  #     gate-liveness-probe.sh's unrelated internal `ext|rel|fp` pipe protocol, ~195 lines from
  #     that file's own §6a extraction — does not in fact constrain WINDOW, because that file is
  #     exonerated by Evidence C (it defines and calls resolve_columns_from_header) no matter
  #     what WINDOW is; setting WINDOW=100000 and rescanning it changes nothing. So 150 is
  #     chosen as "comfortably above the one measured true positive, comfortably below a
  #     whole-file scan", and the false NEGATIVE beyond it is a disclosed, unmeasured cost.
  # Finding the TRUE enclosing block would need a real parser this script deliberately doesn't
  # have — see the header's "WHAT THIS DOES NOT CHECK".
  WINDOW = 150
  a_ever = 0
  na = 0
  nb = 0
  c_found = 0
  tr_seen = 0
  case_seen = 0
  n_blines = 0
}
{
  code = strip_comment($0)
  low = tolower(code)

  # --- Evidence A: a markdown pipe-table row filter. Line numbers recorded for a ±WINDOW
  # ---             proximity test in END (a forward-only countdown missed `done < <(… awk
  # ---             '/^\|/{print}')`, where the extractor sits BELOW the positional pull).
  if (index(code, "/^\\|/") > 0 ||
      index(code, "grep -E '^\\|'") > 0 ||
      index(code, "grep -E \"^\\|\"") > 0) { a_ever = 1; na++; alines[na] = NR }

  # --- Evidence C (file-wide): header-NAME resolution present somewhere, as CODE -----------
  # C1: a function DEFINITION whose name is a resolver name.
  if (match(code, /^[ \t]*(function[ \t]+)?[A-Za-z_][A-Za-z0-9_]*[ \t]*\(\)/)) {
    fn = code
    sub(/^[ \t]*/, "", fn)
    sub(/^function[ \t]+/, "", fn)
    sub(/[ \t]*\(\).*$/, "", fn)
    if (is_resolver_name(tolower(fn))) c_found = 1
  }
  # C2: an INVOCATION of a resolver name at a command position. Statement separators are
  #     normalised to newlines, then only the FIRST WORD of each segment is considered — so
  #     the name has to be in command position, not merely mentioned somewhere on the line.
  seg = code
  gsub(/[;&|(){}`]/, "\n", seg)
  nseg = split(seg, parts, "\n")
  for (si = 1; si <= nseg; si++) {
    w = parts[si]
    sub(/^[ \t"'!]+/, "", w)
    sub(/[^A-Za-z0-9_].*$/, "", w)
    if (w != "" && is_resolver_name(tolower(w))) c_found = 1
  }
  # C3: the inline idiom — lowercase a cell with `tr`, `case`-match it, and assign a
  #     COL*/…_index variable FROM A VARIABLE (the loop index). All three shapes required.
  if (index(code, "[:upper:]") > 0 && index(code, "[:lower:]") > 0 && index(low, "tr") > 0) tr_seen = 1
  if (tr_seen && match(code, /^[ \t]*case[ \t]/)) case_seen = 1
  if (tr_seen && case_seen &&
      match(low, /(^|[ \t;)])[a-z_]*(col|column|columns|idx|index)[a-z0-9_]*[ \t]*=[ \t]*\$[A-Za-z_{]/)) c_found = 1

  # --- Evidence B: a hard-coded integer position. Recorded unconditionally here; attributed
  # ---             to an Evidence-A site by the ±WINDOW proximity test in END.
  hit = 0
  if ((index(code, "-F'|'") > 0 || index(code, "-F\"|\"") > 0) && match(code, /\$[0-9]+/)) hit = 1
  if ((index(code, "-d'|'") > 0 || index(code, "-d\"|\"") > 0) && match(code, /-f[ \t]*[0-9]+/)) hit = 1
  if ((index(code, "IFS='|'") > 0 || index(code, "IFS=\"|\"") > 0) &&
      match(code, /read[ \t]+-r[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]+[A-Za-z_]/) &&
      index(code, " -a ") == 0) hit = 1
  if (match(code, /\$\{[A-Za-z_][A-Za-z0-9_]*\[[0-9]+\]\}/)) hit = 1
  if (hit) { nb++; bnum[nb] = NR; btext[nb] = NR ": " $0 }
}
END {
  b_found = 0
  for (j = 1; j <= nb; j++) {
    for (i = 1; i <= na; i++) {
      d = bnum[j] - alines[i]
      if (d < 0) d = -d
      if (d <= WINDOW) { b_found = 1; n_blines++; blines[n_blines] = btext[j]; break }
    }
  }
  if (!a_ever) {
    print "NOT_A_TABLE_READER"
  } else if (b_found && !c_found) {
    print "VIOLATION"
    for (k = 1; k <= n_blines; k++) print blines[k]
  } else {
    print "TABLE_READER_CLEAN"
  }
}
AWK

echo -e "${BLUE}🔎 Scanning for positional readers of markdown pipe-tables (#103 two-carrier check)...${NC}"
echo "   scope: $GATE_SCOPE"

violations=0
report=""

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  [[ -f "$f" ]] || continue

  result="$(awk -f "$SCAN_AWK" "$f" 2>/dev/null)"
  verdict="$(printf '%s\n' "$result" | head -n1)"

  if [[ "$verdict" == "NOT_A_TABLE_READER" ]]; then
    continue
  fi
  TABLE_READERS=$((TABLE_READERS + 1))
  if [[ "$verdict" == "TABLE_READER_CLEAN" ]]; then
    continue
  fi

  # verdict == VIOLATION
  violations=$((violations + 1))
  matches="$(printf '%s\n' "$result" | tail -n +2)"
  report="${report}
${RED}❌ POSITIONAL_TABLE_READ.P1${NC}: $f reads a markdown pipe-table (\`/^\\|/\`-style row
   extraction) and pulls specific columns by HARD-CODED POSITION within that extraction's
   neighbourhood, with no header-name resolution anywhere in the file. A column inserted into
   the table's schema on its own clock silently re-maps every field this script reads — the
   #103 interval is destructive here, not merely short.
   FIX: resolve the column index from the header row's NAME first (see
   validate-gate-liveness.sh's split_row/resolve_columns_from_header for the reference
   shape), falling back to a named, disclosed positional layout only for a legacy table that
   predates the header. Matching line(s):
$(printf '%s\n' "$matches" | sed 's/^/   /')"
done < "$FILELIST"

if [[ $violations -gt 0 ]]; then
  echo -e "$report"
  echo ""
  echo -e "${RED}Found $violations positional-table-read violation(s) across $TABLE_READERS table-reading file(s) (of $FILES_SCANNED scanned).${NC}"
else
  echo -e "${GREEN}✅ No positional pipe-table readers found ($TABLE_READERS table-reading file(s) of $FILES_SCANNED scanned, all header-resolved or non-positional).${NC}"
fi

if [[ "$STRICT_MODE" == true && $violations -gt 0 ]]; then
  emit_gate_telemetry
  exit 1
fi

emit_gate_telemetry
exit 0
