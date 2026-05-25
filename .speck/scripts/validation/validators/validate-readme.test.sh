#!/usr/bin/env bash
# validate-readme.test.sh — smoke tests for PROFILE validators

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/.speck" "$TMP/specs/projects/test-proj"
echo "v7.7.0" > "$TMP/.speck/VERSION"
echo '{"_active_project":"test-proj"}' > "$TMP/.speck/project.json"
echo "## 1. Paid Promise

We help teams ship faster with evidence-driven specs." > "$TMP/specs/projects/test-proj/product-contract.md"

cat > "$TMP/README.md" << 'EOF'
# Test Product

> We help teams ship faster with evidence-driven specs.

**Status**: Spec phase

<!-- SPECK:START -->
Built with Speck (speck v7.7.0).
<!-- SPECK:END -->
EOF

echo "Test: valid README passes"
bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$TMP"

cat > "$TMP/README.md" << 'EOF'
# Speck 🥓
Spec-driven development methodology
<!-- SPECK:START -->
old
<!-- SPECK:END -->
EOF

echo "Test: legacy marketing fails"
if bash "$ROOT/.speck/scripts/validation/validators/validate-readme.sh" --strict "$TMP" 2>/dev/null; then
  echo "FAIL: expected error for legacy README"
  exit 1
fi

echo "Test: profile-drift-check on aligned README"
cat > "$TMP/README.md" << 'EOF'
# Test Product
> We help teams ship faster with evidence-driven specs.
<!-- SPECK:START -->
speck v7.7.0
<!-- SPECK:END -->
EOF
bash "$ROOT/.speck/scripts/profile-drift-check.sh" "$TMP" test-proj

echo "All validate-readme smoke tests passed"
