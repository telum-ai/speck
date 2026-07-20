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
depends_on: [S001, 002/S077]   # S077 exists ONLY in epic 002 — a decisive cross-epic test
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

# --- epic 002-beta: S001-baz + a uniquely-numbered S077 that ONLY exists here ---
mkdir -p "$PROJ/epics/002-beta/stories/S001-baz" "$PROJ/epics/002-beta/stories/S077-uniq"
cat > "$PROJ/epics/002-beta/stories/S001-baz/spec.md" <<'EOF'
---
artifact_type: story-spec
depends_on: []
blocks: []
---
# Story: Baz
EOF
cat > "$PROJ/epics/002-beta/stories/S077-uniq/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: Uniq (only in epic 002)
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

echo "── Test 3: cross-epic ordinal ref (002/S077) resolves to the RIGHT epic (decisive)"
# S077 exists only in epic 002-beta; if the ordinal qualifier were dropped it'd resolve to
# 001-alpha/S077 (absent) and dangle. Assert the edge landed on 002-beta/S077.
OUT="$(python3 "$GRAPH" query "$PROJ" "001-alpha/S002" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q '"to": "002-beta/S077"'; then
  ok "ordinal cross-epic ref resolved to the correct epic (002-beta/S077)"
else
  bad "cross-epic ordinal qualifier was dropped or misresolved" "$OUT (rc=$RC)"
fi

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

echo "── Test 16: MM delivered ONLY via a discharged PRM (no serves edge) is NOT phantom"
CHK2="$TMP/projects/003-prmpath"
mkdir -p "$CHK2/epics/001-x/stories/S001-a"
cat > "$CHK2/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — Delivered via the matrix, not a serves edge
EOF
# story body does NOT mention MM-1 (no serves edge) — delivery is via the discharged PRM
cat > "$CHK2/epics/001-x/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: A
#### AC-1 — primary
EOF
cat > "$CHK2/epics/001-x/traceability-matrix.md" <<'EOF'
# Matrix
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" check "$CHK2" 2>&1)" && RC=0 || RC=$?
if ! echo "$OUT" | grep -q "PHANTOM_PROMISE.P1"; then
  ok "MM delivered via discharged PRM is not flagged phantom (no false positive)"
else
  bad "PRM-sourcing delivery path should count as delivered" "$OUT (rc=$RC)"
fi

echo "── Test 17: multi-target discharge cell — a dangling target in a NON-first slot is caught"
mkdir -p "$PROJ/epics/001-alpha/stories/S050-multi"
cat > "$PROJ/epics/001-alpha/stories/S050-multi/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: Multi
#### AC-1 — a
EOF
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-1, S050 / AC-1, S999 / AC-1 | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 1 ]] && echo "$OUT" | grep -q "S999"; then
  ok "dangling target in 3rd discharge slot is caught (multi-target parse)"
else
  bad "non-first multi-target should not be dropped" "$OUT (rc=$RC)"
fi
rm -rf "$PROJ/epics/001-alpha/stories/S050-multi"
# restore clean 2-row matrix
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix: Alpha
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | discharged |
| PRM-002 | product-contract §2 JOB-1 | job | S002 / AC-1 | — | impl-green | discharged |
EOF

echo "── Test 18: inline YAML comment in depends_on does NOT leak phantom refs"
mkdir -p "$PROJ/epics/001-alpha/stories/S060-cmt"
cat > "$PROJ/epics/001-alpha/stories/S060-cmt/spec.md" <<'EOF'
---
artifact_type: story-spec
depends_on: []          # nothing blocks it (S010/S099 shipped already)
blocks: []
---
# Story: Cmt
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && ! echo "$OUT" | grep -q "S099"; then
  ok "comment tokens (S010/S099) do not become phantom depends-on edges"
else
  bad "inline YAML comment leaked into refs" "$OUT (rc=$RC)"
fi
rm -rf "$PROJ/epics/001-alpha/stories/S060-cmt"

echo "── Test 19: sub-lettered AC (AC-1a) is extracted + resolvable"
mkdir -p "$PROJ/epics/001-alpha/stories/S070-sub"
cat > "$PROJ/epics/001-alpha/stories/S070-sub/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: Sub
## 2. Acceptance
#### AC-1a — first sub
#### AC-1b — second sub
EOF
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S070 / AC-1a | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" lint-refs "$PROJ" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]]; then ok "AC-1a extracted as a node and the discharge resolves"; else bad "sub-lettered AC not handled" "$OUT (rc=$RC)"; fi
rm -rf "$PROJ/epics/001-alpha/stories/S070-sub"
cat > "$PROJ/epics/001-alpha/traceability-matrix.md" <<'EOF'
# Matrix: Alpha
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | discharged |
| PRM-002 | product-contract §2 JOB-1 | job | S002 / AC-1 | — | impl-green | discharged |
EOF

echo "── Test 20: GRAPH_STALE fires on a content change that keeps id-set + edge-count"
python3 "$GRAPH" build "$PROJ" >/dev/null 2>&1
python3 - "$PROJ/graph/witness.json" <<'PY'
import json, sys
p = sys.argv[1]; g = json.load(open(p))
# mutate a node's title only — same ids, same edge count
for n in g["nodes"]:
    if n["kind"] == "story":
        n["title"] = n["title"] + " (hand-edited)"; break
json.dump(g, open(p, "w"), indent=2)
PY
OUT="$(python3 "$GRAPH" check "$PROJ" 2>&1)" && RC=0 || RC=$?
if echo "$OUT" | grep -q "GRAPH_STALE.P2"; then ok "content change (same ids/count) detected as stale"; else bad "stale content evaded detection" "$OUT"; fi
python3 "$GRAPH" build "$PROJ" >/dev/null 2>&1  # restore fresh

