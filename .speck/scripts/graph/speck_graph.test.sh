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
serves: [MM-1]
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
serves: [JOB-1]
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
serves: [MM-1]
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

echo "── Test 14: check never rubber-stamps — orphan-code NOT-evaluated; taste stays with /audit+LARP"
if echo "$OUT" | grep -q "ORPHAN_CODE: pending" && echo "$OUT" | grep -q "NOT graph-provable"; then
  ok "orphan-code honestly pending; faithful/good explicitly not claimed by the graph"
else
  bad "check must not claim un-evaluated gates as passing" "$OUT"
fi

echo "── Test 15: check on a fully-served graph → no P1 block (caps only), exit 0"
# make MM-2 delivered too
cat > "$CHK/epics/001-x/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
serves: [MM-1, MM-2]
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
printf -- '---\nartifact_type: story-spec\nserves: [MM-1]\n---\n# A\n#### AC-1 — a\n' > "$RD/epics/001-e/stories/S001-a/spec.md"
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

echo "── Test 28: gap line folds structural findings + axes into one evaluator-legible token"
GP="$TMP/projects/008-gap"
mkdir -p "$GP/epics/001-e/stories/S001-a"
cat > "$GP/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — delivered (adopts the scheme)
### MM-2 — nobody delivers this (phantom)
EOF
printf -- '---\nartifact_type: story-spec\nserves: [MM-1]\n---\n# A\n#### AC-1 — a\n' > "$GP/epics/001-e/stories/S001-a/spec.md"
OUT="$(python3 "$GRAPH" gap "$GP" 2>&1)"
if echo "$OUT" | grep -q "^SPECK-GAP:" && echo "$OUT" | grep -q "PHANTOM_PROMISE" && echo "$OUT" | grep -q "CAP="; then
  ok "gap emits a single SPECK-GAP token with the phantom + cap folded in"
else
  bad "gap line malformed" "$OUT"
fi

echo "── Test 29: emit-goal produces a native /goal condition with the 6 components + anti-gaming"
OUT="$(python3 "$GRAPH" gap "$GP" --emit-goal --target ship-rc 2>&1)"
if echo "$OUT" | grep -q "^/goal " \
   && echo "$OUT" | grep -q "OUTCOME:" && echo "$OUT" | grep -q "VERIFICATION SURFACE:" \
   && echo "$OUT" | grep -q "BLOCKED STOP:" && echo "$OUT" | grep -q "VERBATIM" \
   && echo "$OUT" | grep -q "/goal runs the loop — Speck does not"; then
  ok "emit-goal yields a ready-to-run /goal condition; Speck defers the loop to native /goal"
else
  bad "emit-goal condition incomplete" "$OUT"
fi

echo "── Test 30: UNMAPPED_PROMISE — parity with the conservation script (open flags; mapped/descoped don't)"
CN="$TMP/projects/009-conserv"
mkdir -p "$CN/epics/001-e/stories/S001-a"
printf 'x' > "$CN/epics/001-e/epic-breakdown.md"
printf -- '---\nartifact_type: story-spec\n---\n# A\n#### AC-1 — a\n' > "$CN/epics/001-e/stories/S001-a/spec.md"
cat > "$CN/epics/001-e/traceability-matrix.md" <<'EOF'
# M
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | x | discharged one | S001 / AC-1 | — | ux-rc | discharged |
| PRM-002 | x | mapped one (assigned, pending) | S001 / AC-1 | — | — | mapped |
| PRM-003 | x | descoped one | — | DEC-0009 | — | descoped |
| PRM-004 | x | GENUINELY open | — | — | — | open |
EOF
OUT="$(python3 "$GRAPH" check "$CN" 2>&1)" || true
n_unmapped=$(echo "$OUT" | grep -c "UNMAPPED_PROMISE.P1")
if [[ "$n_unmapped" == "1" ]] && echo "$OUT" | grep -q "PRM-004"; then
  ok "only the genuinely-open PRM-004 flags; discharged/mapped/descoped pass (script parity)"
else
  bad "conservation parity wrong ($n_unmapped unmapped)" "$OUT"
fi

echo "── Test 31: open row is ALLOWED pre-breakdown (guide-rail, not a wall)"
rm -f "$CN/epics/001-e/epic-breakdown.md"
OUT="$(python3 "$GRAPH" check "$CN" 2>&1)" || true
if ! echo "$OUT" | grep -q "UNMAPPED_PROMISE.P1"; then
  ok "pre-breakdown open row is guided (GRAPH_UNMIGRATED), not blocked"
else
  bad "pre-breakdown open row should not block" "$OUT"
fi

echo "── Test 32: DEP_CYCLE — a circular depends_on is caught"
CY="$TMP/projects/010-cycle"
mkdir -p "$CY/epics/001-e/stories/S001-a" "$CY/epics/001-e/stories/S002-b"
printf -- '---\nartifact_type: story-spec\ndepends_on: [S002]\n---\n# A\n' > "$CY/epics/001-e/stories/S001-a/spec.md"
printf -- '---\nartifact_type: story-spec\ndepends_on: [S001]\n---\n# B\n' > "$CY/epics/001-e/stories/S002-b/spec.md"
OUT="$(python3 "$GRAPH" check "$CY" 2>&1)" || true
if echo "$OUT" | grep -q "DEP_CYCLE.P1"; then ok "circular depends_on caught (no valid build order)"; else bad "cycle not detected" "$OUT"; fi

echo "── Test 33: verdict extraction — a recorded MM verdict clears UNJUDGED; the rest is capped"
VJ="$TMP/projects/011-verdict"
mkdir -p "$VJ/epics/001-e/stories/S001-a"
cat > "$VJ/product-contract.md" <<'EOF'
# C
## 5. Magic Moments
### MM-1 — judged
### MM-2 — unjudged
EOF
printf -- '---\nartifact_type: story-spec\nserves: [MM-1, MM-2]\n---\n# A\n#### AC-1 — a\n' > "$VJ/epics/001-e/stories/S001-a/spec.md"
cat > "$VJ/epics/001-e/stories/S001-a/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
## Magic Moment Validation
- **VERDICT** MM-1 = GOOD — pixel-anchored, connoisseur Job B
EOF
OUT="$(python3 "$GRAPH" check "$VJ" 2>&1)" || true
if echo "$OUT" | grep -q "UNJUDGED_SURFACE" && echo "$OUT" | grep -q "MM-2" && ! echo "$OUT" | grep -qE "no recorded verdict.*MM-1"; then
  ok "MM-1 (recorded verdict) clears; MM-2 (no verdict) is UNJUDGED — real gate, not pending"
else
  bad "verdict extraction / UNJUDGED gate wrong" "$OUT"
fi

echo "── Test 34: UNJUDGED proves the machinery RAN, not that the verdict is good (anti-rubber-stamp)"
# even a BAD-recorded verdict counts as JUDGED — honesty of the verdict is /audit's job, not the graph's
cat > "$VJ/epics/001-e/stories/S001-a/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
## Magic Moment Validation
- **VERDICT** MM-1 = GOOD
- **VERDICT** MM-2 = BAD — cheap-feeling, needs work
EOF
OUT="$(python3 "$GRAPH" check "$VJ" 2>&1)" || true
if ! echo "$OUT" | grep -q "UNJUDGED_SURFACE"; then
  ok "a recorded BAD verdict still counts as judged (graph proves it ran; /audit owns its honesty)"
else
  bad "a recorded verdict (even BAD) should clear UNJUDGED" "$OUT"
fi

