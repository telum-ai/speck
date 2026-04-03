---
name: epic-analyze
description: Load after epic-tech-spec.md and epic-breakdown.md exist — quality check for consistency and completeness before any story work begins. Catches spec drift and missing coverage between the tech spec and story breakdown.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Validate epic planning artifacts to identify issues before story implementation begins.

1. Load epic artifacts:
   - epic.md (specification)
   - epic-tech-spec.md (technical design with embedded research)
   - epic-breakdown.md (story mapping)
   - Related scan reports (epic-codebase-scan*.md)
   - Project-level PRD and constraints
   - If core files missing: ERROR "Complete epic planning first"
   
   **Note**: Research is now embedded in epic-tech-spec.md - no separate research.md to validate.

   **Load Constitution Chain (if present)**:
   - `[EPIC_DIR]/constitution.md` — epic-level principles
   - `specs/projects/[PROJECT_ID]/constitution.md` — project-level principles
   Apply combined rule set as the authority for compliance checks below.

   **Load UX artifacts (if present)**:
   - `[EPIC_DIR]/user-journey.md` — check if journey stages are reflected in tech spec
   - `[EPIC_DIR]/wireframes.md` — check if screen inventory maps to story breakdown

2. Multi-aspect analysis:

   **A. Requirement Coverage**
   - All user stories have tasks?
   - All acceptance criteria addressable?
   - Technical requirements mapped?
   - Edge cases handled?

   **B. Technical Coherence**
   - Architecture supports all stories?
   - Technology choices consistent?
   - Integration points defined?
   - Performance strategy adequate?

   **C. Task Completeness**
   - All stories broken into tasks?
   - Dependencies correctly mapped?
   - Parallel opportunities identified?
   - Effort estimates reasonable?

   **D. Risk Assessment**
   - Technical risks addressed?
   - Dependencies manageable?
   - Fallback plans exist?
   - Critical path reasonable?

   **E. Quality Coverage**
   - Test strategy comprehensive?
   - Documentation planned?
   - Security addressed?
   - Performance validated?

   **F. Constitution Compliance** (if `constitution.md` exists at epic or project level)
   - Does the tech spec's architecture section respect all MUST rules in the constitution?
   - Do API contract conventions follow constitution-mandated patterns?
   - Do data ownership / boundary rules align with constitution-defined epic interfaces?
   - Are testing requirements at or above the constitution's quality floor?
   - If violations found: FLAG as CRITICAL with exact constitution principle and offending section.

   **G. UX Artifact Integration** (if `user-journey.md` or `wireframes.md` exist)
   - Does epic-tech-spec.md have a "UX Design Context" section?
   - Are journey stages reflected in story groupings in epic-breakdown.md?
   - Does every wireframe screen map to at least one story in epic-breakdown.md?
   - Are UX quality requirements (from emotional targets / pain points) captured as NFRs?
   - If journey/wireframes exist but tech spec has no UX section: FLAG as WARNING
     "UX artifacts present but not incorporated in tech spec — re-run /epic-plan"

3. Deep analysis checks:

   **Story Traceability Matrix**
   ```
   | User Story | Tech Spec Section | Task ID | Test Coverage |
   |------------|------------------|---------|---------------|
   | Story 1.1 | Section 4.1 | S004 | Unit, Integration |
   ```

   **Dependency Analysis**
   - Circular dependencies?
   - External blockers?
   - Critical path too long?
   - Parallel opportunities missed?

   **Technical Debt Assessment**
   - Shortcuts taken?
   - Future refactoring needed?
   - Technical compromises?

4. Generate analysis report:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/epic/epic-analysis-report-template.md
   ```

   Write output to: `[EPIC_DIR]/epic-analysis-report.md`

5. Generate fix suggestions:
   ```
   ## Quick Fixes
   
   For missing task:
   Add to epic-breakdown.md Phase 2:
   - [ ] S006 [Story 2.1 implementation]
   
   For circular dependency:
   Refactor S006 to not depend on S005
   ```

6. Save as `[EPIC_DIR]/epic-analysis-report.md`

7. Output summary:
   ```
   ✅ Epic Analysis Complete!
   
   Status: [Ready/Issues Found]
   
   Coverage:
   - Stories with tasks: [X]%
   - Technical coverage: [Y]%
   - Risk mitigation: [Z]%
   
   Critical Issues: [Count]
   Warnings: [Count]
   
   [If Ready]:
   Next: Begin implementation with Phase 1 stories
   
   [If Issues]:
   Fix critical issues then re-run /epic-analyze
   
   Full report: epic-analysis-report.md
   ```

This ensures epic plan is solid before story work begins.