echo "── Test 21: decorated Status ('**discharged** (UX-RC)') normalizes — no spurious phantom"
CHK3="$TMP/projects/004-decorated"
mkdir -p "$CHK3/epics/001-x/stories/S001-a"
cat > "$CHK3/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — delivered via a decorated-status PRM
EOF
cat > "$CHK3/epics/001-x/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: A
#### AC-1 — a
EOF
cat > "$CHK3/epics/001-x/traceability-matrix.md" <<'EOF'
# Matrix
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | **discharged** (UX-RC — baked-build LARP) |
EOF
OUT="$(python3 "$GRAPH" check "$CHK3" 2>&1)" && RC=0 || RC=$?
if ! echo "$OUT" | grep -q "PHANTOM_PROMISE.P1"; then ok "decorated status counts as discharged (no false phantom)"; else bad "decorated status broke phantom gate" "$OUT"; fi

echo "── Test 22: parser resilience — single-dash divider + escaped pipe"
CHK4="$TMP/projects/005-parser"
mkdir -p "$CHK4/epics/001-x/stories/S001-a"
cat > "$CHK4/epics/001-x/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: A
#### AC-1 — a
EOF
cat > "$CHK4/epics/001-x/traceability-matrix.md" <<'EOF'
# Matrix
## 2. Traceability Matrix
|PRM-ID|Source|Promise|Discharge (story-id + AC-ref)|DEC|Grain|Status|
|-|-|-|-|-|-|-|
|PRM-001|a \| b pipe in cell|wow|S001 / AC-1|—|ux-rc|discharged|
EOF
OUT="$(python3 "$GRAPH" lint-refs "$CHK4" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "all cross-references resolve"; then
  ok "single-dash divider + escaped pipe parsed correctly (row not dropped/shifted)"
else
  bad "parser dropped/shifted a row" "$OUT (rc=$RC)"
fi

echo "── Test 23: gate — orphan story in a promise-adopted epic BLOCKS (build the right thing)"
GT="$TMP/projects/006-gate"
mkdir -p "$GT/epics/001-e/stories/S001-orphan" "$GT/epics/001-e/stories/S002-wired"
printf -- '---\nartifact_type: story-spec\n---\n# Orphan\n' > "$GT/epics/001-e/stories/S001-orphan/spec.md"
printf -- '---\nartifact_type: story-spec\n---\n# Wired\n#### AC-1 — a\n' > "$GT/epics/001-e/stories/S002-wired/spec.md"
cat > "$GT/epics/001-e/traceability-matrix.md" <<'EOF'
# M
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | x | y | S002 / AC-1 | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" gate "$GT" --story 001-e/S001 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 1 ]] && echo "$OUT" | grep -q "ORPHAN_STORY.P1"; then
  ok "orphan story blocks in a promise-adopted epic (exit 1)"
else
  bad "orphan story should block" "$OUT (rc=$RC)"
fi

echo "── Test 24: gate — the SAME missing structure GUIDES (not blocks) in an un-adopted epic"
mkdir -p "$GT/epics/002-fresh/stories/S001-new"
printf -- '---\nartifact_type: story-spec\n---\n# New\n' > "$GT/epics/002-fresh/stories/S001-new/spec.md"
OUT="$(python3 "$GRAPH" gate "$GT" --story 002-fresh/S001 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "guide-rail"; then
  ok "fresh story in un-adopted epic is guided, not walled (exit 0)"
else
  bad "greenfield story should not be bricked" "$OUT (rc=$RC)"
fi

echo "── Test 25: gate — a wired story clears; scoping isolates unrelated rot"
OUT="$(python3 "$GRAPH" gate "$GT" --story 001-e/S002 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]]; then ok "wired story clears (exit 0)"; else bad "wired story should clear" "$OUT (rc=$RC)"; fi

echo "── Test 26: road emits the four ordered buckets and routes findings correctly"
RD="$TMP/projects/007-road"
mkdir -p "$RD/epics/001-e/stories/S001-a"
cat > "$RD/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — delivered
### MM-2 — nobody builds this
EOF
printf -- '---\nartifact_type: story-spec\n---\n# A\nDelivers MM-1.\n#### AC-1 — a\n' > "$RD/epics/001-e/stories/S001-a/spec.md"
cat > "$RD/epics/001-e/traceability-matrix.md" <<'EOF'
# M
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" road "$RD" --stdout 2>&1)"
if echo "$OUT" | grep -q "🧹 TIDY" && echo "$OUT" | grep -q "🗑 REMOVE" \
   && echo "$OUT" | grep -q "🔨 BUILD" && echo "$OUT" | grep -q "🔬 PROVE" \
   && echo "$OUT" | grep -q "PHANTOM_PROMISE.P1" \
   && echo "$OUT" | grep -qE "BUILD \([1-9]\)"; then
  ok "road has 4 ordered buckets; phantom MM-2 routed to BUILD"
else
  bad "road buckets/routing wrong" "$OUT"
fi

echo "── Test 27: road is DERIVED — carries the never-hand-edit banner + GRAPH_CAP"
if echo "$OUT" | grep -q "NEVER hand-edit" && echo "$OUT" | grep -q "GRAPH_CAP"; then
  ok "road declares itself derived + disposable"
else
  bad "road missing derived banner / GRAPH_CAP" "$OUT"
fi

echo ""
echo "════════════════════════════════════════════"
echo "  speck_graph: $PASS passed, $FAIL failed"
echo "════════════════════════════════════════════"
[[ $FAIL -eq 0 ]]
