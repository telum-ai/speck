#!/usr/bin/env bash

# Speck Story Prerequisite Gate Validator
# Deterministically checks if a story is ready for implementation before coding.
# Requirements:
# 1. spec.md must exist and have lifecycle: Specified (or State: Specified)
# 2. plan.md must exist
# 3. tasks.md must exist
# 4. Any analysis report already on disk (any of the three legacy/canonical filenames) is scanned
#    for unresolved CRITICAL items, unconditionally — this is main's original guard, restored. A
#    v10.3+/v11 BOUND report (frontmatter `artifact_type: story-analysis-report`) is checked by
#    delegating to validate-project-analysis.sh --gate, which reads the canonical findings TABLE
#    by header name; an unbound legacy report is checked by the original checkbox/todo heuristic,
#    which is the only thing that can still see that shape.
# 5. v11 tasks declare analysis_required by play level. Build/Platform require a bound
#    story-analysis-report.md; Sprint declares false. Every value this gate sees is cross-checked
#    against the LIVE .speck/project.json play_level, never trusted as self-certifying:
#      - PRESENT and true            -> mandatory gate runs.
#      - PRESENT and false           -> honored only when the live play_level is not Build/Platform;
#                                        a false sitting inside a Build/Platform workspace fails
#                                        closed (ANALYSIS_REQUIRED_FALSE_CONTRADICTS_PLAY_LEVEL.P1).
#      - PRESENT but unparseable     -> an unsubstituted [ANALYSIS_REQUIRED] placeholder or other
#                                        non-true/false rendering fails closed on Build/Platform —
#                                        P3: inability to determine is a finding, not a pass
#                                        (ANALYSIS_REQUIRED_UNPARSEABLE.P1).
#      - ABSENT, speck_version < 11  -> genuinely pre-v11; stays advisory.
#      - ABSENT, speck_version >= 11 -> the frontmatter self-identifies as v11-shaped, so absence
#                                        is a malformed file, not evidence of pre-v11 vintage; fails
#                                        closed on Build/Platform (ANALYSIS_REQUIRED_MISSING_ON_V11.P1).

set -euo pipefail

# shellcheck source=../lib/text.sh
. "$(dirname "$0")/../lib/text.sh"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

STORY_DIR="${1:-}"

if [[ -z "$STORY_DIR" ]]; then
  echo -e "${RED}Error: Please specify the story directory path.${NC}"
  echo "Usage: $0 <specs/projects/PROJECT_ID/epics/EPIC_ID/stories/STORY_ID>"
  exit 1
fi

if [[ ! -d "$STORY_DIR" ]]; then
  echo -e "${RED}Error: Story directory does not exist: $STORY_DIR${NC}"
  exit 1
fi

story_id=$(basename "$STORY_DIR")
failed=false

echo -e "🥓 Checking pre-implementation prerequisites for story ${story_id}...\n"

# 1. Check spec.md
spec_path="${STORY_DIR}/spec.md"
if [[ ! -f "$spec_path" ]]; then
  echo -e "${RED}❌ Missing spec.md${NC}"
  failed=true
else
  # Verify lifecycle state is Specified
  if grep -q -i -E '(current[ -]?state|status|lifecycle(_state)?)\**:[[:space:]]*Specified' "$spec_path" || grep -q -i "state:[[:space:]]*Specified" "$spec_path"; then
    echo -e "${GREEN}✅ spec.md is present and lifecycle state is 'Specified'${NC}"
  else
    echo -e "${YELLOW}⚠️  spec.md is present but lifecycle state is NOT 'Specified'. Found:${NC}"
    found_state=$(grep -i -E "(current[ -]?state|status|lifecycle(_state)?|state)\**:" "$spec_path" | head -n 1 || echo "None")
    echo "   $found_state"
    failed=true
  fi
fi

# 2. Check plan.md
plan_path="${STORY_DIR}/plan.md"
if [[ ! -f "$plan_path" ]]; then
  echo -e "${RED}❌ Missing plan.md${NC}"
  failed=true
else
  echo -e "${GREEN}✅ plan.md is present${NC}"
fi

# 3. Check tasks.md
tasks_path="${STORY_DIR}/tasks.md"
if [[ ! -f "$tasks_path" ]]; then
  echo -e "${RED}❌ Missing tasks.md${NC}"
  failed=true
