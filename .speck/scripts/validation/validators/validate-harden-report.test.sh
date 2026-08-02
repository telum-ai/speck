#!/usr/bin/env bash
# validate-harden-report.test.sh — proves the harden report is no longer exempt, and that the
# Mutation Record placeholders are ENFORCEABLE rather than prose.
#
# NOTE ON PIPEFAIL, repeated at every assertion site because it has silently inverted assertions
# in this repo before: never write `if some-validator ... | grep -q X; then`. Under
# `set -o pipefail` the pipeline reports the VALIDATOR's status, not the match, so the assertion
# becomes one that cannot fail. Capture into a variable, then grep the variable.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-harden-report.sh"
ROUTER="$ROOT/.speck/scripts/validation/validate-template.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/specs"
PASS=0

ok()  { echo "  ✓ $1"; PASS=$((PASS + 1)); }
bad() { echo "  ✗ $1" >&2; exit 1; }

# Exit status of a command, without letting set -e abort us.
rc_of() { set +e; "$@" >/dev/null 2>&1; local r=$?; set -e; printf '%s' "$r"; }

# --- a complete, FILLED v10 harden report (the conformance fixture) ---------------------------
# Written by hand rather than substituted from the template so that a template edit that breaks
# the validator, or a validator edit that the template cannot satisfy, both show up as a failure
# here instead of silently agreeing with each other.
write_report() {
  cat > "$1" <<'EOF'
---
speck_version: 10.0
template_version: "10.0.0"
artifact_type: harden-report
mutation_record: required
---

# Post-Validation Hardening Report: Outbox re-enqueue

**Defect ID**: `HARDEN-004-outbox-owner`

---

## 1. Defect Description (The Truth)

- **Observed Behavior**: Athlete B re-enqueued athlete A's payload under B's identity.
- **Impact Severity**: P0 - Blocker
- **Found by**: Founder post-ship walkthrough

---

## 2. Root Cause Analysis (The Gap)

- **Technical Root Cause**: `retryDroppedWrite` never compared the notice owner to the tapper.
- **Gate Defect (Why did gates miss it?)**: The suite REQUIRED the behaviour — see 2b.

---

## 2b. Counter-Tests (The Suite's Shadow)

- **Pre-Fix Grep**: `rg -n "deliberate claim by the tapper" apps/mobile/__tests__`
- **Pre-Existing Tests That Went Red**: `pendingWriteOutbox.test.ts:214` · "turns the unverifiable entry into a deliberate claim by the tapper" · DEFECT-PINNING
- **If None Went Red**: not applicable — one pre-existing test went red.

---

## 3. Remediations & Hardening Guardrails (The Fix)

- **Implementation Fix**: Compare `notice.ownerId` to the tapper before re-enqueueing.
- **Regression Test**: `refuses to re-enqueue an UNOWNED notice under the tapper`
- **Systemic Guardrail Added**: An owner-identity assertion in the outbox contract tests.
- **Guardrail Mutation-Proof**: `lib/pendingWriteOutbox.ts:118` · match count 1 · 2 red · control `enqueues an OWNED notice` stayed green · GUARD_MUTATION_PROVEN
- **Class Recurrence Check**: first instance; shape grep `rg -n "ownerId ===" apps/mobile/lib` found no second site.

---

## 4. Readiness Re-assessment

- **Affected Artifacts**: `stories/S010/validation-report.md`
- **Prior State**: SHIP-RC
- **Re-assessed State**: SHIP-RC
- **Verification Proof**: test-output.txt
EOF
}

