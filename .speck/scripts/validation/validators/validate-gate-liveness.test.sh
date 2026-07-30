#!/usr/bin/env bash
# validate-gate-liveness.test.sh — tests for the gate WIRING check (issue #88)

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VAL="$ROOT/.speck/scripts/validation/validators/validate-gate-liveness.sh"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# build a contract with a §6a registry; rows come from $2
mkctr() { # dir  rows
  mkdir -p "$1/.speck"
  {
    echo "## 6. Required Static Evidence"
    echo ""
    echo "### 6a. CI-Enforced Gate Registry"
    echo "| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |"
    echo "|---------|------------------|-------|--------|--------|--------|"
    printf '%s\n' "$2"
    echo ""
    echo "## 7. Required Live-Service Evidence"
  } > "$1/evidence-contract.md"
}
run() { RC=0; OUT=$(bash "$VAL" --strict "$1" 2>&1) || RC=$?; }

# 1. bug #1 — declared pre-push, wired stages:[manual] → GATE_WIRING_DRIFT.P1
d="$T/t1"; mkctr "$d" "| vitest | npm run test | pre-push | frontend | — | — |"
cat > "$d/.pre-commit-config.yaml" <<'EOF'
repos:
  - repo: local
    hooks:
      - id: vitest
        name: vitest frontend
        entry: bash -lc 'cd frontend && npm run test'
        stages: [manual]
EOF
run "$d/evidence-contract.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "GATE_WIRING_DRIFT.P1"; } && pass "bug#1: pre-push wired stages:[manual] → DRIFT.P1" || fail "bug#1 should be DRIFT.P1"

# 2. bug #2 — declared ci:push, workflow has branches-ignore:[main] → CI_TRUNK_EXCLUDED.P1
d="$T/t2"; mkctr "$d" "| integ | pytest tests/integration | ci:push | backend | — | — |"
mkdir -p "$d/.github/workflows"
cat > "$d/.github/workflows/ci.yml" <<'EOF'
name: CI
on:
  push:
    branches-ignore: [main]
jobs:
  test:
    steps:
      - run: pytest tests/integration
EOF
run "$d/evidence-contract.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "CI_TRUNK_EXCLUDED.P1"; } && pass "bug#2: CI branches-ignore:[main] → CI_TRUNK_EXCLUDED.P1" || fail "bug#2 should be CI_TRUNK_EXCLUDED.P1"

# 3. bug #3 — declared pre-commit script, never referenced in committed config → SCRIPT_UNREFERENCED.P1
d="$T/t3"; mkctr "$d" "| banned | .speck/scripts/banned-language-lint.sh | pre-commit | copy | — | — |"
cat > "$d/.pre-commit-config.yaml" <<'EOF'
repos:
  - repo: local
    hooks:
      - id: eslint
        entry: eslint
        stages: [pre-commit]
EOF
run "$d/evidence-contract.md"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "SCRIPT_UNREFERENCED.P1"; } && pass "bug#3: script present-on-disk but unreferenced → SCRIPT_UNREFERENCED.P1" || fail "bug#3 should be SCRIPT_UNREFERENCED.P1"

# 4. correctly wired pre-commit gate → GATE_OK, no P1 (and empty .git/hooks must NOT matter)
d="$T/t4"; mkctr "$d" "| eslint | eslint | pre-commit | frontend | — | — |"
cat > "$d/.pre-commit-config.yaml" <<'EOF'
repos:
  - repo: local
    hooks:
      - id: eslint
        entry: eslint --max-warnings 0
        stages: [pre-commit]
EOF
mkdir -p "$d/.git/hooks"   # empty installed-hooks dir must not trigger a P1
run "$d/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "GATE_OK"; } && pass "wired pre-commit gate → OK (empty .git/hooks ignored)" || fail "correctly-wired gate should pass"

# 5. waiver with no backing DEC → GATE_WAIVER_UNBACKED.P2 (not a P1 block)
d="$T/t5"; mkctr "$d" "| slow-e2e | npx playwright test | ci:push | e2e | — | waived DEC-999 |"
run "$d/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "GATE_WAIVER_UNBACKED.P2"; } && pass "waiver without DEC → WAIVER_UNBACKED.P2" || fail "unbacked waiver should be P2"

