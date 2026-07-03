---
name: story-outline
description: Retired in Speck v8 (alias-shim). The v6 story-outline research-mapping step is replaced by /speck-skeptical-review (enumerate implementation-approach alternatives) + /speck-decision-log (lock the choice), with just-in-time research folded into /story-plan. New invocations route there.
disable-model-invocation: false
---

# /story-outline — retired in Speck v8 (alias-shim)

The v6 outline (a separate research-mapping step) no longer exists as its own artifact. Its work is now covered by:

- `/speck-skeptical-review` — enumerate implementation-approach alternatives with tradeoffs
- `/speck-decision-log` — lock the chosen approach
- `/story-plan` — performs just-in-time research inline

**Do this instead**: `/story-clarify` → (`/speck-skeptical-review` if the approach is unclear) → `/story-plan`.

> Alias-shim kept for muscle memory / back-compat. See `docs/v8/v8-north-star.md` §4 and AGENTS.md.
