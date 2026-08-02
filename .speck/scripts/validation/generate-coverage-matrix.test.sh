#!/usr/bin/env bash
# generate-coverage-matrix.test.sh — pins the PERSONA UNIVERSE the skeleton emitter enumerates.
#
# Why this file exists (#101 P3). `generate-coverage-matrix.sh` hardcodes the persona set in one
# string. #84 seeded it with CONSUMER BREADTH — one identity in many states — so for two whole
# releases the matrix could be 100% RUN and still be structurally blind to:
#   • a second ACTOR (the cross-user write: A's rows/queue/receipts readable by B on the same
#     install), because every persona in the set was the same principal, and
#   • an IMPATIENT actor (double-tap, background mid-write, kill between request and response),
#     because every persona in the set waited politely for the spinner.
# The set was a bare constant with no gate, which is exactly how a breadth universe silently
# narrows. These assertions make the constant a control point: dropping either row goes red.
#
# The subject is the SHIPPED generator run end-to-end (never a hand-typed fixture of its output) —
# a fixture that omits the emitter's real boilerplate is how a vacuous assertion gets written.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../" && pwd)"
GEN="$ROOT/.speck/scripts/validation/generate-coverage-matrix.sh"
VAL="$ROOT/.speck/scripts/validation/validators/validate-coverage-matrix.sh"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# --- subject: a real epic dir with a filled experience-chain §2 table, run through the emitter ---
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

bash "$GEN" --level epic "$T/e1" >/dev/null 2>&1
M="$T/e1/coverage-matrix.md"
if [[ ! -f "$M" ]]; then
  echo "  ✗ generator produced no coverage-matrix.md — cannot test the persona universe"
  exit 1
fi

# The universe line is the one the FILLER reads. Assert against that line, not the whole file, so a
# persona name appearing only inside an unrelated prose paragraph cannot satisfy this test.
UNIVERSE="$(grep -m1 '^\- \*\*personas\*\*:' "$M" || true)"
[[ -n "$UNIVERSE" ]] || fail "no '- **personas**:' universe line in the generated matrix"

# 1. #84's consumer-breadth set must not regress while adding to it.
missing84=""
for p in naive-hostile connoisseur-hostile returning-user skeptical-buyer power-user a11y-first locale-switcher low-bandwidth; do
  case "$UNIVERSE" in *"$p"*) ;; *) missing84="$missing84 $p" ;; esac
done
[[ -z "$missing84" ]] && pass "#84 consumer-breadth personas still enumerated" \
  || fail "#84 personas dropped from the universe:$missing84"

# 2. #101 P3: the two rows the consumer-breadth set structurally cannot reach.
case "$UNIVERSE" in *second-actor*) pass "universe enumerates 'second-actor' (the cross-user write persona)" ;;
  *) fail "universe has no 'second-actor' persona — identity/tenancy defects are invisible to this matrix" ;; esac
case "$UNIVERSE" in *impatient*) pass "universe enumerates 'impatient'" ;;
  *) fail "universe has no 'impatient' persona — partial-write/state-claim defects go unreached" ;; esac

# 3. A NAME in a list is not routable. Each new persona must ship an actionable definition in the
#    generated artifact, or a filler invents its own and the breadth claim means nothing.
SA_DEF="$(grep -m1 '`second-actor`' "$M" || true)"
if [[ -n "$SA_DEF" ]] \
   && printf '%s' "$SA_DEF" | grep -qi 'same install' \
   && printf '%s' "$SA_DEF" | grep -qi 'per persistence layer'; then
  pass "'second-actor' carries its protocol (same install · per persistence layer)"
else
  fail "'second-actor' has no actionable definition (needs 'same install' + 'per persistence layer')"
fi

IM_DEF="$(grep -m1 '`impatient`' "$M" || true)"
if [[ -n "$IM_DEF" ]] && printf '%s' "$IM_DEF" | grep -qiE 'double-tap|background mid-write|between request and response'; then
  pass "'impatient' carries its protocol (double-tap / background / kill mid-write)"
else
  fail "'impatient' has no actionable definition (needs the not-waiting behaviours)"
fi

# 4. The added prose must not break the grid parser the validator reads (the definitions sit in the
#    universe section, above '## Cell status grid'). Non-strict must still pass.
if bash "$VAL" "$M" >/dev/null 2>&1; then
  pass "generated matrix still parses for validate-coverage-matrix.sh (non-strict)"
else
  fail "the persona definitions broke validate-coverage-matrix.sh parsing"
fi

if [[ "$FAILED" == 0 ]]; then echo "✅ generate-coverage-matrix: all tests passed"; else echo "❌ generate-coverage-matrix: FAILURES"; exit 1; fi
