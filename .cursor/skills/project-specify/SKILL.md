---
name: project-specify
description: Creates project.md vision and boundaries. Use when starting after any needed brainstorming or brownfield import.
paths:
  - "specs/projects/**"
---

# project-specify

Template: `.speck/templates/project/project-template.md`.

## 0. Completed project check

If project validated/completed and user wants pivot/redesign → STOP; route `/adjust --level project` (not this skill).

## 1. Template

Read `.speck/templates/project/project-template.md` before writing.

## 2. Archetype + play level

Infer **archetype**: `consumer_product` | `b2b_saas` | `internal_tool` | `infra_service` | `backend_api`. Ask if unclear. Write to `.speck/project.json` → `project_archetype`.

Infer **play level** from signals:

| Level | Signals | Later rigor |
|-------|---------|-------------|
| Sprint | weekend, prototype, ship fast | smallest PROMISE and PROVE set |
| Build | subscription, dashboard, v2 | contracts plus conditional architecture/UX |
| Platform | enterprise, marketplace, shared infrastructure | full project flow |

Sprint/Build branches skip sections marked below.

## 3. Mode

| Indicator | Mode |
|-----------|------|
| `project-import.md` OR `project-landscape-overview.md` | Brownfield |
| Neither | Greenfield |

## 4. Greenfield — recipe (optional)

Scan `.speck/recipes/*/recipe.yaml` `keywords:` vs description. Match → offer recipe; on accept set `_active_recipe:` in `project.md` metadata.

## 5. Greenfield — create

Parse description; ask gaps: product type, users, problem, scale.

Domain expertise required? → note in `project.md`; flag `/project-domain`.

```bash
bash .speck/scripts/bash/create-new-project.sh --json [--project-id "$DECLARED_PROJECT_ID"] "$ARGUMENTS"
```

If `.speck/project.json` already declares `project_id`, pass it as
`--project-id`; never create a second project directory from the brief text.
Omit the flag only when no canonical project ID exists yet.

Fill the minimum sufficient template and set its lifecycle status to `Specified`; delete inapplicable example rows and sections rather than expanding them. Every retained claim must trace to the source or be labeled as an inference. Mark gaps
`[NEEDS CLARIFICATION: …]`. Preserve unresolved choices as questions. Do not
turn them into goals, selected options, or invented comparison candidates.

## 6. Brownfield — pre-fill

Load import + landscape. Pre-fill template:
- `[FROM IMPORT]` — import data
- `[INFERRED FROM CODE]` — scan data
- `[NEEDS VALIDATION]` — uncertain

Ask only strategic gaps (vision, personas, metrics, positioning, hidden constraints). Skip discoverable-from-code questions.

## 7. PROFILE refresh

After `project.md` written:
```bash
bash .speck/scripts/regenerate-project-readme.sh
```
The generated README must describe the specification phase honestly and may
link only to artifacts that exist. Remove no-placeholder or broken-link defects
before leaving this phase. Its overview and one-line vision must add distinct
information rather than repeating the same sentence.

## 8. Next

Re-read the marked canonical flow in root `AGENTS.md` and continue at the first incomplete applicable project slot for the selected play level.

## NEVER / ALWAYS

- NEVER run on validated project for pivots — use `/adjust --level project`
- NEVER skip template read
- NEVER leave generic placeholders unfilled
- ALWAYS write `project_archetype` + `play_level` to `.speck/project.json`
- ALWAYS regenerate README after `project.md`
