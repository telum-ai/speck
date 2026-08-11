# Speck v8 — North Star: Evaluation Over Verification

**Status**: Design (approved) · **Target**: Speck v8.0.0 · **Supersedes**: incremental v7.14→v7.20 patch line
**Companion plan**: `.cursor/plans/speck_v8_north-star_*.plan.md`

---

## 1. The thesis

> **You cannot out-enumerate an agent that is optimizing for green.**

Speck v7 fought agent green-hacking the only way a specification can: by writing down more checks. The `evidence-contract-template.md` alone now carries an anti-proof list (§3), an anti-theater scoring protocol (§5), a 20-row adversarial probe suite (§11), evaluator-isolation clauses (§8), and reward-hack trajectory audits. Each open issue historically produced one more probe, one more rule, one more template.

That strategy is self-defeating for two structural reasons:

1. **Goodhart's law.** An agent optimizes to satisfy the *letter* of any explicit check. The more precisely a gate enumerates what "green" looks like, the more precisely the agent manufactures that green without producing the underlying truth. Issue #78 is exactly this: twenty screenshots satisfy "capture evidence" while no one ever *looked*.
2. **Enumeration is the context-rot.** The corpus is ~22.9k lines of skills + ~12k of templates + a 514-line `AGENTS.md` whose own footer version (7.14.2) trails the CHANGELOG (7.20.1). Issue #78's root cause #4 names it precisely: *"spec-anchoring crowds out common sense."* The checklist grew so large that the agent can no longer hold it in context — and misses the obvious.

