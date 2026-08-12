#!/usr/bin/env bash
# validate-project-analysis.sh — Gate A for the decorrelated analysis pass (issue #106).
#
# WHY THIS EXISTS. /analyze --level project was optional at exactly the altitude where the author
# self-certifies. Field evidence, project 001-odd: a planning corpus produced through the FULL
# canonical Build flow — every skill entered, five skeptical-review primitives, a premise-challenge
# pass, every strict validator green — still carried 1 CRITICAL and 13 HIGH defects. All fourteen
# survived every inline gate and were found only by an adversarial 7-lens decorrelated pass.
# AGENTS.md P4 says the adversary is STRUCTURAL; at project-plan level it was opt-in, and the party
# opting in was the author. A rule stated in a skill cannot fail a build.
#
# TWO MODES, ONE IMPLEMENTATION PER PREDICATE.
#   structural:  validate-project-analysis.sh [--strict] <report.md>
#                Routed from validate-template.sh by filename. Handles BOTH
#                project-, epic-, and story-analysis-report.md.
#   gate:        validate-project-analysis.sh [--strict] --gate <PROJECT_DIR|EPIC_DIR>
#                The blocking prerequisite check.
#
# EXIT CONTRACT
#   structural: 0 ok · 1 structural violation UNDER --strict (matching every sibling structural
#               validator) · 2 invocation error.
#   gate:       0 clear · 1 on ANY P1 BY DEFAULT — no --strict needed, because that is what makes
#               it a gate rather than a report · 1 also on a P2 under --strict · 2 invocation error.
#
# VINTAGE BINDING — why this needs no data migration.
# The v10.3 structural requirements bind ONLY a report that DECLARES `artifact_type:
# project-analysis-report` (resp. `epic-analysis-report` / `story-analysis-report`) in its frontmatter. A report with no such
# key is pre-v10.3 vintage and is exempt. Every analysis report already on disk is exactly that, so
# none is retroactively convicted. validate-harden-report.sh is the precedent for the technique.
# The gate still SEES a pre-v10.3 report — it just reports what it can and cannot evaluate rather
# than inventing a verdict (ANALYSIS_DECORRELATION_UNVERIFIED.P2, or the grandfather exemption).
#
# WHAT THE DECORRELATION CHECK PROVES, AND WHAT IT DOES NOT.
# PROVES: (a) a lens roster was DECLARED at the width this project's tier requires — 3 lenses at
# Build-with-4+-epics, 7 at Platform; and (b) every CRITICAL/HIGH finding names a Verifier that is
# a different party from the lens that raised it.
# DOES NOT PROVE: that the reviewer was genuinely a different party. It cannot, and no check in
# this file will pretend otherwise. The obvious candidate — reading `git log --format=%an` on the
# corpus and the report and comparing authors — would be a green that reports its EXPOSURE rather
# than its VERDICT: in an agent workflow the corpus author and the analysis author carry the same
# git account, so such a check prints PASS having had nothing to catch. This repo's own frontier
# report already records that Speck's separation is "enforced by assertion, not measurement";
# nothing here overclaims past that line.
#
# THE SEVERITY MAPPING RULE IS ENFORCED, NOT DOCUMENTED (see effective_severity).
# Severity assigned at the author's discretion is severity the author can lower. 13 of the 14
# motivating defects were HIGH-or-below as authored. So the classes the shared contract calls
# CRITICAL-by-construction are RE-DERIVED here from the row's own Category cell, and a row authored
# below its rule severity is itself a structural violation. The honest limit: the Category cell is
# the control point — this rule reaches the class the author NAMED, never the meaning buried in the
# Description prose.
#
# CODES. UNANALYZED_CORPUS.P1 · ANALYSIS_STALE.P1 · ANALYSIS_CRITICAL_OPEN.P1 ·
# PROMISE_UNCOVERED.P1 · ANALYSIS_DECORRELATION_UNVERIFIED.P2 · ANALYSIS_COVERAGE_UNCOMPUTED.P2 ·
# ANALYSIS_GRANDFATHERED.P2 · FLOW_OPTIONAL_UNREVIEWED.P1 · FLOW_OPTIONAL_MISSING.P1.
# All validator-local. Deliberately NOT reused: GATE_VACUOUS /
# GATE_EMPTY_LEGITIMATE are canary-owned verdicts that gate-liveness-probe.sh produces ABOUT a gate
# from its telemetry; a gate self-emitting them would create two producers of one code — the exact
# drift v10 introduced them to prevent.
#
# Portable bash 3.2 / macOS.

set -euo pipefail

# shellcheck source=../../lib/text.sh
. "$(dirname "$0")/../../lib/text.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# EVERY FUNCTION BELOW ENDS ON AN EXPLICIT `return 0` UNLESS ITS STATUS IS THE ANSWER.
# Under `set -e` a function whose last command is a failing `[[ … ]] && …` returns 1, and the CALL
# then dies as a simple command — verified in bash 3.2.57: `f(){ [[ 1 == 2 ]] && printf hi; }; V="$(f)"`
# exits 1 and takes the validator with it. A gate that aborts mid-run prints fewer findings than it
# found, which is the one failure mode a gate must not have.

usage() {
  cat <<'USAGE'
Usage:
  validate-project-analysis.sh [--strict] <report.md>            # structural mode
  validate-project-analysis.sh [--strict] --gate <PROJECT_DIR>   # gate mode

  --strict   structural: exit 1 on a structural violation.
             gate:       ALSO exit 1 on a P2 (a P1 exits 1 with or without it).
USAGE
}

strict=false
mode="structural"
target=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict=true; shift ;;
    --gate)   mode="gate"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      if [[ -z "$target" ]]; then target="$1"; else
        echo "ERROR: duplicate argument: $1" >&2; exit 2
      fi
      shift ;;
  esac
done

[[ -n "$target" ]] || { echo "ERROR: no target given" >&2; usage >&2; exit 2; }

errors=0        # structural violations (structural mode)
p1=0            # blocking findings (gate mode)
p2=0            # advisory findings (gate mode)

log_error() {
  echo -e "${RED}ERROR:${NC} $1" >&2
  [[ -n "${2:-}" ]] && echo -e "${BLUE}Fix:${NC} $2" >&2
  echo "" >&2
  errors=$((errors + 1))
}
log_ok()     { echo -e "${GREEN}✓${NC} $1"; }
log_notice() { echo -e "${YELLOW}NOTICE:${NC} $1"; }
emit_p1()    { echo -e "${RED}$1${NC}  $2" >&2; p1=$((p1 + 1)); }
emit_p2()    { echo -e "${YELLOW}$1${NC}  $2"; p2=$((p2 + 1)); }
emit_note()  { echo -e "${BLUE}note${NC}  $1"; }

# --- markdown table primitives -------------------------------------------------------------------
# Header-keyed, never positional. A column inserted into a table's schema on its own clock silently
# re-maps every field a positional reader pulls (#103); pre-commit-hook.sh convicts that shape as
# POSITIONAL_TABLE_READ.P1. split_row / resolve_columns_from_header are copied from
# validate-gate-liveness.sh:68-107 so the ONE reference shape stays one shape.
ROW_CELLS=()
split_row() {
  local line="$1" i cell
  local -a raw=()
  IFS='|' read -r -a raw <<< "$line" || true
  ROW_CELLS=()
  for (( i=1; i<${#raw[@]}; i++ )); do
    cell="$(sp_trim "${raw[$i]}")"
    ROW_CELLS+=("$cell")
  done
  return 0
}

# Header cells are written for a human — `**Severity**`, `` `Status` ``, `⚠️ Findings`. Normalise
# the decoration away before matching a name, so a bolded header still resolves.
norm_header() {
  local s
  s="$(sp_strip_decoration "$1")"
  s="$(printf '%s' "$s" | tr -d '*')"
  s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
  sp_trim "$s"
}

COL_HEADER_NAMES=()
resolve_columns_from_header() {
  split_row "$1"
  COL_HEADER_NAMES=()
  local i
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    COL_HEADER_NAMES+=("$(norm_header "${ROW_CELLS[$i]}")")
  done
  [[ ${#COL_HEADER_NAMES[@]} -gt 0 ]]
}

# column_index <name-prefix> → index, or -1 when the table declares no such column. -1 is a fact the
# caller reports, never a position it falls back to.
column_index() {
  local key="$1" i
  for (( i=0; i<${#COL_HEADER_NAMES[@]}; i++ )); do
    case "${COL_HEADER_NAMES[$i]}" in
      $key*) printf '%s' "$i"; return 0 ;;
    esac
  done
  printf '%s' '-1'
}

cell_at() {
  local idx="$1"
  if [[ "$idx" -ge 0 && "$idx" -lt ${#ROW_CELLS[@]} ]]; then
    sp_trim "$(sp_strip_decoration "${ROW_CELLS[$idx]}")"
  fi
  return 0
}

# The pipe-table that sits directly under a heading. Stops at the NEXT heading of any level, so a
# sibling subsection's table can never be read as this one's.
section_table() {
  awk -v pat="$1" '
    !inn && $0 ~ pat { inn=1; next }
    inn && /^#/ { exit }
    inn && /^[[:space:]]*\|/ { print }
  ' <<<"$CONTENT"
}

# Data rows only: everything AFTER the |---|---| separator. Header rows, the separator itself and
# any surrounding prose are excluded (the technique validate-harden-report.sh:188-195 uses).
table_data_rows() {
  awk '
    /^[[:space:]]*\|/ {
      if ($0 ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/) { sep = 1; next }
      if (sep) print
      next
    }
    { sep = 0 }
  ' <<<"$1"
}

# The header row of a table = the first pipe row naming <key-ere>. Captured, never `| grep -q`:
# under `set -o pipefail` a pipeline reports the PRODUCER's status, so a crashed extraction and an
# empty result become indistinguishable (check-story-prereqs.sh:114-130 is the precedent).
table_header_row() {
  local tbl="$1" key="$2" hits
  hits="$(printf '%s\n' "$tbl" | grep -iE "$key" || true)"
  sp_head 1 "$hits"
}

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# --- the severity MAPPING RULE ---------------------------------------------------------------
# effective_severity <severity-cell> <category-cell>
# The shared contract fixes three classes as CRITICAL BY CONSTRUCTION, not by author judgement:
#   • a cross-artifact `contradictory` verdict (two artifacts that cannot both be satisfied — the
#     #106 motivating defect class);
#   • an unaddressed magic moment (MM-N), job (JOB-N), or differentiator pillar (DIF-N);
#   • a gate whose precondition contradicts the evidence contract.
# All three are re-derived from the Category cell here rather than trusted from the Severity cell,
# because a severity the author picks is a severity the author can lower — and 13 of the 14
# motivating defects were authored HIGH or below.
effective_severity() {
  local sev cat
  sev="$(lc "$1")"; cat="$(lc "$2")"
  case "$cat" in
    *contradict*) printf 'critical'; return 0 ;;
  esac
  case "$cat" in
    *unaddressed*|*uncovered*|*unmapped*|*orphan*)
      case "$cat" in
        # `dif-`/`differentiator`/`pillar` join the set in #108, when §3 pillars gained ids. Before
        # that they could not be here: a rule keyed on a class the contract had no id for would
        # convict on the word rather than on the promise.
        *promise*|*magic*|*job*|*mm-*|*dif-*|*differentiator*|*pillar*) printf 'critical'; return 0 ;;
      esac ;;
  esac
  case "$sev" in
    *critical*) printf 'critical' ;;
    *high*)     printf 'high' ;;
    *medium*)   printf 'medium' ;;
    *low*)      printf 'low' ;;
    *)          printf 'unknown' ;;
  esac
}

authored_severity() {
  local sev; sev="$(lc "$1")"
  case "$sev" in
    *critical*) printf 'critical' ;;
    *high*)     printf 'high' ;;
    *medium*)   printf 'medium' ;;
    *low*)      printf 'low' ;;
    *)          printf 'unknown' ;;
  esac
}

