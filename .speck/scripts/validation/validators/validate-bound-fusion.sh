#!/usr/bin/env bash
# validate-bound-fusion.sh — the mechanical slice of issue #93's CLASS 3: a QUALITY bound fused to
# an EXISTENCE bound.
#
# #93 class 3: "not good enough yet" and "not yet" are indistinguishable in an artifact when one
# field carries both. Fused, the quality bar ANNEXES the go/no-go and the gate can never fail
# loudly — every blocked thing reads as merely unripe. #93 filed this as the one class of its five
# with NO mechanism, and the first write-up
# Speck's methodology analysis concluded the same, calling
# out one specific structural property it declined to build. This is that property, built.
#
# THE DISCRIMINATOR #93 GIVES: self-held is fine when the bound governs CONTENT; pathological when
# it decides EXISTENCE.
#
# WHY THE SUBJECT IS THE MACHINERY, NEVER AN ARTIFACT. In a story's validation report, "not good
# enough yet" and "not yet" really are indistinguishable — that is the class's whole premise, so a
# check that read reports would either convict honest "not ready" reports or convict nothing.
# Convicting an honest "not ready" is the worse error by a distance: it teaches authors to route
# around the state, which is precisely the behaviour class 3 describes. So this check never reads a
# story, an epic, or a report, and CANNOT convict one. Its subject is Speck's own gate machinery —
# where the fusion is decidable, because the rungs a quality axis is allowed to gate are written
# down in code as an enumerated set.
#
# WHAT THIS CHECKS
#   Speck's readiness ladder splits into an EXISTENCE floor (does the code exist / run / integrate:
#   NO-SHIP, IMPL-GREEN, INTEGRATION-GREEN) and QUALITY rungs above it (UX-RC and up, explicitly
#   gated on the FELT-GOOD / TASTE axes). The separation is load-bearing and is enforced today only
#   by two files independently continuing to agree — `validate-felt-axis.sh` and
#   `validate-taste-axis.sh` each scope their enforcement to `UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP` via
#   a rung predicate. Nothing stops a later edit from adding `INTEGRATION-GREEN` to that `case`
#   arm, and the day it does, an uncovered TASTE pass caps a story below the existence floor: a
#   team that shipped a rough-but-working flow and a team that shipped nothing now emit the same
#   signal. That edit is one token wide, reviews as a tightening, and is silent.
#
#   So, for every QUALITY-AXIS validator (a validator whose subject is a quality axis field —
#   `felt_axis` / `taste_axis`), this asserts:
#     A. its enforcement rung-set — the rungs on a `case` arm that returns 0 — is NON-EMPTY, and
#     B. that set is DISJOINT from the existence rungs.
#   Plus two anti-vacuity assertions, because "found nothing" and "there was nothing to find" are
#   the two states this release line exists to keep apart:
#     C. EVERY quality axis the shipped template declares has at least one validator enforcing it
#        (else the check quietly inspected a smaller world than the one that exists), and
#     D. every existence rung this check reasons about still EXISTS in the shipped ladder, read
#        from validation-report-template.md's frontmatter — not hard-coded belief about it. A
#        renamed or dropped rung makes the check UNDECIDABLE and loud, never silently clear.
#
# SUBJECT DISCOVERY IS DERIVED, NOT LISTED. The set of quality axes is read from
# validation-report-template.md's frontmatter (`*_axis:` keys), and a validator counts as
# enforcing an axis when it names that axis in CODE and raises a blocking error (`log_error`). A
# hard-coded list of two filenames would go stale the day a third axis lands and would report
# green about a file it never heard of; assertion C is what makes that failure loud instead.
#
# THE CHECK READS CODE, NOT PROSE. Every line is comment-stripped before evidence is evaluated —
# the same discipline validate-two-carrier.sh had to learn the hard way. Both quality-axis
# validators discuss `UX-RC+`, `IMPL-GREEN` and the ladder at length in their header comments; a
# prose-blind version would read those comments as enforcement and could be defeated, or fooled,
# by a sentence.
#
# WHAT THIS DOES NOT CHECK (disclosed, not silently skipped)
#   - Whether a cap directive written in PROSE names a rung floor. The one unbounded quality cap in
#     the shipped machinery is real and located — validation-report-template.md's "A **severe BAD**
#     … caps the claimable state", which names no floor, so on its face a craft verdict caps
#     arbitrarily far down. It is NOT mechanized here: a grep over template prose is the exact
#     shape of rule this repo has already shipped vacuous twice (a rule the shipped template's own
#     boilerplate satisfies), and the repair is one human sentence, not a scanner. It is written up
#     as a located residual in quality-bound-vs-existence-bound.md instead of fabricated into a
#     gate.
#   - Whether a quality-axis error that fires OUTSIDE the rung predicate is a fusion. Some are not:
#     `validate-taste-axis.sh`'s unqualified-"premium"-claim rule fires at any rung, and correctly
#     so — it triggers only on an aesthetic claim the author VOLUNTEERED, and its repair is to drop
#     the word, not to get better. Distinguishing that from a bare "the axis is uncovered" blocker
#     needs the enclosing condition of each call, i.e. a shell parser this script does not have.
#     Convicting it would be a false positive of exactly the kind that trains routing-around.
#   - Any per-project artifact. By construction. See above.
#
# Usage:  validate-bound-fusion.sh [--strict] [<repo-root>]
# Exit:   0 = no findings (or findings without --strict); 1 = findings under --strict;
#         2 = invocation error.
#
# Every exit path emits SPECK_GATE_SCOPE / SPECK_GATE_SUBJECT / SPECK_GATE_PREDICATES /
# SPECK_GATE_MODE (the v10 gate-telemetry contract), so "scanned 2 quality-axis validators, both
# disjoint" is distinguishable from "scanned nothing".

