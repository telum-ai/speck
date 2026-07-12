#!/usr/bin/env bash
# market-reconcile-check.test.sh — smoke tests for §2a↔§3 reconciliation (issue #80)

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SCRIPT="$ROOT/.speck/scripts/market-reconcile-check.sh"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }

# Build a contract. Args: dir, differentiator, wedge-verdict
mkproj() {
  local dir="$1" diff="$2" wedge="$3"
  mkdir -p "$dir/.speck"; echo '{}' > "$dir/.speck/project.json"
  {
    echo "# Product Contract"
    echo ""
    echo "### 2a. Value Defensibility"
    echo ""
    echo "*A price is a claim; not yet defensible unless it survives the substitute.*"
    echo ""
    echo "**Defensible-wedge verdict**: ${wedge}"
    echo ""
    echo "---"
    echo ""
    echo "## 3. The Differentiator"
    echo ""
    echo "**Core differentiator**: ${diff}"
  } > "$dir/product-contract.md"
}

run() { RC=0; OUT=$(bash "$SCRIPT" "$1" 2>&1) || RC=$?; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# 1. No contract → n/a
d="$T/t1"; mkdir -p "$d/.speck"; echo '{}' > "$d/.speck/project.json"
run "$d"
{ [[ "$RC" == 0 ]]; } && pass "no contract → n/a" || fail "no contract should be n/a"

# 2. Both filled, high token overlap, no self-flag → reconciled
d="$T/t2"; mkproj "$d" \
  "Streb adapts the dose locally per exercise from the last set." \
  "The wedge is that Streb adapts the dose locally per exercise, not templates."
run "$d"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "WEDGE_RECONCILED"; } && pass "aligned §3/§2a → reconciled" || fail "aligned should reconcile"

# 3. §2a wedge filled but §3 empty/scaffold → WEDGE_DRIFT.P1 (structural)
d="$T/t3"; mkproj "$d" \
  "REPLACE_BEFORE_SHIP: One sentence." \
  "The defensible wedge is proprietary per-exercise adaptation from set response."
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "WEDGE_DRIFT.P1"; } && pass "wedge but empty §3 → P1 structural" || fail "empty §3 with wedge should be P1"

# 4. §2a self-flags §3 as thin/copyable → WEDGE_DRIFT.P1 (Brightstance case)
d="$T/t4"; mkproj "$d" \
  "A calm daily dashboard for parents." \
  "Our §3 headline is thin and copyable; the real moat is the proprietary school-data pipeline."
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "WEDGE_DRIFT.P1"; } && pass "§2a self-flags §3 → P1" || fail "self-flag should be P1"

# 5. Both filled, low overlap → WEDGE_DRIFT.P2 (hand to auditor)
d="$T/t5"; mkproj "$d" \
  "Streb adapts the dose locally per exercise." \
  "Proprietary biomechanics dataset gathered from thousands of elite athletes."
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "WEDGE_DRIFT.P2"; } && pass "low overlap → P2" || fail "low overlap should be P2"

# 6. Legacy standalone value-defensibility.md (no §2a verdict in contract), §3 empty → P1 via legacy file
d="$T/t6"; mkdir -p "$d/.speck"; echo '{}' > "$d/.speck/project.json"
{
  echo "## 3. The Differentiator"
  echo ""
  echo "**Core differentiator**: REPLACE_BEFORE_SHIP: one sentence."
} > "$d/product-contract.md"
{
  echo "# Value Defensibility"
  echo ""
  echo "**Defensible-wedge verdict**: The wedge is the proprietary longitudinal dataset."
} > "$d/value-defensibility.md"
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "value-defensibility.md"; } && pass "legacy standalone file used" || fail "legacy file should be read"

if [[ "$FAILED" == 0 ]]; then echo "✅ market-reconcile-check: all tests passed"; else echo "❌ market-reconcile-check: FAILURES"; exit 1; fi
