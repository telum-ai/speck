#!/usr/bin/env bash
# validate-wave-safety.test.sh — tests for the wave safety & concurrency collision check (#105).
#
# WHY THIS FILE WAS REWRITTEN WHOLESALE
# The four tests it replaces used the BYTE-IDENTICAL wave row `| 1 | E001, E002 | Yes |` and only
# `—` as a touch-point sentinel. Every #105 defect lived outside that one row: annotated cells,
# an all-serial table, a second table in the file, an eval'd Epics cell, "None"/"zero"
# placeholders, markdown links, bold labels, prose after the last epic. The suite was green
# because it never varied the one input the parser was wrong about.
#
# So the fixture rule here is: vary the shape the SHIPPED TEMPLATE actually authors. The template
# writes `No (foundation)` and `No (integrators)` in the parallel column and `[e.g., …]` in the
# touch-points — both were unparseable, and one of them is the #105(b) crash repro verbatim.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
# SPECK_VALIDATOR_UNDER_TEST is the mutation-harness hook (same convention as
# validate-gate-liveness.test.sh): point it at a scratch copy of the validator to confirm an
# assertion actually goes red when its fix is reverted. Unset in every normal run.
VAL="${SPECK_VALIDATOR_UNDER_TEST:-$ROOT/.speck/scripts/validation/validators/validate-wave-safety.sh}"
TEMPLATE="$ROOT/.speck/templates/project/epics-list-template.md"

FAILED=0
OUT=""
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output -----"; echo "$OUT"; echo "------------------"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

run() { RC=0; OUT=$(bash "$VAL" "$@" 2>&1) || RC=$?; }

# Findings are matched on the marker "❌ Collision (", never on the bare word. The validator's own
# banner reads "Concurrency Collision Validator", so `grep -q "Collision"` is satisfied by a run
# that found nothing — here that produced a false RED, but on a positive assertion the identical
# imprecision is a false GREEN that survives every future refactor.

# ── the mutation harness ──────────────────────────────────────────────────────────────────────
# The scratch copy is laid out at the SAME relative depth as the real validator so its
# `. "$(dirname "$0")/../../lib/text.sh"` resolves. A control that dies on a missing source is red
# for a reason that has nothing to do with the mutation, and proves nothing.
MUTDIR="$T/mut/scripts/validation/validators"
mkdir -p "$MUTDIR" "$T/mut/scripts/lib"
cp "$ROOT/.speck/scripts/lib/text.sh" "$T/mut/scripts/lib/text.sh"
MUT="$MUTDIR/validate-wave-safety.mutant.sh"

# mkmut <label> <old> <new> [<old2> <new2>] — writes $MUT with literal substring replacements.
# Fails loudly when a mutation site is gone or the mutant will not run, so a dead site can never
# masquerade as a passing control.
mkmut() {
  local label="$1"; shift
  python3 - "$VAL" "$MUT" "$@" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
pairs = sys.argv[3:]
text = open(src).read()
for i in range(0, len(pairs), 2):
    old, new = pairs[i], pairs[i + 1]
    if old not in text:
        sys.stderr.write("MUTATION SITE GONE: %r\n" % old)
        sys.exit(3)
    text = text.replace(old, new)
open(dst, "w").write(text)
PY
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    OUT="mkmut: a mutation site no longer exists in $VAL (rc=$rc)"
    fail "mutation control '$label' could not be built"
    return 1
  fi
  if diff -q "$VAL" "$MUT" >/dev/null 2>&1; then
    OUT="mkmut: the mutant is byte-identical to the validator"
    fail "mutation control '$label' changed nothing"
    return 1
  fi
  return 0
}
runmut() { MRC=0; MOUT=$(bash "$MUT" "$@" 2>&1) || MRC=$?; }

command -v python3 >/dev/null 2>&1 || { echo "  ! python3 unavailable — mutation controls skipped"; }

# ══════════════════════════════════════════════════════════════════════════════════════════════
# Fixtures
# ══════════════════════════════════════════════════════════════════════════════════════════════

