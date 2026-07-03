---
speck_version: 8.0
template_version: "8.0.0"
artifact_type: persona-larp
---

# Persona LARP Script: [PERSONA_ID]

<!--
Persona LARP scripts live in: specs/projects/<PROJECT_ID>/personas/<persona-id>.md

This is an executable script — the /larp skill runs it. Be specific about:
- The starting state (clean storage, fresh account, logged out, locale, etc.)
- The exact actions to take (with selectors / refs where applicable)
- The expected emotional state at each step
- What to capture (screenshot, AX tree, transcript)
- What counts as PASS vs FAIL for each step
-->

**Persona ID**: `[persona-id]`
**Persona Name**: [Anxious Beginner / Returning User / Skeptical Buyer / Naive-Hostile First-Timer / etc.]
**Last Updated**: [YYYY-MM-DD]

---

### 🎭 Canonical Persona: Naive-Hostile First-Timer (`naive-hostile`)
This is a standard, context-stripped persona required for all consumer-facing products. **Running it is how the AI covers the FELT-GOOD readiness axis** — the agent applies first-impression taste judgment directly rather than deferring it to a human.
- **Context-stripped setup**: The user just installed this app. They know nothing about its philosophy, founders, or technical architecture. They are impatient, easily confused, and highly sensitive to friction.
- **Goal**: Complete the onboarding flow and reach the first value-producing screen.
- **Hostile mindset**: They are looking for reasons to close the app, uninstall, or feel annoyed. Any jargon, slow loading, or unnecessary input fields will trigger immediate revulsion.
- **Outcome (FELT-GOOD verdict)**: The agent records a first-impression taste verdict from this pass. A clean pass yields `felt_axis: ai-verified` (cite the findings file); any confusion/disorientation/revulsion is a PASS-blocking finding. A human taste review is an optional stronger signal (`felt_axis: human-verified`), never a prerequisite.

---

## Who They Are