# --- the SAME report, DERIVED FROM THE SHIPPED TEMPLATE ---------------------------------------
# The hand-typed fixture above and this one are both required, and they fail in opposite
# directions. The hand-typed one catches a template edit the validator cannot satisfy. This one
# catches the defect class that got through four audit rounds: a rule whose grep is satisfied by
# the TEMPLATE'S OWN EXPLANATORY BOILERPLATE, so it passes on every report the template produces
# while the hand-typed fixture — which omits that boilerplate — still looks like it proves the
# rule. Both §2b's class-code check and the Mutation Record's verdict-code check were vacuous
# exactly this way. Every placeholder is filled; nothing else in the template is touched, so the
# `- \`DEFECT-PINNING\` — the assertion encodes the bug…` bullets are PRESENT in the fixture.
write_report_from_template() {
  python3 - "$ROOT/.speck/templates/project/harden-template.md" "$1" <<'PY'
import re, sys, pathlib
FILL = {
  "SEARCH_QUERY": '`rg -n "deliberate claim by the tapper" apps/mobile/__tests__`',
  "TEST_PATH": '`pendingWriteOutbox.test.ts:214` · "turns the unverifiable entry into a deliberate claim by the tapper" · DEFECT-PINNING',
  "NO_PRE_EXISTING": "not applicable — one pre-existing test went red.",
  "MUTATION_SITE": "`lib/pendingWriteOutbox.ts:118`",
  "MATCH_COUNT": "match count 1",
  "RED_TESTS": "2 red",
  "GREEN_CONTROL": "control `enqueues an OWNED notice` stayed green",
  "VERDICT_CODE": "GUARD_MUTATION_PROVEN",
  "SECOND_INSTANCE": 'first instance; shape grep `rg -n "ownerId ===" apps/mobile/lib` found no second site',
}
def fill(m):
    key = m.group(1).strip().split()[0].rstrip(":")
    return FILL.get(key, "a real transcribed value")
src = pathlib.Path(sys.argv[1]).read_text()
out = re.sub(r"\[([^\]\n]+)\]", fill, src)
assert "`DEFECT-PINNING` — the assertion encodes the bug" in out, \
    "the template's class-explanation boilerplate vanished — this fixture no longer guards the vacuity"
pathlib.Path(sys.argv[2]).write_text(out)
PY
}

R="$TMP/specs/project-harden-report-20260801.md"

echo "Test 1: a complete v10 harden report passes (template ↔ validator conformance)"
write_report "$R"
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "0" ] || bad "the filled report should pass"
ok "filled report passes"

echo "Test 2: the harden report is no longer routed to the exempt branch"
# Before this cluster, validate-template.sh matched *harden-report*.md and exited 0 with the
# comment "no additional structural sub-validator needed" — so NOTHING below could fail.
write_report "$R"
python3 - "$R" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
s = re.sub(r"\n## 2b\..*?\n---\n", "\n", s, flags=re.S)
open(p, "w").write(s)
PY
if grep -qE '^## 2b\.' "$R"; then bad "fixture setup failed: §2b still present"; fi
OUT="$(bash "$ROUTER" "$R" --strict 2>&1 || true)"
[ "$(rc_of bash "$ROUTER" "$R" --strict)" = "1" ] || bad "the ROUTER let a §2b-less harden report through — the exempt branch is still live"
# Assert the ERROR text specifically. An earlier version grepped for "2b. Counter-Tests", which the
# validator ALSO prints on its `✓ section present: 2b. Counter-Tests` success line — so the
# assertion matched a pass and could not fail. Proven by mutation: forcing the §2b presence branch
# to `if true` left that version green.
grep -q "Missing required section '## 2b" <<<"$OUT" || bad "the router's failure does not name §2b as missing: $OUT"
ok "validate-template.sh reaches the structural validator (the chokepoint, (d))"

echo "Test 3: a missing **Guardrail Mutation-Proof** field fails"
write_report "$R"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
kept = [l for l in open(p) if "Guardrail Mutation-Proof" not in l]
open(p, "w").write("".join(kept))
PY
OUT="$(bash "$VALIDATOR" --strict "$R" 2>&1 || true)"
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "a report with no mutation proof passed"
grep -q "Guardrail Mutation-Proof" <<<"$OUT" || bad "error does not name the field"
ok "the guardrail claim cannot be made without a mutation proof"

echo "Test 4: a HAND-TYPED verdict is not a verdict — only the code mutate-guard.sh printed counts"
write_report "$R"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("GUARD_MUTATION_PROVEN", "proven, I checked it myself")
open(p, "w").write(s)
PY
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "a prose verdict passed"
ok "prose verdict rejected"

