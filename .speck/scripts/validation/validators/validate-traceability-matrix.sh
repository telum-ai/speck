#!/usr/bin/env bash
# validate-traceability-matrix.sh — Promise conservation gate (Speck v8.5).
#
# Parses a traceability-matrix.md and enforces that every PRM-NNN row RESOLVES:
#   • discharged by a story+AC, OR
#   • descoped by a DEC, OR
#   • pilot-gated (deferred to pilot, requires a backing reference), OR
#   • visibly open (allowed ONLY before epic-breakdown.md exists).
#
# Usage:
#   validate-traceability-matrix.sh [--require-evidence] [--status-only] [--check-fidelity] <matrix.md | epic-dir>
#
# Modes:
#   default            : once epic-breakdown.md exists, NO row may be open — each row needs a
#                        discharge (story+AC), a DEC, or a pilot-gated status. Pre-breakdown, open rows are allowed.
#   --require-evidence : (epic-validate) every row must be `discharged`, `descoped`, or `pilot-gated`.
#   --check-fidelity   : (opt-in, #86) WARN-only Promise↔Source structural check (presence + vocabulary
#                        overlap). NEVER touches the conservation exit code.
#
# GRAIN (Speck v8.4, #87; ENFORCED v8.5) — a second, ORTHOGONAL axis. Status answers "resolved?"
# (conservation, unchanged); the optional `Grain (proven-at)` column answers "at what grain was the
# discharging evidence collected?" (readiness-ladder enum, optionally ` [pre-v8-proof]`). As of
# v8.5.0 the grain teeth BLOCK under --require-evidence (the /epic-validate gate): grain ≤ the
# discharging story's effective state; a ≥ ux-rc row must cite walk-evidence; an invalid grain token
# is rejected. On the fast path (default mode: pre-commit/recheck) grain findings stay surfaced-only
# (WARN, non-blocking) — enforcement lives at the validate gate, not the commit. Absent grain is
# NEVER a violation in any mode. The gate emits MATRIX_GRAIN_CAP = MIN grain over ALL discharged rows
# for /epic-validate to fold into MAX claimable = MIN(story states, MATRIX_GRAIN_CAP). Promise
# CONSERVATION exit-1 logic is byte-for-byte unchanged since v8.3 — grain violations are a separate,
# additive block.
#
# NOTE on the `[pre-v8-proof]` sentinel: it lives BOTH in a validation report (a story-level fact:
# "this claim predates v8 proof") and in a matrix Grain cell (a row-level fact: "this row's grain
# predates v8 proof"). These are genuinely different facts that happen to share a token — NOT a
# one-fact-two-homes drift violation. /speck-reprove is what converges them.
#
# Exit codes: 0 = pass, 1 = unresolved promises, 2 = invocation error.
#
# Portable bash 3.2 (no mapfile, no associative arrays, guarded array expansion).

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

REQUIRE_EVIDENCE=false
STATUS_ONLY=false
CHECK_FIDELITY=false
TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-evidence) REQUIRE_EVIDENCE=true; shift ;;
    --status-only) STATUS_ONLY=true; shift ;;
    --check-fidelity) CHECK_FIDELITY=true; shift ;;
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

