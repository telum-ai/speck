#!/usr/bin/env bash
# validate-traceability-matrix.sh — Promise conservation gate (Speck v7.15).
#
# Parses a traceability-matrix.md and enforces that every PRM-NNN row RESOLVES:
#   • discharged by a story+AC, OR
#   • descoped by a DEC, OR
#   • pilot-gated (deferred to pilot, requires a backing reference), OR
#   • visibly open (allowed ONLY before epic-breakdown.md exists).
#
# Usage:
#   validate-traceability-matrix.sh [--require-evidence] <matrix.md | epic-dir>
#
# Modes:
#   default            : once epic-breakdown.md exists, NO row may be open — each row needs a
#                        discharge (story+AC), a DEC, or a pilot-gated status. Pre-breakdown, open rows are allowed.
#   --require-evidence : (epic-validate) every row must be `discharged`, `descoped`, or `pilot-gated`.
#
# Exit codes: 0 = pass, 1 = unresolved promises, 2 = invocation error.
#
# Portable bash 3.2 (no mapfile, guarded array expansion).

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

REQUIRE_EVIDENCE=false
STATUS_ONLY=false
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-evidence) REQUIRE_EVIDENCE=true; shift ;;
    --status-only) STATUS_ONLY=true; shift ;;
    --strict) shift ;;  # accepted for router compatibility; this validator is always strict
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "ERROR: provide a traceability-matrix.md path or an epic directory." >&2
  exit 2
fi

# Resolve matrix path + owning epic dir.
if [[ -d "$TARGET" ]]; then
  EPIC_DIR="$TARGET"
  MATRIX="$TARGET/traceability-matrix.md"
elif [[ -f "$TARGET" ]]; then
  MATRIX="$TARGET"
  EPIC_DIR="$(cd "$(dirname "$TARGET")" && pwd)"
else
  echo -e "${RED}ERROR: '$TARGET' not found.${NC}" >&2
  exit 2
fi

if [[ ! -f "$MATRIX" ]]; then
  echo -e "${RED}ERROR: traceability-matrix.md not found at $MATRIX${NC}" >&2
  exit 2
fi

BREAKDOWN_EXISTS=false
[[ -f "$EPIC_DIR/epic-breakdown.md" ]] && BREAKDOWN_EXISTS=true

# Trim leading/trailing whitespace from a string.
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

# Treat —, -, em-dash, empty, or a [bracket placeholder] as "no value".
is_empty_cell() {
  local v; v="$(trim "$1")"
  [[ -z "$v" || "$v" == "—" || "$v" == "-" || "$v" == "–" || "$v" == "N/A" ]] && return 0
  case "$v" in '['*']') return 0 ;; esac
  return 1
}

violations=0
open_rows=0
total=0

