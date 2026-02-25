#!/usr/bin/env bash
# .speck/scripts/audit.sh — Audit Speck artifact completeness
#
# Usage: bash .speck/scripts/audit.sh [specs-root]
# Default specs-root: specs
#
# Checks every story and epic for required artifacts per the
# Artifact Completeness Tiers defined in README.md.
#
# Exit codes:
#   0 — All core artifacts present
#   1 — Missing core artifacts found

set -euo pipefail

SPECS_ROOT="${1:-specs}"

# Core artifacts (required for every story)
CORE_STORY=(spec.md plan.md tasks.md validation-report.md story-retro.md)
# Conditional artifacts (checked but reported separately)
CONDITIONAL_STORY=(quickstart.md ui-spec.md)
# Core epic artifacts
CORE_EPIC=(epic.md epic-tech-spec.md epic-breakdown.md epic-validation-report.md epic-retro.md)

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

total_stories=0
total_core_gaps=0
total_cond_gaps=0
total_epics=0
total_epic_gaps=0

# Find all story directories (S### pattern or numeric prefix)
story_dirs=$(find "$SPECS_ROOT" -type d \( -name "S[0-9]*" -o -name "[0-9][0-9][0-9]-*" \) 2>/dev/null | sort)

echo -e "${BOLD}Speck Artifact Audit${NC}"
echo "Specs root: $SPECS_ROOT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Audit stories
echo -e "${BOLD}STORY ARTIFACTS${NC}"
echo ""

while IFS= read -r sdir; do
  [ -z "$sdir" ] && continue
  total_stories=$((total_stories + 1))
  sname=$(basename "$sdir")
  core_missing=()
  cond_missing=()

  for artifact in "${CORE_STORY[@]}"; do
    if [ ! -f "$sdir/$artifact" ]; then
      core_missing+=("$artifact")
      total_core_gaps=$((total_core_gaps + 1))
    fi
  done

  for artifact in "${CONDITIONAL_STORY[@]}"; do
    if [ ! -f "$sdir/$artifact" ]; then
      cond_missing+=("$artifact")
      total_cond_gaps=$((total_cond_gaps + 1))
    fi
  done

  if [ ${#core_missing[@]} -gt 0 ]; then
    echo -e "  ${RED}✗${NC} ${sname}"
    echo -e "    ${RED}core:${NC} ${core_missing[*]}"
    if [ ${#cond_missing[@]} -gt 0 ]; then
      echo -e "    ${YELLOW}cond:${NC} ${cond_missing[*]}"
    fi
  elif [ ${#cond_missing[@]} -gt 0 ]; then
    echo -e "  ${YELLOW}~${NC} ${sname}"
    echo -e "    ${YELLOW}cond:${NC} ${cond_missing[*]}"
  fi
done <<< "$story_dirs"

echo ""

# Audit epics
echo -e "${BOLD}EPIC ARTIFACTS${NC}"
echo ""

epic_parent_dirs=$(find "$SPECS_ROOT" -type d -name "epics" 2>/dev/null)
while IFS= read -r epics_dir; do
  [ -z "$epics_dir" ] || [ ! -d "$epics_dir" ] && continue
  for edir in "$epics_dir"/*/; do
    [ ! -d "$edir" ] && continue
    total_epics=$((total_epics + 1))
    ename=$(basename "$edir")
    epic_missing=()

    for artifact in "${CORE_EPIC[@]}"; do
      if [ ! -f "$edir/$artifact" ]; then
        epic_missing+=("$artifact")
        total_epic_gaps=$((total_epic_gaps + 1))
      fi
    done

    if [ ${#epic_missing[@]} -gt 0 ]; then
      echo -e "  ${RED}✗${NC} ${ename}"
      echo -e "    ${RED}missing:${NC} ${epic_missing[*]}"
    fi
  done
done <<< "$epic_parent_dirs"

echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BOLD}SUMMARY${NC}"
echo "  Stories:    $total_stories"
echo "  Core gaps:  $total_core_gaps"
echo "  Cond gaps:  $total_cond_gaps"
echo "  Epics:      $total_epics"
echo "  Epic gaps:  $total_epic_gaps"

if [ $total_core_gaps -gt 0 ] || [ $total_epic_gaps -gt 0 ]; then
  echo ""
  echo -e "  ${RED}FAIL${NC} — $((total_core_gaps + total_epic_gaps)) required artifacts missing"
  exit 1
else
  echo ""
  echo -e "  ${GREEN}PASS${NC} — All core artifacts present"
  exit 0
fi
