#!/usr/bin/env bash
# scaffold-clean.test.sh — the fixture that ends the #89 / #92 class
#
# #89 and #92 were both the same shape of bug: a Speck scanner convicting
# Speck's OWN mandated template output — the exact artifact a fresh
# scaffold + a completed fill pass is supposed to produce. A fixture that
# only exercises hand-picked one-line snippets (as validate-template.test.sh
# does elsewhere) can't catch a NEW over-match introduced by a future
# template edit; only building from the real, current templates can.
#
# This test is a PAIR, by design (a positive-only fixture proves nothing —
# a scanner that over-excludes would pass it trivially):
#   1. POSITIVE — build a project from the CURRENT templates verbatim (every
#      section, every instructional HTML comment intact) with every
#      genuinely-fillable field filled, as a completed scaffold would look.
#      Both shipped scanners MUST return zero findings on it.
#   2. NEGATIVE — the same scaffold plus one real unfilled REPLACE_BEFORE_SHIP
#      marker and one real [PLACEHOLDER] residue, each written BOTH as bare
#      prose and inside backticks. Both scanners MUST catch and name all four.
#
# Together these pin the exact defect class shut: a scanner that starts
# swallowing everything (fixing the false positive by introducing a false
# negative) fails step 2; a scanner that regresses to the old behavior fails
# step 1.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

CRM="$ROOT/.speck/scripts/check-replace-markers.sh"
VT="$ROOT/.speck/scripts/validation/validate-template.sh"
PROBE="$TMP/specs/projects/probe"
mkdir -p "$PROBE"

# --- 1. Copy the CURRENT templates verbatim, under their real target names -
cp "$ROOT/.speck/templates/project/evidence-contract-template.md"      "$PROBE/evidence-contract.md"
cp "$ROOT/.speck/templates/project/project-decisions-log-template.md"  "$PROBE/project-decisions-log.md"
cp "$ROOT/.speck/templates/project/product-contract-template.md"       "$PROBE/product-contract.md"
cp "$ROOT/.speck/templates/project/project-state-template.md"          "$PROBE/project-state.md"

# Explicit regression pin (#89): the fenced-block worked example in
# project-state-template.md must still be there, VERBATIM, before we do
# anything else — this is the exact line that was a permanent false
# positive. If a future template edit removes or rewords it, this assertion
# is the thing that notices.
PIN_LINE='grep -rln "REPLACE_BEFORE_SHIP:" specs/projects/<PROJECT_ID>/'
PIN_FOUND="$(grep -F "$PIN_LINE" "$PROBE/project-state.md" 2>/dev/null || true)"
if [[ -z "$PIN_FOUND" ]]; then
  echo "FAIL: project-state-template.md no longer contains the pinned fenced-block"
  echo "      example ('$PIN_LINE'). Either the template changed (update this pin)"
  echo "      or something upstream mangled the copy."
  exit 1
fi
echo "  ✓ project-state-template.md's fenced-block example is present verbatim (pinned)"

# --- 2. Fill pass — simulate what a completed scaffold looks like ----------
# Two kinds of unfilled residue exist in these templates and each needs a
# different fill strategy:
#
#   (a) REPLACE_BEFORE_SHIP fields — filled everywhere EXCEPT inside a fenced
#       code block. The fence-skip is deliberate: the one fenced use of the
#       token in these templates IS the pinned grep example above, and
#       filling it would defeat the pin (and stop testing the real #89
#       case — a literal, unmodified worked example inside a fence).
#
#   (b) generic [bracketed] template fields — filled by exact literal text,
#       one entry per placeholder actually found in these four templates
#       (verified empirically against the current template content; see the
#       cluster's task report for the exact `validate-template.sh --strict`
#       run this list was built from). NOT included: [NEEDS USER REVIEW] —
#       leaving it untouched is the point, it's the #92 fixture case, and a
#       correct scanner must NOT flag it.
python3 - "$PROBE/evidence-contract.md" "$PROBE/project-decisions-log.md" "$PROBE/product-contract.md" "$PROBE/project-state.md" << 'PYEOF'
import sys, re

