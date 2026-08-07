#!/usr/bin/env bash
# validate-wave-safety.sh — wave safety & concurrency collision validator.
#
# Parses the "Epic Concurrency Waves" table in epics.md and, for every wave declared parallel,
# verifies that no two epics in it collide on:
#   1. database migrations (two authors in one wave = two Alembic heads)
#   2. shared model/service files
#   3. shared component/UI files
#
# WHY THIS PARSER WAS REWRITTEN (issue #105)
# The v7.18 parser was a green that could not see its own subject. Six defects, one shape:
#   • `[[ "$parallel_lower" == "yes" ]]` was EXACT-match, so an annotated cell — the shape the
#     shipped template itself authors — read as SERIAL. Verified: a two-row table whose row 1
#     is `Yes` and whose row 2 is `Yes (distinct surfaces; …)` carrying two real collisions
#     exited 0 with "✅ WAVE SAFETY CHECK PASSED" and never named wave 2.
#   • an all-serial epics.md left the wave array empty, and `"${arr[@]:-}"` yields ONE EMPTY
#     STRING on bash 3.2 — so `eval "epics_raw=\$wave_epics_"` aborted on `set -u`
#     ("wave_epics_: unbound variable"). Verified. The array is now length-guarded, never
#     `:-`-defaulted.
#   • the pseudo-associative array was built and read with `eval`, so an Epics cell of
#     `E002:-$(touch /tmp/PWNED)` EXECUTED during validation. Verified: the file appeared on
#     disk. The eval store is gone — parallel indexed arrays plus a linear lookup, with every
#     key validated against ^E[0-9]+$ BEFORE storage.
#   • the wave-row regex ran on EVERY line with no section state, so any pipe table whose first
#     column is an integer parsed as a wave. Verified: a "## Story Estimates" table produced a
#     hard false FAIL. Parsing is now scoped to the Concurrency Waves section.
#   • the touch-point sentinel test covered only a leading `[`, `—` and `-`, so "None", "N/A",
#     "TBD" and "zero" — the word AGENTS.md itself uses for this state — parsed as REAL
#     migration lists and fabricated collisions, while `[models/shared.py](../src/…)`, a real
#     value, was DISCARDED as a placeholder and turned a genuine collision into a green.
#   • the touch-points state re-armed on the bare substring "Touch-points" anywhere, so prose
#     after the last epic fabricated a collision. Verified.
#
# REPORTING VOCABULARY IS VALIDATOR-LOCAL BY CONSTRUCTION.
# This file mints WAVE_* codes only, and emits no SPECK_GATE_* telemetry. An all-serial
# epics.md legitimately compares zero epic pairs; a static gate reporting PREDICATES=0 is
# convicted GATE_VACUOUS.P1 by gate-liveness-probe.sh, and GATE_VACUOUS / GATE_EMPTY_LEGITIMATE
# are canary verdicts produced BY the probe ABOUT a gate — a gate self-emitting them creates two
# producers of one code. The honest-empty states therefore print plain descriptive text, and the
# summary line always carries waves-parsed and pairs-compared so a caller can tell a real green
# from a green that inspected nothing.
#
# Usage:  validate-wave-safety.sh [--strict] <epics.md | project-dir>
# Exit:   0 = no P1, 1 = collision or other P1 (P2 also fails under --strict), 2 = invocation error.
#
# The severity split preserves the pre-#105 contract: the sole caller (project-plan's SKILL.md)
# invokes bare, so a real collision must exit 1 with NO flag. --strict only escalates the P2 tier.

set -euo pipefail

# shellcheck source=../../lib/text.sh
. "$(dirname "$0")/../../lib/text.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

strict=false
[[ "${1:-}" == "--strict" ]] && { strict=true; shift; }

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "ERROR: provide an epics.md path or a project directory." >&2
  exit 2
fi

