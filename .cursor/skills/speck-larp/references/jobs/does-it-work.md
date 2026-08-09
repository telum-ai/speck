# speck-larp / does-it-work

## Purpose

`/larp` is first-class in Speck because runtime LARP closes the spec-to-reality gap. In v8 it is **two non-collapsible jobs** (P1 — evaluation over verification):

- **Job A · DOES-IT-WORK** — functional verification: the flow completes, gates are enforced, magic-moment mechanisms fire, and every claim has a mechanism.
- **Job B · IS-IT-GOOD** — experiential judgment: for *every* captured screen, look **at the pixels** (not the AX tree) and judge, adversarially, how it actually looks and feels to a discerning user of THIS product.

The critical inversion (#78): an agent left to its defaults will *verify* (confirm the spec) and never *evaluate* (judge quality) — a spec is fully satisfiable by an ugly, broken-feeling screen. Job B forces the evaluation mode a human runs reflexively. **Job B has its own pass/fail and can block ship independently of Job A.** A captured screen with no substantive critique is an incomplete LARP (surrogate proof), not a pass.

LARP uses the actual target build (not dev server), cold-starts fresh per persona, captures screenshots/AX trees/timings/transcripts, runs both jobs, validates magic moments, and produces checked-in SHA-stamped evidence that story/epic/project-validate consume.

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
