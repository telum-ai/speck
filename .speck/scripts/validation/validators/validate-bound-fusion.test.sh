#!/usr/bin/env bash
# validate-bound-fusion.test.sh — tests for the #93 class-3 check (a QUALITY bound fused to an
# EXISTENCE bound).
#
# FIXTURES ARE TEMPLATE-DERIVED, NOT HAND-TYPED. Every scratch tree below starts as a byte copy of
# the SHIPPED `.speck/templates/story/validation-report-template.md` and the SHIPPED validators,
# and is then mutated by exactly one edit. This repo has twice shipped a rule that passed on every
# real artifact while a hand-written fixture went green, because the fixture and the real thing had
# drifted; a fixture that IS the real thing minus one token cannot drift.
#
# NO `sed -i`. BSD sed requires an argument to -i, GNU sed forbids one — an assertion pinned to
# that difference is red against a correct implementation on someone else's machine. Every mutation
# below is `sed 'expr' in > out`, which behaves identically on both.
#
# EVERY MUTATION IS COUNT-VERIFIED. A sed expression that silently matched nothing produces an
# unmutated fixture, and the "RED" assertion that follows would then be measuring the control. Each
# mutation asserts its own match count before the verdict is read.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-bound-fusion.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0

# Build a scratch tree that is a byte-for-byte copy of the shipped machinery.
mk_tree() {
  local dest="$1"
  mkdir -p "$dest/.speck/scripts/validation/validators" "$dest/.speck/templates/story"
  cp "$ROOT/.speck/templates/story/validation-report-template.md" "$dest/.speck/templates/story/"
  cp "$ROOT"/.speck/scripts/validation/validators/*.sh "$dest/.speck/scripts/validation/validators/"
}

# Rewrite a file in place via a temp, asserting the expression actually matched N lines.
mutate() {
  local file="$1" expr="$2" want="$3" label="$4"
  local before after
  cp "$file" "$file.orig"
  sed "$expr" "$file.orig" > "$file"
  before="$(cmp -s "$file.orig" "$file" && echo same || echo differs)"
  after="$(diff "$file.orig" "$file" | grep -c '^>' || true)"
  rm -f "$file.orig"
  if [[ "$before" == "same" ]]; then
    echo "ERROR: mutation '$label' changed nothing — the fixture is the CONTROL, so the assertion"
    echo "       that follows would prove nothing. Fix the expression."
    fails=$((fails + 1))
    return 1
  fi
  # `want` is an exact count where the count is load-bearing (one `case` arm, one frontmatter
  # line — if a second one appears, the fixture no longer isolates what the test names), or "+"
  # where the mutation deliberately sweeps prose whose line count is incidental to the template's
  # wording and would turn this suite red on an unrelated doc edit.
  if [[ "$want" == "+" ]]; then
    if [[ "$after" -lt 1 ]]; then
      echo "ERROR: mutation '$label' changed no lines."
      fails=$((fails + 1))
      return 1
    fi
  elif [[ "$after" -ne "$want" ]]; then
    echo "ERROR: mutation '$label' changed $after line(s), expected $want."
    fails=$((fails + 1))
    return 1
  fi
  return 0
}

expect_code() {
  local label="$1" tree="$2" want_rc="$3" want_code="$4"
  local out rc=0
  out="$(bash "$VALIDATOR" --strict "$tree" 2>&1)" || rc=$?
  if [[ $rc -ne $want_rc ]]; then
    echo "ERROR: $label — expected exit $want_rc, got $rc"
    echo "$out"
    fails=$((fails + 1))
    return
  fi
  if [[ -n "$want_code" ]] && ! grep -q "$want_code" <<<"$out"; then
    echo "ERROR: $label — exit was $rc but '$want_code' was not reported"
    echo "$out"
    fails=$((fails + 1))
    return
  fi
  if [[ -z "$want_code" ]] && grep -qE "BOUND_FUSION[A-Z_]*\.P[0-9]" <<<"$out"; then
    echo "ERROR: $label — expected a clean run but a finding was printed"
    echo "$out"
    fails=$((fails + 1))
    return
  fi
  echo "  ✓ $label"
}


echo "Test 1 (GREEN control): the shipped machinery keeps quality and existence bounds disjoint"
# This is the assertion that makes every RED below meaningful — and the one that would have caught
# the fusion had it ever been committed.
expect_code "shipped tree: no quality bound reaches the existence floor" "$ROOT" 0 ""

echo ""
echo "Test 2 (ANTI-VACUITY): the green above came from a NON-EMPTY subject"
# "0 findings" from a check that inspected nothing reads exactly like "0 findings" from a check
# that inspected everything. The telemetry is what tells them apart, so it is asserted, not
# eyeballed: both shipped quality axes (felt, taste) must have been reached.
out="$(bash "$VALIDATOR" --strict "$ROOT" 2>&1)"
pred="$(grep '^SPECK_GATE_PREDICATES=' <<<"$out" | cut -d= -f2)"
subj="$(grep '^SPECK_GATE_SUBJECT=' <<<"$out" | cut -d= -f2)"
if [[ "${pred:-0}" -ge 2 && "${subj:-0}" -ge 2 ]]; then
  echo "  ✓ PREDICATES=$pred quality-axis validator(s) of SUBJECT=$subj scanned (green is about something)"
else
  echo "ERROR: expected PREDICATES>=2 and SUBJECT>=2, got PREDICATES=$pred SUBJECT=$subj —"
  echo "       Test 1's green would be a green about an empty set."
  fails=$((fails + 1))
fi


echo ""
echo "Test 3 (RED): a quality axis gated at INTEGRATION-GREEN is the fusion"
# The one-token edit this check exists for. It reviews as a tightening ("be stricter earlier") and
# is the exact move that makes a rough-but-working story and an unbuilt story emit one signal.
T3="$TMP/t3"; mk_tree "$T3"
if mutate "$T3/.speck/scripts/validation/validators/validate-felt-axis.sh" \
     's/^    UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP) return 0 ;;$/    INTEGRATION-GREEN|UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP) return 0 ;;/' \
     1 "felt axis reaches INTEGRATION-GREEN"; then
  expect_code "felt_axis gated at INTEGRATION-GREEN" "$T3" 1 "BOUND_FUSION.P1"
fi

echo ""
echo "Test 4 (RED): a quality axis gated at NO-SHIP — the same fusion at the bottom of the ladder"
T4="$TMP/t4"; mk_tree "$T4"
if mutate "$T4/.speck/scripts/validation/validators/validate-taste-axis.sh" \
     's/^    UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP) return 0 ;;$/    NO-SHIP|IMPL-GREEN|UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP) return 0 ;;/' \
     1 "taste axis reaches NO-SHIP and IMPL-GREEN"; then
  expect_code "taste_axis gated at NO-SHIP/IMPL-GREEN" "$T4" 1 "BOUND_FUSION.P1"
fi


echo ""
echo "Test 5 (RED): a quality-axis validator with NO rung scope at all is UNDECIDABLE, not clean"
# Deleting the predicate is the *easier* way to fuse the bounds than widening it: with no rung
# scope the axis blocks everywhere, including the existence floor. A check that treated "no
# predicate found" as "nothing to complain about" would be silent on the worse of the two.
T5="$TMP/t5"; mk_tree "$T5"
if mutate "$T5/.speck/scripts/validation/validators/validate-felt-axis.sh" \
     's/^    UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP) return 0 ;;$/    *) return 0 ;;/' \
     1 "felt axis loses its rung scope"; then
  expect_code "felt_axis with no rung predicate" "$T5" 1 "BOUND_FUSION_UNDECIDABLE.P2"
fi


echo ""
echo "Test 6 (RED): a declared axis that nothing enforces is a NO_SUBJECT finding, not a pass"
# The vacuity hole with the widest blast radius: if the axis validators are renamed, moved, or
# deleted, a subject-blind check reports a serene green about a world it can no longer see.
T6="$TMP/t6"; mk_tree "$T6"
rm -f "$T6/.speck/scripts/validation/validators/validate-felt-axis.sh"
expect_code "felt_axis declared but no validator enforces it" "$T6" 1 "BOUND_FUSION_NO_SUBJECT.P2"


echo ""
echo "Test 7 (RED): ladder drift makes the verdict UNDECIDABLE, never silently clear"
# The existence floor is named here (NO-SHIP/IMPL-GREEN/INTEGRATION-GREEN) but VERIFIED against the
# shipped ladder. If a rung is renamed, every verdict about it is stale — and a check that kept
# reporting green would be the purest version of the thing #93 describes.
T7="$TMP/t7"; mk_tree "$T7"
if mutate "$T7/.speck/templates/story/validation-report-template.md" \
     's/INTEGRATION-GREEN/WIRED-GREEN/g' + "ladder rung renamed"; then
  # The mutation must actually have reached the frontmatter ladder — a rename that only touched
  # prose would leave the ladder intact and the RED below would be measuring nothing.
  if grep -q '^readiness_state_claimed:.*INTEGRATION-GREEN' "$T7/.speck/templates/story/validation-report-template.md"; then
    echo "ERROR: the ladder frontmatter still names INTEGRATION-GREEN — the rename missed its target."
    fails=$((fails + 1))
  else
    expect_code "INTEGRATION-GREEN renamed in the ladder" "$T7" 1 "BOUND_FUSION_LADDER_DRIFT.P2"
  fi
fi

echo ""
echo "Test 8 (RED): no readable ladder at all is UNDECIDABLE"
T8="$TMP/t8"; mk_tree "$T8"
if mutate "$T8/.speck/templates/story/validation-report-template.md" \
     's/^readiness_state_claimed:.*$/readiness_state_claimed: TBD/' 1 "ladder frontmatter removed"; then
  expect_code "no parsable readiness ladder" "$T8" 1 "BOUND_FUSION_UNDECIDABLE.P2"
fi


echo ""
echo "Test 9 (GREEN, code-not-prose): a COMMENT describing the fusion does not convict"
# Both shipped axis validators narrate the ladder at length in their headers. A prose-blind scan
# would read a sentence as an enforcement decision — the defect validate-two-carrier.sh had to have
# surgically removed. Comment-stripping must hold in the convicting direction too.
T9="$TMP/t9"; mk_tree "$T9"
{
  echo '# A previous draft read:  NO-SHIP|IMPL-GREEN|INTEGRATION-GREEN) return 0 ;;'
  echo '# …which would have gated the felt axis at the existence floor. It does not do that.'
} >> "$T9/.speck/scripts/validation/validators/validate-felt-axis.sh"
expect_code "a header comment containing an existence-rung case arm" "$T9" 0 ""

echo ""
echo "Test 10 (GREEN, parse ≠ gate): enumerating rungs to READ a claimed state is not enforcement"
# Both validators contain `grep -oE '(NO-SHIP|IMPL-GREEN|INTEGRATION-GREEN|…)'` to parse a claimed
# state out of a report. Extracting a rung and gating on a rung are different acts; a check that
# conflated them would convict the shipped machinery on day one — the "red on arrival" gate that
# gets bypassed rather than fixed.
T10="$TMP/t10"; mk_tree "$T10"
cat >> "$T10/.speck/scripts/validation/validators/validate-taste-axis.sh" <<'EXTRA'
parse_any_rung() {
  echo "$1" | grep -oE '(NO-SHIP|IMPL-GREEN|INTEGRATION-GREEN|UX-RC|SHIP)' | head -n 1 || true
}
EXTRA
expect_code "a rung-parsing helper naming every existence rung" "$T10" 0 ""


echo ""
echo "Test 11 (PRECISION): an honest 'not ready' artifact is not convictable — by construction"
# The bar #93 sets for this class: a check that convicted an honest "not ready" would train exactly
# the routing-around the class describes. This check's subject is the MACHINERY, never a report, so
# no artifact can move its verdict. That is asserted here rather than argued: a scratch tree gains
# a genuine NO-SHIP validation report full of quality-shaped blockers, and the verdict must not
# move a single byte.
T11="$TMP/t11"; mk_tree "$T11"
before_out="$(bash "$VALIDATOR" --strict "$T11" 2>&1)"; before_rc=$?
mkdir -p "$T11/specs/projects/demo/epics/e1/stories/s1"
sed 's/^readiness_state_claimed:.*$/readiness_state_claimed: NO-SHIP/; s/^felt_axis:.*$/felt_axis: uncovered/; s/^taste_axis:.*$/taste_axis: uncovered/' \
  "$T11/.speck/templates/story/validation-report-template.md" \
  > "$T11/specs/projects/demo/epics/e1/stories/s1/validation-report.md"
after_out="$(bash "$VALIDATOR" --strict "$T11" 2>&1)"; after_rc=$?
if [[ "$before_rc" -eq "$after_rc" && "$before_out" == "$after_out" ]]; then
  echo "  ✓ an honest NO-SHIP report with both quality axes uncovered changes nothing (rc=$after_rc)"
else
  echo "ERROR: adding a validation report moved the verdict (rc $before_rc → $after_rc)."
  echo "       This check must be unable to convict an artifact; if it can, it can convict an"
  echo "       honest 'not ready' — the failure mode #93 class 3 warns about."
  fails=$((fails + 1))
fi


echo ""
echo "Test 12: without --strict a finding is reported but exit stays 0"
rc=0
out="$(bash "$VALIDATOR" "$T3" 2>&1)" || rc=$?
if [[ $rc -eq 0 ]] && grep -q "BOUND_FUSION.P1" <<<"$out"; then
  echo "  ✓ non-strict: finding printed, exit 0"
else
  echo "ERROR: expected exit 0 with a printed finding in non-strict mode, got rc=$rc"
  echo "$out"
  fails=$((fails + 1))
fi

echo ""
echo "Test 13: an invalid root exits 2, and telemetry is emitted on every exit path"
rc=0
out="$(bash "$VALIDATOR" --strict "$TMP/definitely-not-a-dir" 2>&1)" || rc=$?
if [[ $rc -eq 2 ]]; then
  echo "  ✓ missing root: exit 2"
else
  echo "ERROR: expected exit 2 for a missing root, got $rc"
  fails=$((fails + 1))
fi
for tree_rc in "$ROOT:0" "$T3:1"; do
  t="${tree_rc%:*}"
  o="$(bash "$VALIDATOR" --strict "$t" 2>&1 || true)"
  for key in SPECK_GATE_SCOPE SPECK_GATE_SUBJECT SPECK_GATE_PREDICATES SPECK_GATE_MODE; do
    if ! grep -q "^$key=" <<<"$o"; then
      echo "ERROR: $key missing from the output for $t"
      fails=$((fails + 1))
    fi
  done
done
echo "  ✓ telemetry present on the clean and the finding paths"


echo ""
if [[ $fails -gt 0 ]]; then
  echo "FAILED: $fails validate-bound-fusion.test.sh assertion(s) failed"
  exit 1
fi
echo "All validate-bound-fusion tests passed successfully!"
exit 0
