---
name: project-validate
description: Project validate after epics. Use at project prove gate.
paths:
  - "specs/projects/**"
---

# project-validate

1. MUST Read templates, then MUST Read `references/spine.md`.
2. For claimed_state and every lower ladder state, MUST Read `references/states/<kebab>.md`.
3. MUST Read `references/jtbd-smoke.md`, `references/rollup.md`.
4. MUST Read `references/gate-liveness.md`, `references/coverage-matrix.md`.
5. If claimed ≥ COMMERCIAL-RC: MUST Read `references/commercial.md`.
6. If claimed ≥ SHIP-RC: MUST Read `references/profile.md`.
7. MUST Read `references/post-write.md`.
STOP on any STOP in a Read node.
