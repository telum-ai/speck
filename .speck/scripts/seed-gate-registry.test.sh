#!/usr/bin/env bash
# seed-gate-registry.test.sh — tests for the §6a producer (issue #88; header-keyed conversion,
# Speck v9.6, this cluster).
#
# Three sites read the §6a table and had already drifted from each other: this script (the
# PRODUCER) hardcoded the header text on one line and the row printf on another with no shared
# source of truth; validate-gate-liveness.sh read $2/$3/$4/$7; gate-liveness-probe.sh read
# $2/$3/$5/$6. Insert a column and Canary silently re-maps to Waiver — a registry that reads as
# un-canaried, reports green.
#
# This file proves (a) the producer's own header/rows can't independently drift (they're derived
# from ONE column list), and (b) a ROUND-TRIP — seed a registry, parse it with BOTH consumers,
# every field lands in the right slot — which did not exist in any form before this conversion.

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
echo "== Producer shape (header + rows from ONE column list) =="

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
      canary: banned-language
EOF

OUT="$(bash "$SEED" "$RECIPE")"

# 1. header carries all six labels, in order
echo "$OUT" | head -n1 | grep -qE '^\| Gate ID \| Command / Script \| Stage \| Domain \| Canary \| Waiver \|$' \
  && pass "header: exact 6 labels, in order" \
  || fail "header shape wrong" "$OUT"

# 2. separator row is a well-formed markdown separator with the SAME column count as the header
hdr_cols=$(echo "$OUT" | head -n1 | awk -F'|' '{print NF}')
sep_cols=$(echo "$OUT" | sed -n '2p' | awk -F'|' '{print NF}')
{ echo "$OUT" | sed -n '2p' | grep -qE '^\|[-| ]+\|$' && [[ "$hdr_cols" == "$sep_cols" ]]; } \
  && pass "separator: well-formed, same column count as header ($hdr_cols)" \
  || fail "separator malformed or column-count mismatch (header=$hdr_cols sep=$sep_cols)" "$OUT"

# 3. row 1 (no canary declared) — every cell lands in the column its header names
row1="$(echo "$OUT" | sed -n '3p')"
{ echo "$row1" | grep -qE '^\| vitest \| `npm run test` \| pre-push \| frontend \| — \| — \|$'; } \
  && pass "row (no canary): id/command/stage/domain/canary-em-dash/waiver-em-dash all in place" \
  || fail "row1 cell placement wrong" "$row1"

# 4. row 2 (canary declared) — canary lands in the Canary cell, not spilling into Waiver
row2="$(echo "$OUT" | sed -n '4p')"
{ echo "$row2" | grep -qE '^\| banned \| `\.speck/scripts/banned-language-lint\.sh` \| pre-commit \| copy \| banned-language \| — \|$'; } \
  && pass "row (with canary): canary in Canary cell, Waiver still its own em-dash" \
  || fail "row2 cell placement wrong" "$row2"

# 5. --contract splice still preserves prose around the table (regression on the splice mode)
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
{ grep -q "vitest" "$CTR" && ! grep -q "stale" "$CTR" && grep -q "Prose that must survive the splice untouched." "$CTR"; } \
  && pass "--contract splice: table replaced in place, surrounding prose untouched" \
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

RT_D="$T/roundtrip"
mkdir -p "$RT_D"
git -C "$RT_D" init -q 2>/dev/null || { mkdir -p "$RT_D"; git -C "$RT_D" init -q; }
git -C "$RT_D" config user.email t@t.co; git -C "$RT_D" config user.name t
RT_CTR="$RT_D/evidence-contract.md"
cat > "$RT_CTR" <<'EOF'
# Evidence Contract

## 6. Required Static Evidence

### 6a. CI-Enforced Gate Registry

| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |
|---------|------------------|-------|--------|--------|--------|
| REPLACE_BEFORE_SHIP | — | — | — | — | — |

## 7. Required Live-Service Evidence
EOF
bash "$SEED" "$RT_RECIPE" --contract "$RT_CTR" >/dev/null
git -C "$RT_D" add -A >/dev/null 2>&1; git -C "$RT_D" commit -q -m init >/dev/null 2>&1

# --- consumer 1: validate-gate-liveness.sh (Stage/Gate-ID) ---
V_OUT="$(bash "$VALIDATE" --strict "$RT_CTR" 2>&1)"
{ echo "$V_OUT" | grep -q "GATE_MANUAL.*gate-domcheck" && echo "$V_OUT" | grep -q "GATE_MANUAL.*gate-cmdcheck"; } \
  && pass "round-trip/validate-gate-liveness: both gid+stage cells read correctly (2 distinct rows)" \
  || fail "round-trip: validate-gate-liveness misread gid/stage from a producer-seeded table" "$V_OUT"

