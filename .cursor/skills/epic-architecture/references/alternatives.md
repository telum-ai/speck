# epic-architecture / alternatives

* How research influenced architectural decisions
   - Create clear diagrams
   - Document all decisions

7. Validate against project architecture:
   - Ensure alignment with system design
   - Verify technology stack consistency
   - Check integration points
   - Confirm scalability approach

8. Output summary:
   ```
    Epic Architecture Designed!

   Epic: [Name]
   Pattern: [Architecture pattern]
   Components: [Number]

   Key Design Decisions:
   - [Decision 1]
   - [Decision 2]

   Integration Points:
   - Depends on: [List]
   - Consumed by: [List]

   Next Steps:
   - Required: /epic-plan (create tech spec)
   - Then: /epic-breakdown (map stories)
   - Optional: /analyze --level epic (validate design)
   ```

## Architecture Coherence

Ensure epic architecture:
- ✓ Aligns with project architecture
- ✓ Respects system boundaries
- ✓ Uses consistent patterns
- ✓ Follows project technology stack
- ✓ Maintains security model
- ✓ Supports performance goals
- ✓ Enables testability
- ✓ Facilitates maintenance

## Relationship to Other Commands

```
/epic-specify → /epic-clarify → /epic-architecture → /epic-plan → /epic-breakdown
                                          ↓
                              (informs tech-spec.md)
```

The epic architecture:
- Provides detailed design for /epic-plan
- Guides story breakdown in /epic-breakdown
- Informs implementation in stories
- Establishes testing boundaries

## Notes

- Epic architecture should be detailed enough to guide implementation
- But not so detailed it constrains story-level decisions
- Focus on interfaces, boundaries, and integration
- Leave implementation details for stories
- Update if significant changes occur during development
