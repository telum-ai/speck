---
name: speck-decision-log
description: Appends a decision lock to the project log. Use at phase boundaries whenever a non-trivial choice is locked.
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

`project-decisions-log.md` is an append-only history of locked decisions with rationale, alternatives, and SHA stamps. It exists so that:

- Future agents (or humans) can understand WHY past decisions were made
- Drift detection can compare current state to locked intent
- Retrospectives have evidence of decisions vs outcomes
- Reopening a decision requires explicit supersession, not silent override

This skill is the ONLY way to write to the log. Other skills invoke this one.

## When to Run

Triggered by other skills at phase boundaries. The triggering skill provides:
- **Phase name** (e.g., "product-contract", "evidence-contract", "epic-plan", "story-plan")
- **Decision title**
- **At least 3 alternatives considered** + tradeoffs
- **Chosen option** + rationale
- **Consequences accepted**

If the calling skill provides fewer than 3 alternatives: REFUSE and tell the calling skill to run the skeptical-review primitive first.

## Execution Steps

### 1. Locate or create the log

Find `specs/projects/<PROJECT_ID>/project-decisions-log.md`. If missing, create from template.

### 2. Generate next decision ID

**Band selection** (prevents number races under concurrent epic execution):

| Context | Band | Next ID rule |
|---------|------|--------------|
| Project-level phases (`project-specify`, `product-contract`, `evidence-contract`, `project-plan`, `project-architecture`, `recheck`) | `DEC-0001`–`DEC-0099` | Max in `DEC-0001`…`DEC-0099` + 1 |
| Epic-level phases (`epic-plan`, `epic-architecture`, `epic-specify`, story-plan inside epic) | `DEC-{NN}01`–`DEC-{NN}99` | `{NN}` = epic number from active epic ID (`E002` → `02`); max in band + 1 |

**Detect active epic**: cwd under `epics/E###-*` or caller-provided epic ID in `$ARGUMENTS`. If epic context is clear, use epic band even on `epic/*` branches.

Scan the log body for `### DEC-NNNN` headings in the **target band only** (source of truth — do NOT rely solely on the index table). Next ID = monotonic max in band + 1.

- Project band empty → start `DEC-0001`
- Epic `E002` band empty → start `DEC-0201` (not `DEC-0002`)
- Epic band exhausted (`DEC-{NN}99` used) → STOP; escalate — band needs expansion or sequential merge

### 2b. Reconcile Decision Index table

If `## Decision Index` is missing, out of sync, or has gaps:
1. Parse all `### DEC-NNNN` entries and their metadata (Date, Phase, Status from entry body).
2. Rebuild the index table under `## Decision Index` from parsed headings.
3. Preserve all `## Decisions` body entries unchanged (append-only discipline).

If the index exists and is current, append one row for the new entry only.

### 3. Validate inputs

The caller (skill) provided:
- Phase ✅
- Decision title ✅
- At least 3 alternatives ✅
- Chosen option ✅
- Rationale ✅

If anything is missing or only 1-2 alternatives present: STOP. Tell the calling skill "Run skeptical-review with N≥3 alternatives first."

### 4. Capture context

- SHA at decision time: `git rev-parse --short HEAD`
- Date: today
- Owner: [AI agent / human / both]

### 5. Append the entry

Append to `## Decisions` section. Do NOT modify any existing entry (other than updating `Supersedes:` on a superseded entry's Status field).

### 6. Update the index table

Add a row to the Decision Index table (or rebuild per step 2b if missing/stale).

### 7. Re-stamp the file

```
.speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/project-decisions-log.md
```

### 8. Report

Return to caller:
```
✅ DEC-NNNN logged: <title>
```

## Behavior Rules

- NEVER assign global sequential DEC IDs when epic context is active — use the epic's band
- NEVER skip the SHA + date stamping
- NEVER allow fewer than 3 alternatives to be logged
- NEVER edit a locked decision; supersede instead
- ALWAYS update or rebuild the index table when appending (scan `### DEC-` headings as source of truth)
- ALWAYS re-stamp the file footer

## Integration Points

Invoked by:
- `/project-specify` (at project lock)
- `/project-product-contract` (paid promise, differentiator, magic moment locks)
- `/project-evidence-contract` (valid/invalid proof sources, gate criteria locks)
- `/project-architecture` (architectural pattern, tech stack locks)
- `/project-plan` (epic split decisions)
- `/epic-plan` (technical approach lock)
- `/epic-architecture` (cross-cutting decisions)
- `/story-plan` (significant technical choices only)
- `/speck-recheck` (decisions reopened by drift findings)
- Any skill that runs the skeptical-review primitive

## Context: $ARGUMENTS
