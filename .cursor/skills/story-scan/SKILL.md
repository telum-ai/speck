---
name: story-scan
description: Retired in Speck v8 (alias-shim). Story-scoped brownfield code scanning is now /speck-scan --level story (one recipe-driven scan skill for project/epic/story). New invocations route there.
disable-model-invocation: false
---

# /story-scan — retired in Speck v8 (alias-shim)

Brownfield code scanning is unified in **`/speck-scan`**, parameterized by level.

**Do this instead**: `/speck-scan --level story [--domain=X]` (HIGH-confidence deep dive on the files this story touches, before `/story-plan`).

> Alias-shim kept for muscle memory / back-compat. See `.cursor/skills/speck-scan/SKILL.md`, `docs/v8/v8-north-star.md` §4, and AGENTS.md.
