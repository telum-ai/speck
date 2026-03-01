# Speck Development Guide

Instructions for developing, releasing, and maintaining the Speck methodology and CLI.

## Repository Structure

```
speck/
├── package.json                     # CLI package (npm) — version here is the CLI version
├── packages/cli/                    # CLI source code
│   └── lib/
│       ├── commands/                # CLI commands (init, upgrade, check, version)
│       ├── sync.js                  # Core sync/merge logic + file lists
│       └── github.js                # GitHub API utilities
├── .speck/                          # Methodology files (synced to projects)
│   ├── VERSION                      # ⚠️  NOT the release version — see Versioning below
│   ├── README.md                    # Methodology documentation
│   ├── templates/                   # Story/epic/project templates
│   ├── patterns/                    # Design and implementation patterns
│   ├── recipes/                     # Project quickstart recipes
│   └── scripts/                     # Utility scripts (audit, orchestrate, etc.)
├── .cursor/skills/                  # AI agent skills (synced to projects)
├── .claude/                         # Claude Code config (synced to projects)
├── .github/workflows/               # GitHub Actions workflows
│   ├── speck-validation.yml         # Spec validation (synced to projects)
│   ├── speck-update-check.yml       # Update checker (synced to projects)
│   ├── speck-orchestrator.yml       # Orchestrator (DISABLED v5.2.0, not synced)
│   └── ...                          # Test/CI workflows (not synced)
└── tests/                           # Test fixtures and specs
```

## ⚠️ Versioning — READ THIS FIRST

Speck has **one version** that matters: the **GitHub release tag**.

### How versioning works

1. `speck upgrade` fetches the **latest GitHub release** via the API
2. The **release tag name** (e.g., `v5.2.0`) becomes the version written to each project's `.speck/VERSION`
3. `speck upgrade` compares the project's `.speck/VERSION` against the release tag to determine if an upgrade is needed

### What this means

| File | Purpose | Used by upgrade? |
|------|---------|:---:|
| **GitHub release tag** | **THE version** — written to projects on upgrade | ✅ Yes — this is the source of truth |
| `.speck/VERSION` (in project) | Tracks which release the project was upgraded to | ✅ Yes — compared against release tag |
| `.speck/VERSION` (in this repo) | Gets overwritten in projects by the release tag; keep in sync but not authoritative | ⚠️ Overwritten |
| `package.json` version | CLI/npm package version; displayed by `speck version` | ❌ Not used by upgrade |

### Version rules

- **Always use semver**: `vMAJOR.MINOR.PATCH` (with `v` prefix on tags)
- **Never create a release tag lower than the previous one** — projects will show a "downgrade"
- **Keep `package.json` version and `.speck/VERSION` aligned with the release tag** — avoid confusion
- Check the latest release tag before bumping: `gh release list --limit 1`

## Releasing a New Version

### 1. Make your changes

Work on `main` branch. Key files to consider:

- **Methodology changes**: `.speck/templates/`, `.speck/patterns/`, `.speck/recipes/`, `.speck/scripts/`, `.speck/README.md`
- **Skill changes**: `.cursor/skills/`, `.cursor/agents/`
- **CLI changes**: `packages/cli/lib/`
- **Sync behavior**: `packages/cli/lib/sync.js` (see Sync System below)
- **Workflow changes**: `.github/workflows/`

### 2. Bump the version

```bash
# Check current latest release
gh release list --limit 1

# Bump package.json and .speck/VERSION to match
# Example: if latest release is v5.2.0, bump to v5.3.0
npm version minor --no-git-tag-version   # or manually edit package.json
echo "v5.3.0" > .speck/VERSION
```

### 3. Commit and push

```bash
git add -A
git commit -m "feat: description of changes (v5.3.0)"
git push origin main
```

### 4. Create GitHub release

```bash
gh release create v5.3.0 \
  --title "v5.3.0 — Short description" \
  --notes "## What changed
- Change 1
- Change 2

### Upgrade
\`\`\`bash
npx github:telum-ai/speck upgrade
\`\`\`"
```

