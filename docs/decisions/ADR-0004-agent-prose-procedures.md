# ADR-0004: Agent prose applies to skill references/procedures

- **Date**: 2026-08-09
- **Status**: accepted
- **Class**: always-on-contract

## Context

v11 relocated oversized SKILL.md bodies into `references/procedure.md`. Several of those files still carried human essays (field evidence, version history, "why this gate exists"). On invoke the model loads the procedure — so essay relocation is not subtraction.

## Decision

1. Every agent-consumed routine — `SKILL.md`, `references/**/*.md`, `.speck/reference/*` — follows ADR-0003 dense imperative prose.
2. Field evidence, design history, and anti-bloat lectures live only in `docs/decisions/`, `CHANGELOG.md`, and north-stars.
3. Corpus-budget CI lints skill `references/` for essay patterns and line ceilings (≤280; shrink-only grandfather if needed).
4. Operational rules (gates, P-codes, severity maps, STOP, commands) stay; narrative justification does not.

## Field evidence home (moved out of procedures)

Project `001-odd` (planning-analysis gate motivation, #106): full canonical Build flow + inline primitives still left 1 CRITICAL + 13 HIGH defects; all found only by a decorrelated multi-lens pass by non-authors. That evidence justifies the analyze gates in CHANGELOG / this ADR — never in `*-analyze` procedures.

## Budget delta

Large cut on invoke-time tokens for analyze/validate/router skills. No new always-on AGENTS surface.

## Consequences

Procedures look sparse to humans reviewing git history. That is intentional. Expanding a procedure with essay prose fails CI.
