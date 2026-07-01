#!/usr/bin/env bash
# validate-wave-safety.sh — Wave safety and concurrency collision validator (Speck v7.18).
#
# Parses epics.md and verifies that no two concurrent epics in the same wave collide on:
#   1. Database migrations (which would break the single Alembic head)
#   2. Shared model/service files or component files
#
# Usage:
#   validate-wave-safety.sh <epics.md | project-dir>
#
# Exit codes: 0 = pass, 1 = collisions found, 2 = invocation error.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "ERROR: provide an epics.md path or a project directory." >&2
  exit 2
fi

if [[ -d "$TARGET" ]]; then
  EPICS_MD="$TARGET/epics.md"
  if [[ ! -f "$EPICS_MD" ]]; then
    # Fallback to specs/projects/<id>/epics.md
    for d in "$TARGET/specs/projects/"*; do
      if [[ -f "$d/epics.md" ]]; then
        EPICS_MD="$d/epics.md"
        break
      fi
    done
  fi
else
  EPICS_MD="$TARGET"
fi

if [[ ! -f "$EPICS_MD" ]]; then
  echo -e "${RED}ERROR: epics.md not found at $EPICS_MD${NC}" >&2
  exit 2
fi

# Trim leading/trailing whitespace from a string.
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

# Helper to check intersection between two lists of files/terms
check_intersection() {
  local list_a="$1"
  local list_b="$2"
  # Normalize lists: replace commas with newlines, remove spaces, and sort
  local norm_a; norm_a=$(echo "$list_a" | tr ',' '\n' | tr -d ' ' | grep -v '^$' | sort -u || true)
  local norm_b; norm_b=$(echo "$list_b" | tr ',' '\n' | tr -d ' ' | grep -v '^$' | sort -u || true)
  
  if [[ -z "$norm_a" || -z "$norm_b" ]]; then
    echo ""
    return
  fi

  # Find common lines
  local common; common=$(comm -12 <(echo "$norm_a") <(echo "$norm_b") || true)
  echo "$common"
}

epic_header_regex='^###[[:space:]]*(E[0-9]+)'
touch_points_regex='Touch-points'
migrations_regex='^[[:space:]]*-?[[:space:]]*Migrations:[[:space:]]*(.*)'
models_regex='^[[:space:]]*-?[[:space:]]*Models/Services:[[:space:]]*(.*)'
files_regex='^[[:space:]]*-?[[:space:]]*Files/Components:[[:space:]]*(.*)'
wave_regex='^[[:space:]]*\|[[:space:]]*([0-9]+)[[:space:]]*\|[[:space:]]*([^|]+)[[:space:]]*\|[[:space:]]*([^|]+)'

current_epic=""
in_touch_points=false
declare -a epic_ids=()
declare -a wave_ids=()