else
  echo -e "${GREEN}✅ tasks.md is present${NC}"
fi

# 4. Restored guard (main had this unconditionally, before the v11 analysis_required flag
#    existed): any analysis report already on disk, under any of the three legacy/canonical
#    filenames, is scanned for unresolved CRITICAL items — regardless of what tasks.md's
#    analysis_required flag says. The v11 rewrite nested this scan inside the
#    analysis_required==true branch only, so a report sitting in the story dir with a live open
#    CRITICAL stopped blocking implementation the moment tasks.md declared false or predated the
#    field.
#
#    The scan itself is format-aware, not a single hand-rolled heuristic:
#      - a v10.3+/v11 BOUND report (frontmatter declares `artifact_type: story-analysis-report`)
#        is the canonical TABLE shape the shipped template produces (a Status cell, never a
#        checkbox). Detecting an open CRITICAL in that shape means reading the table by header
#        name, which is exactly what validate-project-analysis.sh --gate already does — so that
#        is delegated to, not re-implemented. A hand-rolled second detector here would drift from
#        the canonical one the moment either changes; only the ANALYSIS_CRITICAL_OPEN.P1 signal is
#        harvested from its output, so unrelated predicates it also checks (freshness, scope
#        drift, decorrelation width) do not leak into this unconditional guard's verdict.
#      - a genuinely pre-v10.3 (unbound) report has no frontmatter for that gate to read at all —
#        by the vintage rule the gate treats it as exempt, so it would never flag one. The original
#        checkbox/todo heuristic is kept, scoped to exactly this unbound case, since it is the only
#        thing that still sees these legacy files.
analysis_report_path=""
for possible_path in "${STORY_DIR}/analysis-report.md" "${STORY_DIR}/story-analysis-report.md" "${STORY_DIR}/story-analysis.md"; do
  if [[ -f "$possible_path" ]]; then
    analysis_report_path="$possible_path"
    break
  fi
done
analysis_gate_validator=".speck/scripts/validation/validators/validate-project-analysis.sh"
if [[ -n "$analysis_report_path" ]]; then
  # Delegation requires tasks.md too: validate-project-analysis.sh --gate infers story-vs-epic
  # level by checking for BOTH spec.md and tasks.md in the target dir (gate_mode). Without
  # tasks.md it would misclassify STORY_DIR as epic level (the path also matches "/epics/") and
  # look for the wrong report filename, silently missing the very report found above. tasks.md's
  # own presence was already checked as step 3; this only guards the delegation choice.
  if [[ "$(basename "$analysis_report_path")" == "story-analysis-report.md" ]] \
     && grep -qE '^artifact_type:[[:space:]]*"?story-analysis-report"?[[:space:]]*$' "$analysis_report_path" \
     && [[ -f "$analysis_gate_validator" ]] \
     && [[ -f "$tasks_path" ]]; then
    gate_out="$(bash "$analysis_gate_validator" --gate "$STORY_DIR" 2>&1)" || true
    critical_line="$(grep 'ANALYSIS_CRITICAL_OPEN\.P1' <<<"$gate_out" || true)"
    if [[ -n "$critical_line" ]]; then
      echo -e "${RED}❌ Unresolved CRITICAL issues found in $(basename "$analysis_report_path") (validate-project-analysis.sh --gate):${NC}"
      echo "$critical_line" | sed 's/^/   /'
      failed=true
    else
      echo -e "${GREEN}✅ $(basename "$analysis_report_path") is present with no unresolved CRITICAL items (verified via validate-project-analysis.sh --gate)${NC}"
    fi
  else
    criticals=$(grep -i "CRITICAL" "$analysis_report_path" | grep -v "✅" | grep -v "\[x\]" | grep -E "\[[[:space:]]\]|todo" || true)
    if [[ -n "$criticals" ]]; then
      echo -e "${RED}❌ Unresolved CRITICAL issues found in $(basename "$analysis_report_path"):${NC}"
      echo "$criticals" | sed 's/^/   /'
      failed=true
    else
      echo -e "${GREEN}✅ $(basename "$analysis_report_path") is present with no unresolved CRITICAL items${NC}"
    fi
  fi
fi