REPLACEMENTS = {
    "[PROJECT_NAME]": "Probe Project",
    "[Each named persona]": "the primary persona",
    "[Option A name]": "Option A",
    "[Option B name]": "Option B",
    "[Option C name]": "Option C",
    "[Option name]": "Chosen Option",
    "[1-sentence description]": "a one-sentence description of this option",
    "[Specific outcome]": "a specific measurable outcome",
    "[Axis name]": "Speed",
    "[PROJECT_ID]": "probe-project",
    "[consumer_product | b2b_saas | internal_tool | infra_service | backend_api]": "consumer_product",
    "[project-id]": "probe-project",
    "[name]": "codeowner",
    "[Blocker description]": "no known blockers",
    "[Description]": "n/a",
    "[branch name]": "main",
    "[git diff --name-only against last validation SHA]": "no diff recorded",
    "[ISO_TIMESTAMP]": "2026-07-30T00:00:00Z",
}

for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()

    infence = False
    out = []
    for line in lines:
        if line.startswith("```"):
            infence = not infence
            out.append(line)
            continue
        if infence:
            out.append(line)
            continue
        if "REPLACE_BEFORE_SHIP:" in line:
            line = re.sub(r'REPLACE_BEFORE_SHIP:[^|\n]*', 'FILLED-BY-FIXTURE', line)
        out.append(line)

    content = "".join(out)
    for old, new in REPLACEMENTS.items():
        content = content.replace(old, new)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
PYEOF

# --- 3. POSITIVE: check-replace-markers.sh across the whole scaffold -------
echo "Test: scaffold-clean — check-replace-markers.sh returns zero findings"
if OUT="$("$CRM" "$TMP/specs" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -ne 0 ]]; then
  echo "FAIL: check-replace-markers.sh convicted the clean scaffold:"
  echo "$OUT"
  exit 1
fi
echo "  ✓ clean ($OUT)"

# Re-assert the pinned line specifically, in isolation, so a failure here
# points straight at the #89 fenced-block case rather than getting lost in
# an aggregate pass/fail.
echo "Test: scaffold-clean — pinned fenced-block line alone is clean"
if OUT="$("$CRM" "$PROBE/project-state.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -ne 0 ]]; then
  echo "FAIL: check-replace-markers.sh convicted project-state.md's pinned fenced-block line:"
  echo "$OUT"
  exit 1
fi
echo "  ✓ clean"

# --- 4. POSITIVE: validate-template.sh's placeholder scanner ---------------
# project-decisions-log.md and project-state.md aren't routed to a
# sub-validator (validate-template.sh's filename switch falls through to
# "not a tracked template, skip"), so testing them under their real names
# exercises exactly the STEP 1 scanner this cluster fixed, and nothing else.
echo "Test: scaffold-clean — validate-template.sh clean for project-decisions-log.md"
if OUT="$("$VT" --strict "$PROBE/project-decisions-log.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -ne 0 ]]; then
  echo "FAIL: $OUT"
  exit 1
fi
echo "  ✓ clean"

echo "Test: scaffold-clean — validate-template.sh clean for project-state.md"
if OUT="$("$VT" --strict "$PROBE/project-state.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -ne 0 ]]; then
  echo "FAIL: $OUT"
  exit 1
fi
echo "  ✓ clean"

