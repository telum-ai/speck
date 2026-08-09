# speck-larp / felt

## Step 0: Read Template First

Before any other action, read:
```
.speck/templates/story/persona-larp-template.md
```

The template defines the LARP script structure (setup, steps, magic moments, taste rubric, evidence convention).

---

## Behavior Rules

- NEVER accept a captured-but-un-adjudicated screen as a pass — Job B (IS-IT-GOOD) is REQUIRED and non-collapsible
- NEVER let an AI-surface action claim stand without a verified mechanism (action-claim audit, P2)
- NEVER write off an unreachable control as a tooling limitation without running the diagnostic playbook — unreachable = finding (P3)
- NEVER cap on a "named infra blocker" without a logged, reproduced real attempt (P3)
- ALWAYS record separate DOES-IT-WORK, IS-IT-GOOD, and IS-IT-CRAFTED verdicts; look at the pixels for Job B and Job C, not the AX tree
- For consumer UI, ALWAYS run Job C (connoisseur-hostile → TASTE) and record `taste_axis` + `taste_anchor`; surface aesthetic forks for the owner, never resolve subjective taste unilaterally, and never auto-fix contestable taste (only named-rule violations + hard-objective defects)
- NEVER LARP against dev server when evidence-contract requires built artifact
- NEVER claim UX-RC or higher based on an incremental cached build without performing a clean rebuild first
- NEVER skip taste-judgment rubric
- NEVER claim PASS if banned-language lint finds violations
- ALWAYS capture from target runtime
- ALWAYS write evidence with SHA-prefixed filenames
- ALWAYS run backtracking + error scenarios
- ALWAYS verify and record "clean build: yes" under larp setup and validation report for UX-RC+ claims
- ALWAYS run the `naive-hostile` persona pass for consumer onboarding/first-run surfaces, and treat any confusion, disorientation, or revulsion as a PASS-blocking finding
- ALWAYS cover the FELT-GOOD axis yourself: apply first-impression taste judgment during the naive-hostile pass and record a verdict (`felt_axis: ai-verified`) in the findings — never defer taste to a mandatory human. A human taste review is an optional stronger signal (`felt_axis: human-verified`), not a prerequisite.
