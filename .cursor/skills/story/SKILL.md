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

1. MUST Read `references/spine.md`.
2. MUST Read `references/phases.md`.
3. Invoke the next incomplete child skill for this story.
