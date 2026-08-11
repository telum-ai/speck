---
name: epic-architecture
description: Designs epic architecture. Use after epic-clarify before epic-plan for cross-service patterns or complex integrations.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-architecture

Cheap keys: whether the epic crosses a service, package, team, trust, or external-system boundary; whether you are locking a choice.

1. MUST Read `references/decisions.md` (architecture decisions for this epic).
2. If the epic crosses a service, package, team, trust, or external-system boundary: MUST Read `references/seams.md`. Else do not.
3. ONLY before locking an architecture choice (N≥3): MUST Read `references/alternatives.md`. Else do not.
