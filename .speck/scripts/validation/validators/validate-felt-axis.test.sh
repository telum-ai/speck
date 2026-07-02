#!/usr/bin/env bash
# validate-felt-axis.test.sh — smoke tests for FELT-GOOD axis validator

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-felt-axis.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Create mock project.json specifying consumer_product archetype
mkdir -p "$TMP/.speck"
echo '{"project_archetype": "consumer_product"}' > "$TMP/.speck/project.json"

echo "Test 1: UX-RC report with felt_axis: uncovered passes"
cat > "$TMP/validation-report-ux-rc.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: UX-RC
felt_axis: uncovered
---

## 🎯 Readiness State Claim
Claiming: UX-RC

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: Verified via tests
- ON-CONTRACT: Verified via LARP
- FELT-GOOD: uncovered (human required)
EOF

bash "$VALIDATOR" --strict "$TMP/validation-report-ux-rc.md"
echo "  ✓ Passed Test 1"


echo "Test 2: Consumer SHIP-RC claim without human FELT attestation fails"
cat > "$TMP/validation-report-ship-rc-fail.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: SHIP-RC
felt_axis: uncovered
---

## 🎯 Readiness State Claim
Claiming: SHIP-RC

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: Verified via tests
- ON-CONTRACT: Verified via LARP
- FELT-GOOD: uncovered (human required)
EOF

if bash "$VALIDATOR" --strict "$TMP/validation-report-ship-rc-fail.md" >/dev/null 2>&1; then
  echo "ERROR: Expected SHIP-RC without attestation to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 2 (failed correctly)"
fi


echo "Test 3: Consumer SHIP-RC claim with human FELT attestation passes"
cat > "$TMP/validation-report-ship-rc-pass.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: SHIP-RC
felt_axis: human-verified
---

## 🎯 Readiness State Claim
Claiming: SHIP-RC on CORRECT, ON-CONTRACT, and FELT-GOOD axes.

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: Verified via tests
- ON-CONTRACT: Verified via LARP
- FELT-GOOD: human-verified in larp-recordings/123-felt-attestation.md
EOF

# Create the mock attestation file
mkdir -p "$TMP/larp-recordings"
touch "$TMP/larp-recordings/123-felt-attestation.md"

bash "$VALIDATOR" --strict "$TMP/validation-report-ship-rc-pass.md"
echo "  ✓ Passed Test 3"


echo "Test 4: Unqualified 'verified' claim with no axis fails"
cat > "$TMP/validation-report-unqualified.md" <<'EOF'
---
artifact_type: validation-report
readiness_state_claimed: UX-RC
felt_axis: uncovered
---

## 🎯 Readiness State Claim
Claiming: UX-RC. This has been fully verified and validated.

## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)
- CORRECT: Verified via tests
- ON-CONTRACT: Verified via LARP
- FELT-GOOD: uncovered (human required)
EOF

if bash "$VALIDATOR" --strict "$TMP/validation-report-unqualified.md" >/dev/null 2>&1; then
  echo "ERROR: Expected unqualified verified claim to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 4 (failed correctly)"
fi


echo "All validate-felt-axis tests passed successfully!"
exit 0