# --- status, and what counts as an escape ------------------------------------------------------
# Vocabulary: open | resolved | waived DEC-####. Anything else is NOT one of the three, so it is
# not a legitimate escape — an `unknown` status on a CRITICAL row is treated as OPEN. That is the
# safe direction: it demands an explicit resolution rather than granting one, and it closes the
# `pending` / `n/a` / blank-cell hole without minting a code nobody escalates.
DECISIONS_LOG=""
status_class() {
  local s dec
  s="$(sp_trim "$(lc "$1")")"
  if printf '%s' "$s" | grep -qE 'waived[[:space:]]+dec-[0-9]+'; then
    dec="$(printf '%s' "$s" | grep -oE 'dec-[0-9]+' | tr '[:lower:]' '[:upper:]' || true)"
    dec="$(sp_head 1 "$dec")"
    # A waiver is an escape only if the decision it cites exists. When the project keeps no
    # decisions log there is nothing to check against, so the waiver stands and the caller says it
    # could not be verified — unknown, never a silent pass (gate-liveness's waiver precedent).
    if [[ -n "$DECISIONS_LOG" && -f "$DECISIONS_LOG" ]]; then
      if grep -qF "$dec" "$DECISIONS_LOG" 2>/dev/null; then printf 'waived'; else printf 'waived-unbacked'; fi
    else
      printf 'waived-unverifiable'
    fi
    return 0
  fi
  case "$s" in
    resolved*|closed*|fixed*) printf 'resolved' ;;
    open*|reopened*)          printf 'open' ;;
    *)                        printf 'unknown' ;;
  esac
}

# Does this status leave the finding live? `waived-unbacked` does: a waiver citing a decision the
# log does not contain is a claim, not a waiver.
status_is_live() {
  case "$1" in
    resolved|waived|waived-unverifiable) return 1 ;;
    *) return 0 ;;
  esac
}

# --- report loading ----------------------------------------------------------------------------
CONTENT=""; FRONTMATTER=""; ARTIFACT_TYPE=""; BOUND=false

load_report() {
  local f="$1"
  CONTENT="$(cat "$f")"
  # Frontmatter only (the first `---` block), so a report that merely QUOTES `artifact_type:` in
  # prose cannot opt itself in or out.
  FRONTMATTER="$(awk 'NR==1 && $0 ~ /^---[[:space:]]*$/ {inf=1; next} inf && $0 ~ /^---[[:space:]]*$/ {exit} inf {print}' "$f")"
  ARTIFACT_TYPE="$(fm_value 'artifact_type')"
  BOUND=false
  case "$ARTIFACT_TYPE" in
    project-analysis-report|epic-analysis-report|story-analysis-report) BOUND=true ;;
  esac
  return 0
}

fm_value() {
  local key="$1" line
  line="$(grep -E "^[[:space:]]*${key}:" <<<"$FRONTMATTER" || true)"
  line="$(sp_head 1 "$line")"
  line="${line#*:}"
  line="$(sp_trim "$line")"
  line="${line%\"}"; line="${line#\"}"
  line="${line%\'}"; line="${line#\'}"
  printf '%s' "$line"
}

# is_v11_report <report-file> <scope-dir>
# v11-ness decides whether the Flow Fit contract applies. The ORIGINAL defect was that a report
# could duck the whole contract by simply typing an old speck_version, and nothing said a word.
#
# The fix is NOT to override the report's claim from live truth. "Which tooling produced this
# report" is a fact about the past, and every mechanism for recovering it (git ancestry, file
# mtime) is absent in ordinary workspaces — squashed history, gitignored specs/, an uncommitted
# edit, a repo initialised after adoption — so any such rule retroactively convicts genuinely
# vintage reports, which VINTAGE BINDING (above) promises never happens.
#
# So the claim is still honoured, and the dodge is made VISIBLE instead: a report claiming a
# version below the workspace's own tooling raises ANALYSIS_VINTAGE_UNVERIFIED.P2 at the gate
# (see the caller), which --strict escalates. Silence was the bug; a wrong conviction is not the
# cure. Inability to verify is a finding, never a silent pass and never a silent conviction
# (AGENTS.md P3).
is_v11_report() {
  local v major
  v="$(fm_value 'speck_version')"
  major="${v%%.*}"
  [[ "$major" =~ ^[0-9]+$ && "$major" -ge 11 ]]
}

# report_claims_stale_vintage <scope-dir> — true when the report claims a pre-v11 version while
# the workspace's own tooling is v11+. Not a conviction on its own; the caller raises a P2.
report_claims_stale_vintage() {
  local scope="${1:-}" root live live_major v major
  root="$([[ -n "$scope" ]] && speck_root "$scope" || true)"
  [[ -n "$root" && -f "$root/.speck/VERSION" ]] || return 1
  live="$(tr -d '[:space:]' < "$root/.speck/VERSION" 2>/dev/null || true)"
  live_major="${live%%.*}"
  [[ "$live_major" =~ ^[0-9]+$ && "$live_major" -ge 11 ]] || return 1
  v="$(fm_value 'speck_version')"
  major="${v%%.*}"
  [[ "$major" =~ ^[0-9]+$ ]] || return 1
  [[ "$major" -lt 11 ]]
}
flow_slots() {
  case "$1" in
    project|project-analysis-report)
      printf '%s\n' project-import speck-scan-project project-brainstorm project-domain project-ux project-constitution project-architecture project-design-system ;;
    epic|epic-analysis-report)
      printf '%s\n' epic-discover epic-constitution epic-architecture epic-journey epic-wireframes epic-experience-chain ;;
    story|story-analysis-report)
      printf '%s\n' story-extract speck-scan story-ui-spec ;;
  esac
  return 0
}

flow_row_for_slot() { # <rows> <slot-column-index> <exact-slot>
  local rows="$1" slot_index="$2" wanted="$3" candidate actual
  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    split_row "$candidate"
    actual="$(lc "$(cell_at "$slot_index")")"
    if [[ "$actual" == "$wanted" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done <<< "$rows"
  return 1
}

flow_cell_is_substantive() { # reject blank/sentinel/template cells masquerading as adjudication
  local value lower
  value="$(sp_trim "$1")"; lower="$(lc "$value")"
  [[ -n "$value" ]] || return 1
  case "$lower" in
    -|—|–|n/a|na|none|tbd|unknown) return 1 ;;
  esac
  case "$value" in
    \[*\]) return 1 ;;
  esac
  return 0
}

