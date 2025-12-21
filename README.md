# Speck 🥓 Template

Speck is a spec-driven development methodology for building digital products via:
- **Commands** (`.cursor/commands/`)
- **Templates** (`.speck/templates/`)
- **Automation hooks** (`.cursor/hooks/`)
- **Validation workflows** (`.github/workflows/`)

## Getting Started

In Cursor, start with:
- `/speck [describe what you want to build]`

Speck will route you through **project → epic → story** levels.

## MCP Setup (Recommended)

See: `.cursor/MCP-SETUP.md`

## Specs live here

Speck project artifacts are written under:
- `specs/projects/`

## Template sync (optional)

If you use this as a GitHub template repo, you can keep product repos up to date using:
- `.github/workflows/template-sync.yml`
- `.templatesyncignore`

See: `.speck/TEMPLATE-SYNC.md`

## Feeding learnings back (optional)

Validated learnings can be exported back to the template repo from product repos via:
- `.github/workflows/speck-template-feedback.yml`

See: `.speck/TEMPLATE-FEEDBACK.md`
