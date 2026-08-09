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

# Reset AGENTS to slim; inject essay into a skill reference
{
  echo '<!-- SPECK:START -->'
  for i in $(seq 1 10); do echo "line $i"; done
  echo '<!-- SPECK:END -->'
} > "$TMP/AGENTS.md"
mkdir -p "$TMP/.cursor/skills/essay/references"
cat > "$TMP/.cursor/skills/essay/SKILL.md" <<'EOF'
---
name: essay
description: Short desc. Use when testing essay lint.
---

# essay
1. Read references/procedure.md
EOF
cat > "$TMP/.cursor/skills/essay/references/procedure.md" <<'EOF'
# essay procedure
Field evidence from 001-odd says this gate matters.
1. Do the work.
EOF

echo "Test: essay pattern in skill references fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected essay failure"
  exit 1
fi

# Anti-theater: single procedure.md pointer
rm -rf "$TMP/.cursor/skills/essay"
mkdir -p "$TMP/.cursor/skills/theater/references"
cat > "$TMP/.cursor/skills/theater/SKILL.md" <<'EOF'
---
name: theater
description: Short desc. Use when testing anti-theater.
---

# theater
1. Read and fully execute `references/procedure.md`.
EOF
echo '# procedure' > "$TMP/.cursor/skills/theater/references/procedure.md"
# slim AGENTS again (essay test may have left FAIL state only)
{
  echo '<!-- SPECK:START -->'
  for i in $(seq 1 10); do echo "line $i"; done
  echo '<!-- SPECK:END -->'
} > "$TMP/AGENTS.md"

echo "Test: single procedure.md pointer fails"
if bash "$TMP/.speck/scripts/validation/validators/validate-corpus-budget.sh" "$TMP"; then
  echo "FAIL: expected anti-theater failure"
  exit 1
fi

echo "All corpus-budget tests passed"
