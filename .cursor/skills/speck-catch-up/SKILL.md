---
name: speck-catch-up
description: Drive a migrated v6 project to v7-clean reality. v6→v7 migration only scaffolds empty template artifacts; this skill does the brownfield work — backfills product-contract and evidence-contract from existing v6 docs, reconstructs project-decisions-log from git history, downgrades over-optimistic readiness claims on already-shipped stories, re-audits past validation reports for surrogate proof, and writes project-catch-up-plan.md with prioritized remediation work. Load on engagement when project-state.md / product-contract.md / evidence-contract.md are still in their scaffolded-but-empty state (banner intact), or when the user explicitly says "catch up", "bring this project up to v7", "/speck-catch-up", or after a fresh migration run.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

**The problem this solves.** v6 projects almost always ship with the same seven failure modes documented in the six original v6 retrospectives — surrogate proof, "tests pass therefore ready", spec drift, composition fallacy, premature commitment, implementer self-grading, banned-language drift. Just renaming the project to "v7" and scaffolding empty templates does nothing about that debt. The project is still in a bad state.

**`/speck-catch-up` actually does the work.** It treats the migrated project as a **brownfield import** and reconstructs the v7 truth artifacts from what's already on disk + in git history, while honestly downgrading any over-optimistic v6 status claims to what the runtime actually proves today.

After this skill runs, the project's `project-state.md` reflects reality (likely lower readiness states than v6 claimed), and `project-catch-up-plan.md` lists the prioritized remediation work needed to actually hit `UX-RC` / `SHIP-RC` / `SHIP`.

## When to Run

Run automatically when ANY of these is true (the agent should detect on engagement):

1. `product-contract.md` exists and contains the literal banner `<!-- v7 MIGRATION SCAFFOLD -->`
2. `evidence-contract.md` exists and contains the same banner
3. `project-state.md` exists and contains the same banner
4. `.speck/.migration-needs-catchup` marker file exists at workspace root
5. User explicitly says "catch up", "bring this project up to v7", "/speck-catch-up", "the migration scaffolded the artifacts but they're empty"
6. Agent runs `/recheck` and report shows >50% of truth artifacts in scaffold state

**Block any new feature work** (no `/story-implement`, no `/epic-plan`, etc.) until catch-up is complete. The agent should refuse with: *"This project is fresh from v6→v7 migration. The v7 truth artifacts are still empty scaffolds. Run `/speck-catch-up` first."*

## Prerequisites

- Project at `specs/projects/<id>/` exists
- Migration has run (i.e., `migration-report.md` is present at project root)
- Git history is available (most reconstruction comes from commits)
- Project has at least: `project.md`, `PRD.md` (Build/Platform) OR `sprint-log.md` (Sprint)

If those minimal v6 docs are missing, tell the user: *"This project doesn't have enough v6 history to catch up automatically. Either restore the v6 docs or treat this as a fresh `/project-specify` start."* and STOP.

## Execution

Execute the phases below in order. Phases 1–4 are reconstruction (relatively safe). Phase 5 is the honesty pass (downgrading status claims) and requires user confirmation by default.

### Phase 0 — Triage (parallel reads)

Dispatch parallel subagents:

```
├── [Parallel] speck-explorer: List specs/projects/<id>/**/*.md (full inventory)
├── [Parallel] speck-scanner: Read project.md, PRD.md, ux-strategy.md (if present),
│                              domain-model.md (if present), constitution.md (if present)
├── [Parallel] speck-scanner: Read architecture.md, design-system.md, design-system/primitives.md
├── [Parallel] speck-explorer: Read every epic.md and the most recent validation-report.md
├── [Parallel] speck-explorer: List every screenshots/ directory and inventory what's checked in
├── [Parallel] speck-scanner: git log --since=1.year --pretty=oneline -- specs/projects/<id>/
│              (extract major decisions: architecture, plan, design-system commits)
└── [Wait] → Build a project-state-as-of-engagement table
```

Compute the **engagement-triage table**:

