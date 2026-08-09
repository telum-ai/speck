# story-implement / backend

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