# ── Tests 35-37: the readiness-cap defect (issue #96 findings 1-2).
# Scar: the sig-differs branch capped (Test 20 proves it fires — the cap NUMBER it sets is proved
# below, on `gap`, because Test 20's `check` surface masks it), but the UNREADABLE and ABSENT only
# appended the cap STRING — never calling _min_readiness — so DELETING or CORRUPTING witness.json
# printed `GRAPH_STALE.P2` next to `GRAPH_CAP = SHIP`: destroying the tamper-evidence artifact
# REMOVED the ceiling it was supposed to enforce, on check, road and gap alike. And `cmd_check`
# returned `1 if hard else 0`, so a stale graph exited 0 — invisible to every && chain.
# The two absences are NOT the same fact and must not print the same code:
#   corrupt/differs = someone destroyed or hand-edited the evidence → cap + non-zero exit
#   absent          = this project has not been built yet (the whole v8→v9 installed base, which
#                     migrate.js marks with .v9-graph-needed) → honest signal, NO cap, exit 0
CAPP="$TMP/projects/012-cap"
mkdir -p "$CAPP/epics/001-e/stories/S001-a"
cat > "$CAPP/product-contract.md" <<'EOF'
# C
## 2. Primary Persona
**JTBD** (`JOB-1`): When X, I want Y, so that Z.
## 5. Magic Moments
### MM-1 — judged good
EOF
printf -- '---\nartifact_type: story-spec\nserves: [MM-1, JOB-1]\n---\n# A\n#### AC-1 — a\n' > "$CAPP/epics/001-e/stories/S001-a/spec.md"
cat > "$CAPP/epics/001-e/stories/S001-a/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
## Magic Moment Validation
- **VERDICT** MM-1 = GOOD
EOF
cat > "$CAPP/epics/001-e/traceability-matrix.md" <<'EOF'
# M
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | §5 MM-1 | wow | S001 / AC-1 | — | ux-rc | discharged |
EOF
python3 "$GRAPH" build "$CAPP" >/dev/null 2>&1
# sanity: this fixture is a clean SHIP graph, so any cap below is caused by the witness state alone
OUT="$(python3 "$GRAPH" check "$CAPP" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "GRAPH_CAP = SHIP"; then
  ok "fixture baseline: fresh witness → GRAPH_CAP = SHIP, exit 0"
else
  bad "cap fixture is not a clean SHIP baseline" "$OUT (rc=$RC)"
fi

# Where the cap NUMBER is observable — and why `check` alone cannot test this (scar-on-the-scar).
# `cmd_check` sets a separate `stale` flag and prints `GRAPH_CAP = STALE` INSTEAD of the number, so
# on that surface the cap value is masked either way: an assertion there passes whether or not the
# branch ever called `_min_readiness`. Deleting the `_min_readiness(cap_state, "integration-green")`
# from the corrupt branch left all 38 tests green — the fix for #96 was VACUOUSLY tested, which is
# the exact sin the graph exists to name. `gap` is the surface that survives: it prints the raw
# `CAP=<state>`, and that is the token quoted onward into project-state, pickups and /goal. Assert
# the number where the number lives.
echo "── Test 35: a CORRUPT witness.json caps (destroying the evidence must not remove the ceiling)"
echo 'not json {' > "$CAPP/graph/witness.json"
OUT="$(python3 "$GRAPH" check "$CAPP" 2>&1)" && RC=0 || RC=$?
GAPOUT="$(python3 "$GRAPH" gap "$CAPP" 2>&1 || true)"
if [[ $RC -ne 0 ]] && echo "$OUT" | grep -q "GRAPH_STALE.P2" && ! echo "$OUT" | grep -q "GRAPH_CAP = SHIP"; then
  ok "corrupt witness → GRAPH_STALE.P2, cap withheld, non-zero exit"
else
  bad "corrupting witness.json must not leave GRAPH_CAP = SHIP / exit 0" "$OUT (rc=$RC)"
fi
if echo "$GAPOUT" | grep -q "CAP=INTEGRATION-GREEN" && ! echo "$GAPOUT" | grep -q "CAP=SHIP"; then
  ok "corrupt witness → the cap NUMBER itself is lowered (gap: CAP=INTEGRATION-GREEN, never SHIP)"
else
  bad "corrupt witness must lower cap_state, not merely print a warning beside CAP=SHIP" "$GAPOUT"
fi
# road is the OTHER unmasked surface, and the one that gets written to disk (road-to-completion.md)
# and re-read weeks later long after the warning beside it has scrolled away — the literal
# brightstance scar. Same fact, checked where it outlives the session.
ROADOUT="$(python3 "$GRAPH" road "$CAPP" --stdout 2>&1 || true)"
if echo "$ROADOUT" | grep -qE '^\*\*GRAPH_CAP\*\* = `INTEGRATION-GREEN`'; then
  ok "corrupt witness → the written road quotes the lowered cap, not SHIP"
else
  bad "road must not hand a SHIP cap onward from a destroyed witness" "$ROADOUT"
fi

echo "── Test 36: an ABSENT witness.json is UNBUILT, not tampered — honest, distinct, NON-capping"
rm -f "$CAPP/graph/witness.json"
OUT="$(python3 "$GRAPH" check "$CAPP" 2>&1)" && RC=0 || RC=$?
GAPOUT="$(python3 "$GRAPH" gap "$CAPP" 2>&1 || true)"
if [[ $RC -eq 0 ]] && echo "$OUT" | grep -q "GRAPH_UNBUILT.P3" \
   && ! echo "$OUT" | grep -q "GRAPH_STALE" && echo "$OUT" | grep -q "GRAPH_CAP = SHIP"; then
  ok "never-built graph is signalled (GRAPH_UNBUILT.P3) without capping or bricking (exit 0)"
else
  bad "absent witness must not be conflated with tampering, and must not cap" "$OUT (rc=$RC)"
fi
# PIN the non-cap, on the surface where the number is observable. This is the asymmetry, deliberate:
# corrupt/differs lowers the number, ABSENT must not. migrate.js writes `.speck/.v9-graph-needed` to
# every v8→v9 upgrader, so the entire installed base has no committed witness on upgrade day —
# capping absent would drop all of them to INTEGRATION-GREEN on a patch bump, for code nobody
# touched. The engagement gate already blocks feature work there; a cap would be a second, silent
# punishment. Pinned so a future "make it symmetric" tidy-up cannot land unnoticed.
if [[ $RC -eq 0 ]] && echo "$GAPOUT" | grep -q "CAP=SHIP" \
   && ! echo "$GAPOUT" | grep -q "CAP=INTEGRATION-GREEN"; then
  ok "absent witness leaves the cap NUMBER untouched (gap: CAP=SHIP) — installed base not demoted"
else
  bad "an absent witness must NOT lower cap_state (the whole v8→v9 base would drop)" "$GAPOUT (rc=$RC)"
fi

echo "── Test 37: a witness that DIFFERS from a fresh compile exits non-zero, cap unknowable"
python3 "$GRAPH" build "$CAPP" >/dev/null 2>&1
python3 - "$CAPP/graph/witness.json" <<'PY'
import json, sys
p = sys.argv[1]; g = json.load(open(p))
for n in g["nodes"]:
    if n["kind"] == "story":
        n["title"] = n["title"] + " (hand-edited)"; break
json.dump(g, open(p, "w"), indent=2)
PY
OUT="$(python3 "$GRAPH" check "$CAPP" 2>&1)" && RC=0 || RC=$?
GAPOUT="$(python3 "$GRAPH" gap "$CAPP" 2>&1 || true)"
if [[ $RC -ne 0 ]] && echo "$OUT" | grep -q "GRAPH_CAP = STALE" && ! echo "$OUT" | grep -q "GRAPH_CAP = SHIP"; then
  ok "hand-edited witness → exit non-zero and no confident cap NUMBER to quote onward"
else
  bad "a stale graph must not exit 0 nor print a cap number" "$OUT (rc=$RC)"
fi
# Same masking problem as Test 35: `check` swaps the number for STALE, so only `gap` can witness
# that the sig-differs branch actually lowered cap_state rather than just appending a warning.
if echo "$GAPOUT" | grep -q "CAP=INTEGRATION-GREEN" && ! echo "$GAPOUT" | grep -q "CAP=SHIP"; then
  ok "hand-edited witness → the cap NUMBER itself is lowered (gap: CAP=INTEGRATION-GREEN)"
else
  bad "sig-differs must lower cap_state, not merely warn beside CAP=SHIP" "$GAPOUT"
fi

