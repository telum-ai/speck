# ADR-0010: Current-state runtime boundary

- **Date**: 2026-08-11
- **Status**: accepted
- **Class**: spine + JIT + distribution

## Context

The always-loaded `AGENTS.md` mixed the current method with release history, host-specific `/goal` assumptions, unexplained internal labels, and framework-development pointers. The shipped `.speck/` tree also mixed project runtime with methodology evaluations and Speck's own learned patterns. Meanwhile, `.speck/reference/` was required by AGENTS, skills, and the context loader but was not installed by the CLI.

This made the conceptual boundary false in both directions: agents received meta-history they did not need, while required JIT runtime files were absent. Wholesale sync of `.speck/patterns/` could also overwrite the exact project-owned learning area it claimed to support.

## Decision

1. Root `AGENTS.md` describes the current operating model in present-tense, plain language. It keeps the engagement ladder, principles, play levels, readiness model, canonical flow, and non-negotiable gates.
2. Host accelerators, detailed gap routing, command procedure, and artifact maps load JIT from skills or `.speck/reference/`. Native `/goal` is encouraged when available but never assumed.
3. Markdown tables are used only for compact exact mappings or comparisons. Ordered behavior uses numbered steps; nuanced doctrine uses prose or bullets.
4. Version-specific detail appears in live context only when an exact compatibility marker, migration token, or legacy artifact requires it. Release north stars live under `docs/history/` and are not linked from downstream runtime.
5. `.speck/` contains only framework files needed in an installed project: README, VERSION, templates, scripts, recipes, runtime reference, and optional MCP examples.
6. Speck's test harness and reports live under `tests/eval/`; methodology feedback and generalized framework learnings live under `docs/`.
7. `.speck/patterns/learned/` is project-owned and created only by project learning. Speck does not seed or overwrite it. Known framework-authored files from older releases are retired by exact path so project-created siblings survive upgrades.
8. CLI sync and template export ship the same runtime boundary. `.speck/reference/`, host-specific generated agents, `CLAUDE.md`, and cross-host skill links are part of that boundary; tests, reports, feedback, history, and project learning are not.
9. Upgrades remove the old framework-owned `.speck/eval/` and `.speck/feedback/` trees that could leak through template exports. Project-created `.speck/patterns/learned/` remains preserved.

## Consequences

A cold agent receives one current method instead of reconstructing it from release archaeology. Installed projects receive every JIT dependency named by the live instructions. Framework evaluation remains versioned and auditable without masquerading as product runtime. Project learning can finally persist across Speck upgrades.