| Dimension | Found? | State |
|-----------|--------|-------|
| `project.md` | Y/N | full / stale / minimal |
| `PRD.md` | Y/N | full / stale / minimal |
| `ux-strategy.md` | Y/N | … |
| `domain-model.md` | Y/N | … |
| `constitution.md` | Y/N | … |
| `architecture.md` | Y/N | … |
| `design-system.md` | Y/N | … |
| Epics | count | how many marked complete? |
| Stories | count | how many marked complete with no runtime evidence? |
| Active recipe | from `.speck/project.json` or `project.md` | name |
| Banned-language present in user-facing strings | scan | hit count |

### Phase 1 — Backfill `product-contract.md`

The migration scaffolded `product-contract.md` as the empty template. Now fill it.

Read the template at `.speck/templates/project/product-contract-template.md` to know the section structure.

Source mapping:

| Product-contract section | Source artifacts |
|---------------------------|--------------------|
| Paid Promise | `project.md` vision + `PRD.md` core value prop + any `pricing*.md` if present |
| Primary Persona | `project.md` target users + first persona in `personas/` (if exists) |
| Differentiator | `project.md` competitive positioning + `ux-strategy.md` |
| Anti-Differentiators | `project.md` "not for" + `constitution.md` boundaries |
| Inspiration Sources | `ux-strategy.md` references + `design-system.md` inspiration |
| JTBD Scorecard | Derived from `PRD.md` functional reqs + `ux-strategy.md` emotional/social hooks |
| Magic Moments | `ux-strategy.md` magic moments section (if exists) ELSE extract from `epic-journey.md` files |
| Public Language | `ux-strategy.md` voice/tone + `design-system.md` copy patterns |
| Banned Language | `constitution.md` "we don't say" if exists; else propose generic-AI-cheerleading defaults |
| AI Behavior Contract | If project uses LLMs: extract from existing AI-related epic specs; else `(N/A)` |
| Longitudinal Axes | If `adaptive-axes/` directory exists, link those; else `(none)` |

**Skeptical-review primitive applies** to every locked decision. For each section, if the v6 docs give a clear unambiguous answer → fill it. If there's ambiguity or no source → enumerate N≥3 alternatives, mark the section `[NEEDS USER REVIEW]`, and add a row to `project-catch-up-plan.md`.

Remove the `<!-- v7 MIGRATION SCAFFOLD -->` banner only after the content is real. SHA-stamp the file.

Log the decision via `/speck-decision-log`:

```
Decision: Filled product-contract.md from v6 sources
Phase: catch-up
Rationale: v6 → v7 migration; reconstructed from project.md + PRD.md + ux-strategy.md + ...
Alternatives: 1) leave scaffolded for user, 2) ask user every section, 3) reconstruct from sources (CHOSEN)
```

### Phase 2 — Backfill `evidence-contract.md`

Look up the active recipe (from `.speck/project.json` or `project.md` `_active_recipe`).

Read the recipe's `evidence_contract:` block from `.speck/recipes/<name>/recipe.yaml` — every v7+ recipe ships with platform-specific defaults.

Map recipe defaults → `evidence-contract.md` sections:

| Recipe key | Contract section |
|------------|--------------------|
| `platform` | Section 1 Target Launch Platforms |
| `valid_proof_sources` | Section 2 per-platform valid proof |
| `invalid_proof_sources` | Section 3 per-platform anti-proof |
| `required_larp_scope` | Section 4 Required Runtime LARP per readiness state |
| `required_static_evidence` | Section 5 Required Static Evidence |
| `required_live_service_evidence` | Section 6 Required Live-Service Evidence |
| (derived from readiness states) | Section 7 Readiness State Gate Criteria |

If no recipe metadata is found → infer platform from `architecture.md` ("iOS app" → mobile, "Next.js" → web, etc.) and use the corresponding recipe's defaults. Document the inference in the catch-up plan.

Apply skeptical-review for the third-party risk surface section if the project integrates with paid services (Stripe, Clerk, Firebase, etc.). Use the patterns library (`.speck/patterns/library/`) to pull integration-specific risk language.

