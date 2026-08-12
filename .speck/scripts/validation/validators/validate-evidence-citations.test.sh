#!/usr/bin/env bash
# validate-evidence-citations.test.sh — tests for TYPED evidence citations (issue #101).
#
# THE FIXTURE RULE THIS FILE OBEYS: where the shipped template is involved, the fixture is a COPY
# OF THE SHIPPED TEMPLATE, not a hand-typed excerpt. Two v10 rules shipped vacuous because a grep
# over a section body was satisfied by the template's own explanatory boilerplate while the
# hand-written fixture guarding them omitted exactly that boilerplate. So every §2b assertion here
# runs against `.speck/templates/project/evidence-contract-template.md` itself, and the negative
# controls mutate a SCRATCH COPY of it.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
# SPECK_VALIDATOR_UNDER_TEST is the mutation-harness hook (same convention as
# validate-gate-liveness.test.sh): point it at a scratch copy of the validator to confirm an
# assertion actually goes red when its fix is reverted. Unset in every normal run.
VAL="${SPECK_VALIDATOR_UNDER_TEST:-$ROOT/.speck/scripts/validation/validators/validate-evidence-citations.sh}"
TEMPLATE="$ROOT/.speck/templates/project/evidence-contract-template.md"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

run() { RC=0; OUT=$(bash "$VAL" "$@" 2>&1) || RC=$?; }

# ── the mutation harness ──────────────────────────────────────────────────────────────────────
# Every assertion below that claims a behaviour is PAIRED with a scratch copy of the validator in
# which the fix is reverted, and the pair is only credited when the mutant produces the OLD answer.
# The scratch copy is laid out at the SAME relative depth as the real validator so its
# `. "$SCRIPT_DIR/../../lib/text.sh"` resolves — a control that dies on a missing source is red for
# a reason that has nothing to do with the mutation, and proves nothing.
MUTDIR="$T/mut/scripts/validation/validators"
mkdir -p "$MUTDIR" "$T/mut/scripts/lib"
cp "$ROOT/.speck/scripts/lib/text.sh" "$T/mut/scripts/lib/text.sh"

# mkmut <name> <old-substring> <new-substring> — writes $MUT. Returns non-zero (and reports why)
# when the site is gone or the mutant will not run, so a dead mutation site fails loudly instead
# of masquerading as a passing control.
MUT=""
mkmut() {
  local name="$1" old="$2" new="$3"
  MUT="$MUTDIR/$name"
  rm -f "$MUT"
  if ! python3 - "$VAL" "$MUT" "$old" "$new" <<'PY'
import sys
src, dest, old, new = sys.argv[1:5]
s = open(src).read()
if old not in s:
    sys.stderr.write("MUTATION SITE NOT FOUND: %r\n" % old)
    sys.exit(1)
if s.count(old) != 1:
    sys.stderr.write("MUTATION SITE AMBIGUOUS (%d matches): %r\n" % (s.count(old), old))
    sys.exit(1)
open(dest, "w").write(s.replace(old, new))
PY
  then MUT=""; return 1; fi
  bash "$MUT" --print-vocabulary >/dev/null 2>&1 || { MUT=""; return 1; }
  return 0
}
runmut() { RC=0; OUT=$(bash "$MUT" "$@" 2>&1) || RC=$?; }
# grep -c counts LINES; the findings are one per line, so this is a citation count.
count() { echo "$OUT" | grep -c "$1"; }

# A citation site with the shape §11a will have: a Claim type column + a Discharge artifact column.
# Appended to a REAL copy of the shipped template so §2b's own tables are present and in play.
mkfixture() { # <dest> <rows...>
  local dest="$1"; shift
  cp "$TEMPLATE" "$dest"
  {
    echo ""
    echo "### 11a. Standard Probe Library"
    echo ""
    echo "| Probe ID | Claim type | Discharge artifact | Exception |"
    echo "|---|---|---|---|"
    printf '%s\n' "$@"
  } >> "$dest"
}

echo "validate-evidence-citations.sh"

# ── 1. The closed vocabulary and the table are what the contract says they are ────────────────
run --print-vocabulary
{ [[ "$RC" == 0 ]] && [[ "$(echo "$OUT" | grep -c '^[a-z-]*$')" -ge 10 ]]; } \
  && pass "vocabulary prints 10 closed tokens" || fail "vocabulary should print 10 tokens"

for tok in test mutation-guard live-probe db-catalog ax-dump geometry capture device-walk model-eval static; do
  echo "$OUT" | grep -qx "$tok" || { fail "vocabulary missing token '$tok'"; break; }
done
pass "vocabulary carries every token §2b documents"

# ── 2. PARITY: the shipped template's §2b IS the compiled table ───────────────────────────────
# This is what stops §2b being decoration. Runs against the real shipped template.
run --strict --check-contract "$TEMPLATE"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "CITATION_TABLE_PARITY"; } \
  && pass "shipped template §2b matches the compiled admissibility table" \
  || fail "shipped template §2b must match the compiled table"

# 2b. NEGATIVE CONTROL — weaken §2b in a scratch copy of the SHIPPED template and require RED.
# The mutation is the exact scar #101 verified: admitting `test` for a visibility claim.
cp "$TEMPLATE" "$T/mutated.md"
python3 - "$T/mutated.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
old = '| `visibility` | `live-probe` `db-catalog` `device-walk` |'
new = '| `visibility` | `test` `live-probe` `db-catalog` `device-walk` |'
assert old in s, 'MUTATION SITE NOT FOUND — the §2b visibility row moved; this control is dead'
open(p, 'w').write(s.replace(old, new))
PY
run --strict --check-contract "$T/mutated.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "CITATION_TABLE_DRIFT.P2"; } \
  && pass "negative control: weakening §2b's visibility row → CITATION_TABLE_DRIFT.P2, exit 1" \
  || fail "weakening §2b must go RED"

# 2c. NEGATIVE CONTROL — delete a vocabulary token from §2b.
cp "$TEMPLATE" "$T/novocab.md"
python3 - "$T/novocab.md" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
lines = [l for l in s.split('\n') if not l.startswith('| `geometry` | Measured')]
assert len(lines) < len(s.split('\n')), 'MUTATION SITE NOT FOUND — the §2b geometry vocabulary row moved'
open(p, 'w').write('\n'.join(lines))
PY
run --strict --check-contract "$T/novocab.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "vocabulary is"; } \
  && pass "negative control: dropping a §2b vocabulary row → CITATION_TABLE_DRIFT.P2" \
  || fail "dropping a vocabulary row must go RED"

