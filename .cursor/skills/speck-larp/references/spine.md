# speck-larp — spine

---

## When to Run

| Trigger | What to do |
|---------|------------|
| `/story-validate` for UI story | Run LARP for the story's persona(s) |
| `/epic-validate` for UI epic | Run full JTBD walkthrough per persona |
| `/recheck` (every persona) | Cold-start LARP for drift detection |
| `/project-validate` | End-to-end JTBD smoke test across all personas |
| User says "LARP this" | Run with provided persona |
| Before claiming SHIP-RC | Run against launch build (not dev) |

## LARP Must Reach Everything (P3)

If automation cannot reach a control, focus a field, or complete a flow, that is a **finding**, not a valid skip reason (#75-G2).

- "Not tappable / not in the a11y tree / needs a real device / tooling limitation" is NEVER a valid skip — it is a P1 finding until proven otherwise.
- **Default hypothesis**: a control automation can't reach is a control some users can't reach (VoiceOver parity, invisible-overlay hit-testing). The tool is often *surfacing a real layout/a11y bug*, not failing.
- **Diagnostic playbook before blaming tooling**: dump the a11y tree + element frames; coordinate-tap A/B; empirically isolate (stash the suspect layer, re-test); check invisible-overlay geometry (a transformed / opacity-0 absolute-fill plane still hit-tests and still eats VoiceOver focus). Synthetic-tap workarounds are the *wrong* first move.
- A "named infrastructure blocker" cap on readiness requires a **logged, reproduced** failure of the actual LARP recipe (the run + the specific error) — never an assertion, memory, or a prior epic's precedent.

## Context: $ARGUMENTS