# 1. The literal #105(b) repro: every row serial, in the SHIPPED TEMPLATE'S OWN annotated form.
# The old parser matched none of them, left the wave array empty, and `"${arr[@]:-}"` yields ONE
# EMPTY STRING on bash 3.2 — so `eval "epics_raw=\$wave_epics_"` died on `set -u`.
cat > "$T/all-serial.md" <<'EOF'
# Epic Breakdown: Test

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when |
|------|-------|----------------------|-------------|
| 0 | E000 | No (foundation) | Project start |
| 3 | E004, E007 | No (integrators) | Wave 2 merged |
EOF
run "$T/all-serial.md"
{ [[ "$RC" == 0 ]] && ! grep -q "unbound variable" <<<"$OUT"; } \
  && pass "#105(b): an all-serial table exits 0 and never touches an empty wave array" \
  || fail "an all-serial epics.md must not crash on 'wave_epics_: unbound variable'"

{ grep -q "0 parallel waves declared" <<<"$OUT" && grep -q "Waves parsed: 2" <<<"$OUT"; } \
  && pass "#105(b): the empty case reports what it inspected (2 waves parsed, 0 parallel)" \
  || fail "the honest-empty case must print waves-parsed, not a bare green"

{ ! grep -qE "GATE_VACUOUS|GATE_EMPTY_LEGITIMATE|SPECK_GATE_" <<<"$OUT"; } \
  && pass "no canary-owned verdict and no SPECK_GATE_* telemetry is emitted by this validator" \
  || fail "this validator must mint validator-local codes only"

# 2. An annotated `Yes (…)` wave carrying a genuine collision.
cat > "$T/annotated.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 2 | E003, E004 | Yes (distinct surfaces; no shared schema) |

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —

### E004: Four
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —
EOF
run "$T/annotated.md"
{ [[ "$RC" == 1 ]] && grep -q "models/shared.py" <<<"$OUT"; } \
  && pass "an annotated 'Yes (…)' wave is parallel, and its collision is reported" \
  || fail "an annotated Yes cell must not read as serial"

# 3. THE HEADLINE REGRESSION. Row 1 is a clean exact-`Yes` wave; row 2 is an annotated `Yes (…)`
# wave carrying TWO real collisions. The old parser matched row 1, skipped row 2, and printed
# "✅ WAVE SAFETY CHECK PASSED" with wave 2 never named anywhere in its output — a green whose
# text gave the reader no way to notice half the table was unread.
cat > "$T/headline.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Yes |
| 2 | E003, E004 | Yes (distinct surfaces; no shared schema) |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/a.py
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/b.py
- Files/Components: —

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: create table x
- Models/Services: models/shared.py
- Files/Components: —

### E004: Four
**Touch-points (creates/modifies)**:
- Migrations: create table y
- Models/Services: models/shared.py
- Files/Components: —
EOF
run "$T/headline.md"
{ [[ "$RC" == 1 ]] \
  && grep -q "Checking Wave" <<<"$OUT" \
  && grep -qE "Wave.*\b2\b|wave 2" <<<"$OUT" \
  && grep -q "Migration head" <<<"$OUT" \
  && grep -q "models/shared.py" <<<"$OUT"; } \
  && pass "headline: a clean row 1 no longer hides an annotated, colliding row 2 (both collisions reported)" \
  || fail "wave 2's migration AND shared-model collisions must both be reported"

# 4. Over-correction guard. The fix must not turn the template's own `No (…)` cells parallel —
# these two epics collide on everything and are declared serial on purpose.
cat > "$T/serial-annotated.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 0 | E001, E002 | No (foundation) |
| 3 | E003, E004 | No (integrators) |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: create table a
- Models/Services: models/shared.py
- Files/Components: src/App.tsx

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: create table b
- Models/Services: models/shared.py
- Files/Components: src/App.tsx

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: create table c
- Models/Services: models/shared.py
- Files/Components: —

### E004: Four
**Touch-points (creates/modifies)**:
- Migrations: create table d
- Models/Services: models/shared.py
- Files/Components: —
EOF
run "$T/serial-annotated.md"
{ [[ "$RC" == 0 ]] && grep -q "0 parallel waves declared" <<<"$OUT" && ! grep -q "❌ Collision (" <<<"$OUT"; } \
  && pass "'No (foundation)' / 'No (integrators)' still classify SERIAL (no over-correction)" \
  || fail "annotated No cells must stay serial — these waves collide on purpose"

