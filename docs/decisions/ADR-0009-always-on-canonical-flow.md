# ADR-0009: Always-on canonical flow

- **Date**: 2026-08-10
- **Status**: accepted
- **Class**: spine + skill-catalog
- **Amends**: ADR-0008 and v11 north star §6

## Context

ADR-0008 improved description discovery, but its catalog-only evaluator omitted the other context every real Speck agent receives: root `AGENTS.md`. That document carried only a compressed Build path, while fuller and conflicting sequences lived JIT in `command-phases.md` and individual skills. `epic-constitution` therefore described the right condition without exposing its place, and the always-on flow never prompted the agent to evaluate it before planning.

## Decision

1. Root `AGENTS.md` owns one marked, complete project/epic/story flow. It is always in context on every supported host.
2. `command-phases.md` and skill bodies explain gates and procedure but never carry another complete sequence.
3. Phase-bound optional descriptions include the nearest lifecycle boundary as well as their activation condition. Event-driven skills name their event boundary.
4. The routing evaluator receives the exact marked AGENTS flow alongside skill metadata. Reports bind catalog, cases, flow, and route-baseline hashes independently.
5. A versioned route baseline declares the ordered routes and classifies every automatic skill as flow-bound, always-on elsewhere, or event-driven. Static validation fails on missing, extra, reordered, or unclassified skills.
6. After this bootstrap PR, changing that baseline requires the external `flow-baseline-change-approved` PR label. A `pull_request_target` guard runs the checker from the trusted base branch and never executes candidate code, so the candidate patch cannot remove or approve its own guard.
6. Catalog reports prove selection under always-on context. Host transcripts remain the proof of actual invocation and JIT load timing.

## Consequences

Sequence knowledge is paid once in the spine instead of reconstructed from descriptions or discovered after a skill triggers. Descriptions can stay concise while optional slots remain activatable. Any flow edit invalidates checked-in routing evidence until intended models are rerun; changing the route baseline additionally needs an external approval gesture.
