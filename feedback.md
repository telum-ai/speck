# Speck Feedback — E000 execution arc (post-7-story epic close)

**Date**: 2026-05-26
**Speck version (workspace)**: v7.9.1 (v7.4 → 7.5.1 → 7.5.2 → 7.6 → 7.7 → 7.8 → 7.9.1 across the arc)
**Repo HEAD**: `274eed7` on branch `main`
**Workspace**: `flyt` (Platform-level project; first epic E000 — Developer Infrastructure — closed)

---

## TL;DR

E000 shipped 7 stories in ~2 days (vs 7-day Phase 0 budget; ~3.5× under). Speck's discipline held — `/story` chain validated end-to-end, retro discipline produced compounding learnings, and **two round-trip feedback cycles landed shipped framework features in the same session** (v7.8.0 fixed `.speck/feedback/2026-05-25-hooks.md`; v7.9.1 fixed `.speck/feedback/2026-05-25-validators.md`).

This file consolidates **6 new observations** that surfaced during E000 execution and aren't covered by prior feedback files. Three are concrete template improvements (proven gaps); two are skill-orchestration clarity asks; one is a methodology acknowledgment worth highlighting.

---

## Observation 1: `epic-tech-spec-template.md` § "Technology Stack" lacks version-freshness check

**Surfaced in**: S001 (Next.js 15→16 drift), S004 (dual @typescript-eslint 8.59 vs 8.60), S005 (Sentry SDK 8 `ErrorEvent` type change vs my planned `Event`)

**What happened**: epic-tech-spec.md pinned versions from training-data snapshots (Oct 2024 era). At 2026-05-26 reality, Next.js had shipped to 16.x, @sentry/nextjs had narrowed `beforeSend` to `ErrorEvent`, and Node 20 was deprecating-in-GHA. Each of these caused 1+ PR-debug commits.

**Cost**: ~45 min cumulative across the 3 affected stories. 6 of S003's 10 debug commits trace to this class.

**Proposal**: add a "Version-Pin Freshness Check" sub-step to `epic-tech-spec-template.md` § "Technology Stack" with literal command:

```bash
# Run for each pinned tool BEFORE committing the tech spec:
for pkg in next typescript @sentry/nextjs vitest @playwright/test eslint; do
  echo "$pkg: $(npm view $pkg version)"
done
```

…and a normative rule:

> Version pins in this section MUST be validated against `npm view` (or the equivalent for non-npm tools) within 7 days of the tech spec being authored. Training-data snapshots cannot be trusted for fast-moving tooling.

**Impact**: Would have prevented 6 of S003's 10 debug commits + 2 in S005 + 1 in S001.

---

## Observation 2: `tasks-template.md` verification step doesn't include `typecheck`

**Surfaced in**: S004 (TS5097 .ts extension + TS2345 dual-version both passed Vitest locally; tsc-strict caught at PR CI)

**What happened**: My T017 verification followed the template pattern: `pnpm install + lint + test + build`. Vitest's esbuild loader strips types — strict-mode errors don't surface until `tsc --noEmit` runs. PR CI's separate Typecheck step caught them and I needed a fix-commit.

**Cost**: ~20 min PR-debug arc

**Proposal**: update `tasks-template.md` § "Verification" pattern to always include typecheck alongside test + lint:

```markdown
## Phase N: Verification

- [ ] T0XX Local verify: install + lint + typecheck + test + build green

\`\`\`bash
pnpm install                  # workspace resolves
pnpm --filter web typecheck   # tsc --noEmit (Vitest esbuild masks strict errors!)
pnpm --filter web lint        # ESLint clean
pnpm --filter web test        # Vitest passes
pnpm --filter web build       # Next.js (or equivalent) green
\`\`\`

**Why typecheck explicitly**: Vitest's esbuild loader strips types — strict-mode TS errors (TS5097, TS2345, etc.) only surface at `tsc --noEmit`. Skipping typecheck locally means CI catches what should have been a local pre-push fix.
```

**Impact**: Trivial template addition; eliminates a recurring PR-debug class.

---

## Observation 3: `/story` skill orchestration — auto-invoke vs manual-drive ambiguity

**Surfaced in**: Every story (S001-S007). The `/story` skill text describes a 9-step chain (`/story-specify → /story-clarify → /story-plan → ...`) but doesn't actually invoke sub-skills via the Skill tool. I drove each step manually with Read/Write/Bash/Edit.