# The ✅ is a claim about a comparison that happened. A run that compared zero pairs must not print
# it — the plain "0 parallel waves declared" line is the whole conclusion there.
{ ! grep -q "WAVE SAFETY CHECK PASSED" <<<"$OUT"; } \
  && pass "a zero-parallel run does not print the ✅ 'collision-free' claim" \
  || fail "the green must not outrun what the run actually inspected"

# 5. The canonical shipped template, verbatim. Behaviour preserved: exit 0, no collision. The
# fixture is the template FILE, not an excerpt — a hand-typed copy is exactly how a rule ships
# vacuous against the corpus it governs.
run "$TEMPLATE"
{ [[ "$RC" == 0 ]] && ! grep -q "❌ Collision (" <<<"$OUT"; } \
  && pass "the shipped epics-list template still exits 0 with no collision" \
  || fail "the canonical template's behaviour must be preserved"
{ grep -q "WAVE_TABLE_UNFILLED.P2" <<<"$OUT"; } \
  && pass "the template's own \`[e.g., …]\` touch-points are reported unfilled, not silently green" \
  || fail "shipped placeholders must be disclosed"

# 6. An unrelated table whose first column is an integer and whose third column is "Yes". The old
# regex ran on every line with no section state; this produced a HARD FALSE FAIL in the field.
cat > "$T/estimates.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Yes |

## Story Estimates

| Points | Epics | Confident? |
|--------|-------|-----------|
| 3 | E003, E004 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/a.py
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/b.py
- Files/Components: —

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: create table x
- Models/Services: —
- Files/Components: —

### E004: Four
**Touch-points (creates/modifies)**:
- Migrations: create table y
- Models/Services: —
- Files/Components: —
EOF
run "$T/estimates.md"
{ [[ "$RC" == 0 ]] && grep -q "Waves parsed: 1" <<<"$OUT" && ! grep -q "❌ Collision (" <<<"$OUT"; } \
  && pass "a numeric-col1 table under '## Story Estimates' is NOT parsed as a wave" \
  || fail "wave parsing must be scoped to the Concurrency Waves section"

# 7. A column inserted BEFORE "May run in parallel?". Under a positional read the parallel column
# silently re-maps to Owner and every wave becomes unrecognized.
cat > "$T/inserted-col.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | Owner | May run in parallel? | Starts when |
|------|-------|-------|----------------------|-------------|
| 1 | E001, E002 | platform | Yes | E000 merged |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: create table a
- Models/Services: —
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: create table b
- Models/Services: —
- Files/Components: —
EOF
run "$T/inserted-col.md"
{ [[ "$RC" == 1 ]] && grep -q "Migration head" <<<"$OUT" && ! grep -q "WAVE_CELL_UNRECOGNIZED" <<<"$OUT"; } \
  && pass "a column inserted before 'May run in parallel?' is still resolved BY HEADER NAME" \
  || fail "the parallel column must be resolved by name, not by position"

# 8. Command injection. Verified against the pre-#105 parser: this Epics cell interpolated into
# `eval "mig_a=\${epic_migrations_${epic_a}:-}"` and CREATED THE FILE ON DISK during validation.
PWN="$T/PWNED"
rm -f "$PWN"
cat > "$T/inject.md" <<EOF
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002:-\$(touch $PWN) | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/a.py
- Files/Components: —
EOF
run "$T/inject.md"
{ [[ ! -e "$PWN" ]] && grep -q "WAVE_EPIC_UNPARSED.P2" <<<"$OUT"; } \
  && pass "an Epics cell carrying a command substitution executes nothing and is reported unparsed" \
  || fail "the epics cell must never reach an eval — and an unparseable token must be a finding"

# 9. Decorated epic tokens and every declared separator: `,` `+` `/` `;` and the WORD ` and `.
# sp_split_toplevel splits on CHARACTERS, so " and " must be normalised to a comma first or
# "E001 and E002" comes back as one unparseable field and a real collision is silently skipped.
cat > "$T/separators.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | **E001** (foundation) + `E002` / _E003_; E004 and E005 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/b.py
- Files/Components: —

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/c.py
- Files/Components: —

