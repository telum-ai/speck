#!/usr/bin/env bash
# validate-taste-axis.test.sh — smoke tests for the TASTE axis validator (issue #84)

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-taste-axis.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

mkdir -p "$TMP/.speck"
echo '{"project_archetype": "consumer_product"}' > "$TMP/.speck/project.json"

HEADER='## 🧭 Four-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD / TASTE)'

# 1. Consumer UX-RC, covered TASTE, dual anchor → passes
cat > "$TMP/r1.md" <<EOF
---
readiness_state_claimed: UX-RC
felt_axis: ai-verified
taste_axis: ai-critiqued
taste_anchor: product+universal
---

$HEADER
- TASTE: ai-critiqued (connoisseur pass recorded)
EOF
bash "$VALIDATOR" --strict "$TMP/r1.md" >/dev/null 2>&1 && pass "UX-RC + ai-critiqued + product+universal passes" || fail "clean UX-RC should pass"

# 2. Consumer UX-RC, uncovered TASTE → fails
cat > "$TMP/r2.md" <<EOF
---
readiness_state_claimed: UX-RC
taste_axis: uncovered
---

$HEADER
EOF
bash "$VALIDATOR" --strict "$TMP/r2.md" >/dev/null 2>&1 && fail "uncovered TASTE at UX-RC should fail" || pass "uncovered TASTE at UX-RC fails"

# 3. forks-open WITH a populated Aesthetic Forks section → passes
cat > "$TMP/r3.md" <<EOF
---
readiness_state_claimed: UX-RC
taste_axis: forks-open
taste_anchor: product+universal
---

$HEADER

### 🎨 Aesthetic Forks — Owner Decision
- Fork: hero gradient vs flat. Option A: gradient (playful). Option B: flat (calm). Rec: A.
EOF
bash "$VALIDATOR" --strict "$TMP/r3.md" >/dev/null 2>&1 && pass "forks-open with forks listed passes" || fail "forks-open + forks should pass"

# 4. forks-open with an EMPTY forks section → fails
cat > "$TMP/r4.md" <<EOF
---
readiness_state_claimed: UX-RC
taste_axis: forks-open
taste_anchor: product+universal
---

$HEADER

### 🎨 Aesthetic Forks — Owner Decision
EOF
bash "$VALIDATOR" --strict "$TMP/r4.md" >/dev/null 2>&1 && fail "forks-open with empty forks should fail" || pass "forks-open with empty forks fails"

# 5. universal-only anchor at SHIP-RC → fails
cat > "$TMP/r5.md" <<EOF
---
readiness_state_claimed: SHIP-RC
taste_axis: ai-critiqued
taste_anchor: universal-only
---

$HEADER
EOF
bash "$VALIDATOR" --strict "$TMP/r5.md" >/dev/null 2>&1 && fail "universal-only at SHIP-RC should fail" || pass "universal-only at SHIP-RC fails"

# 6. invalid taste_axis value → fails
cat > "$TMP/r6.md" <<EOF
---
readiness_state_claimed: UX-RC
taste_axis: gorgeous
taste_anchor: product+universal
---

$HEADER
EOF
bash "$VALIDATOR" --strict "$TMP/r6.md" >/dev/null 2>&1 && fail "invalid taste_axis should fail" || pass "invalid taste_axis value fails"

# 7. non-consumer (infra_service) with uncovered → passes (axis N/A)
mkdir -p "$TMP/infra/.speck"
echo '{"project_archetype": "infra_service"}' > "$TMP/infra/.speck/project.json"
cat > "$TMP/infra/r.md" <<EOF
---
readiness_state_claimed: SHIP-RC
taste_axis: uncovered
---

$HEADER
EOF
bash "$VALIDATOR" --strict "$TMP/infra/r.md" >/dev/null 2>&1 && pass "infra_service uncovered TASTE passes (N/A)" || fail "infra should skip TASTE"

# 8. unqualified 'premium' claim with uncovered TASTE → fails
cat > "$TMP/r8.md" <<EOF
---
readiness_state_claimed: IMPL-GREEN
taste_axis: uncovered
---

$HEADER

## 🎯 Readiness State Claim
Claiming: IMPL-GREEN. The UI is premium and polished.
EOF
bash "$VALIDATOR" --strict "$TMP/r8.md" >/dev/null 2>&1 && fail "premium claim with uncovered TASTE should fail" || pass "premium claim with uncovered TASTE fails"

# 9. bare 'Four-Axis Readiness' header, no parenthetical axis list → still recognised (issue #102)
cat > "$TMP/r9.md" <<EOF
---
readiness_state_claimed: UX-RC
felt_axis: ai-verified
taste_axis: ai-critiqued
taste_anchor: product+universal
---

## 🧭 Four-Axis Readiness
- TASTE: ai-critiqued (connoisseur pass recorded)
EOF
# NOTE: capture, then grep — piping into `grep -q` lets the validator's own exit status mask
# the match under pipefail, turning this into an assertion that can never fail.
R9_OUT="$(bash "$VALIDATOR" --strict "$TMP/r9.md" 2>&1 || true)"
if grep -q "Missing the Readiness axes header" <<<"$R9_OUT"; then
  fail "bare 'Four-Axis Readiness' header rejected — the match is not loose (issue #102)"
else
  pass "bare 'Four-Axis Readiness' header accepted (no parenthetical required)"
fi

if [[ "$FAILED" == 0 ]]; then echo "✅ validate-taste-axis: all tests passed"; else echo "❌ validate-taste-axis: FAILURES"; exit 1; fi
