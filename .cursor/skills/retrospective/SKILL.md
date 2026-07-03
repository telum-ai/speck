---
name: retrospective
description: Level-dispatching retrospective (Speck v8 unified entry). Routes to the level-appropriate retrospective skill — project-retrospective / epic-retrospective / story-retrospective — based on --level or the current directory. Use when the user says "retro this", "capture learnings", "what did we learn". The per-level specialists own the full learning-capture + commit-tag + pattern-feedback logic.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument:

$ARGUMENTS

## Purpose

`/retrospective` is the unified, level-dispatching entry point for Speck retrospectives. It detects the level and routes to the specialist, which owns the learning-capture, commit-learning-tag harvest, and `/speck-learn` feedback logic.

## Level detection

Use `--level <project|epic|story>` if provided. Otherwise infer from the current directory:

1. In `specs/projects/<id>/epics/<eid>/stories/<sid>/` → **story**
2. In `specs/projects/<id>/epics/<eid>/` → **epic**
3. In `specs/projects/<id>/` or higher → **project**

If the level is still ambiguous, ask the user which level to retro.

## Routing

| Level | Read and fully execute |
|-------|------------------------|
| story | `.cursor/skills/story-retrospective/SKILL.md` |
| epic | `.cursor/skills/epic-retrospective/SKILL.md` |
| project | `.cursor/skills/project-retrospective/SKILL.md` |

**Read the target `SKILL.md` and follow it end-to-end.**

> v8: `/project-retrospective`, `/epic-retrospective`, `/story-retrospective` remain valid direct entry points (unchanged, full logic). `/retrospective` is a convenience that unifies the surface — dispatcher pattern, no lossy merge.
