---
name: story
description: Orchestrator wrapper for story-level work. Detects the current state of a story, resumes its lifecycle, and executes downstream skills step-by-step. Supports --interactive, --from, --skip. Stops ONLY at true decision gates or high-severity findings (P0/P1 drift/errors).
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument:

$ARGUMENTS

## Purpose

`/story` is the **story-level stateful orchestrator**. It automates the progression of a single story from specification to validation by **invoking downstream skills in canonical order** (`/story-specify` → `/story-clarify` → `/story-plan` → `/story-tasks` → `/story-implement` → `/audit` → `/story-validate` → `/larp` → `/story-retrospective`).

**Driving pattern (REQUIRED)**: For each step in `### 3. Execution Loop`, **read and fully execute** the corresponding skill's `SKILL.md` (and its template, per that skill's FIRST ACTION) before advancing. The orchestrator's job is **progression + stop-gate enforcement** — not re-implementing sub-steps from memory.

**ANTI-PATTERN (do NOT do this)**:
- ❌ Writing `spec.md`, `plan.md`, or `tasks.md` inline without loading `/story-specify`, `/story-plan`, or `/story-tasks`
- ❌ Skipping `/audit` or `/story-validate` because the orchestrator "already knows" the outcome
- ❌ Jumping to code changes without running `/story-implement` (including its prerequisite gates)
- ❌ Treating the transition map as a checklist of filenames instead of a checklist of **skills to invoke**

## Usage Syntax

```bash
/story [STORY_ID] [continue | --from <state> | --interactive | --skip <command>]
```

## Lifecycle States

A story's lifecycle in Speck is defined by its specs, tasks, and validation state:

1. **Draft (Placeholder)**: Listed in `epic-breakdown.md` but has no story folder or only carries an empty draft spec.
2. **Specified**: Completed `/story-specify` and `/story-clarify`. `spec.md` is complete with user stories, Gherkin scenarios, and is marked as `Specified`.
3. **Planned**: Completed `/story-plan` and generated `plan.md`, `data-model.md` (if database), and API contracts (if applicable).
4. **Tasked**: Completed `/story-tasks` and generated `tasks.md` with structured phases and sequential/parallel tasks, **including the spec↔plan↔tasks consistency cross-check at its tail** (the pre-impl job of the retired `/story-analyze`).
5. **Implemented**: Completed `/story-implement` and marked all tasks as `[X]` in `tasks.md` with status set to `completed` in frontmatter.
6. **Audited (Post-impl)**: Completed `/audit` post-implementation and generated `audit-report.md`.
7. **Validated**: Completed `/story-validate` and `/larp` (if UI), and generated a stamped `validation-report.md` claiming a verified readiness state.
8. **Done**: Completed `/story-retrospective` and created `story-retro.md` with learning-tagged commits.

---

## Execution Steps

### 1. Locate the Story and Detect Current State

Find the story directory `specs/projects/<PROJECT_ID>/epics/[EPIC_ID]/stories/[STORY_ID]`.
If `[STORY_ID]` is missing from arguments, check `project-state.md` or `epic-breakdown.md` for the current active story.

Read `spec.md` and evaluate its state:
- If `spec.md` doesn't exist → State = **Draft (Needs Specify)**.
- If `spec.md` exists and contains `**Current State**: Draft` → State = **Draft (Needs Specify)**.
- If `spec.md` contains `**Current State**: Specified` but no `plan.md` exists → State = **Specified (Needs Plan)**.
- If `plan.md` exists but no `tasks.md` exists → State = **Planned (Needs Tasks)**.
- If `tasks.md` exists and is marked `status: in_progress` or `status: pending` (not `completed`) → State = **Tasked (Needs Implement)**.
- If `tasks.md` has `status: completed` but no `audit-report.md` exists → State = **Implemented (Needs Post-impl Audit)**.
- If `audit-report.md` exists but `validation-report.md` is missing → State = **Audited (Needs Validate)**.
- If `validation-report.md` exists but `story-retro.md` is missing → State = **Validated (Needs Retrospective)**.
- If `story-retro.md` exists → State = **Done**.

