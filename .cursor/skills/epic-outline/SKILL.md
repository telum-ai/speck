---
name: epic-outline
description: Retired in Speck v8 (alias-shim). The v6 epic-outline research-mapping step is replaced by /speck-skeptical-review (enumerate technical-approach alternatives) + /speck-decision-log (lock the choice with rationale + SHA), with just-in-time research folded into /epic-plan. New invocations route there.
disable-model-invocation: false
---

# /epic-outline — retired in Speck v8 (alias-shim)

The v6 outline (a separate research-mapping step) no longer exists as its own artifact. Its work is now covered by:

- `/speck-skeptical-review` — enumerate ≥3 technical-approach alternatives with tradeoffs
- `/speck-decision-log` — lock the chosen approach with rationale + SHA
- `/epic-plan` — performs just-in-time research inline

**Do this instead**: `/epic-clarify` → (`/speck-skeptical-review` if the approach is unclear) → `/epic-plan`.

> Alias-shim kept for muscle memory / back-compat. See `docs/v8/v8-north-star.md` §4 and AGENTS.md.
