# story — spine

## Purpose

`/story` is the **story-level stateful orchestrator**. It automates the progression of a single story from specification to validation by **invoking downstream skills in canonical order** (`/story-specify` → `/story-clarify` → `/story-plan` → `/story-tasks` → `/story-implement` → `/audit` → `/story-validate` → `/larp` → `/story-retrospective`).

**Driving pattern (REQUIRED)**: For each step in `### 3. Execution Loop`, **read and fully execute** the corresponding skill's `SKILL.md` (and its template, per that skill's FIRST ACTION) before advancing. The orchestrator's job is **progression + stop-gate enforcement** — not re-implementing sub-steps from memory.

**ANTI-PATTERN (do NOT do this)**:
-  Writing `spec.md`, `plan.md`, or `tasks.md` inline without loading `/story-specify`, `/story-plan`, or `/story-tasks`
-  Skipping `/audit` or `/story-validate` because the orchestrator "already knows" the outcome
-  Jumping to code changes without running `/story-implement` (including its prerequisite gates)
-  Treating the transition map as a checklist of filenames instead of a checklist of **skills to invoke**

## Usage Syntax

```bash
/story [STORY_ID] [continue | --from <state> | --interactive | --skip <command>]
```

## Behavior Rules

- **ALWAYS** check that the story's parent epic is currently active and has not been locked out by other outstanding epic validations.
- **ALWAYS** invoke downstream skills by reading their `SKILL.md` — never substitute inline artifact authoring for a skipped skill step. Emitting a template-shaped `spec.md` / `validation-report.md` without running the skill is **simulation, not progress** — it passes superficial checks while bypassing the rigor.
- **NEVER** advance Audited → Validated on mere `validation-report.md` presence. Require the report template-compliant (`validate-template.sh --strict`) AND produced by a real `/story-validate` + `/audit` run. A report that exists but whose skills never ran does not advance state.
- **NEVER** let an agent jump directly to `/story-implement` without running `/story-implement` (including `check-story-prereqs.sh` gate).
- **ALWAYS** regenerate `project-state.md` upon any state transition.
- **When run as a delegated sub-agent** (background/worktree): do NOT stop at a downstream skill's closing "next steps" menu — that menu is not a turn boundary; proceed to the next state. On completion, return the contract `{ readiness_state, pass, p0p1, artifact_paths, skills_invoked, gate_checks }` so the conductor's Verify-Skills Gate can confirm the skills actually ran and the full pre-commit gate passed.
- Provide a clear progress bar or status line (e.g. `[Tasks 🟢] → [Implementing 🟡] → [Audit ⚪]`) in each reply.
