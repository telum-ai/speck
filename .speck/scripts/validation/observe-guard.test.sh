#!/usr/bin/env bash
# observe-guard.test.sh — the guard that answers "did this green have a chance to fail?" must
# itself be shown able to fail.
#
# Every case runs against REAL throwaway git repos with a REAL instrument (a script whose output
# genuinely depends on the flag under test) and a REAL Dockerfile / Procfile. A mocked instrument
# would reproduce the exact defect under test: an observation whose configuration is the lie.
#
# The subject repo is built so the headline #104 instance is literally reproducible here — a secret
# in a URL path segment that the access logger writes at INFO and `--log-level warning` silences.
# Test 1 and Test 2 are the same observation under two invocations, and they disagree.
#
# NOTE ON PIPEFAIL, deliberately repeated at every assertion site: never write
#   `if bash observe-guard.sh ... | grep -q X; then`
# — pipefail reports the SCRIPT's status, not the match, so the assertion silently inverts into one
# that cannot fail. Capture into a variable first, then grep the variable.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
GUARD="$ROOT/.speck/scripts/validation/observe-guard.sh"
PASS=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- subject repos -------------------------------------------------------------------------------
# DOCKED  — has a Dockerfile whose CMD is the shipped invocation (exec form, split over two lines
#           with a continuation, and carrying an ENV, because all three are parse surfaces).
# PLAIN   — no Dockerfile, no Procfile. Leg B is vacuous here, which is the deliberate
#           non-tyrannical case: a subject with no separate shipped configuration is not penalised
#           for one it does not have.
# PROC    — a Procfile instead, to prove the other shipped-invocation source parses.
mk_repo() {
  local d="$1"
  mkdir -p "$d/bin"
  # The instrument. Its output DEPENDS on --log-level, exactly like uvicorn's access logger: at
  # INFO the request line (carrying the token in the path) is written; at warning it is not.
  cat > "$d/bin/serve" <<'EOF'
#!/usr/bin/env bash
lvl="info"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --log-level) lvl="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done
if [ "$lvl" = "info" ]; then echo "INFO: GET /api/v1/tok_LIVESECRET/items 200"; fi
echo "INFO: startup complete"
EOF
  chmod +x "$d/bin/serve"
  git -C "$d" init -q
  git -C "$d" config user.email t@example.com
  git -C "$d" config user.name T
  git -C "$d" add -A
  git -C "$d" -c commit.gpgsign=false commit -qm init
}

DOCKED="$TMP/docked"; mkdir -p "$DOCKED"
cat > "$DOCKED/Dockerfile" <<'EOF'
FROM python:3.12-slim
ENV TZ=UTC
ENV LOG_FORMAT json
CMD ["bash", "bin/serve", \
     "--host", "0.0.0.0", "--port", "8000"]
EOF
mk_repo "$DOCKED"

PLAIN="$TMP/plain"; mkdir -p "$PLAIN"
mk_repo "$PLAIN"

PROC="$TMP/proc"; mkdir -p "$PROC"
printf 'worker: bash bin/serve --queue default\nweb: bash bin/serve --host 0.0.0.0 --port 8000\n' > "$PROC/Procfile"
mk_repo "$PROC"

# --- harness -------------------------------------------------------------------------------------
run_guard() { # <root> <args...>  — echoes combined output; never aborts the caller
  local r="$1"; shift
  bash "$GUARD" --root "$r" "$@" 2>&1 || true
}

run_guard_rc() { # like run_guard but records the exit status in RC
  local r="$1"; shift
  set +e
  OUT="$(bash "$GUARD" --root "$r" "$@" 2>&1)"
  RC=$?
  set -e
}

assert_verdict() {
  local want="$1" out="$2" label="$3"
  if grep -q "^SPECK_OBSERVATION_VERDICT=${want}\$" <<<"$out"; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label — expected $want, got:" >&2
    echo "$out" | sed 's/^/      /' >&2
    exit 1
  fi
}

assert_has() {
  local needle="$1" out="$2" label="$3"
  if grep -qF -- "$needle" <<<"$out"; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label — expected output to contain: $needle" >&2
    echo "$out" | sed 's/^/      /' >&2
    exit 1
  fi
}

assert_rc() {
  local want="$1" got="$2" label="$3"
  if [[ "$want" == "$got" ]]; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label — expected exit $want, got $got" >&2
    exit 1
  fi
}

