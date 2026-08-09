# epic-architecture / epic-architecture-design-process

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
   
   If deep research needed, PAUSE and instruct user:
   ```
   ⏸ Deep Research Needed
   
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
