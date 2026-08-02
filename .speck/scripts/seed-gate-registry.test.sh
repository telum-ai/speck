#!/usr/bin/env bash
# seed-gate-registry.test.sh — tests for the §6a producer (issue #88; header-keyed conversion,
# Speck v9.6; Scope/Subject columns, issue #98).
#
# Three sites read the §6a table and had already drifted from each other: this script (the
# PRODUCER) hardcoded the header text on one line and the row printf on another with no shared
# source of truth; validate-gate-liveness.sh read $2/$3/$4/$7; gate-liveness-probe.sh read
# $2/$3/$5/$6. Insert a column and Canary silently re-maps to Waiver — a registry that reads as
# un-canaried, reports green.
#
# This file proves (a) the producer's own header/rows/separator can't independently drift (all three
# are derived from ONE column list), (b) a ROUND-TRIP — seed a registry, parse it with BOTH
# consumers, every field lands in the right slot — and (c) that the round-trip still holds when a
# column is inserted MID-TABLE, which is what #98 actually does to this schema.

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SEED="$ROOT/.speck/scripts/seed-gate-registry.sh"
VALIDATE="$ROOT/.speck/scripts/validation/validators/validate-gate-liveness.sh"
PROBE="$ROOT/.speck/scripts/validation/validators/gate-liveness-probe.sh"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "${2:-}"; echo "------------------"; FAILED=1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# ===================================================================================================
echo "== Producer shape (header + separator + rows from ONE column list) =="

