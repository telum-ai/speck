# Learned Patterns Library

This directory contains **validated patterns** that have been discovered through project retrospectives and proven useful across multiple epics or projects.

## How Patterns Get Here

Patterns are promoted through the retrospective cascade:

```
Story discovers pattern (1 occurrence)
    ↓
Epic retrospective validates pattern (2+ stories used it)
    ↓
Project retrospective promotes pattern (2+ epics used it)
    ↓
Pattern added here (cross-project reusable)
```

## Pattern Categories

Patterns are organized by type:

- `code/` - Reusable code patterns and snippets
- `architecture/` - Architectural patterns and decisions
- `testing/` - Testing strategies and patterns
- `process/` - Development process patterns
- `gotchas/` - Anti-patterns and pitfalls to avoid

## Pattern File Format

Each pattern file should follow this structure:

```markdown
# Pattern: [Name]

**Category**: [code|architecture|testing|process|gotcha]
**Discovered**: [Date]
**Validated In**: [List of projects/epics]
**Occurrences**: [Number of times used]

## Problem

[What problem does this pattern solve?]

## Solution

[How does the pattern solve it?]

## Example

[Code example or implementation details]

## When to Use

[Conditions where this pattern applies]

## When NOT to Use

[Conditions where this pattern is inappropriate]

## Related Patterns

[Links to related patterns]

## Source

- First discovered: [Epic/Story where first found]
- Validated in: [List of epics where validated]
- Promoted by: [Project retrospective that promoted it]
```

## Using Patterns

When starting a new story or epic:
1. Check this library for relevant patterns
2. Reference patterns in your plan.md
3. Apply patterns in implementation
4. Document variations in retrospective

## Contributing Patterns

Patterns are NOT added manually - they flow through retrospectives:

1. **Story Level**: Discover pattern, add `PATTERN:` tag to commit
2. **Story Retrospective**: Pattern captured in `story-retro.md`
3. **Epic Retrospective**: If pattern appears in 2+ stories, it's validated
4. **Project Retrospective**: If pattern appears in 2+ epics, it's promoted here

This ensures only **truly validated** patterns make it into the library.

## Governance

- Patterns should be reviewed periodically
- Outdated patterns should be marked deprecated
- Each pattern should have clear ownership
- Breaking changes to patterns require migration guide

---

**Version**: 1.0  
**Updated**: 2025-12-20

