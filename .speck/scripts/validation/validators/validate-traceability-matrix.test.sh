#!/usr/bin/env bash
# validate-traceability-matrix.test.sh — smoke tests for traceability matrix validator

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-traceability-matrix.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Test 1: Valid 7-column matrix (with backing and pilot-gated) passes under --require-evidence"
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | discharged |
| PRM-002 | wireframes S05 / auto-reply opt-in toggle | screen element and its job | S018 / AC-1 | — | — | discharged |
| PRM-003 | experience-chain §6 / magic-moment placement | seam rule text | — | DEC-0207 | — | descoped |
| PRM-004 | wireframes S05 / dashboard | consolidated complex visual flow | — | — | AUDIT-E002-42, E002/PRM-054 | pilot-gated |
EOF

bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md"
echo "  ✓ Passed Test 1"


echo "Test 2: Pilot-gated WITHOUT a backing reference fails under --require-evidence"
cat > "$TMP/traceability-matrix-fail.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | discharged |
| PRM-002 | wireframes S05 / auto-reply opt-in toggle | screen element and its job | S018 / AC-1 | — | — | discharged |
| PRM-003 | experience-chain §6 / magic-moment placement | seam rule text | — | DEC-0207 | — | descoped |
| PRM-004 | wireframes S05 / dashboard | consolidated complex visual flow | — | — | — | pilot-gated |
EOF

if bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix-fail.md" >/dev/null 2>&1; then
  echo "ERROR: Expected pilot-gated without backing reference to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 2 (failed correctly)"
fi


echo "Test 3: Old 6-column matrix passes under --require-evidence"
cat > "$TMP/traceability-matrix-old.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | discharged |
| PRM-002 | wireframes S05 / auto-reply opt-in toggle | screen element and its job | S018 / AC-1 | — | discharged |
| PRM-003 | experience-chain §6 / magic-moment placement | seam rule text | — | DEC-0207 | descoped |
EOF

bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix-old.md"
echo "  ✓ Passed Test 3"


echo "Test 4: Unmapped rows under BREAKDOWN_EXISTS fail default mode"
cat > "$TMP/traceability-matrix-unmapped.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | discharged |
| PRM-002 | wireframes S05 / auto-reply opt-in toggle | screen element and its job | S018 / AC-1 | — | — | discharged |
| PRM-003 | experience-chain §6 / magic-moment placement | seam rule text | — | DEC-0207 | — | descoped |
| PRM-004 | epic.md FR-E0NN-014 | requirement text | — | — | — | open |
EOF

# Create an epic-breakdown.md to trigger strict default checks
touch "$TMP/epic-breakdown.md"

if bash "$VALIDATOR" "$TMP/traceability-matrix-unmapped.md" >/dev/null 2>&1; then
  echo "ERROR: Expected unmapped rows after breakdown to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 4 (failed correctly)"
fi

echo "All validate-traceability-matrix tests passed successfully!"
exit 0
