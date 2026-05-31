---
name: speck-audit
description: Adversarial skeptical audit inserted between /story-implement (or /epic-implement) and /story-validate (or /epic-validate). The auditor does NOT trust the implementer's report. For each acceptance criterion it asks "what's the negative case? has it been observed? what evidence proves it works?" Runs adversarial probes (malformed input, oversized payload, dep failure, concurrency, N+1, env vars, observability reach) per evidence-contract.md. Required for every epic close in Speck v7 — replaces the v6 /story-analyze step. Load when implementation just finished, when user says "audit this", "are we sure?", "what's missing", or before any validate gate.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

`/audit` is the skeptical pass that catches what the implementer missed. From Splang's retro:

> Every "ship" doc I wrote was honest about what I'd done — but silent about what I hadn't checked. The methodology failure isn't that the specs were bad. It's that Speck's notion of "done" was satisfiable by tests passing, screenshots looking good, and commit messages reading nicely — none of which are reality checks.

The auditor:
- Does NOT trust the implementer's self-report
- For each acceptance criterion, asks: negative case? evidence? regression guard?
- Auto-runs the adversarial probe suite per `evidence-contract.md`
- Flags banned-phrases in implementation summaries
- Produces a findings report that blocks validate-claim-of-PASS until resolved

This step is **mandatory** between implement and validate. Replaces the v6 `/story-analyze` skill.

## When to Run

| Trigger | What to do |
|---------|------------|
| `/story-implement` just completed | Run `/audit` for that story |
| All stories in an epic are validated | Run `/audit` for the epic (cross-story coverage check) |
| User says "audit" / "are we sure" / "what's missing" | Run for current context |
| Before `/recheck` proceeds to LARP cold-start | Run audit to surface known issues first |
| Banned-phrase detected in implementer's summary | Auto-trigger |

## Prerequisites

For a story audit: `spec.md`, `plan.md`, `tasks.md` exist; implementation done; `evidence-contract.md` exists.
For an epic audit: all stories in epic have completed `/audit` + `/story-validate`.

## Execution Steps

### 1. Locate target

If `--story <id>`: audit that story.
If `--epic <id>`: audit that epic.
Default: audit the active story.

### 2. Load context (parallel)

```
├── [Parallel] speck-explorer: Read spec.md, plan.md, tasks.md
├── [Parallel] speck-explorer: Read evidence-contract.md
├── [Parallel] speck-explorer: Read product-contract.md
├── [Parallel] speck-explorer: List changed files
└── [Parallel] speck-explorer: Read implementer's commit messages
```

### 3. Spec-to-implementation traceability check

For each acceptance criterion / FR in spec.md:
- Find supporting code
- Find supporting test
- Verify test asserts BEHAVIOR, not current (buggy) state
- Flag `expect().toBe(<wrong>)` + "BUG/TODO/should be/fix later" comments
- Flag `test.skip` without reason

### 4. Adversarial probe suite (parallel subagents)

Per evidence-contract.md. Standard 10 probes (see claude skill for full list). Each subagent runs probe + verifies response.

### 5. Failure-mode-handling check

For each external dep, verify implementation handles its failure mode per spec's `failure_modes_handled` section.

### 6. Cascade-on-write check (DB)

For each DB write path, list related tables per spec's `related_tables` section, verify cascade/anonymize behavior.

### 7. Quality patterns scan

N+1 queries, unpaged lists, type coverage, env-var validation, observability reach.

### 8. Banned-phrase detection in implementer summary

Search commit messages + handoff notes for banned phrases. If found, require enumeration.

### 9. Test pollution check

Run test suite twice (default + random order). Results differ → P0 finding.

### 10. Reachability + scaffolding check (UI stories)

Navigation path, no dev shortcuts, real auth flow.

### 10b. Rendering gotchas grep (UI stories)

If `design-system/primitives.md` exists and has a `## Rendering Gotchas` section:

1. Parse the gotchas table — extract **Grep signature** and **Canonical safe form** from each row (skip placeholder/template rows).
2. For each grep signature, run against changed UI files in the story scope (`rg` or equivalent on `.tsx`, `.jsx`, `.vue`, `.svelte`, `.css`).
3. For each match, verify the line also contains the canonical safe form (utility class, component name, or documented exception comment).
4. Raw anti-pattern without safe form → **P1 finding** ("correct code, wrong pixels — survives TDD").

Example: `bg-clip-text` without `.gradient-text-safe` (or project equivalent) on a headline.

Skip this step if no `## Rendering Gotchas` section exists (project has not registered any yet).

### 11. Banned-language scan

Run `.speck/scripts/banned-language-lint.sh` against changed files.

### 12. Compose audit report

Write to `<story-or-epic-dir>/audit-report.md` (template per claude skill).

### 13. Apply stamp + decision gate

```
.speck/scripts/stamp-truth.sh <story-or-epic-dir>/audit-report.md
```

Decision:
- P0 → BLOCKED. Validate must refuse PASS.
- P1-P3 only → NEEDS_FIXES. Surface; user choice.
- Clean → CLEAN. Validate can proceed.

### 14. Report (standard format per claude skill)

## Behavior Rules

- NEVER skip the adversarial probe suite
- NEVER claim CLEAN without random-order test rerun
- NEVER take the implementer's word — verify with evidence
- ALWAYS apply SHA stamp
- ALWAYS write report even if CLEAN
- BLOCK validate on P0 findings

## Integration Points

- Reads: `spec.md`, `plan.md`, `tasks.md`, `evidence-contract.md`, `product-contract.md`, `design-system/primitives.md` (Rendering Gotchas), code
- Writes: `<dir>/audit-report.md`
- Invokes: `banned-language-lint.sh`, `stamp-truth.sh`
- Required before: `/story-validate`, `/epic-validate`

## Context: $ARGUMENTS
