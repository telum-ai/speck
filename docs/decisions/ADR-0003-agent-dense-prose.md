# ADR-0003: Agent-dense imperative prose

- **Date**: 2026-08-09
- **Status**: accepted
- **Class**: always-on-contract
- **Amended**: 2026-08-09 — scope includes skill `references/` (see ADR-0004)

## Context

Agent instruction files used human-oriented formatting (emoji headers, tutorial tone, field-evidence essays). Models prefer short imperative steps; every token competes for adherence. Relocating essays into `references/` without densifying them does not reduce invoke-time tax.

## Decision

These paths use dense imperative prose (numbered steps, STOP if, explicit commands/outputs; no emoji section headers; no “you can / feel free” filler; no version-history / field-evidence essays):

- `AGENTS.md`
- `.cursor/skills/*/SKILL.md`
- `.cursor/skills/*/references/**/*.md`
- `.speck/reference/*`

Humans use CHANGELOG, north stars, README, `docs/decisions/`. Corpus-budget lint enforces the bar.

## Budget delta

Improves adherence density; enables real invoke-time cuts when procedures shrink.

## Evidence

Cursor create-skill + agentskills progressive disclosure + Claude instruction guidance (<200 lines, structured, specific). Invoke-path reality: matched skills load `references/procedure.md` on step 1.

## Consequences

Agent files look less “polished” to humans; that is intentional. See ADR-0004 for procedure ceilings.
