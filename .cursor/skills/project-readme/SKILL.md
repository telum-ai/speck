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

Root `README.md` is the **PROFILE pillar** center-of-gravity artifact (enforced from v7.7+). It derives from PROMISE + PROVE.

Speck manages:
- **Footer** (`<!-- SPECK:START -->` … `<!-- SPECK:END -->`) — always refreshed
- **AUTO-SYNC blocks** — always overwritten from declared source
- **Scaffold placeholders** — auto-filled while still matching template text
- **User-edited sections** — read-only outside AUTO-SYNC blocks

### AUTO-SYNC opt-in (v7.7+)

```markdown
<!-- PROFILE:AUTO-SYNC source=product-contract.md section=1 -->
> Paid promise copy here — always refreshed from contract Section 1
<!-- /PROFILE:AUTO-SYNC -->
```

## When to Run

| Trigger | Command |
|---------|---------|
| After `/project-specify` | `regenerate-project-readme.sh` |
| After `/project-product-contract` | `regenerate-project-readme.sh` |
| After `/project-state` | `regenerate-project-readme.sh` |
| `/epic-validate` PASS (UX-RC+) | `regenerate-project-readme.sh --epic-validated E###` |
| `/recheck` | `profile-drift-check.sh` (+ regen if P3 only) |
| `/speck-catch-up --phase=profile` | backfill + regen |
| Package description sync | `regenerate-project-readme.sh --surface=package` |
| Landing hero drift check | `regenerate-project-readme.sh --surface=landing` (check-only) |
| Story validate (PROFILE UI) | `regenerate-project-readme.sh --check` |
| Drift check only | `regenerate-project-readme.sh --check` |

**Invoked automatically by upstream skills — do not wait for the user to ask.**

## Execution Steps

### 1. Locate project

Find `specs/projects/<PROJECT_ID>/` from cwd or `.speck/project.json` `_active_project`.

### 2. Run script with appropriate flags

Parse `$ARGUMENTS` for `--surface=`, `--check`, `--epic-validated=`.

```bash
.speck/scripts/regenerate-project-readme.sh [flags] [PROJECT_ID]
```

Validation (separate):
```bash
.speck/scripts/validation/validators/validate-readme.sh [--strict]
.speck/scripts/profile-drift-check.sh
```

### 3. Drift grading (from `/recheck`)

| Finding | Severity | Action |
|---------|----------|--------|
| `PROFILE_DRIFT.P1` | SHIP-RC blocker | Surface to user; do not overwrite user one-liner without consent |
| `PROFILE_DRIFT.P2` | UX-RC warning | Recommend regen or AUTO-SYNC block |
| `PROFILE_DRIFT.P3` | Informational | Safe to auto-refresh footer / placeholders |

### 4. Report

```
✅ README.md refreshed (PROFILE)

Path: README.md
Project: <PROJECT_ID>
Auto-filled: ...
Preserved: ...
Drift: P1=0 P2=0 P3=0

Optional: gh repo edit --description "<one-liner>"
```

## Behavior Rules

- NEVER overwrite user prose outside AUTO-SYNC blocks
- NEVER skip footer refresh when markers exist
- ALWAYS run `profile-drift-check.sh` when invoked from `/recheck`
- ALWAYS run after `/project-state` completes

## Integration Points

- Scripts: `regenerate-project-readme.sh`, `profile-drift-check.sh`, `validate-readme.sh`
- Surfaces table: `project.md` ## PROFILE surfaces
- Gates: `evidence-contract.md` ### PROFILE Gate Criteria

## Context: $ARGUMENTS
