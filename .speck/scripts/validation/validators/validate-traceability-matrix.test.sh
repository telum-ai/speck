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


echo "Test 9: invalid grain token BLOCKS under --require-evidence (enforced v8.5.0)"
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | banana | discharged |
EOF

if OUT9="$(bash "$VALIDATOR" --require-evidence --status-only "$TMP/traceability-matrix.md" 2>&1)"; then
  echo "ERROR: expected invalid grain token to BLOCK under --require-evidence (v8.5.0)"; echo "$OUT9"; exit 1
fi
echo "$OUT9" | grep -q "not a readiness-ladder token" || { echo "ERROR: expected invalid-grain block message"; echo "$OUT9"; exit 1; }
echo "  ✓ Passed Test 9"


echo "Test 10: grain tooth 1 — grain exceeds the discharging story's state → BLOCK (v8.5.0)"
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
if OUT10="$(bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md" 2>&1)"; then
  echo "ERROR: expected tooth-1 to BLOCK (v8.5.0)"; echo "$OUT10"; exit 1
fi
echo "$OUT10" | grep -q "exceeds the discharging story's effective state" || { echo "ERROR: expected tooth-1 block message"; echo "$OUT10"; exit 1; }
echo "  ✓ Passed Test 10"


echo "Test 11: grain tooth 1 — [pre-v8-proof] cap makes a ux-rc grain BLOCK even when the story claims UX-RC"
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
if OUT11="$(bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md" 2>&1)"; then
  echo "ERROR: expected pre-v8-proof cap tooth to BLOCK (v8.5.0)"; echo "$OUT11"; exit 1
fi
echo "$OUT11" | grep -q "exceeds the discharging story's effective state 'integration-green'" || { echo "ERROR: expected pre-v8-proof cap block message"; echo "$OUT11"; exit 1; }
echo "  ✓ Passed Test 11"


echo "Test 12: grain tooth 2 — product-grain (≥ux-rc) row without walk-evidence → BLOCK (v8.5.0)"
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
if OUT12="$(bash "$VALIDATOR" --require-evidence "$TMP/traceability-matrix.md" 2>&1)"; then
  echo "ERROR: expected tooth-2 to BLOCK (v8.5.0)"; echo "$OUT12"; exit 1
fi
echo "$OUT12" | grep -q "cites no walk-evidence artifact" || { echo "ERROR: expected tooth-2 block message"; echo "$OUT12"; exit 1; }
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


echo "Test 16: grain is enforced at the gate but SURFACED-only on the fast path (v8.5.0)"
# Default mode (no --require-evidence) = the pre-commit/recheck fast path: an invalid grain token
# and a grain-exceeds situation must WARN, never block. Enforcement lives at --require-evidence.
cat > "$TMP/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Grain (proven-at) | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|-------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S012 / AC-3 | — | — | banana | discharged |
EOF
OUT16="$(bash "$VALIDATOR" "$TMP/traceability-matrix.md")"   # default mode → exit 0 (surfaced-only)
echo "$OUT16" | grep -q "not a readiness-ladder token" || { echo "ERROR: expected fast-path grain WARN"; echo "$OUT16"; exit 1; }
echo "$OUT16" | grep -qi "grain warning" || { echo "ERROR: expected fast-path warning summary"; echo "$OUT16"; exit 1; }
echo "  ✓ Passed Test 16"


echo "Test 17: prose-only Discharge cell does NOT resolve conservation — BLOCKS after epic-breakdown"
# The verified defect: has_discharge was set from cell NON-EMPTINESS, so an honest, correct
# explanation like "OPEN — not discharged; blocked on vendor API" silently RESOLVED the gate.
# It must now fall through to the SAME "unmapped" fate as a truly-open row once breakdown
# exists, with a finding naming the row + quoting the offending cell.
POST17="$TMP/postbreak-17"
mkdir -p "$POST17"
touch "$POST17/epic-breakdown.md"
cat > "$POST17/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-101 | product-contract §3 | vendor sync must complete | OPEN — not discharged; blocked on vendor API | — | — | open |
EOF
if OUT17="$(bash "$VALIDATOR" "$POST17/traceability-matrix.md" 2>&1)"; then
  echo "ERROR: expected prose-only Discharge cell to FAIL conservation post-breakdown"; echo "$OUT17"; exit 1
