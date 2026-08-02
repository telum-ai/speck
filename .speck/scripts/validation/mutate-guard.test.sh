#!/usr/bin/env bash
# mutate-guard.test.sh — the primitive that proves other proofs must itself be proven.
#
# Every case runs against a REAL throwaway git repo with a real production file and two real
# behavioural test scripts (a red target and a green control), because the whole subject of this
# script is "did anything actually execute". A mocked runner would reproduce exactly the defect
# under test.
#
# NOTE ON PIPEFAIL, deliberately repeated at every assertion site: never write
#   `if bash mutate-guard.sh ... | grep -q X; then`
# — pipefail reports the SCRIPT's status, not the match, so the assertion silently inverts into
# one that cannot fail. Capture into a variable first, then grep the variable.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
GUARD="$ROOT/.speck/scripts/validation/mutate-guard.sh"
PASS=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- a throwaway subject repo ----------------------------------------------------------------
# prod.sh is the "production" file. t_add.sh is a behavioural test of the mutated predicate;
# t_mul.sh is the control — it exercises the same FILE but not the same predicate, which is the
# only thing that can tell "I hit the predicate" apart from "I broke the file".
REPO="$TMP/subject"
mkdir -p "$REPO/src" "$REPO/tests"
cat > "$REPO/src/prod.sh" <<'EOF'
#!/usr/bin/env bash
# speck_demo_add returns the sum. This comment line also contains the token PLUSOP for the
# comment-refusal case below.
speck_demo_add() {
  echo $(( $1 + $2 ))
}

speck_demo_mul() {
  echo $(( $1 * $2 ))
}

speck_demo_unobserved() {
  echo "nobody asserts on this"
}
EOF
cat > "$REPO/tests/t_add.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
. ./src/prod.sh
[ "$(speck_demo_add 2 2)" = "4" ]
EOF
cat > "$REPO/tests/t_mul.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
. ./src/prod.sh
[ "$(speck_demo_mul 3 3)" = "9" ]
EOF
cat > "$REPO/src/notes.py" <<'PYEOF'
"""A module docstring that mentions MARKER_IN_DOCSTRING deliberately."""


def real_code():
    return "MARKER_IN_CODE"
PYEOF
mkdir -p "$REPO/tests/fixtures"
echo 'FIXTURE_MARKER = 1' > "$REPO/tests/fixtures/data.py"

git -C "$REPO" init -q
git -C "$REPO" config user.email t@example.com
git -C "$REPO" config user.name  T
git -C "$REPO" add -A
git -C "$REPO" -c commit.gpgsign=false commit -qm init

run_guard() {
  # Echoes combined output; never let a non-zero exit abort the caller (we assert on the verdict).
  bash "$GUARD" --root "$REPO" "$@" 2>&1 || true
}

assert_verdict() {
  local want="$1" out="$2" label="$3"
  if grep -q "^SPECK_MUTATION_VERDICT=${want}\$" <<<"$out"; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label — expected $want, got:" >&2
    echo "$out" | sed 's/^/      /' >&2
    exit 1
  fi
}

echo "Test 1: a real predicate mutation reddens the target and spares the control → PROVEN"
OUT="$(run_guard --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_MUTATION_PROVEN "$OUT" "PROVEN on a live predicate"
grep -q '^SPECK_MUTATION_SITE=src/prod.sh:5$' <<<"$OUT" || { echo "  ✗ site not reported at the real line"; echo "$OUT"; exit 1; }
grep -q '^SPECK_MUTATION_RED_COUNT=1$' <<<"$OUT" || { echo "  ✗ red count wrong"; echo "$OUT"; exit 1; }
echo "  ✓ site and red-count transcribed from the run"
PASS=$((PASS + 1))

echo "Test 2: exit status is 0 for PROVEN"
set +e
bash "$GUARD" --root "$REPO" --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' \
  --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh' >/dev/null 2>&1