Remove the scaffold banner. SHA-stamp.

### Phase 3 — Reconstruct `project-decisions-log.md`

Mine git history for decisions that should have been logged at the time. Look for commits matching:

- `feat(architecture):` / `docs(architecture):` → architecture decisions
- `feat(design-system):` / `docs(design-system):` → design-system decisions
- `feat(plan):` / `docs(plan):` → planning decisions
- `feat(epic-*):` / `docs(epic-*):` → epic-level locks
- Any commit with `ARCH:` or `PATTERN:` or `RULE:` learning tags

For each meaningful decision in git history:

1. Run `/speck-decision-log` to append an entry
2. Set `phase: <inferred>` (architecture / design-system / plan / epic-N)
3. Set `date: <commit date>`
4. Set `sha: <commit sha>`
5. Set `status: locked` (it shipped — it's locked retroactively)
6. Set `alternatives: [reconstructed: "(not documented at the time)", + at least 2 plausible alternatives a reasonable team would have considered]`
7. Set `rationale: <commit message body, or "see commit <sha> for context">`

This produces a **honest** retroactive log: the entries are clearly marked as reconstructed (in the `consequences` field: *"This decision was logged retroactively during v6→v7 catch-up; original alternatives may not match what was actually considered."*). Better than nothing — at least future agents have a starting point.

### Phase 4 — Backfill epic-level v7 artifacts

For each existing epic at `epics/E###-*/`:

1. **If UI epic AND `experience-chain.md` missing**:
   - Synthesize from existing `user-journey.md` + `wireframes.md` (if either exists) + epic's story specs
   - If no UX docs exist at all → write a minimal `experience-chain.md` listing each story's screen and add a P1 entry to `project-catch-up-plan.md` for human review
2. **If `epic-architecture.md` is missing but the epic was cross-cutting** → don't backfill (it's optional); just note it
3. SHA-stamp every new epic-level artifact

### Phase 5 — Honesty pass on completed stories (THE IMPORTANT ONE)

For each story at `stories/S###-*/` with a v6 `validation-report.md` marked `PASS`:

1. Read `validation-report.md`
2. Read the corresponding `evidence-contract.md` (now filled in from Phase 2)
3. Cross-reference:

| Check | Question | If FAIL |
|-------|----------|---------|
| Runtime LARP evidence | Are there checked-in screenshots / recordings from the **target build** (not dev server)? | Lower readiness from `PASS` to `IMPL-GREEN`; add P0 to catch-up plan |
| Surrogate proof | Were the screenshots taken on the wrong platform (browser for iOS, etc., per `evidence-contract.md` Section 3)? | Lower readiness to `IMPL-GREEN`; add P0 |
| Audit report | Is there an `audit-report.md` from `/audit`? | Lower readiness to `IMPL-GREEN`; add P1 |
| User-reachability | Does the validation report explicitly answer "can a real user reach this feature"? | If no → flag P1 |
| Banned-language scan | Does the implementation use user-facing strings flagged by `banned-language-lint.sh`? | Flag P2 |