SELECTED_PROJECT=""
if [[ -d "$TARGET" ]]; then
  EPICS_MD="$TARGET/epics.md"
  if [[ ! -f "$EPICS_MD" ]]; then
    for d in "$TARGET/specs/projects/"*; do
      [[ -d "$d" ]] || continue
      if [[ -f "$d/epics.md" ]]; then
        EPICS_MD="$d/epics.md"
        # Announce the pick. A silent first-match glob over specs/projects/* is how a validator
        # reports a clean run on a DIFFERENT project than the caller meant.
        SELECTED_PROJECT="$d"
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

# The banner used to hard-code "v7.18.0" — a version label that kept printing a truthful-looking
# number for every release after the one that wrote it. Read the real VERSION instead.
speck_version() {
  local d
  d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  while [[ "$d" != "/" ]]; do
    if [[ -f "$d/.speck/VERSION" ]]; then sp_trim "$(cat "$d/.speck/VERSION")"; return 0; fi
    if [[ "$(basename "$d")" == ".speck" && -f "$d/VERSION" ]]; then sp_trim "$(cat "$d/VERSION")"; return 0; fi
    d="$(dirname "$d")"
  done
  printf 'unknown'
}

# ---------------------------------------------------------------------------------------------
# Findings
# ---------------------------------------------------------------------------------------------
p1_count=0
p2_count=0
collisions=0

emit_p1() { echo -e "  ${RED}$1${NC} $2"; p1_count=$((p1_count + 1)); }
emit_p2() { echo -e "  ${YELLOW}$1${NC} $2"; p2_count=$((p2_count + 1)); }

# ---------------------------------------------------------------------------------------------
# Cell normalisation
# ---------------------------------------------------------------------------------------------

# Emphasis markers, stripped LOCALLY. sp_strip_decoration handles quotes and backticks for three
# other validators; widening it to `*`/`_` would change what §7 terms they match, so the blast
# radius stays inside this file.
strip_emphasis() {
  local s="$1"
  s="${s//\*/}"
  s="${s//_/}"
  printf '%s' "$s"
}

# First whitespace-delimited token, without a subprocess.
first_token() {
  local -a parts=()
  read -r -a parts <<< "$1" || true
  printf '%s' "${parts[0]:-}"
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# is_placeholder <value> — 0 when the cell states "nothing here", 1 when it carries a real value.
# The v7.18 test was `!= "["* && != "—" && != "-"`, which convicted three shapes and acquitted
# five. Both directions were wrong: "None"/"none"/"N/A"/"TBD"/"zero"/"(none)"/en-dash all read as
# REAL migration lists and fabricated collisions, and a markdown link — a REAL path — read as a
# placeholder and hid one.
is_placeholder() {
  local s c
  s="$(sp_trim "$1")"
  if [[ -z "$s" ]]; then return 0; fi
  # A leading "[" is the template's placeholder bracket ONLY when it is not a markdown link.
  # `[models/shared.py](../src/models/shared.py)` is a value the author typed on purpose.
  if [[ "$s" == '['* && "$s" != *']('* ]]; then return 0; fi
  c="$(sp_strip_decoration "$s")"
  c="${c//\*/}"
  c="$(sp_trim "$c")"
  # "(none)" is the same statement as "none"; unwrap one balanced pair.
  if [[ "$c" == '('*')' ]]; then c="${c#\(}"; c="${c%\)}"; c="$(sp_trim "$c")"; fi
  c="$(lower "$c")"
  case "$c" in
    ''|'-'|'--'|'—'|'–'|'none'|'no'|'n/a'|'na'|'nil'|'nothing'|'not applicable'|'tbd'|'tba'|'tbc'|'zero'|'0')
      return 0 ;;
  esac
  return 1
}

