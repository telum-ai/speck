# Feeding Learnings Back Into the Speck Template

Speck is designed to be **self-improving**. When you build products with Speck, you will discover:
- reusable patterns
- systemic gotchas
- missing template sections
- command ordering improvements
- automation improvements (CI/hooks)

To keep the template repo improving **without** letting product repos drift, use a **two-channel model**:

1) **Template → Product sync** (via `actions-template-sync`)  
2) **Product → Template feedback** (via issues/PRs driven by retrospectives)

This file documents the **Product → Template** feedback channel.

## The feedback contract (where to write it)

Speck retrospectives are the source of truth for validated learnings:
- Epic: `specs/projects/<PROJECT_ID>/epics/<EPIC_ID>/epic-retro.md`
- Project: `specs/projects/<PROJECT_ID>/project-retro.md`

The epic/project retro templates include an upstream section:

- `<!-- SPECK_FEEDBACK:START -->`
- `<!-- SPECK_FEEDBACK:END -->`

Put template improvement proposals **only** inside that block.

## What qualifies as “template-worthy”

Only upstream improvements that are validated:
- **Epic-level**: confirmed across **2+ stories** in the epic
- **Project-level**: confirmed across **2+ epics** in the project

Each proposal SHOULD include:
- target file(s) in the template (`.speck/**`, `.cursor/**`, `AGENTS.md`, `.github/workflows/speck-validation.yml`, etc.)
- evidence (links to story/epic retros)
- a suggested patch (preferred)

## Automating the feedback to the template repo (recommended)

This repo includes an optional workflow:
- `.github/workflows/speck-template-feedback.yml`

In a product repo, configure these secrets:
- **`SPECK_TEMPLATE_FEEDBACK_REPO`**: `<owner>/<template-repo>`
- **`SPECK_TEMPLATE_FEEDBACK_TOKEN`**: a PAT (fine-grained is recommended) with permission to create issues in the template repo

When an epic/project retro changes, the workflow:
1. Extracts the `SPECK_FEEDBACK` block(s)
2. Opens an issue in the template repo containing the proposed changes + evidence

If secrets are not configured, the workflow exits without doing anything.

## Why issues (default) instead of auto-PRs

Issues are the safest “intake” mechanism:
- no accidental template breakage
- human review of proposed diffs
- can batch and prioritize improvements

If you later want auto-PRs, add a second stage in the template repo that turns a labeled issue into a PR.