### 2. Handle Execution Flags

- `--from <state>`: Force start from a specific state, overriding auto-detection.
- `--interactive`: Prompt the user for approval before transitioning between major states.
- `--skip <command>`: Skip a specific step. **CRITICAL REQUIREMENT**: Log an explicit technical rationale to `project-decisions-log.md` detailing the tradeoff and safety verification.
- `continue`: Resume from the auto-detected active state.

### 3. Execution Loop (The Transition Map)

For **each** transition below: **invoke the listed skill** (read `.cursor/skills/<skill>/SKILL.md`, follow its procedure end-to-end), then evaluate stop conditions before advancing.

Run the appropriate skills in order. After each command completes successfully, evaluate whether a stop condition is met before transitioning.

```
State: Draft         →  Run: /story-specify  →  Clarify (/story-clarify)
                             ↳ STOP if user clarification required.
                               Transition to state: Specified

State: Specified     →  Run: /story-plan
                             ↳ STOP if technical unknowns require research or user decisions.
                               Transition to state: Planned

State: Planned       →  Run: /story-tasks    →  If UI: /story-ui-spec
                             ↳ /story-tasks ends with the spec↔plan↔tasks consistency cross-check.
                             ↳ STOP if any CRITICAL conflict surfaces there.
                               Transition to state: Tasked

State: Tasked        →  Run: /story-implement (writes code)
                             ↳ STOP if test suite or compilation fails.
                               Transition to state: Implemented

State: Implemented   →  Run: /audit
                             ↳ STOP if any P0/P1 issues found post-implementation.
                               Transition to state: Audited (Post-impl)

State: Audited (Post) → Run: /story-validate  →  If UI: /larp
                             ↳ STOP if first-time user comprehension fails or verified state is capped.
                               Transition to state: Validated

State: Validated     →  Run: /story-retrospective
                               Transition to state: Done
```

### 4. Hard Stop Conditions

Do NOT transition automatically and stop immediately if any of these occur:
1. **Unresolved Clarifications**: Any `[NEEDS CLARIFICATION]` markers in `spec.md` or plans.
2. **Critical/P0 Findings**: Any P0 findings returned by the `/story-tasks` consistency cross-check, `/audit`, or failed assertions in `/story-validate`.
3. **Compilation, Test, or Gate Failures**: Any failure in compiling, running tests, or executing the project's full pre-commit gate (lint/eslint, typecheck, banned-language).
4. **Comprehension Block**: Fails first-time user comprehension, capping readiness state.

---

## Behavior Rules

- **ALWAYS** check that the story's parent epic is currently active and has not been locked out by other outstanding epic validations.
- **ALWAYS** invoke downstream skills by reading their `SKILL.md` — never substitute inline artifact authoring for a skipped skill step. Emitting a template-shaped `spec.md` / `validation-report.md` without running the skill is **simulation, not progress** — it passes superficial checks while bypassing the rigor.
- **NEVER** advance Audited → Validated on mere `validation-report.md` presence. Require the report template-compliant (`validate-template.sh --strict`) AND produced by a real `/story-validate` + `/audit` run. A report that exists but whose skills never ran does not advance state.
- **NEVER** let an agent jump directly to `/story-implement` without running `/story-implement` (including `check-story-prereqs.sh` gate).
- **ALWAYS** regenerate `project-state.md` upon any state transition.
- **When run as a delegated sub-agent** (background/worktree): do NOT stop at a downstream skill's closing "next steps" menu — that menu is not a turn boundary; proceed to the next state. On completion, return the contract `{ readiness_state, pass, p0p1, artifact_paths, skills_invoked, gate_checks }` so the conductor's Verify-Skills Gate can confirm the skills actually ran and the full pre-commit gate passed.
- Provide a clear progress bar or status line (e.g. `[Tasks 🟢] → [Implementing 🟡] → [Audit ⚪]`) in each reply.