# Read epics.md line by line
while IFS= read -r line; do
  # Detect epic header
  if [[ "$line" =~ $epic_header_regex ]]; then
    current_epic="${BASH_REMATCH[1]}"
    in_touch_points=false
    eval "epic_migrations_${current_epic}=\"\""
    eval "epic_models_${current_epic}=\"\""
    eval "epic_files_${current_epic}=\"\""
    epic_ids+=("$current_epic")
  fi

  # Detect Touch-points header
  if [[ -n "$current_epic" && "$line" =~ $touch_points_regex ]]; then
    in_touch_points=true
    continue
  fi

  # Parse touch-points bullet points
  if [[ "$in_touch_points" == true ]]; then
    if [[ "$line" =~ ^"---" || "$line" =~ ^"###" ]]; then
      in_touch_points=false
    elif [[ "$line" =~ $migrations_regex ]]; then
      val=$(trim "${BASH_REMATCH[1]}")
      if [[ "$val" != "["* && "$val" != "—" && "$val" != "-" ]]; then
        eval "epic_migrations_${current_epic}=\"\$val\""
      fi
    elif [[ "$line" =~ $models_regex ]]; then
      val=$(trim "${BASH_REMATCH[1]}")
      if [[ "$val" != "["* && "$val" != "—" && "$val" != "-" ]]; then
        eval "epic_models_${current_epic}=\"\$val\""
      fi
    elif [[ "$line" =~ $files_regex ]]; then
      val=$(trim "${BASH_REMATCH[1]}")
      if [[ "$val" != "["* && "$val" != "—" && "$val" != "-" ]]; then
        eval "epic_files_${current_epic}=\"\$val\""
      fi
    fi
  fi

  # Detect wave rows in the table
  if [[ "$line" =~ $wave_regex ]]; then
    wave_id=$(trim "${BASH_REMATCH[1]}")
    epics_list=$(trim "${BASH_REMATCH[2]}")
    parallel_raw=$(trim "${BASH_REMATCH[3]}")
    
    parallel_lower=$(echo "$parallel_raw" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$parallel_lower" == "yes" ]]; then
      eval "wave_epics_${wave_id}=\"\$epics_list\""
      wave_ids+=("$wave_id")
    fi
  fi
done < "$EPICS_MD"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}🔍  Speck Wave Safety & Concurrency Collision Validator (v7.18.0)${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Target epics.md: $EPICS_MD"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

collisions=0

# Deduplicate wave_ids
unique_wave_ids=()
for w in "${wave_ids[@]:-}"; do
  [[ -z "$w" ]] && continue
  found=false
  for uw in "${unique_wave_ids[@]:-}"; do
    if [[ "$uw" == "$w" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" == false ]]; then
    unique_wave_ids+=("$w")
  fi
done

for wave in "${unique_wave_ids[@]:-}"; do
  eval "epics_raw=\$wave_epics_${wave}"
  # Split epics list on commas
  IFS=',' read -r -a wave_epics <<< "$epics_raw"
  
  # Trim each epic name
  trimmed_epics=()
  for e in "${wave_epics[@]}"; do
    trimmed=$(trim "$e")
    if [[ -n "$trimmed" ]]; then
      trimmed_epics+=("$trimmed")
    fi
  done

  count=${#trimmed_epics[@]}
  if [[ $count -lt 2 ]]; then
    continue
  fi

  echo -e "Checking Wave ${YELLOW}${wave}${NC} (Epics: ${trimmed_epics[*]}):"

  # Check all pairs
  for ((i=0; i<count; i++)); do
    for ((j=i+1; j<count; j++)); do
      epic_a="${trimmed_epics[i]}"
      epic_b="${trimmed_epics[j]}"

      # 1. Check migrations collision
      eval "mig_a=\${epic_migrations_${epic_a}:-}"
      eval "mig_b=\${epic_migrations_${epic_b}:-}"
      if [[ -n "$mig_a" && -n "$mig_b" ]]; then
        echo -e "  ${RED}❌ Collision (Migration head)${NC}: Both ${YELLOW}$epic_a${NC} and ${YELLOW}$epic_b${NC} author database migrations."
        echo -e "     - $epic_a: $mig_a"
        echo -e "     - $epic_b: $mig_b"
        collisions=$((collisions + 1))
      fi

      # 2. Check models/services collision
      eval "models_a=\${epic_models_${epic_a}:-}"
      eval "models_b=\${epic_models_${epic_b}:-}"
      common_models=$(check_intersection "$models_a" "$models_b")
      if [[ -n "$common_models" ]]; then
        echo -e "  ${RED}❌ Collision (Shared models/services)${NC}: Both ${YELLOW}$epic_a${NC} and ${YELLOW}$epic_b${NC} modify the same files:"
        echo "$common_models" | sed 's/^/     - /'
        collisions=$((collisions + 1))
      fi

      # 3. Check files/components collision
      eval "files_a=\${epic_files_${epic_a}:-}"
      eval "files_b=\${epic_files_${epic_b}:-}"
      common_files=$(check_intersection "$files_a" "$files_b")
      if [[ -n "$common_files" ]]; then
        echo -e "  ${RED}❌ Collision (Shared files/components)${NC}: Both ${YELLOW}$epic_a${NC} and ${YELLOW}$epic_b${NC} modify the same files:"
        echo "$common_files" | sed 's/^/     - /'
        collisions=$((collisions + 1))
      fi
    done
  done
done

echo -e "${BLUE}----------------------------------------------------------------------${NC}"
if [[ $collisions -gt 0 ]]; then
  echo -e "${RED}❌ WAVE SAFETY CHECK FAILED: ${collisions} collision(s) detected.${NC}"
  echo -e "${YELLOW}Epics running in the same parallel wave must not touch the same files or author migrations.${NC}"
  echo -e "${YELLOW}To resolve, either: (a) sequence them into different waves, or (b) use the 'schema-freeze foundation' pattern.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ WAVE SAFETY CHECK PASSED: Parallel waves are collision-free!${NC}"
exit 0
