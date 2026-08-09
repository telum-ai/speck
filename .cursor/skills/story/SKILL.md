---
name: story
description: Story lifecycle orchestrator. Invoke only via /story.
disable-model-invocation: true
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# story

1. MUST Read `references/spine.md` (purpose, stop conditions).
2. MUST Read `references/phases.md` for next phase routing.
3. Invoke next phase; `/audit` before `/story-validate`; LARP if UI.