# flow_artifact_keyword <slot> → an ERE fragment the artifact's basename must contain (case-
# insensitive) before its existence is even checked. Canonical filenames come from each skill's own
# SKILL.md "Output:" line (ux-strategy.md, architecture.md, design-system.md, constitution.md,
# domain-model.md, user-journey.md, wireframes.md, experience-chain.md, ui-spec.md). Slots with no
# single fixed deliverable — discovery/scan/extract steps, whose output name varies by topic — key on
# their own verb instead, so a genuinely-produced artifact still resolves while an incidental mention
# elsewhere in the sentence does not. Without this filter, ANY existing .md token in the cell
# resolved (FLOW_INCLUDED_PHANTOM.P1's whole reason to exist), which is what let a rationale merely
# mentioning an unrelated, real filename discharge the check for a step that never ran.
#
# TWO SLOTS DELIBERATELY DO NOT KEY ON A GUARANTEED-TO-EXIST FILENAME. epic-discover's own SKILL.md
# names its output `epic.md` — but epic-specify writes the SAME filename, so `epic.md`'s mere presence
# in an epic dir (true of every epic, discovered or not) is not evidence discovery ran; the keyword is
# `discover` alone, so a bare "epic.md" mention can no longer stand in. story-extract's SKILL.md names
# two outputs, `spec.md` and `codebase-scan-extracted.md` — but story-specify ALSO writes spec.md, so
# only the extract-unique artifact counts; `spec.md` was dropped from the alternation for the same
# reason. Both previously let "the filename exists" trivially pass for a step that never ran, because
# the filename it matched was one every story/epic already carries regardless.
flow_artifact_keyword() {
  case "$1" in
    project-import)        printf 'import|landscape-overview' ;;
    speck-scan-project)    printf 'scan|landscape-overview' ;;
    project-brainstorm)    printf 'brainstorm' ;;
    project-domain)        printf 'domain' ;;
    project-ux)            printf 'ux-strategy' ;;
    project-constitution)  printf 'constitution' ;;
    project-architecture)  printf 'architecture' ;;
    project-design-system) printf 'design-system|primitives' ;;
    epic-discover)         printf 'discover' ;;
    epic-constitution)     printf 'constitution' ;;
    epic-architecture)     printf 'architecture' ;;
    epic-journey)          printf 'journey' ;;
    epic-wireframes)       printf 'wireframe' ;;
    epic-experience-chain) printf 'experience-chain' ;;
    story-extract)         printf 'extract|codebase-scan' ;;
    speck-scan)            printf 'scan' ;;
    story-ui-spec)         printf 'ui-spec' ;;
    *)                     printf '%s' "$(lc "$1")" ;;
  esac
  return 0
}

# flow_artifact_exists <artifact-cell> <analysis-scope-dir> <slot>
# The scope directory ONLY — never the project root, never the repo root. Every slot's own SKILL.md
# writes its output into the directory the step ran AT (an epic step into its own epic dir, a story
# step into its own story dir; see flow_artifact_keyword above), so that directory is the entire
# search space. Widening the search to $project or $root let a SAME-NAMED artifact from a DIFFERENT
# altitude discharge a claim it never earned — a project-wide constitution.md satisfying "included"
# for epic-constitution with nothing epic-specific on disk. "A filename in the report is not evidence
# that the step ran" has to mean the step ran HERE, not merely that the name exists somewhere in the
# tree.
flow_artifact_exists() {
  local artifact="$1" scope="$2" slot="$3" token keyword candidate project
  keyword="$(flow_artifact_keyword "$slot")"
  project="$scope"
  case "$scope" in */epics/*) project="${scope%%/epics/*}" ;; esac
  while IFS= read -r token; do
    [[ -n "$token" ]] || continue
    # The token must NAME this slot's own artifact. A filename that merely exists somewhere in the
    # tree is not evidence THIS step ran — binding it to the slot is the entire point of the check.
    printf '%s' "$(lc "$(basename "$token")")" | grep -qE "$keyword" || continue
    # Confine every candidate to the scope directory. An absolute path, or a relative one
    # walking out through `..`, would otherwise reach a same-named artifact at another
    # altitude and discharge a claim this step never earned — the exact bypass the
    # scope-only rule above exists to prevent.
    # Confine every candidate to the scope directory, but accept the spellings the template
    # actually invites ("[path or rationale]"): a bare filename, a path relative to the project
    # root, or an absolute path. Whichever spelling is used, the file it names has to LAND inside
    # the scope dir — otherwise a same-named artifact at another altitude would discharge a claim
    # this step never earned. Confinement is a property of the resolved path, not of the spelling.
    case "$token" in
      */../*|*/..|../*|..) continue ;;
      /*)  candidate="$token" ;;
      *)   if [[ -f "$scope/$token" ]]; then
             candidate="$scope/$token"
           else
             candidate="$project/$token"
           fi ;;
    esac
    [[ "$candidate" == "$scope"/* ]] || continue
    [[ -f "$candidate" ]] && return 0
  done <<< "$(printf '%s' "$artifact" | grep -oE '[A-Za-z0-9_./-]+\.md' || true)"
  return 1
}

# Count of declared lenses. Both the block form (`  - id: L3`) and a bare list (`  - L3`) count;
# an inline `lenses: [a, b, c]` counts its comma-separated items.
lens_declared_count() {
  local inline n
  inline="$(fm_value 'lenses')"
  if [[ -n "$inline" && "$inline" == \[*\]* ]]; then
    n="$(printf '%s' "${inline#[}" | tr ',' '\n' | grep -c '[A-Za-z0-9]' || true)"
    printf '%s' "${n:-0}"; return 0
  fi
  awk '
    /^lenses:[[:space:]]*$/ { inl=1; next }
    inl && /^[^[:space:]#-]/ { inl=0 }
    inl && /^[[:space:]]*-[[:space:]]*/ { if ($0 ~ /id:/ || $0 !~ /:/) n++ }
    END { print n+0 }
  ' <<<"$FRONTMATTER"
}

# ==================================================================================================
# STRUCTURAL MODE
# ==================================================================================================
ISSUES_TABLE=""; ISSUES_HEADER=""
ROSTER_TABLE=""; ROSTER_HEADER=""
COVERAGE_TABLE=""; COVERAGE_HEADER=""
FLOW_TABLE=""; FLOW_HEADER=""

load_tables() {
  ISSUES_TABLE="$(section_table '^#+[[:space:]].*Issues Found')"
  ISSUES_HEADER="$(table_header_row "$ISSUES_TABLE" '\|[[:space:]]*\**[[:space:]]*Severity[[:space:]]*\**[[:space:]]*\|')"
  ROSTER_TABLE="$(section_table '^#+[[:space:]].*Lens Roster')"
  ROSTER_HEADER="$(table_header_row "$ROSTER_TABLE" '\|[[:space:]]*\**[[:space:]]*Lens[[:space:]]*\**[[:space:]]*\|')"
  COVERAGE_TABLE="$(section_table '^#+[[:space:]].*Promise Coverage')"
  COVERAGE_HEADER="$(table_header_row "$COVERAGE_TABLE" '\|[[:space:]]*\**[[:space:]]*Promise dimension')"
  FLOW_TABLE="$(section_table '^#+[[:space:]].*Flow Fit')"
  FLOW_HEADER="$(table_header_row "$FLOW_TABLE" '\|[[:space:]]*\**[[:space:]]*Slot[[:space:]]*\**[[:space:]]*\|')"
  return 0
}

flow_fit_structural_check() { # <report-file> <scope-dir>
  local report_file="$1" scope="$2"
  is_v11_report "$report_file" "$scope" || return 0
  if [[ -z "$FLOW_HEADER" ]]; then
    log_error "the Flow Fit table has no resolvable header row" \
      "Use: Slot | Trigger evidence | Artifact or rationale | Verdict. Every reached optional slot must be adjudicated."
    return 0
  fi
  resolve_columns_from_header "$FLOW_HEADER" || true
  local c_slot c_trigger c_artifact c_verdict
  c_slot="$(column_index 'slot')"; c_trigger="$(column_index 'trigger evidence')"
  c_artifact="$(column_index 'artifact or rationale')"; c_verdict="$(column_index 'verdict')"
  if [[ "$c_slot" -lt 0 || "$c_trigger" -lt 0 || "$c_artifact" -lt 0 || "$c_verdict" -lt 0 ]]; then
    log_error "the Flow Fit table is missing a required column" \
      "Required: Slot | Trigger evidence | Artifact or rationale | Verdict."
    return 0
  fi
  local rows slot row verdict trigger artifact missing="" invalid="" weak="" phantom=""
  rows="$(table_data_rows "$FLOW_TABLE")"
  while IFS= read -r slot; do
    row="$(flow_row_for_slot "$rows" "$c_slot" "$slot" || true)"
    if [[ -z "$row" ]]; then missing="$missing $slot"; continue; fi
    split_row "$row"
    verdict="$(lc "$(cell_at "$c_verdict")")"
    trigger="$(cell_at "$c_trigger")"; artifact="$(cell_at "$c_artifact")"
    case "$verdict" in included|not-applicable|missing) : ;; *) invalid="$invalid $slot('${verdict:-empty}')" ;; esac
    if ! flow_cell_is_substantive "$trigger" || ! flow_cell_is_substantive "$artifact"; then
      weak="$weak $slot"
    fi
    if [[ "$verdict" == included ]] && ! flow_artifact_exists "$artifact" "$scope" "$slot"; then
      phantom="$phantom $slot"
    fi
  done <<< "$(flow_slots "$ARTIFACT_TYPE")"
  [[ -z "$missing" ]] || log_error "Flow Fit omits required slot(s):$missing" \
    "Review every conditional slot; absence is not an implicit not-applicable verdict."
  [[ -z "$invalid" ]] || log_error "Flow Fit uses an invalid verdict:$invalid" \
    "Verdict vocabulary is included | not-applicable | missing."
  [[ -z "$weak" ]] || log_error "Flow Fit lacks substantive trigger evidence or artifact/rationale for:$weak" \
    "Replace blank, sentinel, or template cells with the observed trigger and a concrete artifact path or not-applicable rationale."
  [[ -z "$phantom" ]] || log_error "Flow Fit claims included artifact(s) that do not exist:$phantom" \
    "Point each included row at a checked-in Markdown artifact reachable from the analysis scope."
  [[ -n "$missing$invalid$weak$phantom" ]] || log_ok "Flow Fit adjudicates every conditional $ARTIFACT_TYPE slot"
  return 0
}