# ── Tests 38-49: no proof may be derived from unstructured prose (issue #97).
#
# The scar, in one sentence: `serves` was minted by `re.findall(r"(MM-\d+|JOB-\d+)", body)` over the
# WHOLE story spec, so a sentence written to say the OPPOSITE created the claim it denied. In one
# committed graph 10 of 15 distinct MM `serves` edges were false and 8 came from lines reading
# "None claimed" or "MM-1 and MM-2 are not claimed here." The same matcher was under-inclusive the
# other way: `MM-5a` could not be node-ified at all, so a real promise dropped out of the census with
# NO finding. Two opposite failure directions out of one matcher is the signature of an inference
# that should never have been textual.
#
# The two surfaces these tests read, and why:
#   `check` — the P1 COUNT (its header line is the honest total; a hidden finding shows up here).
#   `gap`   — the raw `CAP=` token. `check` swaps the number for STALE whenever a witness is stale,
#             so the number is only reliably observable on `gap` (the Test-35 scar-on-the-scar).
# Both fixtures below deliberately have NO committed witness.json: GRAPH_UNBUILT is the one absence
# that does not cap, so `CAP=` stays a real number instead of being masked to STALE.

# Parse helpers — no pipelines, so `set -o pipefail` can't turn a non-match into a killed run.
hard_count() { awk '/^❌ [0-9]+ hard finding/ {print $2; f=1; exit} END {if (!f) print 0}' <<<"$1"; }
cap_token()  { awk 'match($0, /CAP=[A-Z-]+/) {print substr($0, RSTART, RLENGTH); exit}' <<<"$1"; }

echo "── Test 38: PROPERTY — an explanatory sentence naming every MM/JOB changes NOTHING (headline)"
# The single highest-value assertion in this file. Appending prose to an UNRELATED story must leave
# the hard-finding count and GRAPH_CAP byte-identical. Today it does the opposite of nothing: the
# disclaimer makes MM-2 look delivered and the real PHANTOM_PROMISE.P1 block disappears.
PZ="$TMP/projects/013-prose"
mkdir -p "$PZ/epics/001-e/stories/S001-claims" "$PZ/epics/001-e/stories/S002-unrelated"
cat > "$PZ/product-contract.md" <<'EOF'
# Contract
## 2. Primary Persona
**JTBD** (`JOB-1`): When X, I want Y, so that Z.
## 5. Magic Moments
### MM-1 — claimed by S001
### MM-2 — nobody claims this (a real phantom)
EOF
cat > "$PZ/epics/001-e/stories/S001-claims/spec.md" <<'EOF'
---
artifact_type: story-spec
serves: [MM-1, JOB-1]
---
# Story: Claims
This story delivers MM-1 for JOB-1.
#### AC-1 — a
EOF
printf -- '---\nartifact_type: story-spec\n---\n# Story: Unrelated\n#### AC-1 — a\n' \
  > "$PZ/epics/001-e/stories/S002-unrelated/spec.md"
BEFORE_CHK="$(python3 "$GRAPH" check "$PZ" 2>&1 || true)"
BEFORE_GAP="$(python3 "$GRAPH" gap "$PZ" 2>&1 || true)"
B_HARD="$(hard_count "$BEFORE_CHK")"; B_CAP="$(cap_token "$BEFORE_GAP")"
cat >> "$PZ/epics/001-e/stories/S002-unrelated/spec.md" <<'EOF'

**Magic moments:** None claimed. MM-1 and MM-2 are not claimed here, and JOB-1 is served by S001.
EOF
AFTER_CHK="$(python3 "$GRAPH" check "$PZ" 2>&1 || true)"
AFTER_GAP="$(python3 "$GRAPH" gap "$PZ" 2>&1 || true)"
A_HARD="$(hard_count "$AFTER_CHK")"; A_CAP="$(cap_token "$AFTER_GAP")"
if [[ "$B_HARD" == "1" && "$B_CAP" == "CAP=NO-SHIP" ]]; then
  ok "property baseline is meaningful (1 hard PHANTOM_PROMISE.P1, CAP=NO-SHIP)"
else
  bad "property baseline is not the intended state" "hard=$B_HARD cap=$B_CAP -- $BEFORE_CHK"
fi
if [[ "$A_HARD" == "$B_HARD" && "$A_CAP" == "$B_CAP" ]]; then
  ok "prose naming every MM/JOB left hard-count ($B_HARD) and $B_CAP byte-identical"
else
  bad "an explanatory sentence changed the graph's verdict" \
      "hard ${B_HARD}→${A_HARD}, cap ${B_CAP}→${A_CAP} -- $AFTER_CHK"
fi

echo "── Test 39: PROPERTY, other direction — a cross-reference must not exit the amnesty for everyone"
# The interaction behind issue #97 finding 3b: with zero serves edges an undelivered promise is
# capped GRAPH_UNMIGRATED.P3 ("nothing wires to any … yet"). The FIRST prose mention anywhere used to
# exit that amnesty for EVERY promise at once — converting soft caps into hard P1 blocks — while
# immunising the one moment it happened to name. Naming a moment in a sentence is not migration.
AM="$TMP/projects/014-amnesty"
mkdir -p "$AM/epics/001-e/stories/S001-a"
cat > "$AM/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — lives in another epic
### MM-2 — not wired yet
### MM-3 — not wired yet
EOF
printf -- '---\nartifact_type: story-spec\n---\n# Story: A\n#### AC-1 — a\n' \
  > "$AM/epics/001-e/stories/S001-a/spec.md"
B_HARD="$(hard_count "$(python3 "$GRAPH" check "$AM" 2>&1 || true)")"
B_CAP="$(cap_token "$(python3 "$GRAPH" gap "$AM" 2>&1 || true)")"
printf '\nCross-reference: MM-1 is delivered in the platform epic, not here.\n' \
  >> "$AM/epics/001-e/stories/S001-a/spec.md"
AFTER_CHK="$(python3 "$GRAPH" check "$AM" 2>&1 || true)"
A_HARD="$(hard_count "$AFTER_CHK")"
A_CAP="$(cap_token "$(python3 "$GRAPH" gap "$AM" 2>&1 || true)")"
if [[ "$B_HARD" == "0" && "$A_HARD" == "0" && "$A_CAP" == "$B_CAP" ]]; then
  ok "a cross-reference left the un-migrated project capped (0 hard, $B_CAP), not blocked"
else
  bad "one prose mention converted every other promise's cap into a block" \
      "hard ${B_HARD}→${A_HARD}, cap ${B_CAP}→${A_CAP} -- $AFTER_CHK"
fi

echo "── Test 40: a backticked date placeholder (YYYY-MM-01) mints no edge and no DANGLING_REF.P1"
# `MM-01` was a hard P1 BLOCK minted from the substring of a date format inside a code span.
DT="$TMP/projects/015-dateformat"
mkdir -p "$DT/epics/001-e/stories/S001-a"
cat > "$DT/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — the one real moment
EOF
cat > "$DT/epics/001-e/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
serves: [MM-1]
---
# Story: A
A date-format placeholder in a table: `YYYY-MM-01`.
#### AC-1 — a
EOF
OUT="$(python3 "$GRAPH" check "$DT" 2>&1 || true)"
if ! grep -q "MM-01" <<<"$OUT"; then
  ok "a date format inside a code span is not a magic-moment reference"
else
  bad "date placeholder still mints an MM-01 reference" "$OUT"
fi

echo "── Test 41: a heterogeneous id (MM-5a) node-ifies — no silent census drop"
# Streb renamed a founder-facing promise (MM-5a → MM-10, 19 files, +77/−67) because the node parser
# pinned `MM-\d+`. AC ids five lines away already accepted `AC-1a`. The tool set the vocabulary.
HT="$TMP/projects/016-hetero"
mkdir -p "$HT/epics/001-e/stories/S001-a"
cat > "$HT/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — plain
### MM-5a — heterogeneous, historically numbered
EOF
cat > "$HT/epics/001-e/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
serves: [MM-1, MM-5a]
---
# Story: A
#### AC-1 — a
EOF
python3 "$GRAPH" build "$HT" --stdout > "$TMP/hetero.json" 2>/dev/null
if python3 - "$TMP/hetero.json" <<'PY'
import json, sys
g = json.load(open(sys.argv[1]))
assert g["counts"]["by_kind"].get("magic-moment") == 2, g["counts"]["by_kind"]
assert any(n["id"] == "MM-5a" for n in g["nodes"]), "MM-5a must be a node"
assert any(e["kind"] == "serves" and e["dst"] == "MM-5a" for e in g["edges"]), "MM-5a must be servable"
PY
then ok "MM-5a is a node and a resolvable serves target (census = 2, matches the contract)"
else bad "MM-5a dropped out of the census silently" "see assertion above"; fi
# The matrix Source cell must accept the same shape, or `MM-5a` matches the PREFIX `MM-5` and mints
# a DANGLING_REF.P1 at a node that never existed — the widening has to be consistent across the file.
cat > "$HT/epics/001-e/traceability-matrix.md" <<'EOF'
# M
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | product-contract §5 MM-5a | wow | S001 / AC-1 | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" lint-refs "$HT" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && ! grep -q "MM-5 " <<<"$OUT"; then
  ok "a Source cell naming MM-5a resolves whole — no MM-5 prefix ghost"
