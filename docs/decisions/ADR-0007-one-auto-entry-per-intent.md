# ADR-0007: One automatic entry per intent family

- **Date**: 2026-08-10
- **Status**: accepted
- **Class**: skill-catalog + JIT
- **Amends**: ADR-0002, ADR-0005, v11 north star §3.2
- **Amended by**: ADR-0012

## Context

Speck exposed generic routers and their level specialists to automatic selection at the same time. The model could choose either entrance for one intent, specialist doctrine drifted, and selecting the generic route added an avoidable second skill load. Ten routers/aliases alone occupied 13.5% of catalog-description context.

## Decision

1. One overlapping intent family has one canonical automatic surface.
2. Use a generic canonical DAG when the operation is shared and level is a cheap branch key. `analyze`, `adjust`, and `speck-scan` follow this shape.
3. Keep specialists automatic when levels prove materially different things. Project/epic/story validation and retrospectives follow this shape; their generic convenience routers are user-only.
4. Compatibility aliases remain only where observed user-facing invocation or migration value justifies their catalog cost. Unused aliases are removed and upgrades delete their stale installed copies.
5. `.speck/reference/skill-catalog-policy.json` is the machine source of truth. Corpus CI fails a missing/extra `disable-model-invocation`, a missing family entrypoint, or an oversized/reference-owning shim.
6. Canonical multi-level DAGs use executable context contracts. Transcript conformance proves selected reach, sibling exclusion, load-before-mutation timing, and post-write gates.

## Analyze staging

Analysis has three temporally distinct loads: selected corpus core, one level-specific lens per independent reviewer, then the selected report template after findings exist. This prevents the conductor from preloading sibling lenses or the 13 KiB report template during review.

## Consequences

- Automatic catalog entries fall from 76 to 63; description context falls from 4,847 to 4,049 characters.
- Shared analyze/adjust invariants have one authority.
- Retained legacy names add one compatibility hop only when explicitly named; unused adjust and story-analyze aliases no longer occupy the catalog.
- Transcript validation can distinguish correct branch use from a prose claim that the method was followed.