flow_fit_gate_check() { # <level> <play> <epics> <scope-dir> <report-file>
  local level="$1" play="${2:-}" epics="${3:-0}" scope="$4" report_file="${5:-}"
  is_v11_report "$report_file" "$scope" || return 0
  if [[ -z "$FLOW_HEADER" ]]; then
    emit_p1 "FLOW_OPTIONAL_UNREVIEWED.P1" "the v11 report has no readable Flow Fit table. Optional flow steps were not adjudicated, so absence cannot be distinguished from deliberate omission."
    return 0
  fi
  resolve_columns_from_header "$FLOW_HEADER" || true
  local c_slot c_trigger c_artifact c_verdict rows slot row verdict trigger artifact omitted="" missing="" weak="" phantom="" required_missing=""
  c_slot="$(column_index 'slot')"; c_trigger="$(column_index 'trigger evidence')"
  c_artifact="$(column_index 'artifact or rationale')"; c_verdict="$(column_index 'verdict')"
  if [[ "$c_slot" -lt 0 || "$c_trigger" -lt 0 || "$c_artifact" -lt 0 || "$c_verdict" -lt 0 ]]; then
    emit_p1 "FLOW_OPTIONAL_UNREVIEWED.P1" "the Flow Fit table lacks a required Slot, Trigger evidence, Artifact or rationale, or Verdict column, so conditional flow coverage cannot be read."
    return 0
  fi
  rows="$(table_data_rows "$FLOW_TABLE")"
  while IFS= read -r slot; do
    row="$(flow_row_for_slot "$rows" "$c_slot" "$slot" || true)"
    if [[ -z "$row" ]]; then omitted="$omitted $slot"; continue; fi
    split_row "$row"
    verdict="$(lc "$(cell_at "$c_verdict")")"
    trigger="$(cell_at "$c_trigger")"; artifact="$(cell_at "$c_artifact")"
    case "$verdict" in
      missing) missing="$missing $slot" ;;
      included|not-applicable) : ;;
      *) omitted="$omitted $slot(unreadable:'${verdict:-empty}')" ;;
    esac
    if ! flow_cell_is_substantive "$trigger" || ! flow_cell_is_substantive "$artifact"; then
      weak="$weak $slot"
    fi
    if [[ "$verdict" == included ]] && ! flow_artifact_exists "$artifact" "$scope" "$slot"; then
      phantom="$phantom $slot"
    fi
  done <<< "$(flow_slots "$level")"
  if [[ "$level" == project ]]; then
    local required_slots=""
    if [[ "$(lc "$play")" == platform ]]; then
      required_slots="project-ux project-constitution project-architecture"
    elif [[ "$(lc "$play")" == build && "$epics" =~ ^[0-9]+$ && "$epics" -ge 4 ]]; then
      required_slots="project-ux project-architecture"
    fi
    for slot in $required_slots; do
      row="$(flow_row_for_slot "$rows" "$c_slot" "$slot" || true)"
      [[ -n "$row" ]] || continue
      split_row "$row"; verdict="$(lc "$(cell_at "$c_verdict")")"
      [[ "$verdict" == included ]] || required_missing="$required_missing $slot"
    done
  fi
  [[ -z "$omitted" ]] || emit_p1 "FLOW_OPTIONAL_UNREVIEWED.P1" "conditional slot(s) were not adjudicated:$omitted."
  [[ -z "$weak" ]] || emit_p1 "FLOW_OPTIONAL_UNREVIEWED.P1" "conditional slot(s) lack substantive trigger evidence or artifact/rationale:$weak."
  [[ -z "$phantom" ]] || emit_p1 "FLOW_INCLUDED_PHANTOM.P1" "conditional slot(s) claim included artifacts that do not exist:$phantom. A filename in the report is not evidence that the step ran."
  [[ -z "$missing" ]] || emit_p1 "FLOW_OPTIONAL_MISSING.P1" "applicable conditional work is missing:$missing. Complete it or change the triggering decision before downstream execution."
  [[ -z "$required_missing" ]] || emit_p1 "FLOW_REQUIRED_MISSING.P1" "the selected play level requires these flow slots to be included:$required_missing. A not-applicable verdict cannot waive a mandatory foundation step."
  [[ -n "$omitted$weak$phantom$missing$required_missing" ]] || emit_note "flow fit: every conditional $level slot was adjudicated and none is missing."
  return 0
}

# The one gate verdict the report declares. Exactly one token of the fixed vocabulary must parse
# out of the line: a line that lists all three (the template's own legend) has declared nothing.
gate_verdict() {
  local line hits n
  line="$(grep -E '\*\*Gate verdict\*\*[[:space:]]*:' <<<"$CONTENT" || true)"
  line="$(sp_head 1 "$line")"
  [[ -z "$line" ]] && { printf 'MISSING'; return 0; }
  hits="$(grep -oE '(BLOCKED|NEEDS_FIXES|CLEAN)' <<<"$line" || true)"
  n="$(printf '%s\n' "$hits" | grep -c '[A-Z]' || true)"
  if [[ "${n:-0}" -eq 1 ]]; then sp_trim "$hits"; else printf 'AMBIGUOUS'; fi
}

