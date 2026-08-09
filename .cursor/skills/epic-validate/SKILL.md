---
name: epic-validate
description: Validates epic after stories + audit. Use at epic prove gate.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-validate

1. MUST Read templates listed in `references/spine.md`, then MUST Read `references/spine.md`.
2. Read `.speck/project.json` → archetype. Claimed state → **claimed**.
3. Branch archetype:
   - backend / no UI: MUST Read `references/backend-skip.md`. Skip larp/felt/taste/visual.
   - UI: MUST Read `references/larp.md`.
4. MUST Read `references/rollup.md`.
5. For claimed + lower ladder states: MUST Read `references/states/<kebab>.md`.
6. MUST Read `references/matrix-graph.md`, `references/mutation.md`, `references/composition.md`.
7. If UI + claimed ≥ ux-rc: MUST Read `references/axes/felt.md`, `references/axes/taste.md`, `references/visual.md`.
8. MUST Read `references/post-write.md`. Write + SHA-stamp.

STOP on any node STOP.
