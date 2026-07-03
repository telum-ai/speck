---
name: analyze
description: Level-dispatching pre-implementation analysis (Speck v8 unified entry). Routes to project-analyze / epic-analyze based on --level or the current directory. Story-level analysis is retired — its consistency job runs at the tail of /story-tasks and its adversarial job is /audit. Use when the user says "analyze this epic/project" before planning/implementation.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument:

$ARGUMENTS

## Purpose

`/analyze` is the unified, level-dispatching entry point for Speck pre-implementation analysis. It detects the level and routes to the specialist.

## Level detection

Use `--level <project|epic|story>` if provided. Otherwise infer from the current directory:

1. In `specs/projects/<id>/epics/<eid>/stories/<sid>/` → **story** (see note below)
2. In `specs/projects/<id>/epics/<eid>/` → **epic**
3. In `specs/projects/<id>/` or higher → **project**

## Routing

| Level | Read and fully execute |
|-------|------------------------|
| epic | `.cursor/skills/epic-analyze/SKILL.md` |
| project | `.cursor/skills/project-analyze/SKILL.md` |
| story | **Retired** — do not author a standalone `analysis-report.md`. The pre-impl spec↔plan↔tasks consistency check runs at the tail of `/story-tasks`; the adversarial behavior-vs-spec check is `/audit` (`speck-audit`) after implementation. |

**Read the target `SKILL.md` and follow it end-to-end.**

> v8: `/project-analyze`, `/epic-analyze` remain valid direct entry points (unchanged, full logic). `/story-analyze` is a retired alias-shim (folded into `/story-tasks` + `/audit`). `/analyze` is a convenience that unifies the surface — dispatcher pattern, no lossy merge.