# ── 3. The shipped templates produce ZERO findings ────────────────────────────────────────────
# The upgrade-day property, asserted rather than assumed: nothing existing becomes non-conformant.
run --strict "$TEMPLATE"
{ [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "\.P1"; } \
  && pass "shipped evidence-contract template: no P1" || fail "shipped template must not raise P1"

# The legacy shape — an Evidence column and no Claim type column — is what EVERY artifact
# downstream looks like today. It must produce P3 nudges (otherwise the P3 is vacuous and the
# "P3, not P1" decision is decorative) and it must be STRUCTURALLY INCAPABLE of producing a P1.
run --strict "$ROOT/.speck/templates/story/validation-report-template.md"
{ [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "\.P1"; } \
  && pass "shipped validation-report template: P3 nudges only, exit 0 — a legacy artifact cannot raise a P1" \
  || fail "validation-report template must never raise a P1"
# PINNED TO THE EXACT COUNT, not `-ge 5`. The figure is EIGHT — measured, and it is the number the
# v10.1 audit reported as nine. A floor of five would have been satisfied by both, which is the
# whole problem with a floor: it cannot tell "the rule still reaches every legacy citation" from
# "the precision fix over-excluded three of them and the rule is quietly decaying". This template
# is shipped and versioned, so the count is a stable fact about it; when a row is legitimately
# added or removed here, update the number in the same commit.
{ [[ "$(count 'CITATION_UNTYPED')" == 8 ]]; } \
  && pass "the P3 reaches EXACTLY the 8 untyped citations in the legacy validation-report shape" \
  || fail "P3 must fire exactly 8 times on the legacy validation-report shape (got $(count 'CITATION_UNTYPED'))"
echo "$OUT" | grep -q "'/' has no citation type" \
  && fail "a bare '/' must not be reported as a citation" \
  || pass "prose fragments (a bare '/' from 'logs / traces') are not reported as citations"

# ── 4. PROBE_SUBSTRATE_MISMATCH.P1 — each of #101's three verified scars ──────────────────────
mkfixture "$T/scar1.md" "| PROBE:rls | \`visibility\` | \`mutation-guard:backend/tests/test_rls.py@edd6e9f0\` | — |"
run --strict "$T/scar1.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "scar 1: a mutation-verified suite for a visibility claim → P1" || fail "visibility/mutation-guard must be P1"

mkfixture "$T/scar2.md" "| PROBE:hook | \`acceptance\` | \`test:supabase/functions/__tests__/webhook.test.ts@264fb33\` | — |"
run --strict "$T/scar2.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "scar 2: a mocked-client test for 'what does the deployment ACCEPT' → P1" || fail "acceptance/test must be P1"

mkfixture "$T/scar3.md" "| PROBE:grid | \`fit\` | \`test:frontend/src/WeekGrid.fits.test.tsx@89468af1\` | — |"
run --strict "$T/scar3.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "scar 3: a props-level assertion for 'does it FIT' → P1 (axe is blind to geometry)" || fail "fit/test must be P1"

# 4b. NEGATIVE CONTROL for the P1 path — the mutation site is the ADMISSIBILITY TABLE ITSELF,
# which is the real control point: every P1 above is computed from claim_admissible_types(). A
# scratch copy of the validator whose `fit` row admits `test` must let scar 3 through green.
#
# The scratch copy is laid out at the SAME relative depth as the real validator so its
# `. "$SCRIPT_DIR/../../lib/text.sh"` resolves. Without that the mutated copy dies on a missing
# source and the control reports RED for a reason that has nothing to do with the mutation — a
# control that cannot distinguish "the mutation bit" from "the copy was broken" proves nothing.
MUTDIR="$T/mut/scripts/validation/validators"
mkdir -p "$MUTDIR" "$T/mut/scripts/lib"
cp "$ROOT/.speck/scripts/lib/text.sh" "$T/mut/scripts/lib/text.sh"
sed 's|^    fit)         printf .*$|    fit)         printf "%s" "ax-dump geometry device-walk test" ;;|' \
  "$VAL" > "$MUTDIR/val-mutated.sh"

# The mutation must actually have changed the file, AND the copy must still run. Both are asserted
# before the verdict is read, so a dead mutation site can never masquerade as a passing control.
if diff -q "$VAL" "$MUTDIR/val-mutated.sh" >/dev/null 2>&1; then
  fail "MUTATION SITE NOT FOUND — claim_admissible_types' fit row moved; this control is dead"
else
  RC=0; OUT=$(bash "$MUTDIR/val-mutated.sh" --print-table 2>&1) || RC=$?
  if [[ "$RC" != 0 ]]; then
    fail "the mutated scratch copy does not run — the control would be red for the wrong reason"
  else
    echo "$OUT" | grep -q "^fit	.*test" \
      || fail "the mutation did not reach claim_admissible_types (fit row unchanged in --print-table)"
    RC=0; OUT=$(bash "$MUTDIR/val-mutated.sh" --strict "$T/scar3.md" 2>&1) || RC=$?
    { [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
      && pass "negative control: admitting \`test\` for \`fit\` in the table makes scar 3 go GREEN (the table is the control point)" \
      || fail "mutating the admissibility table must change the verdict"
  fi
fi

# ── 5. CITATION_UNTYPED.P3 — a nudge, never a block ──────────────────────────────────────────
# The load-bearing severity decision: every downstream artifact is untyped, so P1 here would brick
# every project on upgrade day.
mkfixture "$T/untyped.md" "| PROBE:legacy | \`visibility\` | \`specs/logs/89468af1-live-read.log\` | — |"
run --strict "$T/untyped.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "CITATION_UNTYPED.P3"; } \
  && pass "a legacy untyped citation is P3 and does NOT fail --strict (upgrade day is safe)" \
  || fail "untyped must be P3 and exit 0"

echo "$OUT" | grep -q -- "--stamp-types --write" \
  && pass "the P3 text names the fixing command" || fail "P3 must name the fixing command"

# 5b. An untyped citation must not be silently promoted: the SAME row typed inadmissibly is P1.
mkfixture "$T/untyped2.md" "| PROBE:legacy | \`visibility\` | \`test:specs/logs/x.test.ts\` | — |"
run --strict "$T/untyped2.md"
{ [[ "$RC" == 1 ]]; } && pass "typing the same citation inadmissibly escalates P3 → P1" || fail "typed+inadmissible must be P1"

# ── 6. Degrade-to-honest: an unrecognised claim type is a NOTE, never a false P1 ──────────────
mkfixture "$T/unrouted.md" "| PROBE:x | \`vibes\` | \`test:a/b.test.ts\` | — |"
run --strict "$T/unrouted.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "CLAIM_TYPE_UNROUTED"; } \
  && pass "an unrecognised claim type is reported and skipped, never a false P1" || fail "unrouted must be a note"

# ── 7. correctness admits everything — the default claim type is never punished ───────────────
mkfixture "$T/corr.md" \
  "| PROBE:a | \`correctness\` | \`test:a/b.test.ts@abc1234\` | — |" \
  "| PROBE:b | \`correctness\` | \`capture:screenshots/abc1234-x.png\` | — |" \
  "| PROBE:c | \`correctness\` | \`static:src/lint.log\` | — |"
run --strict "$T/corr.md"
{ [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH"; } \
  && pass "correctness admits every citation type (a green suite stays right and sufficient)" \
  || fail "correctness must never raise a mismatch"

# ── 8. Admissible citations pass ──────────────────────────────────────────────────────────────
mkfixture "$T/good.md" \
  "| PROBE:rls | \`visibility\` | \`live-probe:specs/logs/89468af1-as-principal.log\` | — |" \
  "| PROBE:fit | \`fit\` | \`geometry:specs/logs/89468af1-target-size.json\` | — |" \
  "| PROBE:fit2 | \`fit\` | \`ax-dump:ax-trees/89468af1-grid.xml\` | — |" \
  "| PROBE:wr | \`persistence\` | \`db-catalog:specs/logs/89468af1-readback.log\` | — |" \
  "| PROBE:pr | \`behaviour\` | \`model-eval:transcripts/89468af1-control-vs-treatment.md\` | — |"
run --strict "$T/good.md"
{ [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "\.P1"; } \
  && pass "every admissible (claim, type) pair passes" || fail "admissible pairs must pass"

# ── 9. The definition tables can never report on themselves ──────────────────────────────────
# §2a's and §2b's own tables carry a `Claim type` column. If the citation-site rule matched on the
# claim column alone, the contract would raise findings against its own documentation.
run "$TEMPLATE"
{ echo "$OUT" | grep -q "SPECK_GATE_SUBJECT=1"; } \
  && pass "the two §2b definition tables are inert; only the example citation site is scanned" \
  || fail "definition tables must not be scanned as citation sites"

# 9b. NEGATIVE CONTROL, paired. Inject a REAL typed citation into §2b's own admissibility table
# (into the `Admissible` cell of the visibility row) in a scratch copy of the SHIPPED template.
#   • the shipped validator must IGNORE it — the definition tables have no evidence column;
#   • a validator that also treats `Admissible…` as an evidence column must REPORT it.
# Both halves are asserted, so the "inert" claim cannot pass by accident on a fixture that simply
# contained nothing citable.
cp "$TEMPLATE" "$T/selfreport.md"
python3 - "$T/selfreport.md" <<'PY2'
import sys
p = sys.argv[1]
s = open(p).read()
old = '| `visibility` | `live-probe` `db-catalog` `device-walk` |'
new = '| `visibility` | `live-probe` `db-catalog` `device-walk` `test:a/b.test.ts` |'
assert old in s, 'MUTATION SITE NOT FOUND — the §2b visibility row moved; this control is dead'
open(p, 'w').write(s.replace(old, new))
PY2

run --strict "$T/selfreport.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "SPECK_GATE_SUBJECT=1"; } \
  && pass "a citation planted inside §2b's own admissibility table is IGNORED (definition tables are inert)" \
  || fail "the definition tables must never be scanned as citation sites"

sed 's|^      evidence\*|      admissible*\|evidence*|' "$VAL" > "$MUTDIR/val-selfreport.sh"
if diff -q "$VAL" "$MUTDIR/val-selfreport.sh" >/dev/null 2>&1; then
  fail "MUTATION SITE NOT FOUND — the evidence-column label list moved; this control is dead"
else
  RC=0; OUT=$(bash "$MUTDIR/val-selfreport.sh" --strict "$T/selfreport.md" 2>&1) || RC=$?
  { [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
    && pass "negative control: admitting \`Admissible\` as an evidence column makes §2b report against itself" \
    || fail "the definition-table exclusion must be load-bearing"
fi

# ── 10. --stamp-types: infers only the unambiguous, and leaves the rest untyped ───────────────
mkfixture "$T/stamp.md" \
  "| PROBE:png | \`persistence\` | \`screenshots/89468af1-ok.png\` | — |" \
  "| PROBE:ax | \`fit\` | \`ax-trees/89468af1-grid.xml\` | — |" \
  "| PROBE:att | \`fit\` | \`larp-recordings/89468af1-human-attestation.md\` | — |" \
  "| PROBE:unit | \`correctness\` | \`src/undo.test.ts\` | — |" \
  "| PROBE:amb | \`visibility\` | \`specs/logs/89468af1-read.log\` | — |" \
  "| PROBE:pw | \`fit\` | \`frontend/tests/a11y/target-size.spec.ts\` | — |" \
  "| PROBE:sql | \`acceptance\` | \`supabase/tests/webhook_claim_proof.sql\` | — |"
run --stamp-types --write "$T/stamp.md"
[[ "$RC" == 0 ]] || fail "stamp-types should exit 0"
grep -q 'capture:screenshots/89468af1-ok.png' "$T/stamp.md" && pass "stamps .png → capture" || fail ".png must infer capture"
grep -q 'ax-dump:ax-trees/89468af1-grid.xml' "$T/stamp.md" && pass "stamps ax-trees/ → ax-dump" || fail "ax-trees/ must infer ax-dump"
grep -q 'device-walk:larp-recordings/89468af1-human-attestation.md' "$T/stamp.md" \
  && pass "stamps *-human-attestation.md → device-walk (beats the larp-recordings/ rule)" || fail "attestation must infer device-walk"
grep -q 'test:src/undo.test.ts' "$T/stamp.md" && pass "stamps *.test.ts → test" || fail "*.test.ts must infer test"

# The three deliberate refusals. Guessing a type is worse than leaving it untyped: a wrong type
# produces a confident FALSE admissibility verdict.
grep -q '| `specs/logs/89468af1-read.log` |' "$T/stamp.md" \
  && pass "leaves an ambiguous .log untyped rather than guessing" || fail ".log must be left untyped"
grep -q '| `frontend/tests/a11y/target-size.spec.ts` |' "$T/stamp.md" \
  && pass "leaves a .spec.ts under a11y/ untyped (Playwright geometry and Vitest share the suffix)" \
  || fail "a11y .spec.ts must be left untyped"
grep -q '| `supabase/tests/webhook_claim_proof.sql` |' "$T/stamp.md" \
  && pass "leaves *_proof.sql untyped (a naming convention is not a fact about the substrate)" \
  || fail "_proof.sql must be left untyped"

# 10b. Stamping is idempotent, and it does not damage the cell.
cp "$T/stamp.md" "$T/stamp-again.md"
run --stamp-types --write "$T/stamp-again.md"
diff -q "$T/stamp.md" "$T/stamp-again.md" >/dev/null 2>&1 \
  && pass "stamping twice is a no-op (no double prefixes)" || fail "stamp must be idempotent"

# 10c. Two citations in one cell where one path CONTAINS the other, plus a glob metacharacter.
# A substring substitution corrupts both; this is why the rewrite is field-wise.
mkfixture "$T/collide.md" \
  "| PROBE:s | \`persistence\` | \`foo/bar.png\`, \`x/foo/bar.png\` | — |" \
  "| PROBE:g | \`fit\` | \`ax-trees/a[1].png\` | — |"
run --stamp-types --write "$T/collide.md"
grep -q '| `capture:foo/bar.png`, `capture:x/foo/bar.png` |' "$T/collide.md" \
  && pass "field-wise rewrite: a path containing another path is stamped correctly, decoration intact" \
  || fail "substring collision must not corrupt the cell"
grep -q 'ax-dump:ax-trees/a\[1\].png' "$T/collide.md" \
  && pass "a glob metacharacter in a path is stamped literally" || fail "glob path must stamp literally"

# 10d. Dry-run must not write.
mkfixture "$T/dry.md" "| PROBE:png | \`persistence\` | \`screenshots/89468af1-ok.png\` | — |"
cp "$T/dry.md" "$T/dry-before.md"
run --stamp-types "$T/dry.md"
diff -q "$T/dry.md" "$T/dry-before.md" >/dev/null 2>&1 \
  && pass "--stamp-types without --write does not touch the file" || fail "dry-run must not write"

# 10e. Stamping REVEALS mismatches that were invisible while untyped — the point of the migration.
mkfixture "$T/reveal.md" "| PROBE:cap | \`persistence\` | \`screenshots/89468af1-success.png\` | — |"
run --strict "$T/reveal.md"
[[ "$RC" == 0 ]] || fail "untyped screenshot should not block before stamping"
run --stamp-types --write "$T/reveal.md"
run --strict "$T/reveal.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "stamping a screenshot exposes it as inadmissible for a persistence claim (P3 → P1)" \
  || fail "stamping must expose the latent mismatch"

# ── 11. Gate telemetry on every exit path (#98 §4) ───────────────────────────────────────────
for args in "--print-vocabulary" "--print-table" "--check-contract $TEMPLATE" "$TEMPLATE" "--stamp-types $TEMPLATE"; do
  # shellcheck disable=SC2086
  run $args
  for k in SPECK_GATE_SCOPE SPECK_GATE_SUBJECT SPECK_GATE_PREDICATES SPECK_GATE_MODE; do
    echo "$OUT" | grep -q "^$k=" || { fail "telemetry $k missing on '$args'"; break 2; }
  done
done
pass "publishes SPECK_GATE_SCOPE/SUBJECT/PREDICATES/MODE on every exit path"

run --strict "$T/scar1.md"
echo "$OUT" | grep -q "^SPECK_GATE_MODE=scan" && pass "telemetry survives the failing (exit 1) path" || fail "telemetry must survive exit 1"

run --nonsense
{ [[ "$RC" == 2 ]] && echo "$OUT" | grep -q "^SPECK_GATE_MODE="; } \
  && pass "telemetry survives the invocation-error (exit 2) path" || fail "telemetry must survive exit 2"

# ── 12. Invocation errors ─────────────────────────────────────────────────────────────────────
run
[[ "$RC" == 2 ]] && pass "no target → exit 2" || fail "no target must exit 2"
run "$T/does-not-exist.md"
[[ "$RC" == 2 ]] && pass "missing file → exit 2" || fail "missing file must exit 2"

# ── 13. Placeholders and prose are not citations ─────────────────────────────────────────────
mkfixture "$T/placeholders.md" \
  "| PROBE:a | \`visibility\` | — | — |" \
  "| PROBE:b | \`visibility\` | n/a | — |" \
  "| PROBE:c | \`visibility\` | TBD | — |"
run --strict "$T/placeholders.md"
{ [[ "$RC" == 0 ]] && [[ "$(echo "$OUT" | grep -c 'CITATION_UNTYPED')" == 0 ]]; } \
  && pass "placeholders (— / n/a / TBD) are not reported as untyped citations" || fail "placeholders must not be findings"

# ── 14. PRECISION: a slash is punctuation, not a path ────────────────────────────────────────
# The measured defect: over two real projects' `specs/**` the gate counted API routes, slash
# commands, npm scopes and ordinary English written with a solidus as citations. The figures live
# in ONE place — the header paragraph of validate-evidence-citations.sh — because a number restated
# in two files drifts, and this pair had already disagreed with itself once. A P3 at that
# false-positive rate is a P3 that gets suppressed project-wide on first contact.
mkfixture "$T/fp.md" \
  "| PROBE:route | \`acceptance\` | \`/api/v1/coach/chat\` \`/health\` \`/model/correction\` | — |" \
  "| PROBE:cmd | \`correctness\` | \`/speck-audit\` \`/check-in\` \`/suggest\` | — |" \
  "| PROBE:prose | \`correctness\` | Terms/Privacy, 988/741741, try/catch, 4/4, A/B/C/D | — |" \
  "| PROBE:scope | \`correctness\` | \`@streb/web\` \`pnpm/action-setup@v4\` | — |"
run --strict "$T/fp.md"
# SUBJECT=1 is the shipped template's own single example citation — i.e. everything the fixture
# added was rejected. Asserting the COUNT, not just "no finding for token X", is what makes this
# an exhaustive claim rather than a spot check.
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=1$"; } \
  && pass "routes, slash commands, npm scopes and prose solidi are not citations (13 tokens, 0 reported)" \
  || fail "extension-less punctuation must not be reported as citations"

# 14b. NEGATIVE CONTROL — restore the shipped test (`contains / or @` ⇒ citation) in a scratch
# copy. The mutation site is is_citation_like's FIRST admission rule, which is the real control
# point: every token above is rejected by falling through all three of them.
if mkmut "fp-punct.sh" \
  '  [[ "$base" =~ .\.[A-Za-z0-9]{2,6}$ ]] && return 0' \
  '  [[ "$core" == *"/"* || "$t" == *"@"* ]] && return 0'; then
  runmut --strict "$T/fp.md"
  { [[ "$(count 'CITATION_UNTYPED')" -ge 10 ]]; } \
    && pass "negative control: the punctuation test readmits $(count 'CITATION_UNTYPED') of them (is_citation_like is the control point)" \
    || fail "reverting to the punctuation test must readmit the false positives"
else
  fail "MUTATION SITE NOT FOUND — is_citation_like's extension rule moved; this control is dead"
fi

# ── 15. RECALL: the precision fix must not eat real citations ─────────────────────────────────
# Each row is a shape observed in a real project's specs. A precision fix that also drops these is
# not a fix, and the count assertion is what makes "still reaches them" checkable.
mkfixture "$T/recall.md" \
  "| PROBE:file | \`correctness\` | \`audit-report.md\` | — |" \
  "| PROBE:path | \`correctness\` | \`apps/mobile/src/services/auth.service.ts@89468af1\` | — |" \
  "| PROBE:dir | \`correctness\` | \`larp-recordings/phase2-8c09936c/\` | — |" \
  "| PROBE:lines | \`correctness\` | \`.github/workflows/ci.yml:59-63\` | — |"
run --strict "$T/recall.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=5$"; } \
  && pass "recall: bare filename, path@sha, reserved-dir directory, and path:line-range all still count" \
  || fail "the precision fix must not drop real citations"

# 15b. NEGATIVE CONTROL — empty CITATION_DIRS. The directory citation must be the one that drops.
if mkmut "recall-nodirs.sh" \
  'CITATION_DIRS="specs personas screenshots larp-recordings ax-trees transcripts logs"' \
  'CITATION_DIRS=""'; then
  runmut --strict "$T/recall.md"
  { echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=4$" && ! echo "$OUT" | grep -q "larp-recordings/phase2"; } \
    && pass "negative control: emptying CITATION_DIRS drops the directory citation (the list is load-bearing)" \
    || fail "CITATION_DIRS must be what admits a directory citation"
else
  fail "MUTATION SITE NOT FOUND — CITATION_DIRS moved; this control is dead"
fi

# 15c. NEGATIVE CONTROL — remove the `:<line>` anchor strip. `ci.yml:59-63` must drop.
if mkmut "recall-nolines.sh" \
  '  probe="${core%:[0-9]*}"' \
  '  probe="$core"'; then
  runmut --strict "$T/recall.md"
  { echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=4$" && ! echo "$OUT" | grep -q "ci.yml:59-63"; } \
    && pass "negative control: without the line-anchor strip, \`ci.yml:59-63\` stops being a citation" \
    || fail "the line-anchor strip must be what admits path:line-range"
else
  fail "MUTATION SITE NOT FOUND — the line-anchor strip moved; this control is dead"
fi

# 15d. A TYPED citation whose path is a directory or an absolute file. The three admission rules
# ask questions about a PATH, so the `<type>:` prefix has to come off first — and this is the one
# place where a rejected token is NOT harmless: an unseen typed citation is one whose
# PROBE_SUBSTRATE_MISMATCH.P1 can never fire. Measured before the fix: `test:` on a `fit` claim
# pointing at a LARP recording directory scanned as ZERO citations and exited 0.
mkfixture "$T/typedpath.md" \
  "| PROBE:dir | \`fit\` | \`test:larp-recordings/8c09936c/\` | — |"
run --strict "$T/typedpath.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "a typed citation naming a directory is still routed — its P1 fires" \
  || fail "a typed directory citation must not vanish from the scan"

if mkmut "typedpath-noprefix.sh" \
  '  ty="$(citation_type_of "$core")"
  [[ -n "$ty" ]] && core="${core#"$ty":}"' \
  '  ty=""'; then
  runmut --strict "$T/typedpath.md"
  { [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=1$"; } \
    && pass "negative control: leaving the \`<type>:\` prefix on makes the whole row invisible (exit 0, nothing examined)" \
    || fail "the type-prefix strip must be what keeps a typed non-file citation visible"
else
  fail "MUTATION SITE NOT FOUND — the type-prefix strip moved; this control is dead"
fi

# ── 16. The absolute-path disk probe, pinned in BOTH directions ───────────────────────────────
# `/health` and `$T/onbox/artifact` are indistinguishable as strings: both are absolute, both have
# no extension, neither sits under a reserved directory. Only one of them exists.
mkdir -p "$T/onbox"; : > "$T/onbox/artifact"
mkfixture "$T/abs.md" \
  "| PROBE:real | \`correctness\` | \`$T/onbox/artifact\` | — |" \
  "| PROBE:route | \`correctness\` | \`/health\` | — |"
run --strict "$T/abs.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=2$" && ! echo "$OUT" | grep -q "'/health'"; } \
  && pass "an absolute path that resolves is a citation; an identically-shaped route that does not is not" \
  || fail "the absolute-path disk probe must separate the two"

# 16a. Drop the `-e` test ⇒ the route is readmitted.
if mkmut "abs-noprobe.sh" \
  '  [[ "$core" == /* && -e "$probe" ]] && return 0' \
  '  [[ "$core" == /* ]] && return 0'; then
  runmut --strict "$T/abs.md"
  { echo "$OUT" | grep -q "'/health'"; } \
    && pass "negative control: without the \`-e\` probe, \`/health\` is reported as a citation" \
    || fail "the -e probe must be what excludes an unresolvable absolute token"
else
  fail "MUTATION SITE NOT FOUND — the absolute-path rule moved; this control is dead"
fi

# 16b. Make the `-e` test unsatisfiable ⇒ the REAL path drops. Without this half, an
# always-false rule 3 would pass 16a's control just as well.
if mkmut "abs-neverfound.sh" \
  '  [[ "$core" == /* && -e "$probe" ]] && return 0' \
  '  [[ "$core" == /* && -e "$probe/no-such-thing" ]] && return 0'; then
  runmut --strict "$T/abs.md"
  { echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=1$" && ! echo "$OUT" | grep -q "onbox/artifact"; } \
    && pass "negative control: an unsatisfiable \`-e\` drops the real absolute path (rule 3 is what admits it)" \
    || fail "rule 3 must be what admits a resolvable absolute path"
else
  fail "MUTATION SITE NOT FOUND — the absolute-path rule moved; this control is dead"
fi

# ── 17. --stamp-types writes ONLY where a stamped type can be read back ───────────────────────
# §2b: admissibility is computable only where the claim type and the citation sit in the same row.
# A type stamped into a plan.md acceptance table or an audit-report.md finding table — neither of
# which has a `Claim` column — can therefore never be read by anything. The shipped rewrite did it
# anyway, across 24 files on one project, and unreviewable churn is how a migration gets reverted
# wholesale, taking the correct half with it.
mkstampfixture() { # <dest>
  cp "$TEMPLATE" "$1"
  {
    echo ""
    echo "### 11a. Standard Probe Library"
    echo ""
    echo "| Probe ID | Claim type | Discharge artifact | Exception |"
    echo "|---|---|---|---|"
    echo "| PROBE:cap | \`persistence\` | \`screenshots/89468af1-ok.png\` | — |"
    echo ""
    echo "### A plan.md-shaped acceptance table — evidence column, NO Claim column"
    echo ""
    echo "| AC | Description | Evidence | Status |"
    echo "|---|---|---|---|"
    echo "| AC-1 | undo works | \`screenshots/89468af1-undo.png\` | ✅ |"
  } >> "$1"
}
mkstampfixture "$T/scope.md"
run --stamp-types --write "$T/scope.md"
grep -qF '| PROBE:cap | `persistence` | `capture:screenshots/89468af1-ok.png` | — |' "$T/scope.md" \
  && pass "stamp: a genuine citation site (Claim + evidence column) is stamped" \
  || fail "a Claim+evidence table must still be stamped"
grep -qF '| AC-1 | undo works | `screenshots/89468af1-undo.png` | ✅ |' "$T/scope.md" \
  && pass "stamp: an evidence-only table is left byte-identical (a type written there can never be read)" \
  || fail "an evidence-only table must not be rewritten"
echo "$OUT" | grep -q "2 table(s) skipped" \
  && pass "stamp: the skipped tables are reported, not silently dropped (2)" || fail "skipped tables must be reported"

# 17b. NEGATIVE CONTROL — remove the Claim-column guard; the AC table must get stamped again.
mkstampfixture "$T/scope-mut.md"
if mkmut "scope-noguard.sh" \
  '      if [[ "$mode" == "stamp-types" && "$site" == true && $COL_CLAIM -lt 0 ]]; then' \
  '      if false; then'; then
  runmut --stamp-types --write "$T/scope-mut.md"
  grep -qF '`capture:screenshots/89468af1-undo.png`' "$T/scope-mut.md" \
    && pass "negative control: without the Claim-column guard the AC table IS rewritten (the guard is the control point)" \
    || fail "the Claim-column guard must be what spares the evidence-only table"
else
  fail "MUTATION SITE NOT FOUND — the stamp-scope guard moved; this control is dead"
fi

# ── 18. --stamp-types preserves authored column padding ───────────────────────────────────────
# The stamped cell necessarily grows by `<type>:`. Every OTHER byte of the row — including cells
# this rewrite has no business touching — must survive unchanged, and so must a row where nothing
# was stamped. That is the difference between a diff a consumer will review and one they will not.
mkpadfixture() { # <dest>
  cp "$TEMPLATE" "$1"
  {
    echo ""
    echo "### 11a. Standard Probe Library"
    echo ""
    echo "| Probe ID   | Claim type    | Discharge artifact                 | Exception |"
    echo "|------------|---------------|------------------------------------|-----------|"
    echo "| PROBE:cap  | \`persistence\` | \`screenshots/89468af1-ok.png\`      | —         |"
    echo "| PROBE:amb  | \`correctness\` | \`specs/logs/89468af1-read.log\`     | —         |"
  } >> "$1"
}
mkpadfixture "$T/pad.md"
run --stamp-types --write "$T/pad.md"
grep -qF '| PROBE:amb  | `correctness` | `specs/logs/89468af1-read.log`     | —         |' "$T/pad.md" \
  && pass "padding: a row where nothing was stamped is byte-identical" || fail "an unstamped row must not be reflowed"
grep -qF '| PROBE:cap  | `persistence` | `capture:screenshots/89468af1-ok.png`      | —         |' "$T/pad.md" \
  && pass "padding: on a stamped row only the evidence cell changes — its own pad, and every other cell, survive" \
  || fail "stamping must not collapse the row's padding"

# 18b. NEGATIVE CONTROL — restore the shipped rebuild-from-trimmed-cells. The stamped row must
# lose its alignment, which is exactly what made the 24-file migration diff unreviewable.
mkpadfixture "$T/pad-mut.md"
if mkmut "pad-rebuild.sh" \
  '  printf '"'"'%s%s%s'"'"' "${line:0:off}" "$new" "${line:off + ${#ROW_RAW[$idx]}}"' \
  '  local j out="|"; for (( j=0; j<${#ROW_CELLS[@]}; j++ )); do if [[ $j -eq $idx ]]; then out+=" $(sp_trim "$new") |"; else out+=" ${ROW_CELLS[$j]} |"; fi; done; printf '"'"'%s'"'"' "$out"'; then
  runmut --stamp-types --write "$T/pad-mut.md"
  grep -qF '| PROBE:cap | `persistence` | `capture:screenshots/89468af1-ok.png` | — |' "$T/pad-mut.md" \
    && pass "negative control: rebuilding the row from trimmed cells collapses the authored alignment (splice_cell is the control point)" \
    || fail "splice_cell must be what preserves the padding"
else
  fail "MUTATION SITE NOT FOUND — splice_cell's printf moved; this control is dead"
fi

# ── 19. Stamp mode reports what it examined ───────────────────────────────────────────────────
# #98 §4: a gate publishes its SUBJECT on every exit path. Stamp mode published SPECK_GATE_SUBJECT=0
# while rewriting 24 files — a gate reporting that it looked at nothing while changing the tree is
# indistinguishable from one that ran over an empty scope.
mkstampfixture "$T/telem.md"
run --stamp-types "$T/telem.md"
{ echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=2$" && echo "$OUT" | grep -q "^SPECK_GATE_MODE=stamp-types$"; } \
  && pass "stamp mode publishes the number of citations it actually examined (2), not 0" \
  || fail "stamp mode must publish a real SUBJECT"

if mkmut "telem-nosubject.sh" \
  '      GATE_SUBJECT=$((GATE_SUBJECT + 1))
      ty="$(citation_type_of "$core")"' \
  '      ty="$(citation_type_of "$core")"'; then
  runmut --stamp-types "$T/telem.md"
  echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=0$" \
    && pass "negative control: removing the stamp-path counter restores the SUBJECT=0 lie" \
    || fail "the stamp-path SUBJECT counter must be load-bearing"
else
  fail "MUTATION SITE NOT FOUND — the stamp-path SUBJECT counter moved; this control is dead"
fi

# ══════════════════════════════════════════════════════════════════════════════════════════════
# §11a STANDARD PROBE LIBRARY (issue #101, v10.2)
#
# THE FIXTURE RULE, AGAIN AND HARDER. Every fixture below is a COPY OF THE SHIPPED TEMPLATE with
# one cell edited by a transform that ASSERTS it found all eight rows. A hand-typed §11a table
# would be the shape-(a) vacuity this repo has shipped twice: the rule would pass on the fixture
# and say nothing about the artifact projects actually get.
# ══════════════════════════════════════════════════════════════════════════════════════════════
echo ""
echo "== §11a Standard Probe Library =="

PFIX="$T/probefix.py"
cat > "$PFIX" <<'PY'
import sys
src, dest = sys.argv[1], sys.argv[2]
ops = [o.split('~') for o in sys.argv[3:]]
lines = open(src).read().split('\n')
out, n = [], 0
for l in lines:
    if l.startswith('| PROBE:'):
        n += 1
        c = l.split('|')          # ['', id, class, claim, substrate, controls, discharge, exception, '']
        pid, drop = c[1].strip(), False
        for op in ops:
            k = op[0]
            if k == 'fill':                                    c[7] = ' n/a:fixture reason '
            elif k == 'delete'   and pid == op[1]:             drop = True
            elif k == 'discharge' and pid == op[1]:            c[6] = ' `%s` ' % op[2]
            elif k == 'claim'    and pid == op[1]:             c[3] = ' `%s` ' % op[2]
            elif k == 'except'   and pid == op[1]:             c[7] = ' %s ' % op[2]
            elif k == 'rename'   and pid == op[1]:             c[1] = ' %s ' % op[2]
        if drop: continue
        l = '|'.join(c)
    out.append(l)
assert n == 8, 'MUTATION SITE NOT FOUND — the shipped template has %d §11a PROBE rows, expected 8' % n
open(dest, 'w').write('\n'.join(out))
PY
probefixture() { local dest="$1"; shift; python3 "$PFIX" "$TEMPLATE" "$dest" "$@"; }

# ── 15. The library is closed, and the template renders it exactly ────────────────────────────
run --print-probe-library
{ [[ "$RC" == 0 ]] && [[ "$(echo "$OUT" | grep -c '^PROBE:')" == 8 ]]; } \
  && pass "the probe library is 8 closed classes" || fail "--print-probe-library must list 8 classes"

# PARITY against the SHIPPED template — the §11a analogue of test 2, and what stops the template's
# table being decoration a project can edit into agreement with anything.
run --check-probe-library "$TEMPLATE"
{ [[ "$RC" == 0 ]] && [[ "$(count 'PROBE_LIBRARY_DRIFT')" == 0 ]]; } \
  && pass "shipped template §11a matches the compiled library, cell for cell" \
  || fail "shipped template §11a has drifted from the compiled library"

# ── 16. The template ships UNDISCHARGED on purpose — the anti-vacuity property ────────────────
# If the shipped boilerplate satisfied this gate, a green would mean "nobody edited the template",
# not "the class was proved". So the unedited artifact must be the SIN.
run --check-probe-library "$TEMPLATE"
{ [[ "$RC" == 0 ]] && [[ "$(count 'PROBE_UNDECLARED.P1')" == 8 ]]; } \
  && pass "the unedited template raises 8 PROBE_UNDECLARED.P1 — and still exits 0 (nudge, not block)" \
  || fail "the unedited template must raise exactly 8 PROBE_UNDECLARED.P1 at exit 0"
run --strict --check-probe-library "$TEMPLATE"
[[ "$RC" == 1 ]] && pass "--strict escalates the same findings to exit 1 (the COMMERCIAL-RC/SHIP-RC posture)" \
  || fail "--strict must exit 1 on undeclared classes"

# The paired positive: declaring every row clears it. Without this the P1 above could be
# unconditional — a rule that always fires proves nothing about the artifact.
probefixture "$T/p11a-filled.md" fill
run --strict --check-probe-library "$T/p11a-filled.md"
{ [[ "$RC" == 0 ]] && [[ "$(count 'PROBE_UNDECLARED.P1')" == 0 ]] && [[ "$(count 'PROBE_EXCEPTION_DECLARED')" == 8 ]]; } \
  && pass "declaring an exception on every row clears all 8 (the P1 is conditional, not unconditional)" \
  || fail "a fully declared §11a must be green"

# ── 17. PROBE_SUBSTRATE_MISMATCH.P1 is a real LOOKUP into §2b, per class ─────────────────────
# The P6 scar, in the row that owns it: a props-level suite cited for `fit`.
probefixture "$T/p11a-mismatch.md" fill "discharge~PROBE:geometry-ax~test:frontend/src/WeekGrid.fits.test.tsx@89468af1"
run --strict --check-probe-library "$T/p11a-mismatch.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "PROBE:geometry-ax discharged by a \`test\` citation → P1 (axe is blind to geometry)" \
  || fail "a fit class discharged by a test citation must be P1"

# The admissible counterpart on the SAME row — so the P1 is about the substrate, not the row.
probefixture "$T/p11a-ok.md" fill "discharge~PROBE:geometry-ax~geometry:specs/logs/89468af1-target-size.json"
run --strict --check-probe-library "$T/p11a-ok.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "PROBE_DISCHARGED"; } \
  && pass "the same row discharged by a \`geometry\` citation is admissible" || fail "geometry must discharge fit"

# NEGATIVE CONTROL — the control point is §2b's admissibility table, and nothing else.
if mkmut "probe-fit-admits-test.sh" \
  '    fit)         printf '"'"'%s'"'"' "ax-dump geometry device-walk" ;;' \
  '    fit)         printf '"'"'%s'"'"' "ax-dump geometry device-walk test" ;;'; then
  runmut --strict --check-probe-library "$T/p11a-mismatch.md"
  { [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
    && pass "negative control: admitting \`test\` for \`fit\` in §2b makes the §11a mismatch vanish" \
    || fail "the §11a mismatch must be computed from the admissibility table"
else
  fail "MUTATION SITE NOT FOUND — claim_admissible_types' fit row moved; this control is dead"
fi

# ── 18. UNKNOWN NEVER CONVICTS — the load-bearing decision in (b) ─────────────────────────────
probefixture "$T/p11a-unknown.md" fill "discharge~PROBE:geometry-ax~specs/logs/89468af1-target-size.json"
run --strict --check-probe-library "$T/p11a-unknown.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_UNKNOWN.P3" && ! echo "$OUT" | grep -q "\.P1"; } \
  && pass "an untyped discharge artifact is P3 and exits 0 — unknown is incomplete, not inadmissible" \
  || fail "an unknown citation type must never convict"
echo "$OUT" | grep -q -- "--stamp-types --write" \
  && pass "the unknown-substrate P3 names the command that makes the verdict computable" \
  || fail "PROBE_SUBSTRATE_UNKNOWN must name its fix"

# NEGATIVE CONTROL — the P3 is a real branch, not the absence of a rule. Resolve unknown to
# inadmissible in a scratch copy and the SAME fixture must go red.
if mkmut "probe-unknown-convicts.sh" \
  'emit_p3 "PROBE_SUBSTRATE_UNKNOWN.P3" "$file — $pid discharges' \
  'emit_p1 "PROBE_SUBSTRATE_UNKNOWN.P1" "$file — $pid discharges'; then
  runmut --strict --check-probe-library "$T/p11a-unknown.md"
  [[ "$RC" == 1 ]] \
    && pass "negative control: making unknown convict turns the same fixture red (P3 is a decision, not a gap)" \
    || fail "the unknown branch must be load-bearing"
else
  fail "MUTATION SITE NOT FOUND — the PROBE_SUBSTRATE_UNKNOWN emit moved; this control is dead"
fi

# ── 19. A declared exception is FIRST-CLASS — absence vs inapplicability ─────────────────────
# The same law as GATE_EMPTY_LEGITIMATE vs GATE_VACUOUS: a class that does not apply is DECLARED.
probefixture "$T/p11a-na.md" fill "except~PROBE:money-path~n/a:no revenue path"
run --strict --check-probe-library "$T/p11a-na.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "PROBE_EXCEPTION_DECLARED.*money-path"; } \
  && pass "\`n/a:<reason>\` is a first-class declaration, not a silence" || fail "n/a with a reason must be accepted"

probefixture "$T/p11a-bare-na.md" fill "except~PROBE:money-path~n/a"
run --strict --check-probe-library "$T/p11a-bare-na.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "PROBE_NA_UNBACKED.P2"; } \
  && pass "a bare \`n/a\` with no reason is PROBE_NA_UNBACKED.P2 (indistinguishable from 'nobody looked')" \
  || fail "bare n/a must be P2"

probefixture "$T/p11a-waived.md" fill "except~PROBE:money-path~waived DEC-0042"
run --check-probe-library "$T/p11a-waived.md"
echo "$OUT" | grep -q "PROBE_NA_UNBACKED.P2" \
  && fail "a waiver citing a DEC must not be P2 merely because no log was found" \
  || pass "a waiver with no findable decisions log is recorded as unverified, never convicted"

mkdir -p "$T/dec" && probefixture "$T/dec/evidence-contract.md" fill "except~PROBE:money-path~waived DEC-0042"
printf '# Decisions\n\n## DEC-0042 — accept the dark money path\n' > "$T/dec/project-decisions-log.md"
run --strict --check-probe-library "$T/dec/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "waived DEC-0042 (resolves"; } \
  && pass "\`waived DEC-####\` resolving in project-decisions-log.md is a backed exception" \
  || fail "a resolving DEC must back the waiver"
printf '# Decisions\n\n## DEC-0001 — something else\n' > "$T/dec/project-decisions-log.md"
run --check-probe-library "$T/dec/evidence-contract.md"
echo "$OUT" | grep -q "PROBE_NA_UNBACKED.P2" \
  && pass "a waiver whose DEC is missing from the log is PROBE_NA_UNBACKED.P2" \
  || fail "an unresolvable DEC must be P2"

probefixture "$T/p11a-prose.md" fill "except~PROBE:money-path~doesn't apply to us"
run --check-probe-library "$T/p11a-prose.md"
echo "$OUT" | grep -q "PROBE_NA_UNBACKED.P2" \
  && pass "an exception Speck cannot parse is a silence with extra words (P2)" || fail "prose exception must be P2"

# ── 20. The library is CLOSED: a deleted row is an undeclared class ──────────────────────────
probefixture "$T/p11a-deleted.md" fill "delete~PROBE:second-actor"
run --strict --check-probe-library "$T/p11a-deleted.md"
{ [[ "$RC" == 1 ]] && [[ "$(count 'PROBE_UNDECLARED.P1')" == 1 ]] && echo "$OUT" | grep -q "absent from §11a"; } \
  && pass "deleting a class from an otherwise-declared §11a raises exactly one PROBE_UNDECLARED.P1" \
  || fail "a deleted class must be undeclared, not silently gone"

if mkmut "probe-no-completeness.sh" \
  '    in_list "$pid" "$seen" && continue
    emit_p1 "PROBE_UNDECLARED.P1" "$file — $pid ($(probe_field "$pid" 2)) is absent' \
  '    continue
    emit_p1 "PROBE_UNDECLARED.P1" "$file — $pid ($(probe_field "$pid" 2)) is absent'; then
  runmut --strict --check-probe-library "$T/p11a-deleted.md"
  [[ "$RC" == 0 ]] \
    && pass "negative control: removing the closed-set sweep lets a deleted class pass green" \
    || fail "the closed-set completeness sweep must be load-bearing"
else
  fail "MUTATION SITE NOT FOUND — the completeness sweep moved; this control is dead"
fi

probefixture "$T/p11a-newid.md" fill "rename~PROBE:substrate~PROBE:my-own-idea"
run --check-probe-library "$T/p11a-newid.md"
{ echo "$OUT" | grep -q "not one of Speck" && echo "$OUT" | grep -q "PROBE_UNDECLARED.P1"; } \
  && pass "a project-invented probe ID is drift AND leaves its real class undeclared (§11a is closed)" \
  || fail "an unknown probe ID must be rejected"

# ── 21. Speck-owned cells are parity-checked, and the LOOKUP ignores the cell ─────────────────
# Without this, weakening a row's claim type to `correctness` — which admits everything — would
# silently dissolve every mismatch that row could ever raise. The most valuable single assertion
# here: the drift is reported AND the mismatch still fires, because the lookup routes off the
# COMPILED claim type, never the cell a project can edit.
probefixture "$T/p11a-weakened.md" fill \
  "claim~PROBE:geometry-ax~correctness" \
  "discharge~PROBE:geometry-ax~test:frontend/src/WeekGrid.fits.test.tsx"
run --check-probe-library "$T/p11a-weakened.md"
{ echo "$OUT" | grep -q "PROBE_LIBRARY_DRIFT.P2" && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "weakening a row's claim type is drift AND does not dissolve the mismatch (the cell is not the oracle)" \
  || fail "editing the claim-type cell must not change the admissibility verdict"

# ── 22. PROBE_LIBRARY_ABSENT.P3 and the scaffold that fixes it ───────────────────────────────
awk '/^## 11a\./{ins=1} ins && /^## 12\./{ins=0} !ins' "$TEMPLATE" > "$T/p11a-absent.md"
grep -q '^## 11a\.' "$T/p11a-absent.md" && fail "fixture setup: §11a was not stripped" || true
run --strict --check-probe-library "$T/p11a-absent.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "PROBE_LIBRARY_ABSENT.P3"; } \
  && pass "a contract with no §11a is P3 at exit 0 — every pre-v10.2 contract, unblocked" \
  || fail "an absent §11a must be a P3 nudge"
echo "$OUT" | grep -q -- "--scaffold-probe-library --write" \
  && pass "the absent-library P3 names the command that fixes it" || fail "P3 must name the scaffold command"

cp "$T/p11a-absent.md" "$T/p11a-dryrun.md"
run --scaffold-probe-library "$T/p11a-dryrun.md"
diff -q "$T/p11a-absent.md" "$T/p11a-dryrun.md" >/dev/null 2>&1 \
  && pass "--scaffold-probe-library without --write does not touch the file" || fail "scaffold dry-run must not write"

run --scaffold-probe-library --write "$T/p11a-absent.md"
run --check-probe-library "$T/p11a-absent.md"
{ [[ "$(count 'PROBE_LIBRARY_DRIFT')" == 0 ]] && [[ "$(count 'PROBE_UNDECLARED.P1')" == 8 ]]; } \
  && pass "a scaffolded §11a round-trips drift-free, and lands UNDISCHARGED (never pre-filled green)" \
  || fail "the scaffold must round-trip clean and undischarged"
run --scaffold-probe-library --write "$T/p11a-absent.md"
echo "$OUT" | grep -q "PROBE_LIBRARY_PRESENT" \
  && pass "scaffolding twice is a no-op" || fail "scaffold must be idempotent"

# ── 23. The default scan reaches §11a's own table without a second parser ────────────────────
# §11a is a citation site by construction (a Claim column + a Discharge artifact column), so the
# plain scan computes the same P1. Two readers of one table would be two places to drift.
run --strict "$T/p11a-mismatch.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "PROBE_SUBSTRATE_MISMATCH.P1"; } \
  && pass "the plain scan resolves §11a as a citation site and reaches the same verdict" \
  || fail "§11a must be a citation site for the default scan too"

# ── 24. Telemetry on the new exit paths (#98 §4) ─────────────────────────────────────────────
# `break 2` out of the inner loop used to land on an UNCONDITIONAL `pass`, so a telemetry
# regression printed a ✓ beside its own ✗. The suite still exited 1 (fail() sets FAILED=1), so
# nothing was certified falsely — but a green tick next to a red cross, in a suite whose entire
# subject is honest verdicts, is the wrong artifact to ship. The flag makes the pass conditional.
_telemetry_ok=true
for args in "--print-probe-library" "--check-probe-library $TEMPLATE" "--scaffold-probe-library $T/p11a-dryrun.md"; do
  # shellcheck disable=SC2086
  run $args
  for k in SPECK_GATE_SCOPE SPECK_GATE_SUBJECT SPECK_GATE_PREDICATES SPECK_GATE_MODE; do
    echo "$OUT" | grep -q "^$k=" || { fail "telemetry $k missing on '$args'"; _telemetry_ok=false; break 2; }
  done
done
[[ "$_telemetry_ok" == true ]] && pass "the three §11a modes publish SCOPE/SUBJECT/PREDICATES/MODE"
run --check-probe-library "$TEMPLATE"
{ echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=8$" && echo "$OUT" | grep -q "^SPECK_GATE_MODE=check-probe-library$"; } \
  && pass "the §11a check publishes the 8 classes it actually read, not 0" || fail "§11a check must publish a real SUBJECT"

# ── 25. IT IS WIRED — the assertion this whole cluster is about ───────────────────────────────
# v10.1 shipped this validator with no hook, no CI step and no §6a row, so the rule it implements
# could not fail a build. "It exists" is not wiring. Both halves are pinned here:
#   (a) seed-gate-registry.sh DECLARES it in §6a, so validate-gate-liveness.sh sees it;
#   (b) seed-gate-registry.sh RUNS it on the contract it just wrote.
SEED="$ROOT/.speck/scripts/seed-gate-registry.sh"
RECIPE_FOR_WIRING="$ROOT/.speck/recipes/nextjs-supabase/recipe.yaml"
WOUT="$(bash "$SEED" "$RECIPE_FOR_WIRING" 2>&1 || true)"
{ echo "$WOUT" | grep -q '^| speck:evidence-citations | `.speck/scripts/validation/validators/validate-evidence-citations.sh specs/` | manual |' \
  && echo "$WOUT" | grep -q '^| speck:probe-library | `.speck/scripts/validation/validators/validate-evidence-citations.sh --check-probe-library` | manual |'; } \
  && pass "wired (a): seed-gate-registry.sh emits both standing §6a rows, so the gate is DECLARED" \
  || fail "the standing §6a rows must be seeded"

# The seeded rows must survive the header-keyed round-trip the same way the recipe's do — they go
# through the same producer precisely so a column insert cannot shift only one of the two sets.
echo "$WOUT" | grep -q '^| speck:evidence-citations |.*| evidence | specs/\*\* | citations>0 | — | — |$' \
  && pass "wired (a2): the standing row's Scope/Subject land in their own header-named cells" \
  || fail "the standing row's cells must align with the §6a header"

WIRED_CONTRACT="$T/wired/evidence-contract.md"
mkdir -p "$T/wired" && cp "$TEMPLATE" "$WIRED_CONTRACT"
WRC=0; WOUT2="$(bash "$SEED" "$RECIPE_FOR_WIRING" --contract "$WIRED_CONTRACT" 2>&1)" || WRC=$?
{ [[ "$WRC" == 0 ]] \
  && echo "$WOUT2" | grep -q "SPECK_GATE_MODE=check-contract" \
  && echo "$WOUT2" | grep -q "SPECK_GATE_MODE=check-probe-library"; } \
  && pass "wired (b): seeding a contract RUNS both standing gates on it — and still exits 0 (nudge)" \
  || fail "seeding a contract must run the citation + §11a gates without blocking"
echo "$WOUT2" | grep -q "PROBE_UNDECLARED.P1" \
  && pass "wired (b2): the run reports real findings on the seeded contract (not a silent no-op)" \
  || fail "the wired run must actually produce findings"

echo ""
if [[ "$FAILED" == 0 ]]; then
  echo "✅ validate-evidence-citations.sh — all tests passed"
  exit 0
fi
echo "❌ validate-evidence-citations.sh — FAILURES"
exit 1