# Extract the FIRST canonical readiness-state token from a "key: value" line via the
# state enum — never the whole line. A value like "UX-RC (agent-verified)" or
# "INTEGRATION-GREEN — capped, awaiting keystone" must resolve to the bare token
# ("ux-rc" / "integration-green"), not a mangled "ux-rc(agent-verified)". (#76.3)
extract_readiness_state() {
  local raw first lc
  raw="${1#*:}"                                  # value after the first ':'
  raw="$(printf '%s' "$raw" | tr -d "\`*\"'")"   # strip md emphasis / code ticks / quotes
  first="$(printf '%s' "$raw" | awk '{print $1}')"  # first whitespace-delimited token
  first="${first%%(*}"; first="${first%%,*}"     # drop glued "(..." / ",..." suffixes
  first="$(trim "$first")"
  lc="$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')"
  case "$lc" in
    no-ship|impl-green|integration-green|ux-rc|api-rc|operational-rc|commercial-rc|ship-rc|ship) printf '%s' "$lc" ;;
    *) printf '' ;;
  esac
}

# Extract the canonical grain token from a Grain cell (first token, md/quote-stripped, a trailing
# ` [pre-v8-proof]` is ignored for enum matching). Returns lowercase enum or '' if not a valid grain.
extract_grain() {
  local raw first lc
  raw="$(printf '%s' "$1" | tr -d "\`*\"'")"
  first="$(printf '%s' "$raw" | awk '{print $1}')"
  first="$(trim "$first")"
  lc="$(printf '%s' "$first" | tr '[:upper:]' '[:lower:]')"
  case "$lc" in
    no-ship|impl-green|integration-green|ux-rc|api-rc|operational-rc|commercial-rc|ship-rc|ship) printf '%s' "$lc" ;;
    *) printf '' ;;
  esac
}

# Numeric rank of a readiness/grain enum token on the ladder (higher = more proven).
grain_rank() {
  case "$1" in
    no-ship)          printf '0' ;;
    impl-green)       printf '1' ;;
    integration-green) printf '2' ;;
    ux-rc)            printf '3' ;;
    api-rc)           printf '4' ;;
    operational-rc)   printf '5' ;;
    commercial-rc)    printf '6' ;;
    ship-rc)          printf '7' ;;
    ship)             printf '8' ;;
    *)                printf '-1' ;;
  esac
}

# Treat —, -, em-dash, empty, or a [bracket placeholder] as "no value".
is_empty_cell() {
  local v; v="$(trim "$1")"
  [[ -z "$v" || "$v" == "—" || "$v" == "-" || "$v" == "–" || "$v" == "N/A" ]] && return 0
  case "$v" in '['*']') return 0 ;; esac
  return 1
}

# --- Header-keyed row parser (Speck v8.4) --------------------------------------------------------
# Split a markdown table row into the global array ROW_CELLS (trimmed, 0-indexed at the FIRST real
# column — the empty field before the leading '|' is dropped). A single trailing empty field (from
# the closing '|') is kept but never indexed by a resolved column. Naive '|' split (matrices never
# embed literal pipes — same constraint as every other Speck matrix parser).
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
}

# Column indexes into ROW_CELLS, resolved from the header row by NAME (not position).
# -1 = column absent (e.g. a 6-col matrix has no Backing/Grain; a 7-col matrix has no Grain).
COL_ID=-1; COL_SRC=-1; COL_PROMISE=-1; COL_DISCHARGE=-1; COL_DEC=-1; COL_BACKING=-1; COL_GRAIN=-1; COL_STATUS=-1
COLUMNS_RESOLVED=false

resolve_columns_from_header() {
  split_row "$1"
  COL_ID=-1; COL_SRC=-1; COL_PROMISE=-1; COL_DISCHARGE=-1; COL_DEC=-1; COL_BACKING=-1; COL_GRAIN=-1; COL_STATUS=-1
  local i lc
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    lc="$(printf '%s' "${ROW_CELLS[$i]}" | tr '[:upper:]' '[:lower:]')"
    case "$lc" in
      prm-id*)     COL_ID=$i ;;
      source*)     COL_SRC=$i ;;
      promise*)    COL_PROMISE=$i ;;
      discharge*)  COL_DISCHARGE=$i ;;
      dec*)        COL_DEC=$i ;;
      backing*)    COL_BACKING=$i ;;
      grain*)      COL_GRAIN=$i ;;
      status*)     COL_STATUS=$i ;;
    esac
  done
  [[ $COL_ID -ge 0 && $COL_STATUS -ge 0 ]] && COLUMNS_RESOLVED=true
}

# Fallback for a matrix with no recognizable header row: derive columns positionally from a data
# row's real cell count (drop one trailing empty cell from the closing '|'). Mirrors the historical
# 6-vs-7-col behavior and extends it to 8 (with Grain). Unambiguous because well-formed rows end '|'.
resolve_columns_positional() {
  local n=${#ROW_CELLS[@]}
  # Drop a single trailing empty cell (from the closing pipe) to get the real column count.
  if [[ $n -gt 0 && -z "${ROW_CELLS[$((n-1))]}" ]]; then n=$((n-1)); fi
  COL_ID=0; COL_SRC=1; COL_PROMISE=2; COL_DISCHARGE=3; COL_DEC=4; COL_BACKING=-1; COL_GRAIN=-1; COL_STATUS=-1
  case "$n" in
    6) COL_STATUS=5 ;;
    7) COL_BACKING=5; COL_STATUS=6 ;;
    8) COL_BACKING=5; COL_GRAIN=6; COL_STATUS=7 ;;
    *) COL_STATUS=$((n-1)) ;;  # best-effort: last real cell is Status
  esac
  COLUMNS_RESOLVED=true
}

# Pluck a resolved column's cell from the current ROW_CELLS (empty if the column is absent).
cell_at() {
  local idx="$1"
  [[ "$idx" -ge 0 && "$idx" -lt ${#ROW_CELLS[@]} ]] && printf '%s' "${ROW_CELLS[$idx]}" || printf ''
}

# --- Fidelity check (#86, opt-in, WARN-only) -----------------------------------------------------
# Resolve the artifact a Source cell names, to an absolute path (best-effort). Empty if unknown.
resolve_source_artifact() {
  local src="$1" f
  case "$src" in
    *product-contract*)
      for f in "$EPIC_DIR/../../product-contract.md" "$EPIC_DIR/../product-contract.md" "$EPIC_DIR/product-contract.md"; do
        if [[ -f "$f" ]]; then printf '%s' "$f"; return 0; fi
      done ;;
    *epic.md*)          [[ -f "$EPIC_DIR/epic.md" ]] && printf '%s' "$EPIC_DIR/epic.md" ;;
    *wireframe*)        [[ -f "$EPIC_DIR/wireframes.md" ]] && printf '%s' "$EPIC_DIR/wireframes.md" ;;
    *experience-chain*) [[ -f "$EPIC_DIR/experience-chain.md" ]] && printf '%s' "$EPIC_DIR/experience-chain.md" ;;
  esac
  return 0
}

# Lowercase, split into salient (>3-char, stop-worded) tokens, one per line.
salient_tokens() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '\n' \
    | awk 'length($0) > 3 {
        stop["that"]=1; stop["this"]=1; stop["with"]=1; stop["from"]=1; stop["what"]=1; stop["when"]=1;
        stop["text"]=1; stop["screen"]=1; stop["element"]=1; stop["rule"]=1; stop["seam"]=1; stop["page"]=1;
        stop["their"]=1; stop["they"]=1; stop["will"]=1; stop["must"]=1; stop["into"]=1; stop["only"]=1;
        if (!($0 in stop)) print }'
}

violations=0
open_rows=0
total=0
fidelity_warnings=0
grain_warnings=0
grain_violations=0
discharged_total=0
product_grain_count=0
story_grain_count=0
grain_cap_rank=99
grain_cap_token=""

while IFS= read -r line; do
  # Header row (first cell is literally "PRM-ID") → resolve columns by name, then skip.
  if [[ "$line" =~ ^\|[[:space:]]*[Pp][Rr][Mm]-[Ii][Dd] ]]; then
    resolve_columns_from_header "$line"
    continue
  fi

  # Only data rows whose first cell is PRM-<digits>. Skips separators and prose.
  [[ "$line" =~ ^\|[[:space:]]*PRM-[0-9]+ ]] || continue

  split_row "$line"

  # No header was seen (unusual matrix) — derive columns positionally from this first data row.
  [[ "$COLUMNS_RESOLVED" == true ]] || resolve_columns_positional

  id="$(cell_at "$COL_ID")"
  src="$(cell_at "$COL_SRC")"
  promise="$(cell_at "$COL_PROMISE")"
  discharge="$(cell_at "$COL_DISCHARGE")"
  dec_cell="$(cell_at "$COL_DEC")"
  backing="$(cell_at "$COL_BACKING")"
  grain_cell="$(cell_at "$COL_GRAIN")"
  status="$(cell_at "$COL_STATUS")"
  status="$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')"

  # Skip the template's own example rows (promise still a [bracket placeholder]).
  case "$promise" in '['*']') continue ;; esac

  total=$((total + 1))

  has_discharge=false; is_empty_cell "$discharge" || has_discharge=true
  has_dec=false;       is_empty_cell "$dec_cell" || has_dec=true
  has_backing=false;   is_empty_cell "$backing" || has_backing=true

  # --- GRAIN accounting (soft, all modes) — for MATRIX_GRAIN_CAP + the surface line. -------------
  # Only discharged rows carry grain; descoped/pilot-gated are '—' by contract.
  if [[ "$status" == "discharged" ]]; then
    discharged_total=$((discharged_total + 1))
    row_grain=""
    if ! is_empty_cell "$grain_cell"; then
      row_grain="$(extract_grain "$grain_cell")"
      if [[ -z "$row_grain" ]]; then
        # Present but not a valid enum token. BLOCK at the validate gate (--require-evidence, v8.5.0);
        # surfaced-only on the fast path.
        if [[ "$REQUIRE_EVIDENCE" == true ]]; then
          echo -e "${RED}❌ $id${NC}: Grain '${grain_cell}' is not a readiness-ladder token (no-ship|impl-green|integration-green|ux-rc|api-rc|operational-rc|commercial-rc|ship-rc|ship, optional [pre-v8-proof])."
          grain_violations=$((grain_violations + 1))
        else
          echo -e "${YELLOW}⚠️  $id${NC}: Grain '${grain_cell}' is not a readiness-ladder token (no-ship|impl-green|integration-green|ux-rc|api-rc|operational-rc|commercial-rc|ship-rc|ship, optional [pre-v8-proof])."
          grain_warnings=$((grain_warnings + 1))
        fi
      fi
    fi
    # Effective grain for the CAP: an un-graded/invalid discharged row is story-grain = integration-green.
    eff_grain="$row_grain"; [[ -z "$eff_grain" ]] && eff_grain="integration-green"
    r="$(grain_rank "$eff_grain")"
    if [[ "$r" -ge 3 ]]; then product_grain_count=$((product_grain_count + 1)); else story_grain_count=$((story_grain_count + 1)); fi
    if [[ "$r" -ge 0 && "$r" -lt "$grain_cap_rank" ]]; then grain_cap_rank="$r"; grain_cap_token="$eff_grain"; fi
  fi

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
          # Parse verified state — extract the FIRST canonical token via enum (#76.3),
          # so decorated values ("UX-RC (agent-verified)") resolve correctly.
          state_line="$(grep -i "readiness_state_verified:" "$report_path" | head -n1 || true)"
          if [[ -z "$state_line" ]]; then
            state_line="$(grep -i "\*\*Verified Readiness State\**:" "$report_path" | head -n1 || true)"
          fi
          verified_state="$(extract_readiness_state "$state_line")"

          # Check if verified state is at least integration-green
          is_valid_state=false
          case "$verified_state" in
            integration-green|ux-rc|api-rc|operational-rc|commercial-rc|ship-rc|ship) is_valid_state=true ;;
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

            # --- GRAIN TEETH (BLOCK under --require-evidence as of v8.5.0) ---------------------
            row_grain="$(extract_grain "$grain_cell")"
            if [[ -n "$row_grain" ]]; then
              # Effective story state: numeric verified state, UNLESS the report's state line carries
              # a [pre-v8-proof] stamp → the /speck-reprove cap (INTEGRATION-GREEN) wins.
              eff_state="$verified_state"
              if printf '%s' "$state_line" | grep -qi "pre-v8-proof"; then
                if [[ "$(grain_rank "$verified_state")" -gt "$(grain_rank integration-green)" ]]; then
                  eff_state="integration-green"
                fi
              fi
              # Tooth 1: grain must not exceed the discharging story's effective state. (BLOCK v8.5.0)
              if [[ "$(grain_rank "$row_grain")" -gt "$(grain_rank "$eff_state")" ]]; then
                echo -e "${RED}❌ $id${NC}: Grain '${row_grain}' exceeds the discharging story's effective state '${eff_state}' — a row cannot be proven at a grain higher than its story reached."
                grain_violations=$((grain_violations + 1))
              fi
              # Tooth 2: a ≥ ux-rc (product-grain) row must cite a walk-evidence artifact. (BLOCK v8.5.0)
              if [[ "$(grain_rank "$row_grain")" -ge "$(grain_rank ux-rc)" ]]; then
                if ! grep -qiE 'evidence/|larp|screenshot|persona|walk|\.png|\.jpe?g|\.gif|\.mp4|\.webm' "$report_path"; then
                  echo -e "${RED}❌ $id${NC}: Grain '${row_grain}' is product-grain (≥ ux-rc) but the discharging report cites no walk-evidence artifact (LARP / screenshot / evidence path)."
                  grain_violations=$((grain_violations + 1))
                fi
              fi
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

  # --- FIDELITY (#86, opt-in, WARN-only — NEVER touches the conservation exit code) --------------
  if [[ "$CHECK_FIDELITY" == true ]] && ! is_empty_cell "$src" && ! is_empty_cell "$promise"; then
    artifact="$(resolve_source_artifact "$src")"
    if [[ -z "$artifact" ]]; then
      echo -e "${YELLOW}⚠️  $id${NC}: [fidelity] Source '${src}' names an artifact that could not be located near this epic — phantom or renamed source? (WARN-only)"
      fidelity_warnings=$((fidelity_warnings + 1))
    else
      # Vocabulary overlap: the Promise should share ≥2 salient tokens with the artifact's text.
      # (Presence + overlap only — this does NOT judge whether the product KEEPS the promise.)
      overlap=0
      while IFS= read -r tok; do
        [[ -z "$tok" ]] && continue
        if grep -qiw -- "$tok" "$artifact" 2>/dev/null; then overlap=$((overlap + 1)); fi
        [[ "$overlap" -ge 2 ]] && break
      done <<< "$(salient_tokens "$promise")"
      if [[ "$overlap" -lt 2 ]]; then
        echo -e "${YELLOW}⚠️  $id${NC}: [fidelity] Promise shares <2 salient tokens with its named Source ($(basename "$artifact")) — possible vocabulary drift / silent restatement. (WARN-only; presence+overlap, not faithfulness — see /audit semantic sweep.)"
        fidelity_warnings=$((fidelity_warnings + 1))
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

# --- Grain surface (always-on, #87) — split the honest claim from the read a founder makes. ------
if [[ "$discharged_total" -gt 0 ]]; then
  [[ -z "$grain_cap_token" ]] && grain_cap_token="integration-green"
  echo -e "${BLUE}📐 Grain: ${discharged_total} discharged — ${product_grain_count} at product grain (≥ ux-rc), ${story_grain_count} at story grain (< ux-rc / un-graded).${NC}"
  echo -e "${BLUE}📐 GRAIN FLOOR — this matrix can back at most: $(printf '%s' "$grain_cap_token" | tr '[:lower:]' '[:upper:]') (MIN grain over all discharged rows).${NC}"
  # Machine-readable line for /epic-validate to fold into MAX claimable = MIN(story states, cap).
  echo "MATRIX_GRAIN_CAP=${grain_cap_token}"
fi

# Grain violations BLOCK at the validate gate (--require-evidence) as of v8.5.0 — a separate,
# additive block from promise conservation above. The grain surface/floor is emitted first (it is
# informational and useful even on a failing run) before this exit.
if [[ "$grain_violations" -gt 0 ]]; then
  echo -e "${RED}❌ ${grain_violations} grain violation(s) — a discharged row is graded above its story's proven grain, cites no walk-evidence at product grain, or carries an invalid grain token.${NC}"
  echo -e "${YELLOW}Grade each discharged row at the grain its evidence was actually collected (a helper-importing unit test is impl-green, not the story's headline state). Enforced at /epic-validate as of v8.5.0 (#87).${NC}"
  exit 1
fi

if [[ "$grain_warnings" -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  ${grain_warnings} grain warning(s) — surfaced on the fast path (non-blocking); grain is ENFORCED (BLOCK) at /epic-validate via --require-evidence.${NC}"
fi
if [[ "$CHECK_FIDELITY" == true && "$fidelity_warnings" -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  ${fidelity_warnings} fidelity warning(s) — structural presence/overlap only (WARN-only), NOT a faithfulness verdict.${NC}"
fi

echo -e "${GREEN}✅ Promise conservation holds — every PRM row resolves (discharged / descoped / pilot-gated).${NC}"
echo -e "${YELLOW}   Scope: this gate verifies RESOLUTION + (under --require-evidence) grain enforcement — it does NOT check that a discharge is true. The grain floor above is the honest ceiling.${NC}"
exit 0
