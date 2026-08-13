---
name: epic
description: Epic lifecycle orchestrator. Invoke only via /epic.
disable-model-invocation: true
---

# epic

## Purpose

`/epic` is the **epic-level stateful orchestrator**. It advances an epic by re-reading the marked canonical Epic flow in root `AGENTS.md` at every transition. `AGENTS.md` owns order; this skill owns state detection and stop-gate enforcement, never a second sequence.

**Driving pattern (REQUIRED)**: For each step in `### 3. Execution Loop`, **read and fully execute** the corresponding skill's `SKILL.md` (and its template, per that skill's FIRST ACTION) before advancing. Story work MUST delegate to `/story` (read `.cursor/skills/story/SKILL.md`) — do not implement stories inline from the epic orchestrator.

**ANTI-PATTERN (do NOT do this)**:
-  Writing `epic-tech-spec.md` or `epic-breakdown.md` inline without loading `/epic-plan` or `/epic-breakdown`
-  Implementing stories directly from `/epic` without invoking `/story` for each story
-  Skipping `/analyze --level epic`, `/speck-audit`, or `/epic-validate` because the orchestrator "already knows" the outcome
-  Treating the transition map as a checklist of filenames instead of a checklist of **skills to invoke**

## Usage Syntax

```bash
/epic [EPIC_ID] [continue | --from <state> | --interactive | --skip <command>]
```

## Lifecycle States and stop-gates

**MUST read before advancing any state**: `.speck/reference/lifecycle-state.md` — the epic state
ladder, its detection rules, and the stop-gates binding on every driver, including an autonomous
loop that cannot load this user-only skill. Do not restate it here.

---

## Execution Steps

### 1. Locate the Epic and Detect Current State

Find the epic directory `specs/projects/<PROJECT_ID>/epics/[EPIC_ID]`. 
If `[EPIC_ID]` is missing from arguments, check `project-state.md` for the current active epic, or list the epics directory and ask the user to choose.

Read `epic.md` and evaluate its state:
Detect the state with the epic ladder in `.speck/reference/lifecycle-state.md` — its rules are
evaluated in order and the first match wins.

### 2. Handle Execution Flags

- `--from <state>`: Force start from a specific state, overriding the auto-detection.
- `--interactive`: Prompt the user for approval before transitioning between major states (e.g. "Draft -> Specified complete. Ready to proceed to Plan?").
- `--skip <command>`: Skip a specific step. **CRITICAL REQUIREMENT**: You MUST log an explicit technical rationale to `project-decisions-log.md` with the `--skip` reason, stating the tradeoffs and how quality is preserved.
- `continue`: Resume from the auto-detected active state.

### 3. Execution Loop (The Transition Map)

Before entering the Epic line, run `bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/<PROJECT_ID>`. STOP on exit 1 and route to the reported project-level prerequisite; surface `ANALYSIS_GRANDFATHERED.P2` and proceed.

At every iteration:

1. Re-read the exact `<!-- SPECK:FLOW:START -->` block in root `AGENTS.md` and select its Epic line.
2. Scan that line left-to-right. Resume at the first incomplete required slot or applicable bracketed slot; artifact-based state labels never authorize skipping an earlier slot.
3. Read `.cursor/skills/<selected-skill>/SKILL.md` and execute it end-to-end. `analyze` and `speck-audit` use epic scope; story loop work delegates to `/story` in breakdown order.
4. Apply the decorrelated-analysis and delegated-story gates below. Evaluate hard stops, then re-read the AGENTS flow before choosing the next slot.
5. Mark Done only after every applicable Epic slot, including UI proof and retrospective, has completed.

This keeps stateful resumption without allowing the orchestrator to omit optional constitution, architecture, UX, proof, or closure slots added after this skill was written.

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
5. **`/speck-audit` non-skippable**: a story merged without a real `/speck-audit` run is rejected regardless of its self-reported state.

Self-reported fields are not tamper-evident (host-runtime limit) — the transcript check is the backstop. See AGENTS.md *Delegated execution: verify skills ran before accepting results*.

### 4. Hard Stop Conditions

The stop-gates binding on every driver are in `.speck/reference/lifecycle-state.md`. One epic-level
addition applies here: if `/epic-validate` caps readiness at `IMPL-GREEN` because first-time user
comprehension failed, stop and present the remediation requirements rather than advancing.

---

## Behavior Rules

- **ALWAYS** run `check-epic-prereqs.sh` before the first `/epic-specify` of a session — the project-level `/analyze --level project` gate is REQUIRED at Platform and at Build with 4+ epics, and an epic built on an uncertified plan inherits every defect in it.
- **ALWAYS** run `/analyze --level epic` with lenses decorrelated from the corpus authors — 3 mandatory at Build 4+ (promise-coverage · cross-artifact drift · completeness critic), all 7 at Platform. A lens marked `authored_corpus: true` does not count toward the tier.
- **ALWAYS** check for the `E000` Developer Infrastructure epic first. Ensure testing and CI patterns are resolved before allowing other epics to specify.
- **ALWAYS** invoke downstream skills by reading their `SKILL.md` — never substitute inline artifact authoring for a skipped skill step.
- **ALWAYS** delegate per-story work to `/story`; the epic orchestrator coordinates sequencing, not story implementation.
- **ALWAYS** run the §3a Verify-Skills Gate before accepting a delegated story result — "Stories Complete" counts only verified stories, never self-reported verdicts.
- **NEVER** advance a state on mere artifact presence — require the report template-compliant AND its producing skills verified to have run.
- **NEVER** skip a validation check without an explicit `--skip` argument and its corresponding `project-decisions-log.md` rationale.
- **ALWAYS** regenerate `project-state.md` upon any state transition.
- Provide a clear progress bar or status line (e.g. `[Specified 🟢] → [Planning 🟡] → [Planned ⚪]`) in each reply.
