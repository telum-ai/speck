#!/usr/bin/env bash
# reconcile-matrix-grain.test.sh — tests for the v8 re-prove matrix grain reconciler (#87)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
RECONCILE="$ROOT/.speck/scripts/validation/reconcile-matrix-grain.sh"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-traceability-matrix.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

EPIC="$TMP/projects/001-app/epics/051-crew"
mkdir -p "$EPIC/stories/S050-a" "$EPIC/stories/S051-b"

# S050 — pre-v8 capped report (claim UX-RC, stamped [pre-v8-proof]).
cat > "$EPIC/stories/S050-a/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC [pre-v8-proof]
---
> ### ⛔ [pre-v8-proof] — v8 re-prove cap
Spec Coverage:
- PRM-001
EOF

# S051 — clean v8-native report (INTEGRATION-GREEN, no pre-v8 stamp).
cat > "$EPIC/stories/S051-b/validation-report.md" <<'EOF'
---
readiness_state_verified: INTEGRATION-GREEN
---
Spec Coverage:
- PRM-002
EOF

# 7-column matrix (Backing, no Grain) — the v7.14 shape #87 describes.
cat > "$EPIC/traceability-matrix.md" <<'EOF'
# Promise Traceability Matrix: Crew

## 2. Traceability Matrix

| PRM-ID | Source (artifact §/screen/element) | Promise (what is owed) | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing (fine-grained PRM/audit refs) | Status |
|--------|------------------------------------|------------------------|-------------------------------|-------------------|---------------------------------------|--------|
| PRM-001 | product-contract §3 | differentiator pillar text | S050 / AC-1 | — | — | discharged |
| PRM-002 | epic.md NFR-003 | backend invariant | S051 / AC-2 | — | — | discharged |
| PRM-003 | experience-chain §6 | seam rule | — | DEC-0207 | — | descoped |
EOF

echo "Test 1: reconcile inserts Grain column + caps the pre-v8 row, leaves the clean row un-graded"
bash "$RECONCILE" "$TMP/projects/001-app" >/dev/null
MX="$EPIC/traceability-matrix.md"

grep -q "Grain (proven-at)" "$MX" || { echo "ERROR: Grain column not inserted"; cat "$MX"; exit 1; }
# PRM-001 (pre-v8) → capped grain integration-green [pre-v8-proof]
grep -E "^\| PRM-001 .*integration-green \[pre-v8-proof\] \| discharged \|" "$MX" >/dev/null \
  || { echo "ERROR: PRM-001 not capped to integration-green [pre-v8-proof]"; grep PRM-001 "$MX"; exit 1; }
# PRM-002 (clean v8) → un-graded (—), NOT promoted
grep -E "^\| PRM-002 .* \| — \| discharged \|" "$MX" >/dev/null \
  || { echo "ERROR: PRM-002 (clean) should stay un-graded (—)"; grep PRM-002 "$MX"; exit 1; }
# Status column untouched — all discharged/descoped rows still present
grep -cq . "$MX"
echo "  ✓ Passed Test 1"

echo "Test 2: never auto-promotes — no row gains a ≥ ux-rc grain"
if grep -E "\| (ux-rc|api-rc|operational-rc|commercial-rc|ship-rc|ship)( \[pre-v8-proof\])? \| discharged \|" "$MX" >/dev/null; then
  echo "ERROR: a row was promoted to product grain"; cat "$MX"; exit 1
fi
echo "  ✓ Passed Test 2"

echo "Test 3: idempotent — a second run makes no change"
CKSUM_BEFORE="$(cksum < "$MX")"
bash "$RECONCILE" "$TMP/projects/001-app" >/tmp/reconcile2.log 2>&1
CKSUM_AFTER="$(cksum < "$MX")"
[[ "$CKSUM_BEFORE" == "$CKSUM_AFTER" ]] || { echo "ERROR: second run changed the file"; exit 1; }
grep -q "already reconciled" /tmp/reconcile2.log || { echo "ERROR: expected 'already reconciled' on rerun"; cat /tmp/reconcile2.log; exit 1; }
echo "  ✓ Passed Test 3"

echo "Test 4: the reconciled matrix now validates + reports the honest cap"
OUT="$(bash "$VALIDATOR" --require-evidence --status-only "$MX")"
echo "$OUT" | grep -q "MATRIX_GRAIN_CAP=integration-green" || { echo "ERROR: expected integration-green cap"; echo "$OUT"; exit 1; }
echo "  ✓ Passed Test 4"

echo "Test 5: dry-run does not modify the file"
cp "$MX" "$TMP/mx-backup.md"
# Add a fresh pre-v8 story+matrix to force a would-be change; use --dry-run.
EPIC2="$TMP/projects/001-app/epics/052-dry"
mkdir -p "$EPIC2/stories/S060-x"
cat > "$EPIC2/stories/S060-x/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC [pre-v8-proof]
---
- PRM-010
EOF
cat > "$EPIC2/traceability-matrix.md" <<'EOF'
# M

## 2. Traceability Matrix

| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC (if descoped) | Backing | Status |
|--------|--------|---------|-------------------------------|-------------------|---------|--------|
| PRM-010 | product-contract §3 | pillar | S060 / AC-1 | — | — | discharged |
EOF
CK_DRY_BEFORE="$(cksum < "$EPIC2/traceability-matrix.md")"
bash "$RECONCILE" --dry-run "$TMP/projects/001-app" >/tmp/reconcile-dry.log 2>&1
CK_DRY_AFTER="$(cksum < "$EPIC2/traceability-matrix.md")"
[[ "$CK_DRY_BEFORE" == "$CK_DRY_AFTER" ]] || { echo "ERROR: dry-run modified the file"; exit 1; }
grep -q "would regrade" /tmp/reconcile-dry.log || { echo "ERROR: expected 'would regrade' in dry-run"; cat /tmp/reconcile-dry.log; exit 1; }
echo "  ✓ Passed Test 5"

echo "All reconcile-matrix-grain tests passed successfully!"
exit 0
