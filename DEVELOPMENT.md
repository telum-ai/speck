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
│   └── scripts/                     # Utility scripts (validation, audit, etc.)
├── .cursor/skills/                  # AI agent skills (synced to projects)
├── .claude/                         # Claude Code config (synced to projects)
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
| `SKIP_IF_CUSTOMIZED` | Skipped if the project has modified the file | One-time setup files (v7.6.0: README handled separately — see below) |
| **Project README** | Dedicated handler in `syncProjectReadme()` | Root `README.md` — skeleton on init, footer merge on upgrade, auto-repair legacy Speck marketing |
| **PROFILE validation** | `validate-readme.sh` + `profile-drift-check.sh` | Staged README on pre-commit; SHIP-RC gates in validate skills |
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

## Workflow and Sync Management

### Removing a synced file from projects

Follow the "Removing a synced file" process above. Specifically:
1. Move from `ALWAYS_OVERWRITE` to `REMOVE_FILES` in `sync.js`
2. Delete the file in this repo
3. Release a new version — projects pick up the removal on `speck upgrade`

## Migration (major-version upgrades)

Speck upgrades across a major boundary are automatic on `npx github:telum-ai/speck upgrade` and never delete content — they drop a marker and defer the semantic work to a skill that runs on the next engagement. Two boundaries exist today.

### v6 → v7 (`/speck-catch-up`)

**Step 1 — Scaffolding (automatic, CLI).** `bash .speck/scripts/migrate.sh <project-dir>` runs per project:

1. Adds `speck_version: 7.0.0` to `.speck/project.json`.
2. Scaffolds **empty** templates: `product-contract.md`, `evidence-contract.md`, `project-decisions-log.md`, `project-state.md`, `design-system/primitives.md` (each with a `<!-- v7 MIGRATION SCAFFOLD -->` banner).
3. SHA-stamps existing v6 truth artifacts with current HEAD.
4. Writes a `migration-report.md` per project.
5. Drops a `.speck/.migration-needs-catchup` marker at workspace root.
6. **Does NOT delete any v6 content.**

**Step 2 — Catch-up (brownfield reconstruction, `/speck-catch-up`).** The next engagement detects the marker (via AGENTS.md's first-action rule) and runs the skill, which:

1. Backfills `product-contract.md` from `project.md` + `PRD.md` + `ux-strategy.md` + `domain-model.md` + `constitution.md`.
2. Backfills `evidence-contract.md` from the active recipe's `evidence_contract:` defaults.
3. Reconstructs `project-decisions-log.md` from git history.
4. Backfills `experience-chain.md` for each UI epic from `user-journey.md` + `wireframes.md` + story specs.
5. **Honesty pass** — downgrades unsupported v6 PASS claims to `IMPL-GREEN`, flags surrogate proof.
6. Regenerates `project-state.md` with post-honesty reality.
7. Writes `project-catch-up-plan.md` (P0–P3 remediation).
8. Removes the marker.

Without `/speck-catch-up`, a migrated project carries v6 debt under v7 paint. The skill is mandatory for any project not built v7-native from day one.

**v6 command compatibility.** v6 commands (`/story-analyze`, `/epic-outline`, `/story-outline`, `/project-scan`, …) keep working via alias-shims that route to their current equivalents. The level triplets also expose `--level` dispatchers (`/validate`, `/retrospective`, `/adjust`, `/analyze`) that route to the preserved per-level specialists.

### v7 → v8 (`/speck-reprove`)

v8 ("Evaluation Over Verification") does **not** trust v7-era "green" as evaluation-proven — v7 green was optimized to satisfy enumerated checks (Goodhart), the exact failure mode v8 fixes. The upgrade is deliberately two-layer (design: `docs/v8/v8-north-star.md`):

**Layer 1 — Mechanical (automatic, instant, non-destructive).** On `upgrade` across the v7 → v8 boundary the CLI bumps versions, reconciles the `SPECK:START..END` blocks, installs the alias-shims and lazy patterns, and drops a `.speck/.v8-reprove-needed` marker (the analog of v6 → v7's `.migration-needs-catchup`).

**Layer 2 — Semantic re-prove (`/speck-reprove`, cap-and-worklist).** Any truth artifact stamped `< speck 8` is `V8_STALE` regardless of SHA/date freshness. The next engagement's `/recheck` detects the marker (or a `V8_STALE` stamp), raises `V8_REPROVE.P1`, blocks new feature work, and routes to `/speck-reprove`, which:

1. Triages each suspect-green artifact against the four principles (P1–P4).
2. **Caps** effective shippable state at `INTEGRATION-GREEN` and reverts consumer **FELT-GOOD to `uncovered`**.
3. **Preserves** each historical v7 claim, stamped `[pre-v8-proof]` (nothing reset to zero).
4. Emits a prioritized `project-v8-reprove-report.md` worklist. States climb back to `verified` only as real v8 evidence (adversarial LARP, mechanism-grounded audit) lands.

Without `/speck-reprove`, a v8-upgraded project keeps claiming v7 ship-readiness under v8 paint. The re-prove is mandatory for any project not built v8-native from day one.
