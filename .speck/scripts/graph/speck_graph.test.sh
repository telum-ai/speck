#!/usr/bin/env bash
# speck_graph.test.sh — tests for the Speck Witness Graph extractor + lint-refs gate (v8.7, graph arc)
#
# Covers: clean resolution, real dangling-ref rot (P1), migration degrade-to-honest (P3),
# cross-epic ordinal/full-dir resolution, duplicate-id detection, header-keyed table parsing
# (column-reorder resilience), and build determinism (idempotent, content-hashed).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
GRAPH="$ROOT/.speck/scripts/graph/speck_graph.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "  ✅ $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  ❌ $1"; echo "     $2"; }

PROJ="$TMP/projects/001-demo"
mkdir -p "$PROJ"

# --- product-contract with MM-N + JOB-N ids ---
cat > "$PROJ/product-contract.md" <<'EOF'
# Product Contract: Demo

## 2. Primary Persona
**JTBD** (`JOB-1`): When X, I want Y, so that Z.

## 5. Magic Moments
### MM-1 — First wow
### MM-2 — Second wow
EOF

# --- epic 001-alpha: two stories, one with AC-N anchors, matrix discharging them ---
mkdir -p "$PROJ/epics/001-alpha/stories/S001-foo" "$PROJ/epics/001-alpha/stories/S002-bar"
cat > "$PROJ/epics/001-alpha/stories/S001-foo/spec.md" <<'EOF'
---
artifact_type: story-spec
depends_on: []
blocks: [S002]
readiness_state_verified: UX-RC
---
# Story: Foo
Delivers MM-1.
#### AC-1 — Primary
#### AC-2 — Alt
EOF
cat > "$PROJ/epics/001-alpha/stories/S002-bar/spec.md" <<'EOF'
---
artifact_type: story-spec
depends_on: [S001, 002/S001]
blocks: []
readiness_state_verified: IMPL-GREEN
---
# Story: Bar
Serves JOB-1.
#### AC-1 — Only
EOF
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix: Alpha
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow lands | S001 / AC-1 | — | ux-rc | discharged |
| PRM-002 | product-contract §2 JOB-1 | job done | S002 / AC-1 | — | impl-green | discharged |
EOF

# --- epic 002-beta: a story so cross-epic ordinal ref (002/S001) resolves ---
mkdir -p "$PROJ/epics/002-beta/stories/S001-baz"
cat > "$PROJ/epics/002-beta/stories/S001-baz/spec.md" <<'EOF'
---
artifact_type: story-spec
depends_on: []
blocks: []
---
# Story: Baz
EOF

echo "── Test 1: clean project → lint-refs passes, all refs resolve"
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "all cross-references resolve"; then
  ok "clean project resolves (exit 0)"
else
  bad "clean project should resolve" "$OUT (rc=$RC)"
fi

echo "── Test 2: build emits valid JSON with counts, completeness, content hashes"
python3 "$GRAPH" build "$PROJ" >/dev/null 2>&1
if [[ -f "$PROJ/graph/witness.json" ]]; then
  python3 - "$PROJ/graph/witness.json" <<'PY' && ok "witness.json is valid, complete, hashed" || bad "witness.json malformed" "see above"
import json, sys
g = json.load(open(sys.argv[1]))
assert g["schema_version"] == "1.0", g["schema_version"]
assert g["generator_completeness"] == "complete", g["generator_completeness"]
assert g["counts"]["by_kind"].get("magic-moment") == 2, g["counts"]
assert g["counts"]["by_kind"].get("job") == 1, g["counts"]
assert g["counts"]["by_kind"].get("ac") == 3, g["counts"]
assert all(n["content_hash"] for n in g["nodes"]), "every node must be content-hashed"
PY
else
  bad "build did not write witness.json" "missing file"
fi