RC=$?
set -e
[ "$RC" -eq 0 ] || { echo "  ✗ expected exit 0 for PROVEN, got $RC"; exit 1; }
echo "  ✓ exit 0"
PASS=$((PASS + 1))

echo "Test 3: INVARIANT-ZERO — the subject repo is untouched after a run"
STATUS="$(git -C "$REPO" status --porcelain)"
[ -z "$STATUS" ] || { echo "  ✗ subject repo dirty after the run:"; echo "$STATUS"; exit 1; }
grep -q 'a + b\|\$1 + \$2' "$REPO/src/prod.sh" || { echo "  ✗ production file was mutated in the real tree"; exit 1; }
echo "  ✓ real tree clean and unmutated (nothing to revert, by construction)"
PASS=$((PASS + 1))

echo "Test 4: a mutation the suite does not observe → GUARD_MUTATION_GREEN.P2, not a failure"
OUT="$(run_guard --file src/prod.sh --pattern 'nobody asserts on this' --replacement 'still nobody' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_MUTATION_GREEN.P2 "$OUT" "honest MUTATION-GREEN"
set +e
bash "$GUARD" --root "$REPO" --file src/prod.sh --pattern 'nobody asserts on this' --replacement 'still nobody' \
  --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh' >/dev/null 2>&1
RC=$?
set -e
[ "$RC" -eq 0 ] || { echo "  ✗ MUTATION-GREEN must be NON-BLOCKING (exit 0), got $RC"; exit 1; }
echo "  ✓ non-blocking (exit 0) — the branch that stops authors tuning a mutation until it reddens"
PASS=$((PASS + 1))

echo "Test 5: a mutation that breaks the whole file reddens the control → UNMUTATED, not PROVEN"
OUT="$(run_guard --file src/prod.sh --pattern 'speck_demo_add() {' --replacement 'speck_demo_add( {' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "control reddened → the red proves nothing specific"
grep -q 'went RED too' <<<"$OUT" || { echo "  ✗ reason does not name the control"; echo "$OUT"; exit 1; }
echo "  ✓ reason attributes it to the broken file, not the predicate"
PASS=$((PASS + 1))

echo "Test 6: a pattern that matches zero times → UNMUTATED (the silent no-op, #94 §5a)"
OUT="$(run_guard --file src/prod.sh --pattern 'NO_SUCH_TOKEN_ANYWHERE' --replacement 'x' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "zero matches refused"
grep -q '^SPECK_MUTATION_MATCH_COUNT=0$' <<<"$OUT" || { echo "  ✗ match count not reported"; echo "$OUT"; exit 1; }
echo "  ✓ match count reported as 0"
PASS=$((PASS + 1))

echo "Test 7: a pattern that matches twice → UNMUTATED (ambiguous site)"
OUT="$(run_guard --file src/prod.sh --pattern 'echo' --replacement 'printf' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "multi-match refused"

echo "Test 8: a comment line is not executable → UNMUTATED (#94 §5b, the docstring green)"
OUT="$(run_guard --file src/prod.sh --pattern 'PLUSOP' --replacement 'MINUSOP' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "shell comment refused"
grep -q 'comment, a docstring or blank' <<<"$OUT" || { echo "  ✗ reason wrong"; echo "$OUT"; exit 1; }
echo "  ✓ reason names the non-executable line"
PASS=$((PASS + 1))

echo "Test 9: a Python docstring line is refused, and real code in the same file is not"
OUT="$(run_guard --file src/notes.py --pattern 'MARKER_IN_DOCSTRING' --replacement 'X' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "python docstring refused"
OUT="$(run_guard --file src/notes.py --pattern 'MARKER_IN_CODE' --replacement 'X' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
# Nothing asserts on notes.py, so the honest verdict is MUTATION-GREEN — the point is that the
# executable line got PAST the comment refusal while the docstring did not.
assert_verdict GUARD_MUTATION_GREEN.P2 "$OUT" "python code line accepted (reaches the run)"

