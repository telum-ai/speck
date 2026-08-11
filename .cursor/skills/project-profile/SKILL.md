---
name: project-profile
description: Refreshes declared PROFILE surfaces. Use after product-contract changes before evidence-contract or when drift appears.
paths:
  - "specs/projects/**"
---

# project-profile

Input: `$ARGUMENTS` (`--claim <state>` when proving readiness).
Registry: `[PROJECT_DIR]/project.md` → `## PROFILE surfaces`.

## 1. Read before mutation

Read `.speck/templates/project/readme-template.md`, the active `project.md` PROFILE table, `product-contract.md` §1, and the existing root `README.md`. Every retained registry row is binding; delete a non-applicable row instead of leaving a decorative placeholder.

## 2. Refresh safe managed surfaces

1. Run `.speck/scripts/regenerate-project-readme.sh` to refresh the README footer, placeholders, and explicit AUTO-SYNC blocks while preserving user prose.
2. For a declared `package` adapter, run `.speck/scripts/regenerate-project-readme.sh --surface=package`. It may fill only an empty or placeholder description; user-owned drift remains a finding.
3. Do not rewrite `file` surfaces or the remote `github` description. Route product-surface copy changes through the owning story or project adjustment; remote mutation remains an owner/external gesture.

## 3. Prove every declared surface

```bash
bash .speck/scripts/profile-drift-check.sh [--claim <state>]
```

The checker reads the registry rather than a fixed surface list. It must emit one result per retained row plus `PROFILE_DRIFT_SUMMARY`. A required missing, unreachable, or severely divergent surface is `PROFILE_DRIFT.P1`; do not collapse it into README green.

At SHIP-RC+, also run:

```bash
bash .speck/scripts/validation/validators/validate-readme.sh --strict
```

## 4. Report and continue

Report refreshed surfaces, preserved user-owned surfaces, per-surface drift, and the exact readiness cap. Then re-read the marked canonical flow in root `AGENTS.md` and continue at the first incomplete applicable slot.

## Rules

- Treat README as PROFILE's center of gravity, never its full extent.
- Never overwrite user prose, a landing surface, package prose already owned by the user, or remote metadata to manufacture alignment.
- Never pass a readiness claim while any registry row required by that state has `PROFILE_DRIFT.P1`.
