# epic-architecture / decisions

Own only architecture needed to make the active epic implementable without violating project-level contracts.

1. Read the active `epic.md`, project architecture and constitution when present, relevant project context, and any existing `epic-architecture.md`.
2. Trace each proposed component or boundary to an epic promise. Do not invent infrastructure, scale targets, vendors, or deployment topology absent from the sources.
3. Identify the decisions that must be locked before `epic-plan`; leave story-local choices open.
4. For unstable external facts, invoke `just-in-time-research` before locking the choice and retain only sources that affect the decision.
5. Load `.speck/templates/epic/architecture-template.md`. Fill applicable sections with epic-specific interfaces, data flow, failure behavior, security boundaries, operability, and proof seams; remove unused placeholders.
6. Record assumptions with a falsifier and deferred decisions with a reopening trigger.
7. Run the relevant artifact and reference checks, then append every non-trivial lock to the decision log.

The artifact must be detailed enough for `epic-plan` and `epic-breakdown`, but must not pre-implement stories.