echo "Test 5: GUARD_MUTATION_GREEN.P2 is accepted — the honest branch must never be a failure"
write_report "$R"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("GUARD_MUTATION_PROVEN", "GUARD_MUTATION_GREEN.P2")
open(p, "w").write(s)
PY
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "0" ] || bad "MUTATION-GREEN was treated as a failure — that is the incentive to tune a mutation until it reddens"
ok "MUTATION-GREEN accepted (non-blocking by design)"

echo "Test 6: §2b answering NEITHER branch fails; answering only the zero-red sentence passes"
# ON A TEMPLATE-DERIVED FIXTURE. The hand-typed version of this test could not fail: the check it
# guards grepped the whole §2b BODY for DEFECT-PINNING|DECISION-RECORD|SCOPE-NARROWING, and §2b of
# harden-template.md defines those three literals in its own bullets — so has_class was true on
# every real report. The hand-typed fixture omitted the bullets, which is the only reason it looked
# red. Proven live before the fix: a template-derived report reading `Pre-Existing Tests That Went
# Red: none` / `If None Went Red: n/a` printed `✓ §2b answers the counter-test sweep` and exited 0.
write_report_from_template "$R"
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "0" ] || bad "the template-derived report should pass as generated (template ↔ validator conformance)"
grep -q '`DEFECT-PINNING` — the assertion encodes the bug' "$R" || bad "fixture setup failed: the template's class boilerplate is absent, so this test cannot see the vacuity"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("`pendingWriteOutbox.test.ts:214` · \"turns the unverifiable entry into a deliberate claim by the tapper\" · DEFECT-PINNING", "none")
s = s.replace("not applicable — one pre-existing test went red.", "n/a")
open(p, "w").write(s)
PY
OUT="$(bash "$VALIDATOR" --strict "$R" 2>&1 || true)"
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "§2b with neither branch answered passed ON A TEMPLATE-DERIVED REPORT — the class grep is reading the template's own bullets: $OUT"
grep -q "answers neither branch" <<<"$OUT" || bad "the failure does not name the unanswered §2b: $OUT"
ok "neither-branch §2b rejected (with the template's class boilerplate present)"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("- **If None Went Red**: n/a",
              "- **If None Went Red**: No pre-existing test went red, because the outbox retry path had no coverage at all — that gap is itself a finding and is carried into 3.")
open(p, "w").write(s)
PY
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "0" ] || bad "an honestly answered zero-red sentence should pass"
ok "the zero-red sentence is the requirement — not a hunt for something to break"

echo "Test 6b: §2b listing red tests but classifying NONE of them fails"
# The other half of the same rule: the cell is a CLAIM, so it must carry its class. Answering the
# zero-red sentence does not buy an exemption from classifying tests you said went red.
write_report_from_template "$R"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace(' · DEFECT-PINNING', '')
s = s.replace("- **If None Went Red**: not applicable — one pre-existing test went red.",
              "- **If None Went Red**: not applicable, because one pre-existing test went red.")
open(p, "w").write(s)
PY
# Setup assertions, both directions: the class boilerplate is still there, the authored cell is not.
grep -q '`DEFECT-PINNING` — the assertion encodes the bug' "$R" || bad "fixture setup failed: class boilerplate gone"
RED_LINE="$(grep -F '**Pre-Existing Tests That Went Red**' "$R")"
if grep -qE 'DEFECT-PINNING|DECISION-RECORD|SCOPE-NARROWING' <<<"$RED_LINE"; then bad "fixture setup failed: the cell still carries a class"; fi
OUT="$(bash "$VALIDATOR" --strict "$R" 2>&1 || true)"
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "an unclassified red-test list passed: $OUT"
grep -q "classifies none of them" <<<"$OUT" || bad "the failure does not name the missing classification: $OUT"
ok "an unclassified red test is a finding, not a free pass"

echo "Test 7: a missing **Class Recurrence Check** fails (#100 §1)"
write_report "$R"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
kept = [l for l in open(p) if "Class Recurrence Check" not in l]
open(p, "w").write("".join(kept))
PY
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "no class-recurrence check passed"
ok "class-recurrence check required"

