---
name: speck-catch-up
description: Drive a migrated v6 project to v7-clean reality. v6→v7 migration only scaffolds empty template artifacts; this skill does the brownfield work — backfills product-contract and evidence-contract from existing v6 docs, reconstructs project-decisions-log from git history, downgrades over-optimistic readiness claims on already-shipped stories, re-audits past validation reports for surrogate proof, and writes project-catch-up-plan.md with prioritized remediation work. Supports phased invocation (--phase=triage|contracts|decisions|epic-artifacts|honesty|state|plan|finalize|all) so large brownfield projects can checkpoint between sessions. Load on engagement when project-state.md / product-contract.md / evidence-contract.md are still in their scaffolded-but-empty state (banner intact), or when the user explicitly says "catch up", "bring this project up to v7", "/speck-catch-up", or after a fresh migration run.
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

## Phased Invocation

Catch-up runs in **9 phases** (P0–P8). On large brownfield projects the full sequence is too much work for one session; on small projects running it end-to-end is fine. Phases are independently checkpointable + commitable.

Parse `$ARGUMENTS` for `--phase=<name>`. Default is `--phase=all`.

| Phase argument | What runs | Output | Typical effort |
|----------------|-----------|--------|----------------|
| `--phase=triage` | Phase 0 only — engagement inventory + scale read | `migration-estimate.md` | 2–5 min |
| `--phase=contracts` | Phases 1+2 — backfill product-contract + evidence-contract | both filled | 10–30 min |
| `--phase=decisions` | Phase 3 — reconstruct decisions log from git history | `project-decisions-log.md` populated | 5–15 min |
| `--phase=epic-artifacts` | Phase 4 — backfill experience-chain-historical for each UI epic | one stub per UI epic | 5–10 min |
| `--phase=honesty` | Phase 5 — honesty pass on shipped stories (5a or 5b auto-detected) | downgraded validation reports | 15 min – hours |
| `--phase=state` | Phase 6 — regenerate project-state.md | refreshed project-state | 2 min |
| `--phase=plan` | Phase 7 — write project-catch-up-plan.md | the remediation plan | 5 min |
| `--phase=finalize` | Phase 8 — clean up marker + re-recheck | marker removed | 1 min |
| `--phase=all` (default) | All phases 0 → 8 | everything | varies |

**Recommended flow for large brownfield projects** (e.g., 10+ epics, multi-platform):

```
Session 1 (planning):  /speck-catch-up --phase=triage    → commit
Session 2 (foundation): /speck-catch-up --phase=contracts → commit
Session 3 (history):   /speck-catch-up --phase=decisions  → commit
Session 4 (UI surface): /speck-catch-up --phase=epic-artifacts → commit
Session 5 (truth):     /speck-catch-up --phase=honesty    → commit (this is the heavy one)
Session 6 (close):     /speck-catch-up --phase=state --phase=plan --phase=finalize → commit
```

Each commit produces a reviewable, revertible chunk. For small brownfield projects (1–3 epics, no shipped validation reports), `--phase=all` in one session is fine.

## When to Run

Run automatically when ANY of these is true (the agent should detect on engagement):

1. `product-contract.md` exists and contains the literal banner `<!-- v7 MIGRATION SCAFFOLD -->`
2. `evidence-contract.md` exists and contains the same banner
3. `project-state.md` exists and contains the same banner
4. `.speck/.migration-needs-catchup` marker file exists at workspace root
5. User explicitly says "catch up", "bring this project up to v7", "/speck-catch-up", "the migration scaffolded the artifacts but they're empty"
6. Agent runs `/recheck` and report shows >50% of truth artifacts in scaffold state OR `check-replace-markers.sh` flags un-filled tokens in truth artifacts

**Block any new feature work** (no `/story-implement`, no `/epic-plan`, etc.) until catch-up is complete. The agent should refuse with: *"This project is fresh from v6→v7 migration. The v7 truth artifacts are still empty scaffolds. Run `/speck-catch-up` first."*

## Prerequisites

