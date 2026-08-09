# epic-constitution / more

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

## Step 4: Validation Rules

Define how to verify compliance:

**Automated Checks:**
- API contract tests
- Dependency analysis
- Performance benchmarks
- Security scans

**Manual Reviews:**
- Code review checklist
- Architecture review points
- Documentation standards

## Step 5: Integration with Stories

Explain inheritance:
- "All stories in this epic inherit both project and epic constitutions"
- "Story-level rules can specialize further but not contradict"
- "Stories reference this constitution for epic-specific patterns"

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

## Success Criteria

A good epic constitution:
-  Extends project principles clearly
-  Defines epic boundaries precisely
-  Enables autonomous development
-  Prevents epic coupling
-  Measurable and enforceable

## Step 6: Cross-Epic Coordination

If epic has dependencies:
- "How do constitutions align between dependent epics?"
- "Any shared principles needed?"
- "Contract negotiation required?"
