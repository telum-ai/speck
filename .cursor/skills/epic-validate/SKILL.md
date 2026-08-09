---
name: epic-validate
description: Validates epic after stories + audit. Use at epic prove gate.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-validate

Cheap keys: `.speck/project.json` → archetype; `--claim` / highest supported → `claimed_state`; UI vs backend.

1. MUST Read templates, then MUST Read `references/spine.md`.
2. If backend/infra / no UI: MUST Read `references/backend-skip.md`. Do not Read larp / felt / taste / visual.
3. If UI-facing: MUST Read `references/larp.md`. If claiming UX-RC+: also MUST Read `references/axes/felt.md`, `references/axes/taste.md`, `references/visual.md`. Else skip those axis/visual nodes.
4. For `claimed_state` and every lower ladder state, MUST Read `references/states/<kebab>.md`.
5. MUST Read `references/rollup.md`, `references/matrix-graph.md`, `references/mutation.md`, `references/composition.md`.
6. MUST Read `references/post-write.md`. Write + SHA-stamp.
STOP on any STOP in a Read node.
