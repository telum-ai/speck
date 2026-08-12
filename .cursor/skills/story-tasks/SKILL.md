---
name: story-tasks
description: Writes executable tasks.md from the story plan. Use after story-plan and optional UI spec, before implementation.
---

# story-tasks

Cheap keys: UI-bearing story vs API/backend story, plus project `play_level` for the analysis marker.

1. Classify the story before loading branch context.
2. Before the first mutation, run exactly one:
   - UI-bearing: `python3 .speck/scripts/context/speck_context.py story-tasks-ui`
   - API/backend or no UI: `python3 .speck/scripts/context/speck_context.py story-tasks-backend`
3. Require exit 0 and `SPECK_CONTEXT_RECEIPT`; do not separately load the sibling branch.
4. Execute the loaded spine/branch, write `tasks.md`, run the deterministic validator, and cross-check vs plan/spec.
