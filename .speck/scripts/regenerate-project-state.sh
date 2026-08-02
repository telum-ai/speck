#!/usr/bin/env bash
# regenerate-project-state.sh — the project-state regeneration hook
#
# Usage:
#   .speck/scripts/regenerate-project-state.sh <reason> [PROJECT_DIR]
#
# Where <reason> is one of:
#   story-validate-pass · epic-validate-complete · project-validate-complete
#   recheck-complete · manual-request
#
# WHAT THIS SCRIPT DOES, AND WHY IT CHANGED (v10.2, issue #96 item E).
#
# project-state.md as a whole still needs an agent: it synthesises current state, open questions and
# a next action from sources no script can read. But TWO of its blocks are pure projections of the
# witness graph, and until now the agent was asked to TYPE them:
#
#   • the Readiness State Map, including its Proof column. A hand-authored Proof column is the gated
#     party authoring the gate's input (#93 class 2) — `validation-report.md@abc1234` costs exactly
#     as much to type whether or not the file exists, which is how two consecutive project-states
#     carried a false verdict that nothing could detect, because the claim resolved to nothing.
#   • the work order. `gap` computes which item comes next; a retyped ranking is a second one.
#
# So this script now PRINTS both, derived, ready to paste — and still hands the synthesis back to
# the agent. It is a hint script on a hook path: it exits 0 no matter what, degrades to the hint
# alone when python3 or the graph is unavailable, and NEVER writes (both commands run in `--stdout`
# mode, so a read-only checkout is fine).

set -uo pipefail

REASON="${1:-manual-request}"
PROJECT_DIR="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && cd .. && pwd)"
GRAPH="$ROOT/.speck/scripts/graph/speck_graph.py"

# Auto-detect the project when the caller did not name one. A single project is the common case; with
# several, name the one you mean — guessing would put another project's numbers on this page.
if [[ -z "$PROJECT_DIR" ]]; then
  CANDIDATES=()
  while IFS= read -r d; do
    [[ -n "$d" ]] && CANDIDATES+=("$(dirname "$d")")
  done < <(find "$ROOT/specs/projects" -maxdepth 2 -name "product-contract.md" 2>/dev/null | sort)
  if [[ ${#CANDIDATES[@]} -eq 1 ]]; then
    PROJECT_DIR="${CANDIDATES[0]}"
  fi
fi

cat <<EOF
🔁 PROJECT_STATE_REGENERATION_REQUESTED

Reason: $REASON
Recommended next action for the agent: invoke /project-state to regenerate the single-page status doc.

This script is a marker for hook-based regeneration. The AI agent should detect this
output and run the project-state skill before completing the current command.
EOF

if [[ -z "$PROJECT_DIR" || ! -d "$PROJECT_DIR" ]]; then
  echo
  echo "ℹ️  No single project auto-detected under specs/projects/ — pass the project dir as the"
  echo "    second argument to get the derived blocks: $0 $REASON specs/projects/<id>"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1 || [[ ! -f "$GRAPH" ]]; then
  echo
  echo "ℹ️  python3 or the witness graph is unavailable here — the derived blocks below were"
  echo "    skipped. Generate them by hand with \`speck_graph.py readiness|gap\` before quoting"
  echo "    any readiness state; do NOT type a Proof column."
  exit 0
fi

# Derived block 1 — the Readiness State Map. Paste verbatim; every Proof cell is computed.
MAP="$(python3 "$GRAPH" readiness "$PROJECT_DIR" --stdout 2>&1)"
MAP_RC=$?
echo
echo "─── DERIVED: paste into project-state.md → 🎚️ Readiness State Map ───"
if [[ $MAP_RC -eq 0 ]]; then
  echo "$MAP"
else
  echo "⚠️  readiness did not render (exit $MAP_RC). Do NOT hand-author the table in its place —"
  echo "    a typed Proof column is unfalsifiable by construction. Fix the graph first:"
  echo "$MAP"
fi

# Derived block 2 — the work order. NEXT= names the single item to do; it is not a suggestion to
# re-rank, it is the same row `speck_graph.py findings` ranks first.
GAP="$(python3 "$GRAPH" gap "$PROJECT_DIR" 2>&1)"
GAP_RC=$?
echo
echo "─── DERIVED: the computed work order (severity → gate code → subject) ───"
echo "$GAP"
if [[ $GAP_RC -ne 0 ]]; then
  echo "(gap exited $GAP_RC — treat the line above as unrendered, not as 'no gap')"
fi
echo
echo "Read the sources in this order: project-state → pickup → real open defects → THEN the derived"
echo "road/findings as a completeness cross-check. A clear road means the promise ledger is filled,"
echo "never that the work is done."

exit 0
