#!/usr/bin/env bash

# Speck Epic Prerequisite Gate — the epic-altitude twin of check-story-prereqs.sh.
#
# Named by TRIGGER, like its sibling: check-story-prereqs fires at /story-implement, this fires
# at /epic-specify. It answers one question — "is this project's planning corpus allowed to be
# built on yet?"
#
# WHY IT EXISTS (issue #106). /project-analyze was optional at exactly the altitude where the
# author self-certifies. Measured on project 001-odd: a planning corpus produced through the FULL
# canonical Build flow — every skill entered, five skeptical-review primitives, premise-challenge,
# strict validators green — still carried 1 CRITICAL and 13 HIGH defects. Every one of them
# survived every inline gate, and they were found only by a decorrelated adversarial pass. Speck's
# P4 says the adversary is structural; at project-plan level it was opt-in, and the party opting in
# was the author. This script is what makes the adversarial pass a precondition rather than a
# suggestion, at the first altitude that consumes the corpus.
#
# Usage: check-epic-prereqs.sh [--strict] <PROJECT_DIR> [--epic <EPIC_ID>]
# Exit:  0 = clear to specify an epic, 1 = gate rejected, 2 = invocation error.
#
# THE THREE STEPS, and what each is allowed to do:
#   0. APPLICABILITY — computed from play_level + epic count, printed on EVERY run.
#   1. GRANDFATHER MARKER — a loud, repeated notice. It never blocks (see the block below).
#   2. DELEGATION to validate-project-analysis.sh --gate, which owns every P-code.
#
# WHAT THIS SCRIPT DELIBERATELY DOES NOT DO — mint P-codes of its own. Every finding here belongs
# to validate-project-analysis.sh; this file only decides whether that validator applies and
# escalates its exit status. One producer per code is the invariant v10 introduced GATE_VACUOUS to
# protect, and a second emitter is how that invariant is lost.
#
# AND IT DOES NOT CALL THE WITNESS GRAPH. An earlier draft ran `speck_graph.py gate <PROJECT_DIR>`
# here. Verified at speck_graph.py:1883-1905: with no `--epic`/`--story` scope, `_in_scope` returns
# True for everything and `blocking` becomes EVERY .P1 in the whole project — so specifying one
# epic would be rejected for a dangling ref in an unrelated one. The graph gate is scoped at the
# story altitude (check-story-prereqs.sh) where a scope argument actually exists.

set -euo pipefail

# shellcheck source=../lib/text.sh
. "$(dirname "$0")/../lib/text.sh"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 [--strict] <specs/projects/PROJECT_ID> [--epic <EPIC_ID>]"
  echo "  0 = clear to specify an epic, 1 = gate rejected, 2 = invocation error."
}

# --- arguments -----------------------------------------------------------------------------------
strict=false
project_dir=""
epic_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      strict=true; shift ;;
    --epic)
      shift
      if [[ $# -eq 0 || -z "${1:-}" || "${1:-}" == -* ]]; then
        echo -e "${RED}Error: --epic needs an epic id (e.g. --epic E003).${NC}" >&2
        usage >&2
        exit 2
      fi
      epic_id="$1"; shift ;;
    --epic=*)
      epic_id="${1#--epic=}"
      if [[ -z "$epic_id" ]]; then
        echo -e "${RED}Error: --epic needs an epic id (e.g. --epic=E003).${NC}" >&2
        usage >&2
        exit 2
      fi
      shift ;;
    -h|--help)
      usage; exit 0 ;;
    -*)
      echo -e "${RED}Error: unknown option '$1'.${NC}" >&2
      usage >&2
      exit 2 ;;
    *)
      if [[ -n "$project_dir" ]]; then
        echo -e "${RED}Error: unexpected extra argument '$1' (one PROJECT_DIR only).${NC}" >&2
        usage >&2
        exit 2
      fi
      project_dir="$1"; shift ;;
  esac
done

if [[ -z "$project_dir" ]]; then
  echo -e "${RED}Error: please specify the project directory path.${NC}" >&2
  usage >&2
  exit 2
fi
if [[ ! -d "$project_dir" ]]; then
  echo -e "${RED}Error: project directory does not exist: $project_dir${NC}" >&2
  exit 2
fi

PROJECT_DIR="$(cd "$project_dir" && pwd)"
project_id="$(basename "$PROJECT_DIR")"

