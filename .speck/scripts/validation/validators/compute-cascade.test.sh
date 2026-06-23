#!/usr/bin/env bash
# compute-cascade.test.sh — smoke tests for cascade computer

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/compute-cascade.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Set up project structure
mkdir -p "$TMP/projects/001-test-project/epics/E001-billing/"

cat > "$TMP/projects/001-test-project/epics/E001-billing/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-101 | product-contract.md §3 | differentiator pillar text | S012 / AC-3 | — | — | discharged |
| PRM-102 | product-contract.md §1 | payment processing | S014 / AC-1 | DEC-0004 | — | discharged |
| PRM-103 | product-contract.md §1 | payment refund | — | DEC-0004 | — | descoped |
| PRM-104 | wireframes S05 / dashboard | consolidated complex visual flow | — | DEC-0005 | — | descoped |
EOF

echo "Test 1: Check info mode for --dec"
bash "$VALIDATOR" --dec DEC-0004 "$TMP"
echo "  ✓ Passed Test 1"

echo "Test 2: Check strict mode for --dec (should fail on active discharged row PRM-102)"
if bash "$VALIDATOR" --dec DEC-0004 --strict "$TMP" >/dev/null 2>&1; then
  echo "ERROR: Expected strict mode to fail on active discharged row, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 2 (failed correctly)"
fi

echo "Test 3: Check info mode for --contract-section"
bash "$VALIDATOR" --contract-section "product-contract.md §3" "$TMP"
echo "  ✓ Passed Test 3"

echo "Test 4: Check strict mode for --dec DEC-0005 (should pass since PRM-104 is descoped, not discharged)"
bash "$VALIDATOR" --dec DEC-0005 --strict "$TMP"
echo "  ✓ Passed Test 4"

echo "✅ All compute-cascade smoke tests passed!"
exit 0
