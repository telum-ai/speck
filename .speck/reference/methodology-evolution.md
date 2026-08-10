# Methodology evolution

Classify every Speck change: spine | always-on-contract | skill-catalog | jit | delete.

Prefer JIT (`references/`, templates, scripts, recipes).

Always-on / catalog expansion requires:
- budget room or equal retirement
- ADR in `docs/decisions/`
- fail-closed A1-lite candidate-corpus score against the immutable baseline for gate changes

Run: `bash .speck/scripts/validation/validators/validate-corpus-budget.sh`

For DAG changes, add/update every affected static branch in `skill-load-budgets.json`; dynamic selector DAGs declare the Cartesian-path ceiling in `skill-load-contracts.json`. A reference must be directly owned by its router or executable contract; references never route to references.

One intent family exposes one automatic selection surface. Put cheap level/host/archetype variation behind that canonical router; keep genuinely different evidence models as specialist auto skills. Compatibility aliases and convenience-only routers are user-only and declared in `skill-catalog-policy.json`.

## Automatic description contract

An automatic skill description is discovery infrastructure, not a body summary:

1. **WHAT** — third-person action plus the concrete artifact, outcome, or capability.
2. **WHEN** — `Use ...` plus observable user intent, artifact state, or concrete cases.
3. **WHERE / BOUNDARY when selection-critical** — phase-bound optional skills name their nearest `after`/`before` boundary; event-driven skills name the event boundary (`before lock`, `before dispatch`, `after discovery`).

Target two sentences: `<WHAT>. Use <WHEN, with WHERE or BOUNDARY if needed>.` Template paths, first actions, procedure, and exhaustive outputs stay in the JIT body. User-only routers and compatibility shims instead state that they run only when explicitly named.

The complete canonical flow lives in the marked block in root `AGENTS.md`, so every Speck agent receives it before skill selection. JIT references and skill bodies explain gates and procedure; they never own a competing sequence.

Every automatic skill must have a case in `skill-routing-cases.json`. The versioned `skill-routing/baseline.json` separately pins ordered canonical routes and classifies the whole automatic catalog; changing it after bootstrap requires the external `flow-baseline-change-approved` PR label. Treat description quality as a routing claim: run the always-on evaluator with the exact catalog + canonical-flow context on intended model families. Its reports prove selection only; use separately captured host transcripts to prove invocation, excluded siblings, and load timing. Static lint proves shape and coverage only.

Ceilings: `docs/v11/v11-north-star.md` §4.
Never mutate P1–P4 / first-actions / readiness axes / audit-before-validate / LARP split / graph hard `.P1`.