echo "Test 10: a mutation aimed at a test/fixture path is refused (#94 §5d)"
OUT="$(run_guard --file tests/fixtures/data.py --pattern 'FIXTURE_MARKER' --replacement 'X' \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "fixture path refused"
grep -q 'test/fixture path' <<<"$OUT" || { echo "  ✗ reason wrong"; echo "$OUT"; exit 1; }
echo "  ✓ reason names the fixture path"
PASS=$((PASS + 1))

echo "Test 11: no --green control → refused (a red suite would be unattributable)"
OUT="$(run_guard --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' --red 'bash tests/t_add.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "missing control refused"
grep -q 'no --green control' <<<"$OUT" || { echo "  ✗ reason wrong"; echo "$OUT"; exit 1; }
echo "  ✓ reason names the missing control"
PASS=$((PASS + 1))

echo "Test 12: a --red test that was ALREADY red is refused (nothing is attributable)"
cat > "$REPO/tests/t_broken.sh" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
git -C "$REPO" add -A
git -C "$REPO" -c commit.gpgsign=false commit -qm broken
OUT="$(run_guard --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' \
        --red 'bash tests/t_broken.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "baseline-red target refused"
grep -q 'ALREADY red before the mutation' <<<"$OUT" || { echo "  ✗ reason wrong"; echo "$OUT"; exit 1; }
echo "  ✓ reason names the baseline"
PASS=$((PASS + 1))

echo "Test 13: --expect-count 2 with only one observer → MUTATION-GREEN, not PROVEN"
OUT="$(run_guard --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' --expect-count 2 \
        --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_MUTATION_GREEN.P2 "$OUT" "expect-count is enforced, not assumed"

echo "Test 14: a destructive invocation is refused by the shared canary-lib classifier"
OUT="$(run_guard --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' \
        --red 'terraform apply' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_UNMUTATED.P2 "$OUT" "destructive --red refused"
grep -q 'cl_probe_safety' <<<"$OUT" || { echo "  ✗ reason does not cite the shared classifier"; echo "$OUT"; exit 1; }
echo "  ✓ one safety law, in canary-lib.sh, not a second copy here"
PASS=$((PASS + 1))

echo "Test 15: --require-proven turns MUTATION-GREEN into a non-zero exit for a caller that needs it"
set +e
bash "$GUARD" --root "$REPO" --require-proven --file src/prod.sh \
  --pattern 'nobody asserts on this' --replacement 'still nobody' \
  --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh' >/dev/null 2>&1
RC=$?
set -e
[ "$RC" -eq 1 ] || { echo "  ✗ expected exit 1 under --require-proven, got $RC"; exit 1; }
echo "  ✓ opt-in strictness, default honest"
PASS=$((PASS + 1))

echo "Test 16: INVARIANT-ZERO holds after every case above"
STATUS="$(git -C "$REPO" status --porcelain)"
[ -z "$STATUS" ] || { echo "  ✗ subject repo dirty:"; echo "$STATUS"; exit 1; }
LEFTOVER="$(git -C "$REPO" worktree list | grep -c 'speck-liveness' || true)"
[ "$LEFTOVER" = "0" ] || { echo "  ✗ a probe worktree survived the run"; git -C "$REPO" worktree list; exit 1; }
echo "  ✓ clean tree, no surviving worktree"
PASS=$((PASS + 1))

