---
name: project-product-contract
description: Creates product-contract.md. Use for Build/Platform PROMISE core.
paths:
  - "specs/projects/**"
---

# project-product-contract

Intent: author initial contract or refresh during greenfield planning. Validated/shipped contract with deliberate strategic change → `/adjust --level project` (cascade), not silent re-author.
Output: `specs/projects/[PROJECT_ID]/product-contract.md` (template: `.speck/templates/project/product-contract-template.md`).

## 0. Template

Read `.speck/templates/project/product-contract-template.md` before writing.

## 1. Play level and archetype

Read `.speck/project.json` → `play_level`, `project_archetype` (missing archetype → `consumer_product` or infer from stack).

| Play level | Action |
|------------|--------|
| Sprint | STOP — refine `PRD.md`; run `/project-promote` if growing |
| Build / Platform | Proceed |

Locate `specs/projects/[PROJECT_ID]/`. Prereq: `project.md`. Helpful: `ux-strategy.md`, `constitution.md`, `domain-model.md`, `context.md`, active recipe.

## 2. Archetype sections

Adapt template sections per `project_archetype` (see template WHEN/SKIP):

| Archetype | Adapt |
|-----------|-------|
| `infra_service` / `backend_api` | §1 SLA; §2 operational JTBD; §4 invariants scorecard; §5 operational milestones; §6 API taxonomy; §7 banned anti-patterns; skip §8–§10 unless AI/adaptive |
| `consumer_product` / `b2b_saas` / `internal_tool` | Standard human promise, persona, JTBD, magic moments, public/banned copy, trust moments |

## 3. Load inputs (parallel)

Dispatch parallel reads: `project.md`, `ux-strategy.md`, `constitution.md`, `domain-model.md`, `context.md`, active `recipe.yaml`.

## 4. Skeptical review (before draft)

≥3 alternative framings each; lock one with rationale; log to `project-decisions-log.md`:

1. Paid promise (one outcome-focused sentence)
2. Differentiator
3. Primary magic moment

## 5. Draft

Fill template section-by-section from inputs + user Q&A. Key prompts (ask if missing):

| Section | Prompt |
|---------|--------|
| Paid promise | One outcome sentence — not a feature list |
| Differentiator | Still true if competitor copied every feature? |
| Anti-differentiators | Category this product must never become |
| Inspiration | Principle drawn — not implementation copied |
| JTBD scorecard | All five: functional, emotional, social, trust, commercial |
| Magic moments | 3–7 surfaces: trigger, beats, target emotion, LARP validation |
| Public language | Domain term table per locale; voice principles; good/bad samples |
| Banned language | Term, reason, replacement — product-specific, not generic |
| AI contract | Per AI surface: inputs, shape, tone, cite/avoid, bad/good examples |
| Longitudinal axes | If adaptive: signals, variations, overrides, validation chapters |

Refuse vague paid promise — one specific sentence or STOP.

## 6. Validate

Template checklist: clarity (one-sentence promise/differentiator; named anti-diff failure modes); completeness (JTBD 5/5; ≥5 banned terms; AI contract if AI visible; axes if adaptive); linkage to `evidence-contract.md` and downstream refs.

```bash
bash .speck/scripts/validation/validators/validate-product-contract.sh --strict specs/projects/[PROJECT_ID]/product-contract.md
```

`WEDGE_DRIFT.P1` → promote §2a wedge into §3 before locking.

Run `/speck-premise-challenge` on onboarding/first-run and other high-impact contract surfaces.

## 7. Write and stamp

```bash
.speck/scripts/stamp-truth.sh specs/projects/[PROJECT_ID]/product-contract.md
.speck/scripts/stamp-market.sh specs/projects/[PROJECT_ID]/product-contract.md --baseline
```

Never hand-write market stamp — only `stamp-market.sh`. Real verdict later: `/speck-frontier-scan --product`.

## 8. Downstream

1. `/project-state` — regenerate status
2. `.speck/scripts/regenerate-project-readme.sh` — README from paid promise (do not wait for user)

Report: path, section count, banned/magic/AI/axis counts. Next: `/project-evidence-contract` → `/project-plan`.

## NEVER / ALWAYS

- NEVER vague paid promise
- NEVER skip skeptical review on differentiator
- NEVER auto-fill banned language
- NEVER hand-write market stamp
- ALWAYS SHA stamp on write
- ALWAYS log lock decisions
- ALWAYS `/project-state` then README regen on write