else
  bad "the matrix Source regex shredded MM-5a into MM-5" "$OUT (rc=$RC)"
fi
rm -f "$HT/epics/001-e/traceability-matrix.md"

echo "── Test 42: a §5 heading the schema still cannot node-ify is LOUD (HETEROGENEOUS_ID.P3)"
cat > "$HT/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — plain
### MM-5a — heterogeneous but accepted
### Magic Moment: the coach is already here
EOF
OUT="$(python3 "$GRAPH" check "$HT" 2>&1 || true)"
if grep -q "HETEROGENEOUS_ID.P3" <<<"$OUT" && grep -q "coach is already here" <<<"$OUT"; then
  ok "an un-node-ifiable §5 heading is reported, never silently dropped"
else
  bad "the census disagreed with the contract's own headings and said nothing" "$OUT"
fi

echo "── Test 43: a NEGATED sentence must not clear UNJUDGED_SURFACE (it flipped the cap to SHIP)"
# RE_MM_VERDICT matched an MM id within 80 chars of GOOD|PASS|judged|scored — including inside a
# negation. `MM-1 was NOT judged in this story — no LARP has run` minted a `judges` edge, cleared
# UNJUDGED_SURFACE and lifted GRAPH_CAP from INTEGRATION-GREEN to SHIP.
NV="$TMP/projects/017-negverdict"
mkdir -p "$NV/epics/001-e/stories/S001-a"
cat > "$NV/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — the moment
EOF
cat > "$NV/epics/001-e/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
serves: [MM-1]
---
# Story: A
#### AC-1 — a
EOF
cat > "$NV/epics/001-e/stories/S001-a/validation-report.md" <<'EOF'
---
readiness_state_verified: INTEGRATION-GREEN
---
## Magic Moment Validation
MM-1 was NOT judged in this story — no LARP has run.
EOF
OUT="$(python3 "$GRAPH" check "$NV" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$NV" 2>&1 || true)"
if grep -q "UNJUDGED_SURFACE" <<<"$OUT" && [[ "$(cap_token "$GAPOUT")" == "CAP=INTEGRATION-GREEN" ]]; then
  ok "a negated sentence leaves MM-1 unjudged and the cap at INTEGRATION-GREEN"
else
  bad "a sentence saying MM-1 was NOT judged cleared the unjudged gate" "$OUT / $GAPOUT"
fi
if grep -q "UNPARSED_VERDICT.P3" <<<"$OUT"; then
  ok "the verdict-shaped prose is surfaced as an UNPARSED_VERDICT.P3 hint, not read as proof"
else
  bad "verdict-shaped prose vanished instead of becoming a hint" "$OUT"
fi

echo "── Test 44: only an explicit machine-readable verdict line clears UNJUDGED (positive control)"
cat > "$NV/epics/001-e/stories/S001-a/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
---
## Magic Moment Validation
- **VERDICT** MM-1 = GOOD — pixel-anchored, connoisseur Job B
EOF
OUT="$(python3 "$GRAPH" check "$NV" 2>&1 || true)"
if ! grep -q "UNJUDGED_SURFACE" <<<"$OUT" && ! grep -q "UNPARSED_VERDICT" <<<"$OUT"; then
  ok "an explicit VERDICT line records the judgement (and needs no hint)"
else
  bad "the structured verdict line did not register" "$OUT"
fi

echo "── Test 44b: mm_verdicts: frontmatter also clears UNJUDGED — the tool's OWN remediation path"
# UNPARSED_VERDICT.P3 tells authors to use a VERDICT line "or mm_verdicts: in the report
# frontmatter" — that second half of its own advice had zero coverage until now.
cat > "$NV/epics/001-e/stories/S001-a/validation-report.md" <<'EOF'
---
readiness_state_verified: UX-RC
mm_verdicts: MM-1=GOOD
---
## Magic Moment Validation
Recorded structurally via frontmatter, not a VERDICT line.
EOF
OUT="$(python3 "$GRAPH" check "$NV" 2>&1 || true)"
if ! grep -q "UNJUDGED_SURFACE" <<<"$OUT" && ! grep -q "UNPARSED_VERDICT" <<<"$OUT"; then
  ok "mm_verdicts: frontmatter records the judgement (and needs no hint)"
else
  bad "the frontmatter verdict path (mm_verdicts:) did not register" "$OUT"
fi

echo "── Test 45: a bare prose mention is UNCLAIMED_MM_REF.P3 with path:line — a hint, never a block"
OUT="$(python3 "$GRAPH" check "$PZ" 2>&1 || true)"
if grep -q "UNCLAIMED_MM_REF.P3" <<<"$OUT" \
   && grep -q "S002-unrelated/spec.md:" <<<"$OUT" \
   && [[ "$(hard_count "$OUT")" == "1" ]]; then
  ok "prose drift is VISIBLE (path:line) instead of AUTHORITATIVE, and adds no block"
else
  bad "unclaimed prose mentions must surface as a located P3 hint" "$OUT"
fi

echo "── Test 46: a Status word without an edge behind it is STATUS_WITHOUT_EDGE.P2, not resolution"
SW="$TMP/projects/018-statusword"
mkdir -p "$SW/epics/001-e/stories/S001-a"
printf 'x' > "$SW/epics/001-e/epic-breakdown.md"
printf -- '---\nartifact_type: story-spec\n---\n# A\n#### AC-1 — a\n' > "$SW/epics/001-e/stories/S001-a/spec.md"
cat > "$SW/epics/001-e/traceability-matrix.md" <<'EOF'
# M
## 2. Traceability Matrix
| PRM-ID | Source | Promise | Discharge (story-id + AC-ref) | DEC | Grain | Status |
|--------|--------|---------|-------------------------------|-----|-------|--------|
| PRM-001 | x | really discharged | S001 / AC-1 | — | ux-rc | discharged |
| PRM-002 | x | the word only | — | — | ux-rc | discharged |
EOF
OUT="$(python3 "$GRAPH" check "$SW" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$SW" 2>&1 || true)"
if grep -q "STATUS_WITHOUT_EDGE.P2" <<<"$OUT" && grep -q "PRM-002" <<<"$OUT" \
   && ! grep -q "PRM-001" <<<"$OUT" && [[ "$(cap_token "$GAPOUT")" == "CAP=INTEGRATION-GREEN" ]]; then
  ok "a self-authored 'discharged' with no discharge edge caps instead of resolving silently"
else
  bad "the status WORD still bought resolution with no edge behind it" "$OUT / $GAPOUT"
fi

echo "── Test 47: the §1d checklist line is the migration-era claim slot — and the template emits it"
# The fallback is only reachable if the SHIPPED template puts an id on that line. It used to emit a
# bare NAME placeholder, so the fallback matched nothing on a template-conformant story.
if grep -q 'Magic Moment: MM-N — ' "$ROOT/.speck/templates/story/story-template.md"; then
  ok 'story-template §1d emits "MM-N — [Name]" (the fallback has something to match)'
else
  bad "story-template §1d still emits a bare NAME placeholder" "the checklist fallback is dead on arrival"
fi
CL="$TMP/projects/019-checklist"
mkdir -p "$CL/epics/001-e/stories/S001-a" "$CL/epics/001-e/stories/S002-b"
cat > "$CL/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — claimed on the checklist line
### MM-2 — disclaimed in a checklist line, so NOT claimed
EOF
cat > "$CL/epics/001-e/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: A
### 1d. Magic Moments Tied to This Story
- [x] Magic Moment: MM-1 — First wow
  - Surface: the home screen
