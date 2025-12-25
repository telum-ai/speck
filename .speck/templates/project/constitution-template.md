# [PROJECT_NAME] Constitution

**Version**: 1.0.0  
**Ratified**: [DATE]  
**Last Amended**: [DATE]  
**Status**: [Draft/Active/Deprecated]  
**Extends** (optional): Base Constitution v[X.Y.Z]

<!--
INSTRUCTIONS FOR USING THIS TEMPLATE:

1. Replace [PROJECT_NAME] and all [PLACEHOLDERS] with actual content
2. Remove sections that don't apply (do not leave “N/A”)
3. Use normative language: MUST/SHALL = mandatory, SHOULD = best practice, MAY = optional
4. Prefer small, enforceable principles over vague aspirations
5. Keep this document updated as project constraints evolve

Created by: `/project-constitution`
Used by: `/project-plan`, `/project-architecture`, `/epic-*`, `/story-*`, `/project-validate`
-->

---

## 🔬 Research Informing This Constitution

**Web Search Findings**:
- [Topic]: [Finding with source URL]
- [Topic]: [Finding with source URL]

**Deep Research Reports** (if any):
- [Report filename]: [Key insights that influenced principles/standards]

**Research Impact on Principles**:
- [Principle/Standard]: Added/changed because [research finding]

---

## Preamble

This constitution defines **binding** principles and standards for [PROJECT_NAME].
When trade-offs arise, these rules take precedence over convenience.

---

## Product Overview

### What is [PROJECT_NAME]?

[One paragraph describing the core value proposition and problem being solved]

### Core Functionality

- **[Feature 1]**: [Description]
- **[Feature 2]**: [Description]
- **[Feature 3]**: [Description]

### Key Technical Decisions

- **[Decision Area]**: [Choice made and brief rationale]
- **[Decision Area]**: [Choice made and brief rationale]
- **[Decision Area]**: [Choice made and brief rationale]

### Success Definition

- **Primary Metric**: [What defines success for this product]
- **Key Performance Indicators**: [List measurable targets]

## Core Product Principles

### Principle I: [Principle Name] (Sacred/Non-Negotiable/Foundational)

**Statement**: [One sentence summary of the principle]

**Rationale**: [Why this principle exists and its impact]

**Implementation Requirements**:
- MUST: [Concrete, enforceable requirement]
- MUST: [Concrete, enforceable requirement]
- SHOULD: [Best practice]
- MUST NOT: [Prohibition]

**Validation Criteria**:
- [ ] [How to verify compliance (test, review checklist, metric)]
- [ ] [How to verify compliance]

**Examples**:
- ✅ Good: [Concrete example]
- ❌ Bad: [Counter-example]

### Principle II: [Principle Name]

[Follow the same pattern as above]

### Principle III: [Principle Name]

[Continue as needed - typically 3-7 core principles]

## Brand Identity & Values

### [Brand Element Name]

All user-facing communication MUST embody:

- **[Quality]**: [Description]
- **[Quality]**: [Description]
- **[Quality]**: [Description]

Brand guidelines:

- [Specific guideline]
- [Specific guideline]
- [Specific guideline]

## Technical Excellence Standards

### Performance Standards

- MUST: [Define measurable targets, e.g., “API responses <200ms p95”]
- MUST: [Define availability targets, e.g., “99.9% uptime”]
- SHOULD: [Define budgets, e.g., “bundle size <X”]

### Security & Privacy Standards

- MUST: [Data classification and access control policy]
- MUST: [Encryption requirements in transit/at rest]
- MUST: [Audit/logging requirements]
- MUST NOT: [Prohibited data handling]

### Testing & Quality Standards

- MUST: [Test types required: unit/integration/e2e]
- MUST: [Minimum coverage or quality gates if applicable]
- SHOULD: [Performance tests for critical flows]

### Dependency & Integration Standards

- MUST: [Dependency approval policy]
- MUST: [Versioning/deprecation policy]
- MUST: [Backward compatibility expectations]

## [Domain-Specific Section]

<!--
Add sections specific to your product domain:
- E-commerce: Payment Standards, Inventory Management
- Healthcare: Compliance Standards, Privacy Requirements
- Social: Community Standards, Safety Requirements
- Enterprise: Integration Standards, Security Requirements
-->

### [Domain Requirement]

[Domain-specific requirements and guidelines]

## Development Workflow & Quality Gates

1. **[Phase]**: [Requirements for this phase]
2. **[Phase]**: [Requirements for this phase]
3. **[Phase]**: [Requirements for this phase]

## Governance

- **Authority**: This constitution guides all product, technical, and business decisions.
- **Decision Framework**: When trade-offs arise, prioritize in this order:
  1. [Highest priority]
  2. [Second priority]
  3. [Third priority]
  4. [Continue as needed]

  Deviations must be documented with sunset dates.

- **Amendments**: Proposals via PR with rationale, user impact analysis, and migration plan.
  [Approval process and stakeholders]

- **Versioning Policy**:
  - MAJOR: Changes to core product principles or removal of principles
  - MINOR: New principles, brand evolution, or expanded guidance
  - PATCH: Clarifications, metrics updates, and non-semantic edits

- **Compliance Reviews**:
  - [Review cadence and process]
  - [Validation requirements]
  - [Metrics tracking]

---

## Epic-Specific Principles (Optional)

If certain epics need stricter rules than the project baseline, document them here so epic constitutions can inherit/refine them.

| Epic | Additional Constraints | Success Gates |
|------|------------------------|---------------|
| [EPIC_ID] | [Constraints] | [Gates] |

---

## Validation Gates

### Story Level
- [ ] Meets all applicable project principles
- [ ] Meets project performance/security/accessibility standards

### Epic Level
- [ ] All stories validated (PASS)
- [ ] Integration requirements met
- [ ] Performance targets met at epic scope

### Project Level
- [ ] All epics validated (PASS)
- [ ] Stakeholder sign-off complete
- [ ] Production readiness criteria met

---

## Amendment Process

This constitution may be amended when:
1. New regulations or requirements emerge
2. Material technical constraints change
3. Product direction changes in a way that affects principles

Amendments require:
- Documented rationale
- Impact analysis (what breaks, what changes)
- Approval by [stakeholders/roles]
- Version increment + changelog entry

---

## Enforcement

These principles are enforced via:
- Automated checks (CI/CD, linters, tests, security scans)
- Code review checklists
- Epic/story validation gates
- Project validation gates

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | [DATE] | Initial constitution | [Name] |

---
*Generated by /project-constitution command*  
*Template Version: 1.0.0*

