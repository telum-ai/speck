---
name: validate
description: Level-dispatching validator (Speck v8 unified entry). Routes to the level-appropriate validation skill — project-validate / epic-validate / story-validate — based on --level or the current directory. Use when the user says "validate this", "is this done?", "check readiness". The per-level specialists own the full readiness-state taxonomy, evidence gates, LARP hooks, and cap logic; this skill only picks the right one.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument:

$ARGUMENTS

## Purpose

`/validate` is the unified, level-dispatching entry point for Speck validation. It does **not** re-implement validation logic — it detects the level and routes to the battle-tested specialist, which owns the readiness-state taxonomy (P1/P2/P3), evidence gates, LARP hooks, and cap logic.

## Level detection

Use `--level <project|epic|story>` if provided. Otherwise infer from the current directory:

1. In `specs/projects/<id>/epics/<eid>/stories/<sid>/` → **story**
2. In `specs/projects/<id>/epics/<eid>/` → **epic**
3. In `specs/projects/<id>/` or higher → **project**

If the level is still ambiguous, ask the user which level to validate.

## Routing

| Level | Read and fully execute |
|-------|------------------------|
| story | `.cursor/skills/story-validate/SKILL.md` |
| epic | `.cursor/skills/epic-validate/SKILL.md` |
| project | `.cursor/skills/project-validate/SKILL.md` |

**Read the target `SKILL.md` and follow it end-to-end** (including its FIRST-ACTION template reads). Emitting a `validation-report.md` without running the specialist is simulation, not validation (Verify-Skills Gate).

> v8: `/project-validate`, `/epic-validate`, `/story-validate` remain valid direct entry points (unchanged, full logic). `/validate` is a convenience that unifies the surface — dispatcher pattern, no lossy merge of the specialists.
