# epic / phases

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
State: Draft         →  Run: bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/<PROJECT_ID>
                             ↳ STOP on exit 1 — the project-level /project-analyze gate has not cleared.
                               Route to /project-analyze; do NOT specify the epic.
                               ANALYSIS_GRANDFATHERED.P2 → surface loudly, then proceed.
                        Run: /epic-specify  →  Validate & Clarify (/epic-clarify)
                             ↳ STOP if user clarification required.
                               Transition to state: Specified

State: Specified     →  If UI Epic: Run /epic-journey and /epic-wireframes / /epic-experience-chain
                        Run: /epic-plan     →  Run: /epic-breakdown
                             ↳ STOP if technical tradeoffs require human decision.
                               Transition to state: Planned

State: Planned       →  Run: /epic-analyze  →  Verify zero critical issues.
                             Lenses MUST be decorrelated from whoever authored the epic
                             corpus — if this orchestrator's own session wrote epic-tech-spec.md
                             or epic-breakdown.md, delegate the lenses to a separate agent
                             (@speck-auditor or a separate session). Self-certification is
                             not an analysis pass.
                             ↳ STOP if P0/P1 issues found in plans.
                        Start story implementations (delegating to /story)
                               Transition to state: In Progress

State: In Progress   →  Monitor and coordinate individual story completions.
                        For EACH delegated story result, run the Verify-Skills Gate (§3a) before accepting.
                        Once all stories are complete AND verified:
                               Transition to state: Stories Complete

State: Stories Complete → Run: /audit --epic [EPIC_ID]
                             ↳ STOP if P0 findings exist.
                               Transition to state: Audited

State: Audited       →  Run: /epic-validate
                             ↳ STOP if validated state fails to meet targets.
                               Transition to state: Validated
```

### 3a. Delegated-Execution Verify Gate (accepting sub-agent story results)

When story work is delegated to background/worktree sub-agents, a sub-agent can emit template-shaped `spec.md` / `validation-report.md` with a declared readiness state **without ever invoking the skills** — it will pass every superficial check. Speck's rigor lives in the skills, so a story that produced passing-looking artifacts with zero skill calls is **simulated, not validated**.

Each delegated story sub-agent returns the contract:

```
{ readiness_state, pass, p0p1: [...], artifact_paths: [...], skills_invoked: [...], gate_checks: [{ name, pass, evidence }] }
```

Before ACCEPTING a story result (and before counting it toward "Stories Complete"), the conductor MUST:

1. **Reports exist + compliant**: `validation-report.md` (and `audit-report.md`) exist AND pass `bash .speck/scripts/validation/validate-template.sh --strict <path>`.
2. **Skills actually ran**: `skills_invoked` includes at least `speck-audit` AND `story-validate`; the conductor MUST cross-check the sub-agent's JSON transcript or execution log by grepping for `"name":"Skill"` (the host's tool call key) to confirm at least 2 real skill invocations actually ran. If empty or zero → **REJECT and re-run the story** (never accept on a self-reported state alone).
3. **Mandatory Independent Auditor**: Ensure that the story's `audit-report.md` was authored by a separate, independent auditor agent/session rather than the implementer/validator. Self-audits suffer from confirmation bias (field runs showed separate audits caught 4 critical defects across 9 stories missed by self-audits).
4. **Full pre-commit gate passed**: `gate_checks` lists passing status for eslint, typecheck, tests, build, and banned-language check (reject on any skipped or failed checks).
5. **`/audit` non-skippable**: a story merged without a real `/audit` run is rejected regardless of its self-reported state.

Self-reported fields are not tamper-evident (host-runtime limit) — the transcript check is the backstop. See AGENTS.md *Delegated execution: verify skills ran before accepting results*.

### 4. Hard Stop Conditions

Do NOT transition automatically and stop immediately if any of these occur:
1. **Unresolved Clarifications**: Any `[NEEDS CLARIFICATION]` markers introduced in `epic.md` or specifications.
2. **Critical/P0 Findings**: Any P0 findings returned by `/epic-analyze` or `/audit` must halt the orchestrator immediately. Fix them before continuing.
3. **Project analysis gate not cleared**: `check-epic-prereqs.sh` exits 1 (`UNANALYZED_CORPUS.P1`, `ANALYSIS_STALE.P1`, `ANALYSIS_CRITICAL_OPEN.P1`, `PROMISE_UNCOVERED.P1`). The epic cannot start on a planning corpus no decorrelated lens has read. `ANALYSIS_GRANDFATHERED.P2` is NOT a stop — surface it loudly and continue.
4. **Validation Cap**: If `/epic-validate` is run and first-time user comprehension fails, capping the readiness state at `IMPL-GREEN`, stop and present the remediation requirements to the user.

---
