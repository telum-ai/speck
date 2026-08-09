---
name: project-validate
description: Project validate after epics. Use at project prove gate.
paths:
  - "specs/projects/**"
---

# project-validate

1. MUST Read templates in spine, then MUST Read `references/spine.md`.
2. Read play_level. Sprint: handle per spine table then STOP if promote path.
3. MUST Read `references/jtbd-smoke.md`, `references/rollup.md`.
4. For claimed + lower states: MUST Read `references/states/<kebab>.md`.
5. MUST Read `references/gate-liveness.md`, `references/coverage-matrix.md`.
6. If claimed ≥ commercial-rc: MUST Read `references/commercial.md`.
7. If claimed ≥ ship-rc: MUST Read `references/profile.md`.
8. MUST Read `references/post-write.md`.

STOP on any node STOP.
