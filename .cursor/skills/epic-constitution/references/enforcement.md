# epic-constitution / enforcement

## Epic Constitution Purpose

Epic constitutions:
- **Extend** project principles (never contradict)
- **Specialize** rules for epic's domain
- **Clarify** epic-specific trade-offs
- **Define** epic boundaries and interfaces

## Step 5: Integration with Stories

Explain inheritance:
- "All stories in this epic inherit both project and epic constitutions"
- "Story-level rules can specialize further but not contradict"
- "Stories reference this constitution for epic-specific patterns"

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

## Common Epic Constitution Patterns

### Data-Heavy Epics
- Data quality principles
- Privacy boundaries
- Retention policies
- Access patterns

### User-Facing Epics
- UX consistency rules
- Accessibility standards
- Performance budgets
- Error handling patterns

### Integration Epics
- API versioning rules
- Retry/fallback patterns
- Contract testing requirements
- Monitoring standards

### Security-Critical Epics
- Authentication patterns
- Audit requirements
- Encryption standards
- Compliance mappings

## Success Criteria

A good epic constitution:
-  Extends project principles clearly
-  Defines epic boundaries precisely
-  Enables autonomous development
-  Prevents epic coupling
-  Measurable and enforceable
