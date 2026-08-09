# ADR-0002: User-only orchestrators + delete domain skills

- **Date**: 2026-08-09
- **Status**: accepted
- **Class**: skill-catalog | delete

## Context

`disable-model-invocation` hid domain skills that were never observed loading, while `/speck`/`/story`/`/epic` (user entry points) remained auto. Domain how-tos duplicated recipes + Context7.

## Decision

1. `disable-model-invocation: true` only on `speck`, `story`, `epic`.
2. Delete the ~20 generic domain/integration skills (Stripe, Clerk, Supabase, …, `model-selection`).
3. Substitutes: `.speck/recipes/` for stack start; Context7 / official docs for vendor APIs.
4. CI enforces the allowlist.

## Budget delta

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Domain skill dirs | ~20 | 0 | −20 skills |
| Catalog noise | domain descs | gone | down |

## Evidence

Owner field report (never loaded) + process skills barely reference the pack.

## Consequences

No Speck-owned Stripe playbook until a future recipe expansion. Agents use Context7 JIT.
