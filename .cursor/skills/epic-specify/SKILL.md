---
name: epic-specify
description: Creates epic.md from project plan. Use when starting a new epic.
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-specify

Input: `$ARGUMENTS` (epic description + optional context hints).
Output: `[EPIC_DIR]/epic.md` (template: `.speck/templates/epic/epic-template.md`).
Prereq: Build/Platform play level; `/project-plan` placeholder or explicit create.

## 0. Template

Read `.speck/templates/epic/epic-template.md` before writing.

## 1. Play level

Read `.speck/project.json` → `play_level` (missing = Platform).

| Level | Action |
|-------|--------|
| Sprint | STOP — no epics; use PRD Build Plan or `/project-promote` |
| Build / Platform | Continue |

## 2. Pre-specify gate

```bash
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID]
```

Exit 1 → STOP; route to remedy printed by script:

| Code | Route |
|------|-------|
| `UNANALYZED_CORPUS.P1` | `/project-analyze` |
| `ANALYSIS_STALE.P1` | Re-run `/project-analyze` |
| `ANALYSIS_CRITICAL_OPEN.P1` | Fix/waive CRITICAL |
| `PROMISE_UNCOVERED.P1` | Fix coverage matrix |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Re-run with distinct reviewers |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | Fix graph read; treat as unknown |
| `ANALYSIS_GRANDFATHERED.P2` | Surface notice; proceed advisory |

Build 1–3 epics: gate optional. Also check `project-state.md` — STOP if prior epic implemented but not `/epic-validate`d (unless `--force` + logged rationale).

## 3. Mode

```bash
# In epic dir?
[[ -f epic.md ]] && EPIC_MODE=enhance || EPIC_MODE=create
```

**Enhance** (placeholder from `/project-plan`):
- Load existing `epic.md`; skip filled sections
- If `**Current State**` already `Specified` → warn; confirm re-specify
- Set `**Current State**: Specified`; check Draft + Specified boxes

**Create** (no `epic.md`):
- Resolve project from args or ask; list: `find specs/projects -name project.md`
- Duplication check: PRD, `epics.md`, `epics/` — similar epic? story-level instead?
- Next epic ID:
```bash
ls specs/projects/[PROJECT_ID]/epics/ \
  | grep -E '^(E[0-9]{3}|[0-9]{3})' \
  | sed -E 's/^E?([0-9]{3}).*/\1/' | sort -n | tail -1
```
- `mkdir -p specs/projects/[PROJECT_ID]/epics/[EPIC_ID]-[name]/`

## 4. Load context

- `project.md`, `PRD.md`, `epics.md`
- `[EPIC_DIR]/epic-codebase-scan.md` if present → brownfield pre-fill
- Gap-fill via Q&A: users, features, success criteria, constraints, dependencies, complexity

## 5. Write epic.md

Fill template from context. Mark gaps `[NEEDS CLARIFICATION: …]`.

**10-minute test**: explain capability + value + fit in <10 min. Needs "AND" or >15 stories → split epic; get approval.

Lifecycle:
```
**Current State**: Specified
- [x] **Draft** (if was placeholder)
- [x] **Specified**
```

## 6. Optional step evaluation

Scan saved `epic.md`. Emit table with evidence quotes — not generic advice.

| Step | Required when | Skip when |
|------|------------------|--------------|
| `/epic-clarify` | Vague AC; unclear scope; `[NEEDS CLARIFICATION]` | All AC testable |
| `/epic-constitution` | Regulated domain; API boundary; multi-team | Simple feature |
| `/epic-architecture` | 2+ services; new infra; perf targets; complex integration | CRUD on existing patterns |
| `/epic-journey` + `/epic-wireframes` | Greenfield UI; **Redesign Ambition** (see below) | Backend/CLI/infra only |
| Rubric Mode | Brownfield UI modifying existing screens; NOT Redesign Ambition | Greenfield or redesign |
| `/epic-outline` | Unfamiliar tech; TBD sections; competing approaches | Clear path |

**Redesign Ambition** (load before UI path):
1. Read `product-contract.md` §3 + §5 (Surface / System Boundary)
2. Read `ux-strategy.md` if present
3. Epic touches differentiating surfaces + claims modality shift → REQUIRED journey + wireframes; Rubric Mode prohibited unless founder confirms adequacy (log DEC)

**Brownfield signal**: `epic-codebase-scan.md` lists screens to modify.

Output table + `UI path:` + `Recommended path to /epic-plan:`.

**Continuation**:
- Orchestrated (`/epic`): proceed to first recommended step — do not stop at menu
- Interactive: ask "Proceed with [first step]?" and wait

Flow (greenfield UI): clarify → constitution → architecture → journey → wireframes → outline → plan
Flow (brownfield Rubric): clarify → constitution → architecture → encode Screen Rubric in `ux-strategy.md`/`primitives.md` → outline → plan

## NEVER / ALWAYS

- NEVER specify with failed pre-specify gate (exit 1)
- NEVER start new epic while prior unvalidated (without `--force`)
- NEVER set placeholder `Specified` before this skill runs
- NEVER skip Redesign Ambition founder gate silently
- ALWAYS read template first
- ALWAYS run optional step evaluation after save
- ALWAYS preserve epic ID and dependencies in enhance mode
