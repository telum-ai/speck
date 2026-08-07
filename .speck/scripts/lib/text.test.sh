#!/usr/bin/env bash
# text.test.sh — tests for the shared shell text primitives.
#
# Deliberately runs under `set -euo pipefail`, because pipefail semantics ARE the class
# of bug this library exists to retire. A test that passes only with errexit off would
# not be testing the thing.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
# shellcheck source=/dev/null
. "$ROOT/.speck/scripts/lib/text.sh"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "      expected: [${2-}]"; echo "      actual:   [${3-}]"; FAILED=1; }
eq() { # eq <label> <expected> <actual>
  if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi
}

echo "── sp_trim"
eq "trims both ends"                "hello"          "$(sp_trim "   hello   ")"
eq "leaves inner whitespace alone"  "a  b"           "$(sp_trim "  a  b  ")"
eq "empty stays empty"              ""               "$(sp_trim "   ")"
eq "no-op on clean input"           "x"              "$(sp_trim "x")"

# The regression that motivated the library: xargs treats an apostrophe as an
# unterminated quote and exits 1, which under `set -e` kills the whole validator.
eq "survives a lone apostrophe"     "it's a test"    "$(sp_trim "  it's a test  ")"
eq "survives a lone double quote"   'say "hi'        "$(sp_trim '  say "hi  ')"
# xargs would also DESTROY these on its success path, not merely fail on them.
eq "preserves quotes verbatim"      '"quoted"'       "$(sp_trim '  "quoted"  ')"
eq "preserves backslashes"          'a\b\c'          "$(sp_trim '  a\b\c  ')"
eq "preserves an apostrophe path"   "o'brien/x.svg"  "$(sp_trim "  o'brien/x.svg  ")"

echo "── sp_head (must not SIGPIPE its producer under pipefail)"
seq_out="$(seq 1 100 | sp_head 3)"
eq "takes the first n lines"        "1
2
3"                                                   "$seq_out"
# The real assertion: the pipeline's exit status is 0, not 141. `head` would have
# SIGPIPEd `seq` here and pipefail would surface 141, aborting the caller.
if seq 1 100000 | sp_head 2 >/dev/null; then
  pass "pipeline exits 0 on a large producer (no SIGPIPE)"
else
  fail "pipeline exits 0 on a large producer (no SIGPIPE)" "0" "$?"
fi
eq "accepts a string argument"      "a"              "$(sp_head 1 "a
b")"

echo "── sp_split_toplevel"
eq "splits on a top-level slash"    "exposes
reveals"                                             "$(sp_split_toplevel 'exposes/reveals')"
eq "splits on a top-level comma"    "a
b"                                                   "$(sp_split_toplevel 'a,b')"
# The #90 headline: a slash inside the explanatory parenthetical is NOT a delimiter.
eq "slash inside parens is not a split" '"sett" (Norwegian for rep/set)' \
   "$(sp_split_toplevel '"sett" (Norwegian for rep/set)')"
eq "comma inside parens is not a split" 'absolutes ("100% safe", "clinically proven")' \
   "$(sp_split_toplevel 'absolutes ("100% safe", "clinically proven")')"
