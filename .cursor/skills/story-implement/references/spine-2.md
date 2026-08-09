# story-implement — spine (cont. 2)

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
   
   The orchestrator uses `status: completed` to know implementation is done.

9. Next steps:
   ```
    Story Implementation Complete!
   
   Tasks Completed: [X] of [Y]
   Files Created/Modified: [List]
   Full Pre-Commit Gate: [PASSED/FAILED]
   - Eslint/Lint: [Passing/Failing/Skipped]
   - Typecheck (Tsc): [Passing/Failing/Skipped]
   - Tests (Vitest/Jest): [Passing/Failing/Skipped]
   - Build compiled: [Passing/Failing/Skipped]
   - Banned-language lint: [Passing/Failing/Skipped]
   UI Self-Review Grade: [BEAUTIFUL/ACCEPTABLE/NEEDS_WORK]
   
   CRITICAL CANONICAL ORDERING RULE (Speck v7.3):
   You are NOT allowed to bypass the v7 validation gate. To-dos or other story work cannot begin until this story is fully proved.
   
   The hard-enforced next steps are:
   1. Run `/audit` (skeptical audit) to generate `audit-report.md` in this story directory.
   2. Run `/story-validate` (evidence-backed validation) to generate `validation-report.md`.
   3. Run `/story-retrospective` to capture learnings.
   
   Note: `/story-validate` will verify:
   - Presence of `audit-report.md` with zero critical/P0 issues.
   - Requirements traceability (all FRs implemented)
   - Test results (all tests passing)
   - Performance targets (if specified)
   - Constitution compliance
   - Appropriate Project Archetype proof rules from `evidence-contract.md` (Option A LARP or Option B stress tests).
   ```

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/story-tasks` first to regenerate the task list.