- Project at `specs/projects/<id>/` exists
- Migration has run (i.e., `migration-report.md` is present at project root)
- Git history is available (most reconstruction comes from commits)
- Project has at least: `project.md`, `PRD.md` (Build/Platform) OR `sprint-log.md` (Sprint)

If those minimal v6 docs are missing, tell the user: *"This project doesn't have enough v6 history to catch up automatically. Either restore the v6 docs or treat this as a fresh `/project-specify` start."* and STOP.

## Execution

Execute the requested phase(s) in order. Phase 0 always runs first (cheap; informs scope). If `--phase=all`, run 0→8 in sequence.

### Phase 0 — Triage + Estimate (always runs)

Dispatch parallel subagents:

```
├── [Parallel] speck-explorer: List specs/projects/<id>/**/*.md (full inventory)
├── [Parallel] speck-scanner: Read project.md, PRD.md, ux-strategy.md (if present),
│                              domain-model.md (if present), constitution.md (if present)
├── [Parallel] speck-scanner: Read architecture.md, design-system.md, design-system/primitives.md
├── [Parallel] speck-explorer: Find every epic.md and the most recent validation-report.md
├── [Parallel] speck-explorer: List every screenshots/ directory and inventory what's checked in
├── [Parallel] speck-scanner: git log --since=1.year --pretty=oneline -- specs/projects/<id>/
│              (extract major decisions: architecture, plan, design-system commits)
├── [Parallel] speck-explorer: Find ship docs (docs/archive/ship/SHIP_R*.md, docs/release/*.md,
│              docs/ship-rounds/*.md, RELEASES.md) — these are v6's ship-readiness record
└── [Wait] → Build a project-state-as-of-engagement table + the validation-discovery
            sub-mode that Phase 5 will use
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
| Stories | count | how many marked complete? |
| Story-level `validation-report.md` files | count | (informs Phase 5 mode) |
| Ship docs (`docs/**/SHIP_R*.md` etc.) | count | (informs Phase 5 mode) |
| Active recipe | from `.speck/project.json` or `project.md` | name |
| Recipe stack match | % | 100 = clean, <70 = manual evidence rules needed |
| Banned-language present in user-facing strings | scan | hit count |

**Detect the Phase 5 sub-mode** (per F1):

| Condition | Phase 5 mode |
|-----------|--------------|
| ≥1 `stories/**/validation-report.md` exists with `PASS` | `5a` — per-story honesty walk |
| 0 story-level reports BUT ≥1 ship doc with readiness claims | `5b` — per-feature-area floor at IMPL-GREEN + LARP-required list |
| 0 of either | `5c` — no honesty pass needed (project never claimed readiness) |

Record the chosen mode in `migration-estimate.md` so the user sees what's about to happen.

### Phase 0 deliverable — write `migration-estimate.md`

After the triage table, write `specs/projects/<id>/migration-estimate.md`:

```markdown
# Migration Estimate

Generated by `/speck-catch-up --phase=triage` on <DATE>.

## Engagement Triage

<the table above>

## Phase 5 mode

<5a | 5b | 5c> — <one-line explanation>

## Effort estimate

| Phase | Estimated time | What gets done |
|-------|----------------|----------------|
| Phase 1 — Backfill product-contract.md | ~15 min | Source mapping from <list of v6 docs found> |
| Phase 2 — Backfill evidence-contract.md | ~10 min (recipe `<name>` matches <X>%) | … |
| Phase 3 — Reconstruct decisions log | ~<N> min (<M> candidate commits) | … |
| Phase 4 — experience-chain-historical for <K> UI epics | ~<K × 5> min | … |
| Phase 5 — Honesty pass (mode <5a/5b/5c>) | <see below> | … |
| Phase 6 — Regenerate project-state | ~2 min | … |
| Phase 7 — Write catch-up plan | ~5 min | … |
| Phase 8 — Finalize | ~1 min | … |

### Phase 5 effort detail

For 5a: <N> stories × ~5 min = <N×5> min
For 5b: <N> feature areas × ~10 min for floor claim, plus <M> magic moments × ~20 min LARP = <…>
For 5c: 0 effort

## Post-catch-up remediation backlog (in catch-up-plan.md)

