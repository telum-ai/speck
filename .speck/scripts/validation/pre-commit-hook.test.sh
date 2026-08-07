#!/usr/bin/env bash
# pre-commit-hook.test.sh — REACH tests for the Speck pre-commit hook.
#
# This file exists because of #109, and its subject is not "does the lint work" (that is
# banned-language-lint.test.sh's job) — it is "does the hook ever RUN the lint on the commits the
# lint exists to guard". Those are different questions, and only the second one was ever wrong.
#
# The failure it pins: the banned-language block sat BELOW the hook's early exit, and the early exit
# fires whenever no spec markdown and no README are staged — the description of every ordinary
# code-only commit, which is the entire population of a gate whose subject is user-visible copy in
# source files. Authored, correct, wired, unreachable. The hook printed
# "✓ No Speck specifications or README staged for commit." and never mentioned the lint, so a commit
# that was never scanned and a commit that scanned clean produced identical output.
#
# The only way to test reach is to DRIVE THE HOOK — the same pattern the two-carrier block's own
# comment prescribes for its reach ("driving the hook with only a .sh file staged"). Testing the
# lint directly would have passed on every day this bug was live.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
HOOK_SRC="$ROOT/.speck/scripts/validation/pre-commit-hook.sh"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- hook output -----"; echo "${OUT:-}"; echo "-----------------------"; FAILED=1; }

# Build a minimal but REAL Speck project: git repo, .speck/ with the scripts the hook invokes by
# relative path, and a product-contract.md §7 declaring one banned term.
mkproj() {
  local d="$1"
  mkdir -p "$d/specs/projects/test" "$d/src/app"
  mkdir -p "$d/.speck/scripts/validation/validators" "$d/.speck/scripts/lib"
  cp "$ROOT/.speck/scripts/validation/pre-commit-hook.sh" "$d/.speck/scripts/validation/"
  cp "$ROOT/.speck/scripts/banned-language-lint.sh" "$d/.speck/scripts/"
  cp "$ROOT/.speck/scripts/filter-forbidding-context.py" "$d/.speck/scripts/" 2>/dev/null || true
  cp "$ROOT/.speck/scripts/lib/text.sh" "$d/.speck/scripts/lib/" 2>/dev/null || true
  cat > "$d/.speck/project.json" <<'EOF'
{"project_id":"test","play_level":"sprint"}
EOF
  cat > "$d/specs/projects/test/product-contract.md" <<'EOF'
# Product Contract

## 7. Banned Language / System Anti-Patterns

| Banned Term | Where it appears | Why it's banned | Use instead |
|-------------|------------------|-----------------|-------------|
| synergy | UI | generic pitch | collaboration |
EOF
  git -C "$d" init -q
  git -C "$d" config user.email t@t.co
  git -C "$d" config user.name t
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -q -m init >/dev/null 2>&1
}

run_hook() { RC=0; OUT="$(cd "$1" && bash .speck/scripts/validation/pre-commit-hook.sh 2>&1)" || RC=$?; }

echo "Test 1: #109 REACH — a code-only commit carrying a banned term is BLOCKED"
# No spec markdown, no README: the exact commit shape the early exit used to discard.
d="$T/t1"; mkproj "$d"
printf 'export const COPY = "our synergy platform";\n' > "$d/src/app/copy.ts"
git -C "$d" add src/app/copy.ts >/dev/null 2>&1
run_hook "$d"
{ [[ "$RC" == 1 ]] && echo "$OUT" | grep -qi "banned"; } \
  && pass "code-only commit with a §7 term is rejected (the gate reaches its population)" \
  || fail "a code-only commit carrying a banned term must be blocked — the lint must run above the early exit"

echo "Test 2: #109 — the lint ANNOUNCES itself on a code-only commit"
# The silence was the worse half of the defect: an unscanned commit and a clean one printed the
# same thing. A gate that says nothing cannot be observed to have not run.
d="$T/t2"; mkproj "$d"
printf 'export const COPY = "clean collaboration copy";\n' > "$d/src/app/copy.ts"
git -C "$d" add src/app/copy.ts >/dev/null 2>&1
run_hook "$d"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "staged banned-language lint"; } \
  && pass "a clean code-only commit passes AND the lint reports that it ran" \
  || fail "the lint must announce itself on a code-only commit, and a clean one must pass"

echo "Test 3: a commit with NO staged files at all still exits 0"
d="$T/t3"; mkproj "$d"
run_hook "$d"
[[ "$RC" == 0 ]] && pass "empty stage → clean exit (no regression in the early-exit path)" \
  || fail "an empty stage must not fail the hook"

echo "Test 4: a staged SPEC commit carrying a banned term is still blocked"
# The other side of the move: the lint must not have stopped covering the population it already had.
d="$T/t4"; mkproj "$d"
mkdir -p "$d/specs/projects/test/epics/E001"
printf '# Epic\n\nWe promise real synergy here.\n' > "$d/specs/projects/test/epics/E001/epic.md"
git -C "$d" add -A >/dev/null 2>&1
run_hook "$d"
[[ "$RC" == 1 ]] && pass "spec commit with a §7 term is still rejected" \
  || fail "moving the block must not drop the population it already covered"

if [[ "$FAILED" == 0 ]]; then
  echo "✅ pre-commit-hook: all reach tests passed"
else
  echo "❌ pre-commit-hook: FAILURES"
  exit 1
fi
