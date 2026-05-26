---
name: story
description: Orchestrator wrapper for story-level work. Detects the current state of a story, resumes its lifecycle, and executes downstream skills step-by-step. Supports --interactive, --from, --skip. Stops ONLY at true decision gates or high-severity findings (P0/P1 drift/errors).
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument:

$ARGUMENTS

## Purpose

`/story` is the **story-level stateful orchestrator**. It automates the progression of a single story from specification to validation, executing the required sequence (`/story-specify` → `/story-clarify` → `/story-plan` → `/story-tasks` → `/story-implement` → `/audit` → `/story-validate` → `/larp` → `/story-retrospective`) deterministically.

**Driving pattern**: This skill orchestrates the chain via direct file-write/edit/bash by the agent. Sub-skills (`/story-specify`, `/story-plan`, etc.) are NOT auto-invoked via a separate Skill reload — the agent follows the transition map in `### 3. Execution Loop`, reads each step's template when needed, and produces artifacts directly. This keeps context efficient while preserving canonical artifact shape.

## Usage Syntax

```bash
/story [STORY_ID] [continue | --from <state> | --interactive | --skip <command>]
```

## Lifecycle States

A story's lifecycle in Speck is defined by its specs, tasks, and validation state:

1. **Draft (Placeholder)**: Listed in `epic-breakdown.md` but has no story folder or only carries an empty draft spec.
2. **Specified**: Completed `/story-specify` and `/story-clarify`. `spec.md` is complete with user stories, Gherkin scenarios, and is marked as `Specified`.
3. **Planned**: Completed `/story-plan` and generated `plan.md`, `data-model.md` (if database), and API contracts (if applicable).
4. **Tasked**: Completed `/story-tasks` and generated `tasks.md` with structured phases and sequential/parallel tasks.
5. **Audited (Pre-impl)**: Completed `/story-analyze` (or `/audit --pre-impl`) with zero critical issues.
6. **Implemented**: Completed `/story-implement` and marked all tasks as `[X]` in `tasks.md` with status set to `completed` in frontmatter.
7. **Audited (Post-impl)**: Completed `/audit` post-implementation and generated `audit-report.md`.
8. **Validated**: Completed `/story-validate` and `/larp` (if UI), and generated a stamped `validation-report.md` claiming a verified readiness state.
9. **Done**: Completed `/story-retrospective` and created `story-retro.md` with learning-tagged commits.

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
- If `tasks.md` exists but has not been run or `/story-analyze` is missing → State = **Tasked (Needs Pre-impl Audit)**.
- If `tasks.md` exists and is marked `status: in_progress` or `status: pending` → State = **Pre-impl Audited (Needs Implement)**.
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

Run the appropriate skills in order. After each command completes successfully, evaluate whether a stop condition is met before transitioning.

```
State: Draft         →  Run: /story-specify  →  Clarify (/story-clarify)
                             ↳ STOP if user clarification required.
                               Transition to state: Specified

State: Specified     →  Run: /story-plan
                             ↳ STOP if technical unknowns require research or user decisions.
                               Transition to state: Planned

State: Planned       →  Run: /story-tasks    →  If UI: /story-ui-spec
                               Transition to state: Tasked

State: Tasked        →  Run: /story-analyze
                             ↳ STOP if any CRITICAL or P0 issues found in plan/tasks.
                               Transition to state: Audited (Pre-impl)

State: Audited       →  Run: /story-implement (writes code)
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
2. **Critical/P0 Findings**: Any P0 findings returned by `/story-analyze`, `/audit`, or failed assertions in `/story-validate`.
3. **Compilation or Test Failures**: Any test suite failure during implementation or validation.
4. **Comprehension Block**: Fails first-time user comprehension, capping readiness state.

---

## Behavior Rules

- **ALWAYS** check that the story's parent epic is currently active and has not been locked out by other outstanding epic validations.
- **NEVER** let an agent jump directly to `/story-implement` without checking if all prerequisite artifacts (`spec.md`, `plan.md`, `tasks.md`, `analysis-report.md`) exist and are valid.
- **ALWAYS** regenerate `project-state.md` upon any state transition.
- Provide a clear progress bar or status line (e.g. `[Tasks 🟢] → [Implementing 🟡] → [Audit ⚪]`) in each reply.
