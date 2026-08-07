#!/usr/bin/env bash
# validate-story-tasks.test.sh — tests for the story tasks validator (#107).
#
# WHY THIS FILE DID NOT EXIST UNTIL NOW, which is most of the story.
# validate-story-tasks.sh shipped for eleven minor versions with no suite at all, and the defect it
# carried was a COUNTING bug that reached the field as a WRONG VERDICT: a tasks.md with 18 tasks, 5
# of them `[!]` BLOCKED, reported "13 of 13 complete · Ready for /story-validate". The blocked tasks
# did not read as incomplete — the total was counted with the character class `[ xX]`, so a `[!]`
# line matched neither the numerator nor the denominator and was ERASED from both.
#
# An orchestrator trusting that line advances a story whose acceptance-critical work is explicitly
# blocked, and nothing anywhere prints differently. That is the dark-gate shape, and an untested
# validator is where it lives, because a green with no suite is indistinguishable from a green that
# had nothing to catch.
#
# The fixture rule here is therefore: vary the MARKER, which is the one input the validator was
# wrong about and the one input its (nonexistent) tests would never have varied.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
# The mutation hook, same convention as the sibling suites: point it at a scratch copy with a fix
# reverted to confirm an assertion actually goes red.
VAL="${SPECK_VALIDATOR_UNDER_TEST:-$ROOT/.speck/scripts/validation/validators/validate-story-tasks.sh}"

FAILED=0
OUT=""
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

run() { RC=0; OUT=$(bash "$VAL" "$@" 2>&1) || RC=$?; }

# mktasks <file> <n_done> <n_blocked> <n_pending> [extra marker line]
mktasks() {
  local f="$1" done_n="$2" blocked_n="$3" pending_n="$4" extra="${5-}" i n=0
  { printf -- '---\nstatus: in_progress\n---\n\n### Phase 1: Setup\n\n'
    for ((i=0; i<done_n; i++));    do n=$((n+1)); printf -- '- [x] T%03d Completed thing %d\n' "$n" "$n"; done
    for ((i=0; i<blocked_n; i++)); do n=$((n+1)); printf -- '- [!] T%03d Blocked thing %d\n' "$n" "$n"; done
    for ((i=0; i<pending_n; i++)); do n=$((n+1)); printf -- '- [ ] T%03d Pending thing %d\n' "$n" "$n"; done
    [[ -n "$extra" ]] && printf -- '%s\n' "$extra"
    printf -- '\n'
  } > "$f"
}

echo "── #107: the reported defect, verbatim ──────────────────────────────────────────────────────"

# THE HEADLINE. 18 tasks, 13 done, 5 blocked — the exact E000/S004 shape from the field report.
mktasks "$T/repro.md" 13 5 0
run "$T/repro.md"
{ grep -q "Has 18 task(s)" <<<"$OUT" && ! grep -q "Ready for /story-validate" <<<"$OUT"; } \
  && pass "18 tasks / 13 done / 5 blocked counts 18 and does NOT report Ready" \
  || fail "the #107 repro still overstates (rc=$RC)"

run "$T/repro.md"
grep -q "5 blocked" <<<"$OUT" \
  && pass "the blocked count is reported as its own number, not folded into 'completed'" \
  || fail "blocked tasks are not surfaced distinctly"

# Blocked work must be nameable, not just countable — a count tells you to look, the list tells you
# where. The load-bearing task in the field report was one of the five that had vanished.
run "$T/repro.md"
grep -q "T014" <<<"$OUT" \
  && pass "each blocked task is named in the output" \
  || fail "blocked tasks are counted but not listed"

# --strict is the mode a gate runs in, so that is the mode where a blocked task must be an error.
run --strict "$T/repro.md"
[[ "$RC" == 1 ]] \
  && pass "--strict exits 1 when any task is blocked" \
  || fail "--strict must reject a story with blocked tasks (rc=$RC)"

# …and non-strict must stay advisory, because validate-template.sh routes editor-hook runs here on
# every save. A blocked task mid-implementation is a normal state to be told about, not to be
# stopped by, and a validator that errors on every keystroke gets switched off.
run "$T/repro.md"
[[ "$RC" == 0 ]] \
  && pass "non-strict stays advisory (blocked is a warning, not an error)" \
  || fail "non-strict must not fail on blocked tasks (rc=$RC)"

echo "── the verdict boundary ─────────────────────────────────────────────────────────────────────"

# The honest green still has to be reachable, or the fix has just moved the lie to the other side.
mktasks "$T/alldone.md" 6 0 0
run "$T/alldone.md"
{ [[ "$RC" == 0 ]] && grep -q "Ready for /story-validate" <<<"$OUT"; } \
  && pass "a genuinely complete story still reports Ready" \
  || fail "a fully complete story must still be Ready (rc=$RC)"

# One blocked task among otherwise-complete work is the nastiest case: the percentage rounds to 100
# in the old arithmetic and the story looks finished.
mktasks "$T/onedblocked.md" 9 1 0
run "$T/onedblocked.md"
{ ! grep -q "Ready for /story-validate" <<<"$OUT" && grep -q "NOT ready" <<<"$OUT"; } \
  && pass "a single blocked task among 9 complete blocks the Ready verdict and says why" \
  || fail "one blocked task must defeat Ready"

mktasks "$T/pending.md" 4 0 4
run "$T/pending.md"
{ grep -q "Has 8 task(s)" <<<"$OUT" && grep -q "50% complete" <<<"$OUT"; } \
  && pass "ordinary pending tasks are unaffected: 8 counted, 50%" \
  || fail "the plain [ ] path regressed"

