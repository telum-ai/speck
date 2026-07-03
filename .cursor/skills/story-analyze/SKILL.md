---
name: story-analyze
description: Retired in Speck v8 (alias-shim). The v6 story-analyze cross-check is split — the pre-implementation spec/plan/task consistency check now runs at the tail of /story-tasks, and the adversarial behavior-vs-spec check is /audit (speck-audit), run AFTER implementation. New invocations route there.
disable-model-invocation: false
---

# /story-analyze — retired in Speck v8 (alias-shim)

`/story-analyze` no longer produces a standalone `analysis-report.md`. Its two jobs are covered by:

- **Consistency (pre-impl)** — folded into the tail of `/story-tasks` (spec ↔ plan ↔ tasks coverage/conflict check).
- **Adversarial cross-check (post-impl)** — `/audit` (`speck-audit`), the separately-incentivized truth-seeking pass (P4) run BEFORE `/story-validate`.

**Do this instead**: `/story-plan` → `/story-tasks` → `/story-implement` → `/audit` → `/story-validate`.

> Alias-shim kept for muscle memory / back-compat. `analysis-report.md` is optional in v7+ (no longer a hard prereq of `/story-implement`). See `docs/v8/v8-north-star.md` §4 and AGENTS.md.
