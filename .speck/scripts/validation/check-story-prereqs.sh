#!/usr/bin/env bash

# Speck Story Prerequisite Gate Validator
# Deterministically checks if a story is ready for implementation before coding.
# Requirements:
# 1. spec.md must exist and have lifecycle: Specified (or State: Specified)
# 2. plan.md must exist
# 3. tasks.md must exist
# 4. v11 tasks declare analysis_required by play level. Build/Platform require a bound
#    story-analysis-report.md; Sprint declares false. Older tasks remain advisory.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

STORY_DIR="${1:-}"

if [[ -z "$STORY_DIR" ]]; then
  echo -e "${RED}Error: Please specify the story directory path.${NC}"
  echo "Usage: $0 <specs/projects/PROJECT_ID/epics/EPIC_ID/stories/STORY_ID>"
  exit 1
fi

if [[ ! -d "$STORY_DIR" ]]; then
  echo -e "${RED}Error: Story directory does not exist: $STORY_DIR${NC}"
  exit 1
fi

story_id=$(basename "$STORY_DIR")
failed=false

echo -e "🥓 Checking pre-implementation prerequisites for story ${story_id}...\n"

# 1. Check spec.md
spec_path="${STORY_DIR}/spec.md"
if [[ ! -f "$spec_path" ]]; then
  echo -e "${RED}❌ Missing spec.md${NC}"
  failed=true
else
  # Verify lifecycle state is Specified
  if grep -q -i -E '(current[ -]?state|status|lifecycle(_state)?)\**:[[:space:]]*Specified' "$spec_path" || grep -q -i "state:[[:space:]]*Specified" "$spec_path"; then
    echo -e "${GREEN}✅ spec.md is present and lifecycle state is 'Specified'${NC}"
  else
    echo -e "${YELLOW}⚠️  spec.md is present but lifecycle state is NOT 'Specified'. Found:${NC}"
    found_state=$(grep -i -E "(current[ -]?state|status|lifecycle(_state)?|state)\**:" "$spec_path" | head -n 1 || echo "None")
    echo "   $found_state"
    failed=true
  fi
fi

# 2. Check plan.md
plan_path="${STORY_DIR}/plan.md"
if [[ ! -f "$plan_path" ]]; then
  echo -e "${RED}❌ Missing plan.md${NC}"
  failed=true
else
  echo -e "${GREEN}✅ plan.md is present${NC}"
fi

# 3. Check tasks.md
tasks_path="${STORY_DIR}/tasks.md"
if [[ ! -f "$tasks_path" ]]; then
  echo -e "${RED}❌ Missing tasks.md${NC}"
  failed=true
else
  echo -e "${GREEN}✅ tasks.md is present${NC}"
fi

# 4. Check the decorrelated story-analysis gate for task files created by v11.
analysis_required=false
if [[ -f "$tasks_path" ]] && grep -qE '^analysis_required:[[:space:]]*true[[:space:]]*$' "$tasks_path"; then
  analysis_required=true
fi

if [[ "$analysis_required" == true ]]; then
  analysis_validator=".speck/scripts/validation/validators/validate-project-analysis.sh"
  template_validator=".speck/scripts/validation/validate-template.sh"
  analysis_report="${STORY_DIR}/story-analysis-report.md"
  if [[ ! -f "$analysis_validator" || ! -f "$template_validator" ]]; then
    echo -e "${RED}❌ Story analysis validators are unavailable.${NC}"
    failed=true
  elif [[ ! -f "$analysis_report" ]]; then
    echo -e "${RED}UNANALYZED_CORPUS.P1  story-analysis-report.md does not exist. Run /analyze --level story.${NC}"
    failed=true
  else
    structural_rc=0
    structural_out="$(bash "$template_validator" --strict "$analysis_report" 2>&1)" || structural_rc=$?
    printf '%s\n' "$structural_out"
    analysis_rc=0
    analysis_out="$(bash "$analysis_validator" --gate "$STORY_DIR" 2>&1)" || analysis_rc=$?
    printf '%s\n' "$analysis_out"
    if [[ "$structural_rc" -ne 0 || "$analysis_rc" -ne 0 ]]; then
      echo -e "${RED}❌ Required story analysis has not cleared.${NC}"
      failed=true
    else
      echo -e "${GREEN}✅ Required story analysis is present and clear${NC}"
    fi
  fi
