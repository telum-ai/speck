---
name: speck-larp
description: First-class persona-based runtime LARP (Live-Action Role Play). Cold-starts the actual target build (not dev server), drives it as a named persona through the JTBD flow, captures screenshots + AX trees + timings + taste notes, validates magic moments, and produces checked-in evidence. Recipe-driven via visual_testing config — supports iOS (AXe), Android (Maestro), Web (Playwright/Browser MCP), Desktop (WebdriverIO/Playwright Electron), Flutter (golden tests). Load when validating UI stories/epics, when /recheck runs persona cold-start, or when user says "LARP this", "test as a user", "use the app as a real user", "is this real".
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## ⚠️ Step 0: Read Template First

Before any other action, read:
```
.speck/templates/story/persona-larp-template.md
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
| `/epic-validate` for UI epic | Run full JTBD walkthrough per persona |
| `/recheck` (every persona) | Cold-start LARP for drift detection |
| `/project-validate` | End-to-end JTBD smoke test across all personas |
| User says "LARP this" | Run with provided persona |
| Before claiming SHIP-RC | Run against launch build (not dev) |

## Prerequisites

- `personas/<persona-id>.md` exists (LARP script)
- `evidence-contract.md` exists (defines valid proof sources)
- Active recipe with `visual_testing:` config (defines tooling)
- Built artifact exists (per evidence-contract — NOT dev server)
- **Clean Build for UX-RC+:** Build cache cleared (e.g. `rm -rf .next` / `trash .next` or build tool cache equivalents) and a fresh compilation run of the production built artifact.
- **REQUIRED and non-deferrable:** For all UI-facing stories/epics, the browser cold-start LARP is **REQUIRED and non-deferrable**. You may NOT defer the LARP or use `autonomous-not-done` to bypass it. A cap at `INTEGRATION-GREEN` for a "named infrastructure blocker" is valid ONLY with a **logged, reproduced failure of the actual LARP recipe** (the attempted run + the specific error captured) — never an assertion, memory, or a prior epic's precedent (P3, #76.1). First try the Sandbox-Friendly setup recipe below. Otherwise report a hard blocker (`NO-SHIP`).

If launch-build doesn't exist: STOP and report. Tell user "LARP requires the target build. Run [build command] first."

### 💡 UI LARP Setup Recipe (Sandbox-Friendly)

To execute browser LARPs successfully in sandboxed or restricted environments without real production databases/credentials:
1. **Throwaway/Local DB**: Seed a local/SQLite or Docker-based database with minimal test fixtures.
2. **Loopback/Review-Session Backdoor**: Implement a secure backdoor route or environment flag (e.g. `VITE_DEV_HTTP=true` or `process.env.PLAYWRIGHT_TEST=true`) that bypasses external OAuth/Clerk redirects and logs in a test user.
3. **localStorage Token Re-injection**: Pre-populate `localStorage` or cookies with mock JWTs or session tokens before navigating, to simulate an authenticated state.
4. **Loopback/Mock Server**: Run a lightweight local mock server (e.g., MSW or wiremock) to intercept and mock third-party API calls (e.g., Stripe, Resend) during the browser run.

## Execution Steps

### 1. Locate project, persona, and tooling

Find `specs/projects/<PROJECT_ID>/`.

Read inputs:
- `personas/<persona-id>.md` — LARP script
- `evidence-contract.md` — valid proof sources
- `product-contract.md` — magic moments + banned language
- `.speck/recipes/<active>/recipe.yaml` → `visual_testing:` section

If persona-id not specified, ask user which persona or run all per evidence-contract requirements.

### 2. Verify the target build exists

Map the evidence-contract's valid proof source to a concrete artifact:

| Platform | Target build check |
|----------|--------------------|
| iOS | `.app` exists in ios/build OR TestFlight build registered |
| Android | `.apk`/`.aab` exists in android/app/build OR Play Console build |
| Web | `dist/` or `out/` exists AND is being served behind reverse-proxy-lookalike |
| Desktop | Packaged installer exists |
| CLI | Release binary exists at `target/release/<name>` or equivalent |

If invalid (e.g., user is trying to LARP against dev server for an iOS app): STOP and refuse. Tell user "Per evidence-contract.md, dev-server screenshots don't count as valid proof for this platform. Build the launch artifact first: [exact command]."

**Clean Build Precheck & Split-Brain Env Guard (UX-RC+):**
- Verify that the production build was compiled AFTER clearing any incremental build caches. If a stale cache is detected, fail the precheck and require a clean build to prevent false-green results. Record "clean build: yes" in findings and report templates.
- **Client-Bundle Env Guard:** Always verify the **client-side bundle's environment** (inspect the browser's actual network calls/console) rather than just looking at server-side environment variables. Modern frameworks (e.g. Next.js, Vite) inline public env variables (prefixed with `NEXT_PUBLIC_*`, `PUBLIC_*`, or `EXPO_PUBLIC_*`) directly into client JS chunks **at build time** from `.env` files. Simply changing the server's runtime shell-env does NOT update the client-side bundles, creating a "split-brain" where the server hits local but the browser still hits remote.
- **Dev-Server HMR Warning:** Running a cold-start LARP against a hot-reloading dev server (e.g., Next.js Turbopack) can introduce false failures (such as broken hydration, dead interaction buttons, or hydration mismatches) that do NOT exist in the clean production build. If you encounter a `BLOCKED` state during a dev-server LARP that correlates with HMR or websocket reconnection errors, treat it as **suspect** and verify/reproduce against a clean production build (`next build && next start`) before capping the story's readiness.

### 3. Load the platform-specific visual testing skill

Per `visual_testing.pattern_file` in recipe — load the matching `.cursor/skills/visual-testing-*/SKILL.md`.

### 4. Cold-start the target

Execute setup from `personas/<persona-id>.md`:
- Clean install / clear storage / new account
- Set locale (if multilingual product)
- Reset to viewport / device per persona
- Confirm no logged-in user

Record the **build SHA** that's actually running (not just current HEAD — they should match for fresh evidence).

### 5. Job A — DOES-IT-WORK (functional verification)

Execute the LARP script step-by-step. For each step:
1. Take the action (tap, type, swipe) using platform-specific tooling — always through the **real UI**, never an API/programmatic bypass.
2. Capture per the persona script (screenshot, AX tree, timing, transcript). Write to `<story-or-epic-dir>/larp-recordings/<sha>-<persona>-<step>.{png,xml,json,md}`.
3. Compare against the PASS/FAIL criterion. If FAIL: record finding (P0-P3), continue (don't abort).
4. **Magic moments**: confirm each relevant magic moment's surface / trigger / content beats fire (per `product-contract.md`).
5. **Backtracking / error scenarios**: run the hesitation, back-nav, network-drop, 500, invalid-input, and skip-optional scenarios per the template.
6. **Action-claim audit (P2, #75-G1)**: for *every* action the product or its AI surface claims — in-progress ("building your plan…") or completed ("done", "scheduled", "generated") — verify the mechanism actually fired (endpoint hit, row written, state changed). **A claim with no mechanism is an automatic FELT-GOOD fail + P0** — the product is lying to the user. A no-tools LLM surface must be told what it cannot do, or it will roleplay capabilities it lacks.

### 6. Job B — IS-IT-GOOD (experiential judgment) — REQUIRED, non-collapsible

Switch cognitive modes: stop confirming the spec, start hunting for what is wrong. For **every** captured screen, look **at the image itself (not the AX tree)** and answer:

> "What is the first thing that looks wrong here? Where would a discerning user of THIS product wince?"

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

## 🧭 LARP Must Reach Everything (P3)

If automation cannot reach a control, focus a field, or complete a flow, that is a **finding**, not a valid skip reason (#75-G2).

- "Not tappable / not in the a11y tree / needs a real device / tooling limitation" is NEVER a valid skip — it is a P1 finding until proven otherwise.
- **Default hypothesis**: a control automation can't reach is a control some users can't reach (VoiceOver parity, invisible-overlay hit-testing). The tool is often *surfacing a real layout/a11y bug*, not failing.
- **Diagnostic playbook before blaming tooling**: dump the a11y tree + element frames; coordinate-tap A/B; empirically isolate (stash the suspect layer, re-test); check invisible-overlay geometry (a transformed / opacity-0 absolute-fill plane still hit-tests and still eats VoiceOver focus). Synthetic-tap workarounds are the *wrong* first move.
- A "named infrastructure blocker" cap on readiness requires a **logged, reproduced** failure of the actual LARP recipe (the run + the specific error) — never an assertion, memory, or a prior epic's precedent.

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

### Fallbacks & Adaptations
- **Visual Testing / Browser MCP**: Spawning dynamic browser actions via Playwright/Browser MCP is highly streamlined in Claude/Cursor (using the browser tools or MCP integration). On Codex or other hosts, if automation tools are unavailable, execute the persona steps manually against the target build, take screenshots, save them to `<story-or-epic-dir>/larp-recordings/`, and write the findings note manually.

