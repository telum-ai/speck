
# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Story specification from `{STORY_DIR}/spec.md`

## Execution Flow (/story-plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Check for outline.md (from /story-outline command)
   → IF outline.md exists: Load Technical Context from it (skip step 3)
   → IF outline.md missing: Continue to step 3 (full planning mode)
3. Fill Technical Context if not loaded from outline (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
4. Fill the Constitution Check section based on the project constitution document (if it exists).
5. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
6. Execute just-in-time research and embed findings in plan
   → IF needed: Web search for API usage, implementation patterns
   → IF needed: Generate deep research prompts (rare at story level)
   → Embed all findings in "Research Informing This Plan" section above
7. Execute Phase 1 → contracts, data-model.md, quickstart.md
   → Use codebase-scan-*.md files if available (from /story-scan command) for consistency
8. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
9. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
10. STOP - Ready for /story-tasks command
```

**IMPORTANT**: The /story-plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /story-tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
[Extract from feature spec: primary requirement + technical approach from research]

---

## Technical Approach
[Describe HOW this story will be implemented at a high level: main components touched, key patterns reused, and key decisions/trade-offs. Keep this 3–8 sentences.]

## Dependencies
- Requires: [Other story/epic/system dependency]
- Provides: [What downstream work this enables]

## Testing Strategy
- Unit tests: [What to test]
- Integration tests: [End-to-end scenarios]
- Contract tests (if applicable): [Endpoints/schemas]

---

## Technical Context
**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The plan MUST explicitly address these gates derived from the project constitution or context.md:

**Product Principles** (from project constitution or context.md):
- [CUSTOMIZE: List project-specific product principles]
- [CUSTOMIZE: Example - "User-first: Feature prioritizes user value over metrics"]
- [CUSTOMIZE: Example - "Privacy-first: Data protection mechanisms defined"]

**Technical Excellence** (from project constitution or context.md):
- Code Quality: Modular architecture, lint/format automation
- Quality Assurance: Test coverage defined, testing strategy documented
- Performance: [CUSTOMIZE: Define targets from context.md, e.g., "<200ms system response"]
- UX Standards: [CUSTOMIZE: Reference ux-strategy.md principles]

**Brand Alignment** (from design-system.md):
- Voice & Tone: [CUSTOMIZE: Reference design-system.md content guidelines]
- [CUSTOMIZE: Add project-specific brand requirements]

## Project Structure

### Documentation (this feature)
```
{STORY_DIR}/
├── spec.md                  # Story specification (/story-specify output)
├── outline.md               # Optional: analysis + research plan (/story-outline output)
├── codebase-scan-*.md       # Optional: code analysis (/story-scan output)
├── plan.md                  # This file (/story-plan output with embedded research)
├── data-model.md            # Phase 1 output (/story-plan)
├── quickstart.md            # Phase 1 output (/story-plan)
├── contracts/               # Phase 1 output (/story-plan)
└── tasks.md                 # Phase 2 output (/story-tasks - NOT created by /story-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->
```
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Research Informing This Plan

**Web Search Findings**:
- [Topic]: [Finding with source URL]
- [Topic]: [Finding with source URL]

**Deep Research Reports** (if any):
- [Report filename]: [Key insights that influenced implementation decisions]

**Research Impact on Implementation Decisions**:
- [Implementation Pattern]: Chosen based on [research finding]
- [Library/API Choice]: Informed by [source/report]

**Note**: Research is performed just-in-time during planning, not as a separate phase.

## Phase 1: Design & Contracts

**Check for codebase scans** (from `/story-scan` command):
- Look in {STORY_DIR} for `codebase-scan-*.md` files
- Load ALL scan reports if they exist (auth, user, api, design-system, data, etc.)
- Use for consistency in design decisions below

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable
   - **IF codebase scans exist**:
     * Check for existing entities/models to avoid naming conflicts
     * Follow existing naming conventions (snake_case, PascalCase, etc.)
     * Reference existing model patterns from scans
     * Identify which existing models/entities to reuse vs. create new

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`
   - **IF codebase scans exist**:
     * Follow existing API versioning patterns (e.g., /api/v1/)
     * Match existing endpoint naming conventions
     * Use existing request/response schema patterns
     * Reference existing authentication/authorization patterns

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)
   - **IF codebase scans exist**:
     * Follow existing test file naming conventions
     * Place tests in existing test directories
     * Match existing assertion patterns and test structure

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps
   - **IF codebase scans exist**:
     * Follow existing test scenario organization
     * Use existing test fixture patterns

