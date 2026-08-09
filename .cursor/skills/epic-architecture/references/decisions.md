# epic-architecture / decisions

The text the user typed after `/epic-architecture` in the triggering message. Parse any specific architectural concerns or focus areas.

## Context Requirements

This command requires:
- Active epic with epic.md
- Project-level architecture.md (from /project-architecture)
- Ideally run after `/epic-clarify` but before `/epic-plan`

**Research Approach**: Uses just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`) for epic-specific architecture patterns, integration strategies, and technology evaluation

## Epic Architecture Design Process

1. Load context:
   - Current epic.md for scope and requirements
   - Project architecture.md for system design
   - Project PRD for epic relationships
   - Check for existing research reports: epic-*-research-report-*.md (from earlier commands)
   - Check for existing epic-architecture.md

2. Just-In-Time Research (before architectural decisions):
   
   **Reference**: Follow the just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`)
   
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
