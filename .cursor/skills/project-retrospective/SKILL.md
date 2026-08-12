---
name: project-retrospective
description: Synthesizes epic retros into project-retro.md. Use after project-validate when closing a project phase.
---

# project-retrospective

Read `.speck/templates/project/project-retro-template.md`, `project-validation-report.md`, current project truth, and every epic retro. Story retros have already been synthesized and are not primary inputs.

1. Compare the promised product with delivered outcomes, readiness evidence, effort, drift, and defect escape patterns.
2. Reconcile stale project truth before closing the retrospective.
3. Cross-epic recurrence validates a project-wide pattern. Maintain project-owned `.speck/patterns/learned/` only for evidence-backed rules with named consumers; keep narrower learning in its epic retro.
4. Route generalized Speck defects and improvements through `speck-feedback`, stripped of project secrets. Do not mutate Speck-managed methodology inside the product repo.
5. Fill `[PROJECT_DIR]/project-retro.md`, record concrete actions and remaining questions, and stamp it.