### E004: Four
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/d.py
- Files/Components: —

### E005: Five
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —
EOF
run "$T/separators.md"
{ grep -q "E001 E002 E003 E004 E005" <<<"$OUT"; } \
  && pass "decorated tokens and the ',' '+' '/' ';' ' and ' separators all resolve to epic ids" \
  || fail "every declared separator (including the WORD 'and') must split the Epics cell"
{ [[ "$RC" == 1 ]] && grep -q "models/shared.py" <<<"$OUT" && ! grep -q "WAVE_EPIC_UNPARSED" <<<"$OUT"; } \
  && pass "the E001↔E005 collision across the ' and ' boundary IS detected" \
  || fail "a collision at the far end of the separator chain must still be found"

# 10. Every placeholder sentinel, each paired against E000's REAL migration. If any one of them
# parses as a real migration list, the migration-head collision fires. "zero" is the word
# AGENTS.md itself uses for this state; "None" and "N/A" are what humans type.
cat > "$T/sentinels.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E000, E001, E002, E003, E004, E005, E006, E007, E008 | Yes |

### E000: Anchor
**Touch-points (creates/modifies)**:
- Migrations: create table anchor
- Models/Services: —
- Files/Components: —

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: None
- Models/Services: —
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: none
- Models/Services: —
- Files/Components: —

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: N/A
- Models/Services: —
- Files/Components: —

### E004: Four
**Touch-points (creates/modifies)**:
- Migrations: TBD
- Models/Services: —
- Files/Components: —

### E005: Five
**Touch-points (creates/modifies)**:
- Migrations: zero
- Models/Services: —
- Files/Components: —

### E006: Six
**Touch-points (creates/modifies)**:
- Migrations: (none)
- Models/Services: —
- Files/Components: —

### E007: Seven
**Touch-points (creates/modifies)**:
- Migrations: –
- Models/Services: —
- Files/Components: —

### E008: Eight
**Touch-points (creates/modifies)**:
- Migrations: -
- Models/Services: —
- Files/Components: —
EOF
run "$T/sentinels.md"
{ [[ "$RC" == 0 ]] && ! grep -q "❌ Collision (" <<<"$OUT"; } \
  && pass "None/none/N-A/TBD/zero/(none)/en-dash/em-dash/hyphen all read as 'no migrations'" \
  || fail "a placeholder sentinel must never fabricate a migration collision"
{ grep -q "epic pairs compared: 36" <<<"$OUT"; } \
  && pass "the sentinel green reports its exposure (36 pairs compared, not 0)" \
  || fail "the summary must prove the green actually inspected the pairs"

# 11. A markdown link is a REAL value. The old sentinel test discarded anything starting with `[`,
# so `[models/shared.py](../src/models/shared.py)` on both epics produced a green PASS over a
# genuine collision. Verified against the pre-#105 parser.
cat > "$T/mdlink.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: None
- Models/Services: N/A
- Files/Components: [models/shared.py](../src/models/shared.py)

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: zero
- Models/Services: TBD
- Files/Components: [models/shared.py](../src/models/shared.py)
EOF
run "$T/mdlink.md"
{ [[ "$RC" == 1 ]] && grep -q "Shared files/components" <<<"$OUT" && grep -q "models/shared.py" <<<"$OUT"; } \
  && pass "a markdown-link touch-point is a real value, and its collision IS detected" \
  || fail "a markdown link must not be discarded as a placeholder"

# 12. Bold labels and alternate bullet glyphs. The old regexes required one bullet glyph, no bold,
# and no space before the colon — shapes a human writes without thinking parsed as "no touchpoints".
cat > "$T/labels.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
* **Migrations** : create table a
+ **Models/Services**: models/shared.py
* Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- **Migrations**: create table b
- **Models/Services** : models/shared.py
- Files/Components: —
EOF
run "$T/labels.md"
{ [[ "$RC" == 1 ]] && grep -q "Migration head" <<<"$OUT" && grep -q "models/shared.py" <<<"$OUT"; } \
  && pass "bolded labels, '*'/'+' bullets and a space before the colon all parse" \
  || fail "the touch-point label forms a human actually writes must parse"

