#!/usr/bin/env bash
# compute-cascade.sh — Reverse blast-radius / change-cascade computer (Speck v7.17).
#
# Scans all traceability-matrix.md files in the project to identify downstream 
# epics, stories, and promises affected by a changed product-contract section 
# or a superseded decision (DEC-NNNN).
#
# Usage:
#   bash compute-cascade.sh [--dec DEC-NNNN] [--contract-section "<section>"] [--strict] [SPECS_ROOT]
#
# Exit codes:
#   0 = informational / no active violations (all affected downstream are adjusted/not discharged under old state)
#   1 = active violations (superseded DEC/changed section has active, un-adjusted discharged downstream rows under --strict)
#   2 = invocation error
#
# Portable bash 3.2.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

DEC_TARGET=""
SECTION_TARGET=""
STRICT=false
SPECS_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dec)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --dec requires an argument." >&2
        exit 2
      fi
      DEC_TARGET="$2"
      shift 2
      ;;
    --contract-section)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --contract-section requires an argument." >&2
        exit 2
      fi
      SECTION_TARGET="$2"
      shift 2
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    -*)
      echo "ERROR: Unknown option $1" >&2
      exit 2
      ;;
    *)
      if [[ -z "$SPECS_ROOT" ]]; then
        SPECS_ROOT="$1"
      else
        echo "ERROR: Duplicate specs root argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

# If SPECS_ROOT is empty, default to specs/ or current directory
if [[ -z "$SPECS_ROOT" ]]; then
  if [[ -d "specs" ]]; then
    SPECS_ROOT="specs"
  else
    SPECS_ROOT="."
  fi
fi

if [[ -z "$DEC_TARGET" && -z "$SECTION_TARGET" ]]; then
  echo "ERROR: Must specify at least one of --dec or --contract-section." >&2
  exit 2
fi

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

is_empty_cell() {
  local v; v="$(trim "$1")"
  [[ -z "$v" || "$v" == "—" || "$v" == "-" || "$v" == "–" || "$v" == "N/A" ]] && return 0
  case "$v" in '['*']') return 0 ;; esac
  return 1
}

# Find all traceability matrices
matrices=()
while IFS= read -r -d '' file; do
  matrices+=("$file")
done < <(find "$SPECS_ROOT" -name "traceability-matrix.md" -print0 2>/dev/null || true)