scope_note=""
# --epic scopes the REPORT, nothing else, and saying so is the point: the check this gate runs is a
# property of the PROJECT's corpus, identical for every epic in it. An argument that silently
# implied per-epic scoping would be a label overclaiming its mechanism.
[[ -n "$epic_id" ]] && scope_note=" (specifying epic ${epic_id})"

echo -e "🥓 Checking pre-specify prerequisites for project ${project_id}${scope_note}...\n"

# --- Step 0: APPLICABILITY, computed rather than asserted -----------------------------------------
#
# This is the FIRST mechanical implementation of the 4+-epic threshold anywhere in Speck. Verified
# before writing it: AGENTS.md:92, .speck/README.md:187 and project-plan/SKILL.md all state the rule
# in PROSE, and a rule stated in prose cannot fail a build. The threshold is the tier boundary for
# the lens mandate (3 lenses at Build-with-4+-epics, all 7 at Platform), so it needed a single
# computed answer rather than a per-caller reading.
#
# THE COUNT IS A MAX OF TWO INDEPENDENT MEASUREMENTS, on purpose. epics.md is written by
# /project-plan and the epics/ directories are scaffolded afterwards, so the two disagree for a real
# and legitimate window in every project's life. Taking either one alone under-counts on one side of
# that window — and an under-count here silently switches the gate OFF, which is the failure
# direction that leaves no trace.
epics_md="$PROJECT_DIR/epics.md"
epics_md_count=0
if [[ -f "$epics_md" ]]; then
  # `grep -c` exits 1 on zero matches, which `set -e` would treat as a crash; capture, then sanity
  # check the value, so an unreadable file cannot arrive here as a confident "0 epics".
  epics_md_count="$(grep -cE '^###[[:space:]]*E[0-9]+' "$epics_md" 2>/dev/null || true)"
  epics_md_count="$(sp_trim "$epics_md_count")"
  [[ "$epics_md_count" =~ ^[0-9]+$ ]] || epics_md_count=0
fi

