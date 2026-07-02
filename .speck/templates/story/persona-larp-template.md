---
speck_version: 7.0
template_version: "7.11.0"
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
This is a standard, context-stripped persona required for all consumer-facing products.
- **Context-stripped setup**: The user just installed this app. They know nothing about its philosophy, founders, or technical architecture. They are impatient, easily confused, and highly sensitive to friction.
- **Goal**: Complete the onboarding flow and reach the first value-producing screen.
- **Hostile mindset**: They are looking for reasons to close the app, uninstall, or feel annoyed. Any jargon, slow loading, or unnecessary input fields will trigger immediate revulsion.

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

## Taste Judgment Rubric

*Beyond functional pass/fail — does the experience deserve the magic moments?*

For each captured screenshot, the LARP runner must write a taste note:

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
| Would I pay? | Skeptical buyer judgment: does this earn the price? | ✅/⚠️/❌ | [Note] |

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

## Overall Verdict
[PASS / CONDITIONAL_PASS / FAIL]

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

*[as of SHA `<git_sha_short>` | verified `<date>` | speck v7.0.0]*
