---
name: story-specify
description: Creates story spec.md. Use after epic-breakdown or for new scope, before story-clarify and story-plan.
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# story-specify

Input: `$ARGUMENTS` (story description — use conversation text if literal).
Output: `[STORY_DIR]/spec.md`.
Template: `.speck/templates/story/story-template.md`.

## 0. Template

Before any mutation, run
`python3 .speck/scripts/context/speck_context.py story-specify`. Require exit 0
and `SPECK_CONTEXT_RECEIPT`; follow the receipted story template.

## 1. Play level

Read `.speck/project.json` → `play_level`.

| Level | Action |
|-------|--------|
| Sprint | STOP — ship from PRD Build Plan; `/project-promote` for stories |
| Build | Lightweight: `spec.md` + `plan.md`; skip tasks/validate retro in recommendations unless asked |
| Platform | Full flow |

## 2. Context

Parse args: `project:XXX epic:YYY [description]` or ask progressively.

List options:
```bash
find specs/projects -name project.md -exec dirname {} \; | xargs -I {} basename {}
ls specs/projects/[PROJECT_ID]/epics/
```

## 3. Placeholder detection

```bash
SPEC=$(ls -1 specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]-*/spec.md 2>/dev/null | head -1)
```

| State | Action |
|-------|--------|
| Draft / Draft (Placeholder) | Enhance — preserve YAML frontmatter (`depends_on`, `blocks`) |
| Specified | Warn; confirm re-specify |
| Missing | Create from scratch |

CRITICAL: never drop `depends_on` — orchestrator reads it.

## 4. Pre-validation

Check `epic-breakdown.md` + `stories/` for duplicates. Story-level? (5-min explainability) vs epic-level?

Load: `domain-model.md`, `ux-strategy.md`, `design-system.md`, `epic.md`. Misaligned → offer different epic / expand epic.

## 5. Specify

Enhance draft: show content; refine gaps. Fresh: gather user story, triggers, completion signals, stable `AC-N` scenarios in the template's `GIVEN`/`WHEN`/`THEN` grammar, constraints, test approach, FE/BE scope, API/DB impacts.

```bash
mkdir -p specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]-[name]
```

Fill template → `spec.md`:
```
**Current State**: Specified
- [x] **Draft** (if was placeholder)
- [x] **Specified**
```

Before save, require all four: canonical frontmatter
`lifecycle_state: Specified`; stable `AC-N` scenarios with observable outcomes;
named failure behavior; and a concrete test/LARP approach for every failure.
Preserve `depends_on` and `blocks` byte-for-byte unless the epic breakdown has
also been deliberately amended.

Preserve requirement fidelity. A new required field, actor, integration, or
solution choice must trace to the epic/breakdown/input; otherwise mark it
`[NEEDS CLARIFICATION]` instead of inventing it. Give every named failure path a
negative acceptance criterion and matching test/LARP approach.

After the final artifact edit, run the validator as a standalone command event:
```bash
bash .speck/scripts/validation/validate-template.sh "$STORY_DIR/spec.md" --strict
```
Do not chain, pipe, or wrap it, and do not mutate the story afterward. The
recorded event exit must belong to the validator itself.

**5-minute test**: explain in <5 min. Needs "AND" or >3 AC scenarios → split.

Update epic story list → specified.

## 6. Optional step evaluation

| Step | Required when | Skip when |
|------|------------------|--------------|
| `/story-clarify` | Vague AC; unclear scope; `[NEEDS CLARIFICATION]` | All AC testable |
| `/speck-skeptical-review` | Unfamiliar tech; TBD; competing approaches | Established patterns |
| `/speck-scan --level story` | Modifies existing modules | Greenfield |
| `/story-ui-spec` | UI/screen/form/modal/layout mentioned | Backend/API/CLI only |

Output table with evidence quotes + recommended path.

**Continuation**:
- Orchestrated (`/story`): proceed to first recommended step
- Interactive: ask "Proceed with [first step]?"

After save, re-read the marked canonical Story flow in root `AGENTS.md` and continue at its first incomplete applicable slot. The table selects optional slots; it does not define their order.

UI REQUIRED: note `/story-ui-spec` after plan, before tasks.

## NEVER / ALWAYS

- NEVER overwrite `depends_on` / `blocks` frontmatter
- NEVER create duplicate stories without user approval
- NEVER skip template read
- ALWAYS run optional step evaluation after save
- ALWAYS preserve placeholder progression in lifecycle checkboxes