echo "Test 8: a missing core section fails (this artifact had NO structural validator before)"
write_report "$R"
python3 - "$R" <<'PY'
import sys, re
p = sys.argv[1]
s = re.sub(r"## 1\. Defect Description \(The Truth\)", "## Whatever", open(p).read())
open(p, "w").write(s)
PY
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "a report with no §1 passed"
ok "core sections asserted"

echo "Test 9: a PRE-v10 report is exempt — nothing already on disk breaks (why no migration)"
cat > "$R" <<'EOF'
---
speck_version: 8.0
template_version: "7.13.2"
artifact_type: harden-report
---

# Post-Validation Hardening Report: legacy

## 1. Defect Description (The Truth)
- **Observed Behavior**: something
## 2. Root Cause Analysis (The Gap)
- **Technical Root Cause**: something
## 3. Remediations & Hardening Guardrails (The Fix)
- **Implementation Fix**: something
## 4. Readiness Re-assessment
- **Prior State**: SHIP-RC
EOF
OUT="$(bash "$VALIDATOR" --strict "$R" 2>&1 || true)"
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "0" ] || bad "a pre-v10 report was convicted: $OUT"
grep -q "pre-v10 harden report" <<<"$OUT" || bad "the exemption is silent — it must be printed"
ok "pre-v10 exempt, and the exemption is NOTICED rather than silent"

echo "Test 10: vintage cannot be dodged by deleting one frontmatter line while keeping the sections"
write_report "$R"
python3 - "$R" <<'PY'
import sys
p = sys.argv[1]
s = "".join(l for l in open(p) if not l.startswith("mutation_record:") and not l.startswith("speck_version:"))
s = s.replace("- **Class Recurrence Check**", "- **Removed Class Recurrence Check**")
open(p, "w").write(s)
PY
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "deleting the vintage declaration bought an exemption while keeping §2b"
ok "carrying the section means being held to it"

# --- (c) THE PLACEHOLDER RED/GREEN PAIR -------------------------------------------------------
# The forms proposed in #94 and #99 are lowercase and multi-line. The scanner in
# validate-template.sh matches `\[([^\]\n]+)\]` (single-line only) and skips any bracket whose
# content starts lowercase (is_prose_annotation), so those forms exit 0 — they would have been
# unenforceable prose, reproducing the exact defect the issues were filed about.
echo "Test 11: the placeholder form proposed in the issues escapes the scanner (the counterfactual)"
cat > "$TMP/specs/counterfactual-probe.md" <<'EOF'
# t

- **Guardrail Mutation-Proof**: [production `path:line` mutated · match count · the
  named tests that went red with counts · for a drop/filter guard, the control showing
  legitimate content survives · `RED-AS-EXPECTED` / `MUTATION-GREEN` / `UNMUTATED`]
- **Pre-fix grep**: [the query used to search the suite for assertions naming the old
  behaviour]
EOF
PH_RC="$(rc_of bash "$ROUTER" "$TMP/specs/counterfactual-probe.md" --strict)"
[ "$PH_RC" = "0" ] || bad "expected the lowercase multi-line form to pass the scanner (premise of the ALL-CAPS choice); got $PH_RC"
ok "confirmed: the issues' own placeholder form is unenforceable — hence ALL-CAPS single-line"