# normalize_path_token <token> — one touch-point entry → its comparable identity.
# `tr -d ' '` (v7.18) was both a false-negative and a false-positive source: it turned
# "src/My Comp.tsx" and "src/MyComp.tsx" into the same string and reported a collision between
# two different files.
normalize_path_token() {
  local s
  s="$(sp_trim "$1")"
  # A markdown link's DISPLAY TEXT is what the author means by "the file"; the target is a path
  # relative to the doc. Resolve it before sp_strip_qualifier, which would otherwise eat the
  # target as a trailing parenthetical.
  if [[ "$s" =~ ^\[([^]]+)\]\(.*\)$ ]]; then
    s="${BASH_REMATCH[1]}"
  fi
  s="$(sp_strip_decoration "$s")"
  s="${s//\*/}"                    # bold markers; `_` is legal INSIDE a path, so it stays
  s="$(sp_strip_qualifier "$s")"   # "models/a.py (new)" → models/a.py
  s="$(sp_trim "$s")"
  s="$(lower "$s")"
  s="${s#./}"
  s="${s%.}"
  printf '%s' "$s"
}

# normalize_list <raw value> — one normalised token per line, empty output for a placeholder.
# Delimiters are "," and ";" ONLY: "/" is a path separator here, and splitting on it would shred
# every path in the file into unmatchable fragments.
normalize_list() {
  local raw="$1" tok norm
  if is_placeholder "$raw"; then return 0; fi
  while IFS= read -r tok; do
    norm="$(normalize_path_token "$tok")"
    if [[ -z "$norm" ]]; then continue; fi
    if is_placeholder "$norm"; then continue; fi
    printf '%s\n' "$norm"
  done <<< "$(sp_split_toplevel "$raw" ',;')"
}

# Intersection of two touch-point lists, one shared path per line.
check_intersection() {
  local norm_a norm_b
  norm_a="$(normalize_list "$1" | sort -u)"
  norm_b="$(normalize_list "$2" | sort -u)"
  if [[ -z "$norm_a" || -z "$norm_b" ]]; then return 0; fi
  comm -12 <(printf '%s\n' "$norm_a") <(printf '%s\n' "$norm_b") || true
}

# classify_parallel <cell> → parallel | serial | unrecognized
# Deliberately NOT a `yes*` prefix glob: that is one authoring accident away from matching
# "yes, but treat as No". Strip emphasis, drop ONE trailing parenthetical, lowercase, take the
# first token, then match a closed vocabulary.
classify_parallel() {
  local s tok
  s="$(strip_emphasis "$(sp_strip_decoration "$1")")"
  tok="$(lower "$(first_token "$(sp_strip_qualifier "$s")")")"   # the #105(a) reduction site
  case "$tok" in
    yes|y|true|✅|parallel|concurrent) printf 'parallel' ;;
    no|n|false|❌|sequential|serial|solo|not|deferred) printf 'serial' ;;
    *) printf 'unrecognized' ;;
  esac
}

# ---------------------------------------------------------------------------------------------
# Header-keyed table reading (copied shape: validate-gate-liveness.sh split_row/resolve_columns)
# ---------------------------------------------------------------------------------------------
ROW_CELLS=()
split_row() {
  local i cell
  local -a raw=()
  IFS='|' read -r -a raw <<< "$1" || true
  ROW_CELLS=()
  for (( i=1; i<${#raw[@]}; i++ )); do
    cell="$(sp_trim "${raw[$i]}")"
    ROW_CELLS+=("$cell")
  done
}

COL_WAVE=-1; COL_EPICS=-1; COL_PARALLEL=-1

resolve_columns_from_header() {
  split_row "$1"
  COL_WAVE=-1; COL_EPICS=-1; COL_PARALLEL=-1
  local i lc
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    lc="$(lower "${ROW_CELLS[$i]}")"
    case "$lc" in
      "may run in parallel"*) COL_PARALLEL=$i ;;
      wave*)                  COL_WAVE=$i ;;
      epic*)                  COL_EPICS=$i ;;
      *parallel*)             COL_PARALLEL=$i ;;
    esac
  done
  [[ $COL_WAVE -ge 0 && $COL_EPICS -ge 0 && $COL_PARALLEL -ge 0 ]]
}