if [[ ${#matrices[@]} -eq 0 ]]; then
  search_term=""
  if [[ -n "$DEC_TARGET" ]]; then
    search_term="$DEC_TARGET"
  elif [[ -n "$SECTION_TARGET" ]]; then
    search_term="$SECTION_TARGET"
  fi

  echo -e "${YELLOW}⚠️  No traceability-matrix.md files found under $SPECS_ROOT.${NC}"
  echo -e "${YELLOW}⚠️  Falling back to pre-matrix grep scan for '${search_term}' across specs/**...${NC}"

  # Find all markdown files and grep for the search term
  matching_files=()
  while IFS= read -r -d '' file; do
    if grep -q -F "$search_term" "$file" 2>/dev/null; then
      matching_files+=("$file")
    fi
  done < <(find "$SPECS_ROOT" -name "*.md" -print0 2>/dev/null || true)

  if [[ ${#matching_files[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ Grep scan complete: No references to '${search_term}' found in specs.${NC}"
    exit 0
  fi

  echo -e "\n${RED}📍 Found ${#matching_files[@]} file(s) referencing '${search_term}':${NC}"
  for f in "${matching_files[@]}"; do
    echo -e "  - ${YELLOW}$f${NC}"
  done

  echo -e "\n📋  ${YELLOW}ADJUSTMENT WORK-LIST REQUIRED (Pre-Matrix Fallback):${NC}"
  echo -e "The project has no traceability matrices yet, but the files above reference the changed contract or decision."
  echo -e "You should run ${BLUE}/epic-adjust${NC} or ${BLUE}/story-adjust${NC} on the affected epics/stories to align them."

  if [[ "$STRICT" == true ]]; then
    echo -e "\n${RED}❌ CASCADE BLOCKER DETECTED (CASCADE_STALE.P1)${NC}"
    echo -e "${RED}A project-level directional change or superseded decision was found, and${NC}"
    echo -e "${RED}${#matching_files[@]} file(s) still reference '${search_term}' under the old state.${NC}"
    exit 1
  fi

  echo -e "\n${YELLOW}⚠️  Cascade checked (fallback mode). Downstream deltas are identified.${NC}"
  exit 0
fi

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}🔍  Speck Change Cascade Computer (v7.17.0)${NC}"
echo -e "${BLUE}======================================================================${NC}"
[[ -n "$DEC_TARGET" ]] && echo -e "Superseded DEC Target      : ${YELLOW}$DEC_TARGET${NC}"
[[ -n "$SECTION_TARGET" ]] && echo -e "Changed Contract Section   : ${YELLOW}$SECTION_TARGET${NC}"
echo -e "Specs Root                 : $SPECS_ROOT"
echo -e "Strict Mode (Gate Active)  : $STRICT"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

affected_count=0
discharged_violations=0

# Keep track of worklists
declare -a affected_epics=()
declare -a affected_stories=()
declare -a affected_prms=()

for matrix in "${matrices[@]}"; do
  # Determine epic and project name from path
  epic_dir="$(dirname "$matrix")"
  epic_name="$(basename "$epic_dir")"
  project_dir="$(dirname "$(dirname "$epic_dir")")"
  project_name="$(basename "$project_dir")"

  # If not under an epics/ folder, adjust names
  if [[ "$project_name" == "projects" ]]; then
    project_dir="$(dirname "$epic_dir")"
    project_name="$(basename "$project_dir")"
  fi

  matrix_has_affected=false

  while IFS= read -r line; do
    # Only data rows whose first cell is PRM-<digits>
    [[ "$line" =~ ^\|[[:space:]]*PRM-[0-9]+ ]] || continue

    IFS='|' read -r _lead c_id c_src c_promise c_discharge c_dec c_col6 c_col7 _rest <<< "$line"

    id="$(trim "${c_id:-}")"
    src="$(trim "${c_src:-}")"
    promise="$(trim "${c_promise:-}")"
    discharge="$(trim "${c_discharge:-}")"
    dec_cell="$(trim "${c_dec:-}")"
    
    # Ignore template example lines
    case "$promise" in '['*']') continue ;; esac

    # Determine status (old 6-column vs new 7-column matrix)
    status_raw=""
    if [[ -n "$(trim "${c_col7:-}")" || "$line" =~ \|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\| ]]; then
      status_raw="${c_col7:-}"
    else
      status_raw="${c_col6:-}"
    fi
    status="$(trim "$status_raw")"
    status_lower="$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')"

    # Check match criteria
    match=false
    if [[ -n "$DEC_TARGET" && "$dec_cell" == *"$DEC_TARGET"* ]]; then
      match=true
    fi
    if [[ -n "$SECTION_TARGET" && "$src" == *"$SECTION_TARGET"* ]]; then
      match=true
    fi

    if [[ "$match" == true ]]; then
      if [[ "$matrix_has_affected" == false ]]; then
        echo -e "\n${BLUE}📍 Epic: $epic_name (Project: $project_name)${NC}"
        matrix_has_affected=true
      fi

      affected_count=$((affected_count + 1))
      
      # Extract story ID from discharge
      story_id="—"
      if [[ -n "$discharge" ]]; then
        # Matches S### pattern if present
        if [[ "$discharge" =~ S[0-9]+ ]]; then
          story_id="${BASH_REMATCH[0]}"
        else
          story_id="$discharge"
        fi
      fi

      # Format console line
      status_color="${GREEN}"
      [[ "$status_lower" == "discharged" ]] && status_color="${RED}" # Under superseded DEC, discharged is a risk!
      [[ "$status_lower" == "descoped" ]] && status_color="${NC}"

      echo -e "  - [${status_color}${status}${NC}] ${YELLOW}$id${NC} | Src: $src | Story: $story_id | DEC: $dec_cell"

      # Record for unique summaries
      [[ " ${affected_epics[*]:-} " != *" $epic_name "* ]] && affected_epics+=("$epic_name")
      [[ " ${affected_stories[*]:-} " != *" $story_id "* && "$story_id" != "—" ]] && affected_stories+=("$story_id")
      [[ " ${affected_prms[*]:-} " != *" $id "* ]] && affected_prms+=("$id")

      # Under strict mode, if a superseded decision has an active discharged downstream row, it is a P1 blocker!
      if [[ "$status_lower" == "discharged" ]]; then
        discharged_violations=$((discharged_violations + 1))
      fi
    fi
  done < "$matrix"
done

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "📊  ${BLUE}CASCADE SUMMARY${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Total Promises Affected      : $affected_count"
echo -e "Active Discharged Promises   : $discharged_violations"
echo -e "Affected Epics Count         : ${#affected_epics[@]}"
echo -e "Affected Stories Count       : ${#affected_stories[@]}"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

if [[ ${#affected_epics[@]} -gt 0 ]]; then
  echo -e "\n📋  ${YELLOW}ADJUSTMENT WORK-LIST REQUIRED:${NC}"
  echo -e "The following epics and stories are in the blast-radius. You MUST run:"
  for epic in "${affected_epics[@]}"; do
    echo -e "  - ${BLUE}/epic-adjust${NC} on ${YELLOW}$epic${NC}"
  done
  if [[ ${#affected_stories[@]} -gt 0 ]]; then
    echo -e "And run ${BLUE}/story-adjust${NC} on the following affected stories:"
    printf "  - "
    for story in "${affected_stories[@]}"; do
      printf "${YELLOW}%s${NC} " "$story"
    done
    printf "\n"
  fi
fi

if [[ "$STRICT" == true && $discharged_violations -gt 0 ]]; then
  echo -e "\n${RED}❌ CASCADE BLOCKER DETECTED (CASCADE_STALE.P1)${NC}"
  echo -e "${RED}A project-level directional change or superseded decision was found, but${NC}"
  echo -e "${RED}$discharged_violations downstream promise(s) are still active as 'discharged' under the old state.${NC}"
  echo -e "${YELLOW}Every affected story and epic must run /story-adjust or /epic-adjust to${NC}"
  echo -e "${YELLOW}either descope the promise (via a new DEC) or re-specify and re-validate the delta.${NC}"
  exit 1
fi

if [[ $affected_count -gt 0 ]]; then
  echo -e "\n${YELLOW}⚠️  Cascade checked. Downstream deltas are identified.${NC}"
else
  echo -e "\n${GREEN}✅ Cascade checked. No downstream promises are affected.${NC}"
fi

exit 0
