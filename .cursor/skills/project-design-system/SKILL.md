---
name: project-design-system
description: Defines design tokens, primitives, and component standards. Use for UI Platform or Build needing shared visual rules.
paths:
  - "specs/projects/**"
---

# project-design-system

Output: `specs/projects/[PROJECT_ID]/design-system.md` (optional by play level) + **always** `design-system/primitives.md` (template: `.speck/templates/project/primitives-registry-template.md`).

## 1. Play level guard

Read `.speck/project.json` → `play_level` (missing = Platform).

| Play level | Action |
|------------|--------|
| Sprint | STOP — ship with existing CSS; `/project-promote` to grow |
| Build | Optional full `design-system.md`; **required** live registry `design-system/primitives.md` |
| Platform | Full flow + registry |

**Always** create/update `design-system/primitives.md` from `primitives-registry-template.md`.

## 2. Prerequisites

| Required | If missing |
|----------|------------|
| `ux-strategy.md` | `/project-ux` |
| `architecture.md` | `/project-architecture` |

Load: `project.md`, `ux-strategy.md`, `architecture.md`.

Mode: BROWNFIELD if `project-landscape-overview.md` or UI components in codebase; else GREENFIELD.

## 3. JIT research

Follow `.cursor/skills/just-in-time-research/SKILL.md`: token naming, component patterns, WCAG 2.1 AA, reference design systems. Document in **Research Informing This Design System**.

## 4. BROWNFIELD

1. Scan UI: colors, typography, spacing, radius, shadows, components (grep/list paths from architecture)
2. Consolidate extracted values into token tables (Existing = descriptive)
3. Recommend systematic scale (Recommended = prescriptive); note inconsistencies and a11y gaps
4. Write migration guide: new work uses recommended tokens

Extraction note: Existing = current code; Recommended = target system.

## 5. GREENFIELD

Elicit and generate:

| Layer | Decisions |
|-------|-----------|
| Color | Primary/secondary/neutral/semantic; dark mode |
| Typography | Family; scale xs–6xl; weights, line-height |
| Spacing | 4px or 8px base; component padding standards |
| Shape | Radius scale; shadow scale |
| Components | Primitives, layout, feedback, nav, overlay, data display — needed set + variants |
| Patterns | Forms, loading, empty, error, success; page/section layouts; responsive grid |
| Accessibility | Contrast, focus, keyboard, screen reader, touch targets |

Template: `.speck/templates/project/design-system-template.md` → `design-system.md`.

Optional subdirs: `design-system/components/`, `patterns/`, `examples/`.

## 6. Primitives registry

Always write/update `design-system/primitives.md` — canonical primitive list; prevents inline UI reimplementation drift.

## 7. Report

Path(s), token/component counts, mode. Downstream: `/epic-wireframes`, `/story-ui-spec`, implementation (Storybook optional).

Position: after architecture, before planning.

## NEVER / ALWAYS

- NEVER skip `primitives.md` even when skipping full design-system.md
- NEVER prescribe tokens without checking brownfield extraction first
- ALWAYS document a11y requirements with tokens
- ALWAYS link design-system from epic/story UI specs
