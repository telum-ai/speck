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

4. Generate project roadmap:
   
   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/project/roadmap-template.md
   ```
   
   Write output to: `[PROJECT_DIR]/project-roadmap.md`

5. Output summary:
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
