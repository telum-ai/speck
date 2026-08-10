#!/usr/bin/env bash

# Speck Git Pre-Commit Hook Guard
# Intercepts git commit and validates staged markdown specifications + root README.
#
# To skip intentionally: git commit --no-verify (Git prints a bypass warning).
# Use only for chore commits with known false positives or emergency fixes.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🥓 Running Speck Git pre-commit validation...${NC}"

staged_specs=()
staged_readme=false

while IFS= read -r file; do
  if [[ "$file" == "README.md" && -f "$file" ]]; then
    staged_readme=true
  elif [[ "$file" == *"specs/"* && "$file" == *".md" && -f "$file" ]]; then
    staged_specs+=("$file")
  fi
done < <(git diff --cached --name-only --diff-filter=ACM || true)

errors=0

# ── Staged-scoped two-carrier check (#103) ───────────────────────────────────────────────────
# THIS BLOCK SITS ABOVE THE EARLY EXIT ON PURPOSE, and that placement is the whole point of the
# wiring. Its subject is STAGED SHELL FILES; the early exit below fires whenever no spec markdown
# and no README are staged — which is the description of an ordinary code-only commit, i.e. the
# exact commit that can introduce a positional table reader. Placed below the exit, this check
# would be authored, correct, and structurally unreachable for its entire population: #93 class 1
# ("a guard that never executes, because a broad adjacent default shadows it"), whose named
# instance is a Speck pre-commit block placed after another `exit` in this same file. Reach is
# proven, not assumed, by driving the hook with only a .sh file staged.
#
# WHAT IT CATCHES. A shell script that reads a markdown pipe-table by HARD-CODED COLUMN POSITION
# is destructive in the interval between a schema edit and a reader edit — the two ride different
# clocks and every gate is green on both sides of the window.
#
# WHY STAGED-SCOPED AND ADVISORY. A repo-wide scan on every commit is both slow and blocking, and
# a gate that is red on arrival gets bypassed rather than fixed. Scoped to the .sh files in THIS
# commit it reports only what the author can act on right now, and the measured finding count over
# the whole `.speck/scripts` tree at v10.2 is 0 (92 files scanned, 7 table readers, all
# header-resolved) — so it is green on arrival and the first thing it can ever say is about a
# positional reader someone just wrote. ADVISORY means it never touches `errors`: the field value
# gets measured before the check is allowed to stop a commit. Promote to blocking by adding
# `errors=$((errors + 1))` in the findings branch below, once it has run clean for a release.
two_carrier=".speck/scripts/validation/validators/validate-two-carrier.sh"
if [[ -f "$two_carrier" ]]; then
  staged_sh=()
  while IFS= read -r file; do
    [[ -n "$file" && -f "$file" ]] && staged_sh+=("$file")
  done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.sh$' || true)

  if [[ ${#staged_sh[@]} -gt 0 ]]; then
    echo -e "${BLUE}🔍 Two-carrier positional-table-read check (${#staged_sh[@]} staged shell file(s))...${NC}"
    two_carrier_findings=0
    for sh_file in "${staged_sh[@]}"; do
      # Capture first, test after. `if cmd | grep -q …` hides cmd's own exit status behind the
      # pipe, which is how a check that crashed becomes a check that "found nothing".
      tc_rc=0
      tc_out="$(bash "$two_carrier" --strict "$sh_file" 2>&1)" || tc_rc=$?
      if [[ $tc_rc -eq 1 ]]; then
        two_carrier_findings=$((two_carrier_findings + 1))
        echo "$tc_out"
      elif [[ $tc_rc -ne 0 ]]; then
        echo -e "${YELLOW}⚠ two-carrier check could not run on $sh_file (exit $tc_rc) — NOT counted as clean.${NC}"
      fi
    done
    if [[ $two_carrier_findings -gt 0 ]]; then
      echo -e "${YELLOW}⚠ ADVISORY: $two_carrier_findings staged shell file(s) read a markdown pipe-table by hard-coded position.${NC}"
      echo -e "${BLUE}   Resolve the column index from the header row's NAME first (reference shape:${NC}"
      echo -e "${BLUE}   validate-gate-liveness.sh's resolve_columns_from_header). Not blocking — advisory at v10.2.${NC}"
    else
      echo -e "${GREEN}✓ No positional pipe-table readers among the staged shell files.${NC}"
    fi
  fi
fi

# ── Staged-scoped bound-fusion check (#93 class 3) ───────────────────────────────────────────
# ALSO ABOVE THE EARLY EXIT, for the same reason: its trigger is an edit to Speck's own gate
# machinery — a validator or the validation-report template — which is a code commit, exactly what
# the early exit below discards.
#
# WHAT IT DEFENDS. Speck's readiness ladder has an existence floor (NO-SHIP / IMPL-GREEN /
# INTEGRATION-GREEN: does the code exist, run, integrate) and quality rungs above it (UX-RC+,
# gated on FELT-GOOD / TASTE). Nothing structural keeps the quality axes off the existence floor —
# only two files independently continuing to scope their enforcement to `UX-RC|…`. Widening one of
# those `case` arms is a one-token edit that reads as a tightening, and the day it lands, a
# built-but-rough story and a never-built story emit the same verdict: the quality bar has annexed
# the go/no-go and the gate can no longer fail loudly (#93 class 3).
#
# TRIGGERED, NOT CONSTANT. The check reads the machinery, not the commit, so running it on every
# commit would be noise; running it when someone edits that machinery is when its answer can
# actually have changed. It is ADVISORY at v10.2 for the same reason as the two-carrier block.
bound_fusion=".speck/scripts/validation/validators/validate-bound-fusion.sh"
if [[ -f "$bound_fusion" ]]; then
  machinery_touched=""
  while IFS= read -r file; do
    [[ -n "$file" ]] && machinery_touched="yes"
  done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null \
    | grep -E '^\.speck/(scripts/validation/validators/.*\.sh|templates/story/validation-report-template\.md)$' || true)

  if [[ -n "$machinery_touched" ]]; then
    echo -e "${BLUE}🔍 Bound-fusion check (quality vs. existence rungs — gate machinery was edited)...${NC}"
    bf_rc=0
    bf_out="$(bash "$bound_fusion" --strict . 2>&1)" || bf_rc=$?
    if [[ $bf_rc -eq 1 ]]; then
      echo "$bf_out"
      echo -e "${YELLOW}⚠ ADVISORY: a quality bound may now reach the existence floor (#93 class 3).${NC}"
      echo -e "${BLUE}   Separate the two bounds; never raise the bar. Not blocking — advisory at v10.2.${NC}"
    elif [[ $bf_rc -ne 0 ]]; then
      echo -e "${YELLOW}⚠ bound-fusion check could not run (exit $bf_rc) — NOT counted as clean.${NC}"
    else
      echo -e "${GREEN}✓ Quality bounds stay above the existence floor.${NC}"
    fi
  fi
fi

# ── Staged-scoped banned-language lint (#109) ────────────────────────────────────────────────
# THE THIRD BLOCK ABOVE THE EARLY EXIT, and it belongs here for the reason the two-carrier comment
# already spells out — it just wasn't applied to this one. Banned language lives in SOURCE FILES
# carrying user-visible copy, not in spec markdown, so the gate's entire population is the ordinary
# code-only commit: exactly the commit the exit below discards. Placed under it, the gate was
# authored, correct, wired, and structurally unreachable for every commit it exists to guard —
# #93 class 1, in the very file whose comment names that class.
#
# The silence was the worse half. The hook printed "✓ No Speck specifications or README staged for
# commit." and never mentioned the lint, so a commit that was never scanned and a commit that
# scanned clean produced the same output. Nothing said it did not run.
#
# BLOCKING, unlike the two advisory blocks above it: this one has been blocking since it was
# written, and reaching its real population is a fix to its wiring, not a new bar. A project that
# also chains this lint from its own .husky/pre-commit now runs it twice on spec commits — cheap,
# and harmless.
if [[ -f ".speck/scripts/banned-language-lint.sh" ]]; then
  echo -e "${BLUE}🔍 Running staged banned-language lint...${NC}"
  if ! bash .speck/scripts/banned-language-lint.sh --staged; then
    echo -e "${RED}❌ Banned-language violations in staged files.${NC}"
    errors=$((errors + 1))
  fi
fi

# The early exit cannot stand between a block above it and the error report below it: a
# banned-language finding on a code-only commit would be counted and then discarded unread.
if [[ $errors -gt 0 && ${#staged_specs[@]} -eq 0 && "$staged_readme" == false ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}ERROR: Commit rejected. Found $errors non-compliant file(s).${NC}"
  echo -e "${YELLOW}Please fix the validation errors shown above before committing.${NC}"
  echo -e "${BLUE}Note: If you need to force-commit (not recommended), use 'git commit --no-verify'.${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
  exit 1
fi

# Early-exit when no spec/README is staged, before referencing the array (set -u safe).
# Anything scoped to non-spec files must run ABOVE this line — see the two-carrier,
# bound-fusion and banned-language blocks.
if [[ ${#staged_specs[@]} -eq 0 && "$staged_readme" == false ]]; then
  echo -e "${GREEN}✓ No Speck specifications or README staged for commit.${NC}"
  exit 0
fi

# Bash 3+ safe array expansion when the array may be empty under `set -u`
# Note: traceability-matrix.md is covered here too — validate-template.sh routes it to
# validate-traceability-matrix.sh (default/conservation mode) by filename.
if [[ ${#staged_specs[@]} -gt 0 ]]; then
  for spec in "${staged_specs[@]}"; do
    echo -e "${BLUE}🔍 Validating: $spec...${NC}"
    if ! bash .speck/scripts/validation/validate-template.sh --strict "$spec"; then
      echo -e "${RED}❌ Validation failed for $spec.${NC}"
      errors=$((errors + 1))
    fi
  done
fi

if [[ "$staged_readme" == true ]]; then
  echo -e "${BLUE}🔍 Validating: README.md (PROFILE)...${NC}"
  if ! bash .speck/scripts/validation/validate-profile.sh --strict; then
    echo -e "${RED}❌ Validation failed for README.md.${NC}"
    errors=$((errors + 1))
  fi
fi

# Witness-graph reference integrity (v9): reject a staged spec/matrix edit that introduces a
# dangling reference against an ADOPTED id scheme. You cannot commit rot in. Migration-aware:
# un-adopted schemes surface as guidance (GRAPH_UNMIGRATED), never a block — greenfield is safe.
graph_py=".speck/scripts/graph/speck_graph.py"
if command -v python3 >/dev/null 2>&1 && [[ -f "$graph_py" ]]; then
  staged_specs=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null \
    | grep -E '^specs/projects/[^/]+/(epics/[^/]+/(traceability-matrix\.md|stories/[^/]+/spec\.md)|.*)$' || true)
  if [[ -n "$staged_specs" ]]; then
    # collect the distinct project dirs touched, lint-refs each (real DANGLING/DUP block; unmigrated guides)
    proj_dirs=$(printf '%s\n' "$staged_specs" | sed -E 's#(specs/projects/[^/]+)/.*#\1#' | sort -u)
    while IFS= read -r pd; do
      [[ -d "$pd" ]] || continue
      echo -e "${BLUE}🔍 Witness-graph reference integrity: ${pd}...${NC}"
      if ! python3 "$graph_py" lint-refs "$pd"; then
        echo -e "${RED}❌ Staged edit introduces or leaves a dangling reference (see above).${NC}"
        errors=$((errors + 1))
      fi
    done <<< "$proj_dirs"
  fi
fi

# ── Wave safety on a staged epics.md (#105) — ADVISORY THIS RELEASE ──────────────────────────
# The validator had exactly one caller before v10.3, and it was a line of prose in a SKILL.md. That
# is why #105 arrived as "the validator crashes" rather than as "a wave went unchecked for months":
# nothing on the commit path ever ran it, so its false negative was invisible by construction.
#
# WHY ADVISORY, and this is a disclosed half-measure rather than a preference. The bug being fixed
# is a FALSE NEGATIVE: an annotated `Yes (…)` cell silently skipped collision checking. So the fixed
# validator sees collisions that the broken one hid — real ones, in plans that have read green for
# their whole life. Blocking on arrival would turn green→red on the upgrade commit, for a collision
# the author did not introduce and in a file they may not have touched. That is the direction this
# repo's upgrade-day doctrine refuses, and a gate that is red on arrival gets bypassed, not fixed.
# It never touches `errors`. Promote it to blocking by adding `errors=$((errors + 1))` in the
# findings branch, once the field has run a release with it printing.
wave_safety=".speck/scripts/validation/validators/validate-wave-safety.sh"
if [[ -f "$wave_safety" ]]; then
  staged_epics=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null \
    | grep -E '^specs/projects/[^/]+/epics\.md$' || true)
  if [[ -n "$staged_epics" ]]; then
    while IFS= read -r em; do
      [[ -f "$em" ]] || continue
      echo -e "${BLUE}🔍 Wave safety (advisory): ${em}...${NC}"
      ws_rc=0
      bash "$wave_safety" "$em" || ws_rc=$?
      if [[ $ws_rc -eq 1 ]]; then
        echo -e "${YELLOW}⚠ Wave-safety findings above are ADVISORY in v10.3 — this commit is not blocked.${NC}"
        echo -e "${YELLOW}  Re-sequence the waves or apply the schema-freeze foundation pattern.${NC}"
        echo -e "${YELLOW}  Do NOT de-annotate the wave table to silence this: the annotation is not the defect.${NC}"
      elif [[ $ws_rc -ne 0 ]]; then
        echo -e "${YELLOW}⚠ wave-safety check could not run (exit $ws_rc) — NOT counted as clean.${NC}"
      fi
    done <<< "$staged_epics"
  fi
fi

# ── The project-analysis gate on a staged epic.md (#106) — BLOCKING, grandfathered backward ──
# epic.md is the OUTPUT of /epic-specify, so staging one is the observable moment the planning
# corpus starts being built on. That makes it the honest trigger: the gate asks "was this corpus
# independently analyzed before anyone built on it?", and this is the first commit where the answer
# matters.
#
# This one DOES block, and the asymmetry is deliberate and disclosed. A project planned before v10.3
# carries a `.analysis-gate-grandfathered` marker written by the upgrade migration and gets a loud,
# repeated notice instead of a rejection — it could not have satisfied a gate that did not exist.
# A project planned after v10.3 has no marker and is rejected. Real forward, advisory backward; the
# marker expires by itself the first time /analyze --level project runs, because the gate consults it only
# when the report is absent.
#
# Applicability is the script's job, not this hook's: it exits 0 with an explicit "not applicable"
# line for Build projects under 4 epics. This block never decides who is in scope — asking the
# question here as well would be a second producer of the threshold, and the two would drift.
epic_prereqs=".speck/scripts/validation/check-epic-prereqs.sh"
if [[ -f "$epic_prereqs" ]]; then
  staged_epic_md=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null \
    | grep -E '^specs/projects/[^/]+/epics/[^/]+/epic\.md$' || true)
  if [[ -n "$staged_epic_md" ]]; then
    ep_dirs=$(printf '%s\n' "$staged_epic_md" | sed -E 's#(specs/projects/[^/]+)/epics/.*#\1#' | sort -u)
    while IFS= read -r pd; do
      [[ -d "$pd" ]] || continue
      echo -e "${BLUE}🔍 Planning-corpus analysis gate: ${pd}...${NC}"
      if ! bash "$epic_prereqs" "$pd"; then
        echo -e "${RED}❌ Epic work is gated on an independent /analyze --level project pass (see above).${NC}"
        errors=$((errors + 1))
      fi
    done <<< "$ep_dirs"
  fi
fi

# (The staged-scoped banned-language lint moved ABOVE the early exit — see #109 there.)

if [[ "$errors" -gt 0 ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}ERROR: Commit rejected. Found $errors non-compliant file(s).${NC}"
  echo -e "${YELLOW}Please fix the validation errors shown above before committing.${NC}"
  echo -e "${BLUE}Note: If this is a migrated project with legacy failures, run:${NC}"
  echo -e "  ${GREEN}/speck-catch-up --phase=refresh${NC} or use ${GREEN}speck validate --active-only${NC} to isolate active work."
  echo -e "${BLUE}Note: If you need to force-commit (not recommended), use 'git commit --no-verify'.${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
  exit 1
fi

echo -e "${GREEN}✓ All staged Speck artifacts are valid! Allow commit.${NC}"
exit 0