eq "splits outside, keeps inside"   "Safety
efficacy absolutes (\"100% safe\", \"clinically proven\")" \
   "$(sp_split_toplevel 'Safety/efficacy absolutes ("100% safe", "clinically proven")')"
eq "nested parens tracked"          'a (b (c/d) e)'  "$(sp_split_toplevel 'a (b (c/d) e)')"

echo "── sp_strip_qualifier"
# Single responsibility: it removes the qualifier and nothing else. Quote/backtick
# decoration is sp_strip_decoration's job; callers compose the two.
eq "strips a bare parenthetical"    '"therapy"'      "$(sp_strip_qualifier '"therapy" (as a claim)' )"
eq "strips an italic parenthetical" "host"           "$(sp_strip_qualifier 'host *(in the UI)*')"
eq "strips one with a slash inside" "session"        "$(sp_strip_qualifier 'session (in marketing/primary UI)')"
eq "leaves a term with no qualifier" "revolutionize" "$(sp_strip_qualifier 'revolutionize')"
# An UNBALANCED trailing group is a parse defect upstream — leave it so the caller can
# report it, rather than silently swallowing evidence that the split went wrong.
eq "leaves an unbalanced group in place" "sett (Norwegian for rep" \
   "$(sp_strip_qualifier 'sett (Norwegian for rep')"

echo "── sp_strip_decoration / sp_normalize_term"
eq "strips double quotes"           "therapy"        "$(sp_strip_decoration '"therapy"')"
eq "strips code backticks"          "host"           "$(sp_strip_decoration '`host`')"
# End-to-end on the four §7 rows from #90 that produced unmatchable terms in the field.
eq "normalizes a quoted+qualified row" "therapy"     "$(sp_normalize_term '"therapy" (as a claim)')"
eq "normalizes the Norwegian row"      "sett"        "$(sp_normalize_term '"sett" (Norwegian for rep/set)')"
eq "normalizes the marketing row"      "session"     "$(sp_normalize_term '"session" (in marketing/primary UI)')"
eq "normalizes a backticked row"       "host"        "$(sp_normalize_term '`host`')"
eq "leaves a plain term alone"         "revolutionize" "$(sp_normalize_term 'revolutionize')"
# Every normalized term must be balanced — that is the property the dead-term diagnostic
# downstream relies on, so assert it here rather than trusting it.
for row in '"therapy" (as a claim)' '"sett" (Norwegian for rep/set)' '"session" (in marketing/primary UI)'; do
  t="$(sp_normalize_term "$row")"
  sp_parens_balanced "$t" && pass "normalized term is balanced: $t" || fail "normalized term is balanced: $t" "balanced" "$t"
done

echo "── sp_parens_balanced"
sp_parens_balanced "plain"                  && pass "plain term is balanced"        || fail "plain term is balanced"
sp_parens_balanced "a (b) c"                && pass "matched pair is balanced"      || fail "matched pair is balanced"
sp_parens_balanced "a (b (c) d)"            && pass "nested pair is balanced"       || fail "nested pair is balanced"
sp_parens_balanced "sett (Norwegian for rep" && fail "unbalanced open is caught" "nonzero" "zero" || pass "unbalanced open is caught"
sp_parens_balanced "set)"                   && fail "unbalanced close is caught" "nonzero" "zero" || pass "unbalanced close is caught"

echo "── sp_row_protect / sp_row_restore (escaped pipes, #118)"
row='| PRM-9 | src | a \| b | S1 | — | backing | impl-green | discharged |'
protected="$(sp_row_protect "$row")"
IFS='|' read -r -a raw <<< "$protected"
# 8 real columns + the empty field before the leading pipe = 9. Unprotected this is 10.
eq "escaped pipe no longer splits" "9" "${#raw[@]}"
eq "the cell holding it is intact" "a | b" "$(sp_row_restore "$(sp_trim "${raw[3]}")")"
eq "the column AFTER it is not shifted" "backing" "$(sp_trim "${raw[6]}")"
eq "Status still reads Status" "discharged" "$(sp_trim "${raw[8]}")"
# Plain (unescaped) pipes must still be delimiters — protection must not swallow the table.
IFS='|' read -r -a plain <<< "$(sp_row_protect '| a | b | c |')"
eq "plain pipes still delimit" "4" "${#plain[@]}"
eq "round-trip is byte-identical" 'x \| y' "$(sp_row_restore "$(sp_row_protect 'x \| y')" | sed 's/|/\\|/')"

echo "── sp_match_exact"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
printf 'table:orders\ntable:users\ntype:event_type\n' > "$TMP/catalog"
sp_match_exact "table:orders" "$TMP/catalog" && pass "exact token matches" || fail "exact token matches"
# The substring false-PASS this primitive exists to prevent.
sp_match_exact "table:order" "$TMP/catalog" && fail "prefix must NOT match" "no match" "matched" || pass "prefix does not match (no substring false-pass)"
# A regex metacharacter must be inert, not live.
printf 'a.c\n' > "$TMP/meta"
sp_match_exact "abc" "$TMP/meta" && fail "dot is literal, not any-char" "no match" "matched" || pass "regex metacharacters are inert"
sp_match_exact "a.c" "$TMP/meta" && pass "literal dot matches itself" || fail "literal dot matches itself"

if [[ "$FAILED" == 0 ]]; then
  echo "✅ text.sh: all tests passed"
else
  echo "❌ text.sh: FAILURES"
  exit 1
fi
