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

# V5c: framework/Sprint repositories may have no product contract. A staged
# gate has no banned-term producer in that state, so it must report explicit
# non-applicability instead of blocking every commit as an invocation error.
mkdir -p "$WORK/no-contract/.speck"
init_git "$WORK/no-contract"
(
  cd "$WORK/no-contract"
  echo "framework runtime" > .speck/README.md
  git add .speck/README.md
)
assert_ok "V5c: --staged without a product contract is explicitly not applicable" \
  bash -c "cd '$WORK/no-contract' && out=\$(bash '$LINT' --staged) && grep -q 'not applicable' <<<\"\$out\" && grep -q 'SPECK_GATE_SCOPE=not-applicable:no-product-contract' <<<\"\$out\""

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
#
# The fixture used to be a bare sentence in a .ts file — `We deliver synergy for teams`,
# no quotes. That is not TypeScript, and from v10 the gate reads user-visible strings
# rather than whole files, so the sentence is (correctly) a syntax error's worth of bare
# identifiers, not copy. Held as real code, the assertion keeps testing what it names:
# that a staged product-surface file is reached at all.
write_product_contract "$WORK/staged-product"
init_git "$WORK/staged-product"
(
  cd "$WORK/staged-product"
  mkdir -p src
  echo 'export const marketing = "We deliver synergy for teams";' > src/marketing.ts
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
# v9.6 shipped the any-depth resolution OPT-IN, because reaching frontend/src/** while
# scanning whole files newly convicted untouched code (see V19). v10 removes that cause and
# flips the default: the blindness is the more serious defect once the false convictions are
# gone. Both directions are asserted — the default must reach the monorepo, and an explicit
# `legacy-root` must still reproduce the pre-9.6 anchoring for a repo that wants it.
mkproj "$WORK/v14" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
init_git "$WORK/v14"
mkdir -p "$WORK/v14/frontend/src/components"
echo 'export const tagline = "revolutionize";' > "$WORK/v14/frontend/src/components/A.tsx"
(cd "$WORK/v14" && git add frontend specs .speck)
run_lint "$WORK/v14" --staged
assert_rc      "V14a: the v10 DEFAULT reaches frontend/src/** by path SEGMENT (#98.1)" 1
assert_out_has "V14b: … and publishes the any-depth scope it actually used" "SPECK_GATE_SCOPE=**/src/**"
assert_out_has "V14c: … having actually inspected the staged file" "SPECK_GATE_SUBJECT=1"
set_scope "$WORK/v14" legacy-root
run_lint "$WORK/v14" --staged
assert_rc      "V14d: banned_language.scope=legacy-root restores the pre-9.6 root anchoring" 0
assert_out_has "V14e: … and publishes it, so that green is legible as blindness" "SPECK_GATE_SCOPE=src/**"
assert_out_has "V14f: … with an honestly empty subject" "SPECK_GATE_SUBJECT=0"
set_scope "$WORK/v14" any-depth
run_lint "$WORK/v14" --staged
assert_rc      "V14g: an explicit any-depth is honoured identically to the default" 1

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

# PDR1 (L11.3) — a repo that HAS declared itself a Speck project (`.speck/project.json`
# exists) but whose specs/projects/*/product-contract.md cannot be located (renamed
# specs/projects/, or the contract briefly deleted mid-regen) must not read the same as
# V5c's legitimate "framework repo, nothing to lint" state. --staged used to print the
# same green "not applicable" / SPECK_GATE_SCOPE=not-applicable:no-product-contract in
# both cases, silently disabling the blocking pre-commit gate.
mkdir -p "$WORK/pdr1/.speck" "$WORK/pdr1/specs/product-projects/test"
echo '{"project_id":"test","play_level":"sprint"}' > "$WORK/pdr1/.speck/project.json"
init_git "$WORK/pdr1"
(cd "$WORK/pdr1" && echo ok > README.md && git add README.md)
run_lint "$WORK/pdr1" --staged
assert_rc        "PDR1a: --staged with a declared project.json but no locatable contract fails loud" 2
assert_out_lacks "PDR1b: … and does NOT claim 'not applicable' (that is V5c's state, not this one)" \
  "not applicable"

# PDR2 (L11.4) — two projects, each with its own product-contract.md, at the same
# specs/projects/ level. The old `echo "$cur"/specs/projects/*/ | head -n1` collapsed both
# matches onto one space-joined line, `[[ -d ]]` correctly rejected it, and --staged read
# the resolution failure as "no product-contract.md declared" → green pass, exit 0 — the
# blocking pre-commit gate linted nothing for every multi-project repo.
write_product_contract "$WORK/pdr2"
mv "$WORK/pdr2/specs/projects/test" "$WORK/pdr2/specs/projects/alpha"
mkdir -p "$WORK/pdr2/specs/projects/beta"
cp "$WORK/pdr2/specs/projects/alpha/product-contract.md" "$WORK/pdr2/specs/projects/beta/product-contract.md"
rm -f "$WORK/pdr2/.speck/project.json"
init_git "$WORK/pdr2"
(cd "$WORK/pdr2" && echo ok > README.md && git add README.md)
run_lint "$WORK/pdr2" --staged
assert_rc        "PDR2a: --staged with two ambiguous project contracts fails loud, not green" 2
assert_out_lacks "PDR2b: … and does NOT claim 'not applicable' (a contract WAS declared — twice)" \
  "not applicable"

# PDR2c — the same ambiguity resolves deterministically when .speck/project.json names an
# active project, exactly as profile-lib.sh's profile_resolve_project_id does. rc==0 alone
# does not discriminate this from the old bug (that ALSO exited 0, via the false
# "not applicable" branch) — assert the real project dir was found and scanned.
echo '{"active_project":"beta"}' > "$WORK/pdr2/.speck/project.json"
run_lint "$WORK/pdr2" --staged
assert_rc        "PDR2c: active_project in .speck/project.json disambiguates the pair" 0
assert_out_has   "PDR2d: … the resolved project dir is the named one, beta" \
  "specs/projects/beta"
assert_out_lacks "PDR2e: … not a silent 'not applicable' fallback" "not applicable"

# PDR3 — a single real project plus an unrelated sibling directory with no contract of its
# own (an archived project, a scratch dir) must still resolve — one project plus ANY
# sibling was enough to trip the old bug, no second project.json required. Same
# discrimination need as PDR2c: assert the real project was found, not just rc==0.
write_product_contract "$WORK/pdr3"
mkdir -p "$WORK/pdr3/specs/projects/archived-beta"
init_git "$WORK/pdr3"
(cd "$WORK/pdr3" && echo ok > README.md && git add README.md)
run_lint "$WORK/pdr3" --staged
assert_rc      "PDR3a: a contract-less sibling directory does not break resolution" 0
assert_out_has "PDR3b: … the real project dir was found and scanned" \
  "specs/projects/test"

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
# project-constitution may wire it into Husky/lint-staged. With
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

# V19 — THE ACCEPTANCE TEST FOR THE v10 DEFAULT FLIP. Both halves live in ONE fixture,
# because either one alone is satisfiable by a gate that is simply wrong in the other
# direction: a gate that never convicts passes (a), a gate that convicts everything
# passes (b).
#
# The exact v9.6 counter-example. Speck's OWN shipped product-contract-template.md §7 has
#   - ❌ Technical architecture language ("our backend", "API", "database")
# and the phrase-class extractor pulls each quoted phrase, scanned -i -w -F. With whole-file
# scanning, `frontend/src/lib/client.ts` holding `import { createClient } from "./api"` went
# from exit 0 to ❌ "API" — 4 hit(s), exit 1, on code the team never wrote that week. That
# single false-conviction class is the entire reason any-depth shipped opt-in.
#
# v10 fixes the CAUSE: hits are filtered through a per-file visibility mask, so an import
# specifier is not copy and an identifier named `database` is not copy. The reach is then
# safe to make the default — which is what (b) has to keep honest.
mkproj "$WORK/v19" <<'EOF'
| synergy | UI | generic pitch | collaboration |
EOF
cat >> "$WORK/v19/specs/projects/test/product-contract.md" <<'EOF'

### Banned Phrase Classes (categorical)

- ❌ Technical architecture language ("our backend", "API", "database") in user-facing surfaces
EOF
mkdir -p "$WORK/v19/src" "$WORK/v19/frontend/src/lib" "$WORK/v19/frontend/src/components"
echo 'export const ok = "hello";' > "$WORK/v19/src/ok.ts"
printf 'import { createClient } from "./api";\nconst database = createClient();\nexport const client = database;\n' \
  > "$WORK/v19/frontend/src/lib/client.ts"

# (a) the counter-example, under the DEFAULT scope, must be green.
run_lint "$WORK/v19"
assert_rc        "V19a: the v9.6 counter-example exits 0 under the v10 default" 0
assert_out_lacks "V19b: … the import specifier \"./api\" is not user-visible copy" '"API"'
assert_out_lacks "V19c: … nor is an identifier named database" '"database"'
assert_out_has   "V19d: … and it was NOT green by blindness — frontend/src was reached" "SPECK_GATE_SCOPE=**/src/**"
assert_out_has   "V19e: … with client.ts actually among the files inspected" "SPECK_GATE_SUBJECT=2"
assert_out_has   "V19f: … and nothing fell back to a whole-file read" "SPECK_GATE_UNPARSED=0"

# (b) genuine user-visible copy in the SAME tree must still exit 1.
echo 'export const banner = "Our backend is slow — check the API status";' \
  > "$WORK/v19/frontend/src/components/Banner.tsx"
run_lint "$WORK/v19"
assert_rc      "V19g: genuine copy in the same tree still exits 1" 1
assert_out_has "V19h: … \"API\" inside a real string literal is convicted" '"API"'
assert_out_has "V19i: … and so is the multi-word phrase class" '"our backend"'

# (c) the mask is the load-bearing part, not the scope. Turn it off on the same tree and
# the false conviction comes straight back — the discriminator that keeps V19a from being
# satisfiable by a gate that simply stopped reaching frontend/src.
run_lint "$WORK/v19" --no-strings-only
assert_out_has "V19j: --no-strings-only reproduces the v9.6 false conviction on client.ts" 'client.ts'
assert_out_has "V19k: … proving the visibility mask, not the scope, is what made it green" "SPECK_GATE_FILTER=whole-file"

# V19l — an unrecognised scope value must not silently pick a mode. Warn, keep the default.
rm -f "$WORK/v19/frontend/src/components/Banner.tsx"
set_scope "$WORK/v19" everywhere
run_lint "$WORK/v19"
assert_rc      "V19l: an unrecognised banned_language.scope falls back to the default" 0
assert_out_has "V19m: … loudly, never silently" "not recognised"

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

# ─────────────────────────────────────────────────────────────────────────────────
# v10 — --strings-only. The precondition for the any-depth default (V19), asserted on
# its own terms: what the mask reveals, what it hides, and what it admits it cannot read.
# ─────────────────────────────────────────────────────────────────────────────────

# V22 — locale files: scan VALUES, never keys. `revolutionize_button_label` is an
# identifier a translator never sees; the string it points at is the copy.
mkproj "$WORK/v22" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v22/src/locales"
cat > "$WORK/v22/src/locales/en.json" <<'EOF'
{
  "revolutionize_button_label": "Improve your day",
  "hero": { "revolutionize": "Make it better" }
}
EOF
run_lint "$WORK/v22"
assert_rc        "V22a: a banned word in a locale KEY is not a violation" 0
assert_out_lacks "V22b: … it is never reported" '"revolutionize"'
assert_out_has   "V22c: … and the locale file was genuinely read, not skipped" "SPECK_GATE_SUBJECT=1"
cat > "$WORK/v22/src/locales/en.json" <<'EOF'
{
  "hero_title": "We revolutionize teams"
}
EOF
run_lint "$WORK/v22"
assert_rc      "V22d: the same word in the VALUE is a violation" 1
assert_out_has "V22e: … reported once" "Total banned-language hits: 1"

# V22f — YAML locales take the same rule.
mkproj "$WORK/v22y" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v22y/src/i18n"
# The key is the BARE banned word, not `revolutionize_cta`: grep -w treats "_" as a word
# character, so a suffixed key would never have matched and the assertion would pass on a
# filter that does nothing at all.
printf 'en:\n  revolutionize: Improve your day\n  # revolutionize in a comment\n' \
  > "$WORK/v22y/src/i18n/en.yaml"
run_lint "$WORK/v22y"
assert_rc "V22f: a YAML key and a YAML comment are not copy" 0
printf 'en:\n  cta: We revolutionize teams\n' > "$WORK/v22y/src/i18n/en.yaml"
run_lint "$WORK/v22y"
assert_rc "V22g: … while the YAML value is" 1

# V23 — source files: identifiers, imports, comments and type names are not copy;
# string literals, template literals and JSX text are.
mkproj "$WORK/v23" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v23/src"
# Every line here is a DIFFERENT control point, chosen so no single rule masks another:
#   line 1  comment stripping ALONE — the term is written inside QUOTES in the comment, so
#           without stripping it lexes as a real string literal. `// revolutionize later`
#           would have proved nothing: bare words in a comment are already invisible for
#           being outside a string, and the assertion would survive deleting the rule.
#   line 2  the module-specifier rule ALONE — a bare package name carries no "/" and no
#           leading ".", so the technical-token rule cannot rescue it
#   line 3  the mask itself (a type name is never inside a string)
#   line 4  the mask itself (an identifier)
#   line 5  the technical-token rule ALONE — a route string is a string literal, and only
#           "no whitespace + a path separator" keeps it out of the copy set
cat > "$WORK/v23/src/machinery.ts" <<'EOF'
// TODO: replace "revolutionize" with "improve"
import { revolutionize } from "revolutionize";
type Revolutionize = { revolutionize: string };
const revolutionize_count = 1;
export const endpoint = "/revolutionize/v1";
EOF
run_lint "$WORK/v23"
assert_rc        "V23a: comments, module specifiers, type names, identifiers and routes are not copy" 0
assert_out_lacks "V23b: … none of them is reported" '"revolutionize"'
assert_out_has   "V23c: … and the file was lexed, not waved through" "SPECK_GATE_UNPARSED=0"

cat > "$WORK/v23/src/copy.tsx" <<'EOF'
export const Hero = () => <p>We revolutionize teams</p>;
EOF
run_lint "$WORK/v23"
assert_rc      "V23d: a JSX text node IS copy" 1
assert_out_has "V23e: … reported from the .tsx surface" "copy.tsx"

rm -f "$WORK/v23/src/copy.tsx"
printf 'export const t = `We revolutionize ${teams}`;\n' > "$WORK/v23/src/tpl.ts"
run_lint "$WORK/v23"
assert_rc "V23f: a template literal IS copy" 1

# V24 — the honesty half. A file the lexer does not model is scanned WHOLE (pre-v10
# behaviour, so the mode cannot create a blind spot) AND counted, so a caller can see
# how much of a green rests on the mask. Silently skipping it, or silently scanning it
# whole, are the two failures this release exists to end.
mkproj "$WORK/v24" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v24/src"
echo 'export const ok = "hello";' > "$WORK/v24/src/ok.ts"
echo 'weird-format: revolutionize' > "$WORK/v24/src/config.xyzzy"
run_lint "$WORK/v24"
assert_rc      "V24a: an unlexable file is still SCANNED, not skipped" 1
assert_out_has "V24b: … and the telemetry counts it as unparsed" "SPECK_GATE_UNPARSED=1"
assert_out_has "V24c: … and names it in the human output" "config.xyzzy"
assert_out_has "V24d: … alongside the file that WAS lexed" "SPECK_GATE_SUBJECT=2"

# V25 — the escape hatch, both spellings, and the mode published either way.
mkproj "$WORK/v25" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v25/src"
echo 'const revolutionize = 1;' > "$WORK/v25/src/a.ts"
run_lint "$WORK/v25"
assert_rc      "V25a: an identifier is green under the default" 0
assert_out_has "V25b: … and the mode is published" "SPECK_GATE_FILTER=strings-only"
run_lint "$WORK/v25" --no-strings-only
assert_rc      "V25c: --no-strings-only restores the pre-v10 whole-file read" 1
assert_out_has "V25d: … and publishes THAT mode" "SPECK_GATE_FILTER=whole-file"
cat > "$WORK/v25/.speck/project.json" <<'EOF'
{"project_id":"test","play_level":"sprint","banned_language":{"strings_only":false}}
EOF
run_lint "$WORK/v25"
assert_rc      "V25e: banned_language.strings_only=false does the same from config" 1
run_lint "$WORK/v25" --strings-only
assert_rc      "V25f: … and the flag still outranks the config" 0

# V26/V27 — the filter is a load-bearing dependency, not a decoration. When it cannot run,
# an EMPTY result reads as "term compliant": a crashing filter used to render the whole gate
# green. It is an invocation error now.
#
# The lint calls the filter on TWO paths — once for --parse-report, then once per term — and
# they must be pinned SEPARATELY. A single fixture whose filter dies on everything only ever
# reaches the first one, so the per-term guard could be deleted and the assertion stay green.
# V27's stub therefore answers --parse-report correctly and dies only on a term.
mk_broken_filter_rig() { # <dir> <python-body-file-content>
  local d="$1" body="$2"
  mkdir -p "$d/fakebin/lib"
  cp "$SCRIPT_DIR/banned-language-lint.sh" "$d/fakebin/lint.sh"
  cp "$SCRIPT_DIR/lib/text.sh" "$d/fakebin/lib/text.sh"
  printf '%s' "$body" > "$d/fakebin/filter-forbidding-context.py"
}
run_rig() { # <dir>
  set +e
  LAST_OUT="$(cd "$1" && bash "$1/fakebin/lint.sh" 2>&1)"
  LAST_RC=$?
  set -e
}

mkproj "$WORK/v26" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v26/src"
echo 'export const t = "revolutionize";' > "$WORK/v26/src/a.ts"
mk_broken_filter_rig "$WORK/v26" 'import sys
sys.stderr.write("boom\n")
raise SystemExit(3)
'
run_rig "$WORK/v26"
assert_rc      "V26a: a filter that cannot report parse status is an invocation error" 2
assert_out_has "V26b: … rather than an unbacked SPECK_GATE_UNPARSED=0" "could not report parse status"

# V27 — the per-term call, isolated: --parse-report succeeds, the term call dies.
mkproj "$WORK/v27" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
mkdir -p "$WORK/v27/src"
echo 'export const t = "revolutionize";' > "$WORK/v27/src/a.ts"
mk_broken_filter_rig "$WORK/v27" 'import sys
if "--parse-report" in sys.argv:
    for ln in sys.stdin.read().splitlines():
        if ln.strip():
            print("strings\t" + ln.strip())
    raise SystemExit(0)
sys.stderr.write("boom on a term\n")
raise SystemExit(3)
'
run_rig "$WORK/v27"
assert_rc        "V27a: a hit filter that dies on a TERM is an invocation error too" 2
assert_out_has   "V27b: … naming the filter it refused to proceed without" "hit filter"
assert_out_lacks "V27c: … and never prints the green it would have inherited" "No banned-language violations found"

# ─────────────────────────────────────────────────────────────────────────────────
# V29–V31 (#98.2) — the two mechanisms that turned a real downstream repo RED under the
# v10 any-depth default, on code the team did not write.
#
#   REAL EXIT=1 · ❌ "QA" — 58 hit(s) · SUBJECT=230 · UNPARSED=142
#   …/android/app/.cxx/Debug/…/components/Props.cpp.o: binary file matches
#
#   1. `app` is a SCOPE_SEGMENT, so `android/app/**` became a scope ROOT — and the CMake
#      object cache under it, `android/app/.cxx/**`, contains directories literally named
#      `src` and `components`, which became scope roots of their own (~30 of them).
#   2. rg's binary-match line carries NO `:line:`, and the visibility mask is applied PER
#      LINE. 142 of 230 subject files were therefore read WHOLE — 62% of a scan reporting
#      SPECK_GATE_FILTER=strings-only.
#
# THE FIXTURE IS DERIVED FROM THE SHIPPED TEMPLATE. Every other fixture in this file
# invents a one-row §7, and that is structurally why 12 mutations and 107 assertions never
# saw this class: nobody writes "QA" into a hand-typed fixture. It arrives in
# product-contract-template.md's OWN boilerplate —
#     - ❌ QA/simulator/evidence language ("test mode", "QA", "fixture", "simulator")
# — so every project generated from the template carries it, and a fixture that omits the
# boilerplate cannot reproduce what the shipped template actually produces.
TEMPLATE_PC="$SCRIPT_DIR/../templates/project/product-contract-template.md"
TEMPLATE_CLASSES="$(awk '
  /^### Banned Phrase Classes/ { in_s=1; print; next }
  /^### / && in_s { in_s=0 }
  in_s { print }
' "$TEMPLATE_PC" 2>/dev/null || true)"

if ! grep -qF '"QA"' <<<"$TEMPLATE_CLASSES"; then
  # Not a skip. A fixture that silently degrades to hand-typed terms is the defect.
  _bad "V29-pre: could not read the shipped Banned Phrase Classes out of $TEMPLATE_PC"
else
  _ok "V29-pre: the fixture's §7 is the SHIPPED template's boilerplate, not hand-typed"

  # V29 — a nested build cache under a product-surface segment. The dot-directory is named
  # `.buildcache`, NOT `.cxx`: `.cxx` is in DENY_SEGMENTS for speed, and a fixture that used
  # it would stay green with the general rule deleted. The SHAPE is what is under test.
  mkproj "$WORK/v29" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
  printf '\n%s\n' "$TEMPLATE_CLASSES" >> "$WORK/v29/specs/projects/test/product-contract.md"
  CACHE="$WORK/v29/android/app/.buildcache/Debug/arm64-v8a/CMakeFiles/appmodules.dir"
  mkdir -p "$WORK/v29/android/app/src/main/java/com/x" \
           "$CACHE/react/renderer/components" "$CACHE/_CMakeLTOTest/src"
  echo 'public class App { String s = "Improve your day"; }' \
    > "$WORK/v29/android/app/src/main/java/com/x/App.java"
  # Text copy inside the cache, in dirs named `components` and `src` — the two segments
  # that made ~30 cache directories into scope roots on the real repo.
  echo 'static const char *k = "QA fixture in test mode";' \
    > "$CACHE/react/renderer/components/Props.cpp"
  echo 'static const char *g = "simulator";' > "$CACHE/_CMakeLTOTest/src/gen.cpp"
  # …and a compiled object beside them, so the fixture carries BOTH mechanisms where the
  # real repo carried both.
  printf 'ELF\0\0\0 QA release build\n' > "$CACHE/react/renderer/components/Props.cpp.o"
  run_lint "$WORK/v29"
  assert_rc        "V29a: a build cache under a scope segment does not turn the gate red" 0
  assert_out_lacks "V29b: … no term fires out of it" '"QA"'
  assert_out_lacks "V29c: … including the multi-word one" '"test mode"'
  assert_out_lacks "V29d: … and the cache never became a scope ROOT" ".buildcache"
  assert_out_has   "V29e: … while the real surface under android/app IS the subject" "SPECK_GATE_SUBJECT=1"
  assert_out_has   "V29f: … and it was reached at any depth, not by giving up on scope" \
    "SPECK_GATE_SCOPE=**/src/**"

  # V30 — the binary half, ISOLATED: a binary file directly under a real `components/`
  # surface, no dot-directory anywhere. V29's scope fix cannot reach it, so this pins the
  # `path:line:` shape enforcement in scan_term on its own.
  mkproj "$WORK/v30" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
  printf '\n%s\n' "$TEMPLATE_CLASSES" >> "$WORK/v30/specs/projects/test/product-contract.md"
  mkdir -p "$WORK/v30/components/assets"
  echo 'export const Logo = () => <p>Improve your day</p>;' > "$WORK/v30/components/Logo.tsx"
  printf 'icns\0\0\0 QA release build\n' > "$WORK/v30/components/assets/logo.icns"
  run_lint "$WORK/v30"
  assert_rc        "V30a: a binary asset under a scope dir does not convict the repo" 0
  assert_out_lacks "V30b: … rg's line-number-less binary notice never reaches the tally" \
    "binary file matches"
  assert_out_lacks "V30c: … so the term does not fire" '"QA"'
  assert_out_has   "V30d: … and it was NOT green by skipping the file — it is in the subject set" \
    "SPECK_GATE_SUBJECT=2"
  assert_out_has   "V30e: … counted honestly as a file the lexer could not read" \
    "SPECK_GATE_UNPARSED=1"
  # grep's -I skips binaries and rg's does not, so this is exactly #85's shape: without the
  # shape enforcement the gate's verdict depends on which binary is on PATH.
  if command -v rg >/dev/null 2>&1; then
    assert_branches_agree "V30f: rg and the grep fallback agree on a binary asset (#85)" "$WORK/v30"
  else
    echo "SKIP: V30f — ripgrep not installed"
  fi

  # V31 — the discriminator. V29 and V30 are both satisfiable by a gate that stopped
  # convicting anything; genuine copy in the SAME two trees has to still exit 1.
  echo 'public class Hype { String s = "We revolutionize your QA in test mode"; }' \
    > "$WORK/v29/android/app/src/main/java/com/x/Hype.java"
  run_lint "$WORK/v29"
  assert_rc      "V31a: real copy in the same tree still exits 1" 1
  assert_out_has "V31b: … the template's own phrase class fires on it" '"QA"'
  echo 'export const Hero = () => <p>Try test mode in the simulator</p>;' \
    > "$WORK/v30/components/Hero.tsx"
  run_lint "$WORK/v30"
  assert_rc      "V31c: … and so does copy beside the binary asset" 1
  assert_out_has "V31d: … reported from the real surface, never from the binary" "Hero.tsx"
fi

# V28 — the gate-liveness canary must inject a defect THIS gate is right to catch.
#
# The canary writes one file per extension-class present under the gate's scope and asserts the
# gate goes red on every one. Before v10 it wrote a bare line of prose into `src/__speck_canary__.ts`
# — which from v10 is not copy but a run of identifiers, so the gate stayed (correctly) green and
# the probe read that green as GATE_DISARMED.P1 on EVERY source surface at once. A canary whose
# "defect" the gate is right to ignore measures nothing; it manufactures a P1.
#
# This asserts the contract across the canary's own EXT_CLASSES, by calling the real provider —
# not a copy of it — so the two cannot drift apart again.
CANARY_LIB="$SCRIPT_DIR/validation/canary-lib.sh"
CANARY_DEF="$SCRIPT_DIR/validation/canaries/banned-language.canary"
if [[ -f "$CANARY_LIB" && -f "$CANARY_DEF" ]]; then
  mkproj "$WORK/v28" <<'EOF'
| revolutionize | UI | hype verb | improve |
EOF
  mkdir -p "$WORK/v28/src"
  # shellcheck source=/dev/null
  ( set +u; . "$CANARY_LIB" ) >/dev/null 2>&1 || true
  set +u
  . "$CANARY_LIB" >/dev/null 2>&1
  CANARY_EXTS="$(grep -E '^EXT_CLASSES=' "$CANARY_DEF" | head -n1 | sed -e 's/^EXT_CLASSES="//' -e 's/"$//')"
  set -u
  dark=""
  for ext in $CANARY_EXTS; do
    rm -f "$WORK/v28/src/__speck_canary__".*
    provide_banned_language_write "$WORK/v28" "src/__speck_canary__.$ext" "$ext" \
      "$WORK/v28/specs/projects/test" "revolutionize" >/dev/null 2>&1
    run_lint "$WORK/v28"
    [[ "$LAST_RC" -eq 1 ]] || dark="$dark $ext"
  done
  rm -f "$WORK/v28/src/__speck_canary__".*
  if [[ -z "$CANARY_EXTS" ]]; then
    _bad "V28: could not read EXT_CLASSES from the canary record"
  elif [[ -z "$dark" ]]; then
    _ok "V28: the banned-language canary's injected defect is caught on every EXT_CLASS it declares"
  else
    echo "  dark surfaces:$dark" >&2
    _bad "V28: the banned-language canary injects a defect this gate does not catch"
  fi
else
  echo "SKIP: V28 — canary-lib.sh / banned-language.canary not present in this sync"
fi

# ── V30 (#111): the six-fixture JSX text-run matrix, verbatim from the issue ──────────────
# Six three-line components differing only in the characters inside the text run. Pre-fix, ONE of
# six fired and SPECK_GATE_TEXT_RUNS_REJECTED did not exist, so the five blind files produced
# byte-identical output to five clean ones. Each fixture is asserted INDIVIDUALLY — a matrix
# scored in aggregate hides which member regressed.
#
# B and C are the ones that matter most and are now CAUGHT: Prettier manufactures B by wrapping a
# long JSX line, and a §7 term whose own canonical shape carries an interpolation is C.
# D, E and F stay refused (`( ) ; =` are what protect `if (a > b) { … }`) — but they are now
# COUNTED and NAMED, which is the difference between a residual and a blind spot.
jsx_fixture() { # <dir> <basename> <line>
  mkdir -p "$1/src/app"
  { echo 'export default function C() {'; echo "  return ($3);"; echo '}'; } > "$1/src/app/$2.tsx"
}

for fx in \
  "A|<p>Var server er revolusjonerende</p>|fire" \
  "B|<p>Var server er revolusjonerende{\" \"}</p>|fire" \
  "C|<p>Hei {\"du\"}, var server er revolusjonerende</p>|fire" \
  "D|<p>Valgt fordi (tag) - var server er revolusjonerende</p>|reject" \
  "E|<p>Var server er revolusjonerende; ukesmeny er klar</p>|reject" \
  "F|<p>Odd = uken din, var server er revolusjonerende</p>|reject"
do
  name="${fx%%|*}"; restfx="${fx#*|}"; jsx="${restfx%|*}"; want="${restfx##*|}"
  d="$WORK/v30-$name"
  mkproj "$d" <<'EOF'
| revolusjonerende | UI | hype | bedre |
EOF
  jsx_fixture "$d" "c" "$jsx"
  run_lint "$d"
  if [[ "$want" == "fire" ]]; then
    assert_rc "V30-$name: banned term inside a JSX text run FIRES" 1
  else
    # Still refused — but it must SAY SO. A refusal that reports nothing is the actual defect.
    if grep -q 'SPECK_GATE_TEXT_RUNS_REJECTED=0' <<<"$LAST_OUT"; then
      _bad "V30-$name: a refused text run must be COUNTED, not silent (#111)"
    else
      _ok "V30-$name: refused text run is counted and the file is named"
    fi
  fi
done

# V30g: a clean JSX file must report ZERO rejected runs — otherwise the counter is noise and
# the number stops meaning "there is copy here nobody read".
d="$WORK/v30-clean"
mkproj "$d" <<'EOF'
| revolusjonerende | UI | hype | bedre |
EOF
jsx_fixture "$d" "c" '<p>Var server er helt vanlig{" "}</p>'
run_lint "$d"
assert_rc "V30g: a clean JSX file passes" 0
assert_out_has "V30g: a fully-understood run reports no rejection" "SPECK_GATE_TEXT_RUNS_REJECTED=0"

# V30h: an EXPRESSION CONTAINER's contents must stay hidden. Revealing `{apiClient}` would
# re-open the exact false-conviction class --strings-only exists to close (an import specifier
# matching the template's own §7 "API" row). The prose around it is copy; the identifier is not.
d="$WORK/v30-ident"
mkproj "$d" <<'EOF'
| synergy | UI | generic pitch | collaboration |
EOF
mkdir -p "$d/src/app"
{
  echo 'export default function C({ synergyCount }) {'
  echo '  return (<p>Vi teller {synergyCount} ting her</p>);'
  echo '}'
} > "$d/src/app/c.tsx"
run_lint "$d"
assert_rc "V30h: an identifier inside {…} is not revealed as copy" 0

echo ""
echo "Results: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