echo "Test 17: a run that DOES dirty the real tree is caught by INVARIANT-ZERO and exits 2"
# The cases above assert the tree is clean, which is satisfied by a guard whose breach detector is
# dead code — proven by mutation: forcing the \$ROOT comparison to \`if false\` left every one of
# them green. This is the only case that exercises the detector itself, so it drives a gate that
# deliberately writes OUTSIDE its worktree (via an env var the sandbox passes through) and asserts
# the breach is reported and fatal rather than downgraded to a warning.
cat > "$REPO/tests/t_leaky.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'leak\n' > "${SPECK_TEST_LEAK_TARGET}/speck-invariant-zero-leak.txt"
. ./src/prod.sh
[ "$(speck_demo_add 2 2)" = "4" ]
EOF
git -C "$REPO" add -A
git -C "$REPO" -c commit.gpgsign=false commit -qm leaky
set +e
LEAK_OUT="$(SPECK_TEST_LEAK_TARGET="$REPO" bash "$GUARD" --root "$REPO" \
  --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' \
  --red 'bash tests/t_leaky.sh' --green 'bash tests/t_mul.sh' 2>&1)"
LEAK_RC=$?
set -e
rm -f "$REPO/speck-invariant-zero-leak.txt"
[ "$LEAK_RC" -eq 2 ] || { echo "  ✗ expected exit 2 on an INVARIANT-ZERO breach, got $LEAK_RC"; echo "$LEAK_OUT"; exit 1; }
grep -q 'INVARIANT-ZERO BREACH' <<<"$LEAK_OUT" || { echo "  ✗ the breach was not reported"; echo "$LEAK_OUT"; exit 1; }
grep -q '^SPECK_MUTATION_VERDICT=GUARD_UNMUTATED.P2$' <<<"$LEAK_OUT" || { echo "  ✗ a breached run must not report a usable verdict"; echo "$LEAK_OUT"; exit 1; }
echo "  ✓ breach detected, reported, and fatal — never a warning"
PASS=$((PASS + 1))

# =================================================================================================
# RECEIPTS — the cited-site cross-check.
#
# Read the limit these cases are written against, because over-reading them is the failure mode:
# a receipt is a LOCAL file written by a LOCAL script, so nothing here proves a mutation was run.
# What is proven is narrower and real — a CITED SITE cannot be invented, because it must resolve to
# a line whose content hashes to the pinned value at the pinned SHA. Test 21 is the load-bearing
# one: it drives a HAND-FORGED receipt, which is exactly what an agent under a blocking pre-commit
# would produce next once typing a verdict stops working.
#
# Every fixture below is DERIVED FROM THE SHIPPED TEMPLATE by substituting its placeholder row —
# never hand-typed. A hand-typed minimal report omits the template's own "**Verdicts.**" paragraph,
# which names all three GUARD_* codes in prose; that omission is precisely how a section-body grep
# passed on every report the template produces. Test 19 exists to keep that boilerplate in frame.
# =================================================================================================

TEMPLATE="$ROOT/.speck/templates/story/validation-report-template.md"
[ -f "$TEMPLATE" ] || { echo "✗ shipped template missing at $TEMPLATE"; exit 1; }

# A fresh subject so the receipts under test are the ones these cases created, not leftovers.
RREPO="$TMP/receipts"
mkdir -p "$RREPO/src" "$RREPO/tests"
cat > "$RREPO/src/prod.sh" <<'EOF'
#!/usr/bin/env bash
speck_r_add() {
  echo $(( $1 + $2 ))
}
speck_r_mul() {
  echo $(( $1 * $2 ))
}
EOF
cat > "$RREPO/tests/t_add.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
. ./src/prod.sh
[ "$(speck_r_add 2 2)" = "4" ]
EOF
cat > "$RREPO/tests/t_mul.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
. ./src/prod.sh
[ "$(speck_r_mul 3 3)" = "9" ]
EOF
git -C "$RREPO" init -q
git -C "$RREPO" config user.email t@example.com
git -C "$RREPO" config user.name  T
git -C "$RREPO" add -A
git -C "$RREPO" -c commit.gpgsign=false commit -qm init

ADD_LINE="$(grep -n 'echo \$(( \$1 + \$2 ))' "$RREPO/src/prod.sh" | head -n1 | cut -d: -f1)"
MUL_LINE="$(grep -n 'echo \$(( \$1 \* \$2 ))' "$RREPO/src/prod.sh" | head -n1 | cut -d: -f1)"

