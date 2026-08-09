# epic-constitution / principles

Establish epic-specific constitution that extends project principles.

**When to use this command:**
- Epic has unique compliance/regulatory requirements
- Complex inter-epic boundaries need definition
- Epic owns critical data with special handling rules
- Performance/security requirements differ from project baseline
- Multiple teams working on dependent epics

**When to skip:**
- Simple, standalone epics
- Epic follows standard project patterns
- No special constraints beyond project constitution
- Internal features with flexible requirements

## Context Requirements

First, identify the epic context:
- Project name/ID (ask if not provided)
- Epic name/ID (ask if not provided)

Load hierarchical context:
- Project constitution (parent principles)
- Project technical context
- Epic specification

## Epic Constitution Purpose

Epic constitutions:
- **Extend** project principles (never contradict)
- **Specialize** rules for epic's domain
- **Clarify** epic-specific trade-offs
- **Define** epic boundaries and interfaces

## Interactive Constitution Development

### Step 1: Review Inherited Principles

Load and present project constitution:
- "The project defines these core principles: [list]"
- "Your epic must honor these while adding specificity"

### Step 2: Epic-Specific Principles

Guide principle development:

**Domain-Specific Rules:**
- "What special rules apply to [epic domain]?"
- "Any compliance/security requirements?"
- "Performance constraints unique to this epic?"

**Technical Decisions:**
- "Any epic-specific technology choices?"
- "Special patterns for this domain?"
- "Integration standards?"

**Quality Standards:**
- "Testing requirements beyond project standards?"
- "Documentation needs?"
- "Monitoring/observability requirements?"

### Step 3: Boundary Definition

Clarify epic interfaces:

**API Contracts:**
- "How do other epics interact with this one?"
- "What contracts must be maintained?"
- "Versioning strategy?"

**Data Ownership:**
- "What data does this epic own?"
- "Sharing rules with other epics?"
- "Privacy boundaries?"

**Dependencies:**
- "What can this epic depend on?"
- "What must it NOT depend on?"
- "Abstraction requirements?"

## Constitution Generation

1. Load template: `.speck/templates/epic/constitution-template.md`
2. Create file: `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/constitution.md`
3. Fill template systematically:
   - Copy project principles for reference
   - Define epic-specific extensions
   - Specify boundaries clearly
   - Set measurable standards
   - Document governance process

The template provides comprehensive sections for all constitution needs.

## Step 6: Cross-Epic Coordination

If epic has dependencies:
- "How do constitutions align between dependent epics?"
- "Any shared principles needed?"
- "Contract negotiation required?"

## Constitution Hierarchy

```
Project Constitution (Universal)
    ↓ inherits
Epic Constitution (Domain-specific)
    ↓ inherits
Story Constitution (Feature-specific)
```

Each level:
- **Extends** the level above
- **Specializes** for its scope
- **Never contradicts** parent principles

MUST Read `references/principles-2.md` (continuation). Do not stop at this file.
