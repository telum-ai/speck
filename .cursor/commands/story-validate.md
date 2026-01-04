---
description: Validate implementation against specification, execute acceptance tests, verify constitution compliance, and generate validation report.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Goal: Comprehensively validate that the implementation fulfills the specification, meets non-functional requirements, adheres to constitutional principles, and is ready for review/deployment.

## Subagent Parallelization

This command benefits from parallel speck-auditor execution for independent validation aspects:

```
├── [Parallel] speck-auditor: "Check all FR-XXX requirements are implemented with tests"
├── [Parallel] speck-auditor: "Run test suite and verify all tests pass"
├── [Parallel] speck-auditor: "Validate performance against spec targets"
├── [Parallel] speck-auditor: "Verify constitution principle compliance"
├── [Parallel] speck-auditor: "Check Cursor rules compliance for changed files"
├── [Parallel] speck-auditor: "Run linters and type checks"
├── [Parallel] speck-auditor: "Code review for security and maintainability"
├── [Parallel] speck-auditor: "Check documentation completeness"
└── [Wait] → Synthesize into validation-report.md

Each auditor returns: PASS | FAIL | PARTIAL with evidence
```

**Speedup**: 6-8x compared to sequential validation.

## Execution steps

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If no `spec.md` found: instruct user to `cd` into the story directory or run `/speck` to route
   - Require:
     - `{STORY_DIR}/spec.md`
     - `{STORY_DIR}/plan.md`
     - `{STORY_DIR}/tasks.md`
   - If any missing: ERROR "Run /story-specify, /story-plan, and /story-tasks first"