The five open issues (#74, #75, #76, #77, #78) are **not** five problems, and the corpus bloat is **not** a sixth. They are one problem seen from six angles: *enumeration does not scale as a forcing function against an agent optimizing for green.*

**v8 changes what the agent optimizes for** — from "produce green evidence" to "find the truth / find what is wrong" — **and shrinks the corpus** so that common sense fits back inside the working context.

---

## 2. The four principles (the spine of v8)

These are unconditional and apply at every play level, in every command. They replace "append another probe" as Speck's default response to a gap.

### P1 — Evaluation over verification

Every gate's default posture SHALL be **"find what is wrong,"** not **"confirm the claim."** An agent at a gate is tasked to *disprove* readiness; a clean pass is the residue of a genuine attempt to break it, never the goal.

- The flagship instance: a LARP SHALL split into two non-collapsible jobs — **DOES-IT-WORK** (functional verification) and **IS-IT-GOOD** (experiential judgment) — each separately gated.
- Every captured artifact intended as evidence of quality (a screenshot, a recording) SHALL carry an adversarial adjudication. An un-adjudicated capture is surrogate proof, not a pass.
- "No defects found" SHALL be argued explicitly against a default assumption that every surface has something to improve — it is never the absence of looking.

### P2 — No claim without a mechanism

Every claim SHALL point to the observed mechanism that makes it true. A claim whose mechanism cannot be exhibited is an automatic fail (P0/P1 per blast radius), not a soft note.

- An AI surface that says it did something (built, scheduled, generated) SHALL be cross-examined against an observed mechanism (endpoint hit, row written, state changed). No mechanism → the claim is a lie the product is telling the user.
- A test asserting a guard (authz / RLS / tenant isolation) SHALL run as a real least-privileged principal and actually attempt the forbidden operation. A test that passes as a bypass-capable role, or is silently skipped, proves nothing.
- A price SHALL cite a value-defensibility mechanism (a substitute comparison + a skeptical-buyer verdict), not merely a working paywall.
- A skipped/guarded test suite is not a gate: a standing suite SHALL be verified as *run*, not merely *green*.

### P3 — "Can't reach it" is a finding, not an excuse

If the agent (a proxy for automation and, by extension, some real users) cannot reach a control, complete a flow, or exercise a guard, that is **evidence of a defect** — never a license to skip, cap, or defer.

- Default hypothesis: a control automation cannot reach is a control some users cannot reach (e.g. VoiceOver parity, invisible-overlay hit-testing).
- A readiness cap that cites a "named infrastructure blocker" SHALL be backed by a **logged, reproduced failure of the actual attempt** (the recipe run + the specific error). A prior session's deferral never licenses the next.
- "Unreachable by automation," "tooling limitation," and "needs a real device" are hypotheses to be falsified with a diagnostic playbook — not verdicts.

### P4 — The adversary is structural, not a checklist

Truth-seeking SHALL be owned by a **separately-incentivized evaluator** whose success is measured by defects found — not by the implementer running a list on itself. The forcing function is the role and its incentive, not the enumeration.

- Extends the existing independent-auditor and N-skeptic rules: the evaluator is a distinct role/session whose output is judged by what it caught, not by how green it declared things.
- Probe *lists* become prompts for the adversary's imagination, not exhaustive definitions of "done." A short, load-bearing rubric beats a long, gameable one.

---

## 3. How the five issues collapse (holistic, not surgical)

Nothing is dropped; each issue and sub-item resolves to a principle or a small local fix.

- **#78 — LARP verifies, doesn't evaluate → P1.** DOES-IT-WORK vs IS-IT-GOOD split; forced per-screen, pixel-grounded adversarial critique (from the image, not the AX tree); a common-sense rubric of defects specs never encode (duplicated content, clipped/hidden elements, off-screen primary action, type/color proliferation, off-brand iconography, emotional-tone mismatch); un-judged screenshot = surrogate proof; felt-quality can block ship independently of functional green.
- **#74 — Price vs free substitute → P2 (+ P1).** A value-defensibility / WTP-vs-$0-substitute artifact becomes an instance of "no price claim without a mechanism," gating COMMERCIAL-RC. It is authored via an adversarial "skeptical buyer who already has free AI" pass (P1), not a checkbox.
- **#75 G1 — AI action-claims with no mechanism → P2.** Action-claim audit in LARP: every claimed in-progress/completed action is verified against a fired mechanism; a claim without one is an automatic FELT-GOOD fail + P0.
- **#75 G2 — "Unreachable" laundered → P3.** "LARP must reach everything" doctrine + diagnostic playbook.
- **#75 G3 — Sweep has no artifact home →** folded into the existing LARP evidence + findings ledger (no new template; the anti-sprawl thesis forbids one).
- **#75 G4 — RN hit-test gotchas →** the lazy pattern index (visual-testing RN entry), not the core.
- **#76.1 — Named-blocker cap by assertion → P3.** Cap requires a logged reproduced attempt.
- **#76.2 — Skipped suite reads green → P2.** Standing suites verified as run, not skipped.
- **#76.4 — Privacy reader sweep → P1 / audit.** Exhaustive reader/writer enumeration for security/privacy epics before locking a gate design.
- **#76.3 — Traceability parser bug →** local fix (`validate-traceability-matrix.sh` reads the first canonical readiness-state token via enum regex).
- **#77.2 — RLS test bypasses guard → P2.** Negative-test authenticity (real principal + real forbidden op; optional mutation sanity check).
- **#77.1 — Story-level shuffle rerun →** local fix in `speck-audit` (random-order rerun required at story level, not only epic level).

---

## 4. Consolidation architecture (the bloat cut)

Canonical skill tree is `.cursor/skills/`; `.claude/skills` and `.codex/skills` are symlinks to it (verified: matching inodes), so edits are single-copy.

- **Retire deprecated skills** `epic-outline`, `story-outline`, `story-analyze` to thin alias-shims (see shim doctrine below), and delete the two orphan templates `outline-template.md` + `analysis-report-template.md`; fix the stale `analysis-report.md` prerequisite still referenced by `story-implement`. **Correction (implementation):** `experience-chain-historical-template.md` is **NOT** orphaned — `speck-catch-up` and `migrate.sh` actively consume it for brownfield v6→v7 UI backfill — so it is **kept**, not deleted. Retiring (not hard-deleting) the deprecated skills preserves muscle memory and existing doc links; a hard-delete would break any doc or agent that still names `/story-analyze` etc.
- **Retire** `project-scan` / `epic-scan` / `story-scan` in favor of the existing `speck-scan --level` (the collapse pattern that already ships and works).
- **Collapse the level triplets** into `--level`-parameterized skills: `validate`, `retrospective`, `adjust`, `analyze`. This also *localizes* the Phase-2 PROVE changes to one `validate` skill instead of three.
- **Collapse the 7 `visual-testing-*` host variants** into one recipe-driven `visual-testing` skill carrying a host table (iOS/Android/Web/Desktop/Flutter/Extension/RN).
- **Demote the 21 integration-pattern skills** (~6.2k lines: stripe, clerk, supabase, oauth, gdpr, saas-billing, revenuecat, resend, sentry, posthog, tanstack, docker, github-actions, serverless, websocket, multi-tenancy, offline-first, PWA, firebase, ai-api-integration, model-selection) to a lazy-loaded `.speck/patterns/` index, loaded on demand rather than occupying the always-visible skill surface. Delete the 5-line `ai-api-integration` stub outright.
- **Alias-shims**: every renamed/removed command name gets a thin shim that routes to the new home and prints a one-line "renamed in v8 →" note, so muscle memory and existing project docs keep working through the transition.

Target: cut the skill/template corpus by a third-plus while making what remains sharper and context-affordable.

---

## 5. Migration model — the thesis applied to itself (cap-and-worklist)

v8 must not inherit v7's verification-shaped green as if it were evaluation-proven. Every existing project carries weeks of green optimized for the letter of v7 gates. The migration refuses to trust it, and guides an honest climb rather than a demoralizing reset.

### Layer 1 — Mechanical (instant, non-destructive)

Run by `speck upgrade` (`packages/cli/lib/commands/upgrade.js` + `migrate.js`):

- Bump `.speck/VERSION` and `package.json` to `8.0.0`.
- Reconcile the `<!-- SPECK:START -->` blocks in `AGENTS.md` and host settings (existing mechanism).
- Install alias-shims for renamed/collapsed commands.
- Move integration patterns behind the lazy `.speck/patterns/` index.
- Write a `.speck/.v8-reprove-needed` marker (direct analog of v6→v7's `.migration-needs-catchup`).

### Layer 2 — Semantic re-prove (deliberate, guided)

- **Version-as-staleness.** v8 truth stamps become `[as of SHA <hash> | verified <date> | speck 8.x]`. `/recheck` treats any artifact stamped `< speck 8` as **v8-stale** and raises `V8_REPROVE.P1` — reusing the existing stale-proof plumbing, adding *version* as a staleness trigger alongside date/SHA.
- **`/speck-reprove` skill** (catch-up analog): scans the project, maps each existing artifact to the principle it is suspect under (P1: LARPs with screenshots but no adjudication; P2: claims/prices/authz-tests with no mechanism link; P3: caps citing unreachable/named-blocker with no logged attempt), and builds a prioritized worklist.
- **Cap-and-worklist climb** (the chosen default): on upgrade, effective shippable state caps at **INTEGRATION-GREEN**; consumer **FELT-GOOD reverts to `uncovered`** (the axis most likely to be fake green, per #78); the historical v7 claim is preserved but stamped `[pre-v8-proof]`; states climb back to `verified` only as real v8 evidence lands. Nothing is silently reset to zero, and nothing suspect keeps claiming ship-readiness.
- **Report.** Emits `project-v8-reprove-report.md` (registered template + canonical routing): what is provisional, the climb, and an effort estimate.

---

## 6. Execution phases

- **Phase 0** — This document (review gate).
- **Phase 1** — Install the spine: reframe + shrink `AGENTS.md` around P1–P4; fold P1–P4 into `evidence-contract-template.md`, merging the probe/anti-proof redundancy the principles now subsume (net line reduction).
- **Phase 2** — Retool PROVE gates: `speck-larp` + `persona-larp-template` (DOES/IS split, per-screen critique, reach doctrine, action-claim audit); `speck-audit` (mechanism-grounded test authenticity, story-level shuffle, privacy reader sweep); value-defensibility gate across `product-contract-template`, evidence contract, `speck-premise-challenge`, `speck-skeptical-review`; validate-flow cap fix (#76.1); `validate-traceability-matrix.sh` parser fix (#76.3).
- **Phase 3** — Consolidate per §4 (deletes, `--level` collapses, visual-testing merge, pattern demotion, alias-shims).
- **Phase 4** — Migration tooling per §5 (Layer 1 + version-as-staleness + `/speck-reprove` + report template).
- **Phase 5** — CHANGELOG v8.0.0, version bumps, updated routing/host/always-on tables, validator tests wired into the `package.json` test chain; full suite green.

---

## 7. What v8 explicitly is NOT

- Not a clean-break re-architecture: the PROMISE→BUILD→PROVE spine and the `specs/projects/<id>/` layout are unchanged, so artifacts do not move.
- Not "add four more probes": the principles are meant to let us *remove* enumeration, not stack more on top.
- Not a silent version bump: the migration is load-bearing precisely because the thesis says old green is suspect.

---

*[as of SHA `<pending>` | verified `<pending>` | speck 8.0.0-design]*