elif [[ -f "$tasks_path" ]] && grep -qE '^analysis_required:[[:space:]]*false[[:space:]]*$' "$tasks_path"; then
  echo -e "${GREEN}✅ Sprint tasks declare story analysis not required${NC}"
else
  echo -e "${YELLOW}⚠️  This pre-v11 tasks.md does not declare analysis_required; story analysis remains advisory for this already-planned story.${NC}"
fi

# 5. Witness-graph forcing gate (v9): the story must be non-dangling AND trace UP to a promise,
#    with zero dangling refs in its subtree — an orphan specified-but-unwired story blocks implement.
#    Migration-aware: an epic that hasn't adopted a promise ledger yet GUIDES (never walls) greenfield.
#
#    v10.1 (issue #96 finding 3): `gate` now also computes graph FRESHNESS and reports it here.
#    Read-only — it compares a content signature and never rebuilds, so this stays safe in a
#    read-only CI checkout and leaves any tree-clean assertion intact. Staleness is surfaced and
#    NEVER blocks: a hard freshness gate on every /story-implement would fire on rot nobody in
#    this story caused and would teach `--no-verify` inside a day. Guide-rail, not wall.
graph_py=".speck/scripts/graph/speck_graph.py"
if command -v python3 >/dev/null 2>&1 && [[ -f "$graph_py" ]]; then
  # derive PROJECT_DIR (…/specs/projects/<id>) and STORY_ID (<epic>/<story>) from STORY_DIR
  proj_dir="${STORY_DIR%%/epics/*}"
  rest="${STORY_DIR#*/epics/}"                       # <epic-dir>/stories/<story-dir>
  epic_dir="${rest%%/stories/*}"; story_dir="${rest##*/stories/}"
  story_num="$(printf '%s' "${story_dir%%/*}" | grep -oE '^S[0-9]+' || true)"
  graph_story_id="${epic_dir}/${story_num}"          # canonical node id: <epic-basename>/S###
  if [[ -d "$proj_dir" && "$STORY_DIR" == *"/epics/"* ]]; then
    echo -e "${YELLOW}🔍 Witness-graph reachability + freshness gate (v9.0/v10.1)...${NC}"
    # Captured, not piped: under `set -o pipefail` a `cmd | grep -q` reports the PRODUCER's status,
    # so the match and the command's own failure become indistinguishable.
    if gate_out="$(python3 "$graph_py" gate "$proj_dir" --story "$graph_story_id" 2>&1)"; then
      gate_rc=0
    else
      gate_rc=$?
    fi
    printf '%s\n' "$gate_out"
    if [[ "$gate_rc" -ne 0 ]]; then
      echo -e "${RED}❌ Graph gate: this story is not legitimately wired (see above).${NC}"
      failed=true
    fi
    if grep -q "GRAPH_STALE" <<<"$gate_out"; then
      echo -e "${YELLOW}⚠️  The committed witness graph is STALE — every cap, count and 'clear to advance'${NC}"
      echo -e "${YELLOW}    you read out of it until you rebuild describes a different tree. This does NOT${NC}"
      echo -e "${YELLOW}    block implementation. Fix: python3 $graph_py build $proj_dir${NC}"
    fi
  fi
else
  echo -e "${YELLOW}⚠️  python3 or witness graph unavailable — skipping the graph reachability gate (CI is the backstop).${NC}"
fi

if [[ "$failed" == true ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}GATES REJECTED: One or more pre-implementation prerequisite checks have failed.${NC}"
  echo -e "\n${YELLOW}To begin implementation, please ensure the following steps are run first:${NC}"
  echo -e "  1. Run ${GREEN}/story-specify${NC} to create and specify the story requirements."
  echo -e "  2. Run ${GREEN}/story-plan${NC} to design the technical solution."
  echo -e "  3. Run ${GREEN}/story-tasks${NC} to generate the implementation checklist (includes consistency check at tail)."
  echo -e "  4. Run ${GREEN}/analyze --level story${NC} when tasks.md declares analysis_required: true."
  echo -e "  5. After implementation, run the separate ${GREEN}/speck-audit${NC} before validation."
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 1
else
  echo -e "\n${GREEN}🚀 PREREQUISITE GATES PASSED! Story ${story_id} is approved for implementation!${NC}"
  exit 0
fi
