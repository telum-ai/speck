# speck-catch-up / rebuild

## Phase 1 — Backfill `product-contract.md`

Read `.speck/templates/project/product-contract-template.md`.

| Section | Sources |
|---------|---------|
| Paid Promise | project.md + PRD.md + pricing*.md |
| Primary Persona | project.md + personas/ |
| Differentiator / Anti-Differentiators | project.md + constitution.md |
| Inspiration / JTBD / Magic Moments | ux-strategy.md + PRD.md + epic-journey.md |
| Public Language / Banned Language | ux-strategy.md + constitution.md |
| AI Behavior Contract | AI epic specs or `(N/A)` |
| Longitudinal Axes | adaptive-axes/ or `(none)` |

Clear answer → fill. Ambiguity → N≥3 alternatives, mark `[NEEDS USER REVIEW]`, add to catch-up plan. Replace every `REPLACE_BEFORE_SHIP:` token. Remove scaffold banner only when content is real. SHA-stamp. Log via `/speck-decision-log`.

## Phase 2 — Backfill `evidence-contract.md`

Active recipe from `.speck/project.json` or `project.md` `_active_recipe`. Read `.speck/recipes/<name>/recipe.yaml` `evidence_contract:` block; walk `extends:` chain and shallow-merge.

No recipe → infer platform from architecture.md; document inference in catch-up plan.

Hybrid stack (e.g. React + Capacitor): find composed recipe first; else splice per-platform sections + P3 row "author composed recipe."

Third-party risk surface (Stripe, Clerk, Firebase, etc.): pull current vendor language from **Context7 / official docs JIT** — not domain pattern skills.

Replace all `REPLACE_BEFORE_SHIP:` tokens. Remove scaffold banner. SHA-stamp.

## Phase 3 — Reconstruct `project-decisions-log.md`

Uncomment canonical catch-up caveat block (remove `<!-- CATCH-UP-ONLY: ... -->` wrapper).

Mine git for: `feat(architecture):`, `docs(design-system):`, `feat(plan):`, `feat(epic-*):`, commits with `ARCH:`/`PATTERN:`/`RULE:` tags.

Per decision → `/speck-decision-log` with `Reconstructed: true`, `sha:`, `date:`, `alternatives:` (≥2 plausible reconstructions), `status: locked`.

## Phase 4 — Epic-level artifacts

For each `epics/E###-*/`:

1. UI epic missing `experience-chain.md`:
   - Default: scaffold `experience-chain-historical.md` from brownfield template; populate shipped screens from story specs + git; `brownfield_exempt: true`.
   - Exception: both `user-journey.md` AND `wireframes.md` exist → generate full `experience-chain.md`.
2. Missing `epic-architecture.md` on cross-cutting epic → note only (optional artifact).
3. Replace all `REPLACE_BEFORE_SHIP:` tokens. SHA-stamp.

## Phase 6 — Regenerate `project-state.md`

Invoke `/project-state`. Reflect post-honesty readiness, blocking issues, `[NEEDS USER REVIEW]` markers, remaining `REPLACE_BEFORE_SHIP:` tokens. Next action: work through catch-up plan.

## Phase 7 — Write `project-catch-up-plan.md`

Prioritized P0–P3 remediation backlog: downgraded stories, magic moments needing LARP, sections awaiting review, REPLACE markers, experience-chain-historical deferred conversions. SHA-stamp.

## NEVER / ALWAYS

- NEVER silently downgrade validation reports without `## Catch-Up Downgrade` section
- NEVER invent magic moments or differentiators — mark `[NEEDS USER REVIEW]`
- NEVER delete v6 artifacts
- NEVER mark story UX-RC+ without checked-in runtime evidence; floor = IMPL-GREEN
- NEVER leave `REPLACE_BEFORE_SHIP:` in "filled" artifacts
- ALWAYS SHA-stamp reconstructed artifacts
- ALWAYS invoke `/speck-decision-log` for reconstruction decisions
- ALWAYS produce `project-catch-up-plan.md` (even if empty/clean)
- ALWAYS auto-detect Phase 5 sub-mode — do not ask user
