# epic-retrospective — procedure

Input: `$ARGUMENTS` (epic id).
Output: `[EPIC_DIR]/epic-retro.md` (template: `.speck/templates/epic/epic-retro-template.md`).
Prereq: all stories validated; story retros or sanctioned fallback inputs.

Post-complete: if epic ≥ UX-RC, run `.speck/scripts/regenerate-project-readme.sh --epic-validated [E###]`.

## 0. Template

Read `.speck/templates/epic/epic-retro-template.md` before writing.

## 1. Load inputs

Resolve `[EPIC_DIR]`. Load:

```bash
find [EPIC_DIR]/stories/*/story-retro.md
```

**Fallback** (parallel conductor, no story retros): load `validation-report.md`, `audit-report.md`, orchestration ledger per story — extract lessons; do not block completion.

Load epic corpus: `epic.md`, `epic-breakdown.md`, `epic-architecture.md`, `epic-tech-spec.md`.

Consume synthesized story data only — do NOT mine git commits directly (story retro already did).

## 2. Pattern validation

| Count in story retros | Verdict |
|-----------------------|---------|
| ≥2 stories | VALIDATED — promote |
| 1 story | STORY-SPECIFIC — do not promote |

Same rule for gotchas: ≥2 → SYSTEMIC.

Record reusability: High (project) / Medium (epic) / Low (context).

## 3. Aggregate metrics

From story retros: effort variance, velocity, spec accuracy, performance vs targets.

## 4. Apply learnings — project (non-meta)

Find unstarted epics:
```bash
find [PROJECT_DIR]/epics/*/epic.md | xargs grep -l 'Not Started\|In Progress'
```

Validated patterns (≥2): propose updates to future epic specs + `architecture.md` + `patterns-library.md` (create if missing).

Systemic gotchas: propose warnings in future epic specs.

## 5. Apply learnings — Speck (meta)

Process issues in ≥3 stories → propose command/template diffs. Apply only with approval. Document in `epic-retro.md`.

RULE: tags in ≥2 story retros → propose Cursor rule update; apply with approval.

## 6. Update project truth

From validation reports identify what shipped vs planned. Update as needed:
- `architecture.md` — new patterns, deps
- `PRD.md` — delivered capabilities
- `context.md` — new constraints
- `design-system.md` — new components
- `ux-strategy.md` — validated/changed principles

Stamp "Last Updated"; commit with traceability to epic.

## 7. Write epic-retro.md

Fill template: validated patterns, systemic gotchas, aggregates, architecture review, story synthesis, actions taken, meta proposals, escalations to project retro.

## 8. Optional Speck feedback

Ask user: share methodology-only insights to telum-ai/speck?

If yes: filter project-specific content; show preview; confirm:
```bash
gh issue create --repo telum-ai/speck \
  --title '[Feedback] Methodology insights from epic retrospective' \
  --body '…' --label 'feedback,methodology'
```

## NEVER / ALWAYS

- NEVER block on missing story-retro when fallback inputs exist
- NEVER promote 1-story patterns to project-wide without validation
- NEVER apply meta template changes without approval
- NEVER skip project truth update when architecture/features changed
- ALWAYS consume story-retro summaries, not raw git
- ALWAYS validate pattern frequency before promotion