#### AC-1 — a
EOF
cat > "$CL/epics/001-e/stories/S002-b/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: B
### 1d. Magic Moments Tied to This Story
- [ ] Magic Moment: None claimed. MM-1 and MM-2 are delivered and judged in S001.
#### AC-1 — a
EOF
OUT="$(python3 "$GRAPH" check "$CL" 2>&1 || true)"
if grep -q "PHANTOM_PROMISE.P1" <<<"$OUT" && grep -q "MM-2" <<<"$OUT" \
   && [[ "$(hard_count "$OUT")" == "1" ]]; then
  ok "the checklist line claims MM-1; a 'None claimed' checklist line claims nothing"
else
  bad "the §1d fallback read a disclaimer as a claim (or missed the real one)" "$OUT"
fi

echo "── Test 48: migrate --lift-serves is DRY-RUN by default and shows what it would assert for you"
LS="$TMP/projects/020-lift"
mkdir -p "$LS/epics/001-e/stories/S004-real" "$LS/epics/001-e/stories/S008-disclaimer"
cat > "$LS/product-contract.md" <<'EOF'
# Contract
## 5. Magic Moments
### MM-1 — one
### MM-2 — two
EOF
cat > "$LS/epics/001-e/stories/S004-real/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: Real
- [x] Magic Moment: MM-2 — the wow
#### AC-1 — a
EOF
cat > "$LS/epics/001-e/stories/S008-disclaimer/spec.md" <<'EOF'
---
artifact_type: story-spec
---
# Story: Disclaimer
**None.** MM-1 and MM-2 change character in this epic, but they are delivered by S004.
#### AC-1 — a
EOF
S008_BEFORE="$(shasum "$LS/epics/001-e/stories/S008-disclaimer/spec.md" | awk '{print $1}')"
OUT="$(python3 "$GRAPH" migrate "$LS" --lift-serves 2>&1 || true)"
S008_AFTER="$(shasum "$LS/epics/001-e/stories/S008-disclaimer/spec.md" | awk '{print $1}')"
if grep -q "DRY-RUN" <<<"$OUT" && grep -q "S004-real/spec.md" <<<"$OUT" \
   && grep -qE ":[0-9]+" <<<"$OUT" && grep -q "MM-2" <<<"$OUT" \
   && grep -q "they are delivered by S004" <<<"$OUT" \
   && [[ "$S008_BEFORE" == "$S008_AFTER" ]]; then
  ok "dry-run prints each prose-derived edge with its source line and writes nothing"
else
  bad "lift-serves must be dry-run by default and quote the line it would assert from" "$OUT"
fi

echo "── Test 49: migrate --lift-serves --write lifts real claims into frontmatter, skips disclaimers"
OUT="$(python3 "$GRAPH" migrate "$LS" --lift-serves --write 2>&1 || true)"
S004_FM="$(sed -n '1,6p' "$LS/epics/001-e/stories/S004-real/spec.md")"
S008_FM="$(sed -n '1,6p' "$LS/epics/001-e/stories/S008-disclaimer/spec.md")"
if grep -q "serves: \[MM-2\]" <<<"$S004_FM" && ! grep -q "serves:" <<<"$S008_FM"; then
  ok "the §1d claim was lifted; the 'None.' disclaimer was left for a human"
else
  bad "lift wrote the wrong claims" "S004: $S004_FM / S008: $S008_FM"
fi
# idempotent: a second --write must not duplicate or re-lift
python3 "$GRAPH" migrate "$LS" --lift-serves --write >/dev/null 2>&1 || true
if [[ "$(grep -c "serves:" "$LS/epics/001-e/stories/S004-real/spec.md")" == "1" ]]; then
  ok "lift is idempotent (a second --write adds nothing)"
else
  bad "lift duplicated the frontmatter key" "$(sed -n '1,8p' "$LS/epics/001-e/stories/S004-real/spec.md")"
fi

# ── Tests 50-51: the freshness LEG reaches the lifecycle hooks (issue #96 finding 3).
#
# `check` computed freshness correctly for a whole major version and `gate` — the primitive the
# hooks actually call — never ran it, so NO lifecycle hook could observe a stale graph. Three repos
# were 142 / 169 / 256 commits behind at the time it was filed. The fix is the leg, not a rebuild:
# `gate` must stay a pure read or the first pre-implement check becomes a mutating step and breaks
# read-only checkouts and every tree-clean assertion.

FRESH="$TMP/projects/002-fresh"
mkdir -p "$FRESH/epics/001-f/stories/S001-a"
cat > "$FRESH/product-contract.md" <<'EOF'
# Product Contract: Fresh
## 5. Magic Moments
### MM-1 — Only wow
EOF
cat > "$FRESH/epics/001-f/stories/S001-a/spec.md" <<'EOF'
---
artifact_type: story-spec
serves: [MM-1]
---
# Story: A
#### AC-1 — Primary
EOF

echo "── Test 50: gate on a FRESH graph prints GRAPH_FRESH — a green gate is legible as 'the leg ran'"
python3 "$GRAPH" build "$FRESH" >/dev/null 2>&1
OUT="$(python3 "$GRAPH" gate "$FRESH" --story "001-f/S001" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && grep -q "GRAPH_FRESH" <<<"$OUT"; then
  ok "gate publishes the freshness result on the clear path (a silent pass and an unrun leg differ)"
else
  bad "gate must report that the freshness leg ran, not merely stay quiet" "$OUT (rc=$RC)"
fi

echo "── Test 51: gate SEES a stale witness, reports it, does NOT block, and writes NOTHING"
# Content change that keeps the id-set and the edge count — the predicate is a content signature,
# never `stamped SHA == HEAD`: a witness 5 commits behind HEAD that compiles byte-identical is
# FRESH, and a SHA rule would fire on every non-spec commit and teach `--no-verify` in a day.
python3 - "$FRESH/graph/witness.json" <<'PY'
import json, sys
p = sys.argv[1]; g = json.load(open(p))
for n in g["nodes"]:
    if n["kind"] == "story":
        n["title"] = n["title"] + " (hand-edited)"; break
json.dump(g, open(p, "w"), indent=2)
PY
snap_tree() { (cd "$1" && find . -type f -exec shasum {} \; | sort | shasum | awk '{print $1}'); }
BEFORE="$(snap_tree "$FRESH")"
OUT="$(python3 "$GRAPH" gate "$FRESH" --story "001-f/S001" 2>&1)" && RC=0 || RC=$?
AFTER="$(snap_tree "$FRESH")"
if grep -q "GRAPH_STALE" <<<"$OUT"; then
  ok "the lifecycle-hook primitive can finally SEE staleness (GRAPH_STALE in gate output)"
else
  bad "gate ran no freshness leg — a stale graph is invisible to every hook" "$OUT"
fi
if [[ $RC -eq 0 ]]; then
  ok "…and it GUIDES, never walls (exit 0 — a blocking freshness gate teaches --no-verify)"
else
  bad "gate must not block on staleness" "$OUT (rc=$RC)"
fi
if [[ "$BEFORE" == "$AFTER" ]]; then
  ok "…and it is a pure READ: the tree is byte-identical after the gate (read-only CI survives)"
else
  bad "gate mutated the tree — this is exactly why the leg was deferred in v10" "$BEFORE != $AFTER"
fi
# The stale note must name the ONE command that fixes it, or it is a nag rather than a guide-rail.
if grep -q "speck_graph.py build" <<<"$OUT"; then
  ok "…and the note names the fixing command"
else
  bad "a guide-rail that doesn't name the fix is a nag" "$OUT"
fi

echo "── Test 51b: \`build\` re-renders the road in the SAME call — the documented flow is sufficient"
# The witness and the road may not be separately committable. Pinned two ways: the road exists
# after a bare `build`, and it does NOT quote a GRAPH_STALE line describing the file `build` just
# wrote (the ordering bug this would otherwise ship with).
ROADF="$FRESH/graph/road-to-completion.md"
rm -f "$ROADF"
python3 "$GRAPH" build "$FRESH" >/dev/null 2>&1
if [[ -f "$ROADF" ]]; then
  ok "build wrote the road too — an agent following \`build && check\` no longer leaves it stale"
else
  bad "build refreshed witness.json and left the road behind (issue #96 finding 2)" "no $ROADF"
fi
# Match a routed TABLE ROW, never a bare word: the road's own banner says "The GRAPH_STALE law
# applies to this file", so a grep for the token is satisfied by the artifact's own explanatory
# boilerplate on every road ever rendered — a vacuous green. Only a `|`-row names a finding.
if grep -qE '^\|.*`GRAPH_STALE' "$ROADF"; then
  bad "the road quotes staleness about the witness the same call just wrote — ordering is wrong" \
      "$(grep -nE '^\|.*GRAPH_STALE' "$ROADF")"
