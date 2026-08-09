# epic-breakdown / estimates

---
   ```

   The orchestrator reads `depends_on` from `spec.md` to determine which stories are blocked.

   Create story directories:
   ```
   [EPIC_DIR]/
   └── stories/
       ├── S001-technical-setup/
       │   └── spec.md (lifecycle: Draft, depends_on: [] in frontmatter)
       ├── S005-story-name/
       │   └── spec.md (lifecycle: Draft, depends_on: [S004] in frontmatter)
       └── .../
   ```

6. Save as `[EPIC_DIR]/epic-breakdown.md`

6b. **Update Traceability Matrix Mapping (REQUIRED — conservation law)**:
   - Read the existing `[EPIC_DIR]/traceability-matrix.md` (created by `/epic-plan`).
   - For every `PRM-NNN` row, map it to the newly created story and AC ref by filling in the `Discharge (story-id + AC-ref)` column (e.g. `S001 / AC-2`).
   - Update its Status from `open` to `mapped` (or `pilot-gated` if retrofitted/deferred).
   - Verify that there are zero `open` rows left in the matrix. Any unmapped/open rows remaining will block `/epic-analyze` as a P1 unresolved promise.

7. Output summary:
   ```
    Epic Story Breakdown Complete!
   
   Epic: [Name]
   Total Stories: [X]
   
   Phase Breakdown:
   - Phase 1: [Y] stories (setup)
   - Phase 2: [Z] stories (core)
   - Phase 3: [A] stories (integration)  
   - Phase 4: [B] stories (quality)
   
   Parallel Opportunities: [Count]
   Critical Path Length: [Duration]
   
   Story Directories Created: [Count]
   Placeholder specs created: [Count] (spec.md with lifecycle: Draft — awaiting /story-specify)

   Next Steps:
   1. Review story breakdown with team
   2. Run /story-specify on Phase 1 stories to complete the draft specs
   3. Stories marked [P] can be specified/implemented in parallel
   4. Or run /epic-analyze for validation first

   Note: Placeholder specs have lifecycle state "Draft (Placeholder)" in their spec.md.
   /story-specify reads this state and fills in the full specification in-place.
   ```

Note: This breakdown organizes stories for planning and coordination. Each story will generate its own concrete implementation tasks via /story-tasks. Placeholder specs provide a starting point but require /story-specify to reach "Specified" state before planning or implementation.