echo "Test 12: every ALL-CAPS placeholder the three templates ship IS flagged (red), and its filled form is not (green)"
for PH in \
  '[MUTATION_SITE PATH AND LINE]' \
  '[MATCH_COUNT]' \
  '[RED_TESTS NAMES AND COUNTS]' \
  '[GREEN_CONTROL THAT STAYED GREEN]' \
  '[VERDICT_CODE FROM MUTATE GUARD]' \
  '[SEARCH_QUERY RUN OVER THE SUITE BEFORE WRITING THE FIX]' \
  '[TEST_PATH AND NAME AND CLASS PER ENTRY]' \
  '[NO_PRE_EXISTING TEST WENT RED BECAUSE THE HONEST REASON]' \
  '[SECOND_INSTANCE OF THIS SHAPE FOUND OR NOT AND THE SHAPE GREP USED]' \
  '[GUARD_TEST PATH AND NAME]' \
  '[GREEN_CONTROL TEST NAME]' \
  '[MERGE_COMMIT SHA]' ; do
  F="$TMP/specs/ph-probe.md"
  printf '# t\n\n- **Field**: %s\n' "$PH" > "$F"
  [ "$(rc_of bash "$ROUTER" "$F" --strict)" = "1" ] || bad "placeholder NOT flagged (unenforceable): $PH"
  printf '# t\n\n- **Field**: a real transcribed value\n' > "$F"
  [ "$(rc_of bash "$ROUTER" "$F" --strict)" = "0" ] || bad "filled form was wrongly flagged, next to: $PH"
done
ok "all 12 shipped placeholders are red unfilled and green filled"

echo "Test 13: every placeholder in the SHIPPED templates is one the scanner actually flags"
# Guards the pair above against the templates drifting to a form the scanner ignores.
python3 - "$ROOT" <<'PY'
import re, subprocess, sys, tempfile, os, pathlib
root = sys.argv[1]
tpls = [
  ".speck/templates/project/harden-template.md",
  ".speck/templates/story/validation-report-template.md",
  ".speck/templates/epic/epic-validation-report-template.md",
]
# EVERY bracket placeholder inside the REGIONS this cluster owns — deliberately NOT a list of the
# names we happened to choose. An earlier version of this test matched the placeholders by their
# ALL-CAPS names, which made it vacuous in the one direction that matters: renaming a placeholder
# to the issues' lowercase form REMOVED it from the checked set, so the drift the test exists to
# catch was the drift it stopped looking at. Proven by mutation — that version stayed green when
# `[VERDICT_CODE FROM MUTATE GUARD]` was replaced with `[the verdict mutate-guard printed]`.
# Region = the sections this cluster added, so the rest of each template stays out of scope.
BRACKET = re.compile(r"\[([^\]\n]+)\]")


def regions(text):
    out = []
    lines = text.split("\n")
    grab = False
    for ln in lines:
        if ln.startswith("## "):
            grab = ln.startswith("## 2b.") or ln.startswith("## 🧬 Mutation Record")
            continue
        if grab:
            out.append(ln)
        elif "**Guardrail Mutation-Proof**" in ln or "**Class Recurrence Check**" in ln:
            out.append(ln)
    return "\n".join(out)


found = []
for t in tpls:
    found += ["[%s]" % g for g in BRACKET.findall(regions(pathlib.Path(root, t).read_text()))]
assert found, "no cluster placeholders found in the templates — did the sections get renamed?"
d = tempfile.mkdtemp(); os.makedirs(os.path.join(d, "specs"))
f = os.path.join(d, "specs", "drift-probe.md")
router = os.path.join(root, ".speck/scripts/validation/validate-template.sh")
for ph in sorted(set(found)):
    pathlib.Path(f).write_text("# t\n\n- **Field**: %s\n" % ph)
    r = subprocess.run(["bash", router, f, "--strict"], capture_output=True)
    assert r.returncode == 1, "template ships a placeholder the scanner IGNORES: %s" % ph
print("  ✓ %d distinct shipped placeholders, all enforceable" % len(set(found)))
PY
PASS=$((PASS + 1))

# --- the shared Mutation Record check on validation reports -----------------------------------
echo "Test 14: --mutation-record-only enforces the section on a v10 validation report"
V="$TMP/specs/validation-report.md"
cat > "$V" <<'EOF'
---
artifact_type: validation-report
mutation_record: required
---

# Validation Report