while IFS= read -r line; do
  # Only data rows whose first cell is PRM-<digits>. Skips header (PRM-ID) and separators.
  [[ "$line" =~ ^\|[[:space:]]*PRM-[0-9]+ ]] || continue

  # Split the markdown row on '|'. Leading '|' yields an empty first field.
  # Handles both old 6-column matrix and new 7-column matrix (with Backing column) gracefully.
  IFS='|' read -r _lead c_id c_src c_promise c_discharge c_dec c_col6 c_col7 _rest <<< "$line"

  id="$(trim "${c_id:-}")"
  promise="$(trim "${c_promise:-}")"
  discharge="$(trim "${c_discharge:-}")"
  
  # Heuristically detect whether this is a 6-column or 7-column table by looking at _rest or fields
  # In 6-column: c_discharge is col 4, c_dec is col 5, c_col6 is col 6 (status), c_col7 is rest/empty
  # In 7-column: c_discharge is col 4, c_dec is col 5, c_col6 is col 6 (backing), c_col7 is col 7 (status)
  status_raw=""
  backing_raw=""
  if [[ -n "$(trim "${c_col7:-}")" || "$line" =~ \|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\|[[:space:]]*[^\|]+[[:space:]]*\| ]]; then
    backing_raw="${c_col6:-}"
    status_raw="${c_col7:-}"
  else
    backing_raw=""
    status_raw="${c_col6:-}"
  fi

  status="$(trim "$status_raw")"
  status="$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')"
  backing="$(trim "$backing_raw")"

  # Skip the template's own example rows (promise still a [bracket placeholder]).
  case "$promise" in '['*']') continue ;; esac

  total=$((total + 1))

  has_discharge=false; is_empty_cell "${c_discharge:-}" || has_discharge=true
  has_dec=false;       is_empty_cell "${c_dec:-}" || has_dec=true
  has_backing=false;   is_empty_cell "$backing" || has_backing=true

  # If pilot-gated, it MUST have a backing reference (cannot silently defer without citing details)
  if [[ "$status" == "pilot-gated" && "$has_backing" == false ]]; then
    echo -e "${RED}❌ $id${NC}: status 'pilot-gated' but has no backing reference! Cite fine-grained audit/matrix refs (e.g. AUDIT-E002-42) in the Backing column."
    violations=$((violations + 1))
  fi

  if [[ "$REQUIRE_EVIDENCE" == true ]]; then
    if [[ "$status" != "discharged" && "$status" != "descoped" && "$status" != "pilot-gated" ]]; then
      echo -e "${RED}❌ $id${NC}: status '${status:-<blank>}' — at epic-validate every promise must be 'discharged', 'descoped' (DEC), or 'pilot-gated' (with backing)."
      violations=$((violations + 1))
    elif [[ "$status" == "discharged" && "$STATUS_ONLY" == false ]]; then
      # Parse story_id and ac_id
      story_id=""
      if [[ "$discharge" =~ (S[0-9]+) ]]; then
        story_id="${BASH_REMATCH[1]}"
      fi
      ac_id=""
      if [[ "$discharge" =~ (AC-[0-9]+) ]]; then
        ac_id="${BASH_REMATCH[1]}"
      fi

      if [[ -z "$story_id" ]]; then
        echo -e "${RED}❌ $id${NC}: status 'discharged' but has no story ID in Discharge column!"
        violations=$((violations + 1))
      else
        # Find story directory
        story_dir=""
        for d in "$EPIC_DIR/stories/"${story_id}*; do
          if [[ -d "$d" ]]; then
            story_dir="$d"
            break
          fi
        done

        if [[ -z "$story_dir" || ! -f "$story_dir/validation-report.md" ]]; then
          echo -e "${RED}❌ $id${NC}: status 'discharged' but story validation report not found for ${story_id} at ${story_dir:-$EPIC_DIR/stories/${story_id}*}/validation-report.md"
          violations=$((violations + 1))
        else
          report_path="$story_dir/validation-report.md"
          # Parse verified state
          verified_state=$(grep -i "readiness_state_verified:" "$report_path" | cut -d':' -f2 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' || echo "")
          if [[ -z "$verified_state" ]]; then
            verified_state=$(grep -i "\*\*Verified Readiness State\**:" "$report_path" | cut -d':' -f2- | tr -d '[:space:]*`' | tr '[:upper:]' '[:lower:]' || echo "")
          fi

          # Check if verified state is at least integration-green
          is_valid_state=false
          case "$verified_state" in
            integration-green|ux-rc|api-rc|commercial-rc|ship-rc|ship) is_valid_state=true ;;
          esac

          if [[ "$is_valid_state" == false ]]; then
            echo -e "${RED}❌ $id${NC}: status 'discharged' but story validation report verified state '${verified_state:-<blank>}' is less than INTEGRATION-GREEN"
            violations=$((violations + 1))
          else
            # Check if report contains PRM ID or AC ID
            has_ref=false
            if grep -q -F "$id" "$report_path"; then
              has_ref=true
            elif [[ -n "$ac_id" ]] && grep -q -F "$ac_id" "$report_path"; then
              has_ref=true
            fi

            if [[ "$has_ref" == false ]]; then
              if [[ -n "$ac_id" ]]; then
                echo -e "${RED}❌ $id${NC}: status 'discharged' but story validation report does not cite $id or $ac_id"
              else
                echo -e "${RED}❌ $id${NC}: status 'discharged' but story validation report does not cite $id"
              fi
              violations=$((violations + 1))
            fi
          fi
        fi
      fi
    fi
  else
    if [[ "$status" != "pilot-gated" ]]; then
      if [[ "$has_discharge" == false && "$has_dec" == false ]]; then
        if [[ "$BREAKDOWN_EXISTS" == true ]]; then
          echo -e "${RED}❌ $id${NC}: unmapped (no story+AC, no DEC) after epic-breakdown — promises cannot evaporate. Assign a story+AC, a DEC, or set to pilot-gated (with backing)."
          violations=$((violations + 1))
        else
          open_rows=$((open_rows + 1))
        fi
      fi
    fi
  fi
done < "$MATRIX"

echo ""
if [[ "$REQUIRE_EVIDENCE" == true ]]; then
  echo -e "${BLUE}🔎 Promise conservation (evidence mode): ${total} promise(s) checked.${NC}"
else
  if [[ "$BREAKDOWN_EXISTS" == true ]]; then
    echo -e "${BLUE}🔎 Promise conservation: ${total} promise(s); breakdown present → open rows not allowed.${NC}"
  else
    echo -e "${BLUE}🔎 Promise conservation: ${total} promise(s); ${open_rows} open (pre-breakdown — allowed for now).${NC}"
  fi
fi

if [[ $violations -gt 0 ]]; then
  echo -e "${RED}❌ ${violations} promise(s) unresolved.${NC}"
  echo -e "${YELLOW}Every PRM row must map to a story+AC, be descoped via a DEC, or (pre-breakdown only) stay visibly open.${NC}"
  echo -e "${YELLOW}This is the conservation law — a drawn wireframe or stated seam that has no story and no DEC is a silently-evaporated promise.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Promise conservation holds — no promise evaporated.${NC}"
exit 0
