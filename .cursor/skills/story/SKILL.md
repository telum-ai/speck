---
name: story
description: Story lifecycle orchestrator. Invoke only via /story.
disable-model-invocation: true
---

# story

## Purpose

`/story` is the **story-level stateful orchestrator**. It advances a story by re-reading the marked canonical Story flow in root `AGENTS.md` at every transition. `AGENTS.md` owns order; this skill owns state detection and stop-gate enforcement, never a second sequence.

**Driving pattern (REQUIRED)**: For each step in `### 3. Execution Loop`, **read and fully execute** the corresponding skill's `SKILL.md` (and its template, per that skill's FIRST ACTION) before advancing. The orchestrator's job is **progression + stop-gate enforcement** — not re-implementing sub-steps from memory.

**ANTI-PATTERN (do NOT do this)**: the four hand-rolling shortcuts are enumerated in
`.speck/reference/lifecycle-state.md`. Read them there.

## Usage Syntax

```bash
/story [STORY_ID] [continue | --from <state> | --interactive | --skip <command>]
```

## Lifecycle States and stop-gates

**MUST read before advancing any state**: `.speck/reference/lifecycle-state.md`. It carries the
state ladder, its detection rules, and the stop-gates that bind every driver. It is a reference
rather than orchestrator-internal on purpose: an autonomous loop cannot load this user-only skill,
and the stop-gates have to reach that path too. Do not restate it here — one source, both readers.

---

## Execution Steps

### 1. Locate the Story and Detect Current State

Find the story directory `specs/projects/<PROJECT_ID>/epics/[EPIC_ID]/stories/[STORY_ID]`.
If `[STORY_ID]` is missing from arguments, check `project-state.md` or `epic-breakdown.md` for the current active story.

Detect the state with the ladder in `.speck/reference/lifecycle-state.md` — its rules are
evaluated in order and the first match wins.

### 2. Handle Execution Flags

- `--from <state>`: Force start from a specific state, overriding auto-detection.
- `--interactive`: Prompt the user for approval before transitioning between major states.
- `--skip <command>`: Skip a specific step. **CRITICAL REQUIREMENT**: Log an explicit technical rationale to `project-decisions-log.md` detailing the tradeoff and safety verification.
- `continue`: Resume from the auto-detected active state.

### 3. Execution Loop (The Transition Map)

At every iteration:

1. Re-read the exact `<!-- SPECK:FLOW:START -->` block in root `AGENTS.md` and select its Story line.
2. Scan that line left-to-right. Resume at the first incomplete required slot or applicable bracketed slot; artifact-based state labels never authorize skipping an earlier slot.
3. Read `.cursor/skills/<selected-skill>/SKILL.md` and execute it end-to-end. For generic entries, use story scope.
4. Evaluate this skill's hard stops, then re-read the AGENTS flow before choosing the next slot.
5. Mark Done only after every applicable Story slot, including UI proof slots, has completed.

This keeps stateful resumption without allowing the orchestrator to drift from the always-on order. In particular, an existing `tasks.md` cannot excuse a missing applicable `story-ui-spec`, and a validation report cannot excuse missing UI LARP evidence.

### 4. Hard Stop Conditions

Do NOT transition automatically and stop immediately if any of these occur:
1. **Unresolved Clarifications**: Any `[NEEDS CLARIFICATION]` markers in `spec.md` or plans.
2. **Critical/P0 Findings**: Any P0 findings returned by the `/story-tasks` consistency cross-check, `/speck-audit`, or failed assertions in `/story-validate`.
3. **Compilation, Test, or Gate Failures**: Any failure in compiling, running tests, or executing the project's full pre-commit gate (lint/eslint, typecheck, banned-language).
4. **Comprehension Block**: Fails first-time user comprehension, capping readiness state.

---

## Behavior Rules

- **ALWAYS** check that the story's parent epic is currently active and has not been locked out by other outstanding epic validations.
- **ALWAYS** invoke downstream skills by reading their `SKILL.md` — never substitute inline artifact authoring for a skipped skill step. Emitting a template-shaped `spec.md` / `validation-report.md` without running the skill is **simulation, not progress** — it passes superficial checks while bypassing the rigor.
- **NEVER** advance Audited → Validated on mere `validation-report.md` presence. Require the report template-compliant (`validate-template.sh --strict`) AND produced by a real `/story-validate` + `/speck-audit` run. A report that exists but whose skills never ran does not advance state.
- **NEVER** let an agent jump directly to `/story-implement` without running `/story-implement` (including `check-story-prereqs.sh` gate).
- **ALWAYS** regenerate `project-state.md` upon any state transition.
- **When run as a delegated sub-agent** (background/worktree): do NOT stop at a downstream skill's closing "next steps" menu — that menu is not a turn boundary; proceed to the next state. On completion, return the contract `{ readiness_state, pass, p0p1, artifact_paths, skills_invoked, gate_checks }` so the conductor's Verify-Skills Gate can confirm the skills actually ran and the full pre-commit gate passed.
- Provide a clear progress bar or status line (e.g. `[Tasks 🟢] → [Implementing 🟡] → [Audit ⚪]`) in each reply.
