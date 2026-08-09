---
name: story-tasks
description: Writes tasks.md checklist. Use after plan / before implement.
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# story-tasks

Cheap keys: UI-bearing story vs API/backend story (from spec/plan/ui-spec presence).

1. MUST Read template, then MUST Read `references/spine.md`.
2. If UI-bearing: MUST Read `references/ui-tasks.md`. Else do not.
3. If API/backend story (endpoints/schema/migrations; or no UI): MUST Read `references/api-tasks.md`. Else do not.
4. Write `tasks.md`; run the deterministic validator; cross-check vs plan/spec.