RECIPE="$T/recipe.yaml"
cat > "$RECIPE" <<'EOF'
evidence_contract:
  ci_gates:
    - id: vitest
      command: npm run test
      stage: pre-push
      domain: frontend
    - id: banned
      command: .speck/scripts/banned-language-lint.sh
      stage: pre-commit
      domain: copy
      scope: src/**,app/**
      subject: files>0
      canary: banned-language
EOF

OUT="$(bash "$SEED" "$RECIPE")"

# 1. header carries all eight labels, in order (Scope/Subject inserted MID-TABLE by #98)
echo "$OUT" | head -n1 | grep -qE '^\| Gate ID \| Command / Script \| Stage \| Domain \| Scope \| Subject \| Canary \| Waiver \|$' \
  && pass "header: exact 8 labels, in order (Scope+Subject between Domain and Canary)" \
  || fail "header shape wrong" "$OUT"

# 2. separator row is a well-formed markdown separator with the SAME column count as the header.
#
# PINNED BY MUTATION C BELOW. On its own this assertion is weak: a hardcoded separator string with
# the right number of pipes satisfies it forever, and an audit found exactly that — replacing
# gate_registry_separator's body with a literal left the whole suite exit 0. The assertion is now
# a FUNCTION so the same predicate can be pointed at a mutated producer and required to go RED.
separator_tracks_header() { # <script> -> 0 when the separator's column count matches the header's
  local script="$1" out hdr sep
  out="$(bash "$script" "$RECIPE" 2>/dev/null)" || return 2
  hdr=$(echo "$out" | head -n1 | awk -F'|' '{print NF}')
  sep=$(echo "$out" | sed -n '2p' | awk -F'|' '{print NF}')
  echo "$out" | sed -n '2p' | grep -qE '^\|[-| ]+\|$' || return 1
  [[ "$hdr" == "$sep" ]]
}
hdr_cols=$(echo "$OUT" | head -n1 | awk -F'|' '{print NF}')
separator_tracks_header "$SEED" \
  && pass "separator: well-formed, same column count as header ($hdr_cols)" \
  || fail "separator malformed or column-count mismatch (header=$hdr_cols)" "$OUT"

# 3. row 1 (nothing but the four mandatory keys declared) — every optional cell is an em-dash and
#    every declared cell lands in the column its header names.
row1="$(echo "$OUT" | sed -n '3p')"
{ echo "$row1" | grep -qE '^\| vitest \| `npm run test` \| pre-push \| frontend \| — \| — \| — \| — \|$'; } \
  && pass "row (bare): id/command/stage/domain in place, scope/subject/canary/waiver em-dashed" \
  || fail "row1 cell placement wrong" "$row1"

# 4. row 2 — scope/subject/canary each land in their OWN cell, none spilling into the next
row2="$(echo "$OUT" | sed -n '4p')"
{ echo "$row2" | grep -qE '^\| banned \| `\.speck/scripts/banned-language-lint\.sh` \| pre-commit \| copy \| src/\*\*,app/\*\* \| files>0 \| banned-language \| — \|$'; } \
  && pass "row (full): scope + subject + canary each in their own cell, Waiver still an em-dash" \
  || fail "row2 cell placement wrong" "$row2"

# 5. --contract splice still preserves prose around the table (regression on the splice mode), and
#    it upgrades a LEGACY 6-column table in place — the migration's manual escape hatch.
CTR="$T/evidence-contract.md"
cat > "$CTR" <<'EOF'
# Evidence Contract

## 6. Required Static Evidence

### 6a. CI-Enforced Gate Registry

| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |
|---------|------------------|-------|--------|--------|--------|
| stale | `old` | manual | — | — | — |

## 7. Required Live-Service Evidence

Prose that must survive the splice untouched.
EOF
bash "$SEED" "$RECIPE" --contract "$CTR" >/dev/null
{ grep -q "vitest" "$CTR" && ! grep -q "stale" "$CTR" && grep -q "Prose that must survive the splice untouched." "$CTR" \
  && grep -q '| Gate ID | Command / Script | Stage | Domain | Scope | Subject | Canary | Waiver |' "$CTR"; } \
  && pass "--contract splice: legacy 6-col table replaced with the 8-col schema, prose untouched" \
  || fail "splice did not replace the table cleanly" "$(cat "$CTR")"

# ===================================================================================================
echo ""
echo "== ROUND-TRIP: seed a registry, parse it with BOTH consumers (the test that didn't exist) =="

# Two gates, each isolating a DIFFERENT consumer's field-of-interest:
#   gate-domcheck — proves validate-gate-liveness reads Stage/Gate-ID right (GATE_MANUAL), and
#                   proves gate-liveness-probe reads Domain right (a deliberate mismatch echoes
#                   the extracted domain value back in its finding text).
#   gate-cmdcheck — proves both consumers again on a second row (id isolation across rows), and
#                   proves gate-liveness-probe reads Command AND Canary right (a real canary key
#                   with a matching domain reaches the invocation-resolve step, which echoes the
#                   extracted, unresolvable command back verbatim).
RT_RECIPE="$T/rt-recipe.yaml"
cat > "$RT_RECIPE" <<'EOF'
evidence_contract:
  ci_gates:
    - id: gate-domcheck
      command: "true"
      stage: manual
      domain: unrelated-zone
      canary: banned-language
    - id: gate-cmdcheck
      command: definitely-not-a-real-command-xyz123
      stage: manual
      domain: copy
      canary: banned-language
EOF

# roundtrip <seed-script> <label> — seed a fresh repo's contract with the given producer, then parse
# it with BOTH consumers and assert every field lands in the slot its header names. Parameterized on
# the producer so the SAME assertions can be re-run against a mid-table-mutated producer (below).
roundtrip() {
  local seed="$1" label="$2"
  local rt_d="$T/rt-$label"
  mkdir -p "$rt_d"
  git -C "$rt_d" init -q
  git -C "$rt_d" config user.email t@t.co; git -C "$rt_d" config user.name t
  local rt_ctr="$rt_d/evidence-contract.md"
  cat > "$rt_ctr" <<'EOF'
# Evidence Contract

## 6. Required Static Evidence

### 6a. CI-Enforced Gate Registry

| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |
|---------|------------------|-------|--------|--------|--------|
| REPLACE_BEFORE_SHIP | — | — | — | — | — |

## 7. Required Live-Service Evidence
EOF
  bash "$seed" "$RT_RECIPE" --contract "$rt_ctr" >/dev/null
  git -C "$rt_d" add -A >/dev/null 2>&1; git -C "$rt_d" commit -q -m init >/dev/null 2>&1

  # --- consumer 1: validate-gate-liveness.sh (Stage/Gate-ID) ---
  local v_out
  v_out="$(bash "$VALIDATE" --strict "$rt_ctr" 2>&1)"
  { echo "$v_out" | grep -q "GATE_MANUAL.*gate-domcheck" && echo "$v_out" | grep -q "GATE_MANUAL.*gate-cmdcheck"; } \
    && pass "[$label] validate-gate-liveness: both gid+stage cells read correctly (2 distinct rows)" \
    || fail "[$label] validate-gate-liveness misread gid/stage from a producer-seeded table" "$v_out"

  # --- consumer 2: gate-liveness-probe.sh (Domain/Canary/Command) ---
  local p_out
  p_out="$(bash "$PROBE" "$rt_d" 2>&1)"
  echo "$p_out" | grep -q "unknown canary key" \
    && fail "[$label] probe: canary must resolve to the real library key, not an unknown one" "$p_out" \
    || pass "[$label] probe: Canary cell resolved to a real library key on both rows"
  { echo "$p_out" | grep -q "gate-domcheck.*domain-mismatch" && echo "$p_out" | grep -q "domain 'unrelated-zone'"; } \
    && pass "[$label] probe: Domain cell extracted correctly (echoed back verbatim in the mismatch)" \
    || fail "[$label] probe: Domain cell not extracted correctly" "$p_out"
  { echo "$p_out" | grep -q "gate-cmdcheck" && echo "$p_out" | grep -qF "no locally-runnable invocation resolved for '\`definitely-not-a-real-command-xyz123\`'"; } \
    && pass "[$label] probe: Command cell extracted correctly (echoed back verbatim, unresolved)" \
    || fail "[$label] probe: Command cell not extracted correctly" "$p_out"
}

roundtrip "$SEED" "shipped"

# ===================================================================================================
echo ""
echo "== MUTATIONS: the column list is the single source for header, separator AND row printf =="
#
# Every mutation below edits a SCRATCH COPY of the real producer ($SEED) — never the file under test
# itself. Each first confirms its edit actually matched the producer's current structure (so a future
# refactor that renames the array/function fails loudly here instead of silently no-opping into a
# false pass), then exercises the mutated copy.

# --- Mutation A (desync) ---------------------------------------------------------------------------
# Append a column to GATE_REGISTRY_COLUMNS but leave flush()'s printf arg list untouched: the row
# format string now has one more %s than flush() supplies values for.
#
# PORTABILITY (fixed): this used to assert the literal stderr `awk: not enough args in printf`.
# That string is BSD awk (macOS). Under mawk — the Debian/Ubuntu default — a short printf prints
# EMPTY fields and exits 0, so the assertion would have gone RED against a perfectly correct
# producer on the runner most consumer projects use. `.speck/scripts` is synced into those projects
# and nothing pins the runner OS. The portable invariant is the DESYNC ITSELF: either the producer
# refuses (non-zero exit) or it emits a row with fewer columns than its own header. The stderr text
# survives only as a non-fatal note.
#
# desync_verdict <script> — the portable predicate, shared by A and A2. Echoes one of:
#   refused:<code>          the producer exited non-zero (BSD awk's route)
#   nf-mismatch:<h>/<r>     it exited 0 but emitted a row whose column count ≠ its own header's
#   undetected              it emitted a self-consistent table — the desync got through
desync_verdict() {
  local script="$1" out code h r
  set +e
  out="$(bash "$script" "$RECIPE" 2>&1)"
  code=$?
  set -e
  if [[ "$code" -ne 0 ]]; then printf 'refused:%s' "$code"; return 0; fi
  h=$(printf '%s\n' "$out" | grep 'Gate ID' | head -n1 | awk -F'|' '{print NF}' || true)
  r=$(printf '%s\n' "$out" | grep '^| vitest ' | head -n1 | awk -F'|' '{print NF}' || true)
  if [[ -n "$h" && -n "$r" && "$h" != "$r" ]]; then printf 'nf-mismatch:%s/%s' "$h" "$r"; return 0; fi
  printf 'undetected'
}

MUT_A="$T/seed-mut-desync.sh"
cp "$SEED" "$MUT_A"
sed -i.bak -E 's/^(GATE_REGISTRY_COLUMNS=\(.*)\)$/\1 "Extra")/' "$MUT_A"
if diff -q "$MUT_A.bak" "$MUT_A" >/dev/null; then
  fail "mutation A setup: sed did not match GATE_REGISTRY_COLUMNS in $SEED — producer structure changed?" ""
fi

MUT_A_V="$(desync_verdict "$MUT_A")"
[[ "$MUT_A_V" != "undetected" ]] \
  && pass "mutation A: column appended without updating flush() → desync detected ($MUT_A_V)" \
  || fail "mutation A: header/row desync did not surface" "$(bash "$MUT_A" "$RECIPE" 2>&1 || true)"
# Non-fatal note only — never an assertion. BSD awk says so out loud; mawk does not.
MUT_A_RAW="$(bash "$MUT_A" "$RECIPE" 2>&1 || true)"
if printf '%s\n' "$MUT_A_RAW" | grep -q "not enough args in printf"; then
  echo "    · note: this awk ($(awk --version 2>&1 | head -n1)) also printed 'not enough args in printf'"
else
  echo "    · note: this awk printed short fields rather than erroring — the NF check is what caught it"
fi

# --- Mutation A2 (the mawk shape, reproducible on ANY awk) -----------------------------------------
# A alone cannot prove the portability fix on a BSD-awk machine: it takes the `refused` branch there
# and the NF branch is never executed, which is exactly the kind of untaken branch that made the old
# stderr assertion look proven. A2 forces the OTHER branch on every awk. It shrinks the ROW FORMAT by
# one column while leaving the header and flush()'s arg list alone — awk silently IGNORES surplus
# printf args, so the producer exits 0 and emits a self-inconsistent table, byte-for-byte the failure
# mawk produces for mutation A. Only the header-NF-vs-row-NF check can see it.
MUT_A2="$T/seed-mut-shortrow.sh"
awk '
  /^ROWS="\$\(gen_rows\)"$/ && !done {
    print "gate_registry_row_fmt() { local out=\"\" c; for c in \"${GATE_REGISTRY_COLUMNS[@]:1}\"; do out=\"${out}| %s \"; done; printf '\''%s|'\'' \"$out\"; }"
    done = 1
  }
  { print }
' "$SEED" > "$MUT_A2"
if diff -q "$SEED" "$MUT_A2" >/dev/null; then
  fail "mutation A2 setup: could not find the ROWS=\$(gen_rows) insertion point in $SEED" ""
fi
MUT_A2_V="$(desync_verdict "$MUT_A2")"
case "$MUT_A2_V" in
  nf-mismatch:*) pass "mutation A2: a desync that EXITS 0 (the mawk shape) is still caught — $MUT_A2_V" ;;
  refused:*)     fail "mutation A2: expected an exit-0 desync; this awk refused it, so the NF branch is still unproven ($MUT_A2_V)" "" ;;
  *)             fail "mutation A2: an exit-0 header/row desync went UNDETECTED — the portable check does not work" "$(bash "$MUT_A2" "$RECIPE" 2>&1 || true)" ;;
esac

# --- Mutation B (header derivation) ----------------------------------------------------------------
# Append a column AND give it a matching value in flush() — self-consistent, so the mutated copy
# still runs clean — then confirm the emitted HEADER ROW contains the new label. A hardcoded header
# string would never pick this up; only a header genuinely derived from the array will.
MUT_B="$T/seed-mut-header.sh"
cp "$SEED" "$MUT_B"
sed -i.bak \
  -e 's/^\(GATE_REGISTRY_COLUMNS=(.*\))$/\1 "Owner")/' \
  -e 's/c, "—"; printf "\\n"/c, "—", "—"; printf "\\n"/' \
  "$MUT_B"
if diff -q "$MUT_B.bak" "$MUT_B" >/dev/null; then
  fail "mutation B setup: sed did not match producer structure in $SEED — producer structure changed?" ""
fi

MUT_B_OUT="$(bash "$MUT_B" "$RECIPE")"
echo "$MUT_B_OUT" | head -n1 | grep -qE '^\| Gate ID \| Command / Script \| Stage \| Domain \| Scope \| Subject \| Canary \| Waiver \| Owner \|$' \
  && pass "mutation B: header row is DERIVED from GATE_REGISTRY_COLUMNS (appended column appears automatically)" \
  || fail "mutation B: header did not pick up the appended column — may be hardcoded" "$MUT_B_OUT"

# Mutation B is also the self-consistent shape item 2's audit called for: it appends a column AND a
# matching flush() value, so it's the fixture that proves gate_registry_separator() itself is
# derived, not hardcoded. Assert the emitted SEPARATOR row's column count equals the (also-grown)
# header's AND has gone up by exactly one versus the UNMUTATED $SEED run — a hardcoded separator
# string that merely happens to have the right column count for THIS run would satisfy "matches the
# header" without ever proving it tracks a genuine column addition; the cross-run delta is what closes
# that gap (this is the case Mutation C's `separator_tracks_header` predicate proved was previously
# unpinned — a literal hardcoded body left the whole suite green).
mut_b_hdr_cols=$(echo "$MUT_B_OUT" | head -n1 | awk -F'|' '{print NF}')
mut_b_sep_cols=$(echo "$MUT_B_OUT" | sed -n '2p' | awk -F'|' '{print NF}')
{ [[ "$mut_b_sep_cols" == "$mut_b_hdr_cols" ]] && [[ "$mut_b_sep_cols" == "$((hdr_cols + 1))" ]]; } \
  && pass "mutation B: separator column count matches the grown header, up by one from the unmutated run ($hdr_cols -> $mut_b_sep_cols)" \
  || fail "mutation B: separator did not track the appended column (unmutated=$hdr_cols mutated_hdr=$mut_b_hdr_cols mutated_sep=$mut_b_sep_cols)" "$MUT_B_OUT"

# --- Mutation C (separator pinning) ----------------------------------------------------------------
# The P2 an audit left in this file: gate_registry_separator() was UNPINNED — swap its body for a
# hardcoded string and the whole suite still exited 0. Redefine the function AFTER its real
# definition (bash: last definition wins) with a literal 6-column separator, then require the
# assertion from block 2 — the one that claims the separator tracks the header — to go RED.
# If it does not, that assertion is decoration.
MUT_C="$T/seed-mut-separator.sh"
awk '
  /^ROWS="\$\(gen_rows\)"$/ && !done {
    print "gate_registry_separator() { printf \"%s\" \"|---|---|---|---|---|---|\"; }"
    done = 1
  }
  { print }
' "$SEED" > "$MUT_C"
if diff -q "$SEED" "$MUT_C" >/dev/null; then
  fail "mutation C setup: could not find the ROWS=\$(gen_rows) insertion point in $SEED — producer structure changed?" ""
fi
if separator_tracks_header "$MUT_C"; then
  fail "mutation C: a HARDCODED 6-column separator was NOT caught — the separator/header assertion is vacuous" \
    "$(bash "$MUT_C" "$RECIPE" 2>&1)"
else
  pass "mutation C: hardcoded separator caught — separator column count genuinely tracks the header's"
fi

# --- Mutation D (MID-TABLE insert, the #98 shape) --------------------------------------------------
# #98 does not append a column, it inserts two in the MIDDLE — exactly where the old positional
# readers expected Canary and Waiver. Insert a third one mid-table (Owner, between Domain and Scope)
# and re-run the ENTIRE round-trip: every other field must still land in the slot its header names,
# through both consumers. This is the assertion that makes a mid-table schema change safe to ship.
MUT_D="$T/seed-mut-midtable.sh"
cp "$SEED" "$MUT_D"
sed -i.bak \
  -e 's/^\(GATE_REGISTRY_COLUMNS=("Gate ID" "Command \/ Script" "Stage" "Domain"\)/\1 "Owner"/' \
  -e 's/(domain==""?"—":domain), /(domain==""?"—":domain), "owner-x", /' \
  "$MUT_D"
if diff -q "$MUT_D.bak" "$MUT_D" >/dev/null; then
  fail "mutation D setup: sed did not match producer structure in $SEED — producer structure changed?" ""
fi
MUT_D_OUT="$(bash "$MUT_D" "$RECIPE")"
{ echo "$MUT_D_OUT" | head -n1 | grep -qE '^\| Gate ID \| Command / Script \| Stage \| Domain \| Owner \| Scope \| Subject \| Canary \| Waiver \|$' \
  && echo "$MUT_D_OUT" | grep -qE '^\| banned \| `[^`]+` \| pre-commit \| copy \| owner-x \| src/\*\*,app/\*\* \| files>0 \| banned-language \| — \|$'; } \
  && pass "mutation D: mid-table insert — new cell in its own column, every later cell shifted with its header" \
  || fail "mutation D: a mid-table insert misaligned the later cells" "$MUT_D_OUT"
roundtrip "$MUT_D" "midtable-insert"

if [[ "$FAILED" == 0 ]]; then echo ""; echo "✅ seed-gate-registry: all tests passed"; else echo ""; echo "❌ seed-gate-registry: FAILURES"; exit 1; fi