# =================================================================================================
echo "Test 1: THE HEADLINE — a green observed under a flag the shipped CMD does not pass"
# dev runs --log-level warning; the Dockerfile CMD passes none, so production defaults to INFO.
# The grep finds zero hits and is TRUTHFUL about that. The configuration is the lie.
OUT="$(run_guard "$DOCKED" --subject tok-leak \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000 --log-level warning' \
  --expect-absent 'tok_LIVESECRET' --licenses irreversible)"
assert_has "SPECK_OBSERVATION_OBSERVED=green" "$OUT" "1a: the observation itself IS green — nothing about the check is wrong"
assert_verdict "OBSERVATION_UNEXPOSED_BLOCKING.P1" "$OUT" "1b: … but it licenses something irreversible unexposed → blocking"
assert_has "SPECK_OBSERVATION_DIVERGENCE_DETAIL=local-only --log-level (local='warning' shipped='')" "$OUT" \
  "1c: the divergence is named exactly — the flag, its local value, and its absence from the shipped CMD"
assert_has "SPECK_OBSERVATION_SHIPPED_SOURCE=Dockerfile" "$OUT" "1d: the shipped invocation was auto-detected"

echo "Test 2: the SAME observation under the SHIPPED invocation reproduces the leak"
# This is the whole point of leg B: run it the way it ships and the failing case is right there.
OUT="$(run_guard "$DOCKED" --subject tok-leak-shipped \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000' \
  --expect-absent 'tok_LIVESECRET' --licenses irreversible)"
assert_verdict "OBSERVATION_NOT_GREEN.P1" "$OUT" "2a: under the container's own invocation the token appears in one request"
assert_has "there is no green here to license anything" "$OUT" "2b: … and the report says there is no green to license anything"

echo "Test 3: Q2 IS THE DISCRIMINATOR — same unexposed run, different licence"
# Byte-identical invocation to Test 1 apart from --licenses. This is the half nothing currently
# expresses: if the green licenses only waiting, an unexposed run is harmless.
OUT="$(run_guard "$DOCKED" --subject tok-leak-waiting \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000 --log-level warning' \
  --expect-absent 'tok_LIVESECRET' --licenses waiting)"
assert_verdict "OBSERVATION_UNEXPOSED.P2" "$OUT" "3a: licenses=waiting → honest, non-blocking"
assert_has "buying exposure here would be waste" "$OUT" "3b: … and it says so, rather than nagging for exposure nobody needs"
run_guard_rc "$DOCKED" --subject tok-leak-waiting-rc \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000 --log-level warning' \
  --expect-absent 'tok_LIVESECRET' --licenses waiting
assert_rc 0 "$RC" "3c: … and exits 0, so a waiting-only green never blocks a pipeline"

echo "Test 4: a BLIND instrument — the positive control fires and the needle still never appears"
OUT="$(run_guard "$PLAIN" --subject blind \
  --observe 'bash bin/serve --log-level warning' \
  --expect-absent 'tok_LIVESECRET' --licenses accumulating \
  --positive-control 'true')"
assert_has "SPECK_OBSERVATION_LEVER=blind" "$OUT" "4a: the instrument could not be shown able to display the thing"
assert_verdict "OBSERVATION_UNEXPOSED_BLOCKING.P1" "$OUT" "4b: … so its zero is not evidence of absence"

echo "Test 5: a FIRED positive control with no divergence → the green counts"
OUT="$(run_guard "$DOCKED" --subject fired \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000' \
  --expect-absent 'tok_ROTATED_AWAY' --licenses irreversible \
  --positive-control 'echo "INFO: GET /api/v1/tok_ROTATED_AWAY/x 200"')"
assert_verdict "OBSERVATION_EXPOSED" "$OUT" "5a: instrument proven + shipped invocation matched"
assert_has "SPECK_OBSERVATION_DIVERGENCE=0" "$OUT" "5b: --host/--port from the CONTINUED exec-form CMD are seen, so they are not phantom divergences"
assert_has "this green had a real chance to fail" "$OUT" "5c: the reason states what was actually established"

echo "Test 6: NO LEVER does not excuse — it routes straight to Q2 (the inbound-mail case)"
OUT="$(run_guard "$PLAIN" --subject mail-reconcile \
  --observe 'echo "reconciled: 0 unmatched"' \
  --expect-absent 'unmatched: [1-9]' --licenses accumulating --no-lever)"