fi
echo "$OUT17" | grep -q "PRM-101" || { echo "ERROR: expected the finding to NAME the row (PRM-101)"; echo "$OUT17"; exit 1; }
echo "$OUT17" | grep -qF "OPEN — not discharged; blocked on vendor API" || { echo "ERROR: expected the finding to quote the offending cell"; echo "$OUT17"; exit 1; }
echo "$OUT17" | grep -qi "no structured token" || { echo "ERROR: expected the finding to say WHAT is missing"; echo "$OUT17"; exit 1; }
echo "  ✓ Passed Test 17"


echo "Test 18: each has_structured_token branch INDEPENDENTLY resolves conservation post-breakdown"
POST18="$TMP/postbreak-18"
mkdir -p "$POST18"
touch "$POST18/epic-breakdown.md"
# One row per branch of has_structured_token(), each matching ONLY its own branch, so deleting any
# one branch turns this test RED. PRM-102's Discharge is a BARE `S012` (no ` / AC-1`) on purpose:
# with the AC-ref present, the AC-[0-9]+ branch satisfied the row and the S[0-9]+ branch this test
# names was never actually exercised — the branch could be deleted with the suite still exit 0.
cat > "$POST18/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-102 | product-contract §3 | story-id branch only | S012 | — | — | discharged |
| PRM-103 | product-contract §3 | legal descope | — | DEC-0031 | — | descoped |
| PRM-104 | product-contract §3 | ac-ref branch only | AC-7 | — | — | discharged |
| PRM-105 | product-contract §3 | bare-path branch only | evidence/larp/home.png | — | — | discharged |
EOF
OUT18="$(bash "$VALIDATOR" "$POST18/traceability-matrix.md")"
echo "$OUT18" | grep -qi "Promise conservation holds" || { echo "ERROR: expected structured-token rows to resolve"; echo "$OUT18"; exit 1; }
if echo "$OUT18" | grep -qE "❌ PRM-10[2345]"; then echo "ERROR: PRM-102..105 must not be flagged"; echo "$OUT18"; exit 1; fi
echo "  ✓ Passed Test 18"


echo "Test 19: a genuinely empty cell behaves as today — silent, pre-breakdown open, no [prose] finding"
PRE19="$TMP/prebreak-19"
mkdir -p "$PRE19"
cat > "$PRE19/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-104 | product-contract §3 | vendor sync must complete | — | — | — | open |
EOF
OUT19="$(bash "$VALIDATOR" "$PRE19/traceability-matrix.md")"
if echo "$OUT19" | grep -q "PRM-104"; then echo "ERROR: a truly-empty cell must stay silent (unchanged)"; echo "$OUT19"; exit 1; fi
echo "$OUT19" | grep -q "1 open (pre-breakdown" || { echo "ERROR: expected the row counted as open"; echo "$OUT19"; exit 1; }
echo "  ✓ Passed Test 19"


echo "Test 20: prose-only cell pre-breakdown is treated as open (allowed) but SURFACED, not silent"
PRE20="$TMP/prebreak-20"
mkdir -p "$PRE20"
cat > "$PRE20/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-105 | product-contract §3 | vendor sync must complete | OPEN — not discharged; blocked on vendor API | — | — | open |
EOF
OUT20="$(bash "$VALIDATOR" "$PRE20/traceability-matrix.md")"   # pre-breakdown open is allowed → exit 0
echo "$OUT20" | grep -q "PRM-105" || { echo "ERROR: expected an explicit finding naming PRM-105 (not a silent pass)"; echo "$OUT20"; exit 1; }
echo "$OUT20" | grep -qi "no structured token" || { echo "ERROR: expected the finding to say what token to add"; echo "$OUT20"; exit 1; }
echo "  ✓ Passed Test 20"


