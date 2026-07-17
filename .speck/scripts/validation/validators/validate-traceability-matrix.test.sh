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


echo "Test 6: Decorated readiness-state tokens resolve to the first canonical token (#76.3)"
# S010: frontmatter value with a parenthetical suffix — must resolve to ux-rc, NOT "ux-rc(agent-verified)"
mkdir -p "$TMP/stories/S010-decorated"
cat > "$TMP/stories/S010-decorated/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC (agent-verified, felt: ai-verified)
---
Spec Coverage:
- PRM-010
EOF

# S011: bold prose form with a code-ticked value + em-dash cap note — must resolve to integration-green
mkdir -p "$TMP/stories/S011-decorated"
cat > "$TMP/stories/S011-decorated/validation-report.md" <<'EOF'
# Validation Report

**Verified Readiness State**: `INTEGRATION-GREEN` — capped, awaiting keystone key

Spec Coverage:
- PRM-011
EOF

cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-010 | product-contract §3 | decorated-token differentiator | S010 / AC-1 | — | — | discharged |
| PRM-011 | product-contract §4 | decorated-token invariant | S011 / AC-2 | — | — | discharged |
EOF

bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md"
echo "  ✓ Passed Test 6 (decorated UX-RC + bold INTEGRATION-GREEN both resolved)"

echo "Test 7: 8-column matrix (with Grain) — header-keyed parse; MATRIX_GRAIN_CAP + product/story split"
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Grain (proven-at) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|-------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | ux-rc | discharged |
| PRM-002 | epic.md NFR-003 | backend invariant | S021 / AC-2 | — | — | integration-green | discharged |
| PRM-003 | experience-chain §6 | seam rule text | — | DEC-0207 | — | — | descoped |
EOF

OUT7="$(bash "$VALIDATOR" --require-evidence --status-only "$TMP/traceability-matrix.md")"
echo "$OUT7" | grep -q "MATRIX_GRAIN_CAP=integration-green" || { echo "ERROR: expected cap integration-green"; echo "$OUT7"; exit 1; }
echo "$OUT7" | grep -q "1 at product grain" || { echo "ERROR: expected 1 product-grain row"; echo "$OUT7"; exit 1; }
echo "$OUT7" | grep -q "1 at story grain" || { echo "ERROR: expected 1 story-grain row"; echo "$OUT7"; exit 1; }
echo "  ✓ Passed Test 7"


echo "Test 8: un-graded discharged row counts as story-grain (integration-green) even beside a ux-rc row"
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | ux-rc | discharged |
| PRM-002 | epic.md NFR-003 | backend invariant | S021 / AC-2 | — | — | — | discharged |
EOF

OUT8="$(bash "$VALIDATOR" --require-evidence --status-only "$TMP/traceability-matrix.md")"
echo "$OUT8" | grep -q "MATRIX_GRAIN_CAP=integration-green" || { echo "ERROR: un-graded row must pull cap to integration-green"; echo "$OUT8"; exit 1; }
echo "$OUT8" | grep -q "1 at product grain" || { echo "ERROR: expected 1 product-grain"; echo "$OUT8"; exit 1; }
echo "$OUT8" | grep -q "1 at story grain" || { echo "ERROR: expected 1 story-grain (the un-graded row)"; echo "$OUT8"; exit 1; }
echo "  ✓ Passed Test 8"


echo "Test 9: invalid grain token WARNs but still passes (soft in v8.4.0)"
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | banana | discharged |
EOF

OUT9="$(bash "$VALIDATOR" --require-evidence --status-only "$TMP/traceability-matrix.md")"  # exit 0 (soft)
echo "$OUT9" | grep -q "not a readiness-ladder token" || { echo "ERROR: expected invalid-grain WARN"; echo "$OUT9"; exit 1; }
echo "  ✓ Passed Test 9"


echo "Test 10: grain tooth 1 — grain exceeds the discharging story's state → WARN, still passes"
mkdir -p "$TMP/stories/S030-teeth"
cat > "$TMP/stories/S030-teeth/validation-report.md" <<'EOF'
---
readiness_state_verified: INTEGRATION-GREEN
---
Spec Coverage:
- PRM-030
EOF
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-030 | product-contract §3 | differentiator pillar text | S030 / AC-1 | — | — | ux-rc | discharged |
EOF
OUT10="$(bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md")"  # exit 0
echo "$OUT10" | grep -q "exceeds the discharging story's effective state" || { echo "ERROR: expected tooth-1 WARN"; echo "$OUT10"; exit 1; }
echo "  ✓ Passed Test 10"