assert_has "SPECK_OBSERVATION_LEVER=no-lever" "$OUT" "6a: the declaration is recorded, not silently ignored"
assert_verdict "OBSERVATION_UNEXPOSED_BLOCKING.P1" "$OUT" \
  "6b: a guard that cannot make mail arrive still may not let an unexposed run COUNT"

echo "Test 7: … and the same no-lever subject licensing only waiting is left alone"
run_guard_rc "$PLAIN" --subject mail-reconcile-waiting \
  --observe 'echo "reconciled: 0 unmatched"' \
  --expect-absent 'unmatched: [1-9]' --licenses waiting --no-lever
assert_verdict "OBSERVATION_UNEXPOSED.P2" "$OUT" "7a: no lever + waiting is a legitimate resting state"
assert_rc 0 "$RC" "7b: … and does not block"

echo "Test 8: TWO STATIC PASSES IN A ROW prove only that neither number moved"
run_guard "$PLAIN" --subject static-count \
  --observe 'echo "queue depth: 0"' --expect-absent 'ERROR' --licenses waiting --no-lever >/dev/null
OUT="$(run_guard "$PLAIN" --subject static-count \
  --observe 'echo "queue depth: 0"' --expect-absent 'ERROR' --licenses waiting --no-lever)"
assert_has "SPECK_OBSERVATION_STATIC=true" "$OUT" "8a: the ledger notices a byte-identical repeat of the same subject"
assert_has "two static passes in a row prove only that neither number moved" "$OUT" "8b: … and says the sentence out loud"

echo "Test 9: EXPOSURE IS BOUGHT — --accept-divergence is the dial, and it is on the record"
OUT="$(run_guard "$DOCKED" --subject bought \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000 --log-level info' \
  --expect-absent 'tok_ROTATED_AWAY' --licenses irreversible \
  --accept-divergence '--log-level' \
  --positive-control 'echo "tok_ROTATED_AWAY"')"
assert_verdict "OBSERVATION_EXPOSED" "$OUT" "9a: a declared-irrelevant divergence stops blocking"
assert_has "SPECK_OBSERVATION_DIVERGENCE_ACCEPTED=1" "$OUT" "9b: … and is COUNTED, so the purchase is auditable rather than invisible"
assert_has "[ACCEPTED — declared irrelevant by --accept-divergence]" "$OUT" "9c: … and named in the detail line"

echo "Test 10: an --expect-present green is its own positive control"
OUT="$(run_guard "$PLAIN" --subject ci-verdict \
  --observe 'echo "conclusion: success"' --expect-present 'conclusion: success' --licenses irreversible)"
assert_has "SPECK_OBSERVATION_LEVER=self" "$OUT" "10a: an assertion of PRESENCE that succeeded literally displayed the thing"
assert_verdict "OBSERVATION_EXPOSED" "$OUT" "10b: … so no separate control need be bought"

echo "Test 11: A VERDICT THAT NEVER ARRIVED — a cancelled CI run is a missing result, not a pass"
OUT="$(run_guard "$PLAIN" --subject ci-cancelled \
  --observe 'echo "conclusion: cancelled"' --expect-present 'conclusion: success' --licenses irreversible)"
assert_verdict "OBSERVATION_NOT_GREEN.P1" "$OUT" "11a: absence of the expected result is a finding"
assert_has "A gate you never saw is not a gate that passed" "$OUT" "11b: … named in the reason"

echo "Test 12: --licenses is REQUIRED, and the refusal asks the question"
run_guard_rc "$PLAIN" --subject nolicence --observe 'echo x' --expect-absent 'y'
assert_rc 64 "$RC" "12a: a run that never states what its green licenses is refused"
assert_has "What does this green license?" "$OUT" "12b: … with Q2 spelled out rather than defaulted"

echo "Test 13: a Procfile is the other shipped-invocation source, and 'web:' is the one that counts"
OUT="$(run_guard "$PROC" --subject proc \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000' \
  --expect-absent 'tok_ROTATED_AWAY' --licenses irreversible \
  --positive-control 'echo tok_ROTATED_AWAY')"
