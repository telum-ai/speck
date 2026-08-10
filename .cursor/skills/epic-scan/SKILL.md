---
name: epic-scan
description: Alias of speck-scan --level epic. Use when /epic-scan named.
disable-model-invocation: true
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# /epic-scan — retired in Speck v8 (alias-shim)

Brownfield code scanning is unified in **`/speck-scan`**, parameterized by level.

**Do this instead**: `/speck-scan --level epic [--domain=X]` (MEDIUM-confidence domain-relevant pass before `/epic-plan`).

Alias kept for user-invoked muscle memory and excluded from automatic selection.
