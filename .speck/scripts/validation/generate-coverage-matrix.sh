#!/usr/bin/env bash
# generate-coverage-matrix.sh — deterministic v1 coverage-matrix skeleton emitter (issue #84)
#
# The torture tier's spine: emit a checked-in coverage-matrix.md whose rows enumerate the
# coverage universe (persona × screen × state × viewport × theme) so breadth GAPS are visible,
# not silent — BEFORE anyone pays to FILL them. This is the always-on, cheap GENERATE step.
#
# Deterministic v1: critical-core (magic-moment/flagship screens) get the full state cross;
# every other screen gets one representative cell per state. NO covering-array algorithm.
# If the experience-chain screen table is thin/absent, the matrix is stamped `chain-partial`
# so under-enumeration surfaces as a disclosed generator gap, never false-green coverage.
#
# Usage:
#   generate-coverage-matrix.sh --level epic    <EPIC_DIR>
#   generate-coverage-matrix.sh --level project <PROJECT_DIR>
#
# Writes <DIR>/coverage-matrix.md. Exit: 0 ok, 2 invocation error.

set -euo pipefail

LEVEL=""
DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --level) LEVEL="${2:-}"; shift 2 ;;
    *) DIR="$1"; shift ;;
  esac
done

[[ "$LEVEL" == "epic" || "$LEVEL" == "project" ]] || { echo "ERROR: --level epic|project required" >&2; exit 2; }
[[ -n "$DIR" && -d "$DIR" ]] || { echo "ERROR: pass an existing $LEVEL directory" >&2; exit 2; }
DIR="$(cd "$DIR" && pwd)"

