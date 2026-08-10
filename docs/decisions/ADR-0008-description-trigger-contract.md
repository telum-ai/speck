# ADR-0008: Skill description trigger contracts

- **Date**: 2026-08-10
- **Status**: accepted
- **Class**: skill-catalog
- **Amends**: ADR-0001 and v11 north star §6
- **Amended by**: ADR-0009 (routing evaluation includes always-on flow)

## Context

V11 reduced automatic description context from roughly 30k characters to 4k. Every automatic entry retained a `Use ...` clause, but several clauses became labels or circular conditions instead of selection evidence. One compression changed `story-extract` from reverse-engineering existing code into the incorrect claim that it mined epic materials. The corpus gate measured size, not discovery fitness.

[Anthropic's skill-authoring guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#writing-effective-descriptions) treats `name` and `description` as the discovery surface: descriptions carry both WHAT and specific trigger/context WHEN, use third person, and are tested on intended models.

## Decision

1. Every automatic description uses two semantic slots: third-person WHAT and specific `Use ...` WHEN.
2. Lifecycle position or sibling boundaries appear only when they affect selection.
3. Template paths, first actions, procedure, and exhaustive output detail remain JIT.
4. User-only routers and compatibility shims keep explicit-name-only descriptions.
5. The 120-character per-entry and 10k aggregate ceilings remain. Evidence does not show that either blocks specific triggers.
6. Static validation enforces shape. `skill-routing-cases.json` covers every automatic skill, and the routing evaluator measures model selection separately from body execution.
7. Real transcript conformance remains the judge of actual skill load timing and sibling exclusion after host selection.

## Evidence plan

- Corpus mutations remove WHAT, WHEN, and trigger specificity.
- Routing harness mutations omit a skill, duplicate a case, or inject a wrong prediction.
- Live always-on trials report exact-match accuracy and forbidden-sibling selections per model.
- Catalog reports prove selection only. Host invocation and JIT load timing require separately captured transcript evidence.

## Consequences

Descriptions spend more of the existing catalog budget on discovery signal. Size lint can no longer stand in for trigger quality, and routing quality can be re-run when models or the catalog change.
