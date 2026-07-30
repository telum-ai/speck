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

# ─────────────────────────────────────────────────────────────────────────────────
# #90 / #98 — the term extractor produced terms that can never match, and the
# --staged scope filter inspected zero files in 2 of 3 real repos.
#
# Every assertion below captures the lint's output into a VARIABLE first. Writing
# `if bash "$LINT" | grep -q X` under `set -o pipefail` reports the LINT's exit
# status, not the match — so when the gate correctly exits 1 the assertion inverts
# into one that can never fail. That inversion is how these bugs stayed green.
# ─────────────────────────────────────────────────────────────────────────────────

LAST_OUT=""
LAST_RC=0
run_lint() { # <dir> [args...]
  local dir="$1"; shift
  set +e
  LAST_OUT="$(cd "$dir" && bash "$LINT" "$@" 2>&1)"
  LAST_RC=$?
  set -e
}

# run_lint_nrg — the same run with ripgrep removed from PATH, so the grep fallback branch
# is exercised. python3 stays reachable at /usr/bin/python3 (the config reader and the
# forbidding-context filter both need it).
run_lint_nrg() { # <dir> [args...]
  local dir="$1"; shift
  set +e
  LAST_OUT="$(cd "$dir" && PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash "$LINT" "$@" 2>&1)"
  LAST_RC=$?
  set -e
}

_ok()   { echo "PASS: $1"; pass=$((pass + 1)); }
_bad()  { echo "FAIL: $1" >&2; printf '%s\n' "--- lint output ---" "$LAST_OUT" "-------------------" >&2; fail=$((fail + 1)); }

assert_rc()        { if [[ "$LAST_RC" -eq "$2" ]]; then _ok "$1"; else echo "  (rc=$LAST_RC want=$2)" >&2; _bad "$1"; fi; }
assert_out_has()   { if grep -qF -- "$2" <<<"$LAST_OUT"; then _ok "$1"; else _bad "$1"; fi; }
assert_out_lacks() { if grep -qF -- "$2" <<<"$LAST_OUT"; then _bad "$1"; else _ok "$1"; fi; }

# mkproj <dir>  — §7 table rows arrive on stdin
mkproj() {
  local d="$1"
  mkdir -p "$d/specs/projects/test" "$d/.speck"
  {
    echo '# Product Contract'
    echo ''
    echo '## 7. Banned Language / System Anti-Patterns'
    echo ''
    echo '| Banned Term | Where | Why | Use instead |'
    echo '|---|---|---|---|'
    cat
  } > "$d/specs/projects/test/product-contract.md"
  echo '{"project_id":"test","play_level":"sprint"}' > "$d/.speck/project.json"
}

# set_scope <dir> <legacy-root|any-depth> — flip banned_language.scope in project.json
set_scope() {
  python3 - "$1/.speck/project.json" "$2" <<'PY'
import json, sys
path = sys.argv[1]
cfg = json.load(open(path))
cfg.setdefault("banned_language", {})["scope"] = sys.argv[2]
json.dump(cfg, open(path, "w"))
PY
}

# assert_branches_agree <label> <dir> [args...] — #85's differential, as a reusable
# assertion. The rg branch and the grep fallback must return the SAME rc and the SAME
# per-term verdict lines; if they don't, the gate's answer depends on which binary is
# installed rather than on the code.
assert_branches_agree() {
  local label="$1" dir="$2"; shift 2
  local a_rc a_v b_rc b_v
  run_lint "$dir" "$@"
  a_rc="$LAST_RC"
  a_v="$(grep -E '^(❌ "|SPECK_GATE_(SUBJECT|PREDICATES))' <<<"$LAST_OUT" || true)"
  run_lint_nrg "$dir" "$@"
  b_rc="$LAST_RC"
  b_v="$(grep -E '^(❌ "|SPECK_GATE_(SUBJECT|PREDICATES))' <<<"$LAST_OUT" || true)"
  if [[ "$a_rc" == "$b_rc" && "$a_v" == "$b_v" ]]; then
    _ok "$label"
  else
    echo "  rg[$a_rc]: $a_v" >&2
    echo "  grep[$b_rc]: $b_v" >&2
    _bad "$label"
  fi
}

