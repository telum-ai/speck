---
name: speck-premise-challenge
description: Premise-challenge (anti-spec) pass. Questions whether the contract's underlying design decisions are good (rather than whether the code conforms to them).
disable-model-invocation: false
---

## Purpose

Standard validation checks whether the implementation conforms to the specifications (`spec.md`) and the product contract (`product-contract.md`). However, conformance is blind to taste: **an implementation can be 100% correct and on-spec, yet still be a terrible user experience.** Worse, a bad design decision encoded in the contract will pass all standard gates green.

The **Premise-Challenge (Anti-Spec) Pass** is an adversarial review step designed to question the underlying design decisions of the product contract itself. It is distinct from `speck-skeptical-review` (which enumerates alternatives before locking a decision) and `speck-audit` (which checks for technical correctness and edge cases).

---

## 🎯 Target Surfaces

A Premise-Challenge pass is **mandatory** for stories and epics touching high-impact user experience surfaces:
1. **Onboarding / First-Run**: The very first screen, setup flows, or tutorial.
2. **Empty States**: What the user sees when there is no data yet.
3. **Paywalls / Billing**: Subscription prompts, upgrade triggers, and pricing tables.
4. **Error / Degraded States**: Network disconnect banners, validation errors, and crash screens.
5. **Celebration Surfaces**: Success screens, completion states, and "magic moments."

---

## 🛠️ Core Process

When executing a Premise-Challenge pass, the agent must adopt a hostile, highly skeptical user perspective and ask:

### 1. Challenge the Friction
- Why is this step necessary? Can we eliminate it entirely?
- Are we asking for too much information too early?
- Does the user have to think or hunt to proceed?

### 2. Challenge the Value
- Is the value proposition immediately clear on this screen?
- Are we showing generic AI cheerleading copy instead of real, governed product copy?
- Does the screen feel like a "chore" rather than a "magic moment"?

### 3. Challenge the Failure Paths
- When this fails, does the user feel stupid, or do they feel supported?
- Is the error message clear and actionable, or is it technical jargon?

---

## 📋 Outputs & Escalation

A Premise-Challenge pass results in one of two outcomes:

1. **Premise Wrong (Escalate to `/project-adjust`)**:
   - If the underlying contract design is fundamentally flawed or feels bad, the agent **MUST** halt implementation and trigger `/project-adjust` to re-spec the contract delta and compute the reverse cascade.
2. **Premise Accepted (Escalate to DEC)**:
   - If the design decision is questionable but consciously accepted due to constraints (e.g., legal compliance, technical limitations), the decision **MUST** be logged as a conscious DEC in `project-decisions-log.md` with alternatives and trade-offs.

---

## ⚖️ Operator Guidance & Anti-Laundering Rules

- **"This feels off" is a first-class thread**: Never ignore a gut-level taste or UX concern. If something feels awkward, clunky, or confusing, it is a failed premise.
- **Never conflate CORRECT/ON-CONTRACT with good**: A green test suite and a conforming LARP do not mean the product is ready to ship.
- **Never launder a taste miss as "uncatchable by automation"**: If a user experience is poor, do not excuse it as an autonomous limitation. Document it, raise a premise challenge, and escalate to the human operator.

*[as of SHA HEAD | verified 2026-07-02 | speck v7.20.0]*