The work catch-up DOES NOT do (defers to user via P0/P1/P2/P3 list):

| Category | Estimated count | Estimated effort |
|----------|-----------------|------------------|
| Stories needing re-LARP with valid evidence | <N> | <hours> |
| Magic moments needing new LARP | <N> | <hours> |
| UI epics with `experience-chain-historical.md` to convert to full chain | <N> | <hours, but deferred to re-validation time — see F10> |
| Sections marked `[NEEDS USER REVIEW]` | <N> | <minutes per> |
| Real third-party-service evidence runs (auth, billing, AI APIs) | <N> | <hours> |

**Total reconstruction effort (this skill)**: <minutes>
**Total remediation backlog (deferred to catch-up plan)**: <hours/days>
```

SHA-stamp the file.

If `--phase=triage`, STOP here. Tell the user: *"Triage complete. Review `migration-estimate.md`, then run `/speck-catch-up --phase=contracts` to start the reconstruction. You can also run `--phase=all` to do everything at once if the estimate is small."*

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

**Skeptical-review primitive applies** to every locked decision. For each section, if the v6 docs give a clear unambiguous answer → fill it. If there's ambiguity or no source → enumerate N≥3 alternatives, mark the section `[NEEDS USER REVIEW]`, and add a row to `project-catch-up-plan.md`. **Replace** every `REPLACE_BEFORE_SHIP:` token; do not leave any in a "filled" artifact.

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

Read the recipe's `evidence_contract:` block from `.speck/recipes/<name>/recipe.yaml` — every v7+ recipe ships with platform-specific defaults. If the recipe declares `extends: <base-recipe>`, walk the chain and shallow-merge the defaults (see `.speck/recipes/README.md` for the overlay semantics added in v7.2).

Map recipe defaults → `evidence-contract.md` sections (see the template's mapping table).

If no recipe metadata is found → infer platform from `architecture.md` ("iOS app" → mobile, "Next.js" → web, etc.) and use the corresponding recipe's defaults. Document the inference in the catch-up plan.

**Hybrid stack handling (per F2)**: if `architecture.md` mentions multiple platforms (e.g., "React + FastAPI + Capacitor iOS"), look for the matching composed recipe first (e.g., `capacitor-wrapped-web`). If none exists, manually splice in per-platform sections and add a P3 row to `project-catch-up-plan.md`: "Consider authoring a `<stack-name>` recipe."

Apply skeptical-review for the third-party risk surface section if the project integrates with paid services (Stripe, Clerk, Firebase, etc.). Use the patterns library (`.speck/patterns/library/`) to pull integration-specific risk language.

Remove the scaffold banner. **Replace** every `REPLACE_BEFORE_SHIP:` token. SHA-stamp.

### Phase 3 — Reconstruct `project-decisions-log.md`

**Uncomment the canonical catch-up caveat block** in the template (per F5). It's wrapped in `<!-- CATCH-UP-ONLY: ... -->`; remove the wrapper so the caveat renders as visible content.

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
5. Set `status: locked`
6. **Set `Reconstructed: true`** and add `Reconstructed from: <git ref(s)>` line (the canonical caveat block at the top of the log explains what this means)
7. Set `alternatives: [<at least 2 plausible alternatives a reasonable team would have considered, marked clearly as plausible reconstructions>]`
8. Set `rationale: <commit message body, or "see commit <sha> for context">`

The canonical caveat block (uncommented from the template) makes the retroactive-hypothesis framing explicit at the top of the log; the per-entry `Reconstructed: true` flag makes each entry searchable.

### Phase 4 — Backfill epic-level v7 artifacts

For each existing epic at `epics/E###-*/`:

1. **If UI epic AND `experience-chain.md` missing**:
   - **Default for pre-v7 epics: scaffold `experience-chain-historical.md`** from the brownfield template (`.speck/templates/epic/experience-chain-historical-template.md`).
     - Populate "Shipped screens" from story specs + git history
     - Mark `brownfield_exempt: true` in the frontmatter
     - This satisfies the `/epic-plan` requirement without requiring full chain reverse-engineering at catch-up time
     - `/epic-validate` will generate the full `experience-chain.md` when the epic is re-validated (deferred-generation pattern)
   - **Exception — if `user-journey.md` AND `wireframes.md` BOTH exist** (rare, but ideal): generate the full `experience-chain.md` instead of the historical stub
