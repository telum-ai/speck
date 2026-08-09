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

1. MUST Read `references/spine.md` (purpose, verify-skills, stop conditions).
2. MUST Read `references/phases.md` for next phase routing.
3. Invoke the next phase skill; never skip audit before validate.