**Observation**: this worked great (cold-start agent productivity was high), but it's not clear from the `/story` description whether:
- (a) The agent is **expected** to drive sub-steps manually (current behavior — works fine)
- (b) Sub-skills should be **auto-invoked** via the harness (which would re-load each template fresh + add structure)
- (c) Either pattern is acceptable

**Cost**: Zero (manual drive worked), but ~5 min reading the skill description to confirm intent.

**Proposal**: add a single sentence to `/story` skill description:

> **Driving pattern**: This skill orchestrates the chain via direct file-write/edit/bash by the agent. Sub-skills (`/story-specify`, `/story-plan`, etc.) are NOT auto-invoked — the agent follows the transition map in `### 3. Execution Loop` and produces each artifact directly. This keeps context efficient (each sub-skill's template doesn't reload per step) while preserving the canonical artifact shape.

Same clarification would help `/epic-plan`, `/epic-breakdown`, `/epic-validate`, `/epic-retrospective`.

---

## Observation 4: Validator-vs-content drift (V6 + V7 from `.speck/feedback/2026-05-25-validators.md`) — verify v7.9.1 round-trip

**Already filed**: V1-V5 in the prior file shipped as v7.9.1. V6 (validate-artifact-docs hard-checks Speck-shipped names not in user AGENTS.md) and a new V7-class (Validate Speck Recipes doesn't walk `extends:` chain) were marked `continue-on-error: true` in `speck-validation.yml`.

**Status check needed**: Does v7.9.1 also fix these? If yes, I should remove the `continue-on-error: true` overrides post-verification. If no, they remain deferred.

**Proposal**: at the next `speck upgrade`, the upgrade output should explicitly list which previously-filed feedback items it addresses. Format:

```
✅ Upgraded from v7.8.0 to v7.9.1
   Addresses feedback:
   - V1 (pre-commit-hook empty-array) — fixed
   - V2 (multi-line bracket regex) — fixed
   ...
   - V6 (validate-artifact-docs smart-merge gap) — DEFERRED to v7.10+
```

This closes the round-trip loop visibly: the user knows which `continue-on-error` overrides they can now drop.

---

## Observation 5: Round-trip discipline is working (acknowledgment, not complaint)

**Two cycles in this session**:

| Feedback file | Filed | Shipped | Round-trip time |
|---|---|---|---|
| `2026-05-25-hooks.md` (4 proposals: bash-type Stop hook + SPECK markers + drift detection + upgrade reconciler) | 2026-05-25 AM | v7.8.0 same day | ~6h |
| `2026-05-25-validators.md` (5 V-series gaps + 4 inline patches) | 2026-05-25 PM | v7.9.1 same session | ~hours |

This is **extraordinary methodology velocity** — feedback files literally informed shipped framework versions in the same workday. The pattern that makes it work:

1. Feedback files include CONCRETE inline patches with diffs (not just descriptions)
2. Proposals are numbered (H1/H2/H3/H4, V1/V2/V3/V4/V5/V6) so the maintainer can ship by ID
3. Each finding is documented with: symptom + reproduction + root cause + diff + proposed upstream fix

**Suggestion**: capture this as the canonical feedback-file template (`.speck/templates/feedback/template.md`?). New users would benefit from the structure that produced this velocity.

---

## Observation 6: Constitution-as-code substrate (S004) — worth canonical pattern doc

**What happened**: S004 shipped 8 ESLint rules + banned-language CI step that mechanically enforce Constitution Principle III (Norwegian-Native) + Principle VIII (Theme-able / No Hardcoded Colors) + DEC-0034 Bold Choices on every PR. Total cost: ~75 min focused work. Permanent value: every E001+ commit gets free constitutional checks; structural prevention of drift that AI-paired authoring would otherwise reintroduce.

**Observation**: This is the **highest-leverage substrate of E000** (per epic-retro). For any Platform-level project with explicit constitutional principles, this pattern should be canonical:

```
constitution.md Principles
  ↓
custom ESLint rules / banned-language scan / runtime hooks
  ↓
CI gates on every PR
  ↓
Mechanical drift-prevention (vs honor-system)
```

**Proposal**: add a Platform-archetype-specific section to `.speck/templates/epic/epic-template.md` (or a new `.speck/patterns/constitution-as-code.md` document) describing:

- When to use: Platform-level projects with ≥2 binding constitution principles that are textually-detectable (banned terms, hardcoded values, structural patterns)
- How to use: ESLint custom plugin pattern (see `apps/web/eslint-plugin-flyt/` in Flyt for reference)
- Verification: pass-fixture-first authoring; RuleTester adversarial probe per rule
- Cost benchmark: ~10 min/rule for simple substring/AST patterns; ~30 min/rule for stateful rules requiring imports + context

**Impact**: future Platform projects would default to this pattern. Reduces "constitution drift" risk class systemically.

---

## Bonus: minor observations

### Speck CLI quality-of-life

- `npx github:telum-ai/speck@latest check` silently returned no output (auto-mode classifier blocked something quietly); `npx github:telum-ai/speck check` worked. Suggest: better error surfacing for blocked invocations.
- `speck-cli organizations list` (via underlying SDK call) crashes with a JSON parse error: `missing field requireEmailVerification`. Server-API drift caught Speck's bundled CLI off-guard. Not blocking but worth a version pin tightening.

### Pre-commit hook scope discipline

S007 lint-staged config worked at workspace root with Husky. Documented inline. But the `bash -c '... "$@"' _` shim pattern for invoking `banned-language-lint.sh` (which takes PROJECT_DIR + variadic files) was non-obvious. Consider: ship a `.speck/scripts/banned-language-lint-staged.sh` wrapper that already encodes the PROJECT_DIR-detection, so user pre-commit configs can just call it with appended file list.

### Branch protection paywall

GitHub Pro is required for private-repo branch protection ($4/mo). For Speck workspaces that recommend branch protection, the docs could flag this gating upfront so users budget for it. E000 S007 deferred AC-3/4 cleanly with documented one-shot apply.

---

## Methodology meta-observation

Across `.speck/feedback/2026-05-25-{migration,methodology,hooks,validators}.md` + this file: this is the **5th feedback file in the workspace**. Each landed in `.speck/feedback/` (gitignored), captured CONCRETE proposals, and (for hooks + validators) round-tripped to shipped framework versions same session.

This is methodology working. The compounding discipline:

1. Feedback file → inline patches → upstream PR/issue → shipped framework version
2. Story-retro → epic-retro → project-retro escalation chain
3. Commit gotcha-tags (now enforced by v7.9.0 `commit-msg-hook.sh`) → cold-start-agent friendly history

The Speck team should feel encouraged: feedback velocity is **producing** velocity. The 7-story-in-2-days E000 wouldn't have been possible without the v7.8 hooks fix mid-session, and the v7.9.1 validator fix unblocked S004 + S005.

---

## Concrete proposals summary (prioritized)

| # | Proposal | Effort | Impact |
|---|----------|--------|--------|
| **P1** | Version-Pin Freshness Check in `epic-tech-spec-template.md` § Tech Stack | Trivial template addition | Prevents framework-drift class (~30 min/affected story) |
| **P2** | Add `typecheck` to `tasks-template.md` Verification step | Trivial template addition | Prevents tsc-vs-Vitest-loader gap (~20 min/affected story) |
| **P3** | Clarify `/story` orchestrator drive-pattern in skill description | One sentence | Onboarding clarity |
| **P4** | `speck upgrade` output lists which feedback files it addresses | Medium (changelog parser) | Closes round-trip loop visibly |
| **P5** | Feedback-file template at `.speck/templates/feedback/template.md` | Small | Replicates the velocity-producing structure |
| **P6** | Constitution-as-code pattern doc (Platform-archetype-specific) | Medium | High-leverage for any Platform project with binding principles |

P1 + P2 alone would have saved ~50 min in this E000 execution. P4 closes a long-term loop. P6 captures the highest-leverage E000 outcome as reusable methodology.

---

## Context (auto-collected, no source code)

### Projects in this workspace

- **001-flyt-ai-first-studio-management-platform**: recipe=`(none)`, play_level=`platform`, archetype=`b2b_saas`, speck_version=`v7.9.1`
- E000 closed (`274eed7` on `main`); E001 next; 38 phase-boundary DECs locked; ~85-95 stories total across 9 epics

### Velocity signals

- E000: 7 stories / ~2 calendar days / ~5h focused work
- Phase 0 budget: 7 days → ~3.5× under
- Round-trip feedback cycles in session: 2 (both shipped same workday)
- Speck-feedback files filed: 5 (across the session arc)

---

## Submitting this feedback

Speck does **not** send anything automatically. If you want to share this with the Speck team:

1. **Review the file** — redact anything you don't want public
2. Open a new GitHub issue: https://github.com/telum-ai/speck/issues/new
3. Paste the content of this file
4. Add a title like `Feedback: E000 execution — 6 observations after closing first epic (P1-P6 proposals)`

---

*Generated post-E000 close (PR #6 merged as `274eed7`). 5th feedback file in this workspace this session. No network calls were made.*