- **Demographics**: [Age range, role, life context]
- **Tech comfort**: [Low / Medium / High]
- **Mood/State**: [What's going on for them emotionally as they start]
- **Why they're using this**: [The JTBD]

## Detection Signals

*If the product can detect which persona a user matches, list signals here.*

- Signal: [e.g., "Returns within 7 days of first session" → Returning User]
- Signal: [...]

## Primary Intent

**Job statement**: When [situation], I want to [job], so that I can [outcome].

**Target completion time**: [N seconds/minutes]

**Success criteria** (qualitative + quantitative):
- [Qualitative: e.g., "User feels guided, not pressured"]
- [Quantitative: e.g., "First session started in <60s"]

---

## LARP Script

*Platform-specific. Use the appropriate visual_testing tooling for your recipe.*

### Setup (clean state)

```
Platform: [iOS native / Web / Android / Desktop / etc.]
Tooling: [AXe / Playwright / Maestro / WebdriverIO / Browser MCP]
Build target: [from evidence-contract.md valid proof sources]
Build Fingerprint: [App version / Backend API fingerprint]
```

**Starting state**:
- [ ] Clean build: Yes (build cache cleared before production build compile)
- [ ] Clean install / fresh storage / cleared cookies
- [ ] No user logged in
- [ ] Locale: [if multilingual, which locale to test]
- [ ] Device/viewport: [if applicable]

### Steps

| Step | Action | Capture | Expected emotional state | PASS if | FAIL if |
|------|--------|---------|--------------------------|---------|---------|
| 1 | [Cold-open app] | Screenshot, AX tree, timing | [What user feels] | [Specific success] | [Specific failure] |
| 2 | [Tap CTA / type / etc.] | [What to capture] | [Emotional state] | [PASS criterion] | [FAIL criterion] |
| 3 | [Next action] | [Capture] | [Emotional] | [PASS] | [FAIL] |

### Magic Moments to Validate

*Cross-reference `product-contract.md` magic moments. Which apply to this persona?*

- [ ] Magic Moment #1: [Name] — must land at Step [N]
- [ ] Magic Moment #2: [Name] — must land at Step [N]

### Backtracking / Hesitation Tests

*Real users don't follow happy paths. Test interruption + recovery.*

- [ ] Step [N]: User taps Back. Recovery: [expected behavior]
- [ ] Step [N]: User backgrounds app. Recovery: [expected behavior]
- [ ] Step [N]: User skips optional field. Result: [expected fallback]

### Error / Degraded States

- [ ] Network drops at Step [N]. Expected: [behavior]
- [ ] Backend returns 500 at Step [N]. Expected: [user-facing message + recovery path]
- [ ] User provides invalid input at Step [N]. Expected: [validation + clear next step]

### Longitudinal Proof Mode (if applicable)

*For adaptive/coaching products, define the same-user timeline continuity checks.*

- [ ] **Timeline Log:** Verify `timeline.jsonl` contains the chronological sequence of state mutations.
- [ ] **Continuity Invariant:** Verify that preferences/signals collected on Day 0 are correctly reflected in Week 1+ states.
- [ ] **No Disconnected Seeds:** Confirm that the user's progress is validated via continuous state transitions, not isolated mock states.

---

## IS-IT-GOOD — Per-Screen Adversarial Critique (P1, Job B)

*This is the point of the LARP — how it looks and feels IS the product. Switch modes: stop confirming the spec, look at the pixels for what is WRONG.*

For **every** captured screen, judging **from the image, not the AX tree**, answer: *"What is the first thing that looks wrong? Where would a discerning user of THIS product wince?"* Record **≥2 specific, pixel-anchored observations per screen**. "No defects" is never the default — argue it explicitly against the assumption that every screen has something to improve. A captured screen with no substantive critique is an incomplete LARP (surrogate proof), not a pass.

| Dimension | Question | Rating | Note |
|-----------|----------|--------|------|
| First-Viewport Reaction | **The Naive Rubric**: What is this? / Who's asking? / Why now? / Why should I care? (Any confusion/disorientation/revulsion is a PASS-blocking finding) | ✅/⚠️/❌ | [Note] |
| First glance (3s) | What does the user understand in 3 seconds? | ✅/⚠️/❌ | [Note] |
| Surface economy | What repeats or competes on this screen? (Are there redundant labels, competing CTAs?) | ✅/⚠️/❌ | [Note] |
| Progressive disclosure | What should move one tap deeper to reduce cognitive load? | ✅/⚠️/❌ | [Note] |
| Visual feel | Calm/intentional/premium OR cramped/random/cheap? | ✅/⚠️/❌ | [Note] |
| Copy feel | Specific to product OR generic SaaS? | ✅/⚠️/❌ | [Note] |
| Voice match | Matches product-contract voice principles? | ✅/⚠️/❌ | [Note] |
| Banned-language | Any banned terms appear in user-visible surface? | ✅/⚠️/❌ | [Note] |
| Thumb reach | Primary action reachable for one-handed mobile use? (mobile only) | ✅/⚠️/❌ | [Note] |
| Safe-area | No critical UI clipped by status bar / home indicator? (mobile only) | ✅/⚠️/❌ | [Note] |
| Magic-moment delivery | Does the magic moment actually feel like a magic moment? | ✅/⚠️/❌ | [Note] |
| Would I pay? | Skeptical buyer judgment: does this earn the price *vs a free/DIY substitute*? | ✅/⚠️/❌ | [Note] |

### Common-Sense Defect Sweep (the class specs never encode)

The exact defects a human notices instantly and specs omit. Check every screen:
- [ ] Duplicated / redundant content (a value printed twice, repeated labels)
- [ ] Clipped, hidden, or overlapping elements (esp. inputs behind sticky footers / keyboard)
- [ ] Primary action off-screen or otherwise unreachable
- [ ] Typographic proliferation (too many sizes / weights)
- [ ] Accent colors used with no semantic rule (same accent doing unrelated jobs)
- [ ] Alignment / spacing raggedness
- [ ] Off-brand or wrong iconography / emoji (e.g. gamey full-color emoji on a calm, premium brand)
- [ ] Awkward, truncated, or placeholder-looking copy
- [ ] **Emotional-tone match**: does the visual feeling match the intended feeling? (e.g. maxed 5/5 severity dots reading as a report card on a screen meant to feel gentle)

### Action-Claim Audit (Job A / DOES-IT-WORK, P2)

For every action the product or its AI surface claims (in-progress or completed), verify the mechanism actually fired. A claim with no mechanism is an automatic FELT-GOOD fail + P0 (the product is lying to the user):
- [ ] Claim: "[what the surface said it did / is doing]" → Mechanism observed: [endpoint hit / row written / state change] OR **NONE → P0**

---

## Evidence Capture Convention

Save evidence to `<story-or-epic-dir>/larp-recordings/`:

- Screenshots: `<sha>-<persona-id>-<step>.png`
- AX trees: `<sha>-<persona-id>-<step>.xml` (or `.json`)
- Timings: `<sha>-<persona-id>-timings.json`
- Transcripts (AI features): `<sha>-<persona-id>-transcript.md`
- Video recording (optional but recommended): `<sha>-<persona-id>-full.mp4`
- Findings: `<sha>-<persona-id>-findings.md`

---

## Findings Template

Each LARP run produces a findings note:

```markdown
# LARP Findings — <persona-id> — <sha> — <date>

**Persona**: [name]
**Build SHA**: [hash]
**Build target**: [valid proof source from evidence-contract]
**Date**: [YYYY-MM-DD]

## Overall Verdict (two non-collapsible jobs)
- **DOES-IT-WORK**: [PASS / CONDITIONAL_PASS / FAIL]
- **IS-IT-GOOD**: [PASS / CONDITIONAL_PASS / FAIL]  ← can block ship independently of DOES-IT-WORK
- **felt_axis**: [uncovered / ai-verified / human-verified]

## Step Results
[Per-step table]

## Magic Moment Validation
[Per-moment table]

## Taste Judgment Summary
[Aggregate of dimensions]

## P0-P3 Findings
[Ranked]

## Recommended Fixes
[List]
```

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck 8.0.0]*
