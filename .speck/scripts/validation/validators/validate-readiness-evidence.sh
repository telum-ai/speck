#!/usr/bin/env bash

# Speck Readiness Evidence Validator
# Programmatically enforces that any claims of UX-RC or higher are backed by real, verifiable evidence files.
# Checks that if readiness_state_verified or readiness_state_claimed is UX-RC, COMMERCIAL-RC, or SHIP-RC,
# there must be at least one asset file under specs/projects/PROJECT_ID/larp-recordings/ or STORY_DIR/larp-recordings/
# containing screenshots, AX trees, or videos.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_DIR="${1:-}"
strict="${2:-false}"

if [[ -z "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Please specify the story/epic directory path.${NC}"
  exit 1
fi

val_report=""
if [[ -f "${TARGET_DIR}/validation-report.md" ]]; then
  val_report="${TARGET_DIR}/validation-report.md"
elif [[ -f "${TARGET_DIR}/epic-validation-report.md" ]]; then
  val_report="${TARGET_DIR}/epic-validation-report.md"
fi

if [[ -z "$val_report" || ! -f "$val_report" ]]; then
  # No validation report exists yet, so nothing to enforce
  exit 0
fi

echo -e "🏁 Validating Readiness-State Evidence for $(basename "$TARGET_DIR")...\n"

# Parse claimed or verified readiness state
claimed_state=""
if grep -q -i "readiness_state_verified:" "$val_report"; then
  claimed_state=$(grep -i "readiness_state_verified:" "$val_report" | head -n 1 | sed -E 's/.*:[[:space:]]*["'\'']?([^"'\''[:space:]]+)["'\'']?.*/\1/' || true)
elif grep -q -i "readiness_state_claimed:" "$val_report"; then
  claimed_state=$(grep -i "readiness_state_claimed:" "$val_report" | head -n 1 | sed -E 's/.*:[[:space:]]*["'\'']?([^"'\''[:space:]]+)["'\'']?.*/\1/' || true)
fi

# Standardise to uppercase
claimed_state=$(echo "$claimed_state" | tr '[:lower:]' '[:upper:]')

if [[ -z "$claimed_state" || "$claimed_state" == "NO-SHIP" || "$claimed_state" == "IMPL-GREEN" ]]; then
  echo -e "ℹ️  State is ${claimed_state:-NO-SHIP} (or lower). No visual/runtime evidence files are required."
  exit 0
fi

# Detect Project Archetype
project_archetype="consumer_product" # Default fallback
project_json=""
# Find project.json by climbing up
dir="$TARGET_DIR"
while [[ "$dir" != "/" && -n "$dir" ]]; do
  if [[ -f "${dir}/project.json" ]]; then
    project_json="${dir}/project.json"
    break
  elif [[ -f "${dir}/.speck/project.json" ]]; then
    project_json="${dir}/.speck/project.json"
    break
  fi
  dir=$(dirname "$dir")
done

if [[ -f "$project_json" ]]; then
  archetype=$(grep -o '"project_archetype"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || true)
  if [[ -n "$archetype" ]]; then
    project_archetype="$archetype"
  fi
fi

# If project_archetype is infra_service or backend_api, larp evidence is not required (but integration test logs are required instead, we can check for those if we want)
if [[ "$project_archetype" == "infra_service" || "$project_archetype" == "backend_api" ]]; then
  echo -e "ℹ️  Project Archetype is ${project_archetype}. LARP recordings are bypassed."
  # Optionally check if there is an integration test log in the validation folder
  exit 0
fi

echo -e "👉 Claimed Readiness State: ${BLUE}${claimed_state}${NC}"

# Find larp-recordings directories
recordings_dirs=()

# 1. Look in STORY_DIR/larp-recordings/
if [[ -d "${TARGET_DIR}/larp-recordings" ]]; then
  recordings_dirs+=("${TARGET_DIR}/larp-recordings")
fi

# 2. Look in specs/projects/PROJECT_ID/larp-recordings/
# Find the project directory
project_dir=""
dir="$TARGET_DIR"
while [[ "$dir" != "/" && -n "$dir" ]]; do
  if [[ -f "${dir}/project.md" ]]; then
    project_dir="$dir"
    break
  fi
  dir=$(dirname "$dir")
done

if [[ -n "$project_dir" && -d "${project_dir}/larp-recordings" ]]; then
  recordings_dirs+=("${project_dir}/larp-recordings")
fi

# Count files under the recordings directories matching png, json, mp4, etc.
evidence_count=0
for d in "${recordings_dirs[@]}"; do
  # Count files ending with png, json, or mp4
  count=$(find "$d" -type f \( -name "*.png" -o -name "*.json" -o -name "*.mp4" -o -name "*.mov" \) 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  evidence_count=$((evidence_count + count))
done

if [[ $evidence_count -eq 0 ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}EVIDENCE ERROR: Claim of state '${claimed_state}' rejected.${NC}"
  echo -e "\n${YELLOW}Enforcing Always-On Discipline:${NC}"
  echo -e "  You claimed a high readiness state (${claimed_state}) but NO verifiable runtime evidence"
  echo -e "  files (screenshots, accessibility trees, or video captures) were found under"
  echo -e "  'larp-recordings/'."
  echo -e "\n${BLUE}To resolve this:${NC}"
  echo -e "  1. Run ${GREEN}npx speck larp-play${NC} or manual walkthroughs to capture the visual evidence."
  echo -e "  2. Ensure captured screenshots/AX trees are saved in 'larp-recordings/'."
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  if [[ "$strict" == "true" ]]; then
    exit 1
  fi
else
  echo -e "   ${GREEN}✅ Verified: Found ${evidence_count} evidence files backing state claim '${claimed_state}'!${NC}"
  exit 0
fi
