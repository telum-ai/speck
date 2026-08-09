# project-architecture — procedure

Input: `$ARGUMENTS` (focus areas, constraints).
Output: `[PROJECT_DIR]/architecture.md`.
Template: `.speck/templates/project/architecture-template.md`.
Prereq: `project.md`, `context.md` (REQUIRED). Runs before `/project-plan`.

## 0. Template

Read `.speck/templates/project/architecture-template.md` before writing.

## 1. Play level

Read `.speck/project.json` → `play_level`.

| Level | Action |
|-------|--------|
| Sprint | STOP — skip formal architecture; `/project-promote` when ready |
| Build | Optional — proceed only if user confirms or tech uncertain |
| Platform | Full flow |

## 2. Load context

- `project.md`, `context.md` (STOP if missing → `/project-context`)
- `constitution.md`, `ux-strategy.md`, `*-research-report-*.md`
- Brownfield: `project-landscape-overview.md`, `project-import.md`
- Recipe: `_active_recipe:` → `.speck/recipes/[name]/recipe.yaml` (`stack`, `architecture`, `patterns`, `external_services`)

**Mode**: landscape exists → brownfield (as-is + to-be); else greenfield.

## 3. JIT research

Follow `.cursor/skills/just-in-time-research/SKILL.md`. Gap areas: stack evaluation, patterns, performance, integration, migration (brownfield).

Deep research needed → PAUSE: `project-architecture-research-prompt-[topic].md` → user saves `project-architecture-research-report-[topic].md` → re-run.

## 4. Brownfield

Extract from landscape: pattern, components, stack, data models, APIs, deployment, debt. Document current state; propose evolution aligned with `context.md` constraints.

## 5. Greenfield

Decide: pattern, deployment targets, quality attributes, frontend/backend/DB/integration choices. Verify against `context.md` (team skills, infra limits).

Recipe active → pre-fill from recipe; ask only gaps.

## 6. Write architecture.md

Fill template. Include: components, stack rationale, data/security/performance/scaling/integration/deployment/ops. ASCII or Mermaid diagrams. Cross-reference epic boundaries and shared components.

Embed research in "Research Informing This Architecture."

## 7. Validation checklist

Supports functional + non-functional reqs; fits constraints; clear epic boundaries; independent epic development; security + scale addressed.

## 8. Next

| Step | Notes |
|------|-------|
| `/project-design-system` | UI-heavy projects |
| `/project-plan` | Consumes architecture.md |
| `/project-validate` | Post-implementation only |

## NEVER / ALWAYS

- NEVER plan Platform without architecture feeding `/project-plan`
- NEVER contradict `context.md` constraints silently
- NEVER skip as-is documentation in brownfield
- ALWAYS read template first
- ALWAYS document trade-offs and evolution path
