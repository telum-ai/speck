---
description: Create or update project-specific principles that define technical standards and governance for this project.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

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
   
   **Reference**: Follow the just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`)
   
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

3. Generate project constitution structure:
   ```
   # Project Constitution: [Project Name]
   
   **Version**: 1.0.0
   **Ratified**: [Date]
   **Extends**: Base Constitution v[X.Y.Z]
   
   ## Preamble
   
   This project constitution extends the project constitution with 
   project-specific principles for [Project Name]. These principles 
   are binding for all development within this project and take 
   precedence over base principles where they provide more specific 
   guidance.
   
   ## Core Project Principles
   
   ### I. [Project-Specific Principle Name]
   
   [Statement of principle in clear, actionable terms]
   
   **Rationale**: [Why this principle is necessary for this project]
   
   **Implementation Requirements**:
   - MUST: [Concrete requirement]
   - MUST: [Concrete requirement]
   - SHOULD: [Best practice]
   - MUST NOT: [Prohibition]
   
   **Validation Criteria**:
   - [ ] [How to verify compliance]
   - [ ] [How to verify compliance]
   
   ### II. [Domain-Specific Principle]
   
   [Principle statement]
   
   **Applies To**: [Which epics/areas this affects]
   
   **Examples**:
   - ✅ Good: [Concrete example]
   - ❌ Bad: [What to avoid]
   
   ## Technical Standards
   
   ### Performance Requirements
   - [Specific metric]: [Target]
   - [Specific metric]: [Target]
   
   ### Security Requirements
   - [Standard]: [How applied]
   - [Standard]: [How applied]
   
   ### Integration Standards
   - [System]: [Requirements]
   - [System]: [Requirements]
   
   ## Epic-Specific Principles
   
   ### Epic: [Epic Name]
   - Additional constraints: [List]
   - Success criteria: [List]
   
   ## Validation Gates
   
   ### Story Level
   - [ ] Meets project-specific principles
   - [ ] Passes domain validation
   
   ### Epic Level  
   - [ ] All stories validated
   - [ ] Integration requirements met
   - [ ] Performance targets achieved
   
   ### Project Level
   - [ ] All principles demonstrated
   - [ ] Stakeholder approval received
   - [ ] Production criteria met
   
   ## Amendment Process
   
   Project-specific principles may be amended when:
   1. New regulations or requirements emerge
   2. Technical constraints change
   3. User needs evolution is documented
   
   Amendment requires:
   - Documented rationale
   - Impact analysis
   - Stakeholder approval
   - Version increment
   
   ## Enforcement
   
   These principles are enforced through:
   - Automated validation in CI/CD
   - Code review checklists
   - Epic/story acceptance criteria
   - Project validation gates
   ```

4. Interactive principle development:
   
   If no specific requirements provided, ask:
   - "What unique constraints does this project have?"
   - "Are there industry-specific requirements?"
   - "What quality attributes are non-negotiable?"
   - "What would constitute failure for this project?"

5. Principle categories to consider:
   
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

6. Generate validation checklists:
   - Per-story checklist items
   - Per-epic validation gates
   - Project-level success criteria

7. Save as `[PROJECT_DIR]/constitution.md`

8. Update references:
   - Add to project.md references section
   - Note in PRD.md compliance section
   - Reference in epic templates

9. Output summary:
   ```
   ✅ Project Constitution Created!
   
   Project: [Name]
   Version: 1.0.0
   
   Principles Defined:
   1. [Principle Name]: [Focus area]
   2. [Principle Name]: [Focus area]
   [...]
   
   Validation Points:
   - Story level: [X] checks
   - Epic level: [Y] gates
   - Project level: [Z] criteria
   
   Key Constraints:
   - [Constraint type]: [Requirement]
   - [Constraint type]: [Requirement]
   
   Next Steps:
   1. Review with stakeholders
   2. Distribute to team
   3. Run /project-plan to create PRD (will incorporate these principles)
   4. Configure automated validation (in CI/CD)
   5. Principles will be enforced in epic/story development
   
   Note: Constitution provides essential principle inputs for PRD creation.
   These principles will guide all technical decisions in /project-architecture
   and be enforced throughout epic and story development.
   ```

Note: Project constitutions are living documents. Update as new requirements emerge or constraints change.