else
  ok "…and it is rendered AFTER the witness is written, so it does not slander its own input"
fi

# ── Tests 52-56: reachability witness — the decidable slice #86 set aside (issue #96 finding 4).
#
# Conservation asks whether a promise has an OWNER; it never asks whether a user gesture REACHES
# it. The scar: an epic all-`mapped`, Blocking = 0, GRAPH_CAP = SHIP — whose central promise had
# never once fired for a real user, and whose gate output did not change when it went from
# non-functional to functional.

WIT="$TMP/projects/003-wit"
mkdir -p "$WIT/epics/001-w/stories/S001-a" "$WIT/epics/001-w/stories/S002-b" "$WIT/epics/001-w/stories/S003-c"
cat > "$WIT/product-contract.md" <<'EOF'
# Product Contract: Wit
## 5. Magic Moments
### MM-1 — The thread offer
### MM-2 — The reframe
### MM-3 — No badges, rings or confetti
EOF
wit_story() {   # <dir> <MM> [extra frontmatter lines]
  local d="$1" mm="$2"; shift 2
  { echo "---"
    echo "artifact_type: story-spec"
    echo "serves: [$mm]"
    for line in "$@"; do echo "$line"; done
    echo "---"
    echo "# Story: ${d##*/}"
    echo "#### AC-1 — Primary"
  } > "$WIT/epics/001-w/stories/$d/spec.md"
  # a recorded verdict, so UNJUDGED_SURFACE doesn't mask the cap this section is measuring
  { echo "# Validation Report"
    echo "- **VERDICT** $mm = GOOD — connoisseur Job B"
  } > "$WIT/epics/001-w/stories/$d/validation-report.md"
}
wit_story S001-a MM-1
wit_story S002-b MM-2
wit_story S003-c MM-3

echo "── Test 52: adoption gradient — a project with NO entry_point anywhere is guided, never capped"
OUT="$(python3 "$GRAPH" check "$WIT" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$WIT" 2>&1 || true)"
if grep -q "reachability is NOT evaluated" <<<"$OUT" && grep -q "GRAPH_UNMIGRATED.P3" <<<"$OUT"; then
  ok "un-adopted project gets an honest P3 that names the fixing edit (never a false 'reachable')"
else
  bad "an un-adopted project must be told reachability was not evaluated" "$OUT"
fi
if [[ "$(cap_token "$GAPOUT")" == "CAP=SHIP" ]]; then
  ok "…and the cap NUMBER is untouched — no existing matrix becomes non-conformant on upgrade"
else
  bad "the adoption gradient must not cap the installed base" "$GAPOUT"
fi

echo "── Test 53: once adopted, a promise with an entry point but NO mutation witness caps"
wit_story S001-a MM-1 "entry_point: lib/threadWrite.ts:createThread" "wiring_witness: lib/threadWrite.ts:41"
{ echo "# Validation Report"
  echo "- **VERDICT** MM-1 = GOOD — connoisseur Job B"
  echo ""
  echo "## 🧬 Mutation Record"
  echo "| guard test | mutation site | verdict |"
  echo "|---|---|---|"
  echo "| threadWrite.test.ts::creates a row | lib/threadWrite.ts:41 | GUARD_MUTATION_PROVEN |"
} > "$WIT/epics/001-w/stories/S001-a/validation-report.md"
wit_story S002-b MM-2 "entry_point: app/reframe.tsx:submitReframe"
wit_story S003-c MM-3 "entry_point: n/a — absence promise (no badge, ring, streak or confetti)"
OUT="$(python3 "$GRAPH" check "$WIT" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$WIT" 2>&1 || true)"
if grep -q "MAPPED_UNWITNESSED.P2: 1/3" <<<"$OUT" && grep -q "MM-2" <<<"$OUT"; then
  ok "exactly the promise with no delete-the-call witness is unwitnessed (1 of 3)"
else
  bad "the witness leg convicted the wrong set" "$OUT"
fi
if grep -q "MM-3" <<<"$OUT"; then
  bad "the bounded escape must be accepted — a third of a real matrix is not a call" "$OUT"
else
  ok "…and \`entry_point: n/a — <kind>\` is accepted (schema/RLS/copy/absence promises)"
fi
if [[ "$(cap_token "$GAPOUT")" == "CAP=INTEGRATION-GREEN" ]]; then
  ok "…and it CAPS rather than blocks (mapped-unwitnessed is a ceiling, same polarity as GRAPH_CAP)"
else
  bad "MAPPED_UNWITNESSED must lower the cap number, not merely print beside it" "$GAPOUT"
fi
if [[ "$(hard_count "$OUT")" == "0" ]]; then
  ok "…and mints no hard .P1 — it never blocks implementation"
else
  bad "the witness leg must not become a wall" "$OUT"
fi

echo "── Test 54: THE control point — the join to the story's validation report, not the cell alone"
# A cell in a matrix is one author's sentence. The load-bearing half is that the SAME site appears
# in the delivering story's own report — the citation shape mutate-guard --verify-receipt recomputes
# against the receipts on disk. Delete only the mutation row and MM-1 must flip to unwitnessed.
{ echo "# Validation Report"
  echo "- **VERDICT** MM-1 = GOOD — connoisseur Job B"
} > "$WIT/epics/001-w/stories/S001-a/validation-report.md"
OUT="$(python3 "$GRAPH" check "$WIT" 2>&1 || true)"
if grep -q "MAPPED_UNWITNESSED.P2: 2/3" <<<"$OUT" && grep -q "records no such site" <<<"$OUT"; then
  ok "a wiring_witness the delivering report does not record is not a witness (2/3 now)"
else
  bad "the report join is not the control point — the cell alone satisfied the gate" "$OUT"
fi

echo "── Test 55: a bare \`n/a\` does not discharge — the KIND is the part a reader can disagree with"
wit_story S003-c MM-3 "entry_point: n/a"
OUT="$(python3 "$GRAPH" check "$WIT" 2>&1 || true)"
if grep -q "MM-3" <<<"$OUT" && grep -q "name the kind" <<<"$OUT"; then
  ok "bare n/a is rejected with the instructive message (an unnamed escape is a blank cheque)"
else
  bad "bare n/a must not discharge a promise" "$OUT"
fi
wit_story S003-c MM-3 "entry_point: n/a — absence promise (no badge, ring, streak or confetti)"

# ── Tests 56-59: ONE findings namespace, and the registry has inverted polarity (issue #100 §5).
#
# The open question was which artifact owns the ranking. This module mints every gate code, so a
# second hand-kept project-level list would be a second namespace — measured cost of the hand-kept
# version: 14 of 20 entries stale, the advertised top severity closed eleven fires earlier, and one
# defect carrying three ids across two reports. Resolution: the graph's namespace is authoritative,
# the project view is DERIVED, and the only authored artifact enumerates EXCEPTIONS.

echo "── Test 56: the findings view is DERIVED and ranked by computed severity, not by typing"
OUT="$(python3 "$GRAPH" findings "$WIT" --stdout 2>&1 || true)"
if grep -q "NEVER hand-edit" <<<"$OUT" && grep -q "AUTHORITATIVE" <<<"$OUT" \
   && grep -q "Highest open severity" <<<"$OUT"; then
  ok "the view declares its own derivation and computes the top open severity"
else
  bad "the derived findings view must state the namespace and compute the ranking" "$OUT"
fi
# The ranking is the product: P1 rows must precede P2, which must precede P3. Read the order off
# the rendered table rather than trusting the sort call.
RANKS="$(awk -F'|' '/^\| [0-9]+ \|/ { gsub(/ /, "", $4); print $4 }' <<<"$OUT")"
SORTED="$(printf '%s\n' "$RANKS" | sort)"
if [[ "$RANKS" == "$SORTED" ]]; then
  ok "…and rows are emitted in severity order (P1 → P2 → P3)"
else
  bad "the derived view is not severity-ranked" "$RANKS"
fi

