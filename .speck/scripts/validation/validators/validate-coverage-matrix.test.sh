#!/usr/bin/env bash
# validate-coverage-matrix.test.sh — tests for the coverage-matrix generator + validator (issue #84)

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
GEN="$ROOT/.speck/scripts/validation/generate-coverage-matrix.sh"
VAL="$ROOT/.speck/scripts/validation/validators/validate-coverage-matrix.sh"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# --- an epic with a filled experience-chain §2 screen table ---
mkdir -p "$T/e1/.speck"
echo '{}' > "$T/e1/.speck/project.json"
cat > "$T/e1/experience-chain.md" <<'EOF'
# Experience Chain
## 2. Screen-by-Screen Chain
| # | Screen | Entry state | Single job | Emotion | Emotion | Handoff | No-repeat |
|---|--------|-------------|------------|---------|---------|---------|-----------|
| 1 | Home feed | fresh | browse | calm | curious | Detail | intro |
| 2 | Detail | from feed | decide | curious | committed | Checkout | header |
EOF

# 1. generate → skeleton with GAP cells, completeness complete
GEN_OUT=$(bash "$GEN" --level epic "$T/e1" 2>&1)
{ [[ -f "$T/e1/coverage-matrix.md" ]] && echo "$GEN_OUT" | grep -q "2 screens" && echo "$GEN_OUT" | grep -q "complete"; } \
  && pass "generate: 2 screens, completeness complete" || fail "generate should enumerate 2 screens"

# 2. validate non-strict → passes with GAP warnings (exit 0)
bash "$VAL" "$T/e1/coverage-matrix.md" >/dev/null 2>&1 && pass "validate non-strict passes (GAPs are warnings)" || fail "non-strict should pass"

# 3. validate --strict → fails (un-run GAPs)
bash "$VAL" --strict "$T/e1/coverage-matrix.md" >/dev/null 2>&1 && fail "strict should fail on GAPs" || pass "validate --strict fails on GAP cells"

# 4. a fully-RUN matrix with evidence → passes --strict
cat > "$T/run.md" <<'EOF'
---
artifact_type: coverage-matrix
generator_completeness: complete
---
## Cell status grid
| Persona | Screen/Route | State | Viewport | Theme | DOES-IT-WORK | IS-IT-GOOD | IS-IT-CRAFTED | Status | Evidence |
|---------|-------------|-------|----------|-------|--------------|-----------|---------------|--------|----------|
| naive-hostile | Home | happy | mobile | light | ✅ | ✅ | GOOD | RUN | `larp-recordings/abc-home.md` |
| naive-hostile | Home | error | mobile | light | ✅ | ✅ | GOOD | DEFERRED-BY-BUDGET(secondary) | — |
## Cross-cell defect ledger
EOF
bash "$VAL" --strict "$T/run.md" >/dev/null 2>&1 && pass "fully RUN/waived matrix passes --strict" || fail "RUN+evidence should pass strict"

# 5. a RUN cell with NO evidence → fails --strict (surrogate)
cat > "$T/noev.md" <<'EOF'
---
artifact_type: coverage-matrix
generator_completeness: complete
---
## Cell status grid
| Persona | Screen/Route | State | Viewport | Theme | DOES-IT-WORK | IS-IT-GOOD | IS-IT-CRAFTED | Status | Evidence |
|---------|-------------|-------|----------|-------|--------------|-----------|---------------|--------|----------|
| naive-hostile | Home | happy | mobile | light | ✅ | ✅ | GOOD | RUN | — |
## Cross-cell defect ledger
EOF
bash "$VAL" --strict "$T/noev.md" >/dev/null 2>&1 && fail "RUN without evidence should fail strict" || pass "RUN without evidence fails --strict (surrogate)"

# 6. chain-partial (empty experience-chain) → generate stamps chain-partial → validate --strict fails
mkdir -p "$T/e2/.speck"; echo '{}' > "$T/e2/.speck/project.json"
echo '# Experience Chain (no §2 table yet)' > "$T/e2/experience-chain.md"
bash "$GEN" --level epic "$T/e2" >/dev/null 2>&1
{ grep -q 'generator_completeness: chain-partial' "$T/e2/coverage-matrix.md"; } && pass "generate stamps chain-partial on thin source" || fail "thin chain should stamp chain-partial"
bash "$VAL" --strict "$T/e2/coverage-matrix.md" >/dev/null 2>&1 && fail "chain-partial should fail strict" || pass "chain-partial fails --strict"

if [[ "$FAILED" == 0 ]]; then echo "✅ validate-coverage-matrix: all tests passed"; else echo "❌ validate-coverage-matrix: FAILURES"; exit 1; fi
