# speck-migrate / detect-crossing

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

## Compatibility Mode (No Migration)

If the user declines migration (`/speck-migrate → N`):

- The agent operates in **v7 read-write, v6 read-only** mode
- Reads v6 artifacts (`ux-strategy.md`, `domain-model.md`, etc.) where v7 equivalents are missing
- Will NOT write v7 artifacts; will produce v6-shaped output
- Will warn at each command: "Project is on v6. Run `/speck-migrate` to adopt v7 disciplines (LARP, audit, readiness states)."
