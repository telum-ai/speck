# Project Specification: [PROJECT NAME]

**Project ID**: [PROJECT_NUM]
**Created**: [DATE]
**Status**: Specified
**Play level**: [Sprint | Build | Platform]
**Archetype**: [consumer_product | b2b_saas | internal_tool | infra_service | backend_api]

## Sources

- **Primary input**: [user brief, import artifact, or code scan]
- **Known facts**: [facts preserved from the input]
- **Inferences**: [material inferences, each labeled]

## Project overview

[One paragraph: who has which problem, what outcome the project enables, and why it matters. Describe the product boundary without choosing implementation details.]

## Vision and goals

**Vision**: [One sentence describing the better future this project enables.]

1. **[Outcome]**: [measurable target and time horizon]
2. **[Outcome]**: [measurable target and time horizon]
3. **[Outcome]**: [measurable target and time horizon]

Goals preserve outcomes from the source. Do not convert an unresolved product choice into a goal.

## PROFILE surfaces

*Every retained row is binding. Delete surfaces that do not apply; never retain an unresolved placeholder as a declared surface.*

| Surface | Adapter | Target | Source of truth | Required by |
|---------|---------|--------|-----------------|-------------|
| Root README | `readme` | `README.md` | `project.md#project-overview` until product-contract exists | UX-RC / API-RC |
| Package description | `package` | `package.json#description` | `README.md#one-liner` | COMMERCIAL-RC |
| GitHub repo description | `github` | `remote:description` | `README.md#one-liner` | SHIP-RC |
| Landing page hero | `file` | [repository-relative path] | `product-contract.md#1` | COMMERCIAL-RC |

## Users and jobs

### Primary user

- **User**: [specific role or segment]
- **Situation**: [trigger and context]
- **Problem**: [current friction or failure]
- **Core job**: [action + object + context]
- **Desired outcome**: [observable end state]

### Other affected users

- **[User]**: [how the project affects them]

### Current alternatives

- **[Alternative/workaround]**: [what it does well and where it fails]

## Success measures

| Measure | Baseline | Target | Horizon | How measured |
|---------|----------|--------|---------|--------------|
| [outcome measure] | [known or to establish] | [target] | [time] | [method] |

## Commercial intent

Preserve commercial facts from the source without designing the business model here.

- **Commercial posture**: [non-commercial | paid | internal investment | not stated]
- **Buyer / payer**: [source fact or open question]
- **Value exchanged**: [source fact or open question]
- **Revenue model or funding constraint**: [source fact or open question]
- **Unit constraint**: [source-stated margin, cost, volume, or “Not stated”]

Product-contract owns the paid promise, defensible wedge, and value proof. An unstated commercial choice remains open; it must not disappear and must not be invented.

## Definition of done

- [ ] [User can complete the core job with the promised boundary intact]
- [ ] [Each source success measure can be observed]
- [ ] [Named non-goals remain excluded]

Definition of done may require an open choice to be resolved before delivery, but must not preselect its answer.

## Scope

### In scope

- [capability or outcome boundary]

### Out of scope

- [explicit non-goal preserved from the source]

### Later only

- [use only when the source names a future boundary; otherwise write “None named”]

## Constraints

- **Business**: [budget, schedule, policy, or “None stated”]
- **User/trust**: [consent, human control, privacy, or “None stated”]
- **Technical facts already fixed**: [facts only; architecture choices belong later]

## Risks and assumptions

### Risks

- **[Risk]**: [impact and earliest way to test it]

### Assumptions

- **[Assumption]**: [what would disprove it]

## Open questions

- [Question that materially changes promise, scope, or success. Keep the choice open.]

Write “None” only when the source truly resolves every material question.

## Specification check

- Every source goal, measure, non-goal, and unresolved choice is preserved.
- No provider, architecture, price, feature, persona, or comparison candidate is invented.
- Product-contract owns differentiation, paid promises, and value defensibility; context owns team, stack, and compliance; project-plan owns epics and delivery.
- The artifact is sufficient for clarification and the next PROMISE steps without duplicating those later artifacts.
