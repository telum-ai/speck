# story-implement / ui

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
   - If ANY check fails: **iterate on the implementation before proceeding**
   - Grade your UI: BEAUTIFUL / ACCEPTABLE / NEEDS_WORK / UGLY
   - If NEEDS_WORK or UGLY: fix it now. Functionally correct is NOT done.
   
   Include the grade in the completion summary.

8. Completion validation:
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