### 5. Verify

```bash
# In any Speck project:
npx github:telum-ai/speck upgrade --dry-run
npx github:telum-ai/speck upgrade
```

## The Sync System (`sync.js`)

The sync system controls what happens when a project runs `speck init` or `speck upgrade`. Understanding it is critical before adding or removing synced files.

### File categories

| Category | Behavior | When to use |
|----------|----------|-------------|
| `ALWAYS_OVERWRITE` | Replaced on every upgrade — project customizations are lost | Methodology files, templates, skills, workflows that must stay current |
| `SMART_MERGE_FILES` | Custom merge function preserves project content | `AGENTS.md` (Speck controls `SPECK:START..END`), `.gitignore`, `hooks.json`, `mcp.json` |
| `SKIP_IF_CUSTOMIZED` | Skipped if the project has modified the file | `README.md`, one-time setup files |
| `SKIP_PATTERNS` | Never synced to projects | Test files, internal tooling |
| `REMOVE_FILES` | **Deleted from projects** on upgrade | Deprecated files, removed features |

### Adding a new synced file

1. Create the file in the appropriate location in this repo
2. Add its path to `ALWAYS_OVERWRITE` in `sync.js` (or `SMART_MERGE_FILES` if it needs merging)
3. If it's a directory, add the directory path — sync handles recursive copying

### Removing a synced file

1. **Add the path to `REMOVE_FILES`** — this ensures `speck upgrade` cleans it up from projects
2. **Remove from `ALWAYS_OVERWRITE`** (or whichever category it was in)
3. Optionally keep the file in this repo for reference (it won't be synced)
4. Add a version comment: `// v5.3.0: Reason for removal`

### Disabling a feature (without removing)

1. Move the file path from `ALWAYS_OVERWRITE` to `REMOVE_FILES` in `sync.js`
2. Disable the file in this repo (e.g., comment out workflow triggers)
3. Keep the file for reference — it won't be synced to projects
4. Document the deprecation in the file header and in `.speck/README.md`

### The `PRESERVE_SUBDIRS` mechanism

Some directories in `ALWAYS_OVERWRITE` have subdirectories that projects can customize:

```js
const PRESERVE_SUBDIRS = {
  '.cursor/hooks/hooks': ['hooks.d'],  // Project hook extensions
};
```

When syncing `.cursor/hooks/hooks`, the `hooks.d/` subdirectory is preserved even though its parent is overwritten.

## CLI Commands

| Command | Source | Description |
|---------|--------|-------------|
| `speck init` | `commands/init.js` | Initialize Speck in a project (fetches latest release) |
| `speck upgrade` | `commands/upgrade.js` | Upgrade Speck to latest (or specific) release |
| `speck check` | `commands/check.js` | Check if updates are available |
| `speck version` | `commands/version.js` | Show CLI + project + latest version |

### Testing CLI changes locally

```bash
cd packages/cli
node bin/speck.js version
node bin/speck.js upgrade --dry-run /path/to/test-project
```

## GitHub Workflows

### Synced to projects (via `ALWAYS_OVERWRITE`)
- `speck-validation.yml` — Validates spec artifacts on PR
- `speck-update-check.yml` — Checks for Speck updates

### Internal only (not synced)
- `speck-orchestrator.yml` — **Disabled (v5.2.0)** — was the Copilot orchestrator
- `speck-orchestrator-test.yml` — **Disabled** — orchestrator unit tests
- `speck-orchestrator-e2e-test.yml` — **Disabled** — orchestrator integration tests
- `speck-e2e-cleanup.yml` — **Disabled** — E2E test cleanup
- `copilot-setup-steps.yml` — **Disabled** — Copilot agent environment setup

### Removing a workflow from projects

Follow the "Removing a synced file" process above. Specifically:
1. Move from `ALWAYS_OVERWRITE` to `REMOVE_FILES` in `sync.js`
2. Disable the workflow in this repo (change triggers to `workflow_dispatch:` only)
3. Release a new version — projects pick up the removal on `speck upgrade`