set -euo pipefail

GATE_SCOPE="none"
FILES_SCANNED=0
QUALITY_VALIDATORS=0
TELEMETRY_EMITTED=false
emit_gate_telemetry() {
  [[ "$TELEMETRY_EMITTED" == true ]] && return 0
  TELEMETRY_EMITTED=true
  echo "SPECK_GATE_SCOPE=$GATE_SCOPE"
  echo "SPECK_GATE_SUBJECT=$FILES_SCANNED"
  echo "SPECK_GATE_PREDICATES=$QUALITY_VALIDATORS"
  echo "SPECK_GATE_MODE=static"
}
trap emit_gate_telemetry EXIT

STRICT_MODE=false
ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT_MODE=true; shift ;;
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) ROOT="$1"; shift ;;
  esac
done

if [[ -z "$ROOT" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../" && pwd)"
fi
if [[ ! -d "$ROOT" ]]; then
  echo "ERROR: root '$ROOT' is not a directory." >&2
  exit 2
fi

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

LADDER_FILE="$ROOT/.speck/templates/story/validation-report-template.md"
VALIDATOR_DIR="$ROOT/.speck/scripts/validation/validators"
GATE_SCOPE="$VALIDATOR_DIR/*.sh (quality-axis validators)"

findings=0
report=""
COVERED_AXES=""
add_finding() {
  findings=$((findings + 1))
  report="${report}
$1"
}

echo -e "${BLUE}🔎 Checking that no QUALITY bound reaches below the EXISTENCE floor (#93 class 3)...${NC}"
echo "   root: $ROOT"

# ── D. The ladder, read from the shipped template rather than believed ────────────────────────
# Hard-coding the rung names here and never checking them is how a check keeps passing after the
# thing it names has been renamed. The ladder is parsed; the existence rungs this check reasons
# about must still appear in it, or the verdict is UNDECIDABLE and loud.
EXISTENCE_RUNGS="NO-SHIP IMPL-GREEN INTEGRATION-GREEN"
LADDER=""
if [[ -f "$LADDER_FILE" ]]; then
  # `readiness_state_claimed: [NO-SHIP | IMPL-GREEN | … | SHIP]` — one line, frontmatter.
  LADDER="$(awk '
    /^readiness_state_claimed:/ {
      line = $0
      sub(/^[^[]*\[/, "", line)
      sub(/\].*$/, "", line)
      gsub(/[ \t]/, "", line)
      gsub(/\|/, " ", line)
      print line
      exit
    }' "$LADDER_FILE")"
fi

if [[ -z "$LADDER" ]]; then
  add_finding "${RED}❌ BOUND_FUSION_UNDECIDABLE.P2${NC}: could not read the readiness ladder from
   $LADDER_FILE (expected a \`readiness_state_claimed: [ … ]\` frontmatter line).
   Without the ladder this check cannot tell an existence rung from a quality rung, so it
   reports UNDECIDABLE rather than clean. A missing subject is not a passing subject."
else
  missing=""
  for rung in $EXISTENCE_RUNGS; do
    found=false
    for have in $LADDER; do [[ "$have" == "$rung" ]] && found=true; done
    [[ "$found" == false ]] && missing="$missing $rung"
  done
  if [[ -n "$missing" ]]; then
    add_finding "${RED}❌ BOUND_FUSION_LADDER_DRIFT.P2${NC}: the existence rung(s)${missing} are no longer
   present in the shipped ladder ($LADDER).
   This check's existence floor was pinned to rungs that have since been renamed or removed, so
   every verdict it renders about them is stale. Re-derive the existence floor deliberately
   (which rungs answer \"does it exist / run / integrate\"?) and update EXISTENCE_RUNGS — do not
   silently accept a green from a check that no longer knows what it is measuring."
  fi
fi

# ── C (part 1). The quality axes, derived from the shipped template's own frontmatter ─────────
# `felt_axis:` / `taste_axis:` — whatever the template declares, that is the world this check owes
# coverage of. A third axis landing tomorrow enlarges the subject automatically; if nothing
# enforces it, assertion C below says so out loud.
QUALITY_AXES=""
if [[ -f "$LADDER_FILE" ]]; then
  QUALITY_AXES="$(awk '
    /^---[ \t]*$/ { fm++; if (fm == 2) exit; next }
    fm == 1 && /^[a-z_]+_axis:/ { k = $0; sub(/:.*$/, "", k); print k }
  ' "$LADDER_FILE" | sort -u | tr '\n' ' ')"
fi
if [[ -z "$QUALITY_AXES" ]]; then
  add_finding "${RED}❌ BOUND_FUSION_NO_SUBJECT.P2${NC}: no quality-axis field (\`*_axis:\`) found in the
   frontmatter of $LADDER_FILE.
   This check derives its subject from the template rather than from a hard-coded list, so an
   empty derivation means it would inspect nothing. Reported as a finding, never as a pass."
fi

# ── The per-file scan ─────────────────────────────────────────────────────────────────────────
# One awk pass per candidate. STDOUT contract (first line, always exactly one of):
#   NOT_A_QUALITY_VALIDATOR  — the file does not ENFORCE on any declared quality axis. Two things
#                              are required, not one: the axis named in CODE, and a blocking
#                              `log_error` call. Naming an axis without blocking on it (a meta-tool
#                              — this very file mentions both axes in its scanner) is not a
#                              quality-axis validator, and must not be scanned as one.
#   NO_RUNG_PREDICATE        — it is a quality-axis validator, but no `RUNGS…) return 0 ;;` arm was
#                              found: undecidable, reported loudly.
#   RUNGSET <rung> <rung> …  — the enforcement rung-set, deduped. Second line: AXES <axis> …
SCAN_AWK="$(mktemp)"
trap 'rm -f "$SCAN_AWK"; emit_gate_telemetry' EXIT

cat > "$SCAN_AWK" <<'AWK'
# Read CODE, not prose. Both quality-axis validators narrate the ladder in their header comments;
# a prose-blind scan would take a sentence for an enforcement decision.
function strip_comment(s,   i) {
  if (s ~ /^[ \t]*#/) return ""
  i = index(s, " #");  if (i > 0) s = substr(s, 1, i - 1)
  i = index(s, "\t#"); if (i > 0) s = substr(s, 1, i - 1)
  return s
}

BEGIN {
  n_ladder = split(LADDER, ladder_arr, " ")
  for (i = 1; i <= n_ladder; i++) is_rung[ladder_arr[i]] = 1
  n_axes = split(AXES, axes_arr, " ")
  blocks = 0
  n_hit = 0
  n_set = 0
}
{
  code = strip_comment($0)

  # Which declared quality axes does this file name AS CODE? (A header comment discussing an axis
  # is prose and does not count — both shipped axis validators narrate the ladder at length.)
  for (i = 1; i <= n_axes; i++) {
    if (index(code, axes_arr[i]) > 0 && !(axes_arr[i] in axis_hit)) {
      axis_hit[axes_arr[i]] = 1; n_hit++; hits[n_hit] = axes_arr[i]
    }
  }
  # …and does it BLOCK on what it finds? Naming an axis is description; log_error is enforcement.
  if (index(code, "log_error") > 0) blocks = 1

  # The enforcement rung-set: a `case` arm listing ONLY ladder rungs, separated by `|`, whose body
  # returns 0 ("yes, enforce at this rung"). Anchored to the arm form so that an unrelated rung
  # enumeration elsewhere — e.g. the `grep -oE '(NO-SHIP|IMPL-GREEN|…)'` both validators use to
  # PARSE a claimed state out of a report — is not mistaken for an enforcement decision. Parsing a
  # rung and gating on a rung are different acts; only the second one is this check's business.
  if (match(code, /^[ \t]*[A-Za-z0-9|.\-]+\)[ \t]*return[ \t]+0[ \t]*;;/)) {
    arm = code
    sub(/^[ \t]*/, "", arm)
    sub(/\).*$/, "", arm)
    nparts = split(arm, parts, "|")
    all_rungs = (nparts > 0)
    for (i = 1; i <= nparts; i++) if (!(parts[i] in is_rung)) all_rungs = 0
    if (all_rungs) {
      for (i = 1; i <= nparts; i++) {
        if (!(parts[i] in seen)) { seen[parts[i]] = 1; n_set++; rungset[n_set] = parts[i] }
      }
    }
  }
}
END {
  if (n_hit == 0 || !blocks) { print "NOT_A_QUALITY_VALIDATOR"; exit }
  axline = "AXES"
  for (i = 1; i <= n_hit; i++) axline = axline " " hits[i]
  if (n_set == 0) { print "NO_RUNG_PREDICATE"; print axline; exit }
  line = "RUNGSET"
  for (i = 1; i <= n_set; i++) line = line " " rungset[i]
  print line
  print axline
}
AWK

if [[ ! -d "$VALIDATOR_DIR" ]]; then
  add_finding "${RED}❌ BOUND_FUSION_NO_SUBJECT.P2${NC}: no validator directory at $VALIDATOR_DIR.
   The check had nothing to inspect. Reported as a finding, not as a pass — a gate that certifies
   an empty set is the failure this release line exists to close."
else
  FILELIST="$(mktemp)"
  find "$VALIDATOR_DIR" -maxdepth 1 -type f -name '*.sh' ! -name '*.test.sh' -print 2>/dev/null \
    | sort > "$FILELIST"
  FILES_SCANNED=$(wc -l < "$FILELIST" | tr -d ' ')

  # A scanner is not its own subject. This file names every declared axis and the `log_error`
  # idiom in its own scan logic and finding text, so without an explicit self-exclusion it
  # discovers itself, finds no rung predicate (it has none — it gates nothing at any rung), and
  # reports UNDECIDABLE against itself forever. Disclosed rather than worked around by weakening
  # the discovery rule, which would have cost real subjects.
  SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ -f "$f" ]] || continue
    [[ "$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" == "$SELF" ]] && continue

    result="$(awk -v LADDER="$LADDER" -v AXES="$QUALITY_AXES" -f "$SCAN_AWK" "$f" 2>/dev/null)"
    verdict="$(printf '%s\n' "$result" | head -n1)"
    axline="$(printf '%s\n' "$result" | sed -n '2p')"
    kind="${verdict%% *}"
    if [[ "${axline%% *}" == "AXES" ]]; then
      COVERED_AXES="$COVERED_AXES ${axline#AXES }"
    fi

    case "$kind" in
      NOT_A_QUALITY_VALIDATOR) continue ;;
      NO_RUNG_PREDICATE)
        QUALITY_VALIDATORS=$((QUALITY_VALIDATORS + 1))
        add_finding "${RED}❌ BOUND_FUSION_UNDECIDABLE.P2${NC}: $f blocks on a declared quality axis
   (${axline#AXES }) but no enforcement rung-set could be extracted from it — no
   \`<RUNGS>) return 0 ;;\` arm whose labels are all readiness rungs.
   Either it enforces at EVERY rung (which is the fusion this check exists to catch, reaching the
   existence floor by default), or its rung predicate was written in a shape this check cannot
   read. Both are reported; neither is cleared. Name the rungs in a \`case\` arm, or state in the
   file why the axis legitimately has no rung scope."
        ;;
      RUNGSET)
        QUALITY_VALIDATORS=$((QUALITY_VALIDATORS + 1))
        rungset="${verdict#RUNGSET }"
        overlap=""
        for rung in $EXISTENCE_RUNGS; do
          for have in $rungset; do
            [[ "$have" == "$rung" ]] && overlap="$overlap $rung"
          done
        done
        if [[ -n "$overlap" ]]; then
          add_finding "${RED}❌ BOUND_FUSION.P1${NC}: $f gates a QUALITY axis at the EXISTENCE rung(s)${overlap}.
   Enforcement rung-set: $rungset
   A quality bound that reaches the existence floor fuses two different questions into one field:
   a story that is built-but-rough and a story that was never built now produce the same verdict,
   and the gate can no longer fail loudly — every blocked thing reads as merely unripe (#93 class
   3). The repair is to SEPARATE the two, never to raise the bar: keep the quality axis scoped to
   the quality rungs (UX-RC and above), and let the existence rungs be capped only by existence
   facts (implementation-pending, autonomous-not-done).
   A quality axis may improve a permitted readiness rung; it may not erase the independent go/no-go gate."
        fi
        ;;
      *)
        add_finding "${RED}❌ BOUND_FUSION_UNDECIDABLE.P2${NC}: unrecognised scan verdict for $f: '$verdict'."
        ;;
    esac
  done < "$FILELIST"
  rm -f "$FILELIST"

  # ── C (part 2). Every DECLARED axis must be enforced by something we actually inspected ──────
  # This is the anti-vacuity assertion with teeth. "0 findings" from a check whose subject set is
  # empty — or smaller than the world — reads identically to "0 findings" from a check that looked
  # at everything. A declared axis nobody enforces is either an unguarded quality bound or a check
  # that has gone blind; both are findings, neither is a pass.
  for axis in $QUALITY_AXES; do
    covered=false
    for have in $COVERED_AXES; do [[ "$have" == "$axis" ]] && covered=true; done
    if [[ "$covered" == false ]]; then
      add_finding "${RED}❌ BOUND_FUSION_NO_SUBJECT.P2${NC}: the template declares the quality axis \`$axis\` but
   no validator under $VALIDATOR_DIR both names it in code and blocks on it (\`log_error\`).
   Scanned $FILES_SCANNED validator(s), of which $QUALITY_VALIDATORS enforce a quality axis.
   Either \`$axis\` is enforced somewhere this check cannot see — in which case its rung scope is
   unverified and the existence floor is unguarded for that axis — or it is not enforced at all.
   A green here would have been a green about nothing."
    fi
  done
fi

if [[ $findings -gt 0 ]]; then
  echo -e "$report"
  echo ""
  echo -e "${RED}Found $findings bound-fusion finding(s) across $QUALITY_VALIDATORS quality-axis validator(s) (of $FILES_SCANNED scanned).${NC}"
else
  echo -e "${GREEN}✅ No quality bound reaches the existence floor ($QUALITY_VALIDATORS quality-axis validator(s) of $FILES_SCANNED scanned; existence rungs:${NC} $EXISTENCE_RUNGS${GREEN}).${NC}"
fi

if [[ "$STRICT_MODE" == true && $findings -gt 0 ]]; then
  emit_gate_telemetry
  exit 1
fi

emit_gate_telemetry
exit 0