# evidence-contract.md and product-contract.md, by contrast, DO route to a
# sub-validator (validate-evidence-contract.sh / validate-product-contract.sh).
#
# P2-3 (adversarial review, #93): the ORIGINAL version of this test dodged
# that sub-validator entirely — it copied the filled content under a
# NON-ROUTED filename (evidence-contract-fixture.md /
# product-contract-fixture.md) specifically so validate-template.sh's
# filename switch would fall through and skip STEP 2 routing. That was
# necessary at the time because each sub-validator's OWN "Scan for
# unreplaced REPLACE_BEFORE_SHIP placeholders" step was a SEPARATE,
# unanchored `grep -q "REPLACE_BEFORE_SHIP"` (no colon) that convicted this
# cluster's own reworded PLACEHOLDER CONVENTION prose ("...REPLACE_BEFORE_SHIP
# followed by a colon and a hint...") — P2-4, the same defect class as #89,
# just living in a different file. Dodging the sub-validator meant the
# "positive leg" here never actually proved a real, fully-filled artifact
# could pass the REAL pipeline a downstream project's pre-commit hook runs;
# it only proved STEP 1 was clean, then routed around STEP 2 rather than
# fixing it — exactly the failure mode P2-3 flagged in this file itself.
#
# Now that P2-4 is fixed (both sub-validators delegate their
# REPLACE_BEFORE_SHIP check to check-replace-markers.sh's genuine-marker
# detection instead of a second, independently-buggy reimplementation of the
# same rule), this runs the FULL pipeline under the REAL routed filenames —
# the case is covered, not avoided.
echo "Test: scaffold-clean — validate-template.sh FULL pipeline (incl. validate-evidence-contract.sh) clean for evidence-contract.md"
if OUT="$("$VT" --strict "$PROBE/evidence-contract.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -ne 0 ]]; then
  echo "FAIL: $OUT"
  exit 1
fi
echo "  ✓ clean"

# product-contract.md's full pipeline additionally runs a §2a↔§3
# reconciliation check (validate-product-contract.sh step 11,
# market-reconcile-check.sh, issue #80) that is UNRELATED to
# REPLACE_BEFORE_SHIP and lives in a file NOT owned by this cluster. It
# self-flags on product-contract-template.md's own §2a explanatory
# blockquote ("...when this analysis self-flags §3 as thin/copyable...")
# regardless of how the artifact is filled — a real, pre-existing bug in the
# same class (documentation prose convicted as if it were live content), but
# out of scope here and reported separately rather than patched. Assert only
# on the REPLACE_BEFORE_SHIP check this cluster fixed, not on the unrelated
# check's exit code — asserting the whole pipeline's exit code here would
# just trade one "route around a real defect" for another.
echo "Test: scaffold-clean — validate-template.sh FULL pipeline (incl. validate-product-contract.sh) reports no REPLACE_BEFORE_SHIP placeholders for product-contract.md"
if OUT="$("$VT" --strict "$PROBE/product-contract.md" 2>&1)"; then EC=0; else EC=$?; fi
if printf '%s\n' "$OUT" | grep -q "Found unreplaced 'REPLACE_BEFORE_SHIP' placeholders"; then
  echo "FAIL: validate-product-contract.sh still convicts a fully-filled product-contract.md of unreplaced"
  echo "      REPLACE_BEFORE_SHIP placeholders (P2-4 not fixed):"
  echo "$OUT"
  exit 1
fi
echo "  ✓ REPLACE_BEFORE_SHIP check clean (any other failure here is the unrelated WEDGE_DRIFT"
echo "    self-flag bug in market-reconcile-check.sh — filed separately, not this cluster's scope)"

# --- 4b. NEGATIVE — the sub-validators must still catch the real thing -----
# Regression guard for P2-4 specifically: delegating to
# check-replace-markers.sh must not silently turn the sub-validators' own
# REPLACE_BEFORE_SHIP check into a rubber stamp.
echo "Test: negative control — validate-evidence-contract.sh (via validate-template.sh, real filename) still catches a genuine unfilled marker"
# Deliberately OUTSIDE $TMP/specs (needs "specs/" in its path for
# validate-template.sh to engage at all, but must not live inside the tree
# the directory-mode check-replace-markers.sh scan below walks — otherwise
# these dirty probes would pollute that scan's "clean files stay clean"
# assertion too).
NEG_EC_DIR="$TMP/neg-specs/projects/probe-neg-ec"
mkdir -p "$NEG_EC_DIR"
cp "$PROBE/evidence-contract.md" "$NEG_EC_DIR/evidence-contract.md"
printf '\n**Regression probe**: REPLACE_BEFORE_SHIP: pick a name\n' >> "$NEG_EC_DIR/evidence-contract.md"
if OUT="$("$VT" --strict "$NEG_EC_DIR/evidence-contract.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -eq 0 ]]; then
  echo "FAIL: validate-template.sh passed evidence-contract.md despite a genuine unfilled REPLACE_BEFORE_SHIP marker"
  exit 1
