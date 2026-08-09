# project-constitution / enforcement

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
   4. Configure automated validation (in CI/CD)
   5. Principles will be enforced in epic/story development
   
   Note: Constitution provides essential principle inputs for PRD creation.
   These principles will guide all technical decisions in /project-architecture
   and be enforced throughout epic and story development.
   ```

Note: Project constitutions are living documents. Update as new requirements emerge or constraints change.
