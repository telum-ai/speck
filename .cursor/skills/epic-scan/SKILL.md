---
name: epic-scan
description: Alias of speck-scan --level epic. Use when /epic-scan named.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# /epic-scan — retired in Speck v8 (alias-shim)

Brownfield code scanning is unified in **`/speck-scan`**, parameterized by level.

**Do this instead**: `/speck-scan --level epic [--domain=X]` (MEDIUM-confidence domain-relevant pass before `/epic-plan`).

> Alias-shim kept for muscle memory / back-compat. See `.cursor/skills/speck-scan/SKILL.md`, `docs/v8/v8-north-star.md` §4, and AGENTS.md.
