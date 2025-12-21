---
description: Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Goal: Identify inconsistencies, duplications, ambiguities, and underspecified items across the three core artifacts (`spec.md`, `plan.md`, `tasks.md`) before implementation. This command MUST run only after `/story-tasks` has successfully produced a complete `tasks.md`.

STRICTLY READ-ONLY: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

Constitution Authority: The applicable constitution chain (**project + epic**) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks—not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `/analyze`.

Execution steps:

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If no `spec.md` found: instruct user to `cd` into the story directory or run `/speck` to route
   - Derive absolute paths:
     - SPEC = `{STORY_DIR}/spec.md`
     - PLAN = `{STORY_DIR}/plan.md`
     - TASKS = `{STORY_DIR}/tasks.md`
   Abort with an error message if any required file is missing (instruct the user to run the missing prerequisite command).

2. Load artifacts:
   - Parse spec.md sections: Overview/Context, Functional Requirements, Non-Functional Requirements, User Stories, Edge Cases (if present).
   - Parse plan.md: Architecture/stack choices, Data Model references, Phases, Technical constraints, embedded research findings.
   - Parse tasks.md: Task IDs, descriptions, phase grouping, parallel markers [P], referenced file paths.
   - Load constitutions for principle validation (if they exist):
     - Project: `specs/projects/<PROJECT_ID>/constitution.md` (optional)
     - Epic: `{EPIC_DIR}/constitution.md` (optional)
     - Story: `{STORY_DIR}/constitution.md` (if exists)
   - IF EXISTS: Load codebase-scan-*.md files for existing patterns and conventions
   
   **Note**: Research is embedded in plan.md "Research Informing This Plan" section - extract technical decisions from there.

3. Build internal semantic models:
   - Requirements inventory: Each functional + non-functional requirement with a stable key (derive slug based on imperative phrase; e.g., "User can upload file" -> `user-can-upload-file`).
   - User story/action inventory.
   - Task coverage mapping: Map each task to one or more requirements or stories (inference by keyword / explicit reference patterns like IDs or key phrases).
   - Constitution rule set: Extract principle names and any MUST/SHOULD normative statements.

4. Detection passes:
   
   A. Duplication detection:
      - Identify near-duplicate requirements. Mark lower-quality phrasing for consolidation.
   
   B. Ambiguity detection:
      - Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria.
      - Flag unresolved placeholders (TODO, TKTK, ???, <placeholder>, etc.).
   
   C. Underspecification:
      - Requirements with verbs but missing object or measurable outcome.
      - User stories missing acceptance criteria alignment.
      - Tasks referencing files or components not defined in spec/plan.
   
   D. Constitution alignment:
      - Any requirement or plan element conflicting with a MUST principle.
      - Missing mandated sections or quality gates from constitution.
   
   E. Coverage gaps:
      - Requirements with zero associated tasks;check if plan.md Phase 1.5 has FR table
      - Tasks with no mapped requirement/story; every task should have "Implements: FR-XXX"
      - Non-functional requirements not reflected in tasks (e.g., performance, security)
      - Missing FR → Task mapping table in tasks.md
      - FRs in spec.md but not in plan.md Phase 1.5 FR extraction table
   
   F. Research information completeness:
      - Check if plan.md has "Research Informing This Plan" section
      - If web searches or deep research were conducted, verify findings are documented
      - Check plan.md Phase 1.5 includes code examples and patterns from research
      - Verify performance benchmarks from research are in Performance Optimization Guide
      - Verify security recommendations from research are in Security Implementation Checklist
      - **Flag if**: Research was conducted but plan.md Phase 1.5 is empty or generic
   
   G. Codebase pattern information loss:
      - Components in codebase-scan-*.md but not in plan.md Phase 1.5 Component Registry
      - Patterns in scans but not in plan.md Codebase Patterns for Reuse section
      - Testing patterns in scans but tasks.md test descriptions are generic
      - **Flag if**: Tasks say "create X component" when scan shows X already exists
      - **Flag if**: Tasks say "follow existing patterns" without citing which patterns/files
   
   H. Task context richness check:
      - Tasks missing "Implements: FR-XXX" references
      - Technical tasks missing Pattern OR Research references
      - UI tasks missing Design System component specifications
      - UI tasks missing Brand Voice copy examples
      - Security tasks missing implementation checklists
      - Performance-critical tasks missing optimization techniques
      - **Flag if**: >20% of tasks are in "old format" (just description + file path)
   
   I. Inconsistency:
      - Terminology drift (same concept named differently across files).
      - Data entities referenced in plan but absent in spec (or vice versa).
      - Task ordering contradictions.
      - Conflicting requirements.
   
   J. Research alignment:
      - Plan architecture choices contradicting research recommendations (check plan.md research section).
      - Missing implementation of researched solutions (check if findings are applied).
      - Tech stack choices ignoring research findings.
      - **NEW**: Research code examples not preserved in plan.md Phase 1.5
   
   K. Codebase pattern adherence (IF codebase-scan-*.md exists):
      - Task file paths not following existing directory conventions.
      - Task file naming not matching existing patterns.
      - Missing reuse of existing components/patterns identified in scans.
      - Tasks creating new components when equivalent existing patterns are available.
      - Test organization not following existing test structure.
      - Import/export patterns not matching codebase conventions.
      - Pattern references missing file:line citations
      - Tasks don't warn "DON'T recreate X" when X exists

