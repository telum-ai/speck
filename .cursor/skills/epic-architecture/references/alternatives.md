# epic-architecture / alternatives

* How research influenced architectural decisions
   - Create clear diagrams
   - Document all decisions

7. Validate against project architecture:
   - Ensure alignment with system design
   - Verify technology stack consistency
   - Check integration points
   - Confirm scalability approach

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

The marked canonical Epic flow in root `AGENTS.md` owns order. Resume at its first incomplete applicable slot after this architecture decision.

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