# --- consumer 2: gate-liveness-probe.sh (Domain/Canary/Command) ---
P_OUT="$(bash "$PROBE" "$RT_D" 2>&1)"
echo "$P_OUT" | grep -q "unknown canary key" \
  && fail "round-trip/probe: canary must resolve to the real library key, not an unknown one" "$P_OUT" \
  || pass "round-trip/probe: Canary cell resolved to a real library key on both rows"
{ echo "$P_OUT" | grep -q "gate-domcheck.*domain-mismatch" && echo "$P_OUT" | grep -q "domain 'unrelated-zone'"; } \
  && pass "round-trip/probe: Domain cell extracted correctly (echoed back verbatim in the mismatch)" \
  || fail "round-trip/probe: Domain cell not extracted correctly" "$P_OUT"
{ echo "$P_OUT" | grep -q "gate-cmdcheck" && echo "$P_OUT" | grep -qF "no locally-runnable invocation resolved for '\`definitely-not-a-real-command-xyz123\`'"; } \
  && pass "round-trip/probe: Command cell extracted correctly (echoed back verbatim, unresolved)" \
  || fail "round-trip/probe: Command cell not extracted correctly" "$P_OUT"

# ===================================================================================================
echo ""
echo "== MUTATION: GATE_REGISTRY_COLUMNS is the single source for header AND row printf =="
#
# Both mutations below edit a SCRATCH COPY of the real producer ($SEED) — never the file under
# test itself. Each first confirms its sed actually matched the producer's current structure (so a
# future refactor that renames the array/function fails loudly here instead of silently no-opping
# into a false pass), then exercises the mutated copy.

# Mutation A (desync): append a column to GATE_REGISTRY_COLUMNS but leave flush()'s printf arg list
# untouched. Before this refactor, header text and row format were two independently hardcoded
# strings with no shared source — a column insert like this would just emit a differently-shaped
# table with nobody noticing. Deriving both from the SAME array turns that into a HARD failure: the
# row format string now has one more %s than flush() supplies values for, so awk itself refuses.
MUT_A="$T/seed-mut-desync.sh"
cp "$SEED" "$MUT_A"
sed -i.bak 's/GATE_REGISTRY_COLUMNS=("Gate ID" "Command \/ Script" "Stage" "Domain" "Canary" "Waiver")/GATE_REGISTRY_COLUMNS=("Gate ID" "Command \/ Script" "Stage" "Domain" "Canary" "Waiver" "Scope")/' "$MUT_A"
if diff -q "$MUT_A.bak" "$MUT_A" >/dev/null; then
  fail "mutation A setup: sed did not match GATE_REGISTRY_COLUMNS in $SEED — producer structure changed?" ""
fi

set +e
MUT_A_OUT="$(bash "$MUT_A" "$RECIPE" 2>&1)"
MUT_A_CODE=$?
set -e
{ [[ "$MUT_A_CODE" -ne 0 ]] && echo "$MUT_A_OUT" | grep -q "awk: not enough args in printf"; } \
  && pass "mutation A: column appended without updating flush() → non-zero exit + awk arg-count error" \
  || fail "mutation A: header/row desync did not surface (exit=$MUT_A_CODE)" "$MUT_A_OUT"

# Mutation B (header derivation): append a column to GATE_REGISTRY_COLUMNS AND give it a matching
# value in flush() — self-consistent, so the mutated copy still runs clean — then confirm the
# emitted HEADER ROW contains the new label. A hardcoded header string would never pick this up;
# only a header genuinely derived from GATE_REGISTRY_COLUMNS will.
MUT_B="$T/seed-mut-header.sh"
cp "$SEED" "$MUT_B"
sed -i.bak \
  -e 's/GATE_REGISTRY_COLUMNS=("Gate ID" "Command \/ Script" "Stage" "Domain" "Canary" "Waiver")/GATE_REGISTRY_COLUMNS=("Gate ID" "Command \/ Script" "Stage" "Domain" "Canary" "Waiver" "Owner")/' \
  -e 's/printf fmt, id, command, stage, (domain==""?"—":domain), c, "—"; printf "\\n"/printf fmt, id, command, stage, (domain==""?"—":domain), c, "—", "—"; printf "\\n"/' \
  "$MUT_B"
if diff -q "$MUT_B.bak" "$MUT_B" >/dev/null; then
  fail "mutation B setup: sed did not match producer structure in $SEED — producer structure changed?" ""
fi

MUT_B_OUT="$(bash "$MUT_B" "$RECIPE")"
echo "$MUT_B_OUT" | head -n1 | grep -qE '^\| Gate ID \| Command / Script \| Stage \| Domain \| Canary \| Waiver \| Owner \|$' \
  && pass "mutation B: header row is DERIVED from GATE_REGISTRY_COLUMNS (appended column appears automatically)" \
  || fail "mutation B: header did not pick up the appended column — may be hardcoded" "$MUT_B_OUT"

if [[ "$FAILED" == 0 ]]; then echo ""; echo "✅ seed-gate-registry: all tests passed"; else echo ""; echo "❌ seed-gate-registry: FAILURES"; exit 1; fi
