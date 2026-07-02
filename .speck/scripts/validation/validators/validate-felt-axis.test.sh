#!/usr/bin/env bash
# validate-felt-axis.test.sh — smoke tests for the FELT-GOOD axis validator
#
# Corrected philosophy: the AI covers FELT-GOOD via the naive-hostile LARP.
# 'ai-verified' is sufficient (no human attestation demanded); 'uncovered' fails at
# consumer UX-RC+; 'human-verified' is an optional stronger signal that also passes.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-felt-axis.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Create mock project.json specifying consumer_product archetype
mkdir -p "$TMP/.speck"
echo '{"project_archetype": "consumer_product"}' > "$TMP/.speck/project.json"

echo "Test 1: Consumer UX-RC with felt_axis: ai-verified passes (AI covers FELT — no human needed)"
cat > "$TMP/validation-report-ux-rc-ai.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: UX-RC
felt_axis: ai-verified
---

## 🎯 Readiness State Claim
Claiming: UX-RC

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: tests pass
- ON-CONTRACT: LARP findings
- FELT-GOOD: naive-hostile taste verdict recorded in larp-recordings/abc-naive-hostile-findings.md
EOF

bash "$VALIDATOR" --strict "$TMP/validation-report-ux-rc-ai.md"
echo "  ✓ Passed Test 1"


echo "Test 2: Consumer UX-RC with felt_axis: uncovered fails (naive-hostile LARP not run)"
cat > "$TMP/validation-report-ux-rc-uncovered.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: UX-RC
felt_axis: uncovered
---

## 🎯 Readiness State Claim
Claiming: UX-RC

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: tests pass
- ON-CONTRACT: LARP findings
- FELT-GOOD: uncovered
EOF

if bash "$VALIDATOR" --strict "$TMP/validation-report-ux-rc-uncovered.md" >/dev/null 2>&1; then
  echo "ERROR: Expected uncovered FELT at consumer UX-RC to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 2 (failed correctly)"
fi


echo "Test 3: Consumer SHIP-RC with felt_axis: uncovered fails"
cat > "$TMP/validation-report-ship-rc-uncovered.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: SHIP-RC
felt_axis: uncovered
---

## 🎯 Readiness State Claim
Claiming: SHIP-RC

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: tests pass
- ON-CONTRACT: LARP findings
- FELT-GOOD: uncovered
EOF

if bash "$VALIDATOR" --strict "$TMP/validation-report-ship-rc-uncovered.md" >/dev/null 2>&1; then
  echo "ERROR: Expected uncovered FELT at consumer SHIP-RC to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 3 (failed correctly)"
fi


echo "Test 4: Consumer SHIP-RC with felt_axis: ai-verified passes (AI coverage is sufficient — no human attestation demanded)"
cat > "$TMP/validation-report-ship-rc-ai.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: SHIP-RC
felt_axis: ai-verified
---

## 🎯 Readiness State Claim
Claiming: SHIP-RC on the CORRECT, ON-CONTRACT, and FELT-GOOD axes.

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: tests pass
- ON-CONTRACT: LARP findings
- FELT-GOOD: naive-hostile taste verdict recorded in larp-recordings/abc-naive-hostile-findings.md
EOF

bash "$VALIDATOR" --strict "$TMP/validation-report-ship-rc-ai.md"
echo "  ✓ Passed Test 4"


echo "Test 5: Consumer SHIP-RC with felt_axis: human-verified passes (optional stronger signal)"
cat > "$TMP/validation-report-ship-rc-human.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: SHIP-RC
felt_axis: human-verified
---

## 🎯 Readiness State Claim
Claiming: SHIP-RC on the CORRECT, ON-CONTRACT, and FELT-GOOD axes.

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: tests pass
- ON-CONTRACT: LARP findings
- FELT-GOOD: human taste review in larp-recordings/abc-felt-attestation.md
EOF

bash "$VALIDATOR" --strict "$TMP/validation-report-ship-rc-human.md"
echo "  ✓ Passed Test 5"


echo "Test 6: Unqualified 'verified'/'validated' claim with no axis fails"
cat > "$TMP/validation-report-unqualified.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: UX-RC
felt_axis: ai-verified
---

## 🎯 Readiness State Claim
Claiming: UX-RC. This has been fully verified and validated.

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: tests pass
- ON-CONTRACT: LARP findings
- FELT-GOOD: naive-hostile taste verdict recorded
EOF

if bash "$VALIDATOR" --strict "$TMP/validation-report-unqualified.md" >/dev/null 2>&1; then
  echo "ERROR: Expected unqualified verified claim to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 6 (failed correctly)"
fi


echo "All validate-felt-axis tests passed successfully!"
exit 0
