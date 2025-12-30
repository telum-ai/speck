---
description: Create comprehensive project plan with PRD and epic breakdown based on project specification and research.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Generate a Product Requirements Document (PRD) and identify epics based on project specification and upstream artifacts.

**Research Approach**: If planning needs market/business research, uses just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`)

## Subagent Parallelization

This command benefits from parallel execution:

**Epic Spec Drafting** - Spawn parallel speck-scribe:
```
├── [Parallel] speck-scribe: Draft E001 epic.md placeholder
├── [Parallel] speck-scribe: Draft E002 epic.md placeholder
├── [Parallel] speck-scribe: Draft E003 epic.md placeholder
└── [Wait] → Create all epic directories with drafted specs
```

**Research Phase** (if needed) - Spawn parallel speck-researcher:
```
├── [Parallel] speck-researcher: "Market sizing for [domain]"
├── [Parallel] speck-researcher: "Competitor analysis"
├── [Parallel] speck-researcher: "Pricing strategies"
└── [Wait] → Embed findings in PRD
```

**Speedup**: Nx (where N = number of epics) for spec drafting.

1. Load project context and foundation artifacts:
   - Find active project directory (check cwd, then scan specs/projects/)
   - Load and validate project.md
   - Check for existing research reports: *-research-report-*.md (from earlier commands)
   - Check for brownfield artifacts:
     * project-landscape-overview.md (brownfield code analysis)
     * project-import.md (brownfield non-code aspects)
   - **Load REQUIRED foundation artifacts**:
     * **architecture.md** (from /project-architecture) - REQUIRED! Architecture decisions inform planning
     * ux-strategy.md (from /project-ux) - for UX principles and user journeys
     * context.md (from /project-context) - for constraints and requirements
   - **Load OPTIONAL foundation artifacts**:
     * domain-model.md (from /project-domain) - for domain terminology, rules, and principles
     * design-system.md (from /project-design-system) - for UI requirements
     * constitution.md (from /project-constitution) - for technical principles
   - If project.md missing: ERROR "Run /project-specify first"
   - If architecture.md missing: ERROR "Run /project-architecture first - design decisions must inform planning!"
   
   **Check for Active Recipe**:
   - Look for `_active_recipe:` in project.md metadata
   - If found, load `.speck/recipes/[recipe-name]/recipe.yaml`
   - Recipe provides:
     * `suggested_epics:` → Pre-defined epic structure for this project type
     * `external_services:` → Recommended services to consider
     * `patterns:` → Implementation patterns to reference
   - Use recipe's suggested_epics as starting point in Phase 2 (Epic Identification)
   - Customize epic list based on project-specific requirements
   
   **Note**: UX-strategy.md and context.md are strongly recommended. Design-system.md is optional but valuable for UI-heavy projects.

2. Determine project scale (Level 0-4):
   - Analyze project scope and complexity
   - Consider: feature count, user types, integrations, technical complexity
   - Map to scale:
     * Level 0: Single atomic change
     * Level 1: 1-10 stories, 1 epic
     * Level 2: 5-15 stories, 1-2 epics
     * Level 3: 12-40 stories, 2-5 epics
     * Level 4: 40+ stories, 5+ epics

3. Just-In-Time Research (if needed for planning):
   
   If planning requires market/business insights not yet available:
   - **Market Sizing**: Web search for market data, growth trends
   - **Competition**: Web search for competitor analysis
   - **Business Model**: Web search for pricing strategies, monetization patterns
   - **Deep Research** (if needed): Detailed market analysis, business model validation
   
   Document findings in PRD's "Research Informing This Plan" section.

4. Planning execution phases:

   **Phase 1: PRD Generation**
   - Use `.speck/templates/project/prd-template.md`
   - Fill sections with project-specific content
   - **Incorporate architecture decisions** (REQUIRED):
     * Technology stack choices and rationale
     * Architectural patterns and constraints
     * Component structure and boundaries
     * Integration approaches
     * Performance and scalability considerations
   - **Incorporate UX strategy**:
     * UX principles and user journeys from ux-strategy.md
     * Design philosophy and patterns
   - **Incorporate context constraints**:
     * Non-functional requirements from context.md
     * Team skills and infrastructure constraints
     * Compliance and regulatory requirements
   - **Incorporate design system** (if exists):
     * UI component inventory
     * Design token requirements
     * Accessibility standards
   - **Incorporate technical principles** (if exists):
     * Constitution-mandated approaches from constitution.md
   - **Incorporate domain expertise** (if exists):
     * Use domain-model.md glossary terms in PRD consistently
     * Reference domain entities when defining features
     * Ensure domain rules/invariants are respected in requirements
     * Align feature scope with domain principles
   - Incorporate research findings if available
   - Include landscape-overview insights if brownfield
   - Ensure alignment with project.md vision
   - Mark sections as "[To be defined]" only if critical inputs genuinely missing

   **Phase 2: Epic Identification**
   
   **If Active Recipe exists**:
   - Start with recipe's `suggested_epics:` as base structure
   - E000 (Infrastructure) is already in recipe → use as first epic
   - Customize epics marked with `[CUSTOMIZE]` for project-specific features
   - Add/remove epics based on project.md scope
   - Skip optional epics (`optional: true`) unless project needs them
   
   **If No Recipe**:
   - Based on PRD scope, identify logical epic boundaries
   
   **For all epics**:
   - Each epic should:
     * Deliver standalone value
     * Be independently deployable
     * Have clear success criteria
     * Support 3-15 stories typically
   - Consider dependencies between epics
   - **If domain-model.md exists**:
     * Consider organizing epics around domain concepts
     * Use domain terminology in epic names and descriptions
     * Ensure each epic respects domain invariants
   - **Consider business value for prioritization**:
     * Revenue impact (enables monetization, unlocks paid tier)
     * Customer acquisition (improves funnel, reduces CAC)
     * Retention impact (reduces churn, increases LTV)
     * Competitive necessity (table stakes vs differentiation)
     * Market timing (time-sensitive opportunities)
   - Prioritize for MVP vs post-MVP based on:
     * User value + Business value + Technical dependency
     * Highest business ROI + foundational capabilities first
   
   **Phase 2.5: Foundation Check (IMPORTANT)**
   
   Before finalizing epics, check if a Developer Infrastructure epic is needed:
   
   **Ask the user**:
   ```
   🏗️ Foundation Check
   
   Should I include "E000: Developer Infrastructure" epic as the first epic?
   
   This epic sets up:
   - Testing framework (unit, integration tests)
   - CI/CD pipeline (lint, test, build, deploy)
   - Linting & formatting (consistent code style)
   - Error tracking (Sentry or equivalent)
   - Environment configuration (.env patterns)
   
   Recommended: YES for any production-bound project
   Skip only if: Existing infrastructure or throwaway prototype
   
   Include Developer Infrastructure epic? [Y/n]
   ```
   
   **If YES (default)**:
   - Add E000 epic before all other epics
   - Use tech stack from architecture.md to specify testing framework
   - Reference recipe (if used) for tech-specific tooling recommendations
   
   **If NO**:
   - Document skip reason in epics.md
   - Note: User accepts responsibility for infrastructure setup

   **Phase 3: Epic Documentation**
   - Create epics.md using `.speck/templates/project/epics-list-template.md`
   - For each epic include:
     * Epic ID and name
     * Business value statement (user value + business impact)
     * High-level scope
     * Success criteria
     * Dependencies
     * Estimated story count
     * Business metrics (if applicable): Revenue impact, CAC/LTV impact, retention impact

5. PRD structure (adaptive by level):

   **Level 0-1**: Focused PRD
   - Problem & solution (1 page)
   - Single epic with stories
   - Basic requirements list
   - Simple success metrics

   **Level 2**: Standard PRD  
   - Full problem space analysis
   - 1-2 epics with clear boundaries
   - Detailed requirements by epic
   - Phased delivery plan

   **Level 3-4**: Comprehensive PRD
   - Market & competitive analysis
   - 3-5+ epics with dependencies
   - Detailed user journeys
   - Architecture considerations
   - Rollout and adoption strategy

6. Epic identification patterns:

   **By User Journey**
   - Onboarding epic
   - Core workflow epic
   - Admin/settings epic

   **By Technical Layer**
   - Infrastructure epic
   - API/backend epic
   - UI/frontend epic

   **By Feature Area**
   - Authentication epic
   - Data management epic
   - Reporting epic

   **By Release Phase**
   - MVP epic
   - Enhancement epic
   - Scale epic

7. Generate planning artifacts:

   ```
   [PROJECT_DIR]/
   ├── project.md (already exists)
   ├── PRD.md (new - with embedded research if any)
   ├── epics.md (new)
   └── epics/
       ├── E001-[epic-name]/
       ├── E002-[epic-name]/
       └── .../
   ```

8. Epic directory initialization:
   - Create directory for each epic
   - Add placeholder epic.md with:
     * Epic name and ID
     * Initial scope from PRD
     * Dependencies identified
     * Placeholder sections for details
   - Ready for /epic-specify to enhance

9. Validation and review:
   - PRD addresses all project goals
   - Epics cover full scope
   - No gaps or overlaps
   - Dependencies identified
   - Success metrics clear

10. Output summary:
   ```
   ✅ Project Planning Complete!
   
   Project: [Name]
   Scale: Level [0-4]
   
   Documents Generated:
   - PRD.md (Product Requirements Document with embedded research)
   - epics.md (Epic breakdown)
   
   Epic Summary:
   1. [Epic Name]: ~[X] stories
   2. [Epic Name]: ~[X] stories
   [...]
   
   Total Estimated Scope: ~[X] stories
   
   Next Steps:
   1. Review PRD with stakeholders
   2. Validate epic boundaries
   3. Optional: /project-roadmap (for epic timeline and dependencies)
      - If you intentionally skipped /project-design-system and later decide you need it, run /project-design-system and then update PRD.md accordingly (or re-run /project-plan to re-synthesize PRD + epics with design-system inputs).
   4. Quality gates:
      - /project-analyze (deep quality analysis)
      - /project-validate (go/no-go decision)
   5. Begin epic development:
      - cd epics/E001-[epic-name]
      - /epic-specify (enhances the placeholder epic.md)
      - /epic-clarify (if needed)
      - /epic-plan (generates tech spec)
      
   Note: Epic placeholder files are created with basic structure.
   Running /epic-specify in each epic directory will complete the specification.
   ```

11. Important notes:
    - For Level 0-1: Can skip epic level, go directly to story
    - For Level 3-4: Epic planning is critical for success
    - PRD is living document - update as learning occurs
    - Epic boundaries can be adjusted based on implementation learning
