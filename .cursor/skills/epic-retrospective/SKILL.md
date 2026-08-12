---
name: epic-retrospective
description: Synthesizes story retros into epic-retro.md. Use after epic-validate when closing an epic.
---

# epic-retrospective

Read `.speck/templates/epic/epic-retro-template.md`, `epic-validation-report.md`, the epic corpus, and every story retro. If a parallel execution omitted a story retro, use that story's validation, audit, and orchestration evidence and disclose the fallback.

1. Aggregate outcome, effort, spec accuracy, proof quality, and escaped-defect evidence.
2. An observation recurring in two or more stories is an epic-validated pattern or systemic gotcha; one occurrence stays story-specific.
3. Apply validated learning to project truth and affected unstarted epics. Promote it to project-owned `.speck/patterns/learned/` only when it has a reusable rule, evidence of recurrence, and a named future consumer.
4. Route methodology defects to `speck-feedback`; do not store them as project patterns.
5. Fill `[EPIC_DIR]/epic-retro.md`, stamp it, and refresh the declared PROFILE surface when the validated epic changes it.