fi
if ! printf '%s\n' "$OUT" | grep -q "Found unreplaced 'REPLACE_BEFORE_SHIP' placeholders"; then
  echo "FAIL: expected validate-evidence-contract.sh's REPLACE_BEFORE_SHIP check to name the failure:"
  echo "$OUT"
  exit 1
fi
echo "  ✓ caught"

echo "Test: negative control — a prose-only PROFILE gate cannot pass"
NEG_PROFILE_DIR="$TMP/neg-specs/projects/probe-neg-profile"
mkdir -p "$NEG_PROFILE_DIR"
cp "$PROBE/evidence-contract.md" "$NEG_PROFILE_DIR/evidence-contract.md"
sed '/^PROFILE_/d' \
  "$NEG_PROFILE_DIR/evidence-contract.md" > "$NEG_PROFILE_DIR/evidence-contract.mutant.md"
mv "$NEG_PROFILE_DIR/evidence-contract.mutant.md" "$NEG_PROFILE_DIR/evidence-contract.md"
if OUT="$("$VT" --strict "$NEG_PROFILE_DIR/evidence-contract.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -eq 0 ]]; then
  echo "FAIL: validate-template.sh passed a prose-only PROFILE gate"
  exit 1
fi
if ! printf '%s\n' "$OUT" | grep -q "PROFILE Gate Criteria is shape-only or incomplete"; then
  echo "FAIL: expected the binding PROFILE contract diagnostic:"
  echo "$OUT"
  exit 1
fi
echo "  ✓ caught"

echo "Test: negative control — PROFILE keywords inside explicit negations cannot pass"
NEG_PROFILE_WORDS_DIR="$TMP/neg-specs/projects/probe-neg-profile-words"
mkdir -p "$NEG_PROFILE_WORDS_DIR"
cp "$PROBE/evidence-contract.md" "$NEG_PROFILE_WORDS_DIR/evidence-contract.md"
sed \
  -e 's/^PROFILE_COVERAGE=every-row$/PROFILE_COVERAGE=do-not-inspect-every-row/' \
  -e 's/^PROFILE_P1_BLOCKS=true$/PROFILE_P1_BLOCKS=false # PROFILE_DRIFT.P1 never blocks/' \
  -e 's/^PROFILE_PLACEHOLDER_POLICY=finding$/PROFILE_PLACEHOLDER_POLICY=may-be-ignored/' \
  "$NEG_PROFILE_WORDS_DIR/evidence-contract.md" > "$NEG_PROFILE_WORDS_DIR/evidence-contract.mutant.md"
mv "$NEG_PROFILE_WORDS_DIR/evidence-contract.mutant.md" "$NEG_PROFILE_WORDS_DIR/evidence-contract.md"
if OUT="$("$VT" --strict "$NEG_PROFILE_WORDS_DIR/evidence-contract.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -eq 0 ]]; then
  echo "FAIL: validate-template.sh accepted negated PROFILE semantics"
  exit 1
fi
if ! printf '%s\n' "$OUT" | grep -q "PROFILE Gate Criteria is shape-only or incomplete"; then
  echo "FAIL: expected the authoritative PROFILE machine-contract diagnostic:"
  echo "$OUT"
  exit 1
fi
echo "  ✓ caught"

