#!/usr/bin/env bash

# Speck Story Prerequisite Gate Validator
# Deterministically checks if a story is ready for implementation before coding.
# Requirements:
# 1. spec.md must exist and have lifecycle: Specified (or State: Specified)
# 2. plan.md must exist
# 3. tasks.md must exist
# 4. analysis-report.md is OPTIONAL (v7+: /story-analyze retired — consistency folded into /story-tasks, adversarial check is /audit); if present, it must contain no unresolved CRITICAL items

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

# 4. Check analysis-report.md or story-analysis-report.md
analysis_report_path=""
for possible_path in "${STORY_DIR}/analysis-report.md" "${STORY_DIR}/story-analysis-report.md" "${STORY_DIR}/story-analysis.md"; do
  if [[ -f "$possible_path" ]]; then
    analysis_report_path="$possible_path"
    break
  fi
done

if [[ -z "$analysis_report_path" ]]; then
  echo -e "${YELLOW}⚠️  Missing analysis-report.md (Recommended, but optional in v7 since /story-analyze is folded into tasks + /audit)${NC}"
else
  # Check for unresolved CRITICAL items
  # Typically lines with "[ ] CRITICAL" or similar in markdown checklists
  criticals=$(grep -i "CRITICAL" "$analysis_report_path" | grep -v "✅" | grep -v "\[x\]" | grep -E "\[[[:space:]]\]|todo" || true)
  if [[ -n "$criticals" ]]; then
    echo -e "${RED}❌ Unresolved CRITICAL issues found in analysis-report.md:${NC}"
    echo "$criticals" | sed 's/^/   /'
    failed=true
  else
    echo -e "${GREEN}✅ analysis-report.md is present with no unresolved CRITICAL items${NC}"
  fi
fi

if [[ "$failed" == true ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}GATES REJECTED: One or more pre-implementation prerequisite checks have failed.${NC}"
  echo -e "\n${YELLOW}To begin implementation, please ensure the following steps are run first:${NC}"
  echo -e "  1. Run ${GREEN}/story-specify${NC} to create and specify the story requirements."
  echo -e "  2. Run ${GREEN}/story-plan${NC} to design the technical solution."
  echo -e "  3. Run ${GREEN}/story-tasks${NC} to generate the implementation checklist (includes consistency check at tail)."
  echo -e "  4. The spec↔plan↔tasks consistency check runs at the tail of ${GREEN}/story-tasks${NC}; the adversarial cross-check is ${GREEN}/audit${NC} after implementation (a standalone analysis-report.md is optional; /story-analyze is retired in v8)."
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 1
else
  echo -e "\n${GREEN}🚀 PREREQUISITE GATES PASSED! Story ${story_id} is approved for implementation!${NC}"
  exit 0
fi
