# story-plan — procedure

Input: `$ARGUMENTS`.
Output: `[STORY_DIR]/plan.md` (+ `data-model.md`, `contracts/`, `quickstart.md` per template).
Template: `.speck/templates/story/plan-template.md`.
Prereq: `spec.md` with no unresolved `[NEEDS CLARIFICATION]` (unless user override).

## 0. Template

Read `.speck/templates/story/plan-template.md` before writing.

## 1. Locate story

Walk up to `[STORY_DIR]` containing `spec.md`. STOP if missing → `cd` to story or `/speck` route.

`SPEC_PATH=[STORY_DIR]/spec.md` · `PLAN_PATH=[STORY_DIR]/plan.md`

Unresolved `[NEEDS CLARIFICATION]` → PAUSE → `/story-clarify`.

## 2. Planning mode

| Condition | Mode |
|-----------|------|
| `[STORY_DIR]/outline.md` exists | Post-research — load Technical Context from outline + `research-report-*.md` |
| No outline | Full — derive Technical Context from spec |

Load scans: `[STORY_DIR]/codebase-scan-*.md` — all reports; brownfield → prefer refactor over duplicate.

## 3. Architecture gate

Embed detailed architecture in plan if ANY: cross-cutting; new pattern; new external dep; complex data (>3 entities); security-critical; perf targets; high ambiguity.

Minimal plan if ALL: single-file; existing patterns; standard CRUD/form.

High ambiguity → `/story-outline` first.

## 4. Load constitution + project docs

- `specs/projects/[PROJECT_ID]/constitution.md`
- `[EPIC_DIR]/constitution.md` — epic extends project; never contradicts

Load if present: `domain-model.md`, `ux-strategy.md`, `design-system.md`.

UI story: load `[EPIC_DIR]/user-journey.md`, `wireframes.md` — map stage/screen; note `/story-ui-spec` required before tasks.

Recipe `_active_recipe:` → load `visual_testing:` from recipe.yaml → note platform/strategy in plan Technical Context.

No design docs + UI story → WARN.

## 5. JIT research

Follow `.cursor/skills/just-in-time-research/SKILL.md`. Gaps: API usage, patterns, edge cases, integration, testing.

Deep research rare → PAUSE: `story-plan-research-prompt-[topic].md` → `story-plan-research-report-[topic].md` → re-run.

## 6. Balance symmetry guard

Story decrements/reserves/consumes balance, quota, credit, or inventory → SAME story MUST specify symmetric re-credit/release/refund for failure, rollback, cancellation. Never defer re-credit to a later story.

## 7. Execute plan template

Fill `plan-template.md` → `PLAN_PATH`. Embed research. Generate required phase artifacts per template progress tracking.

Verify all template phases complete; no ERROR states.

## 8. Next

| Step | When |
|------|------|
| `/story-ui-spec` | Required if UI detected — before tasks |
| `/story-tasks` | Required |
| `/story-implement` | After tasks |
| `/audit` | After implement — non-skippable |
| `/story-validate` | After audit |

## NEVER / ALWAYS

- NEVER plan with unresolved clarification markers (without override)
- NEVER split decrement/re-credit across stories
- NEVER skip constitution chain when files exist
- NEVER omit wireframe/journey reference for UI stories when artifacts exist
- ALWAYS read template first
- ALWAYS note `/story-ui-spec` gate in plan when UI detected