# 6. waiver backed by a real DEC → skipped, no finding
d="$T/t6"; mkctr "$d" "| slow-e2e | npx playwright test | ci:push | e2e | — | waived DEC-123 |"
echo "## DEC-123 — e2e is manual for now" > "$d/project-decisions-log.md"
run "$d/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "GATE_WAIVED"; } && pass "waiver backed by DEC-123 → skipped" || fail "backed waiver should skip"

# 7. CI gate but no workflows dir → degrade to UNVERIFIED.P2 (never false-P1)
d="$T/t7"; mkctr "$d" "| integ | pytest | ci:push | backend | — | — |"
run "$d/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "GATE_WIRING_UNVERIFIED.P2"; } && pass "no CI system → UNVERIFIED.P2 (degrade-to-honest)" || fail "unknown CI should degrade, not fail"

# 8. no §6a registry at all → P3 nudge, exit 0 (blocks only at ship, enforced by skills)
d="$T/t8"; mkdir -p "$d/.speck"; printf '## 6. Required Static Evidence\n\n## 7. Live\n' > "$d/evidence-contract.md"
run "$d/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "GATE_WIRING.P3"; } && pass "no §6a → P3 nudge, non-blocking" || fail "missing registry should be a P3 nudge"

# 9. MECHANISM PROOF (header-keyed conversion, #header-keyed-6a) — insert a 7th column ("Scope") in
# the MIDDLE of the table, between Domain and Canary. Under the OLD positional read ($7 = Waiver),
# a 7-column row shifts Waiver's real cell to index 6 while $7 (0-indexed 5) now lands on the
# CANARY cell — exactly the "insert a column and Canary silently re-maps to Waiver" bug this
# conversion exists to kill. The waiver text only matches `waived DEC-\d+` in its REAL cell, so a
# wrong column read here falls through to ordinary (non-waiver) stage classification instead.
d="$T/t9"
mkdir -p "$d/.speck"
{
  echo "## 6. Required Static Evidence"
  echo ""
  echo "### 6a. CI-Enforced Gate Registry"
  echo "| Gate ID | Command / Script | Stage | Domain | Scope | Canary | Waiver |"
  echo "|---------|------------------|-------|--------|-------|--------|--------|"
  echo "| proof-gate | \`scripts/proof.sh\` | pre-commit | frontend | widget | banned-language | waived DEC-707 |"
  echo ""
  echo "## 7. Required Live-Service Evidence"
} > "$d/evidence-contract.md"
run "$d/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "GATE_WAIVER_UNBACKED.P2.*proof-gate" && echo "$OUT" | grep -q "DEC-707"; } \
  && pass "7-col mechanism proof: Waiver still resolved from its REAL (shifted) column" \
  || fail "7-col table: Waiver column must resolve by name, not by the old fixed \$7 position"

# 10. LEGACY FALLBACK — a table with NO header row at all (no line contains "Gate ID") still
# classifies correctly via the historical fixed-position fallback. Proves the header-keyed
# conversion doesn't strand a hand-authored/legacy project whose §6a table has no recognizable
# header for resolve_columns_from_header to key off of.
d="$T/t10"
mkdir -p "$d/.speck"
{
  echo "## 6. Required Static Evidence"
  echo ""
  echo "### 6a. CI-Enforced Gate Registry"
  echo "| eslint | eslint | pre-commit | frontend | — | — |"
  echo ""
  echo "## 7. Required Live-Service Evidence"
} > "$d/evidence-contract.md"
cat > "$d/.pre-commit-config.yaml" <<'EOF'
repos:
  - repo: local
    hooks:
      - id: eslint
        entry: eslint --max-warnings 0
        stages: [pre-commit]
EOF
run "$d/evidence-contract.md"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "GATE_OK"; } \
  && pass "headerless legacy table → positional fallback still classifies correctly" \
  || fail "a table with no header row should fall back to the historical fixed positions"

if [[ "$FAILED" == 0 ]]; then echo "✅ validate-gate-liveness: all tests passed"; else echo "❌ validate-gate-liveness: FAILURES"; exit 1; fi