structural_mode() {
  local f="$1" scope_dir
  [[ -f "$f" ]] || { echo "ERROR: file not found: $f" >&2; exit 2; }
  scope_dir="$(cd "$(dirname "$f")" && pwd)"
  DECISIONS_LOG="$(resolve_decisions_log "$scope_dir")"
  load_report "$f"

  if [[ "$BOUND" == false ]]; then
    log_notice "pre-v10.3 analysis report (no bound project/epic/story artifact_type in the frontmatter) — current lens-roster, findings-table and gate-verdict requirements are not required of it. Re-run /analyze at the applicable level to opt in; no migration touches this file."
    echo -e "${GREEN}Validation PASSED.${NC}"
    exit 0
  fi

  log_ok "v10.3-vintage analysis report: artifact_type: $ARTIFACT_TYPE"

  local sv sha lenses
  sv="$(fm_value 'speck_version')"
  [[ -n "$sv" ]] || log_error "frontmatter is missing 'speck_version'" \
    "Add the version the analysis ran under, e.g. 'speck_version: 10.3.0'."
  sha="$(fm_value 'analyzed_sha')"
  if [[ -z "$sha" ]]; then
    log_error "frontmatter is missing 'analyzed_sha'" \
      "Stamp the full 40-character SHA of HEAD when the analysis ran. Outside git, write 'unknown' — an honest unknown, never a blank that reads as 'someone checked'."
  elif ! printf '%s' "$sha" | grep -qE '^([0-9a-fA-F]{40}|unknown)$'; then
    log_error "'analyzed_sha: $sha' is neither a full 40-character SHA nor the literal 'unknown'" \
      "A short SHA cannot be compared for ancestry across a repo that later grows an ambiguous prefix. Use 'git rev-parse HEAD', or 'unknown' outside a repository."
  fi
  lenses="$(lens_declared_count)"
  if [[ "${lenses:-0}" -lt 1 ]]; then
    log_error "frontmatter declares no 'lenses:' — the roster is the decorrelation claim" \
      "List one entry per lens with id / name / reviewer / authored_corpus, e.g. '- id: L3\\n  name: promise-coverage\\n  reviewer: <agent type>\\n  authored_corpus: false'."
  else
    log_ok "frontmatter declares $lenses lens/lenses"
  fi

  load_tables

  # --- required sections ---
  local sec
  for sec in 'Lens Roster' 'Issues Found' 'Promise Coverage'; do
    if grep -qE "^#+[[:space:]].*$sec" <<<"$CONTENT"; then
      log_ok "section present: $sec"
    else
      log_error "Missing required section: $sec" \
        "Regenerate from the selected project, epic, or story analysis template — do not hand-write around the structure."
    fi
  done
  if is_v11_report "$f" "$scope_dir"; then
    if grep -qE '^#+[[:space:]].*Flow Fit' <<<"$CONTENT"; then
      log_ok "section present: Flow Fit"
    else
      log_error "Missing required section: Flow Fit" \
        "v11 analysis must adjudicate each conditional step before downstream work."
    fi
    flow_fit_structural_check "$f" "$scope_dir"
  fi

  # --- Lens Roster columns, BY HEADER NAME ---
  if [[ -z "$ROSTER_HEADER" ]]; then
    log_error "the Lens Roster has no resolvable header row" \
      "The roster's header is 'Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings'. Columns are resolved by NAME, so the header row is the contract."
  else
    resolve_columns_from_header "$ROSTER_HEADER" || true
    local k
    for k in 'lens' 'hostile question' 'reviewer' 'authored' 'findings'; do
      if [[ "$(column_index "$k")" -lt 0 ]]; then
        log_error "the Lens Roster declares no '$k' column" \
          "Required columns: Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings."
      fi
    done
  fi

  # --- Issues Found columns, BY HEADER NAME ---
  local have_issue_cols=false
  if [[ -z "$ISSUES_HEADER" ]]; then
    log_error "the Issues Found table has no resolvable header row" \
      "The header is 'ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status'. Without it the CRITICAL-open gate predicate has nothing to read."
  else
    resolve_columns_from_header "$ISSUES_HEADER" || true
    have_issue_cols=true
    for k in 'id' 'category' 'severity' 'description' 'recommendation' 'verifier' 'verdict' 'status'; do
      if [[ "$(column_index "$k")" -lt 0 ]]; then
        log_error "the Issues Found table declares no '$k' column" \
          "Required columns: ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status."
        have_issue_cols=false
      fi
    done
  fi

  # --- Promise Coverage columns, BY HEADER NAME ---
  if [[ -z "$COVERAGE_HEADER" ]]; then
    log_error "the Promise Coverage matrix has no resolvable header row" \
      "The header is 'Promise dimension | Source | Epic / story coverage | Status'."
  else
    resolve_columns_from_header "$COVERAGE_HEADER" || true
    for k in 'promise dimension' 'source' 'epic' 'status'; do
      if [[ "$(column_index "$k")" -lt 0 ]]; then
        log_error "the Promise Coverage matrix declares no '$k' column" \
          "Required columns: Promise dimension | Source | Epic / story coverage | Status."
      fi
    done
  fi

  # --- findings rows: vocabularies, the mapping rule, and the open-CRITICAL set ---
  local open_critical=0
  if [[ "$have_issue_cols" == true ]]; then
    resolve_columns_from_header "$ISSUES_HEADER" || true
    local c_id c_cat c_sev c_ver c_verd c_stat
    c_id="$(column_index 'id')";       c_cat="$(column_index 'category')"
    c_sev="$(column_index 'severity')"; c_ver="$(column_index 'verifier')"
    c_verd="$(column_index 'verdict')"; c_stat="$(column_index 'status')"
    local row fid fcat fsev fverd fstat eff auth sclass
    while IFS= read -r row; do
      [[ -z "${row//[[:space:]]/}" ]] && continue
      split_row "$row"
      fid="$(cell_at "$c_id")"; fcat="$(cell_at "$c_cat")"; fsev="$(cell_at "$c_sev")"
      fverd="$(cell_at "$c_verd")"; fstat="$(cell_at "$c_stat")"
      [[ -z "$fid" ]] && continue
      eff="$(effective_severity "$fsev" "$fcat")"
      auth="$(authored_severity "$fsev")"
      if [[ "$auth" == unknown ]]; then
        log_error "finding $fid carries no recognised Severity ('$fsev')" \
          "Severity vocabulary is fixed: CRITICAL | HIGH | MEDIUM | LOW."
      fi
      if [[ "$eff" == critical && "$auth" != critical ]]; then
        log_error "finding $fid is CRITICAL BY RULE (Category '$fcat') but is authored as '${fsev:-empty}'" \
          "Severity is assigned by rule, not at the author's discretion: a cross-artifact contradiction, an unaddressed MM-N/JOB-N/DIF-N, and a gate precondition that contradicts the evidence contract are CRITICAL by construction. Raise the cell, or rename the class if that is not what this finding is."
      fi
      case "$(lc "$fverd")" in
        confirmed|refuted) : ;;
        '') log_error "finding $fid carries no adversarial Verdict" \
              "Per-finding Verdict vocabulary is fixed: confirmed | refuted. A finding nobody adjudicated is surrogate proof, never a pass (AGENTS.md P1)." ;;
        *)  log_error "finding $fid has Verdict '$fverd', which is not in the fixed vocabulary" \
              "Per-finding Verdict vocabulary is fixed: confirmed | refuted." ;;
      esac
      sclass="$(status_class "$fstat")"
      case "$sclass" in
        open|resolved|waived|waived-unverifiable) : ;;
        waived-unbacked)
          log_error "finding $fid is waived against a decision that project-decisions-log.md does not contain ('$fstat')" \
            "A waiver citing a DEC the log does not carry is a claim, not a waiver. Log the decision (see /speck-decision-log) or reopen the finding." ;;
        *)
          log_error "finding $fid has Status '$fstat', which is not in the fixed vocabulary" \
            "Status vocabulary is fixed: open | resolved | waived DEC-####." ;;
      esac
      if [[ "$eff" == critical ]] && status_is_live "$sclass"; then
        open_critical=$((open_critical + 1))
      fi
    done <<< "$(table_data_rows "$ISSUES_TABLE")"
  fi

  # --- the gate verdict, and its consistency with the report's OWN findings ---
  local verdict
  verdict="$(gate_verdict)"
  case "$verdict" in
    BLOCKED|NEEDS_FIXES|CLEAN)
      log_ok "gate verdict declared: $verdict" ;;
    MISSING)
      log_error "no '**Gate verdict**:' line" \
        "Every analysis report ends in exactly one of: **Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN." ;;
    *)
      log_error "the '**Gate verdict**:' line does not parse to exactly one verdict" \
        "Write one of BLOCKED, NEEDS_FIXES or CLEAN — a line that lists all three (the template's legend) has declared nothing." ;;
  esac

  # A report cannot self-certify past its own open CRITICAL. This is the #106 shape in miniature:
  # the author is both the party who assigned the severity and the party who signed the verdict.
  if [[ "$verdict" == "CLEAN" && "$open_critical" -gt 0 ]]; then
    log_error "the report declares 'Gate verdict: CLEAN' while carrying $open_critical CRITICAL finding(s) with a live Status" \
      "CLEAN means no open CRITICAL. Resolve the finding, waive it against a logged DEC, or lower the verdict to NEEDS_FIXES/BLOCKED. The verdict does not get to overrule the table above it."
  fi

  if [[ "$errors" -gt 0 ]]; then
    if [[ "$strict" == true ]]; then
      echo -e "${RED}Validation FAILED with $errors error(s).${NC}" >&2
      exit 1
    fi
    echo -e "${YELLOW}Validation completed with $errors error(s) (ignored without --strict).${NC}"
  fi
  echo -e "${GREEN}Validation PASSED.${NC}"
  exit 0
}

