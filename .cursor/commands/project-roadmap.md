---
description: Create an epic execution timeline showing sequencing, dependencies, and resource allocation for project delivery.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Create a project-level roadmap that shows epic execution timeline, dependencies, resource allocation, and parallel execution opportunities. This is NOT about development tasks - it's about project management and epic orchestration.

1. Load project planning artifacts:
   - Find active project directory
   - Load PRD.md and epics.md (required)
   - Load any epic-level plans if they exist
   - If missing: ERROR "Run /project-plan first to identify epics"

2. Analyze epic relationships:
   
   **Dependency Types**
   - Hard dependencies (Epic B requires Epic A complete)
   - Soft dependencies (Epic B benefits from Epic A)
   - No dependency (Can run in parallel)
   
   **Risk Assessment**
   - Technical risk (unknowns, complexity)
   - Business risk (user impact, revenue)
   - Integration risk (external dependencies)

3. Determine execution strategy:
   
   **Sequential Strategy** (Level 0-2)
   - One epic at a time
   - Clear handoffs
   - Lower coordination overhead
   
   **Parallel Strategy** (Level 3-4)
   - Multiple epics in flight
   - Requires more coordination
   - Faster overall delivery
   
   **Hybrid Strategy**
   - Critical path sequential
   - Independent work parallel
   - Risk-based approach

4. Generate project roadmap structure:
   ```
   # Project Roadmap: [Project Name]
   
   **Strategy**: [Sequential/Parallel/Hybrid]
   **Timeline**: [Estimated duration]
   **Team Size**: [Recommended]
   
   ## Epic Execution Plan
   
   ### Phase 1: Foundation
   - [ ] E001 [Epic Name] (~[X] stories)
     - **Why First**: [Rationale]
     - **Duration**: [Estimate]
     - **Team**: [Size/Skills needed]
     - **Success Gate**: [What marks completion]
   
   ### Phase 2: Core Features [Can run parallel]
   - [ ] E002 [Epic Name] (~[X] stories) [P]
   - [ ] E003 [Epic Name] (~[X] stories) [P]
     - **Dependencies**: None (can run parallel)
     - **Duration**: [Estimate]
     - **Teams**: [How to split]
   
   ### Phase 3: Enhancement [Depends on Phase 2]
   - [ ] E004 [Epic Name] (~[X] stories)
     - **Dependencies**: E002, E003 complete
     - **Duration**: [Estimate]
   
   ## Execution Timeline
   
   ```
   Week 1-4:   [E001: Foundation Epic]
   Week 5-8:   [E002: Feature A] [P]
               [E003: Feature B] [P]
   Week 9-12:  [E004: Integration]
   Week 13-14: [Project validation & launch]
   ```
   
   ## Risk Mitigation Plan
   
   | Epic | Risk | Mitigation | Trigger |
   |------|------|-----------|---------|
   | E001 | [Risk] | [Action] | [When to act] |
   
   ## Resource Allocation
   
   ### Team Structure
   - **Team A**: E001, then E002
   - **Team B**: E003, then E004
   - **Shared**: Architecture, DevOps
   
   ### Skill Requirements by Phase
   | Phase | Skills Needed | Source |
   |-------|--------------|--------|
   | 1 | [List skills] | [Team/Hire/Contract] |
   
   ## Success Metrics Tracking
   
   ### Per Epic
   - E001: [Key metric] = [Target]
   - E002: [Key metric] = [Target]
   
   ### Project Level
   - Overall: [Metric] = [Target]
   - Launch criteria: [List]
   ```

5. Create parallel execution examples:
   ```
   ## Parallel Execution Commands
   
   When Phase 2 begins, run these in parallel:
   
   Terminal 1:
   /epic-specify "E002: [Epic Name]"
   /epic-plan
   /epic-breakdown
   
   Terminal 2:  
   /epic-specify "E003: [Epic Name]"
   /epic-plan
   /epic-breakdown
   ```

6. Integration checkpoints:
   - After each epic completes
   - Before dependent epics begin
   - At phase boundaries
   - Pre-launch validation

7. Generate visual timeline:
   ```
   Epic Timeline:
   
   E001: |████████████████|                           Foundation
   E002:                  |████████████|              Feature A
   E003:                  |████████████|              Feature B
   E004:                                |████████|    Integration
   ```

8. Save as `[PROJECT_DIR]/project-roadmap.md`

9. Output summary:
   ```
   ✅ Project Roadmap Generated!
   
   Execution Strategy: [Type]
   Total Epics: [X]
   
   Phase Breakdown:
   - Phase 1: [X] epics ([Y] weeks)
   - Phase 2: [X] epics ([Y] weeks)
   - Phase 3: [X] epics ([Y] weeks)
   
   Parallel Opportunities: [X] epics can run simultaneously
   
   Critical Path: E001 → E004 ([X] weeks minimum)
   
   Next Steps:
   1. Review execution plan with team
   2. Assign epic owners
   3. Begin Phase 1:
      /epic-specify "E001: [Epic Name]"
   ```

Note: This provides project-level orchestration and timeline. Each epic will have its own story breakdown via /epic-breakdown.
