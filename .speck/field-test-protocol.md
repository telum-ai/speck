---
speck_version: 7.0
artifact_type: field-test-protocol
purpose: "Validate v7 against v6 baselines on a real product end-to-end"
---

# Speck v7 Field-Test Protocol

This is the **only remaining v7 launch task** that requires real-world execution — it cannot be done in a single tooling session. This document is the playbook the next product build follows so v7 is held accountable against the six v6 baselines.

## What we're measuring

The six v6 retrospectives revealed seven recurring failure modes:

| Failure mode | v6 frequency | What v7 changed |
|--------------|--------------|------------------|
| Surrogate proof (browser screenshot for native iOS app) | 6/6 | `evidence-contract.md` per-platform `invalid_proof_sources` |
| "Tests pass therefore ready" | 5/6 | Readiness state taxonomy (`IMPL-GREEN ≠ SHIP`) |
| Spec drift / stale truth | 6/6 | SHA stamping + `staleness-check.sh` + `/recheck` |
| Composition fallacy (each story passes, product doesn't work) | 4/6 | `experience-chain.md` + JTBD walkthrough at epic-validate |
| Premature commitment / no alternatives surfaced | 5/6 | `skeptical-review` primitive + `project-decisions-log.md` |
| Implementer self-grading (no adversarial check) | 6/6 | `/audit` between implement and validate |
| Banned-language drift (generic AI cheerleading) | 4/6 | `banned-language-lint.sh` + product-contract Section 7 |

## Protocol

### Phase 1: Pick the field-test product

Criteria for the test product:

- [ ] Real intent to ship (not a throwaway demo)
- [ ] Non-trivial scope (Build play level, 1-3 epics minimum)
- [ ] At least one Magic Moment that has to feel a particular way
- [ ] At least one paid surface (paywall, license, subscription) — exercises `COMMERCIAL-RC`
- [ ] Cross-platform if possible (web + native) — exercises invalid_proof_sources
- [ ] An adversarial probe surface (user-generated content, file upload, auth, etc.)

Record: product name, complexity level, play level, target platforms, recipe used.

### Phase 2: Run v7 end-to-end

Follow the v7 Build flow strictly. **No shortcuts**.

```
/project-specify  →  /project-clarify  →  /project-product-contract
  →  /project-evidence-contract  →  /project-context  →  [/project-architecture]
  →  /project-plan  →  per epic /epic-specify → /epic-clarify
    → [/epic-architecture] → [/epic-experience-chain if UI]
    → /epic-plan → /epic-breakdown
  →  per story  /story-specify → /story-clarify → /story-plan → /story-tasks
    → /story-implement → /audit → /story-validate → /larp → /story-retrospective
  →  /audit (epic) → /epic-validate → /larp (JTBD) → /epic-retrospective
  →  /project-validate → /project-retrospective
```

**Discipline checkpoints** (all must pass at each gate):

| Gate | Check |
|------|-------|
| Every phase boundary | `project-decisions-log.md` updated? |
| Every non-trivial proposal | `skeptical-review` performed (N≥3 alternatives)? |
| Every commit | `banned-language-lint.sh` clean? |
| Every truth artifact write | SHA stamp footer present and current? |
| Every implement → validate transition | `/audit` ran, no P0 findings open? |
| Every UI validate | `/larp` ran on the **packaged build** (not dev server)? |
| Every readiness claim | Gate criteria from `evidence-contract.md` met? |

### Phase 3: Track field-test metrics

Open a tracking sheet (`specs/projects/<id>/v7-field-test-metrics.md`) and record:

#### Process metrics

| Metric | v6 baseline | v7 target | Actual |
|--------|--------------|-----------|--------|
| Days from `/project-specify` to first PR | (median 5d in v6) | <5d | _record_ |
| Days from first PR to `IMPL-GREEN` | (varies) | n/a | _record_ |
| Days from `IMPL-GREEN` to `UX-RC` | (often skipped in v6) | <3d | _record_ |
| Days from `UX-RC` to `SHIP-RC` | (often blurred in v6) | varies | _record_ |
| % of phase boundaries with decision log entry | (~10% in v6) | 100% | _record_ |
| % of validate gates with `/audit` report present | (0% in v6) | 100% | _record_ |
| % of UI validate gates with `/larp` evidence | (~30% in v6) | 100% | _record_ |
| Banned-language lint violations caught pre-merge | (n/a in v6) | track count | _record_ |

#### Quality metrics

| Metric | v6 baseline | v7 target | Actual |
|--------|--------------|-----------|--------|
| Number of "tests pass but not ready" incidents | 5/6 had ≥1 | 0 | _record_ |
| Number of surrogate-proof incidents | 6/6 had ≥1 | 0 | _record_ |
| Number of stale-truth incidents (decisions referenced wrong file) | 6/6 had ≥1 | 0 | _record_ |
| User-reachability failures (feature built but no entry point) | 4/6 had ≥1 | 0 | _record_ |
| Generic AI cheerleading copy in user-facing strings | 4/6 had ≥1 | 0 | _record_ |

#### Output quality (judgment after ship)

| Quality | v6 baseline | v7 target |
|---------|--------------|-----------|
| Does the magic moment actually feel magic in the shipped product? | inconsistent | yes |
| Does the product feel cohesive (not "7 different apps")? | composition fallacy in 4/6 | yes |
| Are user-visible strings on-brand? | drift in 4/6 | yes |
| Does the paid path work end-to-end without dev shortcuts? | broken in 3/6 | yes |
| Does the product survive `/recheck` after 2 weeks idle? | not measured | yes |

### Phase 4: Capture friction

Throughout the run, log:

- **Wasted time** caused by v7 ceremony (target: <20% of total cycle time)
- **Cases where v7 caught a problem** that v6 would have shipped (count these)
- **Cases where v6 would have moved faster** (count these)
- **Tool/script bugs** (file in `specs/projects/<id>/v7-field-test-issues.md`)

### Phase 5: Retrospective and comparison

After the field test ships (or hits `SHIP-RC` if shipping is blocked externally):

1. Run `/project-retrospective` per usual
2. Compare results to the six v6 baselines:
   - Failure mode count: should be **strictly lower**
   - Days-to-`UX-RC`: should be **same or lower** (any longer is friction debt)
   - Output quality judgments: should be **strictly higher**
3. Write `specs/projects/<id>/v7-field-test-report.md` summarizing:
   - Did v7 prevent the seven v6 failure modes? Yes/No per mode with evidence
   - What ceremony actually paid off?
   - What ceremony was overhead with no payoff? (candidate for v7.1 subtraction)
   - What was still missing? (candidate for v7.1 addition)
4. Open a methodology issue in the Speck repo for findings worth propagating

## Acceptance Criteria for v7 Launch

v7 is **valid for general use** when:

- [ ] The field-test product reaches `SHIP-RC` or `SHIP`
- [ ] All seven v6 failure modes either occur with frequency 0/1 or have a documented v7.1 mitigation
- [ ] Total cycle time is within 20% of the v6 median (any worse = friction debt to address)
- [ ] Field-test report includes both wins and friction calls

Until those criteria are met, **mark v7 as Release Candidate, not GA**.

## Status

- v7 framework code complete: ✅ (this session)
- v7 field test executed: ⏳ (pending — next real product build)
- v7 acceptance criteria met: ⏳ (pending)

When the field test runs, link it here:

```
Field test project: [link or ID]
Field test status: [in-progress | ship-rc | shipped | aborted]
Field test report: [path]
Acceptance criteria met: [date or pending]
```

## Why this is a deliverable, not a session task

The field test takes weeks of real product work — it cannot be done in a single tooling session. What this session delivered is the **complete v7 framework + this protocol**. The user runs the protocol on their next product build, and v7 graduates from RC to GA based on the result.

If the field test reveals critical gaps, those become the v7.1 backlog.

---

*[as of SHA `efa97de` | verified 2026-05-16 | speck v7.0.0]*
