---
name: project-domain
description: Models domain terms, rules, and invariants. Use after project-clarify before foundation work for specialized domains.
paths:
  - "specs/projects/**"
---

# project-domain

Output: `specs/projects/[PROJECT_ID]/domain-model.md` (template: `.speck/templates/project/domain-model-template.md`).

## 1. Play level guard

Read `.speck/project.json` → `play_level` (missing = Platform).

| Play level | Action |
|------------|--------|
| Sprint | STOP — terms inline in PRD |
| Build | WARN — terms live in `product-contract.md` §6/§8; standalone only for substantial rules/invariants. Confirm Y/N; N → `/project-product-contract` |
| Platform | Proceed |

## 2. Load corpus

`PROJECT_DIR=specs/projects/[PROJECT_ID]`

| File | Role |
|------|------|
| `project.md` | Required — vision, domain type |
| `domain-model.md` | Update mode if exists |
| `project-import.md`, `project-landscape-overview.md` | Brownfield hints |

Mode: UPDATE if `domain-model.md` exists; else CREATE.

## 3. JIT research

Follow `.cursor/skills/just-in-time-research/SKILL.md`. Priority: Perplexity MCP → web search → user SME.

| Area | Output section |
|------|----------------|
| Terminology | Glossary with sources |
| Principles | Foundational rules with evidence |
| Rules/constraints | Invariants, safety, regulatory |
| Entities | Core concepts, relationships |

Embed citations in artifact — do not separate research doc.

## 4. Elicit (ask gaps only)

1. Domain field and why expertise matters
2. Canonical terms — definition; synonyms to avoid
3. Core entities — attributes, relationships
4. Invariants — rules that must always hold
5. Principles — scientific/industry guidance for product
6. Constraints — impossible, unsafe, inadvisable; regulatory boundaries

Brownfield: extract terms from code/UI/validation logic; document as-is before changes.

## 5. Write

Fill `domain-model-template.md`. Merge user input + research.

Quality gate before write:

| Check | Requirement |
|-------|-------------|
| Completeness | Glossary; entities+relations; invariants; ≥2 principles with sources; constraints |
| Consistency | Matches `project.md`; no conflicting rules; bidirectional relations |
| Actionability | Code-valid identifiers; testable rules; clear guidance |

## 6. Report

Counts: terms, entities, invariants, principles, constraints. Downstream: `/project-plan`, `/epic-specify`, `/story-specify`, `/story-plan`, `/story-validate`.

Skip entirely if: generic CRUD; purely technical domain; external doc linked instead.

## NEVER / ALWAYS

- NEVER invent domain terms without user or sourced research
- NEVER skip invariants when safety/regulatory domain
- ALWAYS cite external domain claims
- ALWAYS reconcile terminology with `product-contract.md` public language when both exist