**Output**: data-model.md, /contracts/*, quickstart.md

## Phase 1.5: Implementation Guidance (NEW - For /story-tasks)
*This section provides rich context that /story-tasks will use when generating tasks.md*

### Functional Requirements Extraction

**Extract from spec.md** (will be used by /story-tasks for FR → task mapping):

| FR ID | Requirement Summary | Acceptance Criteria | Priority |
|-------|---------------------|---------------------|----------|
| FR-001 | [Short summary of requirement] | [How to verify it works] | Critical |
| FR-002 | [Short summary of requirement] | [How to verify it works] | High |
| ... | ... | ... | ... |

**Note for /story-tasks**: Each task MUST reference which FRs it implements. Use this table to ensure complete coverage.

### Research Findings Preservation

**Key Decisions with Implementation Details** (from research-report-*.md):

**Decision 1: [Technology/Pattern Choice]**
- **Rationale**: [Why chosen over alternatives]
- **Rejected Alternatives**: [What was considered and why rejected]
- **Implementation Pattern**:
  ```[language]
  [Code example from research report]
  ```
- **Performance**: [Benchmarks, optimization techniques]
- **Security**: [Security model, attack mitigations]
- **Relevant Tasks**: [List task IDs that need this]

**Decision 2: [Database Schema Pattern]**
- **Rationale**: [...]
- **Implementation Pattern**: [...]
- **Relevant Tasks**: [...]

(Include 3-5 most critical research findings with code examples)

### Codebase Patterns for Reuse

**From codebase-scan-*.md files** (specify what to reuse, NOT recreate):

**Pattern 1: [Component/Service Name] (ALREADY EXISTS!)**
- **Location**: `path/to/file.ext` (lines X-Y)
- **What It Provides**: [Capabilities]
- **How to Use**:
  ```[language]
  [Usage example]
  ```
- **DON'T**: Create custom [thing]
- **DO**: Import and use existing
- **Relevant Tasks**: [List task IDs]

**Pattern 2: [Another Pattern]**
- **Location**: [...]
- **Relevant Tasks**: [...]

(Include 5-8 most critical patterns to reuse)

### Performance Optimization Guide

**From spec.md NFRs + embedded research + codebase scans**:

| Performance Target | Technique | Existing Infrastructure | Validation | Tasks |
|--------------------|-----------|-------------------------|------------|-------|
| <100ms search | Use GIN index on username_lower | Already exists in user.py | perf test | T012 |
| <2s matching | Batch processing, rate limiting | N/A - implement | integration test | T014 |
| <100ms transition | AnimatePresence from design system | Already exists | manual | T018 |

**Note for /story-tasks**: Include optimization technique in task description, not just "make it fast"

### Security Implementation Checklist

**From embedded research + spec.md privacy requirements**:

- [ ] Client-side hashing (crypto.subtle.digest, not CryptoJS)
- [ ] Global pepper (fetch from server, rotate monthly)
- [ ] Rate limiting (100 contacts/minute per user)
- [ ] Hash validation (64-char hex pattern)
- [ ] No plaintext storage (hashes only)
- [ ] Privacy toggles (explicit consent required)

**Note for /story-tasks**: Each security requirement should be a checklist item in relevant task descriptions.

### Design System Component Registry

**Source Priority** (check in order):
1. `specs/projects/[PROJECT_ID]/design-system.md` → Project design system (tokens, components)
2. `codebase-scan-design-system.md` → Existing component patterns from code

**From design-system.md** (project-level tokens - MUST USE):

| Token Category | Token Name | Value | Usage in This Story |
|----------------|------------|-------|---------------------|
| Color | [e.g., `primary-500`] | [value] | [where used] |
| Typography | [e.g., `text-lg`] | [value] | [where used] |
| Spacing | [e.g., `space-4`] | [value] | [where used] |
| Radius | [e.g., `radius-md`] | [value] | [where used] |

**Components to Use** (from design-system.md or codebase-scan):

| Component | Use For | Required Props | Example | Tasks |
|-----------|---------|----------------|---------|-------|
| [Component] | [Purpose] | [Props] | [Example usage] | [Task IDs] |

**⚠️ CRITICAL**: Do NOT create custom components if design-system.md has equivalents.
- ❌ Wrong: "Create a styled button"
- ✅ Right: "Use Button from design-system with `variant='primary'`"

**Note for /story-tasks**: Specify component names and token values in task descriptions

### Brand Voice Copy Bank

**Source Priority** (check in order):
1. `specs/projects/[PROJECT_ID]/ux-strategy.md` → Voice & Tone section
2. `specs/projects/[PROJECT_ID]/design-system.md` → Content Guidelines section
3. `codebase-scan-design-system.md` → Existing copy patterns from code

**Voice Attributes** (from ux-strategy.md):
- Voice: [Extract from ux-strategy.md Voice section, e.g., "Friendly but not casual"]
- Tone adjustments: [How tone changes by context - success/error/onboarding]

**Copy Patterns for This Feature**:

| Context | Pattern | Example | Source |
|---------|---------|---------|--------|
| Empty state | [Pattern] | [Example copy] | [ux-strategy.md / design-system.md] |
| Loading | [Pattern] | [Example copy] | [Source] |
| Success | [Pattern] | [Example copy] | [Source] |
| Error | [Pattern] | [Example copy] | [Source] |
| Actions | [Pattern] | [Example copy] | [Source] |

**⚠️ CRITICAL**: Match existing voice/tone from project documents.
- ❌ Wrong: Generic "Loading..." if project uses friendly voice
- ✅ Right: "Finding your matches..." per ux-strategy.md tone

**Note for /story-tasks**: Include exact copy in UI task descriptions, not "add loading message"

### Constitution Compliance Gates

**From Constitution Check section above** (specific gates to verify in implementation):

**Gate 1: [CUSTOMIZE: Performance Gate]**
- [CUSTOMIZE: Define specific performance requirement from constitution]
- [CUSTOMIZE: How to achieve it]
- Tasks affected: [List task IDs]

**Gate 2: [CUSTOMIZE: UX Gate]**
- [CUSTOMIZE: Define specific UX requirement from constitution]
- [CUSTOMIZE: How to achieve it]
- Tasks affected: [List task IDs]

**Gate 3: [CUSTOMIZE: Security/Privacy Gate]**
- [CUSTOMIZE: Define specific security requirement from constitution]
- [CUSTOMIZE: How to achieve it]
- Tasks affected: [List task IDs]

**Note for /story-tasks**: Include constitution gate in task description if task validates a gate

## Phase 2: Task Planning Approach
*This section describes what the /story-tasks command will do - DO NOT execute during /story-plan*

**Task Generation Strategy**:
- Load `.speck/templates/story/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /story-tasks command, NOT by /story-plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /story-plan command*

**Phase 3**: Task generation (/story-tasks command creates tasks.md)  
**Phase 4**: Implementation (/story-implement executes tasks.md)  
**Phase 5**: Validation (/story-validate runs tests, validates requirements, generates reports)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [ ] Research embedded in plan (just-in-time during /story-plan)
- [ ] Phase 1: Design complete (/story-plan)
- [ ] Phase 2: Task planning complete (/story-plan - describe approach only)
- [ ] Phase 3: Tasks generated (/story-tasks)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on project constitution - See constitution.md if it exists*
