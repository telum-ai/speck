---
name: speck-graph-up
description: Drive a pre-v9 project to a fully-established witness graph — the v9 migration that paves a perfect road to completion. Hardens identity (AC-N/MM-N/JOB-N), builds the derived graph, heals the road already walked (stale digests, over-claimed matrices, [pre-v9-proof] caps), and emits road-to-completion.md (TIDY→REMOVE→BUILD→PROVE). Load when .speck/.v9-graph-needed exists, when an agent engages a v9 project with no committed graph/witness.json, or when the user says "graph up", "bring this to v9", "/speck-graph-up".
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — consider it before proceeding.

User input:

$ARGUMENTS

---

## Purpose

**The problem this solves.** v9 makes the witness graph the spine — project-state renders from it, the
forcing gates fire off it, `road-to-completion.md` re-projects it, `/goal` drives against it. But a
project upgraded to v9 has only had files swapped; the graph itself is not built, and the *road already
walked* may hold stale digests, over-claimed matrices, dangling refs, and pre-v9 green. `/speck-graph-up`
establishes graph truth and heals the past, so ANY project — regardless of state — ends with an excellent
graph that makes crystal-clear what needs to be **tidied, removed, built, and proved**.

It is the v9 sibling of `/speck-catch-up` (v6→v7) and `/speck-reprove` (v7→v8), and **runs on top of
them**: v9 assumes v7-clean artifacts and v8-honest caps.

The graph proves **traceable · complete · fresh** only. It never grants **faithful · good · excellent** —
those stay owned by `/audit` + the four-axis LARP. This skill establishes the structure; it does not
rubber-stamp quality.

## Phase 0 — Chain preflight (never build on suspect scaffolds)

Run these first, in order; each is a hard prerequisite:

1. If `.speck/.migration-needs-catchup` exists (or a truth doc still holds `<!-- v7 MIGRATION SCAFFOLD -->`) → run `/speck-catch-up` to completion FIRST.
2. If `.speck/.v8-reprove-needed` exists → run `/speck-reprove` to completion FIRST (v9 inherits its `[pre-v8-proof]` caps).
3. Inventory the project: dispatch parallel `speck-explorer` / `speck-scanner` subagents to list every epic/story dir, every matrix, and the current readiness claims — the triage baseline.

## Phase 1 — Harden identity (the graph's precondition)

Extraction over ambiguous free-text keys yields a *confidently-wrong* graph, so identity comes first.

```bash
# dry-run first — review the AC-N renumbering diff, then apply
python3 .speck/scripts/graph/speck_graph.py migrate specs/projects/<id>
python3 .speck/scripts/graph/speck_graph.py migrate specs/projects/<id> --apply
```

- `migrate --apply` numbers acceptance scenarios to `AC-N` (§2-scoped, idempotent, existing headings respected).
- It also **reports** the magic-moment / JTBD headings that need `MM-N` / `JOB-N` ids added — these are heterogeneous and are **never auto-rewritten**; add them by hand (the honest boundary).
- Then `lint-refs` MUST resolve: `python3 .speck/scripts/graph/speck_graph.py lint-refs specs/projects/<id>`. Repoint or log every `DANGLING_REF.P1` / `DUP_ID.P1` (real rot — a renamed story, a duplicate S-number). `GRAPH_UNMIGRATED.P3` is expected and fine at this stage.

## Phase 2 — Build the graph

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/<id>   # → graph/witness.json
```

Commit `witness.json`. It is DERIVED and content-hashed — never hand-edit it.

## Phase 3 — Retroactive cleanup (heal the road already walked)

Idempotent reconcilers, **`--dry-run` default**, per-repo diff surfaced to the owner before `--apply`.
**REMOVE-bucket deletions are ALWAYS a separate human-confirmed gesture — never inside `--apply`.**

1. **Version-as-staleness** — every truth artifact stamped `speck < 9` caps at `≥ ux-rc`; the historical number is PRESERVED and stamped `[pre-v9-proof]` (never silently lowered), routed to PROVE.
2. **Matrix-grain reconcile** (graph-driven) — write each discharged row's Grain from the graph's MIN-grain evidence for that PRM's discharge path (Status untouched, conservation byte-identical, `[pre-v9-proof]`, idempotent). Reuses `reconcile-matrix-grain.sh`.
3. **Prose↔canonical** — render every prose readiness restatement from the single canonical `readiness_state_verified` frontmatter. Structurally ends the digest-rot bug (a fixed defect still shown open).
4. **Un-graded discharge re-grade** — a discharged PRM with no proof-path to grain-sufficient evidence is downgraded honestly and routed to PROVE.
5. **Dangling prune** — fixed by the Phase-1 AC-N migrate, or repointed.
6. **Orphan + retired-parser record** — orphan artifacts flagged for REMOVE (human-confirmed); parsers the graph subsumes (deleted by the mechanical upgrade) recorded so the net-drop is auditable.

## Phase 4 — Emit the road + render project-state from the graph

```bash
python3 .speck/scripts/graph/speck_graph.py road specs/projects/<id>    # → graph/road-to-completion.md
```

The road is DERIVED + disposable (doctrine banner; the `GRAPH_STALE` law applies to itself). Four ordered
buckets, each line `{node · source · gate-code · resolving-skill}`: **🧹 TIDY → 🗑 REMOVE → 🔨 BUILD → 🔬
PROVE**. The sequence *is* the dependency order. Regenerate `project-state.md` FROM the graph so the mirror
is derived and cannot rot.

> `road` and `project-state`-from-graph land in v9.2. Until then, run `check` and hand-transcribe its
> findings/caps into `project-state.md`'s next-action + known-issues; the buckets map onto the gate codes.

## Phase 5 — Finalize (terminal)

Remove `.speck/.v9-graph-needed` **only after** `witness.json` (and, from v9.2, `road-to-completion.md`)
exist AND `check` reports no untracked hard findings. Re-run `check` to confirm. The engagement gate then
lets feature work proceed.

## Engagement gate (why this is mandatory)

Any agent engaging a project while `.speck/.v9-graph-needed` is present **refuses feature work**: "upgraded
to v9 but graph truth not established — run `/speck-graph-up` first." This is the top-level analog of the
`.v8-reprove-needed` / `.migration-needs-catchup` gates. See AGENTS.md First Actions step 0.

## What this skill does NOT do

It does not judge faithful/good/excellent (that's `/audit` + LARP), does not reconstruct decisions from git
history (that's `/speck-catch-up`), and does not delete anything from the REMOVE bucket without a separate
human confirmation. It establishes and heals structure; the four-axis climb to SHIP is the PROVE work the
road then makes legible.
