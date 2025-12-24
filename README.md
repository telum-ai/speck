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

## Automatic Updates

Speck checks daily for updates and creates PRs via `.github/workflows/speck-update-check.yml`.

Updates use **smart merging** to preserve your customizations:
- Your `AGENTS.md` content outside `SPECK:START..END` tags
- Your `.gitignore` entries
- Your custom hooks and MCP config
- Your `README.md` (if customized)
- Your `copilot-setup-steps.yml` (if customized)

For private Speck repos, add `SPECK_GITHUB_TOKEN` secret.

## Methodology Feedback

After running retrospective commands, you can opt-in to share methodology insights with the Speck team.

See: `.speck/README.md` for full documentation.
