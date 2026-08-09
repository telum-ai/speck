---
name: project-promote
description: Raise play level. Use when Sprint/Build outgrows current rigor.
paths:
  - "specs/projects/**"
---

# project-promote

Cheap keys: current `play_level` in `.speck/project.json` and target level (Sprint→Build or Build→Platform).

1. MUST Read `references/spine.md` (read current state; confirm target).
2. If Sprint→Build: MUST Read `references/transitions/sprint-to-build.md` (and `-2` if linked). Do not Read build-to-platform.
3. If Build→Platform: MUST Read `references/transitions/build-to-platform.md`. Do not Read sprint-to-build.
4. Update `.speck/project.json`; report next steps.