echo "Test 11: grain tooth 1 — [pre-v8-proof] cap makes a ux-rc grain WARN even when the story claims UX-RC"
mkdir -p "$TMP/stories/S031-capped"
cat > "$TMP/stories/S031-capped/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC [pre-v8-proof]
---
Spec Coverage:
- PRM-031
LARP evidence: evidence/larp/home.png
EOF
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-031 | product-contract §3 | differentiator pillar text | S031 / AC-1 | — | — | ux-rc | discharged |
EOF
OUT11="$(bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md")"  # exit 0
echo "$OUT11" | grep -q "exceeds the discharging story's effective state 'integration-green'" || { echo "ERROR: expected pre-v8-proof cap WARN"; echo "$OUT11"; exit 1; }
echo "  ✓ Passed Test 11"


echo "Test 12: grain tooth 2 — product-grain (≥ux-rc) row without walk-evidence → WARN"
mkdir -p "$TMP/stories/S032-nowalk"
cat > "$TMP/stories/S032-nowalk/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
Spec Coverage:
- PRM-032 discharged by a unit test importing the helper.
EOF
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-032 | product-contract §3 | differentiator pillar text | S032 / AC-1 | — | — | ux-rc | discharged |
EOF
OUT12="$(bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md")"  # exit 0
echo "$OUT12" | grep -q "cites no walk-evidence artifact" || { echo "ERROR: expected tooth-2 WARN"; echo "$OUT12"; exit 1; }
echo "  ✓ Passed Test 12"


echo "Test 13: grain teeth satisfied — ux-rc grain, story at UX-RC, report cites walk-evidence → no grain WARN"
mkdir -p "$TMP/stories/S033-clean"
cat > "$TMP/stories/S033-clean/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
Spec Coverage:
- PRM-033 discharged by a cold-start build LARP; evidence/larp/home.png captured.
EOF
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-033 | product-contract §3 | differentiator pillar text | S033 / AC-1 | — | — | ux-rc | discharged |
EOF
OUT13="$(bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md")"  # exit 0
if echo "$OUT13" | grep -q "grain warning(s)"; then echo "ERROR: expected NO grain warnings"; echo "$OUT13"; exit 1; fi
echo "$OUT13" | grep -q "1 at product grain" || { echo "ERROR: expected 1 product-grain row"; echo "$OUT13"; exit 1; }
echo "  ✓ Passed Test 13"


echo "Test 14: --check-fidelity (opt-in, WARN-only) — phantom source + vocabulary drift, faithful row silent"
FID="$TMP/fidelity-epic"
mkdir -p "$FID"
cat > "$FID/epic.md" <<'EOF'
# Epic

**NFR-001**: Safety on a live table
- Target: idempotent and reversible migration; validated on a throwaway postgres, never on DEV.
EOF
cat > "$FID/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-001 | epic.md NFR-001 | idempotent reversible migration safety | S001 / AC-1 | — | — | — | discharged |
| PRM-002 | epic.md NFR-001 | completely unrelated banana zebra xylophone | S002 / AC-1 | — | — | — | discharged |
| PRM-003 | wireframes S99 / ghost screen | a drawn element nowhere on disk | S003 / AC-1 | — | — | — | discharged |
EOF
OUT14="$(bash "$VALIDATOR" --check-fidelity "$FID/traceability-matrix.md")"  # exit 0 (WARN-only)
echo "$OUT14" | grep -q "PRM-002.*vocabulary drift" || { echo "ERROR: expected vocabulary-drift WARN on PRM-002"; echo "$OUT14"; exit 1; }
echo "$OUT14" | grep -q "PRM-003.*phantom or renamed source" || { echo "ERROR: expected phantom-source WARN on PRM-003"; echo "$OUT14"; exit 1; }
if echo "$OUT14" | grep -q "PRM-001.*fidelity"; then echo "ERROR: faithful PRM-001 must NOT warn"; echo "$OUT14"; exit 1; fi
echo "  ✓ Passed Test 14"


echo "Test 15: fidelity OFF by default — a drifting row produces no fidelity WARN without the flag"
OUT15="$(bash "$VALIDATOR" "$FID/traceability-matrix.md")"
if echo "$OUT15" | grep -q "\[fidelity\]"; then echo "ERROR: fidelity must be opt-in (no [fidelity] WARN without the flag)"; echo "$OUT15"; exit 1; fi
echo "  ✓ Passed Test 15"


echo "All validate-traceability-matrix tests passed successfully!"
exit 0
