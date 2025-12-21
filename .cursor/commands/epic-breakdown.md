---
description: Create story mapping showing all stories within the epic, their dependencies, and parallelization opportunities.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Create a comprehensive story breakdown that maps all user stories within the epic, showing dependencies, parallelization opportunities, and suggested implementation order. This is NOT about concrete development tasks - it's about story organization and sequencing.

1. Load epic implementation context:
   - Epic specification (epic.md)
   - Technical specification (epic-tech-spec.md) - required (includes embedded research)
   - Epic codebase scan (epic-codebase-scan.md) - if exists, for brownfield code analysis
   - Project constraints from PRD
   - If tech spec missing: ERROR "Run /epic-plan first"
   
   **Brownfield Adaptation**: If epic-codebase-scan.md exists, use it to identify existing code that needs refactoring or enhancement as part of story breakdown.
   
   **Note**: Research is now embedded in epic-tech-spec.md - no separate research.md file to load.

2. Story extraction and analysis:
   - Extract all user stories from epic.md
   - Map to technical implementation from tech spec
   - Identify story dependencies
   - Determine parallelization opportunities

3. Story breakdown approach:

   **User Stories**
   - Extract all user stories from epic.md
   - Map to technical approach from tech spec
   - Include acceptance criteria
   - Identify dependencies between stories

   **Technical Stories**
   - Infrastructure setup stories
   - Integration stories
   - Migration stories
   - Configuration stories

   **Quality Stories**
   - Testing stories
   - Documentation stories
   - Performance validation stories
   - Security review stories

4. Generate epic breakdown structure:
   ```
   # Epic Story Breakdown: [Epic Name]
   
   **Epic**: [ID and Name]
   **Total Stories**: [Count]
   **Dependencies**: [Other epics]
   **Estimated Duration**: [Timeframe]
   
   ## Story Organization
   
   ### Phase 1: Foundation Setup
   - [ ] S001 [Technical setup task]
     - **Type**: Technical
     - **Details**: [What to set up]
     - **References**: Tech spec section X
     - **Duration**: [Estimate]
   
   - [ ] S002 [Database setup] [P]
   - [ ] S003 [API scaffolding] [P]
     - Can run in parallel (different concerns)
   
   ### Phase 2: Core Stories
   - [ ] S004 [User Story 1.1 implementation]
     - **Story**: "As a [user], I want to [action]..."
     - **Technical Approach**: [From tech spec]
     - **Components**: [List what to build]
     - **APIs**: [Endpoints to implement]
     - **Tests**: [Test scenarios]
     - **References**: epic-tech-spec.md#story-1-1
     - **Duration**: [Estimate]
   
   - [ ] S005 [User Story 1.2 implementation]
     - **Story**: "As a [user], I want to [action]..."
     - **Depends on**: S004
     - [Similar details...]
   
   ### Phase 3: Integration Stories [Parallel]
   - [ ] S010 [Story 2.1] [P]
   - [ ] S011 [Story 2.2] [P]
   - [ ] S012 [Story 2.3] [P]
     - These can run in parallel (independent features)
   
   ### Phase 4: Quality & Polish
   - [ ] S020 [Integration testing]
   - [ ] S021 [Performance optimization]
   - [ ] S022 [Documentation]
   - [ ] S023 [Security review]
   
   ## Story Details
   
   ### S004: [Full Story Name]
   
   **User Story**: 
   As a [user type], I want to [action] so that [benefit]
   
   **Acceptance Criteria**:
   - Given [context], when [action], then [outcome]
   - Given [context], when [action], then [outcome]
   
   **Technical Implementation**:
   1. Create component: [Name and purpose]
   2. Implement API: [Endpoint details]
   3. Add state management: [Approach]
   4. Connect to backend: [Integration]
   
   **Code Patterns**: [Reference to tech spec]
   
   **Test Coverage**:
   - Unit: [What to test]
   - Integration: [Scenarios]
   - E2E: [User journey]
   
   ### [Continue for each story...]
   
   ## Execution Strategy
   
   ### Parallel Execution Groups
   
   **Group A** (Can run simultaneously):
   - S002, S003 (Different layers)
   
   **Group B** (After Phase 1):
   - S010, S011, S012 (Independent features)
   
   ### Critical Path
   S001 → S004 → S005 → S020 → Complete
   
   ### Resource Allocation
   - Phase 1: 1 developer
   - Phase 2: 2 developers  
   - Phase 3: 3 developers (parallel)
   - Phase 4: 2 developers
   
   ## Dependencies
   
   ### External Dependencies
   - [Service/API]: Needed by [Story]
   - [Library]: Needed by [Story]
   
   ### Inter-Story Dependencies  
   | Story | Depends On | Provides To |
   |-------|-----------|-------------|
   | S005 | S004 | S020 |
   
   ## Risk Mitigation
   
   | Story | Risk | Mitigation |
   |-------|------|------------|
   | S004 | [Risk] | [Action] |
   
   ## Definition of Done
   
   Per Story:
   - [ ] Code implemented and reviewed
   - [ ] Unit tests passing (>80% coverage)
   - [ ] Integration tests passing
   - [ ] Documentation updated
   - [ ] Acceptance criteria verified
   
   Epic Complete:
   - [ ] All stories done
   - [ ] E2E tests passing
   - [ ] Performance targets met
   - [ ] Security scan clean
   - [ ] Stakeholder sign-off
   ```

5. Create story directories:
   ```
   [EPIC_DIR]/
   └── stories/
       ├── S001-technical-setup/
       ├── S004-story-name/
       └── .../
   ```

6. Execution examples:
   ```
   ## Parallel Execution Example
   
   # Terminal 1:
   cd stories/S002-database-setup
   /story-specify
   /story-implement
   
   # Terminal 2:
   cd stories/S003-api-scaffolding
   /story-specify
   /story-implement
   ```

7. Save as `[EPIC_DIR]/epic-breakdown.md`

8. Output summary:
   ```
   ✅ Epic Story Breakdown Complete!
   
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
   
   Next Steps:
   1. Review task breakdown with team
   2. Begin Phase 1:
      cd stories/S001-*
      /story-specify
   3. Or run /epic-analyze for validation
   ```

Note: This breakdown organizes stories for planning and coordination. Each story will generate its own concrete implementation tasks via /story-tasks.
