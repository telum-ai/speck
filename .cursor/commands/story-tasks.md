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
   
   **CRITICAL: Read spec.md for complete requirements** (NEW!):
   - Extract ALL functional requirements (FR-XXX) with full text
   - Extract acceptance criteria from scenarios
   - Extract edge cases and clarification decisions
   - Extract performance targets from NFRs
   - Extract security/privacy requirements
   - This is REQUIRED - spec.md is the source of truth for WHAT to build
   
   **Always read plan.md** for architecture and context:
   - Tech stack and libraries
   - Constitution compliance gates (specific implementation requirements)
   - **NEW: Phase 1.5 Implementation Guidance section**:
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
   - **NEW**: Validation rules (include in implementation tasks)
   - **NEW**: Business rules and constraints (include in service tasks)
   
   **IF EXISTS: Read contracts/** for API endpoints:
   - Endpoint paths and methods
   - **NEW**: Request/response schemas (include in test tasks)
   - **NEW**: Error responses (include in error handling tasks)
   
   **Read plan.md** for technical decisions (research is embedded here):
   - **OLD**: Extract decisions only
   - **NEW**: Extract implementation patterns, code examples, performance benchmarks
   - **NEW**: Extract security models and attack mitigations
   - **NEW**: Extract rationale and alternatives considered (for task context)
   
   **IF EXISTS: Read quickstart.md** for test scenarios:
   - Integration test scenarios
   - **NEW**: Validation steps (use as acceptance criteria in tasks)
   
   **IF EXISTS: Read codebase-scan-*.md files** for patterns:
   - **OLD**: Existing file naming conventions only
   - **NEW**: Specific components to reuse with file:line references
   - **NEW**: Code examples showing how to use existing patterns
   - **NEW**: Anti-patterns to avoid
   - **NEW**: Testing patterns and fixture examples

   Note: Not all projects have all documents, but spec.md and plan.md are REQUIRED.

   **Extract story dependencies from epic-breakdown.md**:
   - Read `{EPIC_DIR}/epic-breakdown.md` if exists
   - Find this story's entry and extract "Depends on:" field
   - Use these as `depends_on` in tasks.md front matter
   - Also check for stories that depend on THIS story (for `blocks` field)

3. Generate tasks with front matter:
   - Include YAML front matter with dependency declarations:
     ```yaml
     ---
     depends_on: [story-001, story-003]  # From epic-breakdown.md
     blocks: [story-005]                  # Stories waiting on this one
     ---
     ```
   - The orchestrator uses this to manage execution order

   Generate tasks following the template:
   - Use `.speck/templates/story/tasks-template.md` as the base
   - Replace example tasks with actual tasks based on:
     * **Setup tasks**: Project init, dependencies, linting
     * **Test tasks [P]**: One per contract, one per integration scenario
     * **Core tasks**: One per entity, service, CLI command, endpoint
     * **Integration tasks**: DB connections, middleware, logging
     * **Polish tasks [P]**: Unit tests, performance, docs

5. Task generation rules:
   - Each contract file → contract test task marked [P]
   - Each entity in data-model → model creation task marked [P]
   - Each endpoint → implementation task (not parallel if shared files)
   - Each user story → integration test marked [P]
   - Different files = can be parallel [P]
   - Same file = sequential (no [P])

6. Order tasks by dependencies:
   - Setup before everything
   - Tests before implementation (TDD)
   - Models before services
   - Services before endpoints
   - Core before integration
   - Everything before polish

7. Include parallel execution examples:
   - Group [P] tasks that can run together
   - Show actual Task agent commands

8. Create `{STORY_DIR}/tasks.md` with **ENHANCED FORMAT** including:
   
   **Header Section**:
   - Feature name and input documents
   - **NEW**: Implementation Context section with:
     * FR → Task Mapping table (map every FR to implementing tasks)
     * Research Decisions Reference (key decisions affecting tasks)
     * Codebase Patterns to Reuse (components/patterns that exist)
     * Performance Targets (optimization techniques per task)
     * Security Requirements (implementation checklists)
     * Design System Components (which to use where)
     * Brand Voice Examples (copy patterns to follow)
   
   **Task Descriptions**:
   - Numbered tasks (T001, T002, etc.) with **ENHANCED FORMAT**
   - Each task MUST include (where applicable):
     * **Implements**: FR IDs this task addresses
     * **Pattern**: Reference to existing code with file:line numbers
     * **Research**: Key decision/rationale from research reports
     * **Performance**: Target + optimization technique
     * **Security**: Requirements + implementation notes
     * **Design System**: Components to use (not create)
     * **Brand Voice**: Copy examples for UI tasks
     * **Testing**: What tests validate this task
     * **File**: Clear file path
   - Minimum for every task: Implements (FR IDs), File path
   - Minimum for technical tasks: + Pattern OR Research reference
   - Minimum for UI tasks: + Design System components, Brand Voice
   
   **Example Enhanced Task**:
   ```markdown
   - [ ] T014 Implement privacy-preserving contact matching service

   **Implements**: FR-006, FR-010

   **Pattern**: Two-layer async from scan-user.md:206-268
   
   **Research**: SHA-256 + pepper (research-report-privacy-*.md)
     - Query: `WHERE hash = ANY(?)` for batch matching
     - Rate limit: 100/minute
   
   **Performance**: <500ms for 1000 contacts
   
   **File**: `backend/src/services/contact_matching.py`
   ```
   
   **Integration with Codebase Scans**:
   - Use scan findings for accurate file paths
   - **NEW**: Extract specific patterns with line numbers
   - **NEW**: List components that EXIST (with "DON'T recreate" warnings)
   - **NEW**: Include code examples from scans in task descriptions
   - Include references like "See codebase-scan-design-system.md:589-694 for PhoneInput"

**Integration with Research Reports**:
   - **NEW**: Reference research-report-*.md for implementation details
   - **NEW**: Include code examples from research in task notes
   - **NEW**: Add performance benchmarks and optimization techniques
   - **NEW**: Include security models and attack mitigations

**Integration with Spec.md** (CRITICAL NEW REQUIREMENT):
   - **NEW**: MUST read spec.md directly (don't rely on plan.md interpretation)
   - **NEW**: Create FR → Task mapping table at top of tasks.md
   - **NEW**: Every task references which FRs it implements
   - **NEW**: Validate FR coverage (every FR has tasks, no FRs missed)

Context for task generation: $ARGUMENTS

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it **with the context provided in the task description** (not requiring separate research).

8. Output summary:
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
   1. Review task breakdown with team
   2. Optional: /story-analyze (pre-implementation quality check)
   3. Required: /story-implement (execute the tasks)
   4. Then: /story-validate (verify completion)
   
   Note: /story-implement will execute these tasks in order,
   running parallel tasks [P] simultaneously for efficiency.
   ```
