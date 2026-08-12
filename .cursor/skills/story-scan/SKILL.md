---
name: story-scan
description: Alias of speck-scan --level story. Use when /story-scan named.
disable-model-invocation: true
---

# /story-scan — retired in Speck v8 (alias-shim)

Brownfield code scanning is unified in **`/speck-scan`**, parameterized by level.

**Do this instead**: `/speck-scan --level story [--domain=X]` (HIGH-confidence deep dive on the files this story touches, before `/story-plan`).

Alias kept for user-invoked muscle memory and excluded from automatic selection.
