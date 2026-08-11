---
name: story-retrospective
description: Captures story outcomes and learnings in story-retro.md. Use after story-validate when closing a story.
---

# story-retrospective

Prerequisite: `validation-report.md`. Read `.speck/templates/story/story-retro-template.md`, the story validation and audit reports, then the story's commit range.

1. Compare planned and actual scope, effort, proof, and quality. Record what validation or audit caught and what escaped earlier phases.
2. Harvest `PATTERN`, `GOTCHA`, `PERF`, `ARCH`, `RULE`, and `DEBT` observations from artifacts and commit bodies. Keep a first occurrence story-specific.
3. Apply already-binding corrections to current truth and unstarted stories in the same epic. Route methodology defects to `speck-feedback`.
4. Fill `[STORY_DIR]/story-retro.md`, name evidence and epic-level candidates, and stamp it. Do not promote a one-story observation into `.speck/patterns/learned/`.
