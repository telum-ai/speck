# project-state — procedure

Output: `specs/projects/[PROJECT_ID]/project-state.md` (template: `.speck/templates/project/project-state-template.md`). Cap: **200 lines** — refuse write if over; compress first.

Single-page engagement entry: honest staleness, blockers, next action.

## 0. Template

Read `.speck/templates/project/project-state-template.md` before writing.

## 1. Locate project

Walk up from cwd to `specs/projects/[PROJECT_ID]/`. Multiple projects → ask or use `.speck/project.json` `_active_project`.

Missing project → STOP: run `/project-specify` first.

Read `play_level` (missing = Platform).

## 2. Gather facts (parallel)

```
├── List epic/story dirs + readiness from latest validation reports
├── SHA-stamped truth artifacts vs HEAD
├── Latest validation/audit/recheck reports project-wide
├── Open P0/P1 in *-punch-list.md
├── git log --grep='PATTERN:\|GOTCHA:\|PERF:\|ARCH:\|RULE:\|DEBT:' -n 5
└── git rev-parse --short HEAD
```

## 3. Readiness map

Per project/epic/story: latest `validation-report.md` / `epic-validation-report.md` / `project-validation-report.md` → readiness from frontmatter/header; compare report SHA to HEAD → flag stale.

No validation report → `NO-SHIP`.

## 4. Truth staleness

For each truth artifact (`project.md`, `PRD.md`, `architecture.md`, `context.md`, `design-system.md`, `ux-strategy.md`, `domain-model.md`, `product-contract.md`, `evidence-contract.md`, `constitution.md`):

| Condition | Flag |
|-----------|------|
| No SHA stamp | No stamp — proposal |
| SHA ≠ HEAD | Drift |
| `verified` >14 days ago | Stale |
| else | Fresh |

## 5. Blockers and questions

Blockers from: audit P0/P1; validation FAIL blockers; `/recheck` drift blockers; punch-list P0/P1. Rank P0→P3 by severity and recency.

Open questions: `project-decisions-log.md` OPEN entries; `[NEEDS CLARIFICATION]` in active specs; "awaiting human" in recent audits.

## 6. Next action (decision tree)

1. P0 blocker → resolve P0 (name target)
2. Any drift → `/recheck`
3. Story `[Implemented]` without audit → `/audit`
4. Story `[Audited]` without validate → `/story-validate`
5. Epic `[Stories Complete]` without epic validate → `/epic-validate`
6. Story `[Tasked]` without implement → `/story-implement`
7. Draft placeholder stories in breakdown → `/story-specify`
8. else → surface options to user

Write: specific command + target, 1–2 sentence rationale, what blocks proceeding.

## 7. Active context

- `git branch --show-current`
- `git diff --name-only` since last validation SHA
- Active epic/story = most recent unvalidated `epic.md` / `spec.md` mtime

## 8. Render

Fill every template section. Footer:

```
*[as of SHA `<short>` | generated `<iso>` | speck vX.Y.Z]*
```

Line count ≤200 or compress and retry.

## 9. Concurrency guard (pre-write)

```bash
BRANCH=$(git branch --show-current)
```

| Branch | Action |
|--------|--------|
| `main` / `master` | Write + README regen |
| `epic/e*` / `epic/E*` | **Skip write** — print deferred message; still report next action/drift/blockers; skip README; STOP |

## 10. Write (main only)

Overwrite `project-state.md`. Then:

```bash
.speck/scripts/regenerate-project-readme.sh
```

Report: path, line count, fresh/stale/drift counts, blockers, open questions, next action.

## Triggers (auto-invoke)

`story-validate` PASS; `epic-validate` any verdict; `project-validate` any verdict; `/recheck`; missing state; state SHA >5 commits behind HEAD.

Other skills must not write `project-state.md` directly — invoke this skill.

## NEVER / ALWAYS

- NEVER overwrite on `epic/*` concurrent branches
- NEVER write >200 lines
- NEVER hallucinate readiness — only from validation reports
- NEVER claim fresh without SHA check
- ALWAYS SHA footer
- ALWAYS concrete next action over "review project"
- ALWAYS surface drift
