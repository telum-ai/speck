# speck-larp / taste

```

The template defines the LARP script structure (setup, steps, magic moments, taste rubric, evidence convention).

---

## Purpose

`/larp` is first-class in Speck because runtime LARP closes the spec-to-reality gap. In v8 it is **two non-collapsible jobs** (P1 — evaluation over verification):

- **Job A · DOES-IT-WORK** — functional verification: the flow completes, gates are enforced, magic-moment mechanisms fire, and every claim has a mechanism.
- **Job B · IS-IT-GOOD** — experiential judgment: for *every* captured screen, look **at the pixels** (not the AX tree) and judge, adversarially, how it actually looks and feels to a discerning user of THIS product.

The critical inversion (#78): an agent left to its defaults will *verify* (confirm the spec) and never *evaluate* (judge quality) — a spec is fully satisfiable by an ugly, broken-feeling screen. Job B forces the evaluation mode a human runs reflexively. **Job B has its own pass/fail and can block ship independently of Job A.** A captured screen with no substantive critique is an incomplete LARP (surrogate proof), not a pass.

LARP uses the actual target build (not dev server), cold-starts fresh per persona, captures screenshots/AX trees/timings/transcripts, runs both jobs, validates magic moments, and produces checked-in SHA-stamped evidence that story/epic/project-validate consume.

## When to Run

| Trigger | What to do |
|---------|------------|
| `/story-validate` for UI story | Run LARP for the story's persona(s) |
Record **≥2 specific, pixel-anchored observations per screen**. "No defects" is never the default — it must be explicitly argued against the assumption that every screen has something to improve. Run the **Common-Sense Defect Sweep** (the class of defect specs never encode — full list in the persona template): duplicated/redundant content; clipped/hidden/overlapping elements; primary action off-screen or trapped behind a sticky footer; typographic proliferation; accent colors used with no rule; alignment/spacing raggedness; off-brand or wrong iconography/emoji; awkward or truncated copy; anything that "looks like a placeholder"; and **emotional-tone match** — does the *visual* feeling match the intended feeling (e.g. a report-card treatment on a screen meant to feel gentle)?

This is the naive-hostile taste pass — it produces the FELT-GOOD verdict (`felt_axis: ai-verified` on a clean pass, citing the findings file). An un-adjudicated screenshot cannot support any readiness state that depends on felt quality.

### 6b. Job C — IS-IT-CRAFTED (connoisseur judgment) — the TASTE axis, REQUIRED for consumer UI, non-collapsible

Job B asks "is anything *broken / confusing*?" (legibility → FELT-GOOD). Job C asks the distinct, non-collapsible question "is this *crafted* — premium, restrained, does it sing?" (aesthetic connoisseurship → TASTE). **A screen can pass Job B and fail Job C.** First action: read `.speck/templates/story/connoisseur-critique-template.md` (the lazy rubric — dual-anchor rule, the 8 craft dimensions, HARD-vs-FUZZY verdict logic, fork triage, conservative auto-fix, severe-BAD blocking).

Run it **connoisseur-hostile** over the SAME screenshots Job B captured (no new capture run at normal tier). Per screen: GOOD/ACCEPTABLE/BAD across the 8 dimensions, **dual-anchored** against (a) the product's declared intent — `product-contract.md` §6b Aesthetic Contract + `design-system.md` — and (b) universal craft (the `visual-quality` principles). When §6b/design-system is absent: judge universal-only, stamp `taste_anchor: universal-only`, convert borderline calls to forks, nudge `/project-design-system`.

Output → `larp-recordings/<sha>-connoisseur-findings.md`: a **makes-it-premium** list, a **cheapens-it** list, and an **Aesthetic Forks — Owner Decision** list. Verdict → `taste_axis: ai-critiqued` (or `forks-open` if any fork is open) + `taste_anchor`. **You surface forks; you never resolve subjective taste unilaterally.** A **severe BAD** (≥2 pixel-grounded craft violations on a flagship/magic-moment surface) or a named-declared-rule violation **caps the claimable state** — the objective floor blocks, the *direction* of the fix is the owner's fork.

### 7. Write findings note

Per the template's findings format, with **separate DOES-IT-WORK, IS-IT-GOOD, and IS-IT-CRAFTED verdicts**. Save to `<story-or-epic-dir>/larp-recordings/<sha>-<persona>-findings.md` (+ the connoisseur findings to `<sha>-connoisseur-findings.md` when Job C ran).

### 8. Apply SHA stamp

```
.speck/scripts/stamp-truth.sh <story-or-epic-dir>/larp-recordings/<sha>-<persona>-findings.md
```

### 9. Report

Standard report format. Report **all three** job verdicts (DOES-IT-WORK / IS-IT-GOOD / IS-IT-CRAFTED); never collapse Job B into Job A, nor Job C into Job B.

## LARP Must Reach Everything (P3)

If automation cannot reach a control, focus a field, or complete a flow, that is a **finding**, not a valid skip reason (#75-G2).

- "Not tappable / not in the a11y tree / needs a real device / tooling limitation" is NEVER a valid skip — it is a P1 finding until proven otherwise.
- **Default hypothesis**: a control automation can't reach is a control some users can't reach (VoiceOver parity, invisible-overlay hit-testing). The tool is often *surfacing a real layout/a11y bug*, not failing.
- **Diagnostic playbook before blaming tooling**: dump the a11y tree + element frames; coordinate-tap A/B; empirically isolate (stash the suspect layer, re-test); check invisible-overlay geometry (a transformed / opacity-0 absolute-fill plane still hit-tests and still eats VoiceOver focus). Synthetic-tap workarounds are the *wrong* first move.
- A "named infrastructure blocker" cap on readiness requires a **logged, reproduced** failure of the actual LARP recipe (the run + the specific error) — never an assertion, memory, or a prior epic's precedent.
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

## Integration Points

- Reads: `personas/<persona-id>.md`, `evidence-contract.md`, `product-contract.md`, recipe.yaml, platform visual-testing skill
- Writes: `<dir>/larp-recordings/<sha>-<persona>-*` evidence files, findings note
- Invokes: `banned-language-lint.sh`, `stamp-truth.sh`
- Feeds into: `/story-validate`, `/epic-validate`, `/project-validate`, `/recheck`

## Context: $ARGUMENTS

## Cross-Host Portability & Compatibility

This process skill is fully supported across all primary AI runtimes (Claude, Cursor, Codex) with identical evidence requirements.

| Capability | Claude Code | Cursor | Codex |
|------------|-------------|--------|-------|
| **Execution** | Interactive skill command | Interactive skill command | Interactive skill command |
| **Tooling** | Native Browser MCP or Playwright | Playwright or manual capture | Playwright or manual capture |
