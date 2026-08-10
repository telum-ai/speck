---
name: story-analyze
description: Retired alias → audit. Use when /story-analyze named.
disable-model-invocation: true
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# /story-analyze — retired compatibility shim

`/story-analyze` no longer produces a standalone `analysis-report.md`. Its two jobs are covered by:

- **Consistency (pre-impl)** — folded into the tail of `/story-tasks` (spec ↔ plan ↔ tasks coverage/conflict check).
- **Adversarial cross-check (post-impl)** — `/audit` (`speck-audit`), the separately-incentivized truth-seeking pass (P4) run BEFORE `/story-validate`.

**Do this instead**: `/story-plan` → `/story-tasks` → `/story-implement` → `/audit` → `/story-validate`.

Alias kept for user-invoked muscle memory. It is excluded from automatic selection.
