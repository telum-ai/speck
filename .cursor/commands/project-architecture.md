---
description: Design comprehensive system architecture that serves as the technical blueprint for the entire project.
---

User input:

$ARGUMENTS

The text the user typed after `/project-architecture` in the triggering message. Parse any architecture focus areas or constraints.

## Context Requirements

This command requires:
- Active project with project.md
- **Required**: `/project-context` (constraints that architecture must work within)
- Recommended: ux-strategy.md (for user experience alignment)
- Recommended: constitution.md (for technical principles)
- Recommended: Existing research reports (check project dir for *-research-report-*.md)
- Optional: project-landscape-overview.md (brownfield architecture extraction)
- Optional: project-import.md (brownfield non-code aspects)

**Position in Flow**: Runs AFTER context/constitution, BEFORE planning (architecture decisions inform planning!)

**Research Approach**: Uses just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`) for technology evaluation and architecture patterns

## Architecture Design Process

1. Load project context and detect mode:
   - Find active project directory
   - Load project.md for vision and scope
   - Load context.md for constraints and requirements (REQUIRED)
   - Load constitution.md if exists (for technical principles)
   - Check for existing research reports: *-research-report-*.md (for informed decisions)
   - Load project-landscape-overview.md if exists (brownfield extraction)
   - Load project-import.md if exists (brownfield non-code)
   - Check for existing architecture.md
   
   **Determine Architecture Mode**:
   - **BROWNFIELD MODE** (if project-landscape-overview.md exists):
     * Extract existing architecture from landscape overview
     * Document current state ("as-is")
     * Identify what to keep vs refactor
     * Propose evolution path ("to-be")
   
   - **GREENFIELD MODE** (if no landscape overview):
     * Design architecture from scratch
     * Ask architecture questions interactively
     * Make technology choices based on context constraints
     * **Use just-in-time research for technology evaluation**
   
   **IMPORTANT**: 
   - Architecture must work within context.md constraints!
   - If landscape-overview exists, document existing architecture first!
   - Architecture decisions will feed into project-plan for realistic epic breakdown

2. **Just-In-Time Research** (BOTH modes - before architectural decisions):
   
   **Reference**: Follow the just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`)
   
   Before making architecture decisions (greenfield) or proposing evolution (brownfield), conduct research for:
   
   ### Research Areas for Architecture
   
   **1. Technology Stack Evaluation** (greenfield or when considering new tech):
   - Decision: What framework/platform should we use for [component]?
   - Web Search: Framework comparisons, benchmarks, compatibility
   - Deep Research (if needed): Technology proof-of-concept evaluation
   
   **2. Architecture Patterns** (both modes):
   - Decision: What pattern best fits [requirements]?
   - Web Search: Pattern recommendations (monolith, microservices, etc.), case studies
   - Deep Research (if needed): Pattern evaluation for specific domains
   
   **3. Performance Benchmarks** (both modes):
   - Decision: Can [technology] handle [scale requirements]?
   - Web Search: Scalability data, performance benchmarks
   - Deep Research (if needed): Detailed performance analysis
   
   **4. Integration Patterns** (both modes):
   - Decision: How should [system A] integrate with [system B]?
   - Web Search: API design best practices, integration patterns
   - Deep Research (if needed): Complex integration scenarios
   
   **5. Migration Strategies** (brownfield evolution):
   - Decision: How do we migrate from [old tech] to [new tech]?
   - Web Search: Migration patterns, compatibility layers
   - Deep Research (if needed): Complex migration strategies
   
   ### Execute Research
   
   For each area with knowledge gaps:
   1. **Quick web search** for standards and best practices
   2. **Generate deep research prompt** if web search insufficient
   3. **Document findings** in "Research Informing This Architecture" section of output
   
   If deep research needed, PAUSE and instruct user:
   ```
   ⏸️ Deep Research Needed
   
   Topic: [Research Area]
   Prompt Generated: project-architecture-research-prompt-[topic].md
   
   Please:
   1. Review research prompt in project directory
   2. Run in Perplexity/Claude/Gemini/Grok
   3. Save results as: project-architecture-research-report-[topic].md
   4. Re-run this command to continue
   ```

3. **BROWNFIELD MODE** - Extract from Landscape Overview:
   
   If `project-landscape-overview.md` exists, use it to document existing architecture:
   
   **Extract from Landscape Overview**:
   - System architecture pattern (from "Architecture Overview" section)
   - Component breakdown (from "Code Organization" section)
   - Technology stack (from "Tech Stack" section)
   - Data models (from "Data & State" section)
   - API patterns (from "Integration Points" section)
   - Deployment approach (from "Deployment" section)
   - Patterns in use (from scan findings)
   
   **Document Current State**:
   - List all existing components and their roles
   - Document current technology choices with rationale
   - Identify integration patterns already in use
   - Note architecture strengths from scan
   
   **Identify Evolution Needs**:
   - Review "Risks & Technical Debt" section from landscape overview
   - Note any anti-patterns discovered
   - Propose refactoring priorities aligned with context.md constraints
   - Define migration path if technology changes needed
   
   **Then proceed to step 4** to generate architecture document

