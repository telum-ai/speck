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

`/larp` is first-class in Speck v7 because v6's six retrospectives independently said the same thing: **runtime LARP is what closes the spec-to-reality gap.** It's not a late add-on.

LARP:
- Uses the actual target build artifact (not dev server)
- Cold-starts from fresh state per persona
- Captures screenshots, AX trees, timings, transcripts
- Validates magic moments (per product-contract.md)
- Writes taste-judgment notes per screen
- Produces checked-in evidence with SHA stamps

This evidence is what story-validate, epic-validate, project-validate consume.

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

If launch-build doesn't exist: STOP and report. Tell user "LARP requires the target build. Run [build command] first."

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

### 5. Execute the LARP script step-by-step

For each step:
1. Take the action (tap, type, swipe, etc.) using platform-specific tooling
2. Capture per the persona script (screenshot, AX tree, timing, transcript)
3. Write the captured-state file to `<story-or-epic-dir>/larp-recordings/<sha>-<persona>-<step>.{png,xml,json,md}`
4. Compare against expected emotional state / PASS criterion / FAIL criterion
5. If FAIL: record finding (P0-P3), continue (don't abort)

### 6. Validate magic moments

For each magic moment relevant to this persona (per `product-contract.md`):
- Confirm the surface, trigger, content beats fire as expected
- Compare actual content to "target emotional response"
- Write taste judgment using the rubric in the persona template

### 7. Run the backtracking / error scenarios

- Backtracking, hesitation, error states, skip optional fields — per template

### 8. Write findings note

Per the template's findings format. Save to `<story-or-epic-dir>/larp-recordings/<sha>-<persona>-findings.md`.

### 9. Apply SHA stamp

```
.speck/scripts/stamp-truth.sh <story-or-epic-dir>/larp-recordings/<sha>-<persona>-findings.md
```

### 10. Report

Standard report format per claude skill.

## Behavior Rules

- NEVER LARP against dev server when evidence-contract requires built artifact
- NEVER claim UX-RC or higher based on an incremental cached build without performing a clean rebuild first
- NEVER skip taste-judgment rubric
- NEVER claim PASS if banned-language lint finds violations
- ALWAYS capture from target runtime
- ALWAYS write evidence with SHA-prefixed filenames
- ALWAYS run backtracking + error scenarios
- ALWAYS verify and record "clean build: yes" under larp setup and validation report for UX-RC+ claims

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