echo "Test 21: --require-evidence inspects the DEC cell's CONTENT for a descoped row (no inversion)"
# The verified defect: --require-evidence resolved `descoped` on the status WORD alone and never
# looked at the DEC cell, so the STRICTEST gate — the one /epic-validate actually invokes
# (.cursor/skills/epic-validate/SKILL.md) — was WEAKER than the routine default one. On this exact
# fixture default mode exited 1 with "prose alone does not resolve conservation" while BOTH
# --require-evidence and --require-evidence --status-only printed "✅ Promise conservation holds"
# and exited 0. Prose-as-proof bought green at epic close.
INV21="$TMP/inversion-21"
mkdir -p "$INV21"
touch "$INV21/epic-breakdown.md"
cat > "$INV21/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-202 | product-contract §3 | legal descope | — | not descoped yet, waiting on legal review | — | descoped |
EOF
for mode in "--require-evidence" "--require-evidence --status-only" ""; do
  # shellcheck disable=SC2086
  if OUT21="$(bash "$VALIDATOR" $mode "$INV21/traceability-matrix.md" 2>&1)"; then
    echo "ERROR: prose DEC cell must BLOCK in mode '${mode:-<default>}' — it exited 0"; echo "$OUT21"; exit 1
  fi
  echo "$OUT21" | grep -q "PRM-202" || { echo "ERROR: mode '${mode:-<default>}' must NAME the row"; echo "$OUT21"; exit 1; }
  echo "$OUT21" | grep -qF "not descoped yet, waiting on legal review" || { echo "ERROR: mode '${mode:-<default>}' must quote the offending cell"; echo "$OUT21"; exit 1; }
  echo "$OUT21" | grep -qi "no structured token" || { echo "ERROR: mode '${mode:-<default>}' must say WHAT is missing"; echo "$OUT21"; exit 1; }
done
# Control: a real DEC still resolves under every mode (the fix must not blanket-block descopes).
cat > "$INV21/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-203 | product-contract §3 | legal descope | — | DEC-0207 | — | descoped |
EOF
for mode in "--require-evidence" "--require-evidence --status-only" ""; do
  # shellcheck disable=SC2086
  bash "$VALIDATOR" $mode "$INV21/traceability-matrix.md" >/dev/null || {
    echo "ERROR: a real DEC-0207 descope must still PASS in mode '${mode:-<default>}'"; exit 1; }
done
echo "  ✓ Passed Test 21"


echo "Test 22: PROPERTY — every row default mode blocks, --require-evidence must block too"
# The invariant that prevents the inversion class from recurring, stated once over a fixture set
# instead of case by case: --require-evidence is a strict SUPERSET of default mode. It may block
# MORE (it cross-references story validation reports); it may never block LESS. Only add rows here
# that default mode is expected to BLOCK — the anti-vacuity assertion below enforces that.
PROP="$TMP/property-22"
mkdir -p "$PROP"
touch "$PROP/epic-breakdown.md"
PROP_HEADER='| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|--------|'
PROP_ROWS=(
  "| PRM-301 | product-contract §3 | legal descope | — | not descoped yet, waiting on legal review | — | descoped |"
  "| PRM-302 | product-contract §3 | legal descope | — | — | — | descoped |"
  "| PRM-303 | product-contract §3 | vendor sync | OPEN — not discharged; blocked on vendor API | — | — | discharged |"
  "| PRM-304 | product-contract §3 | vendor sync | — | — | — | discharged |"
  "| PRM-305 | product-contract §3 | vendor sync | still deciding with the vendor | — | — | open |"
  "| PRM-306 | product-contract §3 | vendor sync | — | — | — | open |"
  "| PRM-307 | product-contract §3 | complex flow | — | — | — | pilot-gated |"
  "| PRM-308 | product-contract §3 | complex flow | — | — | we will decide this in the pilot | pilot-gated |"
)
blocked_by_default=0
for row in "${PROP_ROWS[@]}"; do
  printf '# Promise Traceability Matrix\n\n%s\n%s\n' "$PROP_HEADER" "$row" > "$PROP/traceability-matrix.md"
  default_rc=0; bash "$VALIDATOR" "$PROP/traceability-matrix.md" >/dev/null 2>&1 || default_rc=$?
  [[ $default_rc -eq 0 ]] && continue
  blocked_by_default=$((blocked_by_default + 1))
  ev_rc=0;   bash "$VALIDATOR" --require-evidence "$PROP/traceability-matrix.md" >/dev/null 2>&1 || ev_rc=$?
  so_rc=0;   bash "$VALIDATOR" --require-evidence --status-only "$PROP/traceability-matrix.md" >/dev/null 2>&1 || so_rc=$?
  if [[ $ev_rc -eq 0 || $so_rc -eq 0 ]]; then
    echo "ERROR: GATE INVERSION — default mode blocked this row (exit $default_rc) but the STRICTER"
    echo "       gate let it through: --require-evidence exit $ev_rc, --status-only exit $so_rc"
    echo "       row: $row"
    exit 1
  fi