assert_has "SPECK_OBSERVATION_SHIPPED_SOURCE=Procfile" "$OUT" "13a: the Procfile is detected"
assert_has "SPECK_OBSERVATION_DIVERGENCE=0" "$OUT" "13b: … and 'web:' is compared, not the earlier 'worker:' line"

echo "Test 14: ENV divergence — the UTC-runner case, where the flag is an environment variable"
set +e
OUT="$(TZ=Europe/Oslo bash "$GUARD" --root "$DOCKED" --subject tz \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000' \
  --expect-absent 'tok_ROTATED_AWAY' --licenses accumulating --env TZ 2>&1)"
set -e
assert_has "SPECK_OBSERVATION_DIVERGENCE_DETAIL=env-differs TZ (local='Europe/Oslo' shipped='UTC')" "$OUT" \
  "14a: an assertion that is meaningful on a UTC+N laptop and vacuous on a UTC runner is now visible"
assert_verdict "OBSERVATION_UNEXPOSED_BLOCKING.P1" "$OUT" "14b: … and an accumulating green may not rest on it"

echo "Test 15: NO shipped-invocation source is a DISCLOSED GAP, not a fabricated pass"
OUT="$(run_guard "$PLAIN" --subject nosource \
  --observe 'echo "0 hits"' --expect-absent 'tok_' --licenses irreversible \
  --positive-control 'echo tok_X')"
assert_has "SPECK_OBSERVATION_SHIPPED_SOURCE=none" "$OUT" "15a: looking and finding nothing is its own state"
assert_verdict "OBSERVATION_EXPOSED" "$OUT" "15b: … a subject with no separate shipped config is not penalised for one it lacks"
assert_has "pass --shipped-cmd if this subject does ship under a different command" "$OUT" \
  "15c: … and the gap is disclosed in the record rather than implied away"

echo "Test 16: a destructive invocation is refused — nothing is measured"
OUT="$(run_guard "$PLAIN" --subject destructive \
  --observe 'terraform apply -auto-approve' --expect-absent 'error' --licenses waiting)"
assert_verdict "OBSERVATION_UNMEASURED.P2" "$OUT" "16: an observation may reach outward, but never destructively"

echo "Test 17: --require-exposed turns an honest P2 into a hard stop for the caller that wants one"
run_guard_rc "$DOCKED" --subject req \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000 --log-level warning' \
  --expect-absent 'tok_LIVESECRET' --licenses waiting --require-exposed
assert_verdict "OBSERVATION_UNEXPOSED.P2" "$OUT" "17a: the verdict stays honest…"
assert_rc 1 "$RC" "17b: … and the exit status is the caller's choice, not a rewritten verdict"

echo "Test 18: the probe leaves the real working tree clean"
assert_has "SPECK_OBSERVATION_TREE_CHANGED=false" "$OUT" "18a: receipts land in a self-ignoring dir and never dirty git status"
STATUS="$(git -C "$DOCKED" status --porcelain)"
if [[ -z "$STATUS" ]]; then
  echo "  ✓ 18b: git status is empty after 8 runs against this repo"
  PASS=$((PASS + 1))
else
  echo "  ✗ 18b: the probe dirtied the subject repo:" >&2; echo "$STATUS" >&2; exit 1
fi

# =================================================================================================
# MUTATION PROOF — the three control points, each reverted in a SCRATCH COPY.
#
# Each site is inside the verdict logic that EVERY invocation runs, not a default parameter a
# caller overrides. The control is Test 2's OBSERVATION_NOT_GREEN.P1: it is decided upstream of all
# three sites, so it must stay identical under every mutation. A mutation that also moves the
# control has broken the file rather than the predicate, and proves nothing.
echo
echo "MUTATION PROOF: reverting each control point in a scratch copy must redden the case it guards"

# The mutants live in a scratch tree that MIRRORS the real layout (mut/ next to lib/), because
# observe-guard.sh resolves canary-lib.sh and ../lib/text.sh relative to its own location. Copying
# the libraries unmutated keeps the mutation confined to the one line under test — and keeps the
# scratch copy out of the repo, where a crashed run would otherwise leave a mutated script behind.
MUTDIR="$TMP/mut"
mkdir -p "$MUTDIR" "$TMP/lib"
cp "$ROOT/.speck/scripts/validation/canary-lib.sh" "$MUTDIR/canary-lib.sh"
cp "$ROOT/.speck/scripts/lib/text.sh" "$TMP/lib/text.sh"

