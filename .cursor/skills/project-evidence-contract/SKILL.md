---
name: project-evidence-contract
description: Create or update evidence-contract.md — the PROVE center of gravity. Defines what counts as proof for THIS product (per platform), what does NOT count, readiness state gate criteria, and adversarial probes. Required at Build+ before /project-plan. Load when user wants to define ship criteria, lock launch gates, prevent surrogate proof, or before any validation work. FIRST ACTION is read the template at .speck/templates/project/evidence-contract-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

Before any other action, read:
```
.speck/templates/project/evidence-contract-template.md
```

The template defines the canonical evidence-contract structure.

---

## Purpose

`evidence-contract.md` is the single document that prevents the most common v6 failure: **specs claim done while runtime proves otherwise.**

It locks down:
- What runtime evidence counts as proof (per platform)
- What does NOT count (e.g., browser screenshots for native iOS launch)
- Exact gate criteria for each readiness state (IMPL-GREEN → SHIP)
- Adversarial probes that must pass before SHIP-RC
- Where evidence artifacts live in the repo

Without this contract, validation reports drift into "tests pass therefore done" and ship docs lie about reality.

## When to Run

| Trigger | What to do |
|---------|------------|
| After `/project-product-contract`, before `/project-plan` | Required at Build+ — create from recipe defaults + product specifics |
| Adding a new target platform | Add per-platform sections |
| Drift detected: validation reports used surrogate proof | Tighten Invalid Proof Sources |
| Migrating from v6 | Construct from existing validation reports + recipe defaults |

## Prerequisites

- `project.md` must exist
- `product-contract.md` should exist (paid promise + magic moments inform evidence requirements)
- Active recipe (if any) — provides `visual_testing` and platform-aware defaults

## Execution Steps

### 1. Detect project, play level, and archetype

Find `specs/projects/<PROJECT_ID>/`. Read `.speck/project.json` → `play_level` and `project_archetype`. (If `project_archetype` is missing, default to `consumer_product` or infer from stack/context).
Read `_active_recipe` field from `project.md` frontmatter.

If recipe exists, load `.speck/recipes/<recipe>/recipe.yaml` → `evidence_contract:` section (defaults per recipe).

**Archetype Adaptation**:
Adapt your writing of the template sections based on the detected `project_archetype` (see `evidence-contract-template.md` for explicit WHEN/SKIP criteria):
- **For `infra_service` / `backend_api` (Non-UI / Systems work)**:
  - In Section 4 (LARP), write the "Integration / Stress-Test Scenarios" (Option B).
  - In Section 7 (Readiness State Gate Criteria), map to API-RC, metered billing, and OPERATIONAL-RC.
- **For `consumer_product` / `b2b_saas` / `internal_tool` (UI/Human-facing products)**:
  - Write standard Option A human-persona-based LARP and standard UX-RC/SHIP-RC gate checklists.

### 2. Read prerequisites (parallel)

```
├── [Parallel] speck-explorer: Read product-contract.md (magic moments + AI behavior contract inform LARP requirements)
├── [Parallel] speck-explorer: Read context.md (platform constraints, compliance requirements)
├── [Parallel] speck-explorer: Read architecture.md if exists (external services + integrations)
└── [Parallel] speck-explorer: Read recipe.yaml visual_testing + evidence_contract sections
```

### 3. Identify target platforms

Ask user (with recipe defaults pre-filled):
- "What platforms ship in production?"
- For each platform: build artifact + distribution

### 4. Per-platform proof rules (skeptical-review primitive)

For each platform, the evidence is platform-specific. Common starting points by platform:

| Platform | Valid proof (start) | Invalid proof (start) |
|----------|---------------------|------------------------|
| iOS native (Expo/RN/native) | Standalone sim build, TestFlight, AXe screenshots, AX trees, native logs | Browser localhost, Expo Go, Safari, dev-client launcher |
| Android native | Emulator/device APK build, ADB logs, screenshots from build | Browser, Expo Go, dev-client |
| Web | Built bundle behind nginx/serve, Playwright against build, Lighthouse | Vite/Next dev server, Storybook-only, mock auth |
| Desktop (Electron/Tauri) | Packaged installer, Playwright Electron / WebdriverIO | npm run dev, browser-only |
| CLI | Release binary, integration tests against binary | cargo run / npm run dev |
| API | Deployed staging/prod, integration tests against deployment | Local server in dev mode |

Run skeptical-review for the platforms — present 2-3 framings of valid/invalid lists, surface tradeoffs, pick one with rationale.

### 5. Required LARP scope

Based on `product-contract.md`'s personas and magic moments:
- For each persona, what's the primary flow they must complete?
- What evidence is required for UX-RC vs SHIP-RC?

Each persona gets a row. LARP scripts live in `personas/<persona-id>.md`.

### 6. Live-service evidence

For each external service named in `context.md` or `architecture.md` (Stripe, Supabase, Sentry, OpenAI, etc.):
- What proves it works in prod?
- What does NOT count?

### 7. Readiness state gate criteria

Use the template's standard gate criteria as a starting point. Add project-specific items (e.g., for a paid iOS app, RevenueCat sandbox proof is mandatory at COMMERCIAL-RC).

### 8. Adversarial probe suite

Start with the standard 10 probes in the template. Add project-specific probes (e.g., for an AI product: prompt injection, model fallback when API down).

### 9. Evidence storage paths

Standard storage paths in template. Customize only if project has unusual structure.

### 10. Write the file and stamp

Write to `specs/projects/<PROJECT_ID>/evidence-contract.md`.

Apply SHA stamp:
```
.speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/evidence-contract.md
```

### 11. Trigger downstream regeneration

Run `/project-state` to regenerate `project-state.md` with evidence contract reflected.

### 12. Report to user

```
✅ evidence-contract.md created

Path: specs/projects/<PROJECT_ID>/evidence-contract.md
Target platforms: <count>
Valid proof sources defined: <count>
Invalid proof sources defined: <count>
Readiness states with gate criteria: 8 (NO-SHIP, IMPL-GREEN, INTEGRATION-GREEN, UX-RC, API-RC, COMMERCIAL-RC, SHIP-RC, SHIP)
LARP requirements: <count> personas × <count> states
Adversarial probes: <count>

Next steps:
1. Review the contract — this is what validation gates will enforce
2. /project-plan can now proceed (PRD + epics)
3. Stories' validation reports will be checked against these criteria
```

## Behavior Rules

- NEVER allow validation reports to claim a readiness state without the gate criteria
- NEVER let the same proof source be both valid and invalid
- ALWAYS use recipe defaults as starting point when available
- ALWAYS apply SHA stamp on write
- ALWAYS trigger `/project-state` regeneration
- For paid products: COMMERCIAL-RC criteria are mandatory, not optional

## Integration Points

- Required input: `product-contract.md`, `context.md`, optionally `architecture.md`, recipe
- Required output: `evidence-contract.md` (with SHA stamp)
- Downstream consumers: every `/story-validate`, `/epic-validate`, `/project-validate`, `/audit`, `/larp`, `/recheck`
- Updates: `project-state.md`

## Context: $ARGUMENTS