## ✅ Gate Criteria Check
| Gate | Evidence |
|---|---|
| Unit tests pass | `tests/guards/owner.test.ts` |
EOF
[ "$(rc_of bash "$VALIDATOR" --mutation-record-only --strict "$V")" = "1" ] || bad "a v10 validation report with no Mutation Record passed"
# The Verdicts paragraph is COPIED VERBATIM FROM validation-report-template.md, and it is the whole
# point of this fixture. Without it the row-level rule looked enforced while being satisfied, on
# every real report, by that paragraph naming all three codes inside the section body. Proven live
# before the fix: this exact section with its only row reading
# `| n/a | n/a | n/a | n/a | n/a | looks fine to me |` printed
# `✓ Mutation Record carries a machine-emitted verdict code` and exited 0.
cat >> "$V" <<'EOF'

## 🧬 Mutation Record

| Guard cited as evidence | Mutation site | Match count | Tests that went red | Green control | Verdict |
|---|---|---|---|---|---|
| `tests/guards/owner.test.ts` | `lib/outbox.ts:118` | 1 | 2 | `enqueues an OWNED notice` | GUARD_MUTATION_PROVEN |

**Verdicts.** `GUARD_MUTATION_PROVEN` · `GUARD_MUTATION_GREEN.P2` — report it green, write the honest
scope onto the test, and never tune the mutation until it reddens · `GUARD_UNMUTATED.P2` — nothing
was measured, so the guard does not discharge its AC at this state.
EOF
[ "$(rc_of bash "$VALIDATOR" --mutation-record-only --strict "$V")" = "0" ] || bad "a filled Mutation Record should pass"
ok "section required and satisfiable on validation reports"

echo "Test 14b: a Mutation Record ROW that ends in prose fails, next to the template's Verdicts paragraph"
python3 - "$V" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace(
  "| `tests/guards/owner.test.ts` | `lib/outbox.ts:118` | 1 | 2 | `enqueues an OWNED notice` | GUARD_MUTATION_PROVEN |",
  "| n/a | n/a | n/a | n/a | n/a | looks fine to me |")
open(p, "w").write(s)
PY
grep -q '\*\*Verdicts\.\*\* `GUARD_MUTATION_PROVEN`' "$V" || bad "fixture setup failed: the template's Verdicts paragraph is absent, so this test cannot see the vacuity"
OUT="$(bash "$VALIDATOR" --mutation-record-only --strict "$V" 2>&1 || true)"
[ "$(rc_of bash "$VALIDATOR" --mutation-record-only --strict "$V")" = "1" ] || bad "a hand-typed row verdict passed — the check is reading the section's prose, not its rows: $OUT"
grep -q "do not end in a verdict code" <<<"$OUT" || bad "the failure does not name the row defect: $OUT"
ok "the verdict is the CELL, never a code named in the surrounding prose"

echo "Test 14c: a Mutation Record with the section but NO table row fails"
python3 - "$V" <<'PY'
import sys
p = sys.argv[1]
kept = [l for l in open(p) if not l.startswith("| n/a")]
open(p, "w").write("".join(kept))
PY
OUT="$(bash "$VALIDATOR" --mutation-record-only --strict "$V" 2>&1 || true)"
[ "$(rc_of bash "$VALIDATOR" --mutation-record-only --strict "$V")" = "1" ] || bad "a row-less Mutation Record passed: $OUT"
grep -q "has no rows" <<<"$OUT" || bad "the failure does not name the empty table: $OUT"
ok "the section is the table, not the prose around it"

echo "Test 14d: the SHIPPED Mutation Record section, filled from its own template row, passes"
# Template ↔ validator conformance on the OTHER two templates this cluster owns: whatever the
# shipped section looks like, a report that fills its row with a real verdict must pass, and the
# unfilled template row must not.
for T in "$ROOT/.speck/templates/story/validation-report-template.md" \
         "$ROOT/.speck/templates/epic/epic-validation-report-template.md"; do
  python3 - "$T" "$V" <<'PY'
import re, sys, pathlib
tpl = pathlib.Path(sys.argv[1]).read_text()
i = tpl.index("## 🧬 Mutation Record")
rest = tpl[i + 5:]
j = rest.index("\n## ")
sect = tpl[i:i + 5 + j]
assert "**Verdicts.**" in sect, "the shipped section no longer carries the Verdicts paragraph"
head = "---\nartifact_type: validation-report\nmutation_record: required\n---\n\n# Validation Report\n\n"
pathlib.Path(sys.argv[2]).write_text(head + re.sub(r"\[([^\]\n]+)\]", "filled", sect))
PY
  [ "$(rc_of bash "$VALIDATOR" --mutation-record-only --strict "$V")" = "1" ] \
    || bad "a row whose verdict cell reads 'filled' passed, on $T"
  python3 - "$V" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("| filled |\n", "| GUARD_MUTATION_PROVEN |\n")