# 13. Prose mentioning touch-points AFTER the last epic. The old state machine re-armed on the
# bare substring anywhere and reset only on `^---`/`^###`, so a following prose line was attributed
# to the last epic as a migration. Verified false FAIL.
cat > "$T/prose.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: create table a
- Models/Services: —
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/b.py
- Files/Components: —

## Notes

Each epic's Touch-points block above is the contract for wave safety.
- Migrations: keep one author per wave.
- Models/Services: list every file you expect to edit.
EOF
run "$T/prose.md"
{ [[ "$RC" == 0 ]] && ! grep -q "❌ Collision (" <<<"$OUT"; } \
  && pass "prose mentioning 'Touch-points' after the last epic fabricates nothing" \
  || fail "the touch-points state must be anchored, and must reset on any heading"

# 14. Duplicate wave ids, with the collision on the FIRST row. The old store overwrote silently,
# so the second row's epics replaced the first row's and erased its collisions.
cat > "$T/dup-wave.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Yes |
| 1 | E003, E004 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/c.py
- Files/Components: —

### E004: Four
**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/d.py
- Files/Components: —
EOF
run "$T/dup-wave.md"
{ [[ "$RC" == 1 ]] && grep -q "WAVE_ID_DUPLICATE.P1" <<<"$OUT" && grep -q "models/shared.py" <<<"$OUT"; } \
  && pass "a duplicate wave id is a P1, and the FIRST row's collision is still found" \
  || fail "a later wave row must never overwrite an earlier one"

# 15. A shipped-placeholder epics.md — planned but never filled in. Reported, non-blocking by
# default (the sole caller invokes bare), blocking under --strict.
cat > "$T/unfilled.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: [e.g., create table auto_reply_config]
- Models/Services: [e.g., models/availability.py]
- Files/Components: [e.g., src/components/AvailabilityCard.tsx]

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: [e.g., create table crew_members]
- Models/Services: [e.g., models/crew.py]
- Files/Components: [e.g., src/components/CrewCard.tsx]
EOF
run "$T/unfilled.md"
{ [[ "$RC" == 0 ]] && grep -q "WAVE_TABLE_UNFILLED.P2" <<<"$OUT"; } \
  && pass "an unfilled epics.md is a disclosed P2, exit 0 by default" \
  || fail "shipped placeholders must be reported without breaking the bare caller"
run --strict "$T/unfilled.md"
{ [[ "$RC" == 1 ]]; } \
  && pass "--strict escalates the P2 tier to exit 1" \
  || fail "--strict must fail on a P2"

# 16. An epic named in a parallel wave with no `### EXXX` section. The old parser resolved it to
# "touches nothing" through `:-` defaults and passed.
cat > "$T/undefined-epic.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E009 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: create table a
- Models/Services: models/a.py
- Files/Components: —
EOF
run "$T/undefined-epic.md"
{ [[ "$RC" == 0 ]] && grep -q "WAVE_EPIC_UNDEFINED.P2" <<<"$OUT" && grep -q "E009" <<<"$OUT"; } \
  && pass "an epic with no section is 'touch-points unknown, not proven safe' (P2)" \
  || fail "an undefined epic must not resolve to 'touches nothing'"

# 17. Three migration-authoring epics in one wave. That is ONE condition — a single migration head
# with too many authors — and the C(N,2) loop reported it three times, so the printed count grew
# quadratically with the size of the real problem.
cat > "$T/three-mig.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002, E003 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: create table a
- Models/Services: —
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: create table b
- Models/Services: —
- Files/Components: —

### E003: Three
**Touch-points (creates/modifies)**:
- Migrations: create table c
- Models/Services: —
- Files/Components: —
EOF
run "$T/three-mig.md"
n_mig=$(grep -c "❌ Collision (Migration head)" <<<"$OUT" || true)
{ [[ "$RC" == 1 ]] && [[ "$n_mig" == 1 ]] && grep -q "E001, E002, E003" <<<"$OUT"; } \
  && pass "three migration authors in one wave = ONE finding naming all three" \
  || fail "the migration finding must be per-wave, not per-pair (got $n_mig findings)"

