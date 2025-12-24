# Speck Distribution

This document explains how to get Speck into your project and keep it updated.

## Distribution Methods

Speck offers two distribution methods:

| Method | Best For | Automation |
|--------|----------|------------|
| **CLI** | New projects, manual updates | On-demand |
| **Update Action** | Existing repos wanting auto-updates | Automatic PRs |

> ⚠️ **Template Sync is deprecated.** See [Migration Guide](#migrating-from-template-sync) below.

## Method 1: CLI (Recommended for New Projects)

The simplest way to add or update Speck. Runs directly from GitHub (no npm publish):

```bash
# Initialize Speck in current directory
npx github:telum-ai/speck init

# Upgrade to latest version
npx github:telum-ai/speck upgrade

# Upgrade to specific version
npx github:telum-ai/speck upgrade v2.1.0

# Preview changes before applying
npx github:telum-ai/speck upgrade --dry-run

# Check for available updates
npx github:telum-ai/speck check
```

> **Access Control**: Requires read permission to the telum-ai/speck repository.
> If the repo is private, users must be collaborators or org members.

### CLI Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Show what would change without making changes |
| `--force` | Overwrite existing files without prompting |
| `--ignore <pattern>` | Additional patterns to ignore (repeatable) |

## Method 2: Update Action (For Existing Repos)

Add automated update PRs to any existing repo:

1. Copy `.github/workflows/speck-update-check.yml.sample` to `.github/workflows/speck-update-check.yml`
2. The workflow runs weekly and creates PRs when updates are available
3. Review and merge the PR to apply updates

### Manual Trigger

You can also trigger the update check manually from the Actions tab.

### Private Speck Repos

If telum-ai/speck is private, the action needs a token to access it:

1. Create a Personal Access Token (PAT) with `repo` scope
2. Add it as a repository secret named `SPECK_TOKEN`
3. Update the workflow to include: `speck-token: ${{ secrets.SPECK_TOKEN }}`

See the sample workflow file for the exact syntax.

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

## Migrating from Template Sync

Template Sync has been deprecated in favor of the CLI and Update Action.

### Quick Migration (5 minutes)

```bash
# 1. Delete the old workflow
rm .github/workflows/template-sync.yml

# 2. Rename ignore file (optional, for custom patterns)
mv .templatesyncignore .speckignore 2>/dev/null || true

# 3. Create version file
mkdir -p .speck
echo "v2.2.0" > .speck/VERSION

# 4. For automated updates, copy the sample workflow
cp .github/workflows/speck-update-check.yml.sample \
   .github/workflows/speck-update-check.yml

# 5. Commit
git add -A
git commit -m "chore: migrate from template-sync to speck-update-action"
```

### What Changes

| Before (Template Sync) | After (Update Action) |
|------------------------|----------------------|
| `.templatesyncignore` | `.speckignore` |
| `TEMPLATE_SYNC_SOURCE_REPO` secret | No secrets needed (public) or `SPECK_TOKEN` (private) |
| Syncs from HEAD | Syncs from releases |
| actions-template-sync | Speck Update Action |

### Manual Updates Only

If you prefer manual control, skip step 4 and just use:

```bash
npx github:telum-ai/speck upgrade
```

## Migrating Between CLI and Update Action

### From CLI to Update Action

1. Copy the sample workflow to `.github/workflows/`
2. The action will handle future updates automatically

### From Update Action to CLI

1. Delete `.github/workflows/speck-update-check.yml`
2. Use `npx github:telum-ai/speck upgrade` when you want updates