echo "── Test 3: cross-epic ordinal ref (002/S001) resolves (no dangling)"
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)"
if ! echo "$OUT" | grep -q "002/S001"; then ok "ordinal cross-epic ref resolved"; else bad "002/S001 should resolve" "$OUT"; fi

echo "── Test 4: dangling story ref → real P1"
mkdir -p "$PROJ/epics/001-alpha/stories/S003-dangler"
cat > "$PROJ/epics/001-alpha/stories/S003-dangler/spec.md" <<'EOF'
---
artifact_type: story-spec
depends_on: [S099]
blocks: []
---
# Story: Dangler
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 1 ]] && echo "$OUT" | grep -q "DANGLING_REF.P1" && echo "$OUT" | grep -q "S099"; then
  ok "dangling story ref blocks (P1, exit 1)"
else
  bad "dangling story ref should be P1" "$OUT (rc=$RC)"
fi
rm -rf "$PROJ/epics/001-alpha/stories/S003-dangler"

echo "── Test 5: discharge → AC in a story with NO AC-N anchors degrades to P3 (not rot)"
mkdir -p "$PROJ/epics/003-gamma/stories/S001-unmig"
cat > "$PROJ/epics/003-gamma/stories/S001-unmig/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: Unmigrated (no AC-N headings)
EOF
cat > "$PROJ/epics/003-gamma/traceability-matrix.md" <<'EOF'
# Matrix: Gamma
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | epic.md FR-001 | thing | S001 / AC-1 | — | — | discharged |
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if echo "$OUT" | grep -q "GRAPH_UNMIGRATED.P3" && ! echo "$OUT" | grep -q "003-gamma/S001/AC-1 : story defines"; then
  ok "AC ref into un-migrated story degrades to P3"
else
  bad "un-migrated AC should be P3, not P1" "$OUT (rc=$RC)"
fi
rm -rf "$PROJ/epics/003-gamma"

echo "── Test 6: discharge → AC in a story that HAS AC-N but not this one → real P1 (renumber)"
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix: Alpha
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-9 | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 1 ]] && echo "$OUT" | grep -q "renumbered"; then
  ok "AC into a story with anchors but wrong number → P1"
else
  bad "renumbered AC should be P1" "$OUT (rc=$RC)"
fi

echo "── Test 7: column-reorder resilience (header-keyed parse)"
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix: Alpha (columns reordered!)
## 2. Traceability Matrix
| Status | Discharge (story-id + AC-ref) | PRM-ID | Grain | Source | Promise | DEC |
|--------|-------------------------------|--------|-------|--------|---------|-----|
| discharged | S001 / AC-1 | PRM-001 | ux-rc | product-contract §5 MM-1 | wow | — |
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]]; then ok "reordered columns still parse + resolve"; else bad "column reorder broke parsing" "$OUT (rc=$RC)"; fi
# restore the clean 2-row matrix
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix: Alpha
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | discharged |
| PRM-002 | product-contract §2 JOB-1 | job | S002 / AC-1 | — | impl-green | discharged |
EOF

echo "── Test 8: duplicate story id in one epic → DUP_ID.P1"
mkdir -p "$PROJ/epics/001-alpha/stories/S001-dupe"
cat > "$PROJ/epics/001-alpha/stories/S001-dupe/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: Dupe (same S-number as S001-foo)
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 1 ]] && echo "$OUT" | grep -q "DUP_ID.P1"; then ok "duplicate story id caught (P1)"; else bad "dup id should be P1" "$OUT (rc=$RC)"; fi
rm -rf "$PROJ/epics/001-alpha/stories/S001-dupe"

echo "── Test 9: build is deterministic (idempotent, byte-identical)"
python3 "$GRAPH" build "$PROJ" >/dev/null 2>&1; H1="$(shasum "$PROJ/graph/witness.json" | awk '{print $1}')"
python3 "$GRAPH" build "$PROJ" >/dev/null 2>&1; H2="$(shasum "$PROJ/graph/witness.json" | awk '{print $1}')"
if [[ "$H1" == "$H2" ]]; then ok "build is deterministic"; else bad "build not deterministic" "$H1 != $H2"; fi

