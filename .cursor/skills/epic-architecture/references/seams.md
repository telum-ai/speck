# epic-architecture / seams

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
