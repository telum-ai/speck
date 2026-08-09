# ADR-0001: Hard corpus budget CI

- **Date**: 2026-08-09
- **Status**: accepted
- **Class**: always-on-contract

## Context

AGENTS.md exceeded Codex's 32 KiB default and Claude's ~200-line adherence guidance. Skill descriptions burned multi-host listing budgets. No gate prevented re-bloat after v8/v9.

## Decision

Ship `validate-corpus-budget.sh` with hard ceilings (AGENTS ≤16 KiB / ≤200 lines; desc ≤120 each / ≤10k sum; disable-model allowlist; skill body ≤200 with shrink-only grandfather; ref nodes ≤120 lines / ≤8 KiB; declared execution-path byte caps). Wire it into `npm test` and `.github/workflows/quality.yml`. Fail closed on regressions and PR whitespace errors.

## Budget delta

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| AGENTS bytes | ~62810 | ≤16384 | −≥46k |
| Desc sum | ~30k | ≤10000 | −≥20k |

## Evidence

`validate-corpus-budget.test.sh` mutation-covers every budget class, including hidden ref edges and execution-path overflow. A1-lite separately protects its six seeded defect capabilities against an immutable baseline.

## Consequences

Methodology PRs must show budget room or equal retirement. Human docs stay outside always-on.
