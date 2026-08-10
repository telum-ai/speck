<!-- SPECK:START -->

# Speck — Promise → Build → Prove (→ Drive)

Evidence-driven methodology. Discipline is unconditional.
Thesis: you cannot out-enumerate an agent optimizing for green. Gates follow P1–P4. Find what is wrong; do not confirm the claim. `docs/v8/v8-north-star.md`
Witness graph proves traceable·complete·fresh — never faithful·good·excellent. `docs/v9/v9-north-star.md`
v11 subtraction + JIT + meta-methodology: `docs/v11/v11-north-star.md`

## Mental model

PROMISE (contract) → BUILD (work) → PROVE (truth) → PROFILE (public face). Drift feeds back.
Centers: product-contract · spec/tasks/experience-chain · project-state/evidence-contract · README.

## Four principles

- P1 Evaluation over verification. Un-adjudicated evidence = surrogate proof. LARP = DOES-IT-WORK + IS-IT-GOOD.
- P2 No claim without a mechanism. No mechanism = automatic fail.
- P3 Can't-reach is a finding, not an excuse. Named blocker needs logged reproduced attempt.
- P4 Adversary is structural. Separately-incentivized evaluator; probe lists prompt imagination, never define done.

## Drive to done

User runs native `/goal`. Each turn: print `speck_graph.py check` + `gap` stdout; terminate on literal `SPECK-GAP: none`. Route top gap:

| gap | route |
|-----|-------|
| untraced/undischarged/phantom promise | story-specify → plan → tasks → implement → audit → story-validate |
| audit P0/P1 | harden |
| uncovered FELT / unjudged MM | larp |
| forks-open TASTE · contract pivot · price · deploy | STOP-BLOCKED owner decision |
| stale graph | speck_graph.py build |

## First actions (stop at first hit)

0. `.speck/.v9-graph-needed` → `/speck-graph-up`. Else `speck_graph.py build` + `check`. Hard `.P1` blocks; repair first. `GRAPH_CAP` caps claims. python3 absent → WARN + proceed.
1. `.speck/.v8-reprove-needed` → `/speck-reprove`. Cap INTEGRATION-GREEN; FELT uncovered until re-earned.
2. `.speck/.migration-needs-catchup` OR `<!-- v7 MIGRATION SCAFFOLD -->` in truth docs → `/speck-catch-up`.
3. Read `specs/projects/<id>/project-state.md` if present.
4. Play level from `.speck/project.json` (`play_level`; missing = platform).
5. Engagement gap (missing/stale>2w/`< speck 8`/new agent) → `/recheck`.
6. Then user request.

## Play levels

| Level | PROMISE | PROVE |
|-------|---------|-------|
| Sprint | PRD + sprint-log | LARP at validate |
| Build | product/context/evidence contracts; arch+ux+analyze required at 4+ epics | LARP + audit + decisions + readiness |
| Platform | full flow | full PROVE; analyze after plan (7 lenses) |

Build 4+ / Platform: `/analyze --level project` required before `/epic-specify` (`check-epic-prereqs.sh`). Grandfather marker `.analysis-gate-grandfathered` is advisory-only until report exists then spend it.

## Readiness

Axes (non-collapsible): CORRECT · ON-CONTRACT · FELT-GOOD · TASTE.
States: NO-SHIP · IMPL-GREEN · INTEGRATION-GREEN · UX-RC/API-RC · COMMERCIAL-RC · SHIP-RC · SHIP.
Never substitute axes. Never claim SHIP-RC from dev-server evidence.

## Always-on discipline

P1–P4 always. Decision-log at phase boundaries. Skeptical-review before non-trivial locks. `/audit` between implement and validate. Verify-skills before accepting delegated results. Runtime LARP for UI validate. SHA-stamp truth. Banned-language lint. Promise conservation via traceability + graph. Value-defensibility before price. Market-claim recheck before COMMERCIAL-RC. PROFILE drift check on recheck.

## Specs routing

Never invent filenames under `specs/`. Canonical homes: `.speck/reference/canonical-routing.md`. Read on write.

## Command order

What/order only — how is in skills. Flows: `.speck/reference/command-phases.md`. Parallel epics: `.speck/patterns/learned/process/parallel-epic-execution.md`.

Sprint: project-specify → ship → promote?
Build: specify → clarify → product-contract → readme → evidence-contract → context → [architecture] → plan → [analyze req 4+] → epic loop → story loop (specify…implement→audit→validate→larp) → epic/project validate.
Post-completion triage: defect→harden; deliberate redesign/pivot→adjust (blast-radius first); new scope→specify; time gap→recheck; play outgrowth→promote.

## Skills

User-only: lifecycle entrypoints `/speck` `/story` `/epic`, convenience routers `/validate` `/retrospective`, and compatibility aliases. Policy: `.speck/reference/skill-catalog-policy.json`.
Auto skills expose one canonical entry per overlapping intent family: `/analyze`, `/adjust`, `/speck-scan`; validation/retrospective stay level-specific. Read SKILL.md; follow load-DAG receipts (ADR-0005/0006/0007).
Vendor APIs: Context7 / official docs JIT. Stack start: `.speck/recipes/`.
Hosts/MCP/model tiers: `.speck/reference/host-capabilities.md`.

## NEVER

Skip project-state / engagement recheck. Pass validate without checked-in evidence. Dev screenshots as launch proof. Non-canonical `specs/` names. Skip `/audit` before validate. Accept delegated self-report without skill-invocation proof. Conflate axes. Launder taste/premise misses as uncatchable. Cap on named blocker without logged attempt. Hand-edit witness.json.

## ALWAYS

First-actions ladder. Read SKILL + template. Stamp truth. ≥3 alternatives at decisions. LARP UI at validate. Analyze when required. Declare readiness state. Log decisions. Enumerate promises into matrix. FELT via naive-hostile LARP.

## When user says

| Say | Do |
|-----|-----|
| /speck … | Read `.cursor/skills/speck/SKILL.md` |
| Build feature | Route to `*-specify`; never skip to implement |
| Is this done? | larp + audit; declare readiness with evidence |
| Status / continue | project-state Next action |
| Parallel epics | wave safety → worktrees → `/epic` |
| Fix bug in validated work | harden |
| Redesign validated | `/adjust` (classify blast radius first) |
| Contract pivot | `/adjust --level project` + cascade |

## Evolution (anti-bloat)

1. Classify: spine | always-on-contract | skill-catalog | jit | delete
2. Prefer JIT
3. Catalog needs ≤120-char description + budget room
4. ADR in `docs/decisions/` (+ A1-lite for gates)
5. `validate-corpus-budget` must stay green
Detail: `.speck/reference/methodology-evolution.md`

## More

`.speck/README.md` · `.cursor/skills/` · `.speck/templates/` · `.speck/recipes/` · `docs/v11/v11-north-star.md`

**Speck Version**: 11.0.0
**Methodology**: Promise → Build → Prove

<!-- SPECK:END -->
