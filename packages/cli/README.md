# Speck CLI

Command-line interface for managing Speck methodology in your projects.

## Usage

Run directly from GitHub (no install needed):

```bash
# Initialize Speck in a new project
npx github:telum-ai/speck init

# Upgrade to latest version
npx github:telum-ai/speck upgrade

# Check for updates
npx github:telum-ai/speck check

# Show current version
npx github:telum-ai/speck version
```

## Smart Merging

The CLI uses intelligent merging to preserve your customizations during updates:

| File | Strategy |
|------|----------|
| **AGENTS.md** | Speck controls `SPECK:START..END`, your content outside preserved |
| **.gitignore** | Your entries merged with Speck defaults |
| **.cursor/hooks/hooks.json** | Your hooks merged with Speck hooks |
| **.cursor/mcp.json** | Your config takes precedence over Speck defaults |
| **README.md** | Skipped if you customized it |
| **copilot-setup-steps.yml** | Skipped if you customized it |
| **Methodology files** | Always updated (commands, templates, patterns, workflows) |
| **.claude/commands** | Auto-mirrored from `.cursor/commands` during init/upgrade |

## Commands

### `init`

Initialize Speck in the current directory.

```bash
npx github:telum-ai/speck init [options]
```

Options:
- `--force` - Reinitialize even if already initialized
- `--dry-run` - Show what would be created without making changes

### `upgrade`

Upgrade Speck to the latest version (or a specific version).

```bash
npx github:telum-ai/speck upgrade [version] [options]
```

Options:
- `version` - Target version (default: latest)
- `--dry-run` - Show what would change without making changes

### `check`

Check if a newer version of Speck is available.

```bash
npx github:telum-ai/speck check
```

### `version`

Show the current Speck version.

```bash
npx github:telum-ai/speck version
```

## Private Repositories

If the Speck repository is private, set the `SPECK_GITHUB_TOKEN` environment variable:

```bash
SPECK_GITHUB_TOKEN=ghp_xxx npx github:telum-ai/speck upgrade
```

## Automatic Updates

Projects include a daily update workflow (`.github/workflows/speck-update-check.yml`) that:
1. Checks for new Speck versions
2. Runs `npx github:telum-ai/speck upgrade`
3. Creates a PR with the changes

For private Speck repos, add `SPECK_GITHUB_TOKEN` as a repository secret.