echo "Test: negative control — validate-product-contract.sh (via validate-template.sh, real filename) still catches a genuine unfilled marker"
NEG_PC_DIR="$TMP/neg-specs/projects/probe-neg-pc"
mkdir -p "$NEG_PC_DIR"
cp "$PROBE/product-contract.md" "$NEG_PC_DIR/product-contract.md"
printf '\n**Regression probe**: REPLACE_BEFORE_SHIP: pick a name\n' >> "$NEG_PC_DIR/product-contract.md"
if OUT="$("$VT" --strict "$NEG_PC_DIR/product-contract.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -eq 0 ]]; then
  echo "FAIL: validate-template.sh passed product-contract.md despite a genuine unfilled REPLACE_BEFORE_SHIP marker"
  exit 1
fi
if ! printf '%s\n' "$OUT" | grep -q "Found unreplaced 'REPLACE_BEFORE_SHIP' placeholders"; then
  echo "FAIL: expected validate-product-contract.sh's REPLACE_BEFORE_SHIP check to name the failure:"
  echo "$OUT"
  exit 1
fi
echo "  ✓ caught"

# --- 5. NEGATIVE CONTROL — must still catch the real thing -----------------
# Same scaffold, plus one genuine unfilled marker of each kind, each written
# BOTH as bare prose and inside backticks (the reviewer's trap case: a fix
# that blanket-strips backtick spans would make the backticked half of this
# invisible).
cat > "$PROBE/negative-control.md" << 'EOF'
# Negative control — genuine unfilled residue (must be caught)

Bare marker: REPLACE_BEFORE_SHIP: pick a name

Backticked marker: `REPLACE_BEFORE_SHIP: pick a name`

Bare placeholder: [PLACEHOLDER]

Backticked placeholder: `[PLACEHOLDER]`
EOF

echo "Test: negative control — check-replace-markers.sh catches both REPLACE_BEFORE_SHIP forms"
if OUT="$("$CRM" "$TMP/specs" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -eq 0 ]]; then
  echo "FAIL: check-replace-markers.sh passed a scaffold containing a genuine unfilled marker"
  exit 1
fi
HITS="$(printf '%s\n' "$OUT" | grep -c "negative-control.md" || true)"
if [[ "$HITS" -lt 1 ]]; then
  echo "FAIL: negative-control.md wasn't named in the failure report:"
  echo "$OUT"
  exit 1
fi
# The report line carries the per-file token COUNT; confirm it's exactly 2
# (bare + backticked), not 1 (one form silently swallowed) or 0.
COUNT_LINE="$(printf '%s\n' "$OUT" | grep "negative-control.md" | head -1)"
if [[ "$COUNT_LINE" != *"| 2 |"* ]]; then
  echo "FAIL: expected 2 genuine markers named (bare + backticked), got: $COUNT_LINE"
  exit 1
fi
# The clean scaffold files must NOT reappear now that one dirty file exists
# alongside them — proves the positive result above wasn't a directory-scan
# fluke.
for clean_file in evidence-contract.md project-decisions-log.md product-contract.md project-state.md; do
  if printf '%s\n' "$OUT" | grep -q "$clean_file"; then
    echo "FAIL: clean scaffold file $clean_file was wrongly named alongside the negative control:"
    echo "$OUT"
    exit 1
  fi
done
echo "  ✓ caught, named, counted 2 (bare + backticked), scaffold files stayed clean"

echo "Test: negative control — validate-template.sh catches both [PLACEHOLDER] forms"
if OUT="$("$VT" --strict "$PROBE/negative-control.md" 2>&1)"; then EC=0; else EC=$?; fi
if [[ "$EC" -eq 0 ]]; then
  echo "FAIL: validate-template.sh passed a file containing genuine [PLACEHOLDER] residue"
  exit 1
fi
FOUND="$(printf '%s\n' "$OUT" | grep -c "Unreplaced placeholder '\[PLACEHOLDER\]'" || true)"
if [[ "$FOUND" -ne 2 ]]; then
  echo "FAIL: expected 2 named [PLACEHOLDER] findings (bare + backticked), got $FOUND:"
  echo "$OUT"
  exit 1
fi
echo "  ✓ caught and named both (bare + backticked)"

echo "All scaffold-clean smoke tests passed"