2. Load artifacts and extract validation criteria:
   - **spec.md**: Functional requirements (FR-XXX), acceptance scenarios, user stories, non-functional requirements, performance targets, key entities
   - **plan.md**: Technical context, constitution check gates, complexity tracking, project structure
   - **tasks.md**: All task IDs and their completion status
   - **Constitution chain** (if exists): Project-specific principles and quality gates
     - Project: `specs/projects/<PROJECT_ID>/constitution.md` (optional)
     - Epic: `{EPIC_DIR}/constitution.md` (optional)
   - **quickstart.md** (if exists): Integration test scenarios
   - **contracts/** (if exists): API specifications to verify

3. Task completion verification:
   - Parse tasks.md for all task checkboxes
   - Report completion percentage (e.g., "28/32 tasks complete (87.5%)")
   - If any tasks incomplete: WARN with list of incomplete task IDs
   - User can override with `--allow-incomplete` flag if iterating

4. Functional requirements traceability:
   - For each FR-XXX in spec.md, determine verification method:
     * If contract test exists → check test passes
     * If integration test exists → check test passes
     * If mentioned in quickstart.md → mark for scenario execution
     * If no test coverage → FLAG as "Untested requirement"
   - Generate requirements traceability matrix (RTM)

5. Execute quickstart scenarios (if quickstart.md exists):
   - Parse quickstart.md for step-by-step test scenarios
   - Attempt to execute each scenario programmatically:
     * API scenarios: send HTTP requests, validate responses
     * CLI scenarios: execute commands, validate output
     * Integration scenarios: run test files, capture results
   - For manual scenarios: provide checklist for user validation
   - Capture pass/fail status for each scenario

6. Run test suite validation:
   - Detect project type and test commands from plan.md:
     * Python: `pytest` (or as specified in Technical Context)
     * JavaScript/TypeScript: `npm test` or `npm run test:ci`
     * Rust: `cargo test`
     * Go: `go test ./...`
     * (Add others based on Language/Version in plan.md)
   - Run tests and capture output
   - Parse test results: total, passed, failed, skipped
   - If any failures: HALT with detailed error report (unless `--force` flag)

7. Performance validation (if targets specified in spec.md):
   - Extract performance targets from spec.md Non-Functional Requirements
   - Look for performance test files (tests/performance/, tests/load/, etc.)
   - Run performance tests and compare against targets
   - Report: Target vs Actual for each metric
   - Flag any violations as PERFORMANCE_GAP

8. Constitution compliance verification:
   - Re-evaluate Constitution Check section from plan.md against actual code
   - For each principle gate:
     * Verify claimed compliance is implemented (e.g., if "feature flags" claimed, check they exist)
     * Check Complexity Tracking justifications are valid
     * Scan codebase for anti-patterns (if constitution defines them)
   - If violations found that weren't in Complexity Tracking: FLAG as "Undocumented deviation"

9. Cursor rules compliance check:
   - Check if `.cursor/rules/` directory exists
   - If exists, scan for all `*.mdc` or `*.md` rule files
   - For each rule file found:
     * Read the rule to understand its trigger conditions and requirements
     * Determine if rule applies to this story based on:
       - File types changed (e.g., `.tsx` files → frontend rules apply)
       - Feature areas mentioned in spec.md (e.g., "migration" → migration rules apply)
       - Technologies used in plan.md (e.g., "React" → React rules apply)
     * If rule applies, validate implementation against rule requirements:
       - Check for required patterns mentioned in rule
       - Check for prohibited patterns mentioned in rule
       - Verify best practices described in rule are followed
     * Document compliance status for each applicable rule
   - Generate rules compliance section:
     ```
     ## Cursor Rules Compliance
     
     Rules Evaluated: [X total, Y applicable to this story]
     
     | Rule | Applicability | Status | Findings |
     |------|---------------|--------|----------|
     | design-system-enforcement.mdc | ✅ Applies (frontend files changed) | ✅ PASS | All components use design system |
     | migrations-safety.mdc | ❌ Not applicable (no migrations) | N/A | - |
     | testing.mdc | ✅ Applies (all stories) | ⚠️ WARN | 2 tests marked .skip() |
     ```
   - If no `.cursor/rules/` directory: Note "No project-specific rules found"
   - If any rule violations found: Include detailed explanation and remediation steps

10. Code quality gates (run from repository root):
   - **Linting**: Run linters specified in plan.md
     * Python: flake8, mypy, black --check
     * JavaScript/TypeScript: eslint, prettier --check
     * Rust: cargo clippy
     * Go: golangci-lint
   - **Type checking** (if applicable):
     * TypeScript: tsc --noEmit
     * Python: mypy
   - **Security scanning** (optional, if tools available):
     * Python: bandit, safety
     * JavaScript: npm audit
   - Capture all violations and warnings

10.5. **Visual/UX Validation** (if ui-spec.md exists OR story has UI components):
   
   **Reference**: `.speck/patterns/visual-testing-pattern.md` for complete details.
   
   **Platform Detection**:
   - Load `project.md` frontmatter for `_active_recipe`
   - Load recipe's `visual_testing.platform` from recipe.yaml
   - If no recipe: detect from architecture.md stack
   - Load appropriate platform pattern from `.speck/patterns/visual-testing/`
   
   **Load Design Specifications**:
   - `specs/projects/[PROJECT_ID]/design-system.md` → tokens, breakpoints
   - `specs/projects/[PROJECT_ID]/ux-strategy.md` → voice/tone, accessibility
   - `{STORY_DIR}/ui-spec.md` → component specs, Testing Checklist
   - `{EPIC_DIR}/wireframes.md` → layouts (if exists)
   
   **Web Platform** (use Browser MCP tools):
   - Navigate to implemented pages/components
   - For each breakpoint in design-system.md:
     * `browser_resize(width, height)`
     * `browser_take_screenshot(filename)`
   - Capture component states (hover, focus, disabled, loading, error)
   - Run `runAccessibilityAudit()` → Check WCAG compliance
   - Run `runPerformanceAudit()` → Check Core Web Vitals (if targets specified)
   - Check console for errors: `getConsoleErrors()`
   
   **Mobile Platform** (if emulator/simulator available):
   - Check device availability via `adb devices` or `xcrun simctl list`
   - If available:
     * Set Demo Mode / status bar override for clean screenshots
     * Capture screenshots on target devices
     * Test dark mode if applicable
   - If unavailable: Generate manual testing checklist
   
   **Desktop/Extension Platforms**:
   - Follow platform-specific pattern guidance
   - Capture window states and theme variations
   
   **Design Token Compliance Check**:
   - Grep changed files for hardcoded values:
     * Hex colors: `#[0-9A-Fa-f]{6}`
     * Pixel values: raw `px` instead of tokens
   - Compare against design-system.md tokens
   - Report: "[X/Y] properties use design tokens ([Z]%)"
   
   **Voice/Tone Compliance** (load ux-strategy.md):
   - Check UI copy (error messages, button labels, empty states)
   - Compare against voice attributes in ux-strategy.md
   - Flag generic/technical copy that doesn't match voice
   
   **ui-spec.md Testing Checklist** (if exists):
   - Load Testing Checklist section from ui-spec.md
   - Check off each item during validation
   - Unchecked items become validation issues
   
   **Store Screenshots**:
   - Create `{STORY_DIR}/screenshots/` directory
   - Save screenshots with convention: `{screen}-{breakpoint|state|device}.png`
   
   **Generate Visual Validation Section**:
   - Include in validation-report.md:
     * Screenshot gallery with annotations
     * Design token compliance percentage
     * Accessibility audit results
     * Voice/tone compliance notes
     * ui-spec.md checklist status

11. Code audit (manual, REQUIRED — "meets requirements" is not enough):
   - Identify the change surface:
     * List changed files (prefer: `git diff --name-only` and `git diff` for the story’s branch)
     * Identify entrypoints touched: API routes, background jobs, UI pages/routes, migrations, cron, etc.
     * For critical code paths: find 1–3 call sites and trace end-to-end flow
   - Audit checklist (record concrete findings + file references):
     * **Correctness & edge cases**:
       - Untrusted inputs validated/sanitized? Boundaries handled (null/empty/invalid)?
       - Error handling: failure paths are explicit and safe (no silent partial writes)
       - Time: timezones, clock skew, ordering, idempotency, retries, timeouts
       - Concurrency: race conditions, transactions, locking, background task reentrancy
     * **Maintainability**:
       - Clear naming, small functions, single-responsibility boundaries
       - Avoids unnecessary abstractions (Simplicity-First). Complexity justified in plan.md
       - No duplicated logic that should be extracted (or extraction justified)
       - No “mystery meat” config/magic values; TODO/FIXME/HACK clearly tracked or removed
     * **Security & privacy**:
       - AuthN/AuthZ checks correct and consistent (no missing permission gates)
       - No secrets/keys/PII in logs, errors, or client responses
       - Injection risks addressed (SQL/NoSQL/command/template), unsafe deserialization avoided
       - Rate limits / abuse considerations noted for public endpoints (if applicable)
     * **Performance**:
       - Avoids N+1 queries, unbounded loops, unpaged lists, large payloads
       - Hot paths are reasonably efficient; perf targets in spec.md are plausibly met
     * **Operability / observability**:
       - Logs/errors are actionable; failures have context (request IDs, user IDs where safe)
       - Metrics/tracing hooks added when warranted by plan/context
     * **Frontend UX/a11y** (if applicable):
       - Uses existing design system; no arbitrary styling
       - Loading/error/empty states exist; keyboard navigation & ARIA are reasonable
     * **Test quality**:
       - Tests cover critical success + failure cases; assertions are meaningful
       - Avoids flakiness (timing, randomness), avoids over-mocking core behavior
   - Determine audit outcome (this feeds overall validation status):
     * **FAIL** if any high-severity issue exists (security vulnerability, data-loss risk, broken authz, major unhandled edge case, pathological perf risk, missing critical tests)
     * **CONDITIONAL_PASS** if implementation works but needs cleanup/refactor/docs/tests before merge (list required follow-ups)
     * **PASS** if maintainable, safe, and consistent with plan/constitution

12. Documentation completeness check:
    - If new entities in data-model.md: Check models have docstrings/comments
    - If new API endpoints in contracts/: Check OpenAPI/GraphQL schema exists
    - If new CLI commands: Check --help text exists
    - If breaking changes: Check migration guide exists
    - Agent context files updated: Verify recent changes include this feature

13. Generate validation report in `{STORY_DIR}/validation-report.md`:
   
   **CRITICAL**: Load and follow the template exactly:
   ```
   .speck/templates/story/validation-report-template.md
   ```
   
   The template is self-documenting - follow all sections and guidelines within it.

14. **Project Truth Update Prompt** (if PASS):
    
    After successful validation, prompt user to update project-level docs:
    
    ```
    ✅ Validation PASSED! 
    
    Before completing this story, consider updating project-level truth:
    
    Project-level docs that MAY need updates based on this story:
    - [ ] `project.md` → If scope/vision expanded
    - [ ] `PRD.md` → If new features delivered or requirements changed
    - [ ] `architecture.md` → If new patterns introduced
    - [ ] `context.md` → If new constraints discovered
    - [ ] `design-system.md` → If new UI patterns added
    - [ ] `ux-strategy.md` → If UX principles validated/changed
    
    To update:
    1. Review validation-report.md for actual changes
    2. Update relevant project docs with "(Added in Story [ID])"
    3. Commit updates with "docs: update project truth after [story-id]"
    
    Skip with: --skip-truth-update
    ```
    
    **Include in validation-report.md**:
    ```markdown
    ## Project Truth Update Checklist
    
    This story delivered features that may require project-level documentation updates:
    
    - [ ] `project.md` → [Relevant? Y/N] - [What changed]
    - [ ] `PRD.md` → [Relevant? Y/N] - [What changed]
    - [ ] `architecture.md` → [Relevant? Y/N] - [What changed]
    - [ ] `context.md` → [Relevant? Y/N] - [What changed]
    - [ ] `design-system.md` → [Relevant? Y/N] - [What changed]
    - [ ] `ux-strategy.md` → [Relevant? Y/N] - [What changed]
    
    **Note**: Project-level docs are the source of truth for "what exists now".
    Stories are proposals; after validation, project docs must reflect new reality.
    ```

15. Report completion to user:
    - Path to validation-report.md
    - Overall status (PASS / CONDITIONAL_PASS / FAIL)
    - If FAIL: List top 3 blockers to fix
    - If PASS: Suggest "Ready for PR - see validation-report.md for details"
    - If PASS: Remind about project truth updates
    - Command to re-run: `/story-validate` (after fixes)

Behavior rules:
- NEVER skip test execution - if tests fail, validation fails (unless `--force`)
- NEVER mark requirements as "verified" without evidence (test or scenario)
- If quickstart.md missing, WARN but continue (use test suite as primary validation)
- Performance validation is optional (only if targets specified in spec.md)
- Constitution check MUST run - it's non-negotiable for Speck workflow
- Code audit MUST run - if audit finds high-severity issues, validation MUST be FAIL even if requirements/tests pass
- Include timestamps in validation report for audit trail
- Allow flags: `--allow-incomplete`, `--force`, `--skip-perf`, `--skip-quickstart`

Error handling:
- If test suite fails: Capture errors, include in report, mark as FAIL
- If performance tests not found but targets exist: WARN, skip performance section
- If quickstart.md malformed: WARN, mark scenarios as "Unable to parse"
- If linting fails: Include in report; treat as CONDITIONAL_PASS unless it indicates correctness/safety (then FAIL)

Context: $ARGUMENTS

