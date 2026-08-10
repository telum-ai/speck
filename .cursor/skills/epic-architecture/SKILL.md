---
name: epic-architecture
description: Designs architecture across services, packages, or teams. Use before epic-plan for new patterns or complex integrations.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-architecture

Cheap keys: whether the epic crosses system/package boundaries; whether you are locking a choice.

1. MUST Read `references/decisions.md` (architecture decisions for this epic).
2. If the epic crosses systems/packages/teams (shared contracts, multi-service): MUST Read `references/seams.md`. Else do not.
3. ONLY before locking an architecture choice (N≥3): MUST Read `references/alternatives.md`. Else do not.