# --- Screens from experience-chain §2 (mechanical enumeration) ---
extract_screens() { # experience-chain.md
  [[ -f "$1" ]] || return 0
  awk '
    /^## 2\. Screen-by-Screen Chain/ { ins=1; next }
    ins && /^## [0-9]/ { ins=0 }
    ins && /^\|[ ]*[0-9]+[ ]*\|/ {
      n=split($0, a, /\|/); s=a[3]; gsub(/^[ \t]+|[ \t]+$/,"",s)
      if (s != "" && s !~ /^\[/) print s
    }
  ' "$1" 2>/dev/null || true
}

SCREENS=""
if [[ "$LEVEL" == "epic" ]]; then
  SCREENS="$(extract_screens "$DIR/experience-chain.md")"
else
  # project: aggregate all epics' experience-chain.md
  if [[ -d "$DIR/epics" ]]; then
    for ec in "$DIR"/epics/*/experience-chain.md; do
      [[ -f "$ec" ]] && SCREENS="$SCREENS"$'\n'"$(extract_screens "$ec")"
    done
  fi
fi
SCREENS="$(printf '%s\n' "$SCREENS" | sed '/^[[:space:]]*$/d' | awk '!seen[$0]++')"
SCREEN_COUNT=$(printf '%s\n' "$SCREENS" | sed '/^$/d' | wc -l | tr -d ' ')

COMPLETENESS="complete"
[[ "$SCREEN_COUNT" -eq 0 ]] && COMPLETENESS="chain-partial"

# --- Viewports from the active recipe (fallback to the canonical three) ---
WS_ROOT="$DIR"; while [[ "$WS_ROOT" != "/" && ! -d "$WS_ROOT/.speck" ]]; do WS_ROOT="$(dirname "$WS_ROOT")"; done
RECIPE_FILE=""
if [[ -f "$WS_ROOT/.speck/project.json" ]]; then
  RECIPE=$(grep -oE '"recipe"[[:space:]]*:[[:space:]]*"[^"]*"' "$WS_ROOT/.speck/project.json" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' | head -1 || true)
  [[ -n "$RECIPE" && -f "$WS_ROOT/.speck/recipes/$RECIPE/recipe.yaml" ]] && RECIPE_FILE="$WS_ROOT/.speck/recipes/$RECIPE/recipe.yaml"
fi
VIEWPORTS="mobile, tablet, desktop"
if [[ -n "$RECIPE_FILE" ]]; then
  vp=$(awk '/^[[:space:]]*breakpoints:/{ins=1;next} ins && /^[[:space:]]*[a-z]+:[[:space:]]*[0-9]+/{gsub(/[: 0-9]/,"",$1);printf "%s%s",sep,$1;sep=", "} ins && /^[[:space:]]*[a-z]+:[[:space:]]*$/{if(NR>1)ins=0}' "$RECIPE_FILE" 2>/dev/null || true)
  [[ -n "$vp" ]] && VIEWPORTS="$vp"
fi

STATES="happy, error, empty, loading"
# Persona universe = #84's breadth set + the two rows #101 P3 showed it structurally cannot reach.
# #84's set is CONSUMER BREADTH — ONE identity in many states (day-0, returning, paused, a11y-first,
# low-bandwidth…). None of its personas is a second ACTOR and none of them is in a hurry, so two
# whole defect families are as invisible to this matrix as they are to a single-user happy-path suite:
#
#   second-actor — a DIFFERENT principal on the SAME install. Sign in as A, write, sign out, sign in
#                  as B (offline), assert B observes NOTHING of A's — run ONCE PER PERSISTENCE LAYER
#                  (server row · cache · queue/outbox · local DB · notification schedule · draft ·
#                  store receipt · in-memory store · billing-SDK identity · analytics), because
#                  ownership is per-layer, not per-endpoint. This is the persona that catches the
#                  cross-user write; no other row in this list can see it.
#   impatient    — the user who does not wait. Double-taps the primary action, backgrounds mid-write,
#                  kills the app between request and response, navigates away before the spinner
#                  resolves. Surfaces the state-claim and partial-write defects a patient walk never
#                  reaches (a surface that renders total/partial failure identically to success).
PERSONAS="naive-hostile, connoisseur-hostile, returning-user, skeptical-buyer, power-user, a11y-first, locale-switcher, low-bandwidth, second-actor, impatient"
TODAY=$(date +%Y-%m-%d)
OUT="$DIR/coverage-matrix.md"

{
  echo "---"
  echo "artifact_type: coverage-matrix"
  echo "coverage_tier: skeleton"
  echo "generator_completeness: $COMPLETENESS"
  echo "---"
  echo ""
  echo "# Coverage Matrix — $(basename "$DIR") ($LEVEL)"
  echo ""
  echo "_Generated skeleton (deterministic v1). Every GAP cell below is an un-run, un-waived cell = a P3 finding. FILL them via \`/project-validate --exhaustive\` (torture tier) or waive with a reason. Breadth caps, never raises, the claimable state._"
  echo ""
  echo "## Coverage universe (dimensions)"
  echo ""
  echo "- **personas**: $PERSONAS (+ evidence-contract §4 named personas)"
  echo "  - \`second-actor\` — a DIFFERENT principal on the SAME install: sign in as A, write, sign out, sign in as B **offline**, assert B observes **nothing** of A's. Run once **per persistence layer** (server row · cache · queue/outbox · local DB · notification schedule · draft · store receipt · in-memory store · billing-SDK identity · analytics) — ownership is per-layer, not per-endpoint. Every other persona in this list is one identity in a different state, so a cross-user write is invisible without this row."
  echo "  - \`impatient\` — the user who does not wait: double-tap the primary action, background mid-write, kill the app between request and response, navigate away before the spinner resolves. Reaches the total- and partial-failure renders a patient walk never sees."
  echo "- **states**: $STATES"
  echo "- **viewports**: $VIEWPORTS  ·  **themes**: light, dark"
  echo "- **input-sample**: N=5 on §8 AI-generative surfaces only"
  echo ""
  if [[ "$COMPLETENESS" == "chain-partial" ]]; then
    echo "> ⚠️ **generator_completeness: chain-partial** — no screens were enumerated from experience-chain §2 (thin/absent source). The universe is UNDER-enumerated; this matrix cannot back a breadth claim until the experience-chain screen table is filled and this is regenerated."
    echo ""
  fi
  echo "## Cell status grid"
  echo ""
  echo "Status ∈ RUN (cite evidence) · DEFERRED-BY-BUDGET(reason) · N-A(reason) · GAP (un-run → P3)."
  echo ""
  echo "| Persona | Screen/Route | State | Viewport | Theme | DOES-IT-WORK | IS-IT-GOOD | IS-IT-CRAFTED | Status | Evidence |"
  echo "|---------|-------------|-------|----------|-------|--------------|-----------|---------------|--------|----------|"
  if [[ "$SCREEN_COUNT" -gt 0 ]]; then
    # Critical-core representative: naive-hostile × screen × each state × mobile × light.
    printf '%s\n' "$SCREENS" | sed '/^$/d' | while IFS= read -r screen; do
      for st in happy error empty loading; do
        echo "| naive-hostile | $screen | $st | mobile | light | — | — | — | GAP | — |"
      done
    done
  else
    echo "| — | (no screens enumerated — see chain-partial) | — | — | — | — | — | — | GAP | — |"
  fi
  echo ""
  echo "## Cross-cell defect ledger"
  echo ""
  echo "| ID | Severity | Surfacing cell | Defect | Fix |"
  echo "|----|----------|----------------|--------|-----|"
  echo "| — | — | — | (none recorded yet) | — |"
  echo ""
  echo "## Breadth verdict"
  echo ""
  echo "- **Coverage**: 0 RUN / $((SCREEN_COUNT * 4)) enumerated in-universe (skeleton) · GAPs: $((SCREEN_COUNT * 4))"
  echo "- **Breadth cap**: NO-SHIP (skeleton un-filled — run \`--exhaustive\` to FILL)"
  echo "- **Generator completeness**: $COMPLETENESS"
  echo ""
  echo "*[as of SHA \`pending\` | verified $TODAY | speck vX.Y.Z]*"
} > "$OUT"

echo "✅ Wrote $OUT ($SCREEN_COUNT screens, completeness: $COMPLETENESS)"
