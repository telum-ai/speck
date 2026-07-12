#!/usr/bin/env bash
# validate-product-contract.test.sh — smoke tests for product contract validator

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-product-contract.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Test 1: Valid product contract with no self-violations passes"
cat > "$TMP/product-contract.md" <<'EOF'
---
artifact_type: product-contract
---

## 1. The Paid Promise / Operational SLA
We deliver high-quality features.

## 2. Primary Persona / Consumer
Persona

## 3. The Differentiator
Differentiator

## 4. JTBD Scorecard / Operational Invariants Scorecard
Scorecard

## 5. Magic Moments / Operational Milestones
Magic moments

## 6. Public Language / API & System Taxonomy
Taxonomy

## 7. Banned Language / System Anti-Patterns

| Banned Term | Use instead |
|-------------|-------------|
| premium     | high-quality |
EOF

bash "$VALIDATOR" --strict "$TMP/product-contract.md"
echo "  ✓ Passed Test 1"


echo "Test 2: Product contract with self-violation fails"
cat > "$TMP/product-contract-fail.md" <<'EOF'
---
artifact_type: product-contract
---

## 1. The Paid Promise / Operational SLA
We deliver premium features.

## 2. Primary Persona / Consumer
Persona

## 3. The Differentiator
Differentiator

## 4. JTBD Scorecard / Operational Invariants Scorecard
Scorecard

## 5. Magic Moments / Operational Milestones
Magic moments

## 6. Public Language / API & System Taxonomy
Taxonomy

## 7. Banned Language / System Anti-Patterns

| Banned Term | Use instead |
|-------------|-------------|
| premium     | high-quality |
EOF

if bash "$VALIDATOR" --strict "$TMP/product-contract-fail.md" >/dev/null 2>&1; then
  echo "ERROR: Expected self-violation to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 2 (failed correctly)"
fi

echo "Test 3: §2a self-flags §3 as thin/copyable → reconciliation fails (issue #80)"
mkdir -p "$TMP/recon"
cat > "$TMP/recon/product-contract.md" <<'EOF'
---
artifact_type: product-contract
---

## 1. The Paid Promise / Operational SLA
We deliver high-quality features.

## 2. Primary Persona / Consumer
Persona

### 2a. Value Defensibility

**Defensible-wedge verdict**: Our §3 headline is thin and copyable; the real moat is the proprietary longitudinal dataset.

## 3. The Differentiator

**Core differentiator**: A friendly daily dashboard.

## 4. JTBD Scorecard / Operational Invariants Scorecard
Scorecard

## 5. Magic Moments / Operational Milestones
Magic moments

## 6. Public Language / API & System Taxonomy
Taxonomy

## 7. Banned Language / System Anti-Patterns

| Banned Term | Use instead |
|-------------|-------------|
| premium     | high-quality |
EOF

if bash "$VALIDATOR" --strict "$TMP/recon/product-contract.md" >/dev/null 2>&1; then
  echo "ERROR: Expected §2a↔§3 reconciliation to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 3 (reconciliation failed correctly)"
fi

echo "Test 4: banned terms in §3a / §5 validation / §6 taxonomy / 'Bad:' examples do NOT self-violate (issue #81)"
mkdir -p "$TMP/t81a"
cat > "$TMP/t81a/product-contract.md" <<'EOF'
---
artifact_type: product-contract
---

## 1. The Paid Promise / Operational SLA
Adapt your training locally, set by set.

## 2. Primary Persona / Consumer
The dedicated lifter.

## 3. The Differentiator

**Core differentiator**: Adjusts load per exercise from your last set.

### 3a. Anti-Differentiators ("We are NOT...")
- We are NOT a rigid planner: no fixed mesocycle templates, no scheduled deload.

## 4. JTBD Scorecard / Operational Invariants Scorecard
Scorecard.

## 5. Magic Moments / Operational Milestones

### Magic Moment 1: First adjust
- **Content / Execution beats**: The set logs, the next target shifts.
- **Validation step**: erased-simulator day-0 LARP confirms the shift.
- Bad: "Great job crushing it!"

## 6. Public Language / API & System Taxonomy

### Canonical Domain Terms
| Internal concept | English UI term | Notes |
|------------------|-----------------|-------|
| `mesocycle` | Training Block | use exactly this phrase |

## 7. Banned Language / System Anti-Patterns

| Banned Term | Use instead |
|-------------|-------------|
| mesocycle | training block |
| simulator | internal tooling |
| Great job | earned praise |
| crushing it | specific progress |
EOF

bash "$VALIDATOR" --strict "$TMP/t81a/product-contract.md"
echo "  ✓ Passed Test 4 (legit meta-mentions no longer false-positive)"


echo "Test 5: a REAL leak (banned term in the §1 promise) still fails (issue #81 guardrail)"
mkdir -p "$TMP/t81b"
sed 's#Adapt your training locally, set by set.#Adapt your mesocycle locally, set by set.#' \
  "$TMP/t81a/product-contract.md" > "$TMP/t81b/product-contract.md"
if bash "$VALIDATOR" --strict "$TMP/t81b/product-contract.md" >/dev/null 2>&1; then
  echo "ERROR: Expected a §1 promise leak to fail, but it passed!"
  exit 1
else
  echo "  ✓ Passed Test 5 (real leak in §1 still caught)"
fi

echo "All validate-product-contract tests passed successfully!"
exit 0
