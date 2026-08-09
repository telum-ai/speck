# ADR-0003: Agent-dense imperative prose

- **Date**: 2026-08-09
- **Status**: accepted
- **Class**: always-on-contract

## Context

Agent instruction files used human-oriented formatting (emoji headers, tutorial tone). Models prefer short imperative steps; every token competes for adherence.

## Decision

AGENTS.md, SKILL.md, and `.speck/reference/*` use dense imperative prose: numbered steps, STOP if, explicit commands/outputs. No emoji section headers. No “you can / feel free” filler. Humans use CHANGELOG, north stars, README. Corpus-budget lint enforces emoji headers / tutorial filler patterns.

## Budget delta

Improves adherence density inside existing byte/line ceilings (not a size expansion).

## Evidence

Cursor create-skill + agentskills progressive disclosure + Claude “write effective instructions” (<200 lines, structured, specific).

## Consequences

Agent files look less “polished” to humans; that is intentional.
