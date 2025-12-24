# @telum-ai/speck

CLI for managing the Speck methodology in your projects.

## Installation

No installation needed - use directly with `npx`:

```bash
npx @telum-ai/speck <command>
```

Or install globally:

```bash
npm install -g @telum-ai/speck
```

## Commands

### Initialize Speck

```bash
npx @telum-ai/speck init
```

Creates all Speck methodology files in your current directory.

### Upgrade Speck

```bash
# Upgrade to latest version
npx @telum-ai/speck upgrade

# Upgrade to specific version
npx @telum-ai/speck upgrade v2.1.0

# Preview changes without applying
npx @telum-ai/speck upgrade --dry-run
```

### Check for Updates

```bash
npx @telum-ai/speck check
```

### Show Versions

```bash
npx @telum-ai/speck version
```

## Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would change without making changes |
| `--force` | Overwrite existing files without prompting |
| `--ignore <pattern>` | Additional patterns to ignore (can be repeated) |

## Configuration

### `.speckignore`

Create a `.speckignore` file in your project root to specify files that should never be overwritten by Speck updates:

```gitignore
# Project-specific files
specs/**
src/**
README.md

# Configuration
copilot-setup-steps.yml
.env*

# Custom Cursor rules
.cursor/rules/my-project-rules.mdc
```

### Default Ignored Patterns

These patterns are always ignored (never synced from template):

- `specs/**` - Your specifications
- `src/**` - Your source code
- `README.md` - Your README
- `.git/**` - Git directory
- `node_modules/**` - Dependencies
- `package.json` - Your package.json
- `.env*` - Environment files
- `copilot-setup-steps.yml` - Project-specific Copilot setup

## What Gets Synced

Speck methodology files:

- `.speck/**` - Templates, patterns, documentation
- `.cursor/commands/**` - Command files
- `.cursor/hooks/**` - Validation hooks
- `.github/workflows/speck-*.yml` - Orchestration workflows
- `.github/copilot-instructions.md` - Copilot instructions
- `AGENTS.md` - Agent methodology guide

## Releases

See [GitHub Releases](https://github.com/telum-ai/speck/releases) for version history and changelogs.

## License

MIT