2. **If `epic-architecture.md` is missing but the epic was cross-cutting** → don't backfill (it's optional); just note it
3. **Replace** every `REPLACE_BEFORE_SHIP:` token in the generated artifact
4. SHA-stamp every new epic-level artifact

### Phase 5 — Honesty pass on completed stories

Use the **Phase 5 sub-mode** determined in Phase 0.

#### Mode 5a — Story-level validation reports exist

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

#### Mode 5b — Ship docs are the only readiness record

For each ship doc found in Phase 0 (e.g., `docs/archive/ship/SHIP_R*.md`):

1. Extract claimed feature areas + their declared readiness state
2. Find the epic/stories each feature area maps to (best-effort via name match)
3. **Apply the floor at the feature-area surface, not per story**:
   - Default readiness post-catch-up: `IMPL-GREEN` for each implicated epic
   - Exception: if the ship doc explicitly cites checked-in evidence files that exist and meet the `evidence-contract.md` rules → may stay at `UX-RC`
4. Write a `catch-up-honesty-pass.md` at project root that lists:
   - Feature area → claimed ship state → post-catch-up state → reason for downgrade
   - Per magic moment in `product-contract.md`: add a P0 row "Run `/larp <persona>` against built artifact to climb back to UX-RC"
5. Do NOT rewrite individual story validation reports (there aren't any)
6. Surface the disclosure plainly in `project-state.md`

#### Mode 5c — No honesty pass needed

Project never claimed readiness (no story validation reports, no ship docs). Skip Phase 5 entirely and note in `project-catch-up-plan.md`: *"This project ships under v7 standards from here on; no historical claims required downgrading."*

#### Common to all modes

**Do not skip Phase 5.** It's the foundation of v7 honesty — the project can't catch up if it can't see its own current state truthfully. Mode 5c is the only no-op path, and only applies when there were no claims to honest.

### Phase 6 — Regenerate `project-state.md`

Now that Phases 1–5 have produced the real picture, regenerate `project-state.md` via `/project-state` (or invoke the project-state skill directly). The new state reflects:

- Current readiness state per epic/story (post-honesty-pass)
- Blocking issues from the catch-up plan
- Open questions from `[NEEDS USER REVIEW]` markers in `product-contract.md`
- Outstanding `REPLACE_BEFORE_SHIP:` markers across all truth artifacts (auto-populated appendix)
- Next action: "Work through `project-catch-up-plan.md`"

### Phase 7 — Write `project-catch-up-plan.md`

This is the deliverable the user actually consumes. Format:

```markdown
# Project Catch-Up Plan

Generated by `/speck-catch-up` on <DATE> during v6 → v7 migration.

## Status

- Phase 5 mode: <5a | 5b | 5c>
- Stories downgraded from PASS to IMPL-GREEN: N
- Feature areas floored at IMPL-GREEN (mode 5b only): F
- Stories needing re-LARP with platform-correct evidence: M
- Sections in product-contract.md flagged [NEEDS USER REVIEW]: K (see project-state.md appendix)
- REPLACE_BEFORE_SHIP markers remaining: T (see project-state.md appendix)
- UI epics now carrying experience-chain-historical.md (deferred to re-validation): J

## P0 — Immediate (blocking ship claim)

- [ ] Review `product-contract.md` sections marked [NEEDS USER REVIEW]
  - List each section + recommended resolution path
- [ ] For each magic moment in product-contract.md: run `/larp <persona>` against built artifact
- [ ] <other P0 items from Phase 5 honesty pass>

## P1 — High (needed for honest UX-RC claim)

- [ ] Per-story re-LARP for downgraded stories
- [ ] <other P1 items>

## P2 — Medium (catches sloppy v6 patterns)

- [ ] <items>

## P3 — Low (housekeeping)

- [ ] Convert `experience-chain-historical.md` to full chains during next `/epic-validate` per epic
- [ ] <items>

## Next session

1. Review `product-contract.md` sections marked [NEEDS USER REVIEW]
2. Work through P0 items
3. Re-run `/recheck` to confirm catch-up progress
```

SHA-stamp this file.

### Phase 8 — Clean up

1. Remove this project's entry from the marker file: `sed -i.bak "\\|^$PROJECT_DIR$|d" .speck/.migration-needs-catchup` (keep the file if other projects still need catch-up; delete entirely if empty)
2. **Run `/project-readme`** — repair legacy Speck-marketing README if present and populate from backfilled contracts
3. Re-run `/recheck` to confirm the project is no longer in scaffold state
4. Update `project-state.md` final paragraph: "Catch-up complete. Resume normal v7 workflow."

### Phase 9 — Report

```
🥓 /speck-catch-up complete for <PROJECT_ID>

Mode: <5a/5b/5c> (selected based on what readiness records were found)

Reconstructed:
  ✓ product-contract.md  (with K sections needing review)
  ✓ evidence-contract.md (from recipe `<name>` defaults)
  ✓ project-decisions-log.md (Y entries from git history, marked Reconstructed: true)
  ✓ J UI epics now have experience-chain-historical.md (deferred full chain to re-validation)

Honesty pass (mode <5a/5b>):
  ⚠️  N stories downgraded from PASS → IMPL-GREEN (no runtime LARP evidence)
  ⚠️  M stories had surrogate proof; flagged for re-validation
  ⚠️  P stories missing /audit report; flagged
  (or F feature areas floored at IMPL-GREEN for mode 5b)

Output:
  - migration-estimate.md (what catch-up planned to do)
  - project-catch-up-plan.md (your remediation list, prioritized)
  - project-state.md (now reflects reality, not v6 optimism)
  - <K> [NEEDS USER REVIEW] markers surfaced in project-state.md appendix

Recommended next:
  - Open project-catch-up-plan.md and triage P0 items
  - Resolve [NEEDS USER REVIEW] markers in product-contract.md (start in project-state.md appendix)
  - Run /story-validate with /larp on each downgraded story (or per-feature for 5b) to climb back to UX-RC

🔁 Optional: run `npx speck feedback` to share what worked / what didn't with the Speck team.
```

## Subagent Parallelization

See the original parallelism layouts in Phase 0 and Phase 5. Each phase is independently parallelizable.

## Behavior Rules

- **NEVER** silently rewrite a `validation-report.md` from `PASS` to `IMPL-GREEN` without leaving a "## Catch-Up Downgrade" section explaining why
- **NEVER** invent a magic moment or differentiator if the v6 docs don't contain one — mark `[NEEDS USER REVIEW]` instead
- **NEVER** delete v6 artifacts; this is brownfield reconstruction, not replacement
- **NEVER** mark a story as `UX-RC` or higher unless there's actually checked-in runtime evidence; the floor for migrated stories is `IMPL-GREEN`
- **NEVER** leave `REPLACE_BEFORE_SHIP:` tokens in any artifact you've "filled" — replace every one or surface the section as `[NEEDS USER REVIEW]`
- **ALWAYS** apply SHA stamps after each reconstructed artifact
- **ALWAYS** invoke `/speck-decision-log` for the reconstruction decisions themselves
- **ALWAYS** produce `project-catch-up-plan.md` — even if nothing needs catching up, write the file saying "No catch-up needed; project shipped clean v7 from migration."
- **ALWAYS** require user confirmation before Phase 5 (the honesty pass) if running in non-CI context AND mode is 5a (per-story rewrites) — mode 5b downgrades are surface-level and may proceed
- **ALWAYS** auto-detect which Phase 5 sub-mode to run (5a/5b/5c) based on what's on disk — don't ask the user

## Idempotency

Safe to re-run. If `product-contract.md` no longer has the scaffold banner → skip Phase 1 (already filled). Same for each phase. Re-running ONLY processes what's still in scaffolded state. The `--phase=<name>` argument also lets the user explicitly target one phase even if others appear complete.

## Context: $ARGUMENTS
