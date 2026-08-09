---
name: epic
description: Epic lifecycle orchestrator. Invoke only via /epic.
disable-model-invocation: true
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic

1. MUST Read `references/spine.md`.
2. MUST Read `references/phases.md`.
3. Invoke the next incomplete child skill for this epic.