# Derive a report FROM THE TEMPLATE by filling its placeholder row. If the template's row ever
# changes shape the substitution stops matching, the fixture stays unfilled, and the asserting
# case fails loudly — which is the intended coupling, not a fragility.
derive_report() { # <out> <site> <verdict>
  sed -e "s#| \[GUARD_TEST PATH AND NAME\] | \[MUTATION_SITE PATH AND LINE\] | \[MATCH_COUNT\] | \[RED_TESTS NAMES AND COUNTS\] | \[GREEN_CONTROL TEST NAME\] | \[VERDICT_CODE FROM MUTATE GUARD\] |#| tests/t_add.sh::adds | $2 | 1 | tests/t_add.sh (1) | tests/t_mul.sh | $3 |#" \
      "$TEMPLATE" > "$1"
  grep -Fq "| $2 |" "$1" || { echo "  ✗ fixture derivation failed — the template's Mutation Record row changed shape; update derive_report"; exit 1; }
  # The boilerplate that defeated the previous section-body grep must still be in the fixture,
  # otherwise these cases are not testing the report the template actually produces.
  grep -Fq 'GUARD_MUTATION_PROVEN` · `GUARD_MUTATION_GREEN.P2' "$1" \
    || { echo "  ✗ fixture lost the template's Verdicts boilerplate — the trap is no longer in frame"; exit 1; }
}

assert_receipt_verdict() { # <want> <out> <label>
  local want="$1" out="$2" label="$3"
  if grep -q "^SPECK_RECEIPT_VERDICT=${want}\$" <<<"$out"; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label — expected $want"; echo "$out"; exit 1
  fi
}

echo "Test 18: a run emits a receipt pinning SHA + site + line CONTENT, and leaves the tree clean"
OUT="$(run_guard --root "$RREPO" --file src/prod.sh --pattern '$1 + $2' --replacement '$1 - $2' \
  --red 'bash tests/t_add.sh' --green 'bash tests/t_mul.sh')"
assert_verdict GUARD_MUTATION_PROVEN "$OUT" "genuine run"
grep -q "^SPECK_MUTATION_SITE_HASH=." <<<"$OUT" || { echo "  ✗ no site hash emitted"; echo "$OUT"; exit 1; }
grep -q "^SPECK_MUTATION_RECEIPT=.speck/mutation-receipts/" <<<"$OUT" || { echo "  ✗ no receipt path emitted"; echo "$OUT"; exit 1; }
RCT="$(grep '^SPECK_MUTATION_RECEIPT=' <<<"$OUT" | sed 's/^[^=]*=//')"
[ -f "$RREPO/$RCT" ] || { echo "  ✗ receipt not on disk at $RCT"; exit 1; }
echo "  ✓ receipt written and its path reported"
PASS=$((PASS + 1))
# The receipt directory is SELF-IGNORING on purpose: a probe whose bookkeeping dirties the repo
# would trip every clean-tree precondition in Speck, including INVARIANT-ZERO's own snapshot.
RSTATUS="$(git -C "$RREPO" status --porcelain)"
[ -z "$RSTATUS" ] || { echo "  ✗ receipts dirtied the subject repo:"; echo "$RSTATUS"; exit 1; }
echo "  ✓ receipts do not dirty the tree"
PASS=$((PASS + 1))

echo "Test 19: an UNTOUCHED template verifies as NO_CITATIONS — its Verdicts prose is not a citation"
# This is the regression case for the defect class this batch exists to kill: the shipped template
# names all three GUARD_* codes in a prose paragraph inside the Mutation Record section, so any
# rule that scans the SECTION BODY passes on every report the template produces. Citations are
# read from TABLE ROWS only.
cp "$TEMPLATE" "$TMP/unfilled.md"
grep -Fq 'GUARD_MUTATION_PROVEN' "$TMP/unfilled.md" || { echo "  ✗ template no longer contains the boilerplate codes — this case is moot, re-derive it"; exit 1; }
OUT="$(bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/unfilled.md" 2>&1 || true)"
assert_receipt_verdict RECEIPT_NO_CITATIONS.P2 "$OUT" "template boilerplate is not a citation"

