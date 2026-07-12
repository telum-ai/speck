---
name: speck-scan
description: Unified scan skill that extracts code-side facts from an existing codebase at project, epic, or story scope. This consolidates the v6 project-scan, epic-scan, and story-scan into one skill with a --level argument. Load when starting brownfield work, when /recheck needs a fresh code-side reality check, or when user says "scan this project/epic/story". Defaults to inferring level from current directory.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

`/scan` extracts code-side facts from an existing codebase and produces a scan artifact that downstream Speck commands consume. v7 unifies what v6 had as three separate skills.

| Scope | Output artifact | Used by |
|-------|------------------|---------|
| `--level project` | `project-landscape-overview.md` at project root | `/project-specify`, `/project-architecture`, `/project-plan`, `/recheck` |
| `--level epic` | `epic-codebase-scan-<topic>.md` in epic dir | `/epic-specify`, `/epic-plan` |
| `--level story` | `codebase-scan-<topic>.md` in story dir | `/story-specify`, `/story-plan`, `/audit` |

## When to Run

| Trigger | --level | What to do |
|---------|---------|------------|
| Brownfield project init | `project` | Full landscape (tech stack, structure, patterns, conventions) |
| Adding a new epic that touches existing code | `epic` | Topic-scoped scan of affected modules |
| Adding a new story that extends existing code | `story` | Narrow scan of file(s) being modified |
| `/recheck` needs fresh code-side reality | inferred | Re-scan at appropriate level |

## Level Detection (when not specified)

1. If user is in `specs/projects/<id>/epics/<eid>/stories/<sid>/` → default `--level story`
2. If user is in `specs/projects/<id>/epics/<eid>/` → default `--level epic`
3. If user is in `specs/projects/<id>/` or higher → default `--level project`

## Execution by Level

### --level project

Produces `project-landscape-overview.md`. Captures:
- Top-level structure (apps, packages, libraries)
- Tech stack (language, framework, build, test, lint, deploy tooling)
- Architectural patterns observed (monolith / microservices / monorepo / etc.)
- External dependencies (databases, third-party services, AI providers, auth)
- Codebase health signals (test coverage, type coverage, lint warnings, recent activity)
- Module boundaries + ownership patterns
- Existing design system / UI primitives (if any) — note for `/project-design-system`
- Recommended epic candidates (functional areas that could become epics)

Output template: `.speck/templates/project/project-landscape-overview-template.md` (use existing template).

### --level epic

Produces `epic-codebase-scan-<topic>.md` in `epics/E###-<name>/`. Captures:
- Files and modules in the epic's scope
- Existing patterns relevant to this epic (data flow, error handling, etc.)
- Existing tests covering this area
- Dependencies on other epics' code
- Known issues / debt in this area

### --level story

Produces `codebase-scan-<topic>.md` in `stories/S###-<name>/`. Captures:
- Specific files this story will touch
- Existing functions/classes/components to refactor vs extend
- Existing tests covering these surfaces
- Coupling to other surfaces

## Execution Steps

### 1. Detect level (per Level Detection rules above) or use --level arg

### 2. Locate paths

Find `specs/projects/<id>/` (and epic/story dirs as relevant).

### 3. Subagent parallel scan

```
├── [Parallel] speck-explorer: List top-level structure (or scoped)
├── [Parallel] speck-explorer: Detect tech stack (package.json, Cargo.toml, requirements.txt, etc.)
├── [Parallel] speck-scanner: Identify architectural patterns
├── [Parallel] speck-scanner: List external dependencies + integrations
├── [Parallel] speck-scanner: Test coverage + health signals
└── [Wait] → Synthesize into scan artifact
```

### 4. Write the scan artifact

Use the level-appropriate template. Write to the level-appropriate path.

### 5. Apply SHA stamp

```
.speck/scripts/stamp-truth.sh <output-path>
```

### 6. Report

```
🔍 /scan complete

Level: <project | epic | story>
Output: <path>
Summary: <1 sentence>

Next:
- For project: run /project-specify (or /project-clarify if specifying)
- For epic: run /epic-specify (or /epic-plan if specifying)
- For story: run /story-specify (or /story-plan if specifying)
```

## v6 Compatibility

The v6 `/project-scan`, `/epic-scan`, `/story-scan` skills remain present as thin shims that route to this unified skill.

## Behavior Rules

- NEVER scan more broadly than the level requires (story scan is narrow)
- ALWAYS use SHA stamp on output
- ALWAYS reference output from downstream commands' "Information Sources" section

## Context: $ARGUMENTS