# 18. A headerless legacy table still parses through the disclosed positional fallback.
cat > "$T/headerless.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| 1 | E001, E002 | Yes |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: create table a
- Models/Services: —
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: create table b
- Models/Services: —
- Files/Components: —
EOF
run "$T/headerless.md"
{ [[ "$RC" == 1 ]] && grep -q "Migration head" <<<"$OUT"; } \
  && pass "a headerless legacy table falls back to the historical Wave|Epics|Parallel layout" \
  || fail "the positional fallback must still parse a pre-header table"

# 19. An unrecognised parallel cell is treated as PARALLEL and checked. Fail-toward-checking: a
# missed parallel wave is the unrecoverable direction, a spurious check is a visible finding.
cat > "$T/unrecognized.md" <<'EOF'
## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? |
|------|-------|----------------------|
| 1 | E001, E002 | Probably, ask the platform team |

### E001: One
**Touch-points (creates/modifies)**:
- Migrations: create table a
- Models/Services: —
- Files/Components: —

### E002: Two
**Touch-points (creates/modifies)**:
- Migrations: create table b
- Models/Services: —
- Files/Components: —
EOF
run "$T/unrecognized.md"
{ [[ "$RC" == 1 ]] && grep -q "WAVE_CELL_UNRECOGNIZED.P2" <<<"$OUT" \
  && grep -q "Probably, ask the platform team" <<<"$OUT" && grep -q "Migration head" <<<"$OUT"; } \
  && pass "an unrecognised cell is named verbatim, treated as parallel, and its wave IS checked" \
  || fail "an unrecognised parallel cell must fail toward checking"

# 20. No Concurrency Waves section at all — plain descriptive text, exit 0, no green claiming a
# check happened and no canary verdict borrowed from gate-liveness-probe.sh.
printf '# Epic Breakdown\n\n### E001: One\n\n**Touch-points (creates/modifies)**:\n- Migrations: create table a\n' > "$T/no-section.md"
run "$T/no-section.md"
{ [[ "$RC" == 0 ]] && grep -q 'No "Concurrency Waves" section found' <<<"$OUT" \
  && ! grep -qE "GATE_VACUOUS|SPECK_GATE_" <<<"$OUT"; } \
  && pass "no waves section → a plain, validator-local description, exit 0" \
  || fail "the no-section case must be described in plain text, not with a canary verdict"

# 21. Invocation errors stay exit 2.
run "$T/does-not-exist.md"
{ [[ "$RC" == 2 ]]; } && pass "a missing file is exit 2 (invocation error)" || fail "missing file must be exit 2"
RC=0; OUT=$(bash "$VAL" 2>&1) || RC=$?
{ [[ "$RC" == 2 ]]; } && pass "no argument is exit 2" || fail "no argument must be exit 2"

# 21b. A CRLF epics.md. \r survives on the last cell of every row, and it defeated the
# separator-row test — `|---|---|\r` is not all dashes, so the separator was promoted to a wave row
# and the waves-parsed count (the number a caller reads to judge exposure) came back inflated.
printf '## Epic Concurrency Waves\r\n\r\n| Wave | Epics | May run in parallel? |\r\n|------|-------|------|\r\n| 1 | E001, E002 | Yes |\r\n\r\n### E001: One\r\n**Touch-points (creates/modifies)**:\r\n- Migrations: create table a\r\n\r\n### E002: Two\r\n**Touch-points (creates/modifies)**:\r\n- Migrations: create table b\r\n' > "$T/crlf.md"
run "$T/crlf.md"
{ [[ "$RC" == 1 ]] && grep -q "Waves parsed: 1" <<<"$OUT" && grep -q "❌ Collision (Migration head)" <<<"$OUT" \
  && ! grep -q "WAVE_CELL_UNRECOGNIZED" <<<"$OUT"; } \
  && pass "a CRLF epics.md parses to 1 wave (not 2) and its collision is found" \
  || fail "carriage returns must not promote the separator row into a wave"

