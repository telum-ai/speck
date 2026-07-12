---
speck_version: 8.0
template_version: "7.17.0"
artifact_type: project-adjust-report
---

# Post-Validation Project Adjustment Report: [Adjust Name]

**Adjustment ID**: `ADJUST-P-[short-description]`  
**Date**: [YYYY-MM-DD HH:MM]  
**Branch**: [branch name]  

---

## 1. Change Intent (The Why)

*Describe exactly what deliberate directional or intent change is being introduced at the project level and why. What high-level contract pivot or strategic shift occurred?*

- **Observed Need / Feedback**: [e.g., "Pivot from custom billing engine to Stripe checkout per business strategy change."]
- **Deliberate Shift**: [e.g., "Banning local billing table structures in favor of using Stripe checkout and webhooks for all user subscriptions."]
- **Strategic Impact**: [P0 - Pivotal / Core | P1 - High | P2 - Medium]

---

## 2. Delta Re-specification (The What)

*Specify the project-level deltas across your product-contract.md, project.md, PRD.md, architecture.md, or evidence-contract.md.*

- **Affected Contract Sections**: `product-contract.md` (§1 Paid Promise and §3 Differentiators / Banned Language)
- **Affected Architecture/PRD**: [e.g., "architecture.md §4 updated to remove local invoice tables, adding Stripe Webhook router instead."]
- **Evidence Contract Changes**: [e.g., "evidence-contract.md §11 updated to include Stripe webhook signature verification tests."]

---

## 3. Superseding Decision Lock (DEC) & Skeptical-Review Summary

*Directional pivots MUST force a new decision lock that explicitly supersedes previous project decisions and passes a skeptical peer review.*

- **Decision Log Reference**: `DEC-00XX` (e.g. `DEC-0004` in `project-decisions-log.md`)
- **Supersedes**: `DEC-00YY` (or `None`)
- **Skeptical Review Options Considered**:
  1. *Option 1 (Baseline)*: [e.g., Keep local billing, build robust retry systems]
  2. *Option 2 (Pivoted)*: [e.g., Transition fully to Stripe-hosted billing]
  3. *Option 3 (Hybrid)*: [e.g., Mix local ledger with Stripe checkout]
- **Trade-off Analysis & Rationale**: [Detail trade-offs and why the pivoted Option was locked]

---

## 4. Cascade & Blast Radius (The Blast Radius)

*Run `.speck/scripts/validation/validators/compute-cascade.sh` to identify all downstream epics, stories, and promises affected by this adjustment or superseded decision.*

- **Compute Cascade Command Run**: `bash .speck/scripts/validation/validators/compute-cascade.sh --dec DEC-00XX`
- **Downstream Impact Summary**:
  - **Affected Epics**: [e.g., `E003-billing`, `E004-subscriptions`]
  - **Affected Stories**: [e.g., `S014-checkout`, `S015-invoice-download`]
  - **Downstream Promises Affected (PRM-IDs)**: [e.g., `PRM-201`, `PRM-204`]

---

## 5. Re-validation Plan (The Plan)

*How will the affected downstream epics and stories be re-aligned and re-proven?*

- **Downstream Actions**:
  - [ ] Run `/epic-adjust` on `E003-billing` to re-spec checkout flows and update its `traceability-matrix.md`
  - [ ] Run `/story-adjust` on `S014` and `S015` to implement Stripe Checkout and Webhooks
- **New Adversarial test guardrails required**: [e.g., "Mock Stripe webhook signature validation to ensure invalid payloads are rejected."]

---

## 6. Readiness Re-assessment (The Status)

*An un-validated project-level directional change downgrades the overall project readiness state to the MIN of the affected downstream epic states.*

- **Prior Project State**: [e.g., `UX-RC`]
- **Downgrade State**: `NO-SHIP` (due to downstream cascade stale flags `CASCADE_STALE.P1`)
- **Re-assessed State**: [e.g., `UX-RC` (fully restored after downstream epics/stories re-validate and cascade is complete)]
- **Cascade Completeness Proof**: [Run `compute-cascade.sh --dec DEC-00XX --strict` returning 0]

---

*[as of SHA <git_sha_short> | verified <date> | speck]*
