---
name: project-validate
description: Project validate after epics. Use at project prove gate.
paths:
  - "specs/projects/**"
---

# project-validate

Cheap keys: `--claim` / highest supported → `claimed_state`; whether PROFILE / commercial gates are in scope.

1. MUST Read templates, then MUST Read `references/spine.md`.
2. For `claimed_state` and every lower ladder state, MUST Read `references/states/<kebab>.md`.
3. If claimed ≥ INTEGRATION-GREEN: MUST Read `references/integration-green.md`.
4. MUST Read `references/jtbd-smoke.md`, `references/rollup.md`.
5. MUST Read `references/gate-liveness.md`, `references/coverage-matrix.md`.
6. If claimed ≥ COMMERCIAL-RC: MUST Read `references/commercial.md`. Else do not.
7. If claimed ≥ SHIP-RC: MUST Read `references/profile.md`. Else do not.
8. MUST Read `references/post-write.md`.
STOP on any STOP in a Read node.
