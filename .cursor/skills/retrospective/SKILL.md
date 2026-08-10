---
name: retrospective
description: User-only router for /retrospective --level. Auto-selection uses the level retrospective directly.
disable-model-invocation: true
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

This router exists for explicit user convenience. Automatic selection uses the level specialist directly.
