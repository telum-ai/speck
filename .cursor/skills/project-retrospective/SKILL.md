---
name: project-retrospective
description: Project retro after validate. Use when closing project phase.
paths:
  - "specs/projects/**"
---

# project-retrospective

Prereq: major milestone; most/all epics complete; each epic has `epic-retro.md` (`/epic-retrospective`).
Output: `specs/projects/[PROJECT_ID]/project-retro.md` (template: `.speck/templates/project/project-retro-template.md`).

Reads **epic-retro.md only** — not `story-retro.md` (already synthesized upstream).

## 0. Template

Read `.speck/templates/project/project-retro-template.md` before writing. Note required sections; continue.

## 1. Load corpus (parallel)

```
├── All epics/*/epic-retro.md
├── project.md, PRD.md, architecture.md
├── context.md, design-system.md, ux-strategy.md, epics.md
└── Optional: git log --all --grep='PATTERN:\|GOTCHA:\|PERF:\|ARCH:\|RULE:\|DEBT:'
```

Resolve `[PROJECT_ID]` from cwd or ask.

Verify project truth docs updated after each epic — stale → update before retro completes.

Metrics from epic retros: story count, effort, velocity trend, goals achieved.

## 2. Cross-epic patterns

For each pattern in epic retros:

| Frequency | Classification | Action |
|-----------|----------------|--------|
| ≥2 epics | Project-wide | Mark validated; propose Speck pattern library if cross-project |
| 1 epic | Epic-specific | Already in epic retro |

Dispatch parallel reviewers (`speck-auditor`) for: cross-epic patterns, systemic gotchas, methodology gaps, effort trends. Synthesize — do not share findings between reviewers before synthesis.

## 3. Cross-epic gotchas

| Frequency | Classification | Action |
|-----------|----------------|--------|
| ≥2 epics | Project-wide issue | Process fix: methodology update OR technology gotcha doc |
| 1 epic | Epic-specific | Documented in epic retro |

## 4. Methodology effectiveness

Rate phases (High/Med/Low + time + would-repeat):

| Phase | Assess |
|-------|--------|
| Foundation | ux, context, constitution → PRD quality |
| Planning | PRD accuracy, epic boundaries, estimates |
| Architecture | tech choices, scale predictions |
| Implementation | spec quality, tasks, validation catch rate |
| Truth management | docs updated per epic; drift; onboarding value |

Truth alignment check: project.md, architecture.md, PRD.md reflect current system? Partial → update docs before finishing retro.

## 5. Command and rules usage

Table: command, times used, value 1–5, issues. List skipped commands + rationale. Log flow deviations + whether flow should change.

Cursor rules: which caught issues; which ignored; created mid-project; need updates.

## 6. Strategic review (interactive)

Vision alignment; process value/overhead; knowledge capture (patterns documented vs tacit); methodology evolution (templates, missing gates).

## 7. Write report

Fill template from epic retros + project truth + optional commit tags.

## 8. Approved actions (user consent)

May update: README flow, templates, skills, cursor rules — only after approval.

## 9. Optional Speck feedback

Ask opt-in to file methodology-only GitHub issue (no project-specific details):

```bash
gh issue create \
  --repo telum-ai/speck \
  --title "[Feedback] Methodology insights from project retrospective" \
  --body "[filtered content]" \
  --label "feedback,methodology"
```

Filter: no project name, domain, features, velocity metrics. Include: command assessments, template gaps, flow improvements.

See `.speck/TEMPLATE-FEEDBACK.md`.

## Report

Goals/epics/stories/duration; patterns/gotchas/rules captured; methodology insights; top practices and gotchas for next project. Path to `project-retro.md`.

## NEVER / ALWAYS

- NEVER read story-retro.md as primary signal
- NEVER include project secrets in Speck feedback issue
- ALWAYS verify epic retros exist before synthesizing
- ALWAYS update stale project truth before closing retro
- ALWAYS get user approval before repo/methodology edits
