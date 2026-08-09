# story-tasks / api-tasks

- Business rules and constraints (include in service tasks)
   
   **IF EXISTS: Read contracts/** for API endpoints:
   - Endpoint paths and methods
   - Request/response schemas (include in test tasks)
   - Error responses (include in error handling tasks)
   
   **IF EXISTS: Read quickstart.md** for test scenarios:
   - Integration test scenarios
   - Validation steps (use as acceptance criteria in tasks)
   
   **UI Spec Gate (if UI-heavy)**:
   - If this story includes UI components (forms/pages/interactive states) and `{STORY_DIR}/ui-spec.md` is missing:
     - STOP and instruct the user to run `/story-ui-spec` first
     - (UI spec is produced after `/story-plan`, and is required before `/story-tasks` for UI-heavy stories)
   
   **IF EXISTS: Read ui-spec.md** for UI implementation requirements:
   - States, variants, and responsive behavior
   - Accessibility requirements and keyboard interactions
   - Design tokens + component usage rules
   - Microcopy/content guidelines
   - **Visual Assets Manifest** (Required Assets table) — Extract all declared assets (logos, SVGs, WebP illustrations)
   - Use these details to generate concrete UI tasks, including:
     * **Specific Visual Asset Creation / Optimisation Tasks**: If assets are declared in the ui-spec.md table, automatically generate concrete task(s) in the "Setup" or "Core" phase to create, hand-optimize, and verify each declared SVG or WebP file at its target path (e.g., `[ ] T1.x: Create hand-optimized SVG asset ASSET-LOGO at public/assets/logo.svg`).
