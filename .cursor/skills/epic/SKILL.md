---
name: epic
description: Orchestrator wrapper for epic-level work. Detects the current state of an epic, resumes its lifecycle, and executes downstream skills step-by-step. Supports --interactive, --from, --skip. Stops ONLY at true decision gates or high-severity findings (P0/P1 drift/errors).
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument:

$ARGUMENTS

## Purpose

`/epic` is the **epic-level stateful orchestrator**. It auto-detects the epic's current state and **invokes downstream skills in canonical order** (`/epic-specify`, `/epic-clarify`, `/epic-plan`, `/epic-breakdown`, `/epic-analyze`, story work via `/story`, `/audit`, `/epic-validate`, `/epic-retrospective`).

**Driving pattern (REQUIRED)**: For each step in `### 3. Execution Loop`, **read and fully execute** the corresponding skill's `SKILL.md` (and its template, per that skill's FIRST ACTION) before advancing. Story work MUST delegate to `/story` (read `.cursor/skills/story/SKILL.md`) — do not implement stories inline from the epic orchestrator.

**ANTI-PATTERN (do NOT do this)**:
- ❌ Writing `epic-tech-spec.md` or `epic-breakdown.md` inline without loading `/epic-plan` or `/epic-breakdown`
- ❌ Implementing stories directly from `/epic` without invoking `/story` for each story
- ❌ Skipping `/epic-analyze`, `/audit`, or `/epic-validate` because the orchestrator "already knows" the outcome
- ❌ Treating the transition map as a checklist of filenames instead of a checklist of **skills to invoke**

## Usage Syntax

```bash
/epic [EPIC_ID] [continue | --from <state> | --interactive | --skip <command>]
```

## Lifecycle States

An epic's lifecycle in Speck is defined by the checkboxes in `epic.md` and the presence of verified validation reports:

1. **Draft (Placeholder)**: Created by `/project-plan`. Has empty sections.
2. **Specified**: Completed `/epic-specify` and `/epic-clarify`. Gaps are filled.
3. **Planned**: Completed `/epic-plan` (`epic-tech-spec.md`) and `/epic-breakdown` (`epic-breakdown.md`).
4. **Tasked & In Progress**: Story directories created; implementation of stories is active.
5. **Stories Complete**: All stories in `epic-breakdown.md` have individual `validation-report.md` files with state >= `IMPL-GREEN`.
6. **Audited**: Epic-level `/audit` has been run and resolved.
7. **Validated (UX-RC / API-RC or higher)**: `/epic-validate` completed and produced a verified readiness state.

---

## Execution Steps

### 1. Locate the Epic and Detect Current State

Find the epic directory `specs/projects/<PROJECT_ID>/epics/[EPIC_ID]`. 
If `[EPIC_ID]` is missing from arguments, check `project-state.md` for the current active epic, or list the epics directory and ask the user to choose.

Read `epic.md` and evaluate its state:
- If `epic.md` doesn't exist → State = **Draft (Needs Specify)**.
- If `epic.md` exists and contains `**Current State**: Draft` → State = **Draft (Needs Specify)**.
- If `epic.md` contains `**Current State**: Specified` but no `epic-tech-spec.md` exists → State = **Specified (Needs Plan)**.
- If `epic-tech-spec.md` exists but no stories are implemented (check story directories) → State = **Planned (Needs Implementation)**.
- If stories are in progress → State = **In Progress**.
- If all stories in `epic-breakdown.md` are complete (each has `validation-report.md`) but no epic-level `audit-report.md` exists → State = **Stories Complete (Needs Audit)**.
- If epic-level `/audit` has been run but `epic-validation-report.md` is missing → State = **Audited (Needs Validate)**.
- If `epic-validation-report.md` exists and is stamped → State = **Validated (Done)**.

### 2. Handle Execution Flags

- `--from <state>`: Force start from a specific state, overriding the auto-detection.
- `--interactive`: Prompt the user for approval before transitioning between major states (e.g. "Draft -> Specified complete. Ready to proceed to Plan?").
- `--skip <command>`: Skip a specific step. **CRITICAL REQUIREMENT**: You MUST log an explicit technical rationale to `project-decisions-log.md` with the `--skip` reason, stating the tradeoffs and how quality is preserved.
- `continue`: Resume from the auto-detected active state.

### 3. Execution Loop (The Transition Map)

For **each** transition below: **invoke the listed skill** (read `.cursor/skills/<skill>/SKILL.md`, follow its procedure end-to-end), then evaluate stop conditions before advancing. Story work uses `/story` per story in `epic-breakdown.md` order.

Run the appropriate skills in order. After each command completes successfully, evaluate whether a stop condition is met before transitioning.

```
State: Draft         →  Run: /epic-specify  →  Validate & Clarify (/epic-clarify)
                             ↳ STOP if user clarification required.
                               Transition to state: Specified

State: Specified     →  If UI Epic: Run /epic-journey and /epic-wireframes / /epic-experience-chain
                        Run: /epic-plan     →  Run: /epic-breakdown
                             ↳ STOP if technical tradeoffs require human decision.
                               Transition to state: Planned

State: Planned       →  Run: /epic-analyze  →  Verify zero critical issues.
                             ↳ STOP if P0/P1 issues found in plans.
                        Start story implementations (delegating to /story)
                               Transition to state: In Progress

State: In Progress   →  Monitor and coordinate individual story completions.
                        Once all stories are complete:
                               Transition to state: Stories Complete

State: Stories Complete → Run: /audit --epic [EPIC_ID]
                             ↳ STOP if P0 findings exist.
                               Transition to state: Audited

State: Audited       →  Run: /epic-validate
                             ↳ STOP if validated state fails to meet targets.
                               Transition to state: Validated
```

### 4. Hard Stop Conditions

Do NOT transition automatically and stop immediately if any of these occur:
1. **Unresolved Clarifications**: Any `[NEEDS CLARIFICATION]` markers introduced in `epic.md` or specifications.
2. **Critical/P0 Findings**: Any P0 findings returned by `/epic-analyze` or `/audit` must halt the orchestrator immediately. Fix them before continuing.
3. **Validation Cap**: If `/epic-validate` is run and first-time user comprehension fails, capping the readiness state at `IMPL-GREEN`, stop and present the remediation requirements to the user.

---

## Behavior Rules

- **ALWAYS** check for the `E000` Developer Infrastructure epic first. Ensure testing and CI patterns are resolved before allowing other epics to specify.
- **ALWAYS** invoke downstream skills by reading their `SKILL.md` — never substitute inline artifact authoring for a skipped skill step.
- **ALWAYS** delegate per-story work to `/story`; the epic orchestrator coordinates sequencing, not story implementation.
- **NEVER** skip a validation check without an explicit `--skip` argument and its corresponding `project-decisions-log.md` rationale.
- **ALWAYS** regenerate `project-state.md` upon any state transition.
- Provide a clear progress bar or status line (e.g. `[Specified 🟢] → [Planning 🟡] → [Planned ⚪]`) in each reply.
