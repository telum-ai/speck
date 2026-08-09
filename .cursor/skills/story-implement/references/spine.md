# story-implement — spine

1. Locate the active story directory (STORY_DIR) and verify ALL prerequisites exist:

   **Step A — Find the story directory**:
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Walk up from current directory until you find `spec.md`
   - If NO `spec.md` found anywhere in the directory tree:
     * ERROR "No story spec found. Run `/story-specify` first to define what to build, then `/story-plan` → `/story-tasks` before implementing."
   - If `spec.md` found but lifecycle state is `Draft (Placeholder)`:
     * ERROR "This story's spec.md is still a Draft placeholder — `/story-specify` has not been run yet. Complete the specification before implementing."

   **Step B — Verify the full prerequisite chain**:
   - Run the deterministic prerequisite check script:
     ```bash
     bash .speck/scripts/validation/check-story-prereqs.sh {STORY_DIR}
     ```
   - `{STORY_DIR}/spec.md` — REQUIRED (ERROR if missing: "Run `/story-specify` first")
   - `{STORY_DIR}/plan.md` — REQUIRED (ERROR if missing: "Run `/story-plan` first")
   - `{STORY_DIR}/tasks.md` — REQUIRED (ERROR if missing: "Run `/story-tasks` first")
   - `{STORY_DIR}/analysis-report.md` — OPTIONAL (v7+: `/story-analyze` is retired — its consistency job runs at the tail of `/story-tasks`, its adversarial job is `/audit`). If a report is present, it must carry no unresolved CRITICALs.

   All three REQUIRED artifacts (spec.md, plan.md, tasks.md) must exist and the prerequisite script must exit with 0 before a single line of implementation code is written.

   ** PRE-IMPLEMENTATION CHECK**:
   The spec↔plan↔tasks consistency cross-check runs at the tail of `/story-tasks`; the adversarial behavior-vs-spec cross-check is `/audit` (`speck-audit`), run AFTER implementation and before `/story-validate`. If an `analysis-report.md` happens to be present, verify it has no unresolved CRITICAL issues:
   - List any CRITICAL issues and refuse to proceed until they are resolved.

2. Load and analyze the implementation context:
   - **RECOMMENDED (v8.8)**: Pull the story's witness-graph context pack in one lookup instead of hand-tracing across artifacts:
     ```bash
     python3 .speck/scripts/graph/speck_graph.py context specs/projects/[PROJECT_ID] [STORY_ID]
     ```
     It returns the promises this story discharges (PRM + source `MM-N`/`JOB-N`/`FR`), the magic moments it serves, its `AC-N` anchors, `depends_on`/`blocks`, and the DECs constraining its epic — so you build against the actual connected intent, not a partial read.
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read plan.md for technical decisions and constraints (research is embedded here)
   - **IF EXISTS**: Read quickstart.md for integration scenarios
   
   **REQUIRED FOR UI STORIES**: Load visual design context:
   - Read `specs/projects/[PROJECT_ID]/design-system.md`
   - Extract and hold in context:
     * **Design Philosophy** — Core principle, emotional keywords, visual vibe, anti-patterns
     * **Bold Choices (Non-Negotiable)** — The specific opinionated rules that define this product's personality
     * **What Success Looks Like** — The feel test for visual quality
   - These sections define what "beautiful" means for THIS project
   - Every UI task must be implemented with these constraints actively in mind
   - Reference: `.cursor/skills/visual-quality/SKILL.md` fires automatically for UI files
   - If design-system.md lacks these sections: WARN "Design system missing Design Philosophy / Bold Choices / What Success Looks Like sections — UI quality will suffer. Consider running /project-design-system to add them."
   
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

7. **Visual Quality Review** (for UI stories — if any tasks created/modified UI files):
   
   Before marking implementation complete, perform a visual self-review:
   
   - Re-read the **Design Philosophy**, **Bold Choices**, and **What Success Looks Like** from design-system.md (loaded in step 2)
   - For each screen/component you created or modified, check:
     * Does it embody the Design Philosophy's core principle?
     * Are ALL Bold Choices (Non-Negotiable) honored? Check each one explicitly.
     * Would it pass the "What Success Looks Like" feel test?
     * Is there intentional typography hierarchy (not flat/boring)?
     * Is negative space active and deliberate (not cramped/random)?
     * Do interactive states (hover/focus/active) feel designed (not browser-default)?
     * Does the UI have texture/depth (not flat/lifeless)?
     * Do components have personality (not generic boilerplate)?

MUST Read `references/spine-2.md` (continuation). Do not stop at this file.