3. **GREENFIELD MODE** - Interactive architecture decisions:
   
   **Core Architecture Questions:**
   - "What's the primary architectural pattern? (monolithic/microservices/serverless/event-driven)"
   - "What are the main deployment targets? (cloud/on-premise/hybrid/edge)"
   - "What are the critical quality attributes? (performance/security/scalability/reliability)"
   
   **Technology Stack Questions:**
   - "Frontend framework preference? (or 'none' for backend-only)"
   - "Backend language/framework preference?"
   - "Database requirements? (relational/document/graph/time-series)"
   - "Any specific integration requirements?"
   
   **Align with Context**:
   - Verify choices work within context.md constraints
   - Ensure tech stack matches team skills (from context.md)
   - Confirm deployment approach matches infrastructure constraints

4. Generate architecture document:
   - Load template from `.speck/templates/project/architecture-template.md`
   - Fill in all sections based on mode:
   
   **For BROWNFIELD**:
     * Existing architecture from landscape overview
     * Current technology stack (from scan)
     * Established patterns (keep what works)
     * Identified issues and evolution path
     * Project constraints from context.md
   
   **For GREENFIELD**:
     * Project vision and goals from project.md
     * Architectural decisions made interactively
     * Best practices for chosen stack
     * Alignment with research findings (if exists)
     * Project constraints from context.md
   
5. Architecture components to address:
   - System-wide component design
   - Technology stack justification
   - Data architecture strategy
   - Security architecture
   - Performance architecture
   - Scalability planning
   - Integration architecture
   - Deployment architecture
   - Operational considerations

6. Cross-reference with epics:
   - Ensure architecture supports all epics
   - Identify shared components
   - Define integration points
   - Establish data flow between epics

7. Risk and trade-off analysis:
   - Identify architectural risks
   - Document trade-offs made
   - Propose mitigation strategies
   - Define evolution path

8. Save architecture.md with:
   - Clear diagrams (ASCII or Mermaid)
   - Technology decisions with rationale
   - Component responsibilities
   - Integration strategies
   - Deployment approach
   - Operational requirements

9. Output summary (mode-specific):
   
   **For BROWNFIELD**:
   ```
   ✅ Project Architecture Documented!
   
   Mode: BROWNFIELD (extracted from codebase scan)
   Architecture Pattern: [Pattern from scan]
   Primary Stack: [Technologies from scan]
   
   Current State:
   - [Components documented]
   - [Patterns identified]
   - [Integration points mapped]
   
   Technical Debt:
   - [Issue 1 from scan]
   - [Issue 2 from scan]
   
   Evolution Path:
   - [Refactoring priority 1]
   - [Refactoring priority 2]
   
   Next Steps:
   - Review architecture document
   - Validate against current implementation
   - Plan refactoring epics if needed
   - Continue with /project-validate
   ```
   
   **For GREENFIELD**:
   ```
   ✅ Project Architecture Designed!
   
   Mode: GREENFIELD (designed from requirements)
   Architecture Pattern: [Pattern chosen]
   Primary Stack: [Technologies chosen]
   
   Key Decisions:
   - [Decision 1 with rationale]
   - [Decision 2 with rationale]
   - [Decision 3 with rationale]
   
   Risk Factors:
   - [Risk 1 with mitigation]
   - [Risk 2 with mitigation]
   
   Next Steps:
   - Recommended: /project-roadmap (epic timeline and resource allocation)
   - Then: /project-validate (architecture and plan review)
   - If approved: Begin epic development
   - For each epic: /epic-specify → /epic-architecture → /epic-plan
   ```

## Architecture Validation

Ensure the architecture:
- ✓ Supports all functional requirements
- ✓ Meets non-functional requirements
- ✓ Aligns with team capabilities
- ✓ Fits within constraints (time, budget, resources)
- ✓ Provides clear epic boundaries
- ✓ Enables independent epic development
- ✓ Includes operational requirements
- ✓ Addresses security concerns
- ✓ Plans for scale

## Integration with Existing Flow

This command fits in Phase 3 (Technical Design) BEFORE planning:

```
Phase 2: Foundation
/project-ux → /project-context → /project-constitution

Phase 3: Technical Design (BEFORE planning!)
/project-architecture → /project-design-system

Phase 4: Planning
/project-plan (creates PRD using foundation + architecture inputs)

Phase 5: Validation
/project-validate
```

The architecture informs:
- Epic technical specifications
- Technology choices in stories
- Integration approaches
- Deployment strategies
- Operational requirements

## Example Workflows

### Brownfield Example (Existing App)
```
1. Run /project-scan → Generates project-landscape-overview.md
2. Run /project-architecture:
   - Detects scan exists → BROWNFIELD MODE
   - Extracts: "Modular monolithic, FastAPI + React, 14 models"
   - Documents: Current component boundaries, WebSocket handlers
   - Identifies: Claude AI placeholder, Capacitor missing
   - Proposes: Migration to Capacitor, Claude integration
3. Output: architecture.md with as-is + to-be sections
```

### Greenfield Example
```
1. Run /project-plan → No existing code
2. Run /project-architecture:
   - No scan found → GREENFIELD MODE
   - Asks: Architecture pattern, deployment targets, tech stack
   - Designs: Component structure, integration approach
   - Documents: Technology choices with rationale
3. Output: architecture.md with design from scratch
```

## Notes

- **For small projects (Level 0-1)**: Architecture might be minimal or skipped
- **For large projects (Level 3-4)**: Architecture is critical for success
- **For brownfield**: Always run `/project-scan` first to extract existing architecture
- **For greenfield**: Use research and planning to inform architecture decisions
- Architecture should be living document, updated as project evolves
- Consider running `/project-refine` later to update architecture
