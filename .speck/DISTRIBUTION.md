# Speck Distribution

This document explains how to get Speck into your project and keep it updated.

## Distribution Methods

Speck offers three distribution methods:

| Method | Best For | Automation |
|--------|----------|------------|
| **CLI** | New projects, manual updates | On-demand |
| **Template Sync** | Repos created from template | Automatic |
| **Update Action** | Existing repos wanting auto-updates | Automatic PRs |

## Method 1: CLI (Recommended for New Projects)

The simplest way to add or update Speck:

```bash
# Initialize Speck in current directory
npx @telum-ai/speck init

# Upgrade to latest version
npx @telum-ai/speck upgrade

# Upgrade to specific version
npx @telum-ai/speck upgrade v2.1.0

# Preview changes before applying
npx @telum-ai/speck upgrade --dry-run

# Check for available updates
npx @telum-ai/speck check
```

### CLI Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would change without making changes |
| `--force` | Overwrite existing files without prompting |
| `--ignore <pattern>` | Additional patterns to ignore (repeatable) |

## Method 2: Template Sync (For Template-Based Projects)

If you created your repo from the Speck template, automatic syncing is built in:

1. The workflow `.github/workflows/template-sync.yml` syncs from the template
2. Configure `.templatesyncignore` to protect your project-specific files
3. When Speck releases a new version, a PR is automatically created

### Configuration

Edit `.templatesyncignore` to specify files that should never be overwritten:

```gitignore
# Your specifications
specs/**

# Your source code
src/**
backend/**
frontend/**

# Your README
README.md

# Project-specific Copilot setup
copilot-setup-steps.yml
```

## Method 3: Update Action (For Existing Repos)

Add automated update PRs to any existing repo:

1. Copy `.github/workflows/speck-update-check.yml.sample` to `.github/workflows/speck-update-check.yml`
2. The workflow runs weekly and creates PRs when updates are available
3. Review and merge the PR to apply updates

### Manual Trigger

You can also trigger the update check manually from the Actions tab.

## What Gets Synced

Speck methodology files are always synced:

```
.speck/                        # Templates, patterns, documentation
.cursor/commands/              # Command files
.cursor/hooks/                 # Validation hooks
.github/workflows/speck-*.yml  # Orchestration workflows
.github/copilot-instructions.md
.github/instructions/
.github/ISSUE_TEMPLATE/speck-*.yml
AGENTS.md
```

## What's Protected

These files are never overwritten by default:

```
specs/**                       # Your specifications
src/**                         # Your source code
README.md                      # Your README
.git/**                        # Git directory
node_modules/**                # Dependencies
package.json                   # Your package.json
.env*                          # Environment files
copilot-setup-steps.yml        # Project-specific Copilot setup
```

## Custom Ignore Patterns

Create `.speckignore` in your project root:

```gitignore
# Custom Cursor rules I don't want overwritten
.cursor/rules/my-custom-rules.mdc

# Project-specific GitHub workflows
.github/workflows/deploy.yml
```

## Version Tracking

Speck stores the current version in `.speck/VERSION`. This is used to:

1. Detect if updates are available
2. Generate accurate changelogs
3. Track which version each project is using

## Releases

All releases are published on GitHub with detailed release notes:

https://github.com/telum-ai/speck/releases

### Versioning

Speck follows semantic versioning:

- **Major** (v2.0.0): Breaking changes to methodology
- **Minor** (v2.1.0): New features, backward compatible
- **Patch** (v2.1.1): Bug fixes, documentation updates

## Migrating Between Methods

### From Template Sync to CLI

1. Remove `.github/workflows/template-sync.yml`
2. Use `npx @telum-ai/speck upgrade` when you want updates

### From CLI to Update Action

1. Copy the sample workflow to `.github/workflows/`
2. The action will handle future updates automatically

### From Template Sync to Update Action

1. Remove `.github/workflows/template-sync.yml`
2. Copy the sample workflow to `.github/workflows/`
3. Rename `.templatesyncignore` to `.speckignore`