For every story that fails any check: **rewrite the validation-report.md** to declare the actual current state honestly (almost always `IMPL-GREEN`, sometimes `UX-RC` if there's partial evidence). Add a section "## Catch-Up Downgrade" explaining the rewrite.

This is the most important part of the skill. **Do not skip it.** Honest downgrade is the foundation of v7 — the project can't catch up if it can't see its own current state truthfully.

### Phase 6 — Regenerate `project-state.md`

Now that Phases 1-5 have produced the real picture, regenerate `project-state.md` via `/project-state` (or invoke the project-state skill directly). The new state reflects:

- Current readiness state per epic/story (post-honesty-pass)
- Blocking issues from the catch-up plan
- Open questions from `[NEEDS USER REVIEW]` markers in `product-contract.md`
- Next action: "Work through `project-catch-up-plan.md`"

### Phase 7 — Write `project-catch-up-plan.md`

This is the deliverable the user actually consumes. Format:

```
# Project Catch-Up Plan

Generated by `/speck-catch-up` on <DATE> during v6 → v7 migration.

## Status

- Stories downgraded from PASS to IMPL-GREEN: N
- Stories needing re-LARP with platform-correct evidence: M
- Sections in product-contract.md flagged [NEEDS USER REVIEW]: K
- UI epics missing experience-chain.md: J

## P0 — Immediate (blocking ship claim)

For each P0 item:
- [ ] **Story S###-name**: <what's missing>. Currently claims `<readiness>`; actual is `IMPL-GREEN`. To fix: <action>.

## P1 — High (needed for honest UX-RC claim)

For each P1 item: …

## P2 — Medium (catches sloppy v6 patterns)

For each P2 item: …

## P3 — Low (housekeeping)

For each P3 item: …

## Next session

1. Review `product-contract.md` sections marked [NEEDS USER REVIEW]
2. Work through P0 items
3. Re-run `/recheck` to confirm catch-up progress
```

SHA-stamp this file.

### Phase 8 — Clean up

1. Delete the migration marker (if present): `rm .speck/.migration-needs-catchup`
2. Re-run `/recheck` to confirm the project is no longer in scaffold state
3. Update `project-state.md` final paragraph: "Catch-up complete. Resume normal v7 workflow."

### Phase 9 — Report

```
🥓 /speck-catch-up complete for <PROJECT_ID>

Reconstructed:
  ✓ product-contract.md  (with K sections needing review)
  ✓ evidence-contract.md (from recipe `<name>` defaults)
  ✓ project-decisions-log.md (Y entries from git history)
  ✓ J UI epics now have experience-chain.md

Honesty pass:
  ⚠️  N stories downgraded from PASS → IMPL-GREEN (no runtime LARP evidence)
  ⚠️  M stories had surrogate proof; flagged for re-validation
  ⚠️  P stories missing /audit report; flagged

Output:
  - project-catch-up-plan.md (your remediation list, prioritized)
  - project-state.md (now reflects reality, not v6 optimism)

Recommended next:
  - Open project-catch-up-plan.md and triage P0 items
  - Run /story-validate with /larp on each downgraded story to climb back to UX-RC
  - Review [NEEDS USER REVIEW] markers in product-contract.md
```

## Subagent Parallelization

Triage phase parallelism:

```
├── [Parallel] speck-explorer: directory listings
├── [Parallel] speck-scanner: project.md, PRD.md, ux-strategy.md
├── [Parallel] speck-scanner: architecture.md, design-system.md
├── [Parallel] speck-scanner: every epic.md + most recent validation-report.md
├── [Parallel] speck-scanner: git log mining
└── [Wait] → triage table
```

Phase 5 (honesty pass) parallelism:

```
For each story in parallel (cap at 5 concurrent):
├── [Parallel] speck-auditor: cross-reference validation-report.md vs evidence-contract.md
└── [Wait] → batch all downgrades, write at end
```

## Behavior Rules

- **NEVER** silently rewrite a `validation-report.md` from `PASS` to `IMPL-GREEN` without leaving a "## Catch-Up Downgrade" section explaining why
- **NEVER** invent a magic moment or differentiator if the v6 docs don't contain one — mark `[NEEDS USER REVIEW]` instead
- **NEVER** delete v6 artifacts; this is brownfield reconstruction, not replacement
- **NEVER** mark a story as `UX-RC` or higher unless there's actually checked-in runtime evidence; the floor for migrated stories is `IMPL-GREEN`
- **ALWAYS** apply SHA stamps after each reconstructed artifact
- **ALWAYS** invoke `/speck-decision-log` for the reconstruction decisions themselves
- **ALWAYS** produce `project-catch-up-plan.md` — even if nothing needs catching up, write the file saying "No catch-up needed; project shipped clean v7 from migration."
- **ALWAYS** require user confirmation before Phase 5 (the honesty pass) if running in non-CI context

## Idempotency

Safe to re-run. If `product-contract.md` no longer has the scaffold banner → skip Phase 1 (already filled). Same for each phase. Re-running ONLY processes what's still in scaffolded state.

## Context: $ARGUMENTS
