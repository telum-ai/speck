---
name: project-state
description: Generate or regenerate project-state.md — the single-page agent first-read for any session. Load when starting any new engagement to check current state, when explicitly requested via /project-state, or as the auto-regeneration hook after any truth-affecting command (story-validate PASS, epic-validate PASS, project-validate, recheck). FIRST ACTION after loading is read the template at .speck/templates/project/project-state-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

Before any other action, read:
```
.speck/templates/project/project-state-template.md
```

The template defines required sections, SHA-stamping format, and the 200-line cap.

---

## Purpose

`project-state.md` is the **single-page status doc** that every agent reads FIRST on engagement. It replaces ad-hoc handoff docs and prevents the "AI must read 5,000+ lines to get oriented" failure mode.

It auto-regenerates on every truth-affecting command. It must be:
- Single-page (200 line cap)
- Three-minute read budget
- Honest about staleness, blockers, open questions
- The authoritative answer to "what's the next thing to do?"

## When to Run

| Trigger | What to do |
|---------|------------|
| User explicitly invokes `/project-state` | Regenerate fresh |
| Last `story-validate` returned PASS | Auto-regenerate to reflect new validated state |
| Last `epic-validate` returned PASS or FAIL | Auto-regenerate with new readiness state |
| `/recheck` just completed | Auto-regenerate with drift findings |
| `project-state.md` does not exist | Create from scratch |
| `project-state.md` exists but `[as of SHA <hash>]` differs from current HEAD by >5 commits | Regenerate |

## Execution Steps

### 1. Locate the project

Find `specs/projects/<PROJECT_ID>/` from current working directory by walking up. If multiple projects exist, prompt user to specify (or use `_active_project` field in `.speck/project.json` if present).

If no project found: ERROR "No Speck project detected. Run `/project-specify` first."

### 2. Detect play level

Read `.speck/project.json` for `play_level`. Missing = Platform.

### 3. Gather facts (subagent parallelization recommended)

Dispatch in parallel:

```
├── [Parallel] speck-explorer: List all epic + story directories with their current readiness states
├── [Parallel] speck-explorer: Find all SHA-stamped truth artifacts; compare stamps to current HEAD
├── [Parallel] speck-explorer: Find latest validation/audit/recheck reports across project/epics/stories
├── [Parallel] speck-explorer: Find open issues in any *-punch-list.md files
├── [Parallel] shell: git log --grep='PATTERN:\|GOTCHA:\|PERF:\|ARCH:\|RULE:\|DEBT:' -n 5
├── [Parallel] shell: git rev-parse --short HEAD
└── [Wait] → Synthesize into project-state.md sections
```

### 4. Compute readiness state map

For each level (project, epic, story):
- Look at the latest `validation-report.md` / `epic-validation-report.md` / `project-validation-report.md`
- Extract the claimed readiness state from the front matter or report header
- Look at `as of SHA` stamp; compare to HEAD; flag stale

If no validation report exists: state = `NO-SHIP` (default).

### 5. Compute truth-staleness report

For each truth artifact (project.md, PRD.md, architecture.md, context.md, design-system.md, ux-strategy.md, domain-model.md, product-contract.md, evidence-contract.md, constitution.md):
- Extract `[as of SHA <hash> | verified <date>]` footer if present
- Compare SHA to current HEAD
- Compute "verification age" from `verified <date>` to today
- Flag as ⚠️ Drift if SHA differs from HEAD
- Flag as ⚠️ Stale if `verified` is >14 days ago
- Flag as ✅ Fresh otherwise
- If no SHA stamp at all: ⚠️ No stamp — treat as proposal, not truth

### 6. Compute blocking issues

Gather from:
- Latest `*-audit-report.md` files: any P0/P1 findings
- Latest `*-validation-report.md` files: any FAIL status with blockers
- Latest `/recheck` output: any drift-detected blockers
- Any `*-punch-list.md` items marked P0/P1

Rank by severity (P0 → P3) and recency.

### 7. Compute open questions

Gather from:
- `project-decisions-log.md`: any entries marked `OPEN` (not yet locked)
- Any `[NEEDS CLARIFICATION]` markers in active specs
- Any explicitly recorded "awaiting human decision" notes in recent audit reports

### 8. Compute next action

The agent's authoritative answer to "what should I do next?" Decision tree:

1. If any P0 blocking issue exists → Next action is to resolve P0
2. Else if truth staleness has any ⚠️ Drift entries → Next action is `/recheck`
3. Else if any story is in `[Implemented]` state without `/audit` → Next action is `/audit` for that story
4. Else if any story is in `[Audited]` state without `/story-validate` → Next action is `/story-validate`
5. Else if any epic is in `[Stories Complete]` without `/epic-validate` → Next action is `/epic-validate`
6. Else if any story is in `[Tasked]` state without `/story-implement` → Next action is `/story-implement`
7. Else if any open `epic-breakdown.md` has Draft (Placeholder) stories → Next action is `/story-specify`
8. Else → Surface options to user

Write the next action with:
- Specific command + target (e.g., `/story-implement E003/S012-transcript-restraint`)
- 1-2 sentence rationale
- What blocks proceeding (or "Nothing — proceed autonomously")

### 9. Recent activity

Run `git log --grep='PATTERN:\|GOTCHA:\|PERF:\|ARCH:\|RULE:\|DEBT:' -n 5 --pretty=format:'%h %s'` and extract the last 5 learning-tagged commits.

### 10. Active work context

From git:
- `git branch --show-current` → active branch
- `git diff --name-only` since last validation SHA (read from latest validation-report.md) → modified files

From file system:
- Active epic = the one with most recent `epic.md` mtime that isn't validated
- Active story = the one with most recent `spec.md` mtime that isn't validated

### 11. Render the document

Use the template at `.speck/templates/project/project-state-template.md`. Fill every section. Keep it under 200 lines.

Footer must include the SHA stamp:
```
---

*[as of SHA `<git_sha_short>` | generated `<iso_timestamp>` | speck v7.0.0]*
```

### 12. Write and report

Write to `specs/projects/<PROJECT_ID>/project-state.md` (overwrite).

Report to user:
```
✅ project-state.md regenerated

Path: specs/projects/<PROJECT_ID>/project-state.md
Lines: <count>
Generated: <timestamp>
Truth status: <X> fresh, <Y> stale, <Z> drift-detected
Blocking issues: <count>
Open questions: <count>
Next action: <next-action-summary>
```

If line count > 200, refuse and report which section is bloated — compress it before writing.

## Behavior Rules

- NEVER commit to the file system if line count > 200; compress instead
- NEVER hallucinate readiness states; only mark what's in actual validation reports
- NEVER claim freshness without checking SHA stamps against HEAD
- ALWAYS include the SHA-stamp footer
- ALWAYS prefer concrete next-action over vague "review project"
- ALWAYS surface drift over hiding it — the agent's job is honest status, not optimism

## Integration Points

This skill is called automatically by:
- `story-validate` (after PASS) — final step
- `epic-validate` (after any verdict) — final step
- `project-validate` (after any verdict) — final step
- `recheck` (always) — final step

Other skills should never write to `project-state.md` directly — they trigger this skill instead.

## Context: $ARGUMENTS
