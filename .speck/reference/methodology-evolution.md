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

Ceilings: `docs/v11/v11-north-star.md` §4.
Never mutate P1–P4 / first-actions / readiness axes / audit-before-validate / LARP split / graph hard `.P1`.
