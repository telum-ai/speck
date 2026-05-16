---
name: speck-decision-log
description: Append a decision-lock entry to project-decisions-log.md at every phase boundary. Unconditional discipline — invoked from project-specify, project-product-contract, project-evidence-contract, project-architecture, project-plan, epic-plan, epic-architecture, story-plan, and any other skill that locks a non-trivial choice. Captures 3+ alternatives + tradeoff + chosen + rationale + SHA + date. Read this skill when you need to log a decision; do not write to the log directly. FIRST ACTION is read the template at .speck/templates/project/project-decisions-log-template.md.
disable-model-invocation: false
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

Read the existing log's decision index table. The next ID is `DEC-<NNNN>` (zero-padded, monotonic).

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

Add a row to the Decision Index table at the top.

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

- NEVER skip the SHA + date stamping
- NEVER allow fewer than 3 alternatives to be logged
- NEVER edit a locked decision; supersede instead
- ALWAYS update the index table when appending
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
- `/recheck` (decisions reopened by drift findings)
- Any skill that runs the skeptical-review primitive

## Context: $ARGUMENTS
