---
description: Design the technical architecture for a specific epic within the project's system architecture.
---

User input:

$ARGUMENTS

The text the user typed after `/epic-architecture` in the triggering message. Parse any specific architectural concerns or focus areas.

## Context Requirements

This command requires:
- Active epic with epic.md
- Project-level architecture.md (from /project-architecture)
- Ideally run after `/epic-clarify` but before `/epic-plan`

**Research Approach**: Uses just-in-time research pattern (`.cursor/rules/speck/patterns/just-in-time-research.mdc`) for epic-specific architecture patterns, integration strategies, and technology evaluation

## Epic Architecture Design Process

1. Load context:
   - Current epic.md for scope and requirements
   - Project architecture.md for system design
   - Project PRD for epic relationships
   - Check for existing research reports: epic-*-research-report-*.md (from earlier commands)
   - Check for existing epic-architecture.md

2. Just-In-Time Research (before architectural decisions):
   
   **Reference**: Follow the just-in-time research pattern (`.cursor/rules/speck/patterns/just-in-time-research.mdc`)
   
   Before designing epic architecture, identify knowledge gaps and conduct research:
   
   ### Research Areas for Epic Architecture
   
   **1. Integration Patterns**:
   - Decision: How should this epic integrate with existing system?
   - Web Search: API integration patterns, event-driven architectures, service mesh patterns
   - Deep Research (if needed): Complex integration scenarios, third-party API evaluation
   
   **2. Data Architecture**:
   - Decision: What data storage/flow patterns should we use?
   - Web Search: Database schema patterns, caching strategies, data synchronization
   - Deep Research (if needed): Complex data modeling, multi-tenant architectures
   
   **3. Technology Evaluation** (if new tech for epic):
   - Decision: Should we use [library/framework] for this epic?
   - Web Search: Library comparisons, benchmarks, compatibility checks
   - Deep Research (if needed): Technology proof-of-concept recommendations
   
   **4. Performance Patterns**:
   - Decision: What optimizations are needed for this epic?
   - Web Search: Performance benchmarks, optimization techniques, caching patterns
   - Deep Research (if needed): Complex performance analysis
   
   **5. Security Architecture** (if security-critical):
   - Decision: How do we secure this epic's functionality?
   - Web Search: Security patterns, authentication/authorization approaches, threat models
   - Deep Research (if needed): Security audit recommendations, compliance requirements
   
   ### Execute Research
   
   For each area with knowledge gaps:
   1. **Quick web search** for patterns and best practices
   2. **Generate deep research prompt** if web search insufficient
   3. **Document findings** in "Research Informing This Architecture" section of output
   
   If deep research needed, PAUSE and instruct user:
   ```
   ⏸️ Deep Research Needed
   
   Topic: [Research Area]
   Prompt Generated: epic-architecture-research-prompt-[topic].md
   
   Please:
   1. Review research prompt in epic directory
   2. Run in Perplexity/Claude/Gemini/Grok
   3. Save results as: epic-architecture-research-report-[topic].md
   4. Re-run this command to continue
   ```

3. Analyze epic architectural needs:
   - Epic's role in system architecture
   - Integration points with other epics
   - Data dependencies
   - Performance requirements
   - Security considerations
   - Scalability needs specific to epic

3. Design epic architecture:
   
   **Component Design**:
   - Identify epic-specific components
   - Define component responsibilities
   - Map component interactions
   - Establish clear boundaries
   
   **Data Architecture**:
   - Epic's data models
   - Data flow within epic
   - Storage requirements
   - State management approach
   
   **API Design**:
   - External APIs epic exposes
   - Internal APIs epic consumes
   - Event contracts
   - Error handling strategies

4. Integration architecture:
   - How epic fits into system architecture
   - Dependencies on other epics/services
   - Consumers of epic's functionality
   - Shared components usage
   - Data synchronization needs

5. Technical decisions:
   - Technology choices within project stack
   - Epic-specific libraries/frameworks
   - Design patterns to apply
   - Caching strategies
   - Background job handling

6. Generate epic-architecture.md:
   - Load template from `.speck/templates/epic/architecture-template.md`
   - Fill all sections with epic-specific details
   - **Add "Research Informing This Architecture" section** documenting:
     * Web search findings with sources
     * Deep research reports referenced (if any)
     * How research influenced architectural decisions
   - Create clear diagrams
   - Document all decisions

7. Validate against project architecture:
   - Ensure alignment with system design
   - Verify technology stack consistency
   - Check integration points
   - Confirm scalability approach

8. Output summary:
   ```
   ✅ Epic Architecture Designed!
   
   Epic: [Name]
   Pattern: [Architecture pattern]
   Components: [Number]
   
   Key Design Decisions:
   - [Decision 1]
   - [Decision 2]
   
   Integration Points:
   - Depends on: [List]
   - Consumed by: [List]
   
   Next Steps:
   - Required: /epic-plan (create tech spec)
   - Then: /epic-breakdown (map stories)
   - Optional: /epic-analyze (validate design)
   ```

## Architecture Coherence

Ensure epic architecture:
- ✓ Aligns with project architecture
- ✓ Respects system boundaries
- ✓ Uses consistent patterns
- ✓ Follows project technology stack
- ✓ Maintains security model
- ✓ Supports performance goals
- ✓ Enables testability
- ✓ Facilitates maintenance

## Relationship to Other Commands

```
/epic-specify → /epic-clarify → /epic-architecture → /epic-plan → /epic-breakdown
                                          ↓
                              (informs tech-spec.md)
```

The epic architecture:
- Provides detailed design for /epic-plan
- Guides story breakdown in /epic-breakdown
- Informs implementation in stories
- Establishes testing boundaries

## Notes

- Epic architecture should be detailed enough to guide implementation
- But not so detailed it constrains story-level decisions
- Focus on interfaces, boundaries, and integration
- Leave implementation details for stories
- Update if significant changes occur during development