# V9 (#90a) — a "/" INSIDE the row's parenthetical must not shred the term.
#   `"sett" (Norwegian for rep/set)`  →  sett            [right]
#                                    →  sett (Norwegian for rep  +  set)   [the bug]
# Both fragments are unmatchable, so the ban silently never fired.
mkproj "$WORK/v9" <<'EOF'
| "sett" (Norwegian for rep/set) | UI | Norwegian leaking into English copy | rep |
EOF
mkdir -p "$WORK/v9/src"
echo 'const label = "sett";' > "$WORK/v9/src/ui.ts"
run_lint "$WORK/v9"
assert_rc        "V9a: slash inside a parenthetical does not shred the term (#90a)" 1
assert_out_has   "V9b: the bare word is the term that fires" '"sett"'
assert_out_lacks "V9c: no shredded fragment term 'set)'" '"set)"'

# V10 (#90b) — the qualifier strip required LITERAL asterisks, so a bare
# `(as a claim)` survived and `therapy (as a claim)` never matched anything.
mkproj "$WORK/v10" <<'EOF'
| "therapy" (as a claim) | UI | medical claim we cannot make | practice |
EOF
mkdir -p "$WORK/v10/src"
echo 'const copy = "therapy";' > "$WORK/v10/src/copy.ts"
run_lint "$WORK/v10"
assert_rc      "V10a: a BARE trailing qualifier is stripped like the italic one (#90b)" 1
assert_out_has "V10b: term reported as the bare word" '"therapy"'

# V11 (#90c) — the '### Banned Phrase Classes' extractor appends with >> and
# BANNED_COUNT was a raw wc -l, so a term present in BOTH places was scanned
# twice and every hit double-counted.
mkproj "$WORK/v11" <<'EOF'
| diagnose | UI | medical claim | describe |
EOF
cat >> "$WORK/v11/specs/projects/test/product-contract.md" <<'EOF'

### Banned Phrase Classes

- ❌ "diagnose"
EOF
mkdir -p "$WORK/v11/src"
echo 'const s = "diagnose";' > "$WORK/v11/src/s.ts"
run_lint "$WORK/v11"
assert_out_has "V11a: a term in both table and phrase-classes is deduped (#90c)" "Terms to check: 1"
assert_out_has "V11b: its hit is counted once" "Total banned-language hits: 1"

# V12 (#98, third defect) — `echo "$x" | head -n 10 | sed` under `set -o pipefail`:
# head exits after 10 lines, SIGPIPEs the producer, the pipeline reports 141 and
# `set -e` kills the run. Every remaining term goes unscanned and the totals line
# never prints — a partial scan that looks like a finished one.
mkproj "$WORK/v12" <<'EOF'
| alpha | UI | placeholder jargon | concrete noun |
| zulu | UI | placeholder jargon | concrete noun |
EOF
mkdir -p "$WORK/v12/src"
: > "$WORK/v12/src/big.ts"
padding="$(printf 'x%.0s' $(seq 1 400))"
for i in $(seq 1 400); do
  echo "const v$i = \"alpha $padding\";" >> "$WORK/v12/src/big.ts"
done
echo 'const z = "zulu";' > "$WORK/v12/src/z.ts"
run_lint "$WORK/v12"
# V12a used to assert rc==1 here. It could never discriminate: the EXIT trap normalises the
# 141 into 1, so the run dies mid-scan and STILL reports 1 — restoring the broken idiom in a
# scratch copy left V12a green while only V12b/V12c went red. Enlarging the fixture does not
# help either (it is already 169 KB, far past the 64 KB pipe buffer; SIGPIPE does fire). The
# honest discriminator is reaching the term-health line, which prints only after the whole
# term loop completes. A flaky assertion in a suite whose entire purpose is trustworthy gates
# is worse than no assertion.
assert_out_has "V12a: the term-health line proves every term was evaluated (#98)" "evaluated: 2"
assert_out_has "V12b: terms after the >10-hit term are still scanned" '"zulu"'
assert_out_has "V12c: the totals line is reached" "Total banned-language hits:"

