---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
---

The user input can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If no `spec.md` found: instruct user to `cd` into the story directory or run `/speck` to route
   - Require `{STORY_DIR}/tasks.md` and `{STORY_DIR}/plan.md` (if missing: ERROR "Run /story-plan and /story-tasks first")

   **⚠️ PRE-IMPLEMENTATION CHECK**:
   Ask user: "Have you run `/story-analyze` to verify artifact quality?"
   - If user says no or is unsure: RECOMMEND running `/story-analyze` first
   - story-analyze catches issues BEFORE implementation, saving rework
   - This is a REQUIRED step in the Speck methodology

2. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read plan.md for technical decisions and constraints (research is embedded here)
   - **IF EXISTS**: Read quickstart.md for integration scenarios
   
   **Update tasks.md YAML frontmatter** to mark implementation started:
   ```yaml
   ---
   status: in_progress
   ---
   ```

3. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

4. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together  
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding

   **Subagent Parallelization** - For tasks marked `[P]`, spawn parallel speck-coder:
   ```
   Phase 2: Tests (example)
   - [P] [ ] T2.1: Write user tests → speck-coder instance 1
   - [P] [ ] T2.2: Write auth tests → speck-coder instance 2 (parallel!)
   - [P] [ ] T2.3: Write API tests  → speck-coder instance 3 (parallel!)
   - [ ] T2.4: Integration tests    → speck-coder (sequential, depends on above)
   ```
   
   Each speck-coder receives:
   - Task ID and description
   - Files to create/modify
   - Relevant patterns from codebase scan
   - TDD flag (write test first)
   
   Wait for all parallel tasks to complete before proceeding to dependent tasks.

5. Implementation execution rules:
   - **Setup first**: Initialize project structure, dependencies, configuration
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Core development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **Polish and validation**: Unit tests, performance optimization, documentation

6. Progress tracking and error handling:
   - Report progress after each completed task
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file.
   

7. Completion validation:
   - Verify all required tasks are completed
   - Mark all completed tasks as [X] in tasks.md
   - Report final status with summary of completed work
   - Suggest running `/story-validate` to verify implementation against spec
   
   **CRITICAL: Update tasks.md YAML frontmatter to mark completion**:
   ```yaml
   ---
   status: completed
   ---
   ```
   
   The orchestrator uses `status: completed` to know implementation is done.

8. Next steps:
   ```
   ✅ Story Implementation Complete!
   
   Tasks Completed: [X] of [Y]
   Files Created/Modified: [List]
   Tests Status: [Passing/Failing]
   
   Next Steps:
   1. Review implementation changes
   2. Required: /story-validate (comprehensive validation)
   3. If validation fails: Fix issues and re-run /story-implement
   4. If validation passes: Ready for PR/merge
   
   Note: /story-validate will check:
   - Requirements traceability (all FRs implemented)
   - Test results (all tests passing)
   - Performance targets (if specified)
   - Constitution compliance
   - Generate validation-report.md and pr-description.md
   ```

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/story-tasks` first to regenerate the task list.
