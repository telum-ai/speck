---
description: Generate an actionable, dependency-ordered tasks.md for the story based on available design artifacts.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If no `spec.md` found: instruct user to `cd` into the story directory or run `/speck` to route
   - Required inputs:
     - `{STORY_DIR}/spec.md`
     - `{STORY_DIR}/plan.md` (if missing: ERROR "Run /story-plan first")

2. Load and analyze available design documents **WITH DEEP EXTRACTION**:
   
   **CRITICAL: Read spec.md for complete requirements**:
   - Extract ALL functional requirements (FR-XXX) with full text
   - Extract acceptance criteria from scenarios
   - Extract edge cases and clarification decisions
   - Extract performance targets from NFRs
   - Extract security/privacy requirements
   - This is REQUIRED - spec.md is the source of truth for WHAT to build
   
   **Always read plan.md** for architecture and context:
   - Tech stack and libraries
   - Constitution compliance gates (specific implementation requirements)
   - Phase 1.5 Implementation Guidance section:
     * FR extraction table (use for FR → task mapping)
     * Research findings with code examples (use in task descriptions)
     * Codebase patterns to reuse (specify in tasks)
     * Performance optimization guide (include in relevant tasks)
     * Security implementation checklist (add to security tasks)
     * Design system component registry (specify components in UI tasks)
     * Brand voice copy bank (include copy examples in UI tasks)
     * Constitution gates (reference in affected tasks)
   
   **IF EXISTS: Read data-model.md** for entities:
   - Entity names, fields, relationships
   - Validation rules (include in implementation tasks)
   - Business rules and constraints (include in service tasks)
   
   **IF EXISTS: Read contracts/** for API endpoints:
   - Endpoint paths and methods
   - Request/response schemas (include in test tasks)
   - Error responses (include in error handling tasks)
   
   **IF EXISTS: Read quickstart.md** for test scenarios:
   - Integration test scenarios
   - Validation steps (use as acceptance criteria in tasks)
   
   **IF EXISTS: Read codebase-scan-*.md files** for patterns:
   - Specific components to reuse with file:line references
   - Code examples showing how to use existing patterns
   - Anti-patterns to avoid
   - Testing patterns and fixture examples

   Note: Not all projects have all documents, but spec.md and plan.md are REQUIRED.

   **Extract story dependencies from epic-breakdown.md**:
   - Read `{EPIC_DIR}/epic-breakdown.md` if exists
   - Find this story's entry and extract "Depends on:" field
   - Use these as `depends_on` in tasks.md front matter
   - Also check for stories that depend on THIS story (for `blocks` field)

3. Generate tasks.md:

   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/story/tasks-template.md
   ```
   
   The template contains ALL format rules, task generation rules, ordering guidelines,
   and enhanced task description format. Follow it precisely - validation will fail
   if the exact format is not used.
   
   Key template sections:
   - YAML front matter (dependencies from epic-breakdown.md)
   - FR → Task Mapping table
   - Enhanced task descriptions with context cards
   - Task generation rules and ordering
   - Validation checklist

   **Apply extracted context** (from step 2) when generating tasks:
   - Extracted FRs → FR → Task Mapping table
   - Extracted patterns → Pattern references in task descriptions
   - Extracted performance targets → Performance notes in tasks
   - Extracted security requirements → Security checklists in tasks
   - Extracted design components → Design System references in UI tasks
   - Extracted brand voice → Copy examples in UI tasks

   Write output to `{STORY_DIR}/tasks.md`.

   The tasks.md should be immediately executable - each task must be specific enough 
   that an LLM can complete it **with the context provided in the task description** 
   (not requiring separate research).

4. Output summary:
   ```
   ✅ Story Tasks Generated!
   
   Feature: [Name]
   Total Tasks: [X]
   
   Task Breakdown:
   - Setup: [Y] tasks
   - Tests: [Z] tasks (marked [P] for parallel)
   - Core Implementation: [A] tasks
   - Integration: [B] tasks
   - Polish: [C] tasks
   
   Parallel Opportunities: [Count] tasks can run simultaneously
   
   FR Coverage: All [X] functional requirements mapped to tasks
   
   Next Steps:
   1. Review task breakdown
   2. ⚠️ REQUIRED: Run /story-analyze (quality check - DO NOT SKIP)
   3. Then: /story-implement (execute the tasks)
   4. Finally: /story-validate (verify completion)
   
   Note: /story-implement will execute these tasks in order,
   running parallel tasks [P] simultaneously for efficiency.
   ```
