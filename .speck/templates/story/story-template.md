---
# Story dependency declaration for autonomous orchestration
# The orchestrator reads this to determine execution order
depends_on: []  # e.g., [S001, S003] - stories that must be validated first
blocks: []      # e.g., [S005] - stories waiting on this one (informational)
---

# Story Specification: [STORY NAME]

**Story ID**: `S###-story-name`  
**Branch** (optional): `S###-story-name`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: [User description from /story-specify command]

---

## 📊 Information Sources

**Traceability**: This story specification was created from the following sources:

- **Required Inputs**:
  - User description (from command input)
  - `epic.md` → Epic context and user stories
- **Recommended Inputs**:
  - `epic-tech-spec.md` → Technical implementation approach
  - `project.md` → Project vision and constraints (inherited)
- **Domain Context** (for specialized domains):
  - `domain-model.md` → Domain terminology, entities, rules, and principles
  - Use glossary terms consistently in story descriptions
  - Validate against domain invariants
- **Design Context** (for UI/UX stories):
  - `ux-strategy.md` → UX principles, voice/tone, emotional goals
  - `design-system.md` → Design tokens, components, patterns
  - If missing: Mark as [NEEDS DESIGN CONTEXT] and suggest `/project-ux` or `/project-design-system`
- **Brownfield** (if applicable):
  - `codebase-scan-*.md` → Existing code analysis
  - Approach: Refactor/enhance existing code when overlap detected

**Information Flow**:
```
User input + epic.md + [epic-tech-spec/codebase-scan-*]
  ↓
spec.md (this document)
  ↓
clarify → plan → tasks → implement → validate → retrospective
```

---

## Story Lifecycle State Tracking

**Current State**: Specified

- [x] **Specified** - spec.md created
- [ ] **Clarified** - Ambiguities resolved (`/story-clarify` complete)
- [ ] **Planned** - plan.md created (`/story-plan` complete)
- [ ] **Tasked** - tasks.md created (`/story-tasks` complete)
- [ ] **Approved** - Explicit go-ahead to implement (team review)
- [ ] **In Progress** - Implementation started (`/story-implement` running)
- [ ] **Implemented** - Code complete, all tasks marked [x]
- [ ] **Validated** - validation-report.md shows PASS (`/story-validate` complete)
- [ ] **Retrospective** - story-retro.md created (`/story-retrospective` complete)
- [ ] **Archived** - Ready for archive with date prefix

Update state checkboxes as story progresses through workflow.

---

## Purpose

[Describe the user problem and the value delivered in 1–3 sentences. Include who benefits and what “done” means. Keep this between 50–300 characters.]

---

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs
   - Accessibility expectations (WCAG 2.1 AA) and UX consistency

---

## User Scenarios & Testing *(mandatory)*

### Job Context (JTBD)

**Core Job Being Addressed**:
When [situation/trigger], I'm trying to [job statement: action verb + object + context].

*Example: "When reviewing project status, I'm trying to identify at-risk tasks before they become blockers."*

### Primary User Story (JTBD Enhanced)

As a [user type], I want to [action] so that I can [outcome statement: direction + measure + object].

*Traditional format is acceptable, but prefer outcome-focused "so that" clauses:*
- ❌ "so that I have a dashboard" (solution-focused)
- ✅ "so that I can minimize the time it takes to identify at-risk tasks" (outcome-focused)

### Success Metrics (Outcome-Driven)

Define how we'll measure if this story achieves the desired outcome:

- [ ] **[Metric 1]**: [Direction] the [measure] of [object] by [target/baseline]
- [ ] **[Metric 2]**: [Direction] the likelihood of [outcome]
- [ ] **[Metric 3]**: [Qualitative outcome if not measurable]

*Examples:*
- *Minimize the time to complete checkout by 30% vs current flow*
- *Reduce the likelihood of abandoned carts due to payment errors*
- *Users report feeling confident about their purchase (qualitative)*

### Acceptance Scenarios

Use structured GIVEN/WHEN/THEN format for all scenarios:

#### Scenario: [Primary success path]
- **GIVEN** [initial state or context]
- **WHEN** [user action or trigger]
- **THEN** [expected outcome]
- **AND** [additional outcomes if any]

#### Scenario: [Alternative path or variation]
- **GIVEN** [different initial state]
- **WHEN** [user action]
- **THEN** [expected outcome]

#### Scenario: [Edge case or error handling]
- **GIVEN** [boundary condition]
- **WHEN** [error condition occurs]
- **THEN** [system handles gracefully]
- **AND** [user receives clear feedback]

**Note**: Each scenario should be independently testable. If you need "AND" for actions, consider if it's actually multiple scenarios.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]
- **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]  
- **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]
- **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]
- **FR-005**: System MUST [behavior, e.g., "log all security events"]

*Example of marking unclear requirements:*
- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

### Key Entities *(include if feature involves data)*
- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Non-Functional Requirements *(mandatory)*

### Performance Targets

*Define project-specific performance requirements. Reference context.md or constitution.md if they exist.*

- [CUSTOMIZE: Define latency targets, e.g., "System response: < 200ms p95"]
- [CUSTOMIZE: Define throughput targets, e.g., "Support 100 concurrent users"]
- [CUSTOMIZE: Define availability targets, e.g., "99.9% uptime"]
- State rationale if targets differ from project-level standards

### Security & Privacy

- [CUSTOMIZE: Define data privacy requirements for this feature]
- [CUSTOMIZE: Specify who can access what data]
- [CUSTOMIZE: Define data retention and deletion policies]

### Accessibility & UX

- WCAG 2.1 AA conformance required
- [CUSTOMIZE: Define UX principles from ux-strategy.md]
- [CUSTOMIZE: Define copy/tone guidelines from design-system.md]

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value and business needs
- [ ] Written for non-technical stakeholders
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous  
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and assumptions identified
- [ ] Performance targets align with project requirements (from context.md)
- [ ] Security/privacy requirements specified
- [ ] UX criteria align with project UX strategy (from ux-strategy.md)
- [ ] Accessibility included (WCAG 2.1 AA minimum)

---

## Project Documentation Updates
*Complete after `/story-validate` passes to update project-level truth*

After validation, determine which project-level documents need updates to reflect new reality:

**Check for Updates**:
- [ ] `project.md` → If story expanded/changed project scope or vision
- [ ] `PRD.md` → If story delivered new features or changed requirements
- [ ] `architecture.md` → If story introduced architectural patterns or changes
- [ ] `context.md` → If story revealed new constraints or changed existing ones
- [ ] `design-system.md` → If story added UI patterns, components, or tokens
- [ ] `ux-strategy.md` → If story validated/changed UX principles

**Update Instructions**:
1. Read `validation-report.md` for actual changes vs spec
2. For each document needing update:
   - Add new sections showing current state
   - Mark superseded sections with "(Updated after Story [ID])"
   - Update "Last Updated" timestamp
3. Commit changes explaining truth update

**Why**: Project-level docs = single source of truth for "what exists now". Stories are proposals; after validation, project docs must reflect new reality.

---

## Execution Status
*Updated by main() during processing*

- [ ] User description parsed
- [ ] Key concepts extracted
- [ ] Ambiguities marked
- [ ] User scenarios defined
- [ ] Requirements generated
- [ ] Entities identified
- [ ] Review checklist passed

---