echo "── Test 57: an exception whose finding no longer fires is a PHANTOM and fails LOUDLY"
cat > "$WIT/findings-exceptions.md" <<'EOF'
# Findings — exceptions
| Finding | Posture | Why |
|---------|---------|-----|
| DEP_CYCLE | ACCEPTED | Nothing in this project has a depends_on cycle; this row exists to prove the ratchet fires. |
EOF
OUT="$(python3 "$GRAPH" check "$WIT" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$WIT" 2>&1 || true)"
if grep -q "EXCEPTION_PHANTOM.P2" <<<"$OUT" && grep -q "NO LONGER FIRES" <<<"$OUT"; then
  ok "a stale exception is caught — a list of exceptions fails loudly where a list of instances rots"
else
  bad "the registry must delete its own phantoms, or it becomes standing permission slips" "$OUT"
fi
if [[ "$(cap_token "$GAPOUT")" == "CAP=INTEGRATION-GREEN" ]]; then
  ok "…and it caps (the ratchet fires in BOTH directions, which is the direction that matters)"
else
  bad "a phantom exception must move the number, not merely print" "$GAPOUT"
fi

echo "── Test 58: there is nowhere to write 'looks fine', and only two postures exist"
cat > "$WIT/findings-exceptions.md" <<'EOF'
# Findings — exceptions
| Finding | Posture | Why |
|---------|---------|-----|
| MAPPED_UNWITNESSED | ACCEPTED | looks fine |
| UNJUDGED_SURFACE | maybe later | This reason is comfortably longer than the forty character floor requires. |
EOF
OUT="$(python3 "$GRAPH" check "$WIT" 2>&1 || true)"
if grep -q "says nothing an outsider can check" <<<"$OUT"; then
  ok "belief words and thin entries are rejected by name"
else
  bad "'looks fine' is the phrase that turned the hand-kept registries into decoration" "$OUT"
fi
if grep -q "there are exactly two an entry can take" <<<"$OUT"; then
  ok "…and a posture outside ACCEPTED|SUPERSEDED is rejected (SUPERSEDED is not 'fixed')"
else
  bad "an entry must declare which of the two it is" "$OUT"
fi

echo "── Test 59: acceptance moves a finding in the WORK ORDER, never in the ceiling"
cat > "$WIT/findings-exceptions.md" <<'EOF'
# Findings — exceptions
| Finding | Posture | Why |
|---------|---------|-----|
| MAPPED_UNWITNESSED | ACCEPTED | MM-2's reframe path ships behind a kill switch that is off in production, so no gesture reaches it this quarter. |
EOF
OUT="$(python3 "$GRAPH" findings "$WIT" --stdout 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$WIT" 2>&1 || true)"
ACCEPTED_ROW="$(grep "MAPPED_UNWITNESSED" <<<"$OUT" || true)"
if grep -q "ACCEPTED" <<<"$ACCEPTED_ROW"; then
  ok "the accepted finding is marked in the derived view (convergence stays visible, not deleted)"
else
  bad "a legitimate exception must annotate its finding" "$ACCEPTED_ROW"
fi
if [[ "$(cap_token "$GAPOUT")" == "CAP=INTEGRATION-GREEN" ]]; then
  ok "…and GRAPH_CAP is UNCHANGED — an authored file may never grant readiness (§6.4 caps, never raises)"
else
  bad "an exception lifted the ceiling — that is the one thing it may never do" "$GAPOUT"
fi
rm -f "$WIT/findings-exceptions.md"

# ── Tests 60-62: the incremental-adoption path, and read-only survival of the derived surfaces.
#
# Both are v10.1 audit findings against the two surfaces added above.
#   60/61 — MAPPED_UNWITNESSED was adoption-gated by ONE project-wide flag, so the first `Entry
#           Point` cell a team filled anywhere flipped the gate on for every delivered promise at
#           once and dropped a SHIP-RC project to INTEGRATION-GREEN. A gate whose entire cost lands
#           on the first honest step is a gate people route around.
#   62    — `findings` (and `road`) died with a raw PermissionError traceback on a read-only tree,
#           where `gate` and `check` both behave. Not a hook path and `--stdout` exists, so this is
#           degradation — and degradation gets a MESSAGE, the way graph_freshness degrades an
#           unreadable witness to "corrupt" instead of raising.

INC="$TMP/projects/004-inc"
mkdir -p "$INC/epics/001-alpha/stories/S001-a" "$INC/epics/002-beta/stories/S001-b"
cat > "$INC/product-contract.md" <<'EOF'
# Product Contract: Incremental
## 5. Magic Moments
### MM-1 — Alpha's promise
### MM-2 — Beta's promise
EOF
inc_story() {  # <epic-dir> <story-dir> <MM> [extra frontmatter lines]
  local e="$1" d="$2" mm="$3"; shift 3
  { echo "---"
    echo "artifact_type: story-spec"
    echo "serves: [$mm]"
    for line in "$@"; do echo "$line"; done
    echo "---"
    echo "# Story: $d"
    echo "#### AC-1 — Primary"
  } > "$INC/epics/$e/stories/$d/spec.md"
  { echo "# Validation Report"
    echo "- **VERDICT** $mm = GOOD — connoisseur Job B"
  } > "$INC/epics/$e/stories/$d/validation-report.md"
}
inc_story 001-alpha S001-a MM-1
inc_story 002-beta  S001-b MM-2

echo "── Test 60: baseline — a two-epic project that has adopted NOTHING is guided, never capped"
OUT="$(python3 "$GRAPH" check "$INC" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$INC" 2>&1 || true)"
if grep -q "reachability is NOT evaluated for 2 delivered promise(s)" <<<"$OUT" \
   && grep -q "MM-1" <<<"$OUT" && grep -q "MM-2" <<<"$OUT"; then
  ok "both promises sit on the non-capping line, named individually"
else
  bad "an un-adopted two-epic project must name both un-evaluated promises" "$OUT"
fi
if [[ "$(cap_token "$GAPOUT")" == "CAP=SHIP" ]] && ! grep -q "MAPPED_UNWITNESSED" <<<"$OUT"; then
  ok "…and the ceiling is untouched (CAP=SHIP, no MAPPED_UNWITNESSED)"
else
  bad "nothing is adopted, so nothing may cap" "$GAPOUT / $OUT"
fi

echo "── Test 61: THE incremental path — adopting ONE row in epic alpha must not cap epic beta"
# The defect, stated as a fixture: alpha fills its Entry Point cell HONESTLY and COMPLETELY (entry
# point + wiring witness + the site recorded in its own validation report, i.e. alpha is fully
# witnessed and owes nothing). Beta has not started. Under project-wide adoption this run printed
# `MAPPED_UNWITNESSED.P2: 1/2` and CAP=INTEGRATION-GREEN — the first honest step demoting a project
# for an epic nobody had touched. Under per-epic adoption alpha is judged (and passes), beta stays
# on the P3 line, and the ceiling does not move.
inc_story 001-alpha S001-a MM-1 \
  "entry_point: lib/alpha.ts:createAlpha" "wiring_witness: lib/alpha.ts:41"
{ echo "# Validation Report"
  echo "- **VERDICT** MM-1 = GOOD — connoisseur Job B"
  echo ""
  echo "## 🧬 Mutation Record"
  echo "| guard test | mutation site | verdict |"
  echo "|---|---|---|"
  echo "| alpha.test.ts::creates a row | lib/alpha.ts:41 | GUARD_MUTATION_PROVEN |"
} > "$INC/epics/001-alpha/stories/S001-a/validation-report.md"
OUT="$(python3 "$GRAPH" check "$INC" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$INC" 2>&1 || true)"
if ! grep -q "MAPPED_UNWITNESSED" <<<"$OUT"; then
  ok "adopting one epic's row raises NO cap on the un-adopted sibling (the cliff is gone)"
else
  bad "the first honest step still caps a sibling epic — a gate people route around" \
      "$(grep 'MAPPED_UNWITNESSED' <<<"$OUT")"
fi
if [[ "$(cap_token "$GAPOUT")" == "CAP=SHIP" ]]; then
  ok "…and the cap NUMBER is unchanged (CAP=SHIP) — a SHIP-RC project may start adopting for free"
else
  bad "adoption cost must not land on the first honest step" "$GAPOUT"
