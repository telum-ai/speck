---
name: adjust
description: Routes adjust by --level story|epic|project. Use when redesigning validated work.
---

The user input can be provided directly by the agent or as a command argument:

$ARGUMENTS

## Purpose

`/adjust` is the unified, level-dispatching entry point for **deliberate** changes to already-validated/shipped work (not defect fixes — those go to `/harden`). It detects the intended blast radius and routes to the specialist, which owns delta-spec authoring, promise conservation, superseding DECs, and (project level) the reverse cascade.

## Level detection

Use `--level <project|epic|story>` if provided. Otherwise infer from the change's blast radius:

1. Single story redesign / visual overhaul → **story**
2. Epic-level structure / IA pivot spanning multiple stories → **epic**
3. Directional / strategic / product-contract change → **project**

When unsure, prefer the **narrowest** level that fully contains the change, and ask the user to confirm before a project-level cascade.

## Routing

| Level | Read and fully execute |
|-------|------------------------|
| story | `.cursor/skills/story-adjust/SKILL.md` |
| epic | `.cursor/skills/epic-adjust/SKILL.md` |
| project | `.cursor/skills/project-adjust/SKILL.md` |

**Read the target `SKILL.md` and follow it end-to-end.** Project-level adjust runs `compute-cascade.sh` and routes each affected downstream unit back through `/epic-adjust` or `/story-adjust`.

> v8: `/project-adjust`, `/epic-adjust`, `/story-adjust` remain valid direct entry points (unchanged, full logic). `/adjust` is a convenience that unifies the surface — dispatcher pattern, no lossy merge.
