---
name: story-implement
description: Implements analyzed story work. Use after required spec, plan, tasks, and story analysis before speck-audit.
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# story-implement

Cheap keys: `STORY_DIR` has `ui-spec.md` / UI tasks in `tasks.md` (UI-bearing); or API/backend-only story.

1. Classify the story before loading branch context.
2. Before the first mutation, run exactly one:
   - UI-bearing: `python3 .speck/scripts/context/speck_context.py story-implement-ui`
   - API/backend or no UI: `python3 .speck/scripts/context/speck_context.py story-implement-backend`
3. Require exit 0 and `SPECK_CONTEXT_RECEIPT`; do not separately load the sibling branch.
4. Execute the loaded spine/branch. Mark tasks done and run the project implementation gates after the last mutation. Do not claim validate; route `/audit` next.
