# project-constitution — full procedure (2)

   
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

8. Save as `specs/projects/[PROJECT_ID]/constitution.md`

9. Update references:
   - Add to project.md references section
   - Note in PRD.md compliance section
   - Reference in epic templates

10. Output summary:
   ```
    Project Constitution Created!
   
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