echo "── unknown markers: named, never silently absorbed ──────────────────────────────────────────"

# A marker the validator has never seen must change the count it cannot be dropped from — that is
# the whole class of #107, and `[!]` was itself an undocumented field convention before this fix.
mktasks "$T/unknown.md" 2 0 0 "- [~] T003 Half-done thing"
run "$T/unknown.md"
{ grep -q "Has 3 task(s)" <<<"$OUT" && grep -q "does not recognise" <<<"$OUT"; } \
  && pass "an unrecognised [~] marker enters the denominator AND is named" \
  || fail "unknown markers must not vanish (rc=$RC)"

run "$T/unknown.md"
! grep -q "Ready for /story-validate" <<<"$OUT" \
  && pass "an unrecognised marker counts as incomplete, so Ready is withheld" \
  || fail "an unknown marker must not read as complete"

echo "── mutation proofs (each assertion, proven red against a reverted copy) ──────────────────────"

MUT="$T/mutant.sh"
mkmut() {
  local label="$1" from="$2" to="$3"
  if ! grep -qF "$from" "$VAL"; then
    echo "  ✗ $label: mutation site not found — the control is dead, not passing"; FAILED=1; return 1
  fi
  python3 - "$VAL" "$MUT" "$from" "$to" <<'PY'
import sys
src=open(sys.argv[1]).read()
open(sys.argv[2],'w').write(src.replace(sys.argv[3], sys.argv[4], 1))
PY
  return 0
}
runmut() { MRC=0; MOUT=$(bash "$MUT" "$@" 2>&1) || MRC=$?; }

# M1 — restore the original denominator character class, and nothing else. The five blocked tasks
# must vanish from the count: 18 tasks read as 13.
#
# Worth recording what this control taught when it was first written asserting the "Ready" line
# instead: it went RED, because the blocked guard alone still withheld the verdict. That is the
# defense-in-depth working — neither fix depends on the other — so the two failures are proven
# separately here (M1 = the erasure, M1b = the verdict) rather than conflated into one assertion
# that passes for whichever reason happens to fire first.
DENOM_FIXED='total_tasks=$(echo "$content" | grep -E -c "^- \[.\] T[0-9]+")'
DENOM_OLD='total_tasks=$(echo "$content" | grep -E -c "^- \[[ xX]\] T[0-9]+")'
if mkmut "M1 original denominator" "$DENOM_FIXED" "$DENOM_OLD"; then
  runmut "$T/repro.md"
  grep -q "Has 13 task(s)" <<<"$MOUT" \
    && pass "M1: the original [ xX] class erases the 5 blocked tasks (18 counts as 13)" \
    || { OUT="$MOUT"; fail "M1 mutant should under-count to 13 (rc=$MRC)"; }
fi

# M1b — the field bug in full: the old denominator AND no blocked guard. This is the exact line the
# orchestrator on E000/S004 read and acted on.
if mkmut "M1b field bug" "$DENOM_FIXED" "$DENOM_OLD"; then
  python3 - "$MUT" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old='''if [ "$blocked_tasks" -gt 0 ]; then
      log_success "Progress: $completion_pct% complete ($completed_tasks/$total_tasks) — NOT ready: $blocked_tasks blocked"
    elif [ "$completion_pct" -eq 100 ]; then'''
new='''if false; then
      :
    elif [ "$completion_pct" -eq 100 ]; then'''
assert old in s, "M1b second mutation site not found"
open(p,'w').write(s.replace(old,new,1))
PY
  runmut "$T/repro.md"
  { grep -q "Has 13 task(s)" <<<"$MOUT" && grep -q "Ready for /story-validate" <<<"$MOUT"; } \
    && pass "M1b: both reverts together reproduce the field report verbatim (13 of 13, Ready)" \
    || { OUT="$MOUT"; fail "M1b mutant should print the exact field bug (rc=$MRC)"; }
fi

# M2 — drop the blocked guard on the verdict. Proves the guard is load-bearing on its own and not
# merely shadowed by the corrected percentage.
if mkmut "M2 unguarded verdict" \
    'if [ "$blocked_tasks" -gt 0 ]; then
      log_success "Progress: $completion_pct% complete ($completed_tasks/$total_tasks) — NOT ready: $blocked_tasks blocked"
    elif [ "$completion_pct" -eq 100 ]; then' \
    'if false; then
      :
    elif [ "$completion_pct" -eq 100 ]; then'; then
  runmut "$T/onedblocked.md"
  ! grep -q "NOT ready" <<<"$MOUT" \
    && pass "M2: removing the blocked guard drops the NOT-ready verdict" \
    || { OUT="$MOUT"; fail "M2 mutant should lose the NOT-ready line (rc=$MRC)"; }
fi

# M3 — make blocked tasks advisory even under --strict. The gate must go quiet.
if mkmut "M3 strict no longer errors" \
    'if [ "$strict" = true ]; then
      log_error "$blocked_tasks task(s) marked BLOCKED' \
    'if false; then
      log_error "$blocked_tasks task(s) marked BLOCKED'; then
  runmut --strict "$T/repro.md"
  [[ "$MRC" == 0 ]] \
    && pass "M3: a non-erroring strict path lets the blocked story through at exit 0" \
    || { OUT="$MOUT"; fail "M3 mutant should exit 0 (rc=$MRC)"; }
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ validate-story-tasks: all tests passed"
else
  echo "❌ validate-story-tasks: FAILURES"
  exit 1
fi
