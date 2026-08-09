#!/usr/bin/env bash
# validate-corpus-budget.test.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
SCRIPT="$ROOT/.speck/scripts/validation/validators/validate-corpus-budget.sh"

echo "Test: live repo passes"
bash "$SCRIPT" "$ROOT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Build a fake tree with validator + lib copied so ROOT=TMP works
mkdir -p "$TMP/.speck/scripts/validation/validators" "$TMP/.cursor/skills/good" "$TMP/.speck"
cp "$ROOT/.speck/scripts/validation/validators/validate-corpus-budget.sh" \
   "$TMP/.speck/scripts/validation/validators/"
cp "$ROOT/.speck/scripts/validation/validators/_corpus_budget_lib.py" \
   "$TMP/.speck/scripts/validation/validators/"
printf '# grandfather\n' > "$TMP/.speck/corpus-budget-grandfather.txt"

# 250-line AGENTS should fail line ceiling
{
  echo '<!-- SPECK:START -->'
  for i in $(seq 1 250); do echo "line $i"; done
  echo '<!-- SPECK:END -->'
} > "$TMP/AGENTS.md"

cat > "$TMP/.cursor/skills/good/SKILL.md" <<'EOF'
---
name: good
description: Short desc. Use when testing budget.
---

# good
1. Do thing.
EOF

echo "Test: oversized AGENTS fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected failure"
  exit 1
fi

echo "All corpus-budget tests passed"
