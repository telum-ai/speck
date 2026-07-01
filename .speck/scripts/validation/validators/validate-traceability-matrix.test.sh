#!/usr/bin/env bash
# validate-traceability-matrix.test.sh — smoke tests for traceability matrix validator

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-traceability-matrix.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Test 1: Valid 7-column matrix (with backing and pilot-gated) passes under --require-evidence --status-only"
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

bash "$VALIDATOR" --require-evidence --status-only "$TMP/traceability-matrix.md"
echo "  ✓ Passed Test 1"


echo "Test 2: Pilot-gated WITHOUT a backing reference fails under --require-evidence --status-only"
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

if bash "$VALIDATOR" --require-evidence --status-only "$TMP/traceability-matrix-fail.md" >/dev/null 2>&1; then
  echo "ERROR: Expected pilot-gated without backing reference to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 2 (failed correctly)"
fi


echo "Test 3: Old 6-column matrix passes under --require-evidence --status-only"
cat > "$TMP/traceability-matrix-old.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | discharged |
| PRM-002 | wireframes S05 / auto-reply opt-in toggle | screen element and its job | S018 / AC-1 | — | discharged |
| PRM-003 | experience-chain §6 / magic-moment placement | seam rule text | — | DEC-0207 | descoped |
EOF

bash "$VALIDATOR" --require-evidence --status-only "$TMP/traceability-matrix-old.md"
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


echo "Test 5: --require-evidence checks story validation reports"
# Setup mock epic structure
mkdir -p "$TMP/stories/S001-test"
mkdir -p "$TMP/stories/S002-test"
mkdir -p "$TMP/stories/S003-test"

# S001 has a valid report (UX-RC, cites PRM-001)
cat > "$TMP/stories/S001-test/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
Spec Coverage:
- PRM-001
EOF

# S002 has a report with state too low (IMPL-GREEN)
cat > "$TMP/stories/S002-test/validation-report.md" <<'EOF'
---
readiness_state_verified: IMPL-GREEN
---
Spec Coverage:
- PRM-002
EOF

# S003 has a valid state but doesn't cite PRM-003
cat > "$TMP/stories/S003-test/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
Spec Coverage:
- unrelated
EOF

# Matrix to test
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S001 / AC-1 | — | — | discharged |
EOF

# S001 should pass
bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md"
echo "  ✓ S001 passed"

# S002 (low state) should fail
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-002 | product-contract §3 | differentiator pillar text | S002 / AC-1 | — | — | discharged |
EOF

if bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md" >/dev/null 2>&1; then
  echo "ERROR: Expected S002 with low state to fail, but it passed!"
  exit 1
else
  echo "  ✓ S002 failed correctly"
fi

# S003 (no citation) should fail
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-003 | product-contract §3 | differentiator pillar text | S003 / AC-1 | — | — | discharged |
EOF

if bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md" >/dev/null 2>&1; then
  echo "ERROR: Expected S003 with missing citation to fail, but it passed!"
  exit 1
else
  echo "  ✓ S003 failed correctly"
fi

# Missing report should fail
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-004 | product-contract §3 | differentiator pillar text | S004 / AC-1 | — | — | discharged |
EOF

if bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md" >/dev/null 2>&1; then
  echo "ERROR: Expected S004 with missing report to fail, but it passed!"
  exit 1
else
  echo "  ✓ S004 failed correctly"
fi

echo "All validate-traceability-matrix tests passed successfully!"
exit 0
