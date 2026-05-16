---
name: speck-migrate
description: Migrate a v6 Speck project to v7 additively. Detects v6 project.json, creates new v7 artifacts (product-contract, evidence-contract, project-decisions-log, project-state, design-system/primitives) without deleting anything. Updates speck_version. Generates migration report. Load when user says "migrate to v7", "upgrade to v7", "speck migrate", or when a v6 project (speck_version <7 or absent) needs to adopt v7 mechanisms.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

Migrate an existing v6 Speck project to v7 without breaking anything. Strategy: **additive only** — never delete v6 artifacts. New v7 artifacts get scaffolded, and the agent populates them by running the corresponding skills, drawing content from existing v6 docs.

## When to Run

- User explicitly says "migrate to v7" / "upgrade to v7" / "/speck migrate"
- A v6 project (i.e., `.speck/project.json` has no `speck_version` or `speck_version < 7.0.0`) is detected on engagement
- `/project-state` reports v6 project without v7 artifacts present
- `/recheck` detects v6 project that needs migration to use v7 disciplines

## Prerequisites

- Existing project directory at `specs/projects/<id>/`
- (Optional) `.speck/project.json` with current `play_level`
- Git repo (for SHA stamping)

## Execution

### Step 1: Locate target project

```bash
# Argument or current dir context
PROJECT_DIR="${ARG_PROJECT_DIR:-$(detect_project_dir)}"
```

If multiple projects under `specs/projects/`, ask the user which one to migrate.

### Step 2: Detect v6 vs v7 state

Check:
- `.speck/project.json` → `speck_version` (absent or `<7` = v6)
- Presence of v7-only artifacts: `product-contract.md`, `evidence-contract.md`, `project-decisions-log.md`, `project-state.md`

If `speck_version >= 7.0.0` AND all v7 artifacts exist → already migrated. Tell the user and exit.

### Step 3: Confirm with user

Before any writes:

```
Migration plan for <PROJECT_ID>:

Will CREATE (additively):
  - product-contract.md          [scaffold, run /project-product-contract to fill]
  - evidence-contract.md         [scaffold, run /project-evidence-contract to fill]
  - project-decisions-log.md     [empty log, prior decisions added by /speck-decision-log]
  - project-state.md             [scaffold, /project-state will regenerate]
  - design-system/primitives.md  [scaffold if UI project]

Will UPDATE:
  - .speck/project.json          [speck_version → 7.0.0]
  - Existing truth artifacts     [add SHA stamp footer if missing]

Will NOT DELETE:
  - Any v6 file (constitution.md, ux-strategy.md, domain-model.md, design-system.md, etc.)
  - Any epic/story directories

Proceed? [Y/n]
```

### Step 4: Run the migration script

```bash
bash .speck/scripts/migrate.sh <PROJECT_DIR>
```

This script handles:
- `.speck/project.json` speck_version update
- Scaffolding v7 artifacts (skipping if they already exist)
- SHA-stamping existing v6 truth artifacts
- Writing `v7-migration-report.md`

### Step 5: Populate v7 artifacts from v6 content

The migration script leaves scaffolds with `<!-- v7 MIGRATION SCAFFOLD -->` banners. The agent must now run the corresponding skills to fill them, reading from existing v6 artifacts as inputs.

**Recommended order** (skip steps for missing v6 inputs):

1. **`/project-product-contract`** — Reads `project.md`, `PRD.md`, `ux-strategy.md` (if exists), `domain-model.md` (if exists), `constitution.md` (if exists). Produces `product-contract.md` consolidating paid promise, JTBD, magic moments, banned language, AI behavior contract.

2. **`/project-evidence-contract`** — Reads project recipe + `architecture.md`. Produces `evidence-contract.md` with per-platform valid/invalid proof sources and readiness state gate criteria.

3. **For each historical major decision found in commits or retros**, prompt the user: "Should I log this decision into `project-decisions-log.md`?" If yes, invoke `/speck-decision-log`.

4. **For UI projects, `/project-design-system`** in registry mode — populate `design-system/primitives.md` from existing components (scan output: `find <project>/components -type f`).

5. **`/project-state`** — Auto-regenerates the engagement-pickup view from the now-complete v7 artifacts.

### Step 6: Validate migration

Run:

```bash
bash .speck/scripts/staleness-check.sh <PROJECT_DIR>
```

Expected: all newly created v7 artifacts report `FRESH` (just stamped); existing v6 artifacts report `FRESH` (just stamped) or `NOSTAMP` if the agent skipped stamping due to no content change.

### Step 7: Update `project-state.md`

Trigger regeneration:

```bash
bash .speck/scripts/regenerate-project-state.sh
```

Then run `/project-state` to actually produce the file.

### Step 8: Report

```
🥓 v7 migration complete

Project: <PROJECT_ID>
Created (scaffolds): N artifacts
Populated: M artifacts
Pending agent action: K skills to run

Migration report: specs/projects/<PROJECT_ID>/v7-migration-report.md

Next:
  - Run /project-state to see current engagement-pickup view
  - Run /recheck to confirm drift-free state
  - Resume normal v7 workflow
```

## Compatibility Mode (No Migration)

If the user declines migration (`/speck-migrate → N`):

- The agent operates in **v7 read-write, v6 read-only** mode
- Reads v6 artifacts (`ux-strategy.md`, `domain-model.md`, etc.) where v7 equivalents are missing
- Will NOT write v7 artifacts; will produce v6-shaped output
- Will warn at each command: "Project is on v6. Run `/speck-migrate` to adopt v7 disciplines (LARP, audit, readiness states)."

## Behavior Rules

- **NEVER** delete a v6 artifact during migration
- **NEVER** silently overwrite — always check `if [[ -f "$target" ]]` and skip
- **ALWAYS** generate a migration report
- **ALWAYS** stamp newly created artifacts
- **ALWAYS** confirm with the user before any writes

## Context: $ARGUMENTS
