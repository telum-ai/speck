---
name: project-ux
description: UX strategy. Use before plan when Platform / 4+ epic Build.
---

# project-ux

Output: `specs/projects/[PROJECT_ID]/ux-strategy.md` (template: `.speck/templates/project/ux-strategy-template.md`).

## 1. Play level guard

Read `.speck/project.json` → `play_level` (missing = Platform). Count epics: max of `### E###` in `epics.md` and `epics/` dirs.

| Play level | Epics | Action |
|------------|-------|--------|
| Sprint | any | STOP — UX in PRD |
| Build | 1–3 | Optional; content in `product-contract.md` §5/§6/§10. Confirm Y/N; N → `/project-product-contract` |
| Build | 4+ | REQUIRED (composition fallacy gate) |
| Platform | any | REQUIRED |

## 2. Load and mode

Resolve `[PROJECT_ID]`. Load: `project.md`, `domain-model.md` (if exists), `project-landscape-overview.md`.

| Signal | Mode |
|--------|------|
| `[INFERRED FROM CODE]` in `project.md` OR landscape overview | EXTRACT (brownfield) |
| else | CREATE (greenfield) |

## 3. JIT research

Follow `.cursor/skills/just-in-time-research/SKILL.md`:

| Area | Use in strategy |
|------|-----------------|
| User behavior | Persona/journey patterns |
| Accessibility | WCAG/ARIA/contrast |
| UX patterns | App-type best practices |
| Design psychology | Cognitive load, hierarchy, ethics |

Document in **Research Informing This Strategy**.

## 4. EXTRACT (brownfield)

1. Inventory UI from landscape/code paths (`frontend/`, `src/ui/`, etc.)
2. If no UI → switch to CREATE
3. Infer principles from patterns (spacing rhythm, motion, contrast, density)
4. Validate inferences with user
5. Fill gaps: emotional goals, a11y beyond code, brand guidelines
6. Write sections: Existing Patterns, Inferred Principles, Gaps, Recommendations

Extraction note: descriptive (what exists), not prescriptive.

## 5. CREATE (greenfield)

Gap discovery — ask only missing:

| Gap | Question |
|-----|----------|
| Emotional goals | What should users feel? |
| Personality | Formal/casual; playful/serious |
| Visual direction | Brand guidelines or preferences |
| Accessibility | Required compliance level |

Define 3–5 principles with do/don't each. Fill template; mark unknowns `[NEEDS CLARIFICATION]`.

## 6. Write and report

Path, principles summary, personality. Next: follow `AGENTS.md` command phases for play level (typically `/project-context` or contracts/architecture).

## NEVER / ALWAYS

- NEVER skip at Build 4+ / Platform when UI product
- NEVER invent principles without user validation in CREATE mode
- ALWAYS apply research to principles section
- ALWAYS use domain glossary from `domain-model.md` in UX copy guidance