5. Severity assignment heuristic (ENHANCED):
   - CRITICAL: Violates constitution MUST, missing core spec artifact, requirement with zero coverage that blocks baseline functionality, >30 percent of FRs have no implementing tasks, plan.md Phase 1.5 missing or empty when research/scans exist.
   - HIGH: Duplicate or conflicting requirement, ambiguous security/performance attribute, untestable acceptance criterion, architecture contradicting research recommendations, missing reuse of critical existing patterns, >50 percent of tasks missing FR references, tasks recreating components that exist in scans, research code examples not in plan.md.
   - MEDIUM: Terminology drift, missing non-functional task coverage, underspecified edge case, file paths not matching codebase conventions, test structure inconsistencies, **NEW**: tasks missing pattern references, >20 percent of tasks in "old format".
   - LOW: Style/wording improvements, minor redundancy not affecting execution order, optional pattern reuse opportunities.

6. Produce a Markdown report (no file writes) with sections:

   ### Specification Analysis Report
   | ID | Category | Severity | Location(s) | Summary | Recommendation |
   |----|----------|----------|-------------|---------|----------------|
   | A1 | Duplication | HIGH | spec.md:L120-134 | Two similar requirements ... | Merge phrasing; keep clearer version |
   (Add one row per finding; generate stable IDs prefixed by category initial.)

   Additional subsections:
   - Coverage Summary Table:
     | Requirement Key | Has Task? | Task IDs | Notes |
   - Constitution Alignment Issues (if any)
   - Research Alignment Issues (check plan.md research section)
   - Codebase Pattern Adherence Issues (if codebase-scan-*.md exists)
   - Unmapped Tasks (if any)
   - Metrics:
     * Total Requirements
     * Total Tasks
     * Coverage % (requirements with >=1 task)
     * Ambiguity Count
     * Duplication Count
     * Critical Issues Count
     * Research Integration % (% of research recommendations from plan.md implemented in tasks)
     * Pattern Reuse % (if scans exist - % of tasks reusing existing patterns vs. creating new)
     * Information Flow Metrics:
       - FR Traceability: % of FRs with explicit task mapping
       - Task Context Richness: % of tasks with "Implements: FR-XXX"
       - Research Preservation: % of research decisions in plan.md Phase 1.5
       - Pattern Linkage: % of tasks citing scan patterns with file:line refs
       - Context Loss Score: (100 - avg of above metrics) = overall information loss %

7. At end of report, output a concise Next Actions block:
   - If CRITICAL issues exist: Recommend resolving before `/story-implement`.
   - If only LOW/MEDIUM: User may proceed, but provide improvement suggestions.
   - Provide explicit command suggestions: e.g., "Run /story-specify with refinement", "Run /story-plan to adjust technical approach", "Manually edit tasks.md to add coverage for missing FRs/NFRs".

8. Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply them automatically.)

Behavior rules:
- NEVER modify files.
- NEVER hallucinate missing sections—if absent, report them.
- KEEP findings deterministic: if rerun without changes, produce consistent IDs and counts.
- LIMIT total findings in the main table to 50; aggregate remainder in a summarized overflow note.
- If zero issues found, emit a success report with coverage statistics and proceed recommendation.

Context: $ARGUMENTS
