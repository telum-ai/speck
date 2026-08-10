---
name: project-plan
description: Creates PRD + epics + E000. Use after required PROMISE artifacts.
paths:
  - "specs/projects/**"
---

# project-plan

Input: `$ARGUMENTS`.
Output: `[PROJECT_DIR]/PRD.md`, `[PROJECT_DIR]/epics.md`, `[PROJECT_DIR]/epics/E###-*/epic.md` placeholders.
Templates: `.speck/templates/project/prd-template.md`, `.speck/templates/project/epics-list-template.md`.
Prereq: `project.md`; Platform requires `architecture.md`.

## 0. Templates

Read both templates before writing.

## 1. Play level

Read `.speck/project.json` → `play_level`.

| Level | Action |
|-------|--------|
| Sprint | STOP — use `sprint-prd-template.md`; `/project-promote` first |
| Build | Proceed; architecture optional unless 4+ epics (gate below) |
| Platform | Full flow; `architecture.md` REQUIRED |

### Build complexity gate

If `play_level=build` and plan yields **≥4 epics** → STOP; warn:

Required before continue: `architecture.md`, `ux-strategy.md`.
Required after plan: `/analyze --level project` (3 lenses) before any `/epic-specify`.

Options: `/project-promote` (6+ epics) · architecture+ux then continue · reduce to ≤3 epics.

Platform: `/analyze --level project` required regardless of epic count.

## 2. Load foundation

STOP if `project.md` missing → `/project-specify`.
STOP if Platform and `architecture.md` missing → `/project-architecture`.

Load:
- **Required**: `architecture.md`, `context.md`
- **Recommended**: `ux-strategy.md`, `constitution.md`, `domain-model.md`, `design-system.md`
- **Brownfield**: `project-landscape-overview.md`, `project-import.md`
- **Research**: `*-research-report-*.md`
- **Recipe**: `_active_recipe:` in `project.md` → `.speck/recipes/[name]/recipe.yaml` (`suggested_epics`, `patterns`, `external_services`)

JIT research (`.cursor/skills/just-in-time-research/SKILL.md`) for market/competition/pricing gaps → embed in PRD "Research Informing This Plan."

## 3. Scale

Map scope → Level 0–4 (atomic → 40+ stories, 5+ epics). Adaptive PRD depth by level.

## 4. Phase 1 — PRD

Fill `prd-template.md` from foundation + research + `project.md` vision. Incorporate architecture decisions, UX principles, constraints, domain terms, constitution MUSTs.

## 5. Phase 2 — Epics

Recipe present → start from `suggested_epics`; customize. Else derive from PRD.

Each epic: standalone value, deployable slice, clear success criteria, 3–15 stories typical, dependencies noted.

**E000 gate** — ask: include Developer Infrastructure epic (CI, tests, lint, env)? Default YES for production; skip reason in `epics.md` if NO.

## 6. Phase 3 — epics.md + placeholders

Write `epics.md` from `epics-list-template.md`.

**Concurrency waves** (required: Platform OR ≥4 epics):
- Assign every epic to exactly one wave
- Fill Touch-points per epic (Migrations, Models/Services, Files/Components)
- Validate:
```bash
bash .speck/scripts/validation/validators/validate-wave-safety.sh epics.md
```
- Wave 0 = E000; parallel waves = independent slices; integrators last

Create `epics/E###-[name]/epic.md` placeholders:
```
**Current State**: Draft (Placeholder)
- [x] **Draft** - Placeholder created by `/project-plan`
- [ ] **Specified**
```
NEVER set `Specified` on placeholders.

## 7. Validation

PRD covers project goals; epics cover scope; no gaps/overlaps; dependencies + metrics clear.

## 8. Next

| Step | When |
|------|------|
| `/analyze --level project` | REQUIRED Platform; Build 4+; recommended Build 1–3 |
| `/project-roadmap` | Optional timeline |
| `/epic-specify` | Blocked until analyze gate clears |
| `/project-validate` | Post-implementation only — NOT now |

Never write `.analysis-gate-grandfathered` on new plans.

## NEVER / ALWAYS

- NEVER plan Platform without architecture.md
- NEVER skip wave validation at 4+ epics
- NEVER mark placeholder epics Specified
- NEVER grandfather a new corpus
- ALWAYS read both templates first
- ALWAYS run `/analyze --level project` before first `/epic-specify` when gate applies