# V13 (#90e) — the core ask: a term that can never match is a PARSE DEFECT, not
# compliance. Today its zero hits are indistinguishable from a clean surface.
mkproj "$WORK/v13" <<'EOF'
| "growth" (as a claim | UI | unbalanced qualifier, author typo | traction |
EOF
mkdir -p "$WORK/v13/src"
echo 'const ok = "hello";' > "$WORK/v13/src/ok.ts"
run_lint "$WORK/v13"
assert_rc      "V13a: an unmatchable term is non-green (#90e)" 1
assert_out_has "V13b: it is reported as a PARSE DEFECT" "PARSE DEFECT"
assert_out_has "V13c: the defective term is named" "growth (as a claim"

# V13d — zero-hit terms are reported per-term, distinguishing 'compliant' from
# 'could not match'. A well-formed term with no hits is real evidence.
mkproj "$WORK/v13b" <<'EOF'
| synergy | UI | generic pitch | collaboration |
EOF
mkdir -p "$WORK/v13b/src"
echo 'const ok = "hello";' > "$WORK/v13b/src/ok.ts"
run_lint "$WORK/v13b"
assert_rc      "V13d: a well-formed zero-hit term stays green" 0
assert_out_has "V13e: zero-hit terms are reported as compliant" "compliant"

# V14 (#98 finding 1) — the --staged scope globs were anchored at the repo root,
# so a monorepo laying out frontend/src/** matched ZERO staged files and exited 0
# green. Measured 0 of 1194 files in Splang, 0 of 590 in Streb.
#
# The any-depth resolution is correct and monorepos need it — but it cannot be the DEFAULT
# in a minor: it newly reaches files the team did not change, and a gate that was green in
# a downstream repo must not go red on the upgrade commit. So it ships behind
# `banned_language.scope: "any-depth"`, with legacy-root (the pre-9.6 root anchoring) as
# the default. Both modes are asserted here so the flip in v10 is a one-line default change
# against a suite that already covers the destination.
mkproj "$WORK/v14" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
init_git "$WORK/v14"
mkdir -p "$WORK/v14/frontend/src/components"
echo 'export const tagline = "revolutionize";' > "$WORK/v14/frontend/src/components/A.tsx"
(cd "$WORK/v14" && git add frontend specs .speck)
run_lint "$WORK/v14" --staged
assert_rc      "V14a: default scope=legacy-root keeps the pre-9.6 root anchoring" 0
assert_out_has "V14b: … and publishes the root-anchored scope it actually used" "SPECK_GATE_SCOPE=src/**"
set_scope "$WORK/v14" any-depth
run_lint "$WORK/v14" --staged
assert_rc      "V14c: scope=any-depth reaches frontend/src/** by path SEGMENT (#98.1)" 1
assert_out_has "V14d: telemetry reports the file it actually scanned" "SPECK_GATE_SUBJECT=1"
assert_out_has "V14e: … and publishes the any-depth scope" "SPECK_GATE_SCOPE=**/src/**"

# V15 (#90 secondary, #98 pairing) — broadening scope without an exclude mechanism
# newly convicts test files, including the vocabulary guard whose own regex
# literals ARE the banned words: the gate convicts its own guard.
mkproj "$WORK/v15" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
init_git "$WORK/v15"
mkdir -p "$WORK/v15/frontend/src"
echo 'export const tagline = "improve";' > "$WORK/v15/frontend/src/A.tsx"
echo 'it("bans revolutionize", () => expect(copy).not.toMatch(/revolutionize/));' \
  > "$WORK/v15/frontend/src/A.test.ts"
(cd "$WORK/v15" && git add frontend specs .speck)
set_scope "$WORK/v15" any-depth   # the exclude mechanism is what is under test, not the scope
run_lint "$WORK/v15" --staged
assert_rc      "V15a: **/*.test.* is excluded by default — the guard is not convicted" 0
assert_out_has "V15b: telemetry counts only the non-excluded file" "SPECK_GATE_SUBJECT=1"

# V15c/d — --exclude-glob flag, and the same list from .speck/project.json.
mkproj "$WORK/v15c" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v15c/src/legacy"
echo 'const old = "revolutionize";' > "$WORK/v15c/src/legacy/old.ts"
run_lint "$WORK/v15c"
assert_rc "V15c: without --exclude-glob the legacy file is convicted" 1
run_lint "$WORK/v15c" --exclude-glob '**/legacy/**'
assert_rc "V15d: --exclude-glob suppresses it" 0
cat > "$WORK/v15c/.speck/project.json" <<'EOF'
{"project_id":"test","play_level":"sprint","banned_language":{"exclude":["**/legacy/**"]}}
EOF
run_lint "$WORK/v15c"
assert_rc "V15e: banned_language.exclude in project.json does the same" 0

# V16 (#98 §4) — the gate output contract. Every exit path publishes the scope it
# actually used and the subject count it actually inspected, so a consumer never
# has to re-derive scope from a second hardcoded list (the correlated blind spot
# that made #88's own canary unable to see finding 1).
run_lint "$WORK"                       # no product-contract.md anywhere above → exit 2
assert_rc      "V16a: the invocation-error path still exits 2" 2
assert_out_has "V16b: … and still publishes SPECK_GATE_SCOPE" "SPECK_GATE_SCOPE="
assert_out_has "V16c: … and SPECK_GATE_PREDICATES" "SPECK_GATE_PREDICATES=0"

mkproj "$WORK/v16d" </dev/null       # §7 present, zero rows
mkdir -p "$WORK/v16d/src"
echo 'const ok = "hello";' > "$WORK/v16d/src/ok.ts"
run_lint "$WORK/v16d"
assert_out_has "V16d: an empty §7 publishes PREDICATES=0 (vacuity is a dead predicate set)" \
  "SPECK_GATE_PREDICATES=0"

mkproj "$WORK/v16e" <<'EOF'
| synergy | UI | generic pitch | collaboration |
EOF
init_git "$WORK/v16e"
(cd "$WORK/v16e" && echo ok > README.md && git add README.md)
run_lint "$WORK/v16e" --staged
assert_rc      "V16e: --staged with no in-scope staged files is still green" 0
assert_out_has "V16f: … and says so honestly with SUBJECT=0" "SPECK_GATE_SUBJECT=0"
assert_out_has "V16g: … while PREDICATES proves the term set was not dead" "SPECK_GATE_PREDICATES=1"

# V17 (#90/#98) — with no product dir the full scan fell back to WORKSPACE_ROOT and
# convicted Speck's own .speck/ templates and recipes: 4025 hits for "plan" on one
# repo, top hits being story-retro-template.md and AGENTS.md.
mkproj "$WORK/v17" <<'EOF'
| synergy | UI | generic pitch | collaboration |
EOF
mkdir -p "$WORK/v17/.speck/templates" "$WORK/v17/node_modules/pkg" "$WORK/v17/docs"
echo 'Template prose about synergy in a Speck template.' > "$WORK/v17/.speck/templates/x.md"
echo 'export const synergy = 1;' > "$WORK/v17/node_modules/pkg/index.js"
echo 'plain docs, nothing banned here' > "$WORK/v17/docs/readme.md"
run_lint "$WORK/v17"
assert_rc      "V17a: the fallback scan does not convict .speck/ or node_modules/" 0
assert_out_has "V17b: fallback scope is published, not inferred" "SPECK_GATE_SCOPE="

# W — the lint-staged wrapper. It calls the lint as `"" file1 file2 …`, an empty
# placeholder standing in for the auto-located project dir. With lint-staged's file list
# EMPTY the wrapper used to hand rg a "" path; once that placeholder is shifted off, the
# invocation degenerates into the no-targets branch and silently escalates a diff-scoped
# pre-commit check into a FULL-REPO scan. Neither is acceptable: the gate must inspect the
# files it was handed, and nothing else.
WRAP="$SCRIPT_DIR/banned-language-lint-staged.sh"
run_wrap() { # <dir> [args...]
  local dir="$1"; shift
  set +e
  LAST_OUT="$(cd "$dir" && bash "$WRAP" "$@" 2>&1)"
  LAST_RC=$?
  set -e
}

mkproj "$WORK/w1" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/w1/frontend/src"
echo 'export const tagline = "revolutionize";' > "$WORK/w1/frontend/src/A.tsx"
run_wrap "$WORK/w1" frontend/src/A.tsx
assert_rc      "W1a: the wrapper scans the file paths it is handed" 1
assert_out_has "W1b: … and publishes them as the scope" "SPECK_GATE_SCOPE=frontend/src/A.tsx"

mkproj "$WORK/w2" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
init_git "$WORK/w2"
mkdir -p "$WORK/w2/frontend/src"
echo 'export const tagline = "revolutionize";' > "$WORK/w2/frontend/src/A.tsx"   # NOT staged
(cd "$WORK/w2" && echo ok > README.md && git add README.md)
run_wrap "$WORK/w2"
assert_rc        "W2a: the wrapper with no file list does not escalate to a full-repo scan" 0
assert_out_has   "W2b: … and reports an honest empty subject" "SPECK_GATE_SUBJECT=0"
assert_out_lacks "W2c: … so an unstaged file is never convicted" '"revolutionize"'
assert_out_has   "W2d: … while PREDICATES proves the term set is alive" "SPECK_GATE_PREDICATES=1"

# W3 (R-A P0-1, the second door) — the wrapper IS Speck's documented pre-commit surface:
# .speck/patterns/constitution-as-code.md tells teams to wire it into Husky/lint-staged. With
# a file list it takes the explicit-targets path, NOT --staged, so making only --staged's
# parse-defect exit advisory left one typo'd §7 row still blocking every commit in any repo
# that followed the documented pattern. The mode has to travel with the invocation, not with
# the flag that happens to select the file set.
mkproj "$WORK/w3" <<'EOF'
| "growth" (as a claim | UI | unbalanced qualifier, author typo | traction |
EOF
mkdir -p "$WORK/w3/src"
echo 'export const ok = "hello";' > "$WORK/w3/src/ok.ts"
run_wrap "$WORK/w3" src/ok.ts
assert_rc      "W3a: a §7 typo does not block a lint-staged commit either" 0
assert_out_has "W3b: … while the 🧨 diagnostic still prints in full" "PARSE DEFECT"
run_lint "$WORK/w3" "$WORK/w3/specs/projects/test" src/ok.ts
assert_rc      "W3c: … but the same explicit-target run without the flag (CI) still exits 1" 1

# G — the rg branch and the grep fallback must agree. #85 landed because they did not:
# the fast branch scanned a subset and reported green while the fallback would have
# caught the term. Re-run the same tree with rg removed from PATH and diff the verdicts.
#
# The fixture is a REAL git repo with a .gitignore covering a file under a scope dir. The
# old fixture never ran `git init`, so rg's ignore logic never engaged and the differential
# could not see the one thing that still divided the branches: `rg --files` honours
# .gitignore and `find` does not. Measured on that tree — rg: SUBJECT=1, exit 0; grep:
# SUBJECT=2, exit 1. The gate's verdict depended on whether ripgrep happened to be
# installed, under a test that claimed #85 was closed.
mkproj "$WORK/g1" <<'EOF'
| "sett" (Norwegian for rep/set) | UI | Norwegian leak | rep |
| revolutionize | UI | hype verb | improve |
EOF
init_git "$WORK/g1"
mkdir -p "$WORK/g1/src/generated" "$WORK/g1/.speck/templates"
echo 'const s = "sett"; const t = "revolutionize";' > "$WORK/g1/src/A.tsx"
echo 'template prose about revolutionize' > "$WORK/g1/.speck/templates/x.md"
echo 'generated/' > "$WORK/g1/.gitignore"
echo 'const g = "revolutionize";' > "$WORK/g1/src/generated/gen.ts"
if command -v rg >/dev/null 2>&1; then
  assert_branches_agree "G1: rg branch and grep fallback agree on a gitignored file (#85)" "$WORK/g1"
else
  echo "SKIP: G1 — ripgrep not installed, the differential has only one branch to compare"
fi

# G2 — the same differential in the any-depth resolver, so the v10 default flip does not
# reopen #85 in the mode nobody had exercised.
mkproj "$WORK/g2" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
init_git "$WORK/g2"
set_scope "$WORK/g2" any-depth
mkdir -p "$WORK/g2/frontend/src/generated"
echo 'const t = "improve";' > "$WORK/g2/frontend/src/A.tsx"
echo 'generated/' > "$WORK/g2/.gitignore"
echo 'const g = "revolutionize";' > "$WORK/g2/frontend/src/generated/gen.ts"
if command -v rg >/dev/null 2>&1; then
  assert_branches_agree "G2: … and they agree under scope=any-depth too" "$WORK/g2"
else
  echo "SKIP: G2 — ripgrep not installed"
fi

# ─────────────────────────────────────────────────────────────────────────────────
# v9.6 adversarial review — the defects the chokepoint work introduced.
# ─────────────────────────────────────────────────────────────────────────────────

# V18 — a malformed §7 row must not make the repo UNCOMMITTABLE.
# PARSE_DEFECTS is computed from the CONTRACT, before any file is scanned, and the tail
# fired independently of GATE_SUBJECT. So a docs-only commit in a repo with one typo'd §7
# row printed "Files in scan scope: 0", "✅ No staged product-surface files", and then
# exited 1 — and validation/pre-commit-hook.sh turns that into a rejected commit. One field
# project measured 12 of 64 rows malformed: on the upgrade commit itself, with no migration
# and no opt-out, that repo could not commit at all — including the commit that would FIX
# the rows. The diagnostic is right and stays verbatim; the EXIT is what has to be
# mode-aware. Pre-commit advises, the full scan / CI enforces.
mkproj "$WORK/v18" <<'EOF'
| "growth" (as a claim | UI | unbalanced qualifier, author typo | traction |
EOF
init_git "$WORK/v18"
mkdir -p "$WORK/v18/docs"
echo 'plain docs, nothing banned here' > "$WORK/v18/docs/readme.md"
(cd "$WORK/v18" && git add docs specs .speck)
run_lint "$WORK/v18" --staged
assert_rc      "V18a: a §7 typo does not block a commit that touches zero product files" 0
assert_out_has "V18b: … while the 🧨 diagnostic still prints in full" "PARSE DEFECT"
assert_out_has "V18c: … the term is still named" "growth (as a claim"
assert_out_has "V18d: … and the empty subject is still reported honestly" "Files in scan scope: 0"
run_lint "$WORK/v18"
assert_rc      "V18e: the full-scan / CI invocation still exits 1 on the same typo" 1

# V19 — v9.6 broadened the scan to product-surface dirs at ANY depth AND scans whole files
# with no user-visible-string filter. Those two together convict ordinary code using Speck's
# OWN shipped default terms: product-contract-template.md §7 ships
#   - ❌ Technical architecture language ("our backend", "API", "database")
# and the phrase-class extractor pulls each quoted phrase. On a monorepo,
# frontend/src/lib/client.ts holding `import { createClient } from "./api"` scored exit 0
# before the change and ❌ "API" — 4 hit(s), exit 1 after it. The team changed none of that
# code. So the any-depth resolver ships opt-in for one minor; the implementation is right
# and stays whole.
mkproj "$WORK/v19" <<'EOF'
| synergy | UI | generic pitch | collaboration |
EOF
cat >> "$WORK/v19/specs/projects/test/product-contract.md" <<'EOF'

### Banned Phrase Classes (categorical)

- ❌ Technical architecture language ("our backend", "API", "database") in user-facing surfaces
EOF
mkdir -p "$WORK/v19/src" "$WORK/v19/frontend/src/lib"
echo 'export const ok = "hello";' > "$WORK/v19/src/ok.ts"
printf 'import { createClient } from "./api";\nconst database = createClient();\n' \
  > "$WORK/v19/frontend/src/lib/client.ts"
run_lint "$WORK/v19"
assert_rc        "V19a: default scope=legacy-root does not newly convict deep dirs" 0
assert_out_lacks "V19b: … so the team's untouched client.ts stays untouched" '"API"'
assert_out_has   "V19c: … and the published scope names the mode that ran" "SPECK_GATE_SCOPE=src/**"
set_scope "$WORK/v19" any-depth
run_lint "$WORK/v19"
assert_rc      "V19d: scope=any-depth opts in to the monorepo-correct resolution" 1
assert_out_has "V19e: … and frontend/src/** is then reached" '"API"'

# V19f — an unrecognised scope value must not silently pick a mode. Warn, keep the default.
set_scope "$WORK/v19" everywhere
run_lint "$WORK/v19"
assert_rc      "V19f: an unrecognised banned_language.scope falls back to the default" 0
assert_out_has "V19g: … loudly, never silently" "not recognised"

# V20 — DEFAULT_EXCLUDES exists so the gate does not convict its own guard: a test file
# holds assertions that a banned word is ABSENT, and a vocabulary guard whose regex literals
# ARE the banned words. It only knew JS/TS spellings, so the moment v9.6 broadened what gets
# scanned, that self-conviction went live for every other language Speck ships a recipe for
# — django-htmx, go-templ-htmx, expo-fastapi, react-fastapi-postgres.
mkproj "$WORK/v20" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v20/src/__mocks__" "$WORK/v20/app/e2e" "$WORK/v20/app/tests"
echo 'export const t = "improve";' > "$WORK/v20/src/ok.ts"
echo 'def test_copy(): assert "revolutionize" not in COPY' > "$WORK/v20/app/tests.py"
echo 'def test_views(): assert "revolutionize" not in COPY' > "$WORK/v20/app/test_views.py"
echo 'func TestCopy(t *testing.T) { want := "revolutionize" }' > "$WORK/v20/src/foo_test.go"
echo 'class FooTest { String banned = "revolutionize"; }' > "$WORK/v20/src/FooTest.java"
echo 'RSpec.describe "revolutionize" do end' > "$WORK/v20/src/x_spec.rb"
echo 'export const api = "revolutionize";' > "$WORK/v20/src/__mocks__/api.ts"
echo 'test("revolutionize", () => {});' > "$WORK/v20/app/e2e/flow.ts"
echo 'BANNED = ["revolutionize"]' > "$WORK/v20/app/tests/vocabulary.py"
run_lint "$WORK/v20"
assert_rc        "V20a: Python/Go/Java/Ruby/mock/e2e guards are excluded by default" 0
assert_out_lacks "V20b: … so the gate does not convict its own guard outside JS/TS" '"revolutionize"'
assert_out_has   "V20c: … and the one real product file is still the subject" "SPECK_GATE_SUBJECT=1"

# V21 — DENY_SEGMENTS is the same "do not convict what you do not own" rule applied to
# VENDORED trees. A Python .venv, CocoaPods, a Rust/Java target/, an Xcode DerivedData all
# carry third-party `src` dirs; once the resolver walks at any depth it finds them, and
# Speck starts linting other people's prose. Asserted on BOTH branches — the deny list is
# consumed by find_scope_dirs and by the find fallback, and rg has its own glob list.
mkproj "$WORK/v21" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
set_scope "$WORK/v21" any-depth
mkdir -p "$WORK/v21/src" "$WORK/v21/.venv/lib/python3.12/site-packages/pkg/src" \
         "$WORK/v21/Pods/Lib/src" "$WORK/v21/target/debug/src" "$WORK/v21/coverage/src"
echo 'export const t = "improve";' > "$WORK/v21/src/ok.ts"
echo 'DESC = "revolutionize your workflow"' \
  > "$WORK/v21/.venv/lib/python3.12/site-packages/pkg/src/mod.py"
echo 'let s = "revolutionize";' > "$WORK/v21/Pods/Lib/src/a.swift"
echo 'const s = "revolutionize";' > "$WORK/v21/target/debug/src/gen.rs"
echo 'const s = "revolutionize";' > "$WORK/v21/coverage/src/report.js"
run_lint "$WORK/v21"
assert_rc      "V21a: a vendored src/ under .venv/Pods/target/coverage is never scanned" 0
assert_out_has "V21b: … and only the real product file is the subject" "SPECK_GATE_SUBJECT=1"
run_lint_nrg "$WORK/v21"
assert_rc      "V21c: … and the grep fallback prunes exactly the same trees" 0
assert_out_has "V21d: … down to the same subject count" "SPECK_GATE_SUBJECT=1"

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
