---
name: project-context
description: Constraints/compliance/team context. Use before plan.
paths:
  - "specs/projects/**"
---

# project-context

Output: `specs/projects/[PROJECT_ID]/context.md` (template: `.speck/templates/project/context-template.md`).

## 0. Template

Read `.speck/templates/project/context-template.md` before writing.

## 1. Project and mode

Resolve `[PROJECT_ID]` from args or ask. Set `PROJECT_DIR=specs/projects/[PROJECT_ID]`.

| Signal | Mode |
|--------|------|
| `project-landscape-overview.md` exists | BROWNFIELD — extract from scan |
| else | GREENFIELD — interactive |

Update mode: load existing `context.md`; change only requested sections; document why.

## 2. Recipe (greenfield)

If `project.md` has `_active_recipe:` → load `.speck/recipes/[name]/recipe.yaml` `context:` section as seed (technical, development, quality). Ask only gaps.

## 3. JIT research

Follow `.cursor/skills/just-in-time-research/SKILL.md`. Gap areas:

| Area | Decide |
|------|--------|
| Industry standards | ISO/regulations for domain |
| Technology constraints | Stack limits, compatibility |
| Compliance | GDPR/HIPAA/SOC2/PCI as applicable |
| Best practices | Testing, security, org standards |

Document findings in template **Research Informing This Context** section.

## 4. BROWNFIELD

Prereq: `project-landscape-overview.md` (else STOP → `/speck-scan --level project`).

1. Extract from scan: stack, architecture, integrations, quality metrics, components
2. Pre-fill: Technology Constraints, Development Standards
3. Ask only non-inferable: team size/expertise, timeline/budget, stack rationale, hard constraints, planned migrations
4. Add extraction note: current state, not necessarily future direction

## 5. GREENFIELD

Elicit progressively (skip if recipe covers):

**Technical** — required tech/integrations; browser/device; platform; legacy compatibility
**Development** — team size/expertise; timeline; budget; timezone distribution
**Standards** — style guide/linter; test coverage; docs; git workflow; review; CI/CD
**Compliance** — WCAG level; privacy regs; industry standards; audit needs
**Operational** — latency targets; concurrency; data volume; auth/authz; uptime SLA; DR
**Project constraints** — deadlines; budget; integration/legacy limits

## 6. Write

Fill template. Populate **Research Informing This Context**. Include inheritance rules (how constraints flow to epics/stories).

Pre-write checklist: all constraint sections filled; compliance explicit; performance/security targets set; flexible vs fixed marked.

```bash
bash .speck/scripts/bash/get-context.sh --project [PROJECT_ID]
```

## 7. Report

Path, mode, sections updated. Next by play level: `/project-constitution` (complex/regulated) or `/project-plan` (uses constraints in PRD).

## NEVER / ALWAYS

- NEVER brownfield without scan artifact
- NEVER skip compliance when regulated domain indicated
- NEVER leave conflicting requirements unresolved — surface trade-off
- ALWAYS fill research section when JIT ran
- ALWAYS preserve unchanged sections on update