done
if [[ $blocked_by_default -ne ${#PROP_ROWS[@]} ]]; then
  echo "ERROR: property loop went vacuous — only $blocked_by_default of ${#PROP_ROWS[@]} fixtures were blocked by default mode,"
  echo "       so the superset invariant was asserted on fewer rows than intended."
  exit 1
fi
echo "  ✓ Passed Test 22 ($blocked_by_default rows, superset invariant held in both evidence modes)"


echo "Test 23: the message's OWN example (AUDIT-E002-42 ALONE) must resolve conservation — P1 fix"
# VERIFIED DEFECT (v9.6, undeclared breaking change): a pilot-gated row with NO backing reference
# fails with a finding that says "Cite fine-grained audit/matrix refs (e.g. AUDIT-E002-42,
# PRM-054)" — but has_structured_token() had branches for S/AC/DEC/PRM/path and NO AUDIT branch,
# so an author who cited EXACTLY "AUDIT-E002-42" (the message's own suggestion) still failed. The
# template's own example row (traceability-matrix-template.md §2, PRM-005) only ever survived
# because it ALSO carries "E002/PRM-054" riding along. This fixture is DERIVED FROM THAT SHIPPED
# TEMPLATE ROW — same Source/Promise/Status — with the Backing cell reduced to the bare AUDIT
# token the message names, so it exercises exactly the gap a hand-typed minimal fixture would miss.
FIX23="$TMP/fix-23"
mkdir -p "$FIX23"
cat > "$FIX23/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: [Epic Name]

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Grain (proven-at) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|-------------------|--------|
| PRM-005 | wireframes S05 / dashboard | consolidated complex visual flow | — | — | AUDIT-E002-42 | — | pilot-gated |
EOF
OUT23="$(bash "$VALIDATOR" --require-evidence --status-only "$FIX23/traceability-matrix.md" 2>&1)"; RC23=$?
[[ "$RC23" -eq 0 ]] || { echo "ERROR: a Backing cell of the message's own example 'AUDIT-E002-42' must PASS, not fail"; echo "$OUT23"; exit 1; }
echo "$OUT23" | grep -q "❌ PRM-005" && { echo "ERROR: PRM-005 must not be flagged"; echo "$OUT23"; exit 1; }
echo "  ✓ Passed Test 23 (bare AUDIT-E002-42 resolves conservation)"


echo "Test 24: MUTATION PROOF — reverting the AUDIT branch in a SCRATCH COPY turns Test 23 RED"
# Confirms the mutation site is the REAL control point: has_structured_token() itself, not a
# default arg or an unreached branch. Deleting exactly the AUDIT line must flip Test 23's fixture
# from pass to fail — nothing else about the validator changes.
# The scratch copy must sit in a MIRRORED tree: the validator sources ../../lib/text.sh relative to
# its own location (#118), so a flat copy in $TMP would die on a missing library and "fail" for the
# wrong reason — a mutation proof that passes because the mutant crashed proves nothing.
SCRATCH24_ROOT="$TMP/scratch24"
mkdir -p "$SCRATCH24_ROOT/.speck/scripts/validation/validators" "$SCRATCH24_ROOT/.speck/scripts/lib"
cp "$ROOT/.speck/scripts/lib/text.sh" "$SCRATCH24_ROOT/.speck/scripts/lib/text.sh"
SCRATCH24="$SCRATCH24_ROOT/.speck/scripts/validation/validators/validate-traceability-matrix.sh"
cp "$ROOT/.speck/scripts/validation/validators/validate-traceability-matrix.sh" "$SCRATCH24"
# Remove the AUDIT branch line (portable: match on the literal regex text, not line number).
sed -i.bak '/\[\[ "\$v" =~ AUDIT-\[A-Za-z0-9-\]\*\[0-9\] \]\] && return 0/d' "$SCRATCH24"
grep -q '=~ AUDIT-\[A-Za-z0-9-\]\*\[0-9\] \]\] && return 0' "$SCRATCH24" && { echo "ERROR: mutation did not actually remove the AUDIT branch (control point not found)"; exit 1; }
if bash "$SCRATCH24" --require-evidence --status-only "$FIX23/traceability-matrix.md" >/dev/null 2>&1; then
  echo "ERROR: MUTATION PROOF FAILED — reverting the AUDIT branch should make the fixture fail (RED), but it still passed"
  exit 1
fi
echo "  ✓ Passed Test 24 (revert-and-confirm-RED: the AUDIT branch is the real control point)"


echo "Test 25: ESCAPED PIPE in a Backing cell does not shift the columns after it (#118)"
# The Backing column holds evidence, and evidence is commands — so a matrix row WILL eventually
# carry a shell pipeline. Pre-fix, `IFS='|'` split on the `\|` too: the row below yielded one extra
# cell, the header-resolved Grain index landed on Backing and Status landed on Grain. The author
# wrote `discharged`; the validator read `story` and reported an unresolved promise.
FIX25="$TMP/fix25"; mkdir -p "$FIX25"
cat > "$FIX25/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Grain (proven-at) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|-------------------|--------|
| PRM-001 | product-contract §3 | grant posture is revoked | S002 / AC-1 | — | S002/AC-1 via `supabase status -o env \| sed 's/^/export /'` | impl-green | discharged |
EOF
OUT25="$(bash "$VALIDATOR" --require-evidence --status-only "$FIX25/traceability-matrix.md" 2>&1)"; RC25=$?
[[ "$RC25" -eq 0 ]] || { echo "ERROR: a row whose Backing cell cites a shell pipeline must still resolve"; echo "$OUT25"; exit 1; }
echo "$OUT25" | grep -q "cells but the header has" && { echo "ERROR: an ESCAPED pipe must not trip the cell-count check"; echo "$OUT25"; exit 1; }
echo "  ✓ Passed Test 25 (escaped pipe parsed as one cell; Status still read as 'discharged')"


echo "Test 26: an UNESCAPED extra pipe is REPORTED, not silently re-read"
# The cause-agnostic half of #118: whatever produces a cell-count divergence, every column after it
# is read from the wrong cell. One count comparison surfaces the class without knowing the cause.
FIX26="$TMP/fix26"; mkdir -p "$FIX26"
cat > "$FIX26/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Test Epic

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Grain (proven-at) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|-------------------|--------|
| PRM-001 | product-contract §3 | grant posture is revoked | S002 / AC-1 | — | a | b | impl-green | discharged |
EOF
OUT26="$(bash "$VALIDATOR" --require-evidence --status-only "$FIX26/traceability-matrix.md" 2>&1 || true)"
echo "$OUT26" | grep -q "cells but the header has" || { echo "ERROR: a column-count divergence must be reported, not absorbed"; echo "$OUT26"; exit 1; }
echo "  ✓ Passed Test 26 (cell-count divergence surfaced)"


echo "All validate-traceability-matrix tests passed successfully!"
exit 0