# ==================================================================================================
# GATE MODE
# ==================================================================================================
resolve_decisions_log() {
  local d="$1" p
  if [[ -f "$d/project-decisions-log.md" ]]; then printf '%s' "$d/project-decisions-log.md"; return 0; fi
  case "$d" in
    */epics/*)
      p="${d%%/epics/*}"
      if [[ -f "$p/project-decisions-log.md" ]]; then printf '%s' "$p/project-decisions-log.md"; fi ;;
  esac
  return 0
}

speck_root() {
  local cur; cur="$(cd "$1" && pwd)"
  while [[ "$cur" != "/" ]]; do
    if [[ -d "$cur/.speck" || -d "$cur/.git" ]]; then printf '%s' "$cur"; return 0; fi
    cur="$(dirname "$cur")"
  done
  return 0
}

# The tier that decides whether this gate applies at all, and how wide the roster must be.
# 3 lenses at Build-with-4+-epics, 7 at Platform. Below that the mandate does not exist —
# AGENTS.md:37's anti-bloat rule is explicit that a gap is installed as a principle, not appended as
# another universal checklist item, and a 2-epic Build does not have the cross-artifact surface the
# 7-lens pass exists to search.
required_lens_count() {
  local play="$1" epics="$2" level="${3:-project}"
  if [[ "$level" == "story" ]]; then
    case "$(lc "$play")" in
      platform) printf '3'; return 0 ;;
      build)    printf '1'; return 0 ;;
    esac
    printf '0'; return 0
  fi
  if [[ "$level" == "epic" ]]; then
    case "$(lc "$play")" in
      platform) printf '7'; return 0 ;;
      build)    printf '1'; return 0 ;;
    esac
    printf '0'; return 0
  fi
  case "$(lc "$play")" in
    platform) printf '7'; return 0 ;;
    build)    if [[ "${epics:-0}" -ge 4 ]]; then printf '3'; else printf '0'; fi; return 0 ;;
  esac
  printf '0'
}

# THE MAX OF BOTH SOURCES, never the first one that answers.
#
# This function decided whether the whole #106 gate applies, and an earlier draft returned the
# `epics/` directory count whenever it was non-zero, consulting epics.md only as a fallback. That
# is wrong in the single most common state a project is ever in: /project-plan writes epics.md with
# every epic, then the directories are scaffolded ONE AT A TIME. A project with 4 planned epics and
# its first epic dir created counts 1 — below the threshold — so the gate reported "not applicable"
# and passed clean. VERIFIED end-to-end before this was rewritten: a fixture with four `### E00N`
# headings and one `epics/E001/` dir produced "epics: 1 · lenses required: 0" and exit 0, while
# check-epic-prereqs.sh, one call up the stack, had already computed 4 and printed APPLICABLE.
#
# Two producers of one threshold, disagreeing, with the wrong one winning — and the failure
# direction leaves no trace, because an inert gate and a satisfied gate print the same exit code.
# check-epic-prereqs.sh:126-156 documents the MAX rule and implements it correctly; this is the
# copy that drifted. The regression test asserts the two agree on the same fixture, because the
# duplication is the real defect and a shared assertion is the only thing that holds it closed.
#
# Both directory namings count: `E###-epic-name` and the ordinal `001-epic-name`, per AGENTS.md.
# Matching only `E*` under-counts every ordinal-named repo to zero — the same silent gate-off.
count_epics() {
  local proj="$1" dir_n=0 md_n=0 candidate
  if [[ -d "$proj/epics" ]]; then
    for candidate in "$proj"/epics/*; do
      [[ -d "$candidate" ]] || continue
      case "$(basename "$candidate")" in
        E[0-9]*|[0-9]*) dir_n=$((dir_n + 1)) ;;
      esac
    done
  fi
  if [[ -f "$proj/epics.md" ]]; then
    md_n="$(grep -cE '^#+[[:space:]]*E[0-9]+' "$proj/epics.md" 2>/dev/null || true)"
    md_n="$(sp_trim "$md_n")"
    [[ "$md_n" =~ ^[0-9]+$ ]] || md_n=0
  fi
  if [[ "$dir_n" -gt "$md_n" ]]; then printf '%s' "$dir_n"; else printf '%s' "$md_n"; fi
}

play_level_of() {
  local root="$1" pj v
  pj="$root/.speck/project.json"
  [[ -f "$pj" ]] || { printf ''; return 0; }
  v="$(grep -oE '"play_level"[[:space:]]*:[[:space:]]*"[^"]*"' "$pj" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || true)"
  sp_head 1 "$v"
}

# FRESHNESS IS THE CONTENT PREDICATE, never `stamped SHA == HEAD`.
# project-state-template.md:125-128 rules the SHA form out explicitly, and speck_graph.py's
# _git_changed_since (:2508-2532) is the reusable implementation: a proof is stale when the thing it
# proves CHANGED AFTER it. ANCESTRY (`<sha>..HEAD -- <path>`), not timestamps — two commits can
# share a second, and a `%ct` comparison called a proof fresh while its subject had visibly moved.
# With no git history the answer is `unknown`, never `fresh`.
freshness_check() {
  local dir="$1" report="$2"; shift 2
  local root report_sha art cnt dirty stale=""
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "$root" ]]; then
    emit_note "freshness: UNKNOWN — $dir is not inside a git repository, so 'did the corpus change after the report' has no answer here. Reported as unknown, never as fresh."
    return 0
  fi
  dirty="$(git -C "$dir" status --porcelain -- "$report" 2>/dev/null || true)"
  report_sha="$(git -C "$dir" log -1 --format=%H -- "$report" 2>/dev/null || true)"
  if [[ -n "$dirty" || -z "$report_sha" ]]; then
    # Not a hole. An uncommitted or modified report is being authored right now and will carry this
    # commit, at which point its commit is newer than every corpus artifact in it — so it IS fresh.
    emit_note "freshness: the report is uncommitted or modified in the working tree — it is being authored in this commit, so it postdates the corpus by construction."
    return 0
  fi
  for art in "$@"; do
    [[ -f "$art" ]] || continue
    cnt="$(git -C "$dir" rev-list --count "${report_sha}..HEAD" -- "$art" 2>/dev/null || true)"
    if ! printf '%s' "$cnt" | grep -qE '^[0-9]+$'; then
      emit_note "freshness: ancestry for $(basename "$art") could not be computed — UNKNOWN, not fresh."
      continue
    fi
    if [[ "$cnt" -gt 0 ]]; then stale="$stale $(basename "$art") (+$cnt commit(s))"; fi
  done
  if [[ -n "$stale" ]]; then
    emit_p1 "ANALYSIS_STALE.P1" "the corpus moved after the analysis was committed:$stale. Every finding, every 'no issue here' and the gate verdict itself describe a different tree. Re-run the analysis."
  else
    emit_note "freshness: fresh — no corpus artifact has a commit after the report's."
  fi
  return 0
}

# PROMISE COVERAGE, READ FROM THE GRAPH — never a second parser.
# speck_graph.py:13-14's design invariant 2 forbids a parallel truth, and :424-440 already extracts
# MM-N, JOB-N and (since #108) DIF-N from product-contract.md. So the graph is the READER here:
# shell out, take every node of kind magic-moment / job / differentiator, and never re-grep
# '### MM-N' in bash. If python3 is missing or the build fails, say completeness was NOT computed —
# an honest unknown, never a silent pass.
#
# DIF-N closes the limit v10.3 shipped disclosed (#108): §3 pillars were free prose with no id, so
# the gate emitted "pillars: not evaluated" rather than claim a verdict it could not compute. They
# have ids now, and they are gated exactly like MM-N — but only once a contract declares one, which
# is why no project is newly convicted by this. §3a anti-differentiators are deliberately NOT nodes:
# an anti-differentiator is a constraint, and demanding a delivery path for a claim whose content is
# that nothing gets delivered produces findings closable only by deleting the claim.
promise_coverage_check() {
  local proj="$1"
  local graph_py graph_json ids id row rc=0
  graph_py="$(cd "$(dirname "$0")/../../graph" 2>/dev/null && pwd || true)/speck_graph.py"
  if [[ ! -f "$graph_py" ]]; then
    local root; root="$(speck_root "$proj")"
    graph_py="$root/.speck/scripts/graph/speck_graph.py"
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    emit_p2 "ANALYSIS_COVERAGE_UNCOMPUTED.P2" "python3 is not available, so the promise set could not be read from the witness graph. Matrix completeness was NOT computed — this is an unknown, not a pass."
    return 0
  fi
  if [[ ! -f "$graph_py" ]]; then
    emit_p2 "ANALYSIS_COVERAGE_UNCOMPUTED.P2" "speck_graph.py was not found, so the promise set could not be read. Matrix completeness was NOT computed — this is an unknown, not a pass."
    return 0
  fi
  graph_json="$(python3 "$graph_py" build "$proj" --stdout 2>/dev/null)" || rc=$?
  if [[ "$rc" -ne 0 || -z "$graph_json" ]]; then
    emit_p2 "ANALYSIS_COVERAGE_UNCOMPUTED.P2" "'speck_graph.py build $proj --stdout' did not produce a graph (exit ${rc}). Matrix completeness was NOT computed — this is an unknown, not a pass."
    return 0
  fi
  rc=0
  ids="$(printf '%s' "$graph_json" | python3 -c '
import json, sys
try:
    g = json.load(sys.stdin)
except Exception:
    sys.exit(3)
for n in g.get("nodes", []):
    if n.get("kind") in ("magic-moment", "job", "differentiator"):
        print(n.get("id", ""))
' 2>/dev/null)" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    emit_p2 "ANALYSIS_COVERAGE_UNCOMPUTED.P2" "the witness graph JSON could not be parsed. Matrix completeness was NOT computed — this is an unknown, not a pass."
    return 0
  fi
  if [[ -z "${ids//[[:space:]]/}" ]]; then
    emit_note "promise coverage: the graph knows no MM-N, JOB-N or DIF-N node for this project (product-contract.md declares none) — nothing to require of the matrix."
    return 0
  fi

  resolve_columns_from_header "$COVERAGE_HEADER" || true
  local c_stat missing="" unresolved="" scell sclass
  c_stat="$(column_index 'status')"
  if [[ -z "$COVERAGE_HEADER" || "$c_stat" -lt 0 ]]; then
    emit_p1 "PROMISE_UNCOVERED.P1" "the report has no Promise Coverage matrix with a resolvable Status column, while the graph knows $(printf '%s' "$ids" | grep -c . || true) promise node(s). An uncovered promise is CRITICAL by construction, so an unreadable matrix cannot report a pass."
    return 0
  fi
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    row="$(printf '%s\n' "$(table_data_rows "$COVERAGE_TABLE")" | grep -E "(^|[^A-Za-z0-9_-])${id}([^A-Za-z0-9_-]|$)" || true)"
    row="$(sp_head 1 "$row")"
    if [[ -z "$row" ]]; then
      missing="$missing $id"
      continue
    fi
    split_row "$row"
    scell="$(cell_at "$c_stat")"
    # ONE status vocabulary across both tables — the template says so explicitly, so the matrix
    # reuses status_class rather than growing a second dialect that drifts from it. The pre-v10.3
    # matrices wrote '✅ / ⚠️ P1' instead, so a bare tick still reads as resolved; everything the
    # vocabulary does not recognise stays unresolved, which is the safe direction (it demands a
    # resolution rather than granting one).
    sclass="$(status_class "$scell")"
    if [[ "$sclass" == unknown ]] && printf '%s' "$scell" | grep -q '✅' && ! printf '%s' "$scell" | grep -qE '⚠️|❌'; then
      sclass=resolved
    fi
    if status_is_live "$sclass"; then unresolved="$unresolved $id(status:'${scell:-empty}')"; fi
  done <<< "$ids"

  if [[ -n "$missing" ]]; then
    emit_p1 "PROMISE_UNCOVERED.P1" "the graph knows these promise nodes and the coverage matrix does not name them:$missing. An unaddressed MM-N/JOB-N/DIF-N is CRITICAL by construction — the matrix is where that gets caught, so a promise absent from it is a promise nobody looked for."
  fi
  if [[ -n "$unresolved" ]]; then
    emit_p1 "PROMISE_UNCOVERED.P1" "these promise nodes appear in the coverage matrix with an unresolved status:$unresolved. A row that names a gap is a finding, not coverage."
  fi
  if [[ -z "$missing" && -z "$unresolved" ]]; then
    emit_note "promise coverage: every MM-N/JOB-N/DIF-N the graph knows is present in the matrix with a resolved status."
  fi
  return 0
}

# DECORRELATION. See the file header for exactly what this proves and what it does not.
#
# THE RAISING LENS IS READ OFF THE ROW, not out of the roster's Findings cell. The template fixes
# the finding ID as `<lens id>-<n>` ("`L3-1` was raised by L3") and has the Category name that lens
# too, while the roster's Findings column carries a COUNT. So the ID prefix is the primary key and
# the Category is the fallback; a row that yields neither has no recorded raiser, and an unrecorded
# raiser cannot be shown to differ from the verifier.
raising_lens_of() {
  local fid="$1" fcat="$2" tok
  tok="$(printf '%s' "$fid" | grep -oE '^[A-Za-z]+[0-9]+' || true)"
  if [[ -n "$tok" ]]; then printf '%s' "$(lc "$tok")"; return 0; fi
  printf '%s' "$(lc "$fcat")"
  return 0
}

decorrelation_check() {
  local required="$1" level="${2:-project}"
  local declared roster_rows=0
  declared="$(lens_declared_count)"

  # Roster lookup, built ONCE before the findings loop: every table read shares ROW_CELLS, so a
  # nested read would clobber the outer row mid-iteration.
  local roster_lookup="" row lens reviewer
  local c_lens c_rev
  if [[ -n "$ROSTER_HEADER" ]]; then
    resolve_columns_from_header "$ROSTER_HEADER" || true
    c_lens="$(column_index 'lens')"; c_rev="$(column_index 'reviewer')"
    while IFS= read -r row; do
      [[ -z "${row//[[:space:]]/}" ]] && continue
      split_row "$row"
      lens="$(cell_at "$c_lens")"; reviewer="$(cell_at "$c_rev")"
      [[ -z "$lens" ]] && continue
      roster_rows=$((roster_rows + 1))
      roster_lookup="${roster_lookup}$(lc "$lens")	$(lc "$reviewer")
"
    done <<< "$(table_data_rows "$ROSTER_TABLE")"
  fi

  local effective_declared="$declared"
  if [[ "${effective_declared:-0}" -lt 1 ]]; then effective_declared="$roster_rows"; fi
  if [[ "${effective_declared:-0}" -lt "$required" ]]; then
    if [[ "$level" == "story" ]]; then
      emit_p1 "ANALYSIS_DECORRELATION_MISSING.P1" "this story tier requires $required independent lens/lenses and the report declares ${effective_declared:-0}. Build requires S1; Platform requires S1-S3."
    else
      emit_p2 "ANALYSIS_DECORRELATION_UNVERIFIED.P2" "this tier requires $required lens/lenses and the report declares ${effective_declared:-0}. The mandatory three at Build-with-4+-epics are L3 promise-coverage, L6 cross-artifact-drift and L7 completeness-critic; Platform requires all seven."
    fi
  fi

  if [[ -z "$ISSUES_HEADER" ]]; then
    if [[ "$level" == "story" ]]; then
      emit_p1 "ANALYSIS_DECORRELATION_MISSING.P1" "the Issues Found table has no resolvable header row, so no finding's Verifier could be compared with the lens that raised it."
    else
      emit_p2 "ANALYSIS_DECORRELATION_UNVERIFIED.P2" "the Issues Found table has no resolvable header row, so no finding's Verifier could be compared with the lens that raised it."
    fi
    return 0
  fi
  resolve_columns_from_header "$ISSUES_HEADER" || true
  local c_id c_cat c_sev c_ver
  c_id="$(column_index 'id')"; c_cat="$(column_index 'category')"
  c_sev="$(column_index 'severity')"; c_ver="$(column_index 'verifier')"
  if [[ "$c_id" -lt 0 || "$c_ver" -lt 0 ]]; then
    if [[ "$level" == "story" ]]; then
      emit_p1 "ANALYSIS_DECORRELATION_MISSING.P1" "the Issues Found table declares no ID and/or Verifier column, so no finding's verification could be compared with the lens that raised it."
    else
      emit_p2 "ANALYSIS_DECORRELATION_UNVERIFIED.P2" "the Issues Found table declares no ID and/or Verifier column, so no finding's verification could be compared with the lens that raised it."
    fi
    return 0
  fi
  local fid fcat fsev fver eff bad="" raiser vlc rrev
  while IFS= read -r row; do
    [[ -z "${row//[[:space:]]/}" ]] && continue
    split_row "$row"
    fid="$(cell_at "$c_id")"; fcat="$(cell_at "$c_cat")"
    fsev="$(cell_at "$c_sev")"; fver="$(cell_at "$c_ver")"
    [[ -z "$fid" ]] && continue
    eff="$(effective_severity "$fsev" "$fcat")"
    case "$eff" in critical|high) : ;; *) continue ;; esac
    if [[ -z "$fver" ]]; then
      bad="$bad $fid(no Verifier)"
      continue
    fi
    raiser="$(raising_lens_of "$fid" "$fcat")"
    if [[ -z "$raiser" ]]; then
      bad="$bad $fid(no raising lens readable from its ID or Category)"
      continue
    fi
    vlc="$(lc "$fver")"
    if [[ "$vlc" == "$raiser" ]] || printf '%s' "$vlc" | grep -qE "(^|[^a-z0-9_-])${raiser}([^a-z0-9_-]|$)"; then
      bad="$bad $fid(Verifier '$fver' is the lens that raised it)"
      continue
    fi
    # A verifier naming the RAISER'S OWN reviewer is the same party wearing the other lens.
    rrev="$(printf '%s' "$roster_lookup" | grep -E "^${raiser}(	| )" || true)"
    rrev="$(printf '%s' "$(sp_head 1 "$rrev")" | cut -d'	' -f2)"
    if [[ -n "$rrev" && "$vlc" == "$rrev" ]]; then
      bad="$bad $fid(Verifier '$fver' is the raising lens's own reviewer)"
    fi
  done <<< "$(table_data_rows "$ISSUES_TABLE")"

  if [[ -n "$bad" ]]; then
    if [[ "$level" == "story" ]]; then
      emit_p1 "ANALYSIS_DECORRELATION_MISSING.P1" "CRITICAL/HIGH finding(s) whose verification is not decorrelated:$bad. Each must name a Verifier that is a different party from the lens that raised it."
    else
      emit_p2 "ANALYSIS_DECORRELATION_UNVERIFIED.P2" "CRITICAL/HIGH finding(s) whose verification is not decorrelated:$bad. Each must name a Verifier that is a different party from the lens that raised it — self-confirmation is the shape #106 exists to catch."
    fi
  elif [[ "${effective_declared:-0}" -ge "$required" ]]; then
    emit_note "decorrelation: $effective_declared lens/lenses declared (>= $required required), and every CRITICAL/HIGH finding names a verifier distinct from its lens. This proves the roster's WIDTH and the row-level distinctness — it does NOT prove the reviewer was genuinely a different party, and nothing here claims it does."
  fi
  return 0
}

gate_mode() {
  local dir="$1"
  [[ -d "$dir" ]] || { echo "ERROR: --gate needs a directory, got: $dir" >&2; exit 2; }
  dir="$(cd "$dir" && pwd)"

  local level report proj
  if [[ -f "$dir/spec.md" && -f "$dir/tasks.md" ]]; then
    level="story"; report="$dir/story-analysis-report.md"; proj="${dir%%/epics/*}"
  elif [[ -f "$dir/epic.md" || "$dir" == */epics/* ]]; then
    level="epic"; report="$dir/epic-analysis-report.md"; proj="${dir%%/epics/*}"
  else
    level="project"; report="$dir/project-analysis-report.md"; proj="$dir"
  fi
  DECISIONS_LOG="$(resolve_decisions_log "$dir")"

  local root play play_declared epics required fm_play="" fm_epics=""
  root="$(speck_root "$dir")"
  epics="$(count_epics "$proj")"
  play_declared="$(play_level_of "$root")"
  play="$play_declared"
  [[ -z "$play" ]] && play="platform"

  # Live project truth decides rigor. Report frontmatter is a bound claim to compare, never an
  # authority that can lower the gate by declaring a cheaper play level or smaller epic count. But
  # the comparison needs a LIVE declaration to disagree with — when .speck/project.json carries no
  # play_level at all, "platform" above is this gate's own conservative assumption (AGENTS.md: "if
  # absent, use Platform until the project is classified"), not a fact the report can be convicted of
  # contradicting. Accusing a report of drifting from a guess this gate invented is the exact
  # self-referential shape ANALYSIS_SCOPE_DRIFT.P1 exists to catch, one level up — so the play_level
  # comparison runs only against $play_declared, never against the synthesized default.
  if [[ -f "$report" ]]; then
    load_report "$report"
    fm_play="$(fm_value 'play_level')"; fm_epics="$(fm_value 'epic_count')"
    if [[ -n "$play_declared" && -n "$fm_play" && "$(lc "$fm_play")" != "$(lc "$play_declared")" ]]; then
      emit_p1 "ANALYSIS_SCOPE_DRIFT.P1" "report play_level '$fm_play' disagrees with live project level '$play_declared'. The report cannot lower or redefine its own rigor."
    fi
    if [[ "$level" != story ]] && printf '%s' "$fm_epics" | grep -qE '^[0-9]+$' && [[ "$fm_epics" -ne "$epics" ]]; then
      emit_p1 "ANALYSIS_SCOPE_DRIFT.P1" "report epic_count '$fm_epics' disagrees with the live plan/directory count '$epics'. The report cannot shrink the corpus it claims to analyze."
    fi
  fi
  required="$(required_lens_count "$play" "$epics" "$level")"

  echo -e "${BLUE}🧪 Analysis gate (#106) — $level: $dir${NC}"
  echo "   play_level: $play · epics: $epics · lenses required: $required"
  echo ""

  if [[ "$required" -eq 0 ]]; then
    if [[ -f "$report" && "$BOUND" == true ]] && is_v11_report "$report" "$dir"; then
      load_tables
      flow_fit_gate_check "$level" "$play" "$epics" "$dir" "$report"
    fi
    if (( p1 > 0 )); then
      gate_verdict_and_exit
    fi
    emit_note "the decorrelated-analysis mandate does not reach this tier. Project scope binds Build with 4+ epics and Platform; epic scope binds Build and Platform; story scope binds Build and Platform. Nothing to gate here."
    echo -e "${GREEN}Analysis gate: not applicable at this tier.${NC}"
    exit 0
  fi

  local marker="$dir/.analysis-gate-grandfathered"

  # --- predicate 1: does an analysis report exist, and is it one this contract can read? ---
  local bound_report=false
  if [[ -f "$report" ]]; then
    load_report "$report"
    bound_report="$BOUND"
  fi

  if [[ "$bound_report" == false ]]; then
    # THE GRANDFATHER PATH. Decided by the repo owner: a project planned before this release gets a
    # loud, repeated notice, never a block, until /analyze --level project runs once. The gate is real
    # FORWARD and advisory BACKWARD, and that asymmetry is disclosed here rather than hidden.
    #
    # The marker keys on "no report this contract can read", which covers both the absent report and
    # the pre-v10.3-vintage one — running /analyze --level project under v10.3 writes a bound report, so the
    # exemption expires by itself and nobody has to remember to delete the marker.
    #
    # DELIBERATELY NOT ESCALATED BY --strict, unlike every other P2 in this file. An exemption is a
    # disclosure, not a finding; escalating it would turn "never a block" into "blocks in CI", which
    # is where --strict actually runs. The one place the exit contract bends, said out loud.
    if [[ -f "$marker" ]]; then
      echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${YELLOW}ANALYSIS_GRANDFATHERED.P2${NC}  this project was planned before the decorrelated"
      echo -e "  analysis gate shipped, so it is EXEMPT — this notice never blocks, and it will"
      echo -e "  repeat on every run until the exemption expires."
      echo -e "  A full canonical planning corpus — every skill entered, five skeptical-review"
      echo -e "  primitives, premise-challenge, every strict validator green — was measured"
      echo -e "  carrying 1 CRITICAL and 13 HIGH defects that only an adversarial decorrelated"
      echo -e "  pass found. That is what this project has not had."
      echo -e "  Clear it by running ${GREEN}/analyze --level project${YELLOW} once; the marker expires by itself"
      echo -e "  the moment a v10.3 report lands (${marker#"$dir"/})."
      echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${GREEN}Analysis gate: grandfathered (advisory, non-blocking).${NC}"
      exit 0
    fi
    if [[ ! -f "$report" ]]; then
      emit_p1 "UNANALYZED_CORPUS.P1" "$(basename "$report") does not exist. This tier requires a decorrelated analysis pass before execution begins: the author who wrote the corpus is not the party who can certify it (AGENTS.md P4). Run /analyze --level $level."
    else
      # A report exists but predates the v10.3 contract. It is NOT unanalyzed — saying so would be
      # false — and its structure is exempt by the vintage rule, so the honest report is that its
      # decorrelation is unverifiable, not that it passed.
      emit_p2 "ANALYSIS_DECORRELATION_UNVERIFIED.P2" "$(basename "$report") predates v10.3 (no 'artifact_type:' in its frontmatter), so it declares no lens roster and no per-finding verifier. Its structure is exempt by the vintage rule; its decorrelation is UNKNOWN, never verified. Re-run /analyze --level project to produce a report this gate can read, or drop a .analysis-gate-grandfathered marker to take the disclosed exemption."
    fi
    gate_verdict_and_exit
  fi

  log_ok_gate "analysis report present and v10.3-vintage: $(basename "$report")"
  [[ -f "$marker" ]] && emit_note "a .analysis-gate-grandfathered marker is present but a v10.3 report exists, so the exemption has expired and the marker is inert. It is safe to delete."

  # A report may exempt itself from the Flow Fit contract by declaring a pre-v11 version. That
  # claim is honoured (see is_v11_report) but never silently: when the workspace's own tooling is
  # already v11, say so, so the exemption is a visible decision instead of an invisible one.
  if report_claims_stale_vintage "$dir"; then
    emit_p2 "ANALYSIS_VINTAGE_UNVERIFIED.P2" "$(basename "$report") declares speck_version $(fm_value 'speck_version') while this workspace's .speck/VERSION is already v11+, so it is exempt from the Flow Fit contract on its own say-so. That exemption is legitimate for a report genuinely written before the upgrade and is NOT verifiable from the artifact itself. Re-run /analyze --level $level to produce a report this gate can read in full."
  fi

  load_tables

  # --- predicate 2: conditional flow coverage ---
  flow_fit_gate_check "$level" "$play" "$epics" "$dir" "$report"

  # --- predicate 3: freshness (CONTENT, never `stamped SHA == HEAD`) ---
  if [[ "$level" == "story" ]]; then
    freshness_check "$dir" "$report" "$dir/spec.md" "$dir/plan.md" "$dir/tasks.md"
  elif [[ "$level" == "epic" ]]; then
    freshness_check "$dir" "$report" "$dir/epic.md" "$dir/epic-tech-spec.md" "$dir/epic-breakdown.md"
  else
    freshness_check "$dir" "$report" "$dir/PRD.md" "$dir/epics.md" "$dir/product-contract.md"
  fi

  # --- predicate 4: an open CRITICAL ---
  critical_open_check

  # --- predicate 5: promise coverage, read from the graph ---
  # Project-level only. MM-N/JOB-N/DIF-N are project-global nodes, so requiring one epic's matrix to name
  # every promise in the product would manufacture a finding out of correct scoping.
  if [[ "$level" == "project" ]]; then
    promise_coverage_check "$proj"
  else
    emit_note "promise coverage is a project-level predicate and is not evaluated at $level altitude; the selected report still checks its scoped coverage rows."
  fi

  # --- predicate 6: decorrelation ---
  decorrelation_check "$required" "$level"

  gate_verdict_and_exit
}

log_ok_gate() { echo -e "${GREEN}✓${NC} $1"; }

# The CRITICAL-open predicate reads the findings TABLE by header name.
# Explicitly NOT check-story-prereqs.sh:85's pipeline
#   grep -i CRITICAL … | grep -E "\[[[:space:]]\]|todo"
# — it requires a `[ ]` checkbox or the word `todo` on the same line, so it cannot see a table row,
# which is exactly the shape the analysis template mandates. That grep would report zero findings on
# every conforming report: a green reporting its exposure, not its verdict.
critical_open_check() {
  if [[ -z "$ISSUES_HEADER" ]]; then
    emit_p1 "ANALYSIS_REPORT_MALFORMED.P1" "this report declares v10.3 vintage but its Issues Found table has no resolvable header row, so the open-CRITICAL predicate has nothing to read. A bound report that cannot be read is not a report that passed. (Validator-local code, outside the shared P-code set: it fires only when a bound report's mandated structure is missing.) Run: validate-project-analysis.sh --strict <report.md>"
    return 0
  fi
  resolve_columns_from_header "$ISSUES_HEADER" || true
  local c_id c_cat c_sev c_stat
  c_id="$(column_index 'id')"; c_cat="$(column_index 'category')"
  c_sev="$(column_index 'severity')"; c_stat="$(column_index 'status')"
  if [[ "$c_id" -lt 0 || "$c_sev" -lt 0 || "$c_stat" -lt 0 ]]; then
    emit_p1 "ANALYSIS_REPORT_MALFORMED.P1" "the Issues Found table is missing one of the ID / Severity / Status columns, so the open-CRITICAL predicate cannot be evaluated. (Validator-local code, outside the shared P-code set.) Run: validate-project-analysis.sh --strict <report.md>"
    return 0
  fi
  local row fid fcat fsev fstat eff sclass open="" ruled=""
  while IFS= read -r row; do
    [[ -z "${row//[[:space:]]/}" ]] && continue
    split_row "$row"
    fid="$(cell_at "$c_id")"; fcat="$(cell_at "$c_cat")"
    fsev="$(cell_at "$c_sev")"; fstat="$(cell_at "$c_stat")"
    [[ -z "$fid" ]] && continue
    eff="$(effective_severity "$fsev" "$fcat")"
    [[ "$eff" == critical ]] || continue
    [[ "$(authored_severity "$fsev")" == critical ]] || ruled="$ruled $fid"
    sclass="$(status_class "$fstat")"
    status_is_live "$sclass" && open="$open $fid(status:'${fstat:-empty}')"
  done <<< "$(table_data_rows "$ISSUES_TABLE")"

  if [[ -n "$ruled" ]]; then emit_note "severity raised BY RULE (the Category names a class the contract fixes as CRITICAL, whatever the Severity cell says):$ruled"; fi
  if [[ -n "$open" ]]; then
    emit_p1 "ANALYSIS_CRITICAL_OPEN.P1" "CRITICAL finding(s) with a live status:$open. Only 'resolved' or 'waived DEC-####' against a logged decision closes one — a blank, 'pending' or 'n/a' cell is open, because the alternative is a status field that closes findings by being vague."
  else
    emit_note "no CRITICAL finding is open."
  fi
  return 0
}

gate_verdict_and_exit() {
  echo ""
  echo "Analysis gate: ${p1} blocking(P1) · ${p2} advisory(P2)"
  if [[ "$p1" -gt 0 ]]; then
    echo -e "${RED}⛔ Analysis gate REJECTED — $p1 blocking finding(s).${NC}" >&2
    exit 1
  fi
  if [[ "$p2" -gt 0 && "$strict" == true ]]; then
    echo -e "${RED}⛔ Analysis gate REJECTED under --strict — $p2 advisory finding(s).${NC}" >&2
    exit 1
  fi
  echo -e "${GREEN}✅ Analysis gate: clear.${NC}"
  exit 0
}

if [[ "$mode" == "gate" ]]; then
  gate_mode "$target"
else
  structural_mode "$target"
fi