fi
# The P3 must now name ONLY beta's promise — otherwise the gate is silently untargeted and the
# un-evaluated set is not really per-epic, it is just off.
P3LINE="$(grep "reachability is NOT evaluated" <<<"$OUT" || true)"
if grep -q "MM-2" <<<"$P3LINE" && ! grep -q "MM-1" <<<"$P3LINE"; then
  ok "…and the un-evaluated line names beta's promise ONLY (alpha was judged, and passed)"
else
  bad "adoption scoping is not per-epic — the un-evaluated set did not shrink to beta" "$P3LINE"
fi
# THE CONTROL POINT for "alpha is really judged, not merely skipped". Break alpha's witness only:
# same fixture, one artifact edited. If per-epic adoption had degraded into "never evaluate", this
# stays green and the whole leg is decoration.
cp "$INC/epics/001-alpha/stories/S001-a/validation-report.md" "$TMP/alpha-report.bak"
{ echo "# Validation Report"
  echo "- **VERDICT** MM-1 = GOOD — connoisseur Job B"
} > "$INC/epics/001-alpha/stories/S001-a/validation-report.md"
OUT="$(python3 "$GRAPH" check "$INC" 2>&1 || true)"
GAPOUT="$(python3 "$GRAPH" gap "$INC" 2>&1 || true)"
if grep -q "MAPPED_UNWITNESSED.P2: 1/1" <<<"$OUT" && grep -q "MM-1" <<<"$OUT" \
   && [[ "$(cap_token "$GAPOUT")" == "CAP=INTEGRATION-GREEN" ]]; then
  ok "the ADOPTED epic is genuinely judged — alpha's broken witness caps, denominator 1 (not 2)"
else
  bad "per-epic adoption degraded into 'never evaluated' — the leg proves nothing" "$OUT / $GAPOUT"
fi
if grep -q "reachability is NOT evaluated for 1 delivered promise" <<<"$OUT"; then
  ok "…and beta stays on the non-capping line in the SAME run (both signals coexist)"
else
  bad "the incremental path must show both signals at once, or it reads as a cliff" "$OUT"
fi
cp "$TMP/alpha-report.bak" "$INC/epics/001-alpha/stories/S001-a/validation-report.md"

echo "── Test 62: the derived surfaces survive a READ-ONLY checkout — a stack trace is not a message"
RO="$TMP/projects/005-readonly"
mkdir -p "$RO/epics/001-r/stories/S001-a"
cat > "$RO/product-contract.md" <<'EOF'
# Product Contract: ReadOnly
## 5. Magic Moments
### MM-1 — Only wow
EOF
printf -- '---\nartifact_type: story-spec\nserves: [MM-1]\n---\n# A\n#### AC-1 — a\n' \
  > "$RO/epics/001-r/stories/S001-a/spec.md"
python3 "$GRAPH" build "$RO" >/dev/null 2>&1
# The happy path FIRST, while the tree is still writable — otherwise the only coverage
# `_write_derived` has is its failure branch, and "always returns the error" would read as green.
rm -f "$RO/graph/findings.md"
WOUT="$(python3 "$GRAPH" findings "$RO" 2>&1)" && WRC=0 || WRC=$?
if [[ $WRC -eq 0 ]] && [[ -s "$RO/graph/findings.md" ]] && grep -q "AUTHORITATIVE" "$RO/graph/findings.md"; then
  ok "findings still WRITES the derived view on a normal tree (exit 0, file has the real content)"
else
  bad "the degradation wrapper broke the ordinary write path" "$WOUT (rc=$WRC)"
fi
chmod -R a-w "$RO"
# Restore write permission no matter how this section exits, so the EXIT trap can clean up.
restore_ro() { chmod -R u+w "$RO" 2>/dev/null || true; }
trap 'restore_ro; rm -rf "$TMP"' EXIT

# gate and check are the surfaces that already behaved; they are the comparison, so a green here is
# not "read-only happens to work" but "findings now matches its neighbours".
GOUT="$(python3 "$GRAPH" gate "$RO" --story "001-r/S001" 2>&1)" && GRC=0 || GRC=$?
if [[ $GRC -eq 0 ]] && grep -q "GRAPH_FRESH" <<<"$GOUT"; then
  ok "gate's freshness leg still runs and WRITES NOTHING on a genuinely unwritable tree (exit 0)"
else
  bad "the freshness leg must stay a pure read — a read-only checkout may not brick the hooks" \
      "$GOUT (rc=$GRC)"
fi

FOUT="$(python3 "$GRAPH" findings "$RO" 2>&1)" && FRC=0 || FRC=$?
if grep -q "Traceback" <<<"$FOUT"; then
  bad "findings still dies with a raw Python stack trace on a read-only tree" "$FOUT"
else
  ok "findings no longer raises — the unwritable tree is handled, not propagated"
fi
# A named error that points at the escape hatch. Assert the CODE and the flag, not a vendor string:
# `exc.strerror` is libc's wording and differs across platforms, so pinning "Permission denied"
# would be the same vendor-message trap that has already shipped twice in this repo.
# The flag must be named ON THE GRAPH_UNWRITABLE LINE ITSELF, not merely somewhere in the output:
# `--stdout` also appears in the USAGE block, which any error path could print, so a whole-output
# grep for it would be satisfied by boilerplate.
UNWRITABLE_LINE="$(grep "GRAPH_UNWRITABLE" <<<"$FOUT" || true)"
if [[ -n "$UNWRITABLE_LINE" ]] && grep -q -- "--stdout" <<<"$UNWRITABLE_LINE" && [[ $FRC -ne 0 ]]; then
  ok "…it degrades to a NAMED error that names the working alternative (--stdout), exit non-zero"
else
  bad "degradation must name itself and the fix, not merely avoid crashing" "$FOUT (rc=$FRC)"
fi
# And the escape hatch has to actually work, or the message is a lie.
SOUT="$(python3 "$GRAPH" findings "$RO" --stdout 2>&1)" && SRC=0 || SRC=$?
if [[ $SRC -eq 0 ]] && grep -q "AUTHORITATIVE" <<<"$SOUT" && ! grep -q "GRAPH_UNWRITABLE" <<<"$SOUT"; then
  ok "…and \`--stdout\` genuinely renders the full view on the same read-only tree"
else
  bad "the named error points at a flag that does not work" "$SOUT (rc=$SRC)"
fi
# `road` is the same derived-surface contract and shared the same defect.
ROUT="$(python3 "$GRAPH" road "$RO" 2>&1)" && RRC=0 || RRC=$?
if ! grep -q "Traceback" <<<"$ROUT" && grep -q "GRAPH_UNWRITABLE" <<<"$ROUT" && [[ $RRC -ne 0 ]]; then
  ok "road degrades identically — one rule for every derived view, not a per-command patch"
else
  bad "road still crashes on a read-only tree" "$ROUT (rc=$RRC)"
fi

echo "── Test 62b: gate's absent-witness branch is still NON-capping, exit 0, on the gate surface"
# Test 36 pins this on check/gap. The v10 release note promises it on `gate` too, and the installed
# base depends on it: migrate.js marks every v8→v9 upgrader with .v9-graph-needed, so on upgrade day
# NO project has a committed witness. If gate blocked there, the whole base is bricked by a bump.
restore_ro
UNB="$TMP/projects/006-unbuilt"
mkdir -p "$UNB/epics/001-u/stories/S001-a"
cat > "$UNB/product-contract.md" <<'EOF'
# Product Contract: Unbuilt
## 5. Magic Moments
### MM-1 — Only wow
EOF
printf -- '---\nartifact_type: story-spec\nserves: [MM-1]\n---\n# A\n#### AC-1 — a\n' \
  > "$UNB/epics/001-u/stories/S001-a/spec.md"
OUT="$(python3 "$GRAPH" gate "$UNB" --story "001-u/S001" 2>&1)" && RC=0 || RC=$?
if [[ $RC -eq 0 ]] && grep -q "GRAPH_UNBUILT" <<<"$OUT" && ! grep -q "GRAPH_STALE" <<<"$OUT"; then
  ok "a never-built graph is reported as UNBUILT on gate and clears to advance (exit 0)"
else
  bad "gate must not brick a project that has never run build (the whole v8→v9 base)" "$OUT (rc=$RC)"
fi

echo ""
echo "════════════════════════════════════════════"
echo "  speck_graph: $PASS passed, $FAIL failed"
echo "════════════════════════════════════════════"
[[ $FAIL -eq 0 ]]