# 5. The decorrelated story-analysis gate for task files created by v11.
#
# The field is PARSED, not string-matched. v11 tasks.md renders analysis_required through a
# template substitution step that can leave it quoted ("true"), YAML-1.1-cased (True), trailing-
# commented (true  # Build/Platform), or — if that substitution step never ran — literally
# unsubstituted ([ANALYSIS_REQUIRED], shipped verbatim at
# .speck/templates/story/tasks-template.md:7). A regex anchored on the bare lowercase literal
# misses every one of those and fell through to the advisory branch meant for tasks.md files that
# predate the field entirely.
#
# Every state this field can be in is enumerated in the header comment at the top of this file.
#
# Shared play_level walk-up: read the workspace .speck/project.json, the same lookup and the
# same Platform back-compat default check-epic-prereqs.sh uses (.speck/README.md:187 — "No
# project.json = treated as Platform"; an unknown level should make a gate RUN, not vanish).
# Reused by every branch below that needs to know whether the live workspace actually requires
# story analysis, rather than trusting whatever tasks.md's own self-declared field claims.
resolve_live_play_level() {
  local dir="$1" level="platform" cur declared_level
  cur="$(cd "$dir" && pwd)"
  while [[ "$cur" != "/" ]]; do
    if [[ -f "$cur/.speck/project.json" ]]; then
      declared_level="$(grep -o '"play_level"[[:space:]]*:[[:space:]]*"[^"]*"' "$cur/.speck/project.json" 2>/dev/null \
        | sed -E 's/.*"([^"]*)"$/\1/' || true)"
      declared_level="$(sp_trim "$declared_level")"
      [[ -n "$declared_level" ]] && level="$(printf '%s' "$declared_level" | tr '[:upper:]' '[:lower:]')"
      break
    fi
    cur="$(dirname "$cur")"
  done
  printf '%s' "$level"
}

