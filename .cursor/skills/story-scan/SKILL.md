---
name: story-scan
description: Alias of speck-scan --level story. Use when /story-scan named.
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# /story-scan — retired in Speck v8 (alias-shim)

Brownfield code scanning is unified in **`/speck-scan`**, parameterized by level.

**Do this instead**: `/speck-scan --level story [--domain=X]` (HIGH-confidence deep dive on the files this story touches, before `/story-plan`).

> Alias-shim kept for muscle memory / back-compat. See `.cursor/skills/speck-scan/SKILL.md`, `docs/v8/v8-north-star.md` §4, and AGENTS.md.