mutate_copy() { # <exact-line-substring> <replacement line> <outfile>
  local marker="$1" repl="$2" out="$3" n
  n="$(grep -cF -- "$marker" "$GUARD" || true)"
  if [[ "$n" != "1" ]]; then
    echo "  ✗ mutation marker is not a unique site (matched $n times): $marker" >&2
    exit 1
  fi
  awk -v m="$marker" -v r="$repl" 'index($0, m) > 0 { print r; next } { print }' "$GUARD" > "$out"
}

mrun() { # <mutant> <root> <args...>
  local m="$1" r="$2"; shift 2
  bash "$m" --root "$r" "$@" 2>&1 || true
}

assert_mutant_verdict() {
  local want="$1" out="$2" label="$3"
  if grep -q "^SPECK_OBSERVATION_VERDICT=${want}\$" <<<"$out"; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label — expected the mutant to report $want, got:" >&2
    echo "$out" | sed 's/^/      /' >&2
    exit 1
  fi
}

CONTROL_ARGS=(--subject ctrl --observe 'bash bin/serve --host 0.0.0.0 --port 8000' --expect-absent 'tok_LIVESECRET' --licenses irreversible)

# --- M1: Q2 itself. Make every licence non-blocking. ---------------------------------------------
M1="$MUTDIR/m1.sh"
mutate_copy '  waiting)' '  waiting|accumulating|irreversible)' "$M1"
OUT="$(mrun "$M1" "$DOCKED" --subject tok-leak-m1 \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000 --log-level warning' \
  --expect-absent 'tok_LIVESECRET' --licenses irreversible)"
assert_mutant_verdict "OBSERVATION_UNEXPOSED.P2" "$OUT" \
  "M1: erasing the licence distinction downgrades Test 1's blocking verdict — that branch is load-bearing"
OUT="$(mrun "$M1" "$DOCKED" "${CONTROL_ARGS[@]}")"
assert_mutant_verdict "OBSERVATION_NOT_GREEN.P1" "$OUT" "M1-control: the upstream verdict is unmoved — the file still works"

# --- M2: leg B. Declare the invocation always matched. --------------------------------------------
M2="$MUTDIR/m2.sh"
mutate_copy 'if [[ "$SHIPPED_SOURCE" == "none" || "$DIVERGENCE_COUNT" -eq 0 ]]; then LEG_B=true; fi' \
            'LEG_B=true' "$M2"
OUT="$(mrun "$M2" "$DOCKED" --subject bought-m2 \
  --observe 'bash bin/serve --host 0.0.0.0 --port 8000 --log-level info' \
  --expect-absent 'tok_ROTATED_AWAY' --licenses irreversible \
  --positive-control 'echo "tok_ROTATED_AWAY"')"
assert_mutant_verdict "OBSERVATION_EXPOSED" "$OUT" \
  "M2: ignoring the shipped-invocation diff green-lights the run Test 9 had to BUY — leg B is load-bearing"
OUT="$(mrun "$M2" "$DOCKED" "${CONTROL_ARGS[@]}")"
assert_mutant_verdict "OBSERVATION_NOT_GREEN.P1" "$OUT" "M2-control: unmoved"

# --- M3: leg A. Credit a blind instrument as proven. ----------------------------------------------
M3="$MUTDIR/m3.sh"
mutate_copy 'case "$LEVER" in self|fired) LEG_A=true ;; esac' \
            'case "$LEVER" in self|fired|blind|none|no-lever) LEG_A=true ;; esac' "$M3"
OUT="$(mrun "$M3" "$PLAIN" --subject blind-m3 \
  --observe 'bash bin/serve --log-level warning' \
  --expect-absent 'tok_LIVESECRET' --licenses accumulating \
  --positive-control 'true')"
assert_mutant_verdict "OBSERVATION_EXPOSED" "$OUT" \
  "M3: crediting a blind instrument turns Test 4 into a pass — leg A is load-bearing"
OUT="$(mrun "$M3" "$DOCKED" "${CONTROL_ARGS[@]}")"
assert_mutant_verdict "OBSERVATION_NOT_GREEN.P1" "$OUT" "M3-control: unmoved"

echo
echo "observe-guard.test.sh: $PASS assertions passed"
