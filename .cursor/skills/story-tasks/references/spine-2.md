# story-tasks — spine (cont. 2)

   - Extracted patterns → Pattern references in task descriptions
   - Extracted performance targets → Performance notes in tasks
   - Extracted security requirements → Security checklists in tasks
   - Extracted design components → Design System references in UI tasks
   - Extracted brand voice → Copy examples in UI tasks

   Write output to `{STORY_DIR}/tasks.md`.

   The tasks.md should be immediately executable - each task must be specific enough 
   that an LLM can complete it **with the context provided in the task description** 
   (not requiring separate research).

4. Consistency cross-check (folds in the retired `/story-analyze` — do NOT skip):
   Before reporting done, reconcile the three artifacts against each other and list any conflicts inline (resolve them or flag CRITICAL):
   - **Coverage** — every `FR-XXX` / acceptance scenario in `spec.md` maps to ≥1 task, and every task traces back to a requirement (no orphan tasks, no uncovered requirements).
   - **Plan alignment** — tasks use the tech stack, file paths, and patterns from `plan.md`; no task contradicts a plan decision or constitution gate.
   - **UI completeness** — if `ui-spec.md` exists, every declared screen / state / asset has a task.
   - **Dependency sanity** — task ordering respects `depends_on`; no task depends on a later task.
   This is the **pre-implementation** consistency gate. If a CRITICAL conflict can't be resolved here, fix `spec.md`/`plan.md`/`tasks.md` before implementing. The **adversarial** behavior-vs-spec check is `/audit`, run AFTER implementation.

5. Output summary:
   ```
    Story Tasks Generated!
   
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
   Consistency cross-check: [PASS | N conflicts resolved | N CRITICAL open]
   
   Next Steps:
   1. Review task breakdown + the consistency cross-check result above
   2. Then: /story-implement (execute the tasks)
   3. Then: /audit (adversarial behavior-vs-spec check — non-skippable, by a separate auditor)
   4. Finally: /story-validate (declare a readiness state with evidence)
   
   Note: /story-implement will execute these tasks in order,
   running parallel tasks [P] simultaneously for efficiency.
   ```
