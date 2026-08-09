---
name: epic-validate
description: Validates epic after stories + audit. Use at epic prove gate.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-validate

1. MUST Read templates, then MUST Read `references/spine.md`.
2. Read archetype. Backend/no-UI: also MUST Read `references/backend-skip.md`.
3. UI: also MUST Read `references/larp.md`; if claiming UX-RC+: `references/axes/felt.md`, `references/axes/taste.md`, `references/visual.md`.
4. For claimed_state and every lower ladder state, MUST Read `references/states/<kebab>.md`.
5. MUST Read `references/rollup.md`, `references/matrix-graph.md`, `references/mutation.md`, `references/composition.md`.
6. MUST Read `references/post-write.md`. Write + SHA-stamp.
STOP on any STOP in a Read node.
