#!/usr/bin/env bash
# reconcile-matrix-grain.sh — /speck-reprove Phase 1.5 (Speck v8.4, #87).
#
# The v7→v8 re-prove (DEC-0537) capped validation REPORTS but never wrote back to the traceability
# MATRICES — so a matrix keeps asserting `discharged` at a readiness the report's cap removed, and
# the two artifacts contradict each other in the same epic directory (#87). This reconciler closes
# that gap: for every `discharged` row whose discharging story's report is pre-v8-stamped or capped,
# it writes the row's Grain to the EFFECTIVE (capped) state, stamped `[pre-v8-proof]` — the same
# sentinel the reports carry, so matrix and report converge and MATRIX_GRAIN_CAP drops the epic to
# its honest ceiling.
#
# Usage:
#   reconcile-matrix-grain.sh [--dry-run] <PROJECT_DIR>
#
# Invariants:
#   • Status is NEVER touched — every row stays `discharged`. Conservation math is byte-identical.
#   • NEVER auto-promotes to product grain — it only ever writes the capped (≤ integration-green) grain.
#   • Reads the EFFECTIVE state (the cap), never the preserved numeric claim.
#   • Idempotent: re-running produces byte-identical output.
#   • Inserts the Grain column (before Status) if the matrix is still 6/7-col.
#
# Exit codes: 0 = ok (reconciled or already-clean), 2 = invocation error.
#
# Portable bash 3.2 (no mapfile, no associative arrays).

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

DRY_RUN=false
PROJECT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) PROJECT_DIR="$1"; shift ;;
  esac
done

