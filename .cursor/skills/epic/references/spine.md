# epic — spine

## Purpose

`/epic` is the **epic-level stateful orchestrator**. It auto-detects the epic's current state and **invokes downstream skills in canonical order** (`/epic-specify`, `/epic-clarify`, `/epic-plan`, `/epic-breakdown`, `/epic-analyze`, story work via `/story`, `/audit`, `/epic-validate`, `/epic-retrospective`).

**Driving pattern (REQUIRED)**: For each step in `### 3. Execution Loop`, **read and fully execute** the corresponding skill's `SKILL.md` (and its template, per that skill's FIRST ACTION) before advancing. Story work MUST delegate to `/story` (read `.cursor/skills/story/SKILL.md`) — do not implement stories inline from the epic orchestrator.

**ANTI-PATTERN (do NOT do this)**:
-  Writing `epic-tech-spec.md` or `epic-breakdown.md` inline without loading `/epic-plan` or `/epic-breakdown`
-  Implementing stories directly from `/epic` without invoking `/story` for each story
-  Skipping `/epic-analyze`, `/audit`, or `/epic-validate` because the orchestrator "already knows" the outcome
-  Treating the transition map as a checklist of filenames instead of a checklist of **skills to invoke**

## Usage Syntax

```bash
/epic [EPIC_ID] [continue | --from <state> | --interactive | --skip <command>]
```

## Behavior Rules

- **ALWAYS** run `check-epic-prereqs.sh` before the first `/epic-specify` of a session — the project-level `/project-analyze` gate is REQUIRED at Platform and at Build with 4+ epics, and an epic built on an uncertified plan inherits every defect in it.
- **ALWAYS** run `/epic-analyze` with lenses decorrelated from the corpus authors — 3 mandatory at Build 4+ (promise-coverage · cross-artifact drift · completeness critic), all 7 at Platform. A lens marked `authored_corpus: true` does not count toward the tier.
- **ALWAYS** check for the `E000` Developer Infrastructure epic first. Ensure testing and CI patterns are resolved before allowing other epics to specify.
- **ALWAYS** invoke downstream skills by reading their `SKILL.md` — never substitute inline artifact authoring for a skipped skill step.
- **ALWAYS** delegate per-story work to `/story`; the epic orchestrator coordinates sequencing, not story implementation.
- **ALWAYS** run the §3a Verify-Skills Gate before accepting a delegated story result — "Stories Complete" counts only verified stories, never self-reported verdicts.
- **NEVER** advance a state on mere artifact presence — require the report template-compliant AND its producing skills verified to have run.
- **NEVER** skip a validation check without an explicit `--skip` argument and its corresponding `project-decisions-log.md` rationale.
- **ALWAYS** regenerate `project-state.md` upon any state transition.
- Provide a clear progress bar or status line (e.g. `[Specified 🟢] → [Planning 🟡] → [Planned ⚪]`) in each reply.
