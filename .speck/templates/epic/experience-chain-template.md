---
speck_version: 7.0
artifact_type: experience-chain
required_for: ui-epics
---

# Experience Chain — [EPIC_NAME]

<!--
THIS IS REQUIRED FOR ANY UI EPIC.

The experience-chain.md defines the SEAMS between screens, not the screens themselves.
Each story optimizes its own screen, but only this artifact prevents the result from feeling
like "seven different apps stitched together."

If your epic has user-facing UI and no experience-chain.md, /epic-plan refuses to run.

Skip ONLY for: backend-only, API-only, CLI-only, infrastructure/devops epics.

For legacy brownfield epics without an upfront chain, see experience-chain-historical-template.md
(scaffolded by /speck-catch-up). Those use a lighter exemption marker — the
canonical chain is reverse-engineered on re-validation, not authored upfront.

PLACEHOLDER CONVENTION:
  Tokens marked  REPLACE_BEFORE_SHIP: <hint>  MUST be filled before this artifact
  can claim ship-readiness. /speck-recheck greps for them.
-->

**Epic**: REPLACE_BEFORE_SHIP: E### - Name
**Project**: `REPLACE_BEFORE_SHIP: project-id`
**Last Updated**: REPLACE_BEFORE_SHIP: YYYY-MM-DD

---

## 1. Epic's Place in the Product

**Where in the JTBD this epic lives**:
[1 sentence. Which segment of the primary JTBD does this epic deliver?]

**What's true at the END of this epic that wasn't true at the START**:
[1-2 sentences. Outcome-focused, user-centered.]

---

## 2. Screen-by-Screen Chain

*Each screen in the epic gets a row. Every row defines BOTH the screen's job AND the handoff to the next.*

| # | Screen | Entry state (what user brings in) | Single job on this screen | Emotional state on arrival | Emotional state on handoff | Handoff to | What MUST NOT repeat from previous screen |
|---|--------|-----------------------------------|---------------------------|-----------------------------|-----------------------------|------------|--------------------------------------------|
| 1 | [Screen name + story-id] | [State] | [The one job] | [Emotion] | [Emotion] | [Next screen] | [Anti-repetition rule] |
| 2 | [Screen] | [State] | [Job] | [Emotion] | [Emotion] | [Next] | [Rule] |

---

## 3. Variants Per Screen

*Real users don't all follow the same path. Define explicit variants.*

| Screen | First-time variant | Returning variant | Interrupted/Resumed variant |
|--------|--------------------|--------------------|------------------------------|
| [Screen 1] | [What differs] | [What differs] | [What differs] |
| [Screen 2] | [What differs] | [What differs] | [What differs] |

For each variant, list:
- What's hidden, shown, pre-filled, skipped, or added
- Why the change serves THIS variant
- Verification: how `/larp` proves the variant works

---

## 4. No-Repetition Rule (between adjacent screens)

For each transition, list what would feel redundant or robotic if repeated:

| Transition | Redundant if shown twice | Enforced by |
|------------|--------------------------|-------------|
| Screen 1 → 2 | [Welcome/intro repetition] | [Single PageHeader pattern; primitives registry] |
| Screen 2 → 3 | [Same field labels phrased identically] | [Voice principles in product-contract.md] |

---

## 5. "Why now?" for the First Viewport (per screen)

*What does the user see in the first 3 seconds that makes them want to engage with THIS screen now? Not later, not skip, not back.*

**The Density Budget Rule:**
Every screen must respect the density budget: **one screen, one job, one primary action, one proof point, details one tap deeper.** Do not clutter the first viewport.

| Screen | First-viewport "why now?" | Density Budget Compliance |
|--------|----------------------------|----------------------------|
| [Screen 1] | [The single thing that earns 3 seconds of attention] | [Verified: 1 job, 1 CTA, details 1 tap deep] |
| [Screen 2] | [Same — different per screen] | [Verified] |

---

## 6. Magic-Moment Placement

*Cross-reference `product-contract.md` magic moments. Where in the chain does each one land?*

| Magic Moment (from product-contract.md) | Screen # in this chain | Why this screen specifically? |
|------------------------------------------|-------------------------|--------------------------------|
| [Name] | [#] | [Rationale for placement] |

---

## 7. Continuity Threads (cross-screen invariants)

*Information that must persist visibly across screens to maintain context — name them so individual stories don't lose them.*

| Thread | Visible on screens | Why continuity matters |
|--------|--------------------|-------------------------|
| [e.g., User's chosen goal] | All onboarding screens | Identity anchor; pre-fills downstream forms |
| [e.g., Progress indicator] | Steps 2-5 | Reduces abandonment |
| [e.g., Selected plan] | Pre-purchase to post-purchase | Trust + reassurance |

---

## 8. Backtracking Behavior

*What happens on Back / Cancel / Close at each screen?*

| Screen | Back behavior | Cancel behavior | Close behavior |
|--------|---------------|------------------|----------------|
| [Screen 1] | [Where they go, what's preserved] | [What happens to in-progress state] | [Quit confirmation? auto-save?] |

---

## 9. Adjacency to Other Epics

*The seams between THIS epic and others — handoffs, shared state, cross-references.*

| Other epic | Where they touch | Shared state | Test point |
|------------|-------------------|--------------|------------|
| [Epic X] | [Entry/exit] | [What carries over] | [How `/epic-validate` checks this seam] |

---

## 10. Validation Anchors

*The `/epic-validate` JTBD walkthrough uses this chain to drive the test.*

The walkthrough script:
1. Cold-start fresh persona (per `personas/<id>.md`)
2. Walk through this chain end-to-end
3. At each screen, validate:
   - Entry state matches expectation
   - Single job is achievable
   - Emotional progression lands
   - No-repetition rule held
   - Continuity threads visible
4. Verify cross-epic seams work

`/epic-validate` writes findings into `epic-validation-report.md` JTBD Walkthrough section.

---

## Acceptance Checklist

- [ ] Every screen in the epic has a row in the chain
- [ ] Every screen has a single job (not multiple)
- [ ] Emotional states are specific (not "feels good"; specific like "feels trust" or "feels capability")
- [ ] No-repetition rule has at least one entry per transition
- [ ] First-viewport "why now?" is named for every screen
- [ ] Magic moments are placed on specific screens
- [ ] Continuity threads enumerated
- [ ] Backtracking behavior defined per screen
- [ ] Adjacency to other epics named (or "no adjacency")

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck]*