if [[ -z "$PROJECT_DIR" || ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: provide an existing project directory." >&2
  exit 2
fi

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

extract_readiness_state() {
  local raw first lc
  raw="${1#*:}"
  raw="$(printf '%s' "$raw" | tr -d "\`*\"'")"
  first="$(printf '%s' "$raw" | awk '{print $1}')"
  first="${first%%(*}"; first="${first%%,*}"
  first="$(trim "$first")"
  lc="$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')"
  case "$lc" in
    no-ship|impl-green|integration-green|ux-rc|api-rc|operational-rc|commercial-rc|ship-rc|ship) printf '%s' "$lc" ;;
    *) printf '' ;;
  esac
}

grain_rank() {
  case "$1" in
    no-ship) printf '0' ;; impl-green) printf '1' ;; integration-green) printf '2' ;;
    ux-rc) printf '3' ;; api-rc) printf '4' ;; operational-rc) printf '5' ;;
    commercial-rc) printf '6' ;; ship-rc) printf '7' ;; ship) printf '8' ;; *) printf '-1' ;;
  esac
}

is_empty_cell() {
  local v; v="$(trim "$1")"
  [[ -z "$v" || "$v" == "—" || "$v" == "-" || "$v" == "–" || "$v" == "N/A" ]] && return 0
  case "$v" in '['*']') return 0 ;; esac
  return 1
}

ROW_CELLS=()
split_row() {
  local line="$1" i cell
  local -a raw=()
  IFS='|' read -r -a raw <<< "$line" || true
  ROW_CELLS=()
  for (( i=1; i<${#raw[@]}; i++ )); do
    cell="$(trim "${raw[$i]}")"
    ROW_CELLS+=("$cell")
  done
  # Drop a single trailing empty cell (from the closing '|').
  local n=${#ROW_CELLS[@]}
  if [[ $n -gt 0 && -z "${ROW_CELLS[$((n-1))]}" ]]; then unset 'ROW_CELLS[$((n-1))]'; fi
}

COL_ID=-1; COL_STATUS=-1; COL_GRAIN=-1; COL_DISCHARGE=-1
resolve_columns_from_header() {
  split_row "$1"
  COL_ID=-1; COL_STATUS=-1; COL_GRAIN=-1; COL_DISCHARGE=-1
  local i lc
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    lc="$(printf '%s' "${ROW_CELLS[$i]}" | tr '[:upper:]' '[:lower:]')"
    case "$lc" in
      prm-id*)    COL_ID=$i ;;
      discharge*) COL_DISCHARGE=$i ;;
      grain*)     COL_GRAIN=$i ;;
      status*)    COL_STATUS=$i ;;
    esac
  done
}

# Join the current ROW_CELLS array into a markdown row.
join_row() {
  local out="|" c
  for c in "${ROW_CELLS[@]}"; do out="$out $c |"; done
  printf '%s' "$out"
}

# Is a story validation report pre-v8 (carries the reprove cap)? True if it has the [pre-v8-proof]
# sentinel OR is stamped speck < v8.
report_is_pre_v8() {
  local report="$1"
  grep -qi "pre-v8-proof" "$report" && return 0
  grep -qiE 'speck[ _]v?7|speck_version:[[:space:]]*"?7' "$report" && return 0
  return 1
}

# Effective (capped) grain for a pre-v8 discharged row: the numeric claim, but never above
# integration-green (the /speck-reprove cap). Defaults to integration-green when unparseable.
effective_capped_grain() {
  local report="$1" state_line numeric
  state_line="$(grep -i "readiness_state_verified:" "$report" | head -n1 || true)"
  [[ -z "$state_line" ]] && state_line="$(grep -i "\*\*Verified Readiness State\**:" "$report" | head -n1 || true)"
  numeric="$(extract_readiness_state "$state_line")"
  if [[ -z "$numeric" || "$(grain_rank "$numeric")" -gt "$(grain_rank integration-green)" ]]; then
    printf 'integration-green'
  else
    printf '%s' "$numeric"
  fi
}

find_story_report() {
  local epic_dir="$1" story_id="$2" d
  for d in "$epic_dir/stories/"${story_id}*; do
    if [[ -d "$d" && -f "$d/validation-report.md" ]]; then printf '%s' "$d/validation-report.md"; return 0; fi
  done
  return 0
}

total_matrices=0
total_regraded=0
total_columns_added=0
matrices_changed=0

# Find all traceability matrices.
matrices=()
while IFS= read -r -d '' f; do matrices+=("$f"); done < <(find "$PROJECT_DIR" -name "traceability-matrix.md" -print0 2>/dev/null || true)

if [[ ${#matrices[@]} -eq 0 ]]; then
  echo -e "${YELLOW}⚠️  No traceability-matrix.md files found under $PROJECT_DIR — nothing to reconcile.${NC}"
  exit 0
fi

for MATRIX in "${matrices[@]}"; do
  total_matrices=$((total_matrices + 1))
  EPIC_DIR="$(cd "$(dirname "$MATRIX")" && pwd)"
  epic_name="$(basename "$EPIC_DIR")"

  # First pass: resolve header + detect grain presence.
  header_found=false; has_grain=false; status_idx=-1; grain_idx=-1; discharge_idx=-1
  while IFS= read -r line; do
    if [[ "$line" =~ ^\|[[:space:]]*[Pp][Rr][Mm]-[Ii][Dd] ]]; then
      resolve_columns_from_header "$line"
      header_found=true; status_idx=$COL_STATUS; grain_idx=$COL_GRAIN; discharge_idx=$COL_DISCHARGE
      [[ $COL_GRAIN -ge 0 ]] && has_grain=true
      break
    fi
  done < "$MATRIX"

  if [[ "$header_found" != true || "$status_idx" -lt 0 ]]; then
    echo -e "${YELLOW}⚠️  $epic_name: no recognizable matrix header — skipped.${NC}"
    continue
  fi

  regraded_here=0
  column_added_here=false
  TMP_OUT="$(mktemp)"
  after_header=false

  while IFS= read -r line; do
    # Header row.
    if [[ "$line" =~ ^\|[[:space:]]*[Pp][Rr][Mm]-[Ii][Dd] ]]; then
      if [[ "$has_grain" != true ]]; then
        split_row "$line"
        # Insert "Grain (proven-at)" before Status.
        local_new=(); i=0
        for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
          [[ $i -eq $status_idx ]] && local_new+=("Grain (proven-at)")
          local_new+=("${ROW_CELLS[$i]}")
        done
        ROW_CELLS=("${local_new[@]}")
        join_row >> "$TMP_OUT"; printf '\n' >> "$TMP_OUT"
        column_added_here=true
      else
        printf '%s\n' "$line" >> "$TMP_OUT"
      fi
      after_header=true
      continue
    fi

    # Separator row immediately after header (only dashes/colons/pipes/spaces).
    if [[ "$after_header" == true && "$line" =~ ^\|[[:space:]:|-]+$ ]]; then
      if [[ "$has_grain" != true ]]; then
        split_row "$line"
        local_new=(); i=0
        for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
          [[ $i -eq $status_idx ]] && local_new+=("-------------------")
          local_new+=("${ROW_CELLS[$i]}")
        done
        ROW_CELLS=("${local_new[@]}")
        join_row >> "$TMP_OUT"; printf '\n' >> "$TMP_OUT"
      else
        printf '%s\n' "$line" >> "$TMP_OUT"
      fi
      after_header=false
      continue
    fi
    after_header=false

    # Data row.
    if [[ "$line" =~ ^\|[[:space:]]*PRM-[0-9]+ ]]; then
      split_row "$line"
      # If we're inserting the column, splice an empty grain cell before Status first.
      cur_grain_idx=$grain_idx
      cur_status_idx=$status_idx
      if [[ "$has_grain" != true ]]; then
        local_new=(); i=0
        for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
          [[ $i -eq $status_idx ]] && local_new+=("—")
          local_new+=("${ROW_CELLS[$i]}")
        done
        ROW_CELLS=("${local_new[@]}")
        cur_grain_idx=$status_idx
        cur_status_idx=$((status_idx + 1))
      fi

      # Skip template example rows (promise placeholder) — leave untouched.
      status_val="$(printf '%s' "${ROW_CELLS[$cur_status_idx]:-}" | tr '[:upper:]' '[:lower:]')"
      status_val="$(trim "$status_val")"

      if [[ "$status_val" == "discharged" ]]; then
        # Discharge column is left of Status, so a grain splice never shifts it.
        disch="${ROW_CELLS[$discharge_idx]:-}"
        story_id=""
        [[ "$disch" =~ (S[0-9]+) ]] && story_id="${BASH_REMATCH[1]}"
        new_grain="${ROW_CELLS[$cur_grain_idx]}"   # default: preserve existing
        if [[ -n "$story_id" ]]; then
          report="$(find_story_report "$EPIC_DIR" "$story_id")"
          if [[ -n "$report" ]] && report_is_pre_v8 "$report"; then
            eff="$(effective_capped_grain "$report")"
            candidate="$eff [pre-v8-proof]"
            if [[ "${ROW_CELLS[$cur_grain_idx]}" != "$candidate" ]]; then
              regraded_here=$((regraded_here + 1))
            fi
            new_grain="$candidate"
          fi
        fi
        ROW_CELLS[$cur_grain_idx]="$new_grain"
      fi

      join_row >> "$TMP_OUT"; printf '\n' >> "$TMP_OUT"
      continue
    fi

    printf '%s\n' "$line" >> "$TMP_OUT"
  done < "$MATRIX"

  # Write back only if changed.
  if ! cmp -s "$TMP_OUT" "$MATRIX"; then
    if [[ "$DRY_RUN" == true ]]; then
      echo -e "${BLUE}↺ $epic_name: would regrade ${regraded_here} row(s)$( [[ "$column_added_here" == true ]] && printf ' + insert Grain column')  (dry-run).${NC}"
    else
      cp "$TMP_OUT" "$MATRIX"
      echo -e "${GREEN}↺ $epic_name: regraded ${regraded_here} pre-v8 discharged row(s)$( [[ "$column_added_here" == true ]] && printf ' + inserted Grain column').${NC}"
    fi
    matrices_changed=$((matrices_changed + 1))
  else
    echo -e "${BLUE}✓ $epic_name: already reconciled (no change).${NC}"
  fi
  total_regraded=$((total_regraded + regraded_here))
  [[ "$column_added_here" == true ]] && total_columns_added=$((total_columns_added + 1))
  rm -f "$TMP_OUT"
done

echo ""
echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}📐 Matrix grain reconcile (v8 re-prove Phase 1.5)${NC}"
echo -e "Matrices scanned        : $total_matrices"
echo -e "Matrices changed        : $matrices_changed"
echo -e "Grain columns inserted  : $total_columns_added"
echo -e "Rows regraded [pre-v8]  : $total_regraded"
echo -e "${BLUE}======================================================================${NC}"
# Machine-readable line for the reprove report / recheck to fold in.
echo "MATRIX_GRAIN_RECONCILE regraded=${total_regraded} columns_added=${total_columns_added} matrices_changed=${matrices_changed}"
exit 0