# A headerless legacy wave table is Wave | Epics | May run in parallel? — the layout the v7.18
# regex hard-coded. Disclosed, not silent, and only reached when no header row resolves.
resolve_columns_positional() { COL_WAVE=0; COL_EPICS=1; COL_PARALLEL=2; }

cell_at() {
  local idx="$1"
  if [[ "$idx" -ge 0 && "$idx" -lt ${#ROW_CELLS[@]} ]]; then printf '%s' "${ROW_CELLS[$idx]}"; else printf ''; fi
}

is_separator_row() {
  local body
  body="$(printf '%s' "$1" | tr -d ' |:-')"
  [[ -z "$body" ]]
}

# ---------------------------------------------------------------------------------------------
# Epic touch-point store — parallel indexed arrays, no eval, keys validated before storage
# ---------------------------------------------------------------------------------------------
epic_keys=()
epic_migrations=()
epic_models=()
epic_files=()

epic_index() {
  local key="$1" i
  for (( i=0; i<${#epic_keys[@]}; i++ )); do
    if [[ "${epic_keys[$i]}" == "$key" ]]; then printf '%s' "$i"; return 0; fi
  done
  printf '%s' "-1"
}

# Returns through the global EPIC_IDX, NOT stdout: a `$(epic_register …)` call would run the
# array appends in a command-substitution subshell and discard every touch-point in the file.
EPIC_IDX=-1
epic_register() {
  local key="$1"
  EPIC_IDX="$(epic_index "$key")"
  if [[ "$EPIC_IDX" != "-1" ]]; then return 0; fi
  epic_keys+=("$key")
  epic_migrations+=("")
  epic_models+=("")
  epic_files+=("")
  EPIC_IDX=$(( ${#epic_keys[@]} - 1 ))
}

# ---------------------------------------------------------------------------------------------
# Parse
# ---------------------------------------------------------------------------------------------
wave_row_ids=()
wave_row_epics=()
wave_row_parallel=()

epic_header_regex='^#+[[:space:]]*([Ee][0-9]+)'
heading_regex='^(#+)[[:space:]]'
wave_heading_regex='^##+[[:space:]].*[Cc]oncurrency[[:space:]]+[Ww]aves'
# A touch-points HEADER line, not the bare substring. v7.18 re-armed on "Touch-points" appearing
# anywhere on any line, so a sentence mentioning touch-points after the last epic re-opened the
# block and attributed the next prose line to the last epic.
#
# The discriminator is the SHAPE of a header, not the bold marker. An earlier draft of this fix
# required `**`, which traded one false negative for another: a hand-written `Touch-points:` — no
# bold, which is what a human types — captured nothing, so two epics sharing a model file passed
# clean at exit 0. VERIFIED before this line was written: the identical fixture detected the
# collision with the bold header and reported PASS without it. A validator that reads only the
# shape the template happens to emit is checking its own scaffolding, not the corpus.
#
# So: line start, optional bullet, optional emphasis, the word, an optional parenthetical, and a
# colon with NOTHING after it. Prose ("Touch-points are important: they matter") carries text past
# the colon and is still rejected, which is the property the anchor was added for.
touch_points_regex='^[[:space:]]*(-[[:space:]]+)?[*_]*Touch-points[*_]*([[:space:]]*\([^)]*\))?[*_]*[[:space:]]*:[[:space:]]*$'

# Labels: `-`/`*`/`+` bullets (or none), optional bold/italic wrapper, optional space before the
# colon. v7.18 required one specific bullet glyph and no bold, so `- **Migrations**: …` — a shape
# a human writes without thinking — parsed as no migrations at all.
label_value() {
  local line="$1" label="$2" re
  re="^[[:space:]]*([-*+][[:space:]]+)?[*_]*${label}[*_]*[[:space:]]*:[[:space:]]*(.*)$"
  if [[ "$line" =~ $re ]]; then
    LABEL_VALUE="$(sp_trim "${BASH_REMATCH[2]}")"
    return 0
  fi
  return 1
}
LABEL_VALUE=""

in_fence=false
in_wave_section=false
wave_heading_level=0
in_table=false
header_resolved=false
current_epic=""
current_epic_idx=-1
in_touch_points=false
unfilled_placeholder=false
wave_section_seen=false

line=""
while IFS= read -r line || [[ -n "$line" ]]; do
  # A CRLF epics.md leaves \r on the last cell of every row, which defeats the separator-row test
  # (`|---|---|\r` is not all dashes) and promotes the separator into a wave row — inflating the
  # waves-parsed count a caller reads to judge how much was actually inspected.
  line="${line%$'\r'}"

  # Fenced code blocks hold `#` comments and `|` characters that are not headings or table rows.
  if [[ "$line" =~ ^[[:space:]]*'```' ]]; then
    if [[ "$in_fence" == true ]]; then in_fence=false; else in_fence=true; fi
    continue
  fi
  if [[ "$in_fence" == true ]]; then continue; fi

  if [[ "$line" =~ $heading_regex ]]; then
    level=${#BASH_REMATCH[1]}
    in_touch_points=false
    in_table=false
    header_resolved=false

    if [[ "$in_wave_section" == true && $level -le $wave_heading_level ]]; then
      in_wave_section=false
    fi
    if [[ "$line" =~ $wave_heading_regex ]]; then
      in_wave_section=true
      wave_section_seen=true
      wave_heading_level=$level
    fi
    if [[ "$line" =~ $epic_header_regex ]]; then
      current_epic="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')"
      epic_register "$current_epic"
      current_epic_idx="$EPIC_IDX"
    fi
    continue
  fi

  if [[ "$line" =~ ^--- ]]; then
    in_touch_points=false
    in_table=false
    header_resolved=false
    continue
  fi

  is_row=false
  if [[ "$line" =~ ^[[:space:]]*\| ]]; then is_row=true; fi

  # A table row ends a touch-points block: the bullets are prose, and the next table is a
  # different artifact entirely.
  if [[ "$is_row" == true ]]; then in_touch_points=false; fi

  if [[ "$in_touch_points" == true && -n "$current_epic" && "$current_epic_idx" != "-1" ]]; then
    if label_value "$line" "Migrations"; then
      if [[ "$LABEL_VALUE" == *'[e.g.'* ]]; then unfilled_placeholder=true; fi
      if ! is_placeholder "$LABEL_VALUE"; then epic_migrations[$current_epic_idx]="$LABEL_VALUE"; fi
    elif label_value "$line" "Models/Services"; then
      if [[ "$LABEL_VALUE" == *'[e.g.'* ]]; then unfilled_placeholder=true; fi
      if ! is_placeholder "$LABEL_VALUE"; then epic_models[$current_epic_idx]="$LABEL_VALUE"; fi
    elif label_value "$line" "Files/Components"; then
      if [[ "$LABEL_VALUE" == *'[e.g.'* ]]; then unfilled_placeholder=true; fi
      if ! is_placeholder "$LABEL_VALUE"; then epic_files[$current_epic_idx]="$LABEL_VALUE"; fi
    fi
  fi

  if [[ -n "$current_epic" && "$line" =~ $touch_points_regex ]]; then
    in_touch_points=true
    continue
  fi

  # Wave rows are read ONLY inside the Concurrency Waves section. Without this scope, every pipe
  # table in the file whose first column is an integer was a wave.
  if [[ "$in_wave_section" == true && "$is_row" == true ]]; then
    if is_separator_row "$line"; then
      in_table=true
      continue
    fi
    if [[ "$in_table" == false ]]; then
      in_table=true
      header_resolved=false
    fi
    if [[ "$header_resolved" == false ]]; then
      if resolve_columns_from_header "$line"; then
        header_resolved=true
        continue
      fi
      resolve_columns_positional
      header_resolved=true
    fi

    split_row "$line"
    wave_id="$(sp_trim "$(strip_emphasis "$(sp_strip_decoration "$(cell_at "$COL_WAVE")")")")"
    epics_cell="$(cell_at "$COL_EPICS")"
    parallel_cell="$(cell_at "$COL_PARALLEL")"
    if [[ -z "$wave_id" ]]; then continue; fi
    if [[ "$epics_cell" == *'[e.g.'* ]]; then unfilled_placeholder=true; fi

    wave_row_ids+=("$wave_id")
    wave_row_epics+=("$epics_cell")
    wave_row_parallel+=("$parallel_cell")
    continue
  fi

  # A non-row line closes the current table run, so a SECOND table in the same section resolves
  # its own header instead of inheriting the first one's column map.
  if [[ "$is_row" == true ]]; then
    in_table=true
  else
    in_table=false
    header_resolved=false
  fi
done < "$EPICS_MD"

# ---------------------------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------------------------
echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}🔍  Speck Wave Safety & Concurrency Collision Validator (v$(speck_version))${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Target epics.md: $EPICS_MD"
[[ -n "$SELECTED_PROJECT" ]] && echo -e "Project selected by directory fallback: $SELECTED_PROJECT"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

waves_parsed=${#wave_row_ids[@]}
parallel_waves=0
pairs_compared=0

if [[ "$unfilled_placeholder" == true ]]; then
  emit_p2 "WAVE_TABLE_UNFILLED.P2" "epics.md still carries the template's \`[e.g., …]\` placeholders. Every touch-point they stand in for is unknown, so a clean run here proves nothing about them."
fi

seen_wave_ids=()

if [[ $waves_parsed -gt 0 ]]; then
  for (( r=0; r<waves_parsed; r++ )); do
    wave="${wave_row_ids[$r]}"
    epics_cell="${wave_row_epics[$r]}"
    parallel_cell="${wave_row_parallel[$r]}"

    # Duplicate wave ids used to overwrite silently, erasing the FIRST row's collisions.
    dup=false
    if [[ ${#seen_wave_ids[@]} -gt 0 ]]; then
      for prev in "${seen_wave_ids[@]}"; do
        if [[ "$prev" == "$wave" ]]; then dup=true; break; fi
      done
    fi
    seen_wave_ids+=("$wave")
    if [[ "$dup" == true ]]; then
      emit_p1 "WAVE_ID_DUPLICATE.P1" "wave id \"$wave\" is declared by more than one row. Both rows are checked — a later row never replaces an earlier one — but one of the two ids is wrong."
    fi

    verdict="$(classify_parallel "$parallel_cell")"
    if [[ "$verdict" == "unrecognized" ]]; then
      # Fail toward checking: a missed parallel wave is the unrecoverable direction.
      emit_p2 "WAVE_CELL_UNRECOGNIZED.P2" "wave \"$wave\" parallel cell reads \"$parallel_cell\" — not a recognised yes/no. Treated as PARALLEL and checked."
      verdict="parallel"
    fi
    if [[ "$verdict" != "parallel" ]]; then continue; fi
    parallel_waves=$((parallel_waves + 1))

    # `and` is a word separator; sp_split_toplevel splits on CHARACTERS, so "E001 and E002"
    # would otherwise come back as one unparseable field and silently skip a real collision.
    split_cell="$epics_cell"
    split_cell="${split_cell// and /,}"
    split_cell="${split_cell// AND /,}"
    split_cell="${split_cell// And /,}"

    wave_epics=()
    while IFS= read -r raw_tok; do
      tok="$(sp_trim "$raw_tok")"
      if [[ -z "$tok" ]]; then continue; fi
      tok="$(strip_emphasis "$(sp_strip_decoration "$tok")")"
      tok="$(sp_strip_qualifier "$tok")"
      tok="$(sp_trim "$tok")"
      tok="$(printf '%s' "$tok" | tr '[:lower:]' '[:upper:]')"
      if [[ -z "$tok" ]]; then continue; fi
      # Every key is validated BEFORE it is used as one. The v7.18 store interpolated this token
      # into an `eval`, so `E002:-$(touch /tmp/PWNED)` executed instead of failing to parse.
      if [[ ! "$tok" =~ ^E[0-9]+$ ]]; then
        emit_p2 "WAVE_EPIC_UNPARSED.P2" "wave \"$wave\" lists \"$tok\", which is not an epic id (expected E###). It is not checked for collisions."
        continue
      fi
      wave_epics+=("$tok")
    done <<< "$(sp_split_toplevel "$split_cell" ',/+&;')"

    count=${#wave_epics[@]}
    if [[ $count -eq 0 ]]; then
      echo -e "Wave ${YELLOW}${wave}${NC}: declared parallel, but no epic ids parsed from \"$epics_cell\"."
      continue
    fi

    echo -e "Checking Wave ${YELLOW}${wave}${NC} (Epics: ${wave_epics[*]}):"

    # An epic with no `### E###` section resolved to "touches nothing" via `:-` defaults and
    # passed. Unknown is not safe.
    mig_authors=""
    mig_author_count=0
    for e in "${wave_epics[@]}"; do
      idx="$(epic_index "$e")"
      if [[ "$idx" == "-1" ]]; then
        emit_p2 "WAVE_EPIC_UNDEFINED.P2" "wave \"$wave\" names $e, which has no \`### $e\` section in this file — its touch-points are unknown, not proven safe."
        continue
      fi
      if [[ -n "${epic_migrations[$idx]}" ]]; then
        if [[ -z "$mig_authors" ]]; then mig_authors="$e"; else mig_authors="$mig_authors, $e"; fi
        mig_author_count=$((mig_author_count + 1))
      fi
    done

    # ONE finding per wave. The C(N,2) loop printed 3 collisions for 3 migration-authoring epics,
    # which is one condition — a single migration head with too many authors — reported 3 times,
    # and the count it printed grew quadratically with the size of the real problem.
    if [[ $mig_author_count -gt 1 ]]; then
      echo -e "  ${RED}❌ Collision (Migration head)${NC}: ${YELLOW}${mig_authors}${NC} all author database migrations in wave $wave."
      for e in "${wave_epics[@]}"; do
        idx="$(epic_index "$e")"
        if [[ "$idx" == "-1" ]]; then continue; fi
        if [[ -n "${epic_migrations[$idx]}" ]]; then echo -e "     - $e: ${epic_migrations[$idx]}"; fi
      done
      collisions=$((collisions + 1))
      p1_count=$((p1_count + 1))
    fi

    for (( i=0; i<count; i++ )); do
      for (( j=i+1; j<count; j++ )); do
        epic_a="${wave_epics[$i]}"
        epic_b="${wave_epics[$j]}"
        pairs_compared=$((pairs_compared + 1))
        idx_a="$(epic_index "$epic_a")"
        idx_b="$(epic_index "$epic_b")"
        if [[ "$idx_a" == "-1" || "$idx_b" == "-1" ]]; then continue; fi

        common_models="$(check_intersection "${epic_models[$idx_a]}" "${epic_models[$idx_b]}")"
        if [[ -n "$common_models" ]]; then
          echo -e "  ${RED}❌ Collision (Shared models/services)${NC}: ${YELLOW}$epic_a${NC} and ${YELLOW}$epic_b${NC} modify the same files:"
          printf '%s\n' "$common_models" | sed 's/^/     - /'
          collisions=$((collisions + 1))
          p1_count=$((p1_count + 1))
        fi

        common_files="$(check_intersection "${epic_files[$idx_a]}" "${epic_files[$idx_b]}")"
        if [[ -n "$common_files" ]]; then
          echo -e "  ${RED}❌ Collision (Shared files/components)${NC}: ${YELLOW}$epic_a${NC} and ${YELLOW}$epic_b${NC} modify the same files:"
          printf '%s\n' "$common_files" | sed 's/^/     - /'
          collisions=$((collisions + 1))
          p1_count=$((p1_count + 1))
        fi
      done
    done
  done
fi

echo -e "${BLUE}----------------------------------------------------------------------${NC}"

# The honest-empty states, in plain validator-local prose. Neither is a finding, and neither is
# dressed up as a green that inspected something.
if [[ "$wave_section_seen" == false ]]; then
  echo -e "No \"Concurrency Waves\" section found in $EPICS_MD — this file declares no waves, so there is no concurrency surface for this validator to check."
elif [[ $waves_parsed -eq 0 ]]; then
  echo -e "A \"Concurrency Waves\" section exists but carries no wave rows — nothing to check."
elif [[ $parallel_waves -eq 0 ]]; then
  echo -e "0 parallel waves declared — every wave is serial, so no concurrency surface to check."
fi

# EXPOSURE, not verdict. This line exists so a caller can tell a real green from a green that
# inspected nothing — so every number on it must count what was actually READ, never what was
# merely seen. `epics with touch-points` counted `${#epic_keys[@]}` until this comment was written:
# the registered `### EXXX` headers, which is a count of epics that EXIST. VERIFIED: a fixture whose
# touch-points headers the parser did not recognise captured zero values and still printed
# "epics with touch-points: 3" beside a PASS — the exposure signal reporting the verdict's
# confidence instead of its reach, which is the one thing this line was added to prevent.
epics_with_touchpoints=0
i=0
while [[ $i -lt ${#epic_keys[@]} ]]; do
  if [[ -n "${epic_migrations[$i]:-}" || -n "${epic_models[$i]:-}" || -n "${epic_files[$i]:-}" ]]; then
    epics_with_touchpoints=$((epics_with_touchpoints + 1))
  fi
  i=$((i + 1))
done
echo -e "Waves parsed: ${waves_parsed} | parallel waves: ${parallel_waves} | epic pairs compared: ${pairs_compared} | epics with parsed touch-points: ${epics_with_touchpoints}/${#epic_keys[@]}"

if [[ $collisions -gt 0 ]]; then
  echo -e "${RED}❌ WAVE SAFETY CHECK FAILED: ${collisions} collision(s) detected.${NC}"
  echo -e "${YELLOW}Epics running in the same parallel wave must not touch the same files or author migrations.${NC}"
  echo -e "${YELLOW}To resolve, either: (a) sequence them into different waves, or (b) use the 'schema-freeze foundation' pattern.${NC}"
  exit 1
fi

if [[ $p1_count -gt 0 ]]; then
  echo -e "${RED}❌ WAVE SAFETY CHECK FAILED: ${p1_count} P1 finding(s).${NC}"
  exit 1
fi

if [[ $p2_count -gt 0 ]]; then
  if [[ "$strict" == true ]]; then
    echo -e "${RED}❌ WAVE SAFETY CHECK FAILED (--strict): ${p2_count} P2 finding(s).${NC}"
    exit 1
  fi
  echo -e "${YELLOW}⚠️  WAVE SAFETY: no collision found, but ${p2_count} P2 finding(s) mean part of the surface was not proven safe.${NC}"
  exit 0
fi

# The ✅ is reserved for a run that actually compared something. Printing "collision-free" over a
# file with no parallel waves is a label claiming more than the run's status — the plain lines
# above already said what happened, and they are the conclusion in that case.
if [[ $parallel_waves -eq 0 ]]; then
  exit 0
fi

echo -e "${GREEN}✅ WAVE SAFETY CHECK PASSED: parallel waves are collision-free.${NC}"
exit 0
