---
name: project-readme
description: Generate or refresh the root README.md public face from Speck truth artifacts. Load after /project-specify, /project-product-contract, or automatically via /project-state regeneration. Keeps GitHub-visible project identity in sync with PROMISE and PROVE. FIRST ACTION is read .speck/templates/project/readme-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## Step 0: Read Template First

Before any other action, read:
```
.speck/templates/project/readme-template.md
```

---

## Purpose

Root `README.md` is the **PROFILE pillar** artifact — the public face GitHub visitors see first. It derives from PROMISE (`product-contract.md`, `project.md`) and PROVE (`project-state.md`) but is not a substitute for either.

Speck manages:
- **Footer only** (`<!-- SPECK:START -->` … `<!-- SPECK:END -->`) — always refreshed
- **Scaffold sections** — auto-filled only while they still match template placeholders
- **User-edited sections** — read-only; never overwritten

## When to Run

| Trigger | Action |
|---------|--------|
| After `/project-specify` creates `project.md` | First populate title + PROJECT_ID links |
| After `/project-product-contract` locks contract | Refresh elevator pitch from paid promise |
| After `/project-state` regeneration | Refresh status line + footer |
| `/recheck` detects README drift | Flag drift; refresh placeholder sections only |
| `/speck-catch-up --phase=finalize` | Repair legacy Speck-marketing README + populate |
| User invokes `/project-readme` | Full regen pass |

**This skill is invoked automatically by upstream skills — do not wait for the user to ask.**

## Execution Steps

### 1. Locate project

Find `specs/projects/<PROJECT_ID>/` from cwd or `.speck/project.json` `_active_project`.

If no project: ERROR "No Speck project detected. Run `/project-specify` first."

### 2. Run regeneration script

```bash
.speck/scripts/regenerate-project-readme.sh [PROJECT_ID]
```

Exit code handling:
- `0` — success; continue to report
- `1` — no project; stop with error
- `2` — README lacks SPECK markers; tell user to run `speck upgrade` first, then retry

### 3. Drift check (when invoked from `/recheck`)

Compare README one-liner (`> ...` blockquote) against `product-contract.md` Section 1 paid promise:
- If both exist and diverge materially → flag **P1 PROFILE drift** in recheck report
- Do NOT overwrite user-edited one-liner; surface the drift for human decision

### 4. Report

```
✅ README.md refreshed (PROFILE)

Path: README.md
Project: <PROJECT_ID>
Auto-filled: <list sections still at template placeholders that were updated>
Preserved: <list user-edited sections left untouched>
Footer: updated (Speck version + cross-links)

Optional: align GitHub repo description with one-liner via:
  gh repo edit --description "<one-liner>"
```

## Behavior Rules

- NEVER overwrite user-edited README sections (non-placeholder content)
- NEVER copy Speck marketing content to root README
- NEVER skip footer refresh when markers exist
- ALWAYS run after `/project-state` write completes
- ALWAYS preserve `<!-- SPECK:START -->` / `<!-- SPECK:END -->` markers

## Integration Points

- Invoked by: `/project-specify`, `/project-product-contract`, `/project-state`, `/speck-recheck`, `/speck-catch-up` finalize
- Script: `.speck/scripts/regenerate-project-readme.sh`
- Template: `.speck/templates/project/readme-template.md`
- Sources: `project.md`, `product-contract.md`, `project-state.md`

## Context: $ARGUMENTS