open(p, "w").write(s)
PY
  OUT="$(bash "$VALIDATOR" --mutation-record-only --strict "$V" 2>&1 || true)"
  [ "$(rc_of bash "$VALIDATOR" --mutation-record-only --strict "$V")" = "0" ] \
    || bad "the shipped section, filled with a real verdict, was convicted on $T: $OUT"
done
ok "both shipped Mutation Record sections are satisfiable and non-vacuous"

echo "Test 15: a pre-v10 validation report is exempt from the Mutation Record"
cat > "$V" <<'EOF'
---
artifact_type: validation-report
speck_version: 9.0
---

# Validation Report
EOF
[ "$(rc_of bash "$VALIDATOR" --mutation-record-only --strict "$V")" = "0" ] || bad "a pre-v10 validation report was convicted"
ok "no data migration needed: every report already on disk is exempt"

echo "Test 16: a readiness failure does not HIDE a missing Mutation Record (both run, codes combined)"
# validate-template.sh runs under `set -e`, so a sequential pair made the Mutation Record check
# unreachable whenever validate-readiness-evidence.sh aborted first. Proven live: a report claiming
# SHIP-RC with no LARP evidence and NO Mutation Record section printed ONLY the readiness failure —
# the missing section appeared only once the claim was lowered to IMPL-GREEN. A validator you
# cannot reach is not a gate, and the defect it hides behind is unrelated to the one it reports.
cat > "$V" <<'EOF'
---
artifact_type: validation-report
mutation_record: required
readiness_state_verified: SHIP-RC
---

# Validation Report

## ✅ Gate Criteria Check
| Gate | Evidence |
|---|---|
| Unit tests pass | `tests/guards/owner.test.ts` |
EOF
OUT="$(bash "$ROUTER" "$V" --strict 2>&1 || true)"
[ "$(rc_of bash "$ROUTER" "$V" --strict)" = "1" ] || bad "the router passed a SHIP-RC claim with no evidence and no Mutation Record"
grep -q "Readiness-State Evidence" <<<"$OUT" || bad "the readiness validator did not run: $OUT"
grep -q "Missing the '## 🧬 Mutation Record' section" <<<"$OUT" \
  || bad "the readiness failure SUPPRESSED the Mutation Record check — the second validator is unreachable: $OUT"
ok "both validators run and their exit codes are combined"

echo "Test 17: the base sections bind EVERY vintage — the disclosed break, pinned"
# Deliberate and documented (see the VINTAGE BINDING block in the validator): only the v10
# ADDITIONS are vintage-gated. §1–§4 have been byte-identical in harden-template.md since v7.13.0,
# so this convicts only a hand-written report that never followed the structure. Asserted here so
# the break stays a decision rather than becoming an accident again.
cat > "$R" <<'EOF'
---
speck_version: 8.0
template_version: "7.13.2"
artifact_type: harden-report
---

# Post-Validation Hardening Report: hand-written legacy

## Defect
It broke.

## Fix
Fixed it.
EOF
OUT="$(bash "$VALIDATOR" --strict "$R" 2>&1 || true)"
[ "$(rc_of bash "$VALIDATOR" --strict "$R")" = "1" ] || bad "a pre-v10 report with none of the four base sections passed"
grep -q "Missing required harden-report section" <<<"$OUT" || bad "the failure does not name the missing base sections: $OUT"
grep -q "pre-v10 harden report" <<<"$OUT" || bad "the v10 exemption notice should still print for this vintage: $OUT"
ok "base sections bind all vintages; the v10 additions do not (both asserted together)"

echo ""
echo "All validate-harden-report tests passed ($PASS assertions)."
exit 0
