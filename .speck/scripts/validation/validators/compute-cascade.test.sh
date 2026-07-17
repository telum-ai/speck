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

echo "Test 5: Check pre-matrix fallback behavior when zero matrices are found"
TMP_FALLBACK="$(mktemp -d)"
mkdir -p "$TMP_FALLBACK/epics/E001-billing"
cat > "$TMP_FALLBACK/epics/E001-billing/epic.md" <<'EOF'
This is a mock epic that references DEC-0004.
EOF

# Info mode should pass
bash "$VALIDATOR" --dec DEC-0004 "$TMP_FALLBACK"
echo "  ✓ Passed Test 5 (info mode)"

# Strict mode should fail
if bash "$VALIDATOR" --dec DEC-0004 --strict "$TMP_FALLBACK" >/dev/null 2>&1; then
  echo "ERROR: Expected strict fallback mode to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 5 (strict mode failed correctly)"
fi
rm -rf "$TMP_FALLBACK"

echo "Test 6: 8-column matrix (with Grain) — Status read by header, not mistaken for Grain (v8.4, #87)"
mkdir -p "$TMP/projects/001-test-project/epics/E002-grain/"
cat > "$TMP/projects/001-test-project/epics/E002-grain/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Grain Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Grain (proven-at) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|-------------------|--------|
| PRM-201 | product-contract §3 | differentiator pillar text | S050 / AC-1 | DEC-0009 | — | ux-rc | discharged |
| PRM-202 | product-contract §1 | payment refund | — | DEC-0009 | — | — | descoped |
EOF

# The DEC-0009 blast radius includes PRM-201, whose Status is 'discharged' (column 8). If the parser
# read Grain (column 7 = 'ux-rc') as Status, this would NOT be flagged and strict mode would pass.
if bash "$VALIDATOR" --dec DEC-0009 --strict "$TMP/projects/001-test-project" >/dev/null 2>&1; then
  echo "ERROR: 8-col matrix — expected strict mode to fail on active discharged row PRM-201, but it passed! (Grain likely mis-read as Status)"
  exit 1
else
  echo "  ✓ Passed Test 6 (8-col discharged row correctly detected under superseded DEC)"
fi

echo "✅ All compute-cascade smoke tests passed!"
exit 0
