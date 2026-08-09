---
name: story-implement
description: Implements story from plan/tasks. Use when coding the story.
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# story-implement

Cheap keys: `STORY_DIR` has `ui-spec.md` / UI tasks in `tasks.md` (UI-bearing); or API/backend-only story.

1. MUST Read `references/spine.md` (locate story, execute tasks, track, complete).
2. If UI-bearing (ui-spec present OR tasks create/modify UI): MUST Read `references/ui.md`. Else do not.
3. If API/backend-heavy (migrations, endpoints, services; or no UI): MUST Read `references/backend.md`. Else do not.
4. Mark tasks done. Run implementation gates. Do not claim validate; route `/audit` next.