echo "Test 19b: a row that names a verdict but NO site is a contradiction, not a silent skip"
# This case exists because the branch it drives was unreachable on first write. The rows were
# passed to `read` tab-separated, and tab is an IFS *whitespace* character, so a leading empty
# field was collapsed: a site-less row arrived as site=<verdict>, verdict="", and was `continue`d
# by the emptiness guard — the report degraded to NO_CITATIONS instead of blocking. Typing a
# verdict into a cell and leaving the site cell vague is the cheapest surrogate available, so this
# is exactly the row that must not be dropped.
derive_report "$TMP/nosite_cell.md" "src/prod.sh:$ADD_LINE" GUARD_MUTATION_PROVEN
# Blank out the site CELL while keeping the verdict cell filled.
sed -i.bak "s#| tests/t_add.sh::adds | src/prod.sh:$ADD_LINE |#| tests/t_add.sh::adds | (see above) |#" "$TMP/nosite_cell.md"
grep -Fq '| (see above) |' "$TMP/nosite_cell.md" || { echo "  ✗ fixture edit did not apply"; exit 1; }
OUT="$(bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/nosite_cell.md" 2>&1 || true)"
assert_receipt_verdict RECEIPT_MISMATCH.P1 "$OUT" "a site-less verdict row blocks"
grep -q 'names no <path>:<line>' <<<"$OUT" || { echo "  ✗ the site-less branch did not fire — it is unreachable again"; echo "$OUT"; exit 1; }
echo "  ✓ the site-less branch is reachable"
PASS=$((PASS + 1))

echo "Test 20: a report citing the REAL mutated site verifies"
derive_report "$TMP/real.md" "src/prod.sh:$ADD_LINE" GUARD_MUTATION_PROVEN
OUT="$(bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/real.md" 2>&1 || true)"
assert_receipt_verdict RECEIPT_VERIFIED "$OUT" "a real citation resolves"
set +e
bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/real.md" >/dev/null 2>&1
RC=$?
set -e
[ "$RC" -eq 0 ] || { echo "  ✗ a verified report must exit 0, got $RC"; exit 1; }
echo "  ✓ exit 0"
PASS=$((PASS + 1))

echo "Test 21: a HAND-FORGED receipt is caught by recomputing the pinned content at the pinned SHA"
# THE assertion of this cluster. Forging a receipt is the next move available to an agent once
# typing GUARD_MUTATION_PROVEN into a cell stops working, so the content hash — recomputed from
# `git show <sha>:<file>`, never trusted from the receipt — is the only thing standing between a
# cited site and an invented one. Proven by mutation: replacing the hash comparison with `if false`
# turns this case into RECEIPT_VERIFIED.
RSHA="$(git -C "$RREPO" rev-parse --short HEAD)"
cat > "$RREPO/.speck/mutation-receipts/forged.receipt" <<EOF
SPECK_RECEIPT_VERSION=1
SPECK_MUTATION_SHA=$RSHA
SPECK_MUTATION_FILE=src/prod.sh
SPECK_MUTATION_SITE=src/prod.sh:$MUL_LINE
SPECK_MUTATION_SITE_HASH=deadbeefdeadbeefdeadbeefdeadbeefdeadbeef
SPECK_MUTATION_VERDICT=GUARD_MUTATION_PROVEN
EOF
derive_report "$TMP/forged.md" "src/prod.sh:$MUL_LINE" GUARD_MUTATION_PROVEN
OUT="$(bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/forged.md" 2>&1 || true)"
assert_receipt_verdict RECEIPT_MISMATCH.P1 "$OUT" "forged content hash rejected"
grep -q 'does not recompute' <<<"$OUT" || { echo "  ✗ the finding does not name the recompute — a different branch fired, so this case is not exercising the hash"; echo "$OUT"; exit 1; }
echo "  ✓ the recompute branch is what fired, not a neighbouring refusal"
PASS=$((PASS + 1))
set +e
bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/forged.md" >/dev/null 2>&1
RC=$?
set -e
[ "$RC" -eq 1 ] || { echo "  ✗ a contradicted report must exit 1, got $RC"; exit 1; }
echo "  ✓ a contradiction blocks (exit 1)"
PASS=$((PASS + 1))
rm -f "$RREPO/.speck/mutation-receipts/forged.receipt"