# Both documented directory namings count. AGENTS.md's naming line reads "`E###-epic-name` (or the
# ordinal `001-epic-name` as many repos use)" — matching only `E*` would under-count every
# ordinal-named repo to zero, which is precisely the silent gate-off this MAX exists to prevent.
epic_dir_count=0
if [[ -d "$PROJECT_DIR/epics" ]]; then
  for candidate in "$PROJECT_DIR"/epics/*; do
    [[ -d "$candidate" ]] || continue
    case "$(basename "$candidate")" in
      E[0-9]*|[0-9]*) epic_dir_count=$((epic_dir_count + 1)) ;;
    esac
  done
fi

epic_count="$epics_md_count"
if [[ "$epic_dir_count" -gt "$epic_count" ]]; then
  epic_count="$epic_dir_count"
fi

# play_level lives in the WORKSPACE's .speck/project.json, which sits above specs/projects/<id>/ —
# so it is found by walking up, exactly as staleness-check.sh:58-66 does. Absence defaults to
# `platform`: that is Speck's documented back-compat rule (.speck/README.md:187, "No project.json =
# treated as Platform"), it is what promote.js:59 and commit-msg-hook.sh:71 already assume, and it
# is the safe direction for a gate — an unknown play level makes the check RUN rather than vanish.
# The Speck repo itself has no .speck/project.json, so this path is the normal one, not the edge.
play_level="platform"
play_level_source="default (no .speck/project.json found — Speck's documented Platform back-compat)"
project_json=""
workspace_root=""
cur="$PROJECT_DIR"
while [[ "$cur" != "/" ]]; do
  if [[ -f "$cur/.speck/project.json" ]]; then
    project_json="$cur/.speck/project.json"
    workspace_root="$cur"
    break
  fi
  cur="$(dirname "$cur")"
done
if [[ -n "$project_json" ]]; then
  # Captured, never tested through the pipe: under `set -o pipefail` a `grep | sed` that finds
  # nothing reports failure, and "the field is absent" and "the read crashed" become the same event.
  declared_level="$(grep -o '"play_level"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" 2>/dev/null \
    | sed -E 's/.*"([^"]*)"$/\1/' || true)"
  declared_level="$(sp_trim "$declared_level")"
  if [[ -n "$declared_level" ]]; then
    play_level="$(printf '%s' "$declared_level" | tr '[:upper:]' '[:lower:]')"
    play_level_source="$project_json"
  else
    play_level_source="$project_json (no play_level field — Platform back-compat)"
  fi
fi

applicable=false
if [[ "$play_level" == "platform" ]]; then
  applicable=true
  applicability_reason="play_level is Platform"
elif [[ "$epic_count" -ge 4 ]]; then
  applicable=true
  applicability_reason="${play_level} with ${epic_count} epics (threshold: 4+)"
else
  # The declared level is quoted back rather than hardcoded as "Build": a project can declare
  # `sprint`, and a line that names the wrong tier is a small lie in the one place an author looks
  # to understand why the gate did or did not fire.
  applicability_reason="${play_level}, ${epic_count} epic(s) — below the 4+ threshold"
fi

# Printed on EVERY run, applicable or not. A gate that decides silently that it does not apply is
# indistinguishable from a gate that ran and found nothing, and that ambiguity is the whole subject
# of this release.
echo -e "${BLUE}Step 0 — applicability${NC}"
echo "   play_level: ${play_level}   [${play_level_source}]"
echo "   epic count: ${epic_count}   [epics.md headings: ${epics_md_count}, epics/ dirs: ${epic_dir_count} — MAX taken]"
if [[ "$applicable" != true ]]; then
  echo -e "${GREEN}   → NOT APPLICABLE (${applicability_reason}).${NC}"
  echo -e "${GREEN}\n✅ /project-analyze is not required at this scale. Clear to specify epic${epic_id:+ $epic_id}.${NC}"
  echo "   (It stays a good idea; it is simply not a gate below Build-with-4-epics — AGENTS.md:37's anti-bloat rule.)"
  exit 0
fi
echo -e "${YELLOW}   → APPLICABLE (${applicability_reason}). The analysis gate is in force.${NC}\n"

# --- the combined verdict, built WITHOUT short-circuiting -----------------------------------------
#
# validate-template.sh:466-517 is the precedent and the scar: under `set -e` a sequential pair of
# checks makes the second unreachable whenever the first aborts, so a report's missing section was
# never reported at all because an unrelated failure got there first. A validator you cannot reach
# is not a gate. Every step below therefore runs to completion and contributes to `rc`; nothing
# exits early; and exactly ONE verdict is printed, at the end, after all of them.
rc=0

# --- Step 1: the grandfather marker ---------------------------------------------------------------
#
# THE ASYMMETRY, DISCLOSED RATHER THAN HIDDEN. A project planned before v10.3 could not have run a
# gate that did not exist, so the v10-3-analysis-gate-grandfather migration writes it a marker and
# this gate downgrades to a loud, repeated notice for it — advisory backward. A project planned
# after this release has no marker and is blocked — real forward. The marker is per-PROJECT because
# the gap is per-project; .speck/project.json is workspace-scoped and would exempt a project that
# never had the gap.
#
# It is never a block, by decision. A gate that is red on arrival across every existing project gets
# bypassed rather than fixed, and a bypass habit costs more than the finding it was meant to force.
marker="$PROJECT_DIR/.analysis-gate-grandfathered"
report="$PROJECT_DIR/project-analysis-report.md"

echo -e "${BLUE}Step 1 — grandfather marker${NC}"
if [[ -f "$marker" ]]; then
  if [[ -f "$report" ]]; then
    # A spent marker still on disk is a live false-exemption: delete the report later and the marker
    # silently re-exempts the project. Naming it is cheap; leaving it is a quiet hole.
    echo -e "${YELLOW}   ⚠️  This project has BOTH a grandfather marker and a project-analysis-report.md.${NC}"
    echo -e "${YELLOW}       The exemption is spent. Remove the marker so it cannot re-exempt this project later:${NC}"
    echo -e "         rm ${marker}"
  else
    # One line, then the marker itself. The delegate below explains the exemption at length; what
    # only this step can show is the marker's own contents — which upgrade granted it, and the exact
    # gesture that ends it. Two copies of the same paragraph is noise, and noise is how a repeated
    # notice stops being read.
    echo -e "${YELLOW}   ⚠️  GRANDFATHERED (planned before the v10.3 analysis gate) — NOT blocked; repeats on every run until /project-analyze runs once.${NC}"
    echo "   ── marker: ${marker} ──"
    sed 's/^/   │ /' "$marker" || true
    echo "   ────────────────────────────────────────────────────────────"
  fi
else
  echo "   No marker — this project is inside the v10.3 gate (not grandfathered)."
fi
echo ""

# --- Step 2: delegate to validate-project-analysis.sh ---------------------------------------------
#
# That validator owns every P-code (UNANALYZED_CORPUS.P1, ANALYSIS_STALE.P1,
# ANALYSIS_CRITICAL_OPEN.P1, PROMISE_UNCOVERED.P1, and the P2s). It exits 1 on any P1 by default —
# no --strict needed, which is what makes it a gate rather than a report — and --strict additionally
# escalates its P2s. This script forwards --strict and escalates the result; it interprets nothing.
strict_flag=""
[[ "$strict" == true ]] && strict_flag="--strict"

# Resolved from two COMMITTED locations only — never from an environment variable. An env-overridable
# validator path is a gate with an off switch, which is the defect class this release is about.
analysis_validator=""
analysis_candidates="$SCRIPT_DIR/validators/validate-project-analysis.sh"
[[ -n "$workspace_root" ]] && analysis_candidates="$analysis_candidates
$workspace_root/.speck/scripts/validation/validators/validate-project-analysis.sh"
while IFS= read -r candidate; do
  if [[ -n "$candidate" && -f "$candidate" ]]; then
    analysis_validator="$candidate"
    break
  fi
done <<< "$analysis_candidates"

echo -e "${BLUE}Step 2 — project-analysis gate${NC}"
if [[ -z "$analysis_validator" ]]; then
  # NOT a pass. The gate is applicable and could not be evaluated, and "could not run" reported as
  # "found nothing" is the exact reporting defect #106 is about. The two scripts ship together in
  # .speck/scripts/, so this state means an incomplete sync (or a deleted gate) — both are things a
  # human must see, and neither is a clean corpus.
  echo -e "${RED}   ❌ validate-project-analysis.sh not found — the analysis gate could NOT be evaluated.${NC}"
  echo -e "${YELLOW}       Expected at: $SCRIPT_DIR/validators/validate-project-analysis.sh${NC}"
  echo -e "${YELLOW}       Restore it with \`speck upgrade\` (it ships in .speck/scripts/), then re-run.${NC}"
  rc=1
else
  gate_rc=0
  # Captured, then tested — the check-story-prereqs.sh:114-130 precedent. Piping into grep would
  # report the PRODUCER's status and make a crashed validator indistinguishable from a clean one.
  gate_out="$(bash "$analysis_validator" $strict_flag --gate "$PROJECT_DIR" 2>&1)" || gate_rc=$?
  printf '%s\n' "$gate_out"
  if [[ "$gate_rc" -eq 0 ]]; then
    echo -e "${GREEN}   ✓ Analysis gate clear.${NC}"
  elif [[ "$gate_rc" -eq 1 ]]; then
    echo -e "${RED}   ❌ Analysis gate REJECTED (see the findings above).${NC}"
    rc=1
  else
    # Exit 2+ is the validator's invocation-error contract, i.e. it never reached a verdict.
    echo -e "${RED}   ❌ validate-project-analysis.sh exited ${gate_rc} — it did not reach a verdict.${NC}"
    echo -e "${YELLOW}       NOT counted as clean: an unevaluated gate is an unknown, never a green.${NC}"
    rc=1
  fi
fi

# --- ONE final verdict ----------------------------------------------------------------------------
#
# The delegate prints its own terminal line, so a naive combination ends with that line above this
# one. A reader — or an agent — scanning the tail takes the LAST verdict as the verdict, which is
# how a green sits on top of a block (validate-template.sh:504-515, same scar).
echo ""
if [[ "$rc" -ne 0 ]]; then
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}GATE REJECTED: the planning corpus for ${project_id} is not clear to build on.${NC}"
  echo -e "\n${YELLOW}To clear it:${NC}"
  echo -e "  1. Run ${GREEN}/project-analyze${NC} on ${PROJECT_DIR} — a decorrelated adversarial pass over"
  echo -e "     PRD.md, epics.md and product-contract.md, by a reviewer that did not author them."
  echo -e "  2. Resolve (or waive with a DEC) every CRITICAL finding it records."
  echo -e "  3. Re-run this check."
  echo -e "\n${YELLOW}(Any '✅'/'PASSED' line above belongs to a single sub-check, not to this gate.)${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 1
fi

echo -e "${GREEN}🚀 PREREQUISITE GATES PASSED! ${project_id} is clear to specify epic${epic_id:+ $epic_id}.${NC}"
exit 0