echo "── Test 10: unadopted MM/JOB scheme degrades to P3, does not block"
cat > "$PROJ/product-contract.md" <<'EOF'
# Product Contract: Demo (no MM-N / JOB-N ids — free-text era)
## 5. Magic Moments
### First wow
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "GRAPH_UNMIGRATED.P3"; then
  ok "unadopted MM scheme → P3, exit 0 (degrade-to-honest)"
else
  bad "unadopted MM should degrade, not block" "$OUT (rc=$RC)"
fi

echo "── Test 11: query returns a node's in/out edges"
OUT="$(python3 "$GRAPH" query "$PROJ" "001-alpha/PRM-001" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q '"discharges"' && echo "$OUT" | grep -q "001-alpha/S001/AC-1"; then
  ok "query resolves a PRM and shows its discharge edge"
else
  bad "query should show PRM edges" "$OUT (rc=$RC)"
fi

echo "── Test 12: context pack assembles a story's discharges + ACs + deps in one call"
OUT="$(python3 "$GRAPH" context "$PROJ" "S001" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] \
   && echo "$OUT" | grep -q '"acs"' \
   && echo "$OUT" | grep -q "001-alpha/S001/AC-1" \
   && echo "$OUT" | grep -q '"prm": "001-alpha/PRM-001"' \
   && echo "$OUT" | grep -q "001-alpha/S002"; then
  ok "context pack resolves bare 'S001' and assembles discharges + ACs + blocks"
else
  bad "context pack incomplete" "$OUT (rc=$RC)"
fi

echo "── Test 13: check — phantom promise (an MM no story delivers) → P1, GRAPH_CAP NO-SHIP"
CHK="$TMP/projects/002-check"
mkdir -p "$CHK/epics/001-x/stories/S001-a"
cat > "$CHK/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — Delivered
### MM-2 — Nobody delivers this
EOF
cat > "$CHK/epics/001-x/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: A
Delivers MM-1.
#### AC-1 — primary
EOF
cat > "$CHK/epics/001-x/traceability-matrix.md" <<'EOF'
# Matrix
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" check "$CHK" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 1 ]] && echo "$OUT" | grep -q "PHANTOM_PROMISE.P1" && echo "$OUT" | grep -q "MM-2" && echo "$OUT" | grep -q "GRAPH_CAP = NO-SHIP"; then
  ok "phantom promise (MM-2) blocks; GRAPH_CAP NO-SHIP"
else
  bad "phantom promise should block" "$OUT (rc=$RC)"
fi

echo "── Test 14: check never rubber-stamps — orphan-code + un-judged reported as NOT-evaluated"
if echo "$OUT" | grep -q "ORPHAN_CODE: pending" && echo "$OUT" | grep -q "UNJUDGED_SURFACE: pending" \
   && echo "$OUT" | grep -q "NOT graph-provable"; then
  ok "honest pending notes present; taste explicitly not claimed"
else
  bad "check must not claim un-evaluated gates as passing" "$OUT"
fi

echo "── Test 15: check on a fully-served graph → no P1 block (caps only), exit 0"
# make MM-2 delivered too
cat > "$CHK/epics/001-x/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: A
Delivers MM-1 and MM-2.
#### AC-1 — primary
EOF
OUT="$(python3 "$GRAPH" check "$CHK" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && ! echo "$OUT" | grep -q "PHANTOM_PROMISE.P1"; then
  ok "no phantom once every MM is delivered (exit 0, caps only)"
else
  bad "fully-served graph should not block" "$OUT (rc=$RC)"
fi

echo ""
echo "════════════════════════════════════════════"
echo "  speck_graph: $PASS passed, $FAIL failed"
echo "════════════════════════════════════════════"
[[ $FAIL -eq 0 ]]
