---
name: epic-outline
description: Retired alias → speck-skeptical-review / story-tasks. Use when /epic-outline named.
disable-model-invocation: true
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# /epic-outline — retired in Speck v8 (alias-shim)

The v6 outline (a separate research-mapping step) no longer exists as its own artifact. Its work is now covered by:

- `/speck-skeptical-review` — enumerate ≥3 technical-approach alternatives with tradeoffs
- `/speck-decision-log` — lock the chosen approach with rationale + SHA
- `/epic-plan` — performs just-in-time research inline

**Do this instead**: re-read the marked canonical Epic flow in root `AGENTS.md` and resume at its first incomplete applicable slot.

Alias kept for user-invoked muscle memory and excluded from automatic selection.
