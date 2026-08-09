# speck-recheck

Engagement-gap drift detector. Run before new feature work when assumptions may be stale.

Input: `$ARGUMENTS`.

## When to run (mandatory)

- >14 days since latest truth artifact `verified` stamp
- New agent / no session continuity
- User requests audit, "make ship-ready", "is this still working"
- `project-state.md` Next action unknown or empty
- `.speck/.v8-reprove-needed` exists OR `staleness-check.sh` reports `V8_STALE` (stamp `< speck 8`) → `V8_REPROVE.P1`; route `/speck-reprove` before other drift work

Recommended: major dependency updates; multiple parallel branches merged since last validation.

## Prerequisites

- Speck project (`specs/projects/<id>/`)
- Git repository

## 1. Locate project

Find project dir. Play level from `.speck/project.json`. Required checks: `project-state.md`, truth artifacts per play level, `product-contract.md`, `evidence-contract.md`.