# 22. The directory fallback globs specs/projects/* and takes the first hit. A SILENT first match
# is how a validator reports a clean run on a different project than the caller meant, so the pick
# is announced in the header.
mkdir -p "$T/proj/specs/projects/001-alpha"
cp "$T/headline.md" "$T/proj/specs/projects/001-alpha/epics.md"
run "$T/proj"
{ [[ "$RC" == 1 ]] && grep -q "Project selected by directory fallback: $T/proj/specs/projects/001-alpha" <<<"$OUT"; } \
  && pass "the directory fallback announces which project it selected" \
  || fail "a first-match glob over specs/projects/* must disclose its pick"

# 23. The banner version is READ, not frozen. It printed "v7.18.0" on every release after the one
# that wrote it — a truthful-looking number that was wrong by construction.
run "$T/all-serial.md"
{ ! grep -q "v7\.18\.0" <<<"$OUT"; } \
  && pass "the banner no longer prints the frozen v7.18.0 literal" \
  || fail "the version banner must not be hard-coded"
if [[ "$VAL" == "$ROOT/.speck/scripts/validation/validators/validate-wave-safety.sh" ]]; then
  # Only meaningful for the SHIPPED validator: a scratch copy outside the repo has no .speck/VERSION
  # above it and honestly reports "unknown".
  SPECK_VER="$(tr -d ' \n' < "$ROOT/.speck/VERSION" 2>/dev/null || true)"
  { [[ -n "$SPECK_VER" ]] && grep -q "(v$SPECK_VER)" <<<"$OUT"; } \
    && pass "the banner reads the real .speck/VERSION ($SPECK_VER)" \
    || fail "the banner must carry the version from .speck/VERSION"
fi

# ══════════════════════════════════════════════════════════════════════════════════════════════
# Mutation controls — each headline assertion above is credited only if a scratch copy of the
# validator with THAT fix reverted produces the OLD answer.
# ══════════════════════════════════════════════════════════════════════════════════════════════
if command -v python3 >/dev/null 2>&1; then

  # M1 — revert the #105(a) cell reduction to the v7.18 exact-match test, and revert
  # unrecognised→parallel to unrecognised→serial. Together these ARE the old predicate, and the
  # headline fixture must go back to the green that never named wave 2.
  if mkmut "M1 exact-match parallel cell" \
      'tok="$(lower "$(first_token "$(sp_strip_qualifier "$s")")")"' \
      'tok="$(lower "$s")"' \
      '      verdict="parallel"' \
      '      verdict="serial"'; then
    runmut "$T/headline.md"
    { [[ "$MRC" == 0 ]] && ! grep -q "❌ Collision (" <<<"$MOUT"; } \
      && pass "M1: reverting the cell reduction restores the #105 green (mutant misses wave 2)" \
      || { OUT="$MOUT"; fail "M1 mutant should reproduce the old false PASS (rc=$MRC)"; }
  fi

  # M2 — the crash class: read the wave store past its actual extent under `set -u`. The historical
  # `"${arr[@]:-}"` idiom is gone (the fix replaced it with an index loop), so the mutation
  # reproduces the failure MODE the assertion guards — an unbound array read on the wave store —
  # rather than the retired idiom.
  if mkmut "M2 unbound wave-store read" \
      'for (( r=0; r<waves_parsed; r++ )); do' \
      'for (( r=0; r<=waves_parsed; r++ )); do'; then
    runmut "$T/all-serial.md"
    { [[ "$MRC" != 0 ]] && grep -q "unbound variable" <<<"$MOUT"; } \
      && pass "M2: an off-by-one on the wave store reproduces the #105(b) 'unbound variable' abort" \
      || { OUT="$MOUT"; fail "M2 mutant should crash with 'unbound variable' (rc=$MRC)"; }
  fi

  # M3 — revert is_placeholder to the v7.18 sentinel set (leading `[`, em dash, bare hyphen only).
  # The sentinel fixture must go back to fabricating a migration collision out of "None"/"zero".
  if mkmut "M3 narrow placeholder set" \
      "''|'-'|'--'|'—'|'–'|'none'|'no'|'n/a'|'na'|'nil'|'nothing'|'not applicable'|'tbd'|'tba'|'tbc'|'zero'|'0')" \
      "''|'-'|'—')"; then
    runmut "$T/sentinels.md"
    { [[ "$MRC" == 1 ]] && grep -q "Migration head" <<<"$MOUT"; } \
      && pass "M3: the narrow sentinel set fabricates a migration collision out of None/zero" \
      || { OUT="$MOUT"; fail "M3 mutant should fabricate a collision (rc=$MRC)"; }
  fi

  # M4 — revert the markdown-link acquittal: any leading `[` is a placeholder again. The real
  # collision must disappear behind a green.
  if mkmut "M4 markdown link discarded" \
      "if [[ \"\$s\" == '['* && \"\$s\" != *']('* ]]; then return 0; fi" \
      "if [[ \"\$s\" == '['* ]]; then return 0; fi"; then
    runmut "$T/mdlink.md"
    { [[ "$MRC" == 0 ]] && ! grep -q "❌ Collision (" <<<"$MOUT"; } \
      && pass "M4: discarding markdown links restores the green that hid a real collision" \
      || { OUT="$MOUT"; fail "M4 mutant should hide the collision (rc=$MRC)"; }
  fi
