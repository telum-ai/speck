#!/usr/bin/env bash
# Regression tests for banned-language-lint.sh (macOS bash 3.2 + --staged scoping)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/banned-language-lint.sh"
TMPDIR_ROOT="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "$TMPDIR_ROOT/speck-banned-lint-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

assert_ok() {
  local label="$1"
  shift
  if "$@"; then
    echo "PASS: $label"
    pass=$((pass + 1))
  else
    echo "FAIL: $label" >&2
    fail=$((fail + 1))
  fi
}

assert_fail() {
  local label="$1"
  shift
  if "$@"; then
    echo "FAIL: $label (expected failure)" >&2
    fail=$((fail + 1))
  else
    echo "PASS: $label"
    pass=$((pass + 1))
  fi
}

write_product_contract() {
  local dir="$1"
  mkdir -p "$dir/specs/projects/test"
  cat > "$dir/specs/projects/test/product-contract.md" <<'EOF'
# Product Contract

## 7. Banned Language / System Anti-Patterns

| Banned Term | Where it appears | Why it's banned | Use instead |
|-------------|------------------|-----------------|-------------|
| synergy | UI | generic pitch | collaboration |
EOF
  mkdir -p "$dir/.speck"
  cat > "$dir/.speck/project.json" <<'EOF'
{"project_id":"test","play_level":"sprint"}
EOF
}

init_git() {
  local dir="$1"
  (
    cd "$dir"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test"
  )
}

# V5a: direct bash 3.2 empty-array idiom (mirrors line 40)
assert_ok "V5a: empty EXTRA_ARGS expansion under set -u" \
  bash -c 'set -euo pipefail; EXTRA_ARGS=(); set -- ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}; exit 0'

# V5b: --staged with no extra args (pre-commit invocation path)
write_product_contract "$WORK/empty-args"
init_git "$WORK/empty-args"
(
  cd "$WORK/empty-args"
  echo "ok" > README.md
  git add README.md
)
assert_ok "V5b: --staged with empty EXTRA_ARGS (pre-commit path)" \
  bash -c "cd '$WORK/empty-args' && bash '$LINT' --staged"

# V6: --staged must skip .speck/ and specs/ (framework docs contain banned-term examples)
write_product_contract "$WORK/staged-scope"
init_git "$WORK/staged-scope"
(
  cd "$WORK/staged-scope"
  mkdir -p .speck .cursor/rules specs/projects/test
  echo 'Example banned term: synergy in methodology docs' > .speck/README.md
  echo 'Another synergy mention' > .cursor/rules/foo.md
  echo 'synergy in specs should also be skipped' > specs/projects/test/notes.md
  git add .speck .cursor specs
)
assert_ok "V6: --staged skips .speck/.cursor/specs (no false positives)" \
  bash -c "cd '$WORK/staged-scope' && bash '$LINT' --staged"

# V6b: staged product-surface files are still scanned
write_product_contract "$WORK/staged-product"
init_git "$WORK/staged-product"
(
  cd "$WORK/staged-product"
  mkdir -p src
  echo 'We deliver synergy for teams' > src/marketing.ts
  git add src/marketing.ts specs .speck
)
assert_fail "V6b: --staged still scans src/* for banned terms" \
  bash -c "cd '$WORK/staged-product' && bash '$LINT' --staged"

# V7: §7 terms written in backticks + a *(qualifier)* note must still match the bare word in code (#83)
mkdir -p "$WORK/backtick/specs/projects/test" "$WORK/backtick/.speck" "$WORK/backtick/src"
cat > "$WORK/backtick/specs/projects/test/product-contract.md" <<'EOF'
# Product Contract

## 7. Banned Language / System Anti-Patterns

| Banned Term | Where it appears | Why it's banned | Use instead |
|-------------|------------------|-----------------|-------------|
| `host`, `organizer` *(of the user)* | UI pills | positions the user as a host | founder |
EOF
cat > "$WORK/backtick/.speck/project.json" <<'EOF'
{"project_id":"test","play_level":"sprint"}
EOF
printf 'export const pill = "✦ HOST";\nconst label = "organizer";\n' > "$WORK/backtick/src/pill.tsx"
assert_fail "V7: backtick/qualifier §7 terms match bare words in code (#83)" \
  bash -c "cd '$WORK/backtick' && bash '$LINT'"

# V8: non-allowlist extensions (.astro) must be scanned — the rg branch used to omit them (#85)
mkdir -p "$WORK/astro/specs/projects/test" "$WORK/astro/.speck" "$WORK/astro/src/pages"
cat > "$WORK/astro/specs/projects/test/product-contract.md" <<'EOF'
# Product Contract
## 7. Banned Language / System Anti-Patterns
| Banned Term | Where | Why | Use instead |
|-------------|-------|-----|-------------|
| thought leader | UI | jargon | practitioner |
EOF
echo '{"project_id":"test","play_level":"sprint"}' > "$WORK/astro/.speck/project.json"
echo '<p>He is a thought leader.</p>' > "$WORK/astro/src/pages/probe.astro"
assert_fail "V8: .astro user-visible strings are scanned (#85)" \
  bash -c "cd '$WORK/astro' && bash '$LINT'"

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
