#!/usr/bin/env bash
# market-staleness-check.test.sh — smoke tests for the competitive-claim staleness detector (issue #80)

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SCRIPT="$ROOT/.speck/scripts/market-staleness-check.sh"
FAILED=0

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }

# Portable "N days ago" as YYYY-MM-DD (BSD -v, else GNU -d)
days_ago() { date -v-"$1"d +%Y-%m-%d 2>/dev/null || date -d "$1 days ago" +%Y-%m-%d; }

# Build a throwaway project. Args: dir, differentiator, stamp-line, wedge, [project.json]
mkproj() {
  local dir="$1" diff="$2" stamp="$3" wedge="$4" pj="${5:-{\}}"
  mkdir -p "$dir/.speck"
  printf '%s' "$pj" > "$dir/.speck/project.json"
  {
    echo "# Product Contract"
    echo ""
    echo "### 2a. Value Defensibility"
    echo ""
    echo "**Defensible-wedge verdict**: ${wedge}"
    echo ""
    echo "## 3. The Differentiator"
    echo ""
    echo "**Core differentiator**: ${diff}"
    [[ -n "$stamp" ]] && echo "$stamp"
  } > "$dir/product-contract.md"
}

run() { RC=0; OUT=$(bash "$SCRIPT" "$1" 2>&1) || RC=$?; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# 1. No contract at all → n/a, exit 0
d="$T/t1"; mkdir -p "$d/.speck"; echo '{}' > "$d/.speck/project.json"
run "$d"
{ [[ "$RC" == 0 ]]; } && pass "no contract → n/a (exit 0)" || fail "no contract should be n/a"

# 2. Scaffold (REPLACE_BEFORE_SHIP) → no drift
d="$T/t2"; mkproj "$d" "REPLACE_BEFORE_SHIP: one sentence" "" "REPLACE_BEFORE_SHIP: fill"
run "$d"
{ [[ "$RC" == 0 ]]; } && pass "unfilled scaffold → no drift" || fail "scaffold should not drift"

# 3. Filled generic differentiator, no stamp → MARKET_DRIFT.P2
d="$T/t3"; mkproj "$d" "Streb adapts the dose locally per exercise from your last set." "" ""
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "MARKET_DRIFT.P2"; } && pass "generic + no stamp → P2" || fail "generic no-stamp should be P2"

# 4. Absolute claim, no stamp → MARKET_DRIFT.P1
d="$T/t4"; mkproj "$d" "No competitor offers real-time autoregulation plus LLM coaching." "" ""
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "MARKET_DRIFT.P1"; } && pass "absolute + no stamp → P1" || fail "absolute no-stamp should be P1"

# 5. Absolute claim + FRESH verified stamp (today, holds, sources 5, report exists) → clean
d="$T/t5"; mkproj "$d" "No competitor offers real-time autoregulation plus LLM coaching." \
  "*[market-verified $(days_ago 0) | verdict: holds | sources: 5 | scan: project-market-research-report-x.md]*" ""
echo "report" > "$d/project-market-research-report-x.md"
run "$d"
{ [[ "$RC" == 0 ]]; } && pass "absolute + fresh verified stamp → clean" || fail "fresh verified absolute should be clean"

# 6. Absolute claim + STALE verified stamp (60d > 30d tight clock) → P1
d="$T/t6"; mkproj "$d" "No competitor offers real-time autoregulation plus LLM coaching." \
  "*[market-verified $(days_ago 60) | verdict: holds | sources: 5 | scan: r.md]*" ""
echo "r" > "$d/r.md"
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "MARKET_DRIFT.P1"; } && pass "absolute + 60d-old stamp → P1 (tight clock)" || fail "stale absolute should be P1"

# 7. Verified stamp citing a MISSING report → P1 (phantom evidence)
d="$T/t7"; mkproj "$d" "No competitor offers X." \
  "*[market-verified $(days_ago 0) | verdict: holds | sources: 5 | scan: ghost.md]*" ""
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "phantom"; } && pass "missing cited report → P1 phantom" || fail "phantom evidence should be P1"

# 8. verdict:false → P1
d="$T/t8"; mkproj "$d" "No competitor offers X." \
  "*[market-verified $(days_ago 0) | verdict: false | sources: 5 | scan: r.md]*" ""
echo r > "$d/r.md"
run "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -q "MARKET_DRIFT.P1"; } && pass "verdict:false → P1" || fail "false verdict should be P1"

# 9. market_scan:false → disabled, exit 0
d="$T/t9"; mkproj "$d" "No competitor offers X." "" "" '{"market_scan": false}'
run "$d"
{ [[ "$RC" == 0 ]]; } && pass "market_scan:false → disabled" || fail "opt-out should disable"

# 10. Generic differentiator + fresh stamp within cadence → clean
d="$T/t10"; mkproj "$d" "Streb adapts the dose locally per exercise." \
  "*[market-verified $(days_ago 10) | verdict: holds | sources: 4 | scan: r.md]*" ""
echo r > "$d/r.md"
run "$d"
{ [[ "$RC" == 0 ]]; } && pass "generic + fresh stamp → clean" || fail "fresh generic should be clean"

if [[ "$FAILED" == 0 ]]; then echo "✅ market-staleness-check: all tests passed"; else echo "❌ market-staleness-check: FAILURES"; exit 1; fi
