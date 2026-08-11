# project-evidence-contract / platform

## Purpose

`evidence-contract.md` prevents the recurring failure where **specs claim done while runtime proves otherwise.**

It locks down:
- What runtime evidence counts as proof (per platform)
- What does NOT count (e.g., browser screenshots for native iOS launch)
- Exact gate criteria for each readiness state (IMPL-GREEN → SHIP)
- Adversarial probes that must pass before SHIP-RC
- Where evidence artifacts live in the repo

Without this contract, validation reports drift into "tests pass therefore done" and ship docs lie about reality.

## Prerequisites

- `project.md` must exist
- `product-contract.md` should exist (paid promise + magic moments inform evidence requirements)
- Active recipe (if any) — provides `visual_testing` and platform-aware defaults