analysis_field_present=false
analysis_field_state="invalid"
analysis_value=""
tasks_speck_major=""
if [[ -f "$tasks_path" ]]; then
  # speck_version is read regardless of whether analysis_required is present: it is what tells
  # an absent key apart from a genuinely pre-v11 file (see the ABSENT branch below).
  tasks_speck_major="$(grep -m1 -E '^speck_version:' "$tasks_path" \
    | sed -E 's/^speck_version:[[:space:]]*"?v?([0-9]+).*/\1/' || true)"
  [[ "$tasks_speck_major" =~ ^[0-9]+$ ]] || tasks_speck_major=""

  analysis_line="$(grep -m1 -E '^analysis_required:' "$tasks_path" || true)"
  if [[ -n "$analysis_line" ]]; then
    analysis_field_present=true
    analysis_value="${analysis_line#analysis_required:}"
    analysis_value="${analysis_value%%#*}"          # drop a trailing comment
    analysis_value="$(sp_trim "$analysis_value")"
    if [[ "$analysis_value" =~ ^\"(.*)\"$ ]]; then
      analysis_value="${BASH_REMATCH[1]}"           # unwrap "double quotes"
    elif [[ "$analysis_value" =~ ^\'(.*)\'$ ]]; then
      analysis_value="${BASH_REMATCH[1]}"           # unwrap 'single quotes'
    fi
    case "$(printf '%s' "$analysis_value" | tr '[:upper:]' '[:lower:]')" in
      true)  analysis_field_state="true" ;;
      false) analysis_field_state="false" ;;
    esac
  fi
fi

analysis_required=false
if [[ "$analysis_field_state" == "true" ]]; then
  analysis_required=true
fi

if [[ "$analysis_required" == true ]]; then
  analysis_validator=".speck/scripts/validation/validators/validate-project-analysis.sh"
  template_validator=".speck/scripts/validation/validate-template.sh"
  analysis_report="${STORY_DIR}/story-analysis-report.md"
  if [[ ! -f "$analysis_validator" || ! -f "$template_validator" ]]; then
    echo -e "${RED}❌ Story analysis validators are unavailable.${NC}"
    failed=true
  elif [[ ! -f "$analysis_report" ]]; then
    echo -e "${RED}UNANALYZED_CORPUS.P1  story-analysis-report.md does not exist. Run /analyze --level story.${NC}"
    failed=true
  else
    structural_rc=0
    structural_out="$(bash "$template_validator" --strict "$analysis_report" 2>&1)" || structural_rc=$?
    printf '%s\n' "$structural_out"
    analysis_rc=0
    analysis_out="$(bash "$analysis_validator" --gate "$STORY_DIR" 2>&1)" || analysis_rc=$?
    printf '%s\n' "$analysis_out"
    if [[ "$structural_rc" -ne 0 || "$analysis_rc" -ne 0 ]]; then
      echo -e "${RED}❌ Required story analysis has not cleared.${NC}"
      failed=true
    else
      echo -e "${GREEN}✅ Required story analysis is present and clear${NC}"
    fi
  fi
elif [[ "$analysis_field_state" == "false" ]]; then
  # analysis_required is self-declared: the story-tasks skill writes it FROM the live play_level
  # at generation time (references/spine.md: "Set analysis_required: false for Sprint and true for
  # Build/Platform"), but this field is never re-derived here — it is trusted verbatim. A false
  # declaration sitting inside a workspace whose LIVE play_level is Build/Platform is exactly the
  # stale-or-tampered case that self-declaration cannot catch on its own: cross-check it against
  # the same live .speck/project.json every other branch in this gate already trusts.
  play_level="$(resolve_live_play_level "$STORY_DIR")"
  if [[ "$play_level" == "build" || "$play_level" == "platform" ]]; then
    echo -e "${RED}❌ ANALYSIS_REQUIRED_FALSE_CONTRADICTS_PLAY_LEVEL.P1  tasks.md declares analysis_required: false, but this workspace's live play_level is ${play_level}, which always requires story analysis (AGENTS.md: 'analyze(story), required Build/Platform'). A self-declared false cannot waive a mandatory gate its own workspace requires — it is either stale or was copied from a different tier. Fix the value to true and run /analyze --level story, or confirm .speck/project.json's play_level is genuinely sprint for this workspace.${NC}"
    failed=true
  else
    echo -e "${GREEN}✅ Sprint tasks declare story analysis not required${NC}"
  fi
elif [[ "$analysis_field_present" == true ]]; then
  # The key is present but its value is neither a genuine true nor false — an unsubstituted
  # [ANALYSIS_REQUIRED] placeholder or some other malformed rendering. Whether that blocks depends
  # on whether this project actually needs the gate.
  play_level="$(resolve_live_play_level "$STORY_DIR")"
  if [[ "$play_level" == "build" || "$play_level" == "platform" ]]; then
    echo -e "${RED}❌ ANALYSIS_REQUIRED_UNPARSEABLE.P1  tasks.md's analysis_required value ('${analysis_value}') is not a valid true/false — an unsubstituted [ANALYSIS_REQUIRED] placeholder or other malformed rendering cannot silently waive the mandatory story analysis. This project's play_level is ${play_level}, which requires it. Fix the value to true/false, or run /analyze --level story.${NC}"
    failed=true
  else
    echo -e "${YELLOW}⚠️  tasks.md's analysis_required value ('${analysis_value}') does not parse as true/false; treating as advisory because this project's play_level is ${play_level}.${NC}"
  fi
elif [[ -n "$tasks_speck_major" && "$tasks_speck_major" -ge 11 ]]; then
  # The key is ABSENT, but tasks.md's own frontmatter self-identifies as speck_version 11+ — the
  # exact version that introduced analysis_required (see the header comment above). Absence is
  # not evidence of pre-v11 vintage when the file's own frontmatter says otherwise two lines away;
  # treat this the same as a present-but-unparseable value rather than the genuinely pre-v11
  # advisory path, which is the cheaper escape hatch (`sed -i '/analysis_required/d'`) this closes.
  play_level="$(resolve_live_play_level "$STORY_DIR")"
  if [[ "$play_level" == "build" || "$play_level" == "platform" ]]; then
    echo -e "${RED}❌ ANALYSIS_REQUIRED_MISSING_ON_V11.P1  tasks.md declares speck_version: ${tasks_speck_major}.x.x (v11+) but carries no analysis_required key at all — that self-identifies this file as v11-shaped, so absence is a malformed file, not evidence of pre-v11 vintage. This project's play_level is ${play_level}, which requires it. Add analysis_required: true or false, or run /analyze --level story.${NC}"
    failed=true
  else
    echo -e "${YELLOW}⚠️  tasks.md declares speck_version: ${tasks_speck_major}.x.x but carries no analysis_required key; treating as advisory because this project's play_level is ${play_level}.${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  This pre-v11 tasks.md does not declare analysis_required; story analysis remains advisory for this already-planned story.${NC}"
fi

# 6. Witness-graph forcing gate (v9): the story must be non-dangling AND trace UP to a promise,
#    with zero dangling refs in its subtree — an orphan specified-but-unwired story blocks implement.
#    Migration-aware: an epic that hasn't adopted a promise ledger yet GUIDES (never walls) greenfield.
#
#    v10.1 (issue #96 finding 3): `gate` now also computes graph FRESHNESS and reports it here.
#    Read-only — it compares a content signature and never rebuilds, so this stays safe in a
#    read-only CI checkout and leaves any tree-clean assertion intact. Staleness is surfaced and
#    NEVER blocks: a hard freshness gate on every /story-implement would fire on rot nobody in
#    this story caused and would teach `--no-verify` inside a day. Guide-rail, not wall.
graph_py=".speck/scripts/graph/speck_graph.py"
if command -v python3 >/dev/null 2>&1 && [[ -f "$graph_py" ]]; then
  # derive PROJECT_DIR (…/specs/projects/<id>) and STORY_ID (<epic>/<story>) from STORY_DIR
  proj_dir="${STORY_DIR%%/epics/*}"
  rest="${STORY_DIR#*/epics/}"                       # <epic-dir>/stories/<story-dir>
  epic_dir="${rest%%/stories/*}"; story_dir="${rest##*/stories/}"
  story_num="$(printf '%s' "${story_dir%%/*}" | grep -oE '^S[0-9]+' || true)"
  graph_story_id="${epic_dir}/${story_num}"          # canonical node id: <epic-basename>/S###
  if [[ -d "$proj_dir" && "$STORY_DIR" == *"/epics/"* ]]; then
    echo -e "${YELLOW}🔍 Witness-graph reachability + freshness gate (v9.0/v10.1)...${NC}"
    # Captured, not piped: under `set -o pipefail` a `cmd | grep -q` reports the PRODUCER's status,
    # so the match and the command's own failure become indistinguishable.
    if gate_out="$(python3 "$graph_py" gate "$proj_dir" --story "$graph_story_id" 2>&1)"; then
      gate_rc=0
    else
      gate_rc=$?
    fi
    printf '%s\n' "$gate_out"
    if [[ "$gate_rc" -ne 0 ]]; then
      echo -e "${RED}❌ Graph gate: this story is not legitimately wired (see above).${NC}"
      failed=true
    fi
    if grep -q "GRAPH_STALE" <<<"$gate_out"; then
      echo -e "${YELLOW}⚠️  The committed witness graph is STALE — every cap, count and 'clear to advance'${NC}"
      echo -e "${YELLOW}    you read out of it until you rebuild describes a different tree. This does NOT${NC}"
      echo -e "${YELLOW}    block implementation. Fix: python3 $graph_py build $proj_dir${NC}"
    fi
  fi
else
  echo -e "${YELLOW}⚠️  python3 or witness graph unavailable — skipping the graph reachability gate (CI is the backstop).${NC}"
fi

if [[ "$failed" == true ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}GATES REJECTED: One or more pre-implementation prerequisite checks have failed.${NC}"
  echo -e "\n${YELLOW}To begin implementation, please ensure the following steps are run first:${NC}"
  echo -e "  1. Run ${GREEN}/story-specify${NC} to create and specify the story requirements."
  echo -e "  2. Run ${GREEN}/story-plan${NC} to design the technical solution."
  echo -e "  3. Run ${GREEN}/story-tasks${NC} to generate the implementation checklist (includes consistency check at tail)."
  echo -e "  4. Run ${GREEN}/analyze --level story${NC} when tasks.md declares analysis_required: true."
  echo -e "  5. After implementation, run the separate ${GREEN}/speck-audit${NC} before validation."
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 1
else
  echo -e "\n${GREEN}🚀 PREREQUISITE GATES PASSED! Story ${story_id} is approved for implementation!${NC}"
  exit 0
fi
