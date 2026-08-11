---
name: project-constitution
description: Defines project technical principles. Use after project-context before project-architecture when governance is needed.
---

# project-constitution

## Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/project/constitution-template.md
```
The template defines required sections and formatting for `constitution.md`, including principle categories, rationale format, and constraint declarations. Generating it from memory produces structurally incorrect output.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to Play Level Check.

## Play Level Check

Read `.speck/project.json` (if it exists) for `play_level`.

- **Sprint**: Tell the user: "Sprint projects don't need a constitution. Ship first, structure later. If you're growing to Platform, run `/project-promote` and come back."
- **Build**: Constitution is optional for Build. Only proceed if the user confirms they want it.
- **Platform** (or no project.json): Full flow below — constitution is REQUIRED before project architecture.

---

Define project-specific principles and constraints that will guide all development within this project.

**When to use this command:**
- Regulated industries (healthcare, finance, government)
- Projects with strict performance/security requirements
- Multi-team coordination with clear boundaries needed
- High-stakes projects where failure has serious consequences

**When to skip:**
- Prototypes or MVPs
- Internal tools with flexible requirements
- Well-understood domains with standard practices
- Small projects with single team

1. Load project context:
   - Find active project directory
   - Load project.md to understand project nature and goals
   - Load context.md if exists (constraints and requirements)
   - Check if constitution.md already exists
   
   **Note**: Constitution runs BEFORE planning, so PRD.md doesn't exist yet. Use project.md and context.md for guidance.

2. Just-In-Time Research (if needed):
   
   **Reference**: Follow the just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`)
   
   **Research Areas for Constitution**:
   - **Security Best Practices**: Web search for industry-standard security patterns
   - **Technical Principles**: Web search for framework-specific best practices
   - **Domain Standards**: Web search for industry-specific development standards
   - **Case Studies**: Deep research (if needed) for lessons learned from similar projects
   
   Document findings in "Research Informing This Constitution" section of output.

3. Analyze project needs for specific principles:
   
   **Domain-Specific Requirements**
   - Industry regulations (healthcare, finance, etc.)
   - User safety requirements
   - Data privacy constraints
   - Accessibility standards
   
   **Technical Constraints**
   - Performance requirements
   - Platform limitations  
   - Integration requirements
   - Security standards
   
   **Business Constraints**
   - Time-to-market pressures
   - Budget limitations
   - Team capabilities
   - Stakeholder requirements
   
   **User Experience Principles**
   - Target user needs
   - Interaction patterns
   - Brand requirements
   - Localization needs

4. Generate project constitution using the template:
   
   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/project/constitution-template.md
   ```
   
   Create/update: `specs/projects/[PROJECT_ID]/constitution.md`
   
   Notes:
   - Use normative language (MUST/SHALL/SHOULD/MAY) in all principles and standards.
   - Embed any research findings in the template’s "Research Informing This Constitution" section.
   - If updating an existing constitution, preserve unchanged principles and add a short changelog entry.

5. Interactive principle development:
   
   If no specific requirements provided, ask:
   - "What unique constraints does this project have?"
   - "Are there industry-specific requirements?"
   - "What quality attributes are non-negotiable?"
   - "What would constitute failure for this project?"

6. Principle categories to consider:
   
   **Regulatory Compliance**
   - GDPR, HIPAA, SOX, etc.
   - Industry standards
   - Certification requirements
   
   **Quality Attributes**
   - Performance (specific metrics)
   - Reliability (uptime requirements)
   - Scalability (growth targets)
   - Maintainability (team constraints)
   
   **User Experience**
   - Accessibility (WCAG level)
   - Responsiveness requirements
   - Offline capabilities
   - Cross-platform needs
   
   **Development Process**
   - Review requirements
   - Testing standards
   - Documentation needs
   - Deployment constraints

7. Generate validation checklists:
   - Per-story checklist items
   - Per-epic validation gates
   - Project-level success criteria
   - If two or more principles are mechanically detectable, read `references/enforcement.md` and bind them to repository gates

8. Save as `specs/projects/[PROJECT_ID]/constitution.md`

9. Update references:
   - Add to project.md references section
   - Note in PRD.md compliance section
   - Reference in epic templates

10. Resume the canonical project flow in root `AGENTS.md`; downstream planning and validation inherit this constitution.

Note: Project constitutions are living documents. Update as new requirements emerge or constraints change.