echo "Test 22: in a repo that DOES emit receipts, a citation with no receipt is a contradiction"
derive_report "$TMP/nosite.md" "src/prod.sh:999" GUARD_MUTATION_PROVEN
OUT="$(bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/nosite.md" 2>&1 || true)"
assert_receipt_verdict RECEIPT_MISMATCH.P1 "$OUT" "fabricated site in an adopted repo blocks"

echo "Test 23: in a repo that has NEVER emitted a receipt, the same report only DEGRADES"
# The adoption gradient, and the reason it is not a hard block: projects predating receipts must
# not be failed by a mechanism they never opted into. An absence degrades; a contradiction blocks.
NREPO="$TMP/never"
mkdir -p "$NREPO/src"
cp "$RREPO/src/prod.sh" "$NREPO/src/prod.sh"
git -C "$NREPO" init -q
git -C "$NREPO" config user.email t@example.com
git -C "$NREPO" config user.name  T
git -C "$NREPO" add -A
git -C "$NREPO" -c commit.gpgsign=false commit -qm init
[ -d "$NREPO/.speck/mutation-receipts" ] && { echo "  ✗ NREPO is not actually un-adopted"; exit 1; }
OUT="$(bash "$GUARD" --root "$NREPO" --verify-receipt "$TMP/real.md" 2>&1 || true)"
assert_receipt_verdict RECEIPT_MISSING.P2 "$OUT" "un-adopted repo degrades rather than blocks"
set +e
bash "$GUARD" --root "$NREPO" --verify-receipt "$TMP/real.md" >/dev/null 2>&1
RC=$?
set -e
[ "$RC" -eq 0 ] || { echo "  ✗ a degrade must NOT block; expected exit 0, got $RC"; exit 1; }
echo "  ✓ degrade is non-blocking (exit 0)"
PASS=$((PASS + 1))

echo "Test 24: a report may not claim a STRONGER verdict than the receipt records"
OUT="$(run_guard --root "$RREPO" --file src/prod.sh --pattern '$1 * $2' --replacement '$1 + $2' \
  --red 'bash tests/t_add.sh' --green 'bash tests/t_add.sh')"
# t_add is unaffected by the mul mutation, so the honest verdict is MUTATION-GREEN.
assert_verdict GUARD_MUTATION_GREEN.P2 "$OUT" "honest green recorded on the receipt"
derive_report "$TMP/upgraded.md" "src/prod.sh:$MUL_LINE" GUARD_MUTATION_PROVEN
OUT="$(bash "$GUARD" --root "$RREPO" --verify-receipt "$TMP/upgraded.md" 2>&1 || true)"
assert_receipt_verdict RECEIPT_MISMATCH.P1 "$OUT" "claimed PROVEN over a recorded GREEN.P2 blocks"
grep -q 'stronger verdict' <<<"$OUT" || { echo "  ✗ a different branch fired than the rank check"; echo "$OUT"; exit 1; }
echo "  ✓ the rank check is what fired"
PASS=$((PASS + 1))

echo ""
echo "All mutate-guard tests passed ($PASS assertions)."
exit 0
