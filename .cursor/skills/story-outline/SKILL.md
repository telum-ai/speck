---
name: story-outline
description: Retired alias. Use when /story-outline named.
disable-model-invocation: true
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# /story-outline — retired in Speck v8 (alias-shim)

The v6 outline (a separate research-mapping step) no longer exists as its own artifact. Its work is now covered by:

- `/speck-skeptical-review` — enumerate implementation-approach alternatives with tradeoffs
- `/speck-decision-log` — lock the chosen approach
- `/story-plan` — performs just-in-time research inline

**Do this instead**: re-read the marked canonical Story flow in root `AGENTS.md` and resume at its first incomplete applicable slot.

Alias kept for user-invoked muscle memory and excluded from automatic selection.
