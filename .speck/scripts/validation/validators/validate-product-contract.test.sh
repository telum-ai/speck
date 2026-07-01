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

echo "All validate-product-contract tests passed successfully!"
exit 0