fi

# ── the over-correction pair (found by running the fix, not by reading it) ────────────────────
# Both of these were introduced BY the #105 fix and caught only because the original issue repro
# was re-run against the finished validator. They are the reason this block exists: a rewrite that
# closes a false negative is exactly where the next false negative gets authored.

# 1. The first draft anchored the touch-points header on `**`. The shipped template emits bold, so
#    every fixture in this file passed — while a hand-written `Touch-points:` captured NOTHING and
#    two epics sharing a model file reported a clean PASS at exit 0.
cat > "$T/plain-header.md" <<'EOF'
# Epics

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when |
|------|-------|----------------------|-------------|
| 1 | E001, E002 | Yes | now |

### E001: One

Touch-points:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —

### E002: Two

Touch-points:
- Migrations: —
- Models/Services: models/shared.py
- Files/Components: —
EOF
run "$T/plain-header.md"
{ [[ "$RC" == 1 ]] && grep -q "❌ Collision (" <<<"$OUT"; } \
  && pass "an UNBOLDED 'Touch-points:' header is still parsed — the shared model file collides" \
  || fail "unbolded touch-points header hid a real collision (rc=$RC)"

# 2. …and the anti-prose property the bold anchor was reaching for must survive widening it. A
#    sentence carrying text PAST the colon is not a header and must not re-open the block.
run "$T/plain-header.md"   # baseline captured above; now the prose variant
cat > "$T/prose-rearm.md" <<'EOF'
# Epics

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when |
|------|-------|----------------------|-------------|
| 1 | E001, E002 | Yes | now |

### E001: One

**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/a.py
- Files/Components: —

### E002: Two

**Touch-points (creates/modifies)**:
- Migrations: —
- Models/Services: models/b.py
- Files/Components: —

## Notes

Touch-points are important: they matter a lot.
- Models/Services: models/a.py
EOF
run "$T/prose-rearm.md"
{ [[ "$RC" == 0 ]] && ! grep -q "❌ Collision (" <<<"$OUT"; } \
  && pass "prose carrying text past the colon does NOT re-arm the touch-points block" \
  || fail "prose after the last epic fabricated a collision (rc=$RC)"

# 3. The exposure counter must count what was READ, not what exists. It reported the registered
#    `### EXXX` headers, so a run that captured zero touch-points still printed "3" beside a PASS.
cat > "$T/unparsed-tp.md" <<'EOF'
# Epics

## Epic Concurrency Waves & Rebase Cadence

| Wave | Epics | May run in parallel? | Starts when |
|------|-------|----------------------|-------------|
| 1 | E001, E002 | Yes | now |

### E001: One

Files touched by this epic are still being worked out.

### E002: Two

Files touched by this epic are still being worked out.
EOF
run "$T/unparsed-tp.md"
{ [[ "$RC" == 0 ]] && grep -q "epics with parsed touch-points: 0/2" <<<"$OUT"; } \
  && pass "the exposure line reports 0/2 when nothing was parsed — never the epic count" \
  || fail "exposure counter overstated its reach (rc=$RC)"

if [[ "$FAILED" == 0 ]]; then
  echo "✅ validate-wave-safety: all tests passed"
else
  echo "❌ validate-wave-safety: FAILURES"
  exit 1
fi
