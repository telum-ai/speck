# Speck v9 — North Star: the Witness Graph is the Spine

*Builds on v8 (Evaluation over Verification) and the v8.7–8.8 witness graph. Owner: Kjetil.*

## 1. The thesis

v8 made every gate an instance of four principles. v9 makes the **witness graph the spine those
gates hang from** — the single derived, content-hashed index that:

- **project-state renders from** (no more digest tree-walk, no more mirror-rot),
- **the forcing gates fire off** at four lifecycle boundaries ("you cannot advance without the graph
  having what it needs"),
- **`road-to-completion.md` re-projects** into a crystal-clear TIDY → REMOVE → BUILD → PROVE worklist,
- **`/goal` drives against** to reach *actual* 100%, not just green gates.

The graph proves **traceable · complete · fresh**. It never certifies **faithful · good · excellent** —
those stay owned by `/audit` + the four-axis LARP. v9 preserves that law end to end: the graph can
*see* that the excellence machinery hasn't run (and force it to), but it cannot *grant* the verdict.

## 2. The one signal that makes forcing safe: id-scheme adoption

The requirement — "it must not be possible to advance if the graph lacks what it needs" — would brick
every greenfield project if applied naively. It doesn't, because of one signal computed from the
graph's own node counts (never from author assertion): **has this scope adopted the id scheme?**

- Scope **has** adopted it (ids exist) but a reference is broken → **ROT** → hard `.P1` **BLOCK**.
- The **identical** structural absence in a scope that has **not** adopted the scheme → `GRAPH_UNMIGRATED.P3`
  → a readiness **CAP + guidance line**, never a block.

Same missing structure is a **wall** for a rotted project and a **guide-rail** for a fresh one. "What
the graph needs" is scoped to what the phase's own adopted scheme makes detectable.

## 3. The forcing model — one mechanism, four boundaries

At every phase boundary, run `speck_graph.py check` scoped to the work grain; advancement is permitted
iff there is **no hard finding** (`.P1`: `DANGLING_REF` / `DUP_ID` / `PHANTOM_PROMISE` / cycle) in scope.

0. **First Actions (AGENTS.md):** `build && check` the project. A hard `.P1` drops the session into
   "repair the graph first" mode — the top-level analog of the `.v8-reprove-needed` gate. `GRAPH_STALE`
   does not block here (First Actions rebuilds; the graph self-heals).
1. **`check-story-prereqs.sh`:** a story must be non-dangling AND trace **up to a promise** with zero
   dangling refs in its subtree. An orphan specified-but-unwired story blocks implementation.
2. **story / epic / project-validate (step 5d):** the graph check is a hard readiness gate;
   `PHANTOM_PROMISE` blocks UX-RC+, `GRAPH_CAP` folds into MAX-claimable. This is the non-bypassable
   authority — even a `--no-verify` commit cannot claim a state past the graph cap.
3. **`pre-commit-hook.sh`:** a staged spec edit that introduces a reference dangling against the current
   tree is rejected. You cannot commit rot in.

All python3-guarded: absent → loud WARN + proceed, with CI as the enforcing backstop.

## 4. The migration "perfect road" — heal the past, chart the future

Reuses Speck's three-layer pattern (mechanical-trusted → marker-gated skill → cap-and-worklist), plus
a fourth crossing flag and a retroactive-cleanup pass.

- **Mechanical (`migrate.js` + `sync.js`):** VERSION→9.x; ship the graph scripts; `REMOVE_FILES` deletes
  the parsers the graph subsumes (v9.1+, CI-asserted net drop); `detectMigration` adds
  `graphV9 = toMajor≥9 && fromMajor<9`, chain-aware (a v6→v9 jump runs scaffoldV7 → reproveV8 → graphV9
  in dependency order); `writeV9GraphMarker` drops `.speck/.v9-graph-needed`.
- **Engagement gate:** an agent engaging a project with `.v9-graph-needed` refuses feature work until
  `/speck-graph-up` runs.
- **`/speck-graph-up` (per-project semantic skill):** Phase 0 chain-preflight (catch-up/reprove first if
  their markers exist) → Phase 1 identity-harden (`migrate --apply` AC-N numbering; `report_missing_ids`
  surfaces MM/JOB for manual add; lint-refs must resolve) → Phase 2 `build` → Phase 3 **retroactive
  cleanup** (idempotent reconcilers, `--dry-run` default, per-repo diff to Kjetil: version-as-staleness
  `[pre-v9-proof]` caps, graph-driven matrix-grain reconcile, prose↔canonical readiness render, un-graded
  discharge re-grade, dangling prune, orphan/retired-parser record) → Phase 4 emit road + regenerate
  project-state FROM the graph → Phase 5 finalize (remove marker only after witness.json + road exist).
- **`road-to-completion.md`** (`speck_graph.py road`): DERIVED + disposable (doctrine banner, GRAPH_STALE
  law applied to itself). Header = `GRAPH_CAP`, blocking-`.P1` count, single-next-action. Then four
  ordered buckets, each line `{node · source · gate-code · resolving-skill}`:
  **🧹 TIDY** (stale/unmigrated/dangling/dup/prose-drift — cheapest first) →
  **🗑 REMOVE** (orphans, retired parsers, superseded-yet-referenced DECs — deletion always a separate
  human-confirmed gesture) →
  **🔨 BUILD** (phantom promises, uncovered JOB/MM/PRM — weakest-grain then topological) →
  **🔬 PROVE** (unjudged surfaces, `[pre-v9-proof]` caps, grain deficits, reverted FELT-GOOD —
  closest-to-ceiling first, lifts `GRAPH_CAP` fastest).
  The bucket sequence *is* the dependency order: tidy so it's legible, remove so you don't build on
  orphans, build so there's something to prove, prove to climb grain.

## 5. Subtraction — what the graph lets us delete (retire-and-prove)

Deletion is **parity-proven** (Kjetil's call): a validator is removed only after a committed test proves
the graph reproduces its output byte-for-byte on Streb + Splang, and a CI assertion **fails the arc if
the bespoke-validator file count does not drop**.

- **REPLACE / FOLD (structural re-derivation):** `validate-traceability-matrix.sh` conservation branch →
  `PHANTOM_PROMISE` + `DANGLING_REF` anti-join (v9.1); `compute-cascade.sh` → cascade reverse-reachability
  query (v9.1, whole file −1); project-state steps 3–5 tree-walk → render from graph (v9.2); story-validate
  PRM-row scan → `context` pack; epic/project-analyze promise-coverage matrices → `PHANTOM_PROMISE`.
- **KEEP (semantic / orthogonal — the graph feeds, never replaces):** the grain *teeth* (BLOCK) until a
  graph grain-gate ships (v9.4); `/audit` fidelity; recheck's spec-vs-code grounding (until tests-as-join
  P5); banned-language, market/profile/settings drift, gate-liveness canaries; catch-up's git-history
  forensics; scan's code-side extraction; reprove's proof-vintage triage.
- **Net: machinery DOWN** — −2 parsers, −6 skill re-derivation steps, vs +subcommands in the one graph
  file +2 skill files. The load-bearing rot source (regex-over-markdown) strictly decreases.

## 6. `/goal` — driving to actual 100% by leveraging native functionality

**Speck does NOT reimplement the loop.** Native `/goal` (Claude Code v2.1.139+ prompt-Stop-hook; Codex
thread-scoped goals) already is the turn-continuation engine: set a completion condition, a fast model
checks it against **surfaced transcript text** after each turn (it runs no tools), continues on "no,"
clears on "yes." Speck cannot invoke `/goal` for the user (it's a client command) and gains nothing by
duplicating it. Speck makes native `/goal` powerful by supplying the three things it cannot compute:

1. **The completion condition** — from the graph. `speck_graph.py gap --emit-goal [--target]` maps "true
   100%" onto what Speck already tracks: *works* = CORRECT + LARP Job-A pass · *feels-good* = `felt_axis`
   ai-verified · *looks-good/tasteful* = `taste_axis` ai-critiqued, no severe cap, no forks-open ·
   *truly-magic* = every `MM-N` observed firing (Job A) AND judged good (Job B) · *JTBD-solved* = every
   `JOB-N` served (no `PHANTOM_PROMISE`) + end-to-end walkthrough passes. The condition is the terminating
   gap state, ≤4000 chars, with the target defaulting to the evidence-contract's ship state (SHIP-RC).
2. **The evidence surface** — because the evaluator reads only surfaced text, every driven turn prints
   the verbatim stdout of `check` + `gap`. `gap` folds structural findings + report frontmatter + LARP
   verdicts into ONE machine-legible line the evaluator pattern-matches:
   `SPECK-GAP: 2·P1(PHANTOM MM-3, DANGLING E011/S041/AC-2) | FELT:uncovered(consumer) | TASTE:forks-open(2) | MM-3:unjudged | JTBD:pass`
   terminating on `SPECK-GAP: none — GRAPH_CAP=SHIP-RC · 4/4 axes · MM 5/5 judged · JTBD pass`.
   Anti-gaming: the condition requires `check` re-run this turn; `GRAPH_STALE` catches a hand-edited
   witness.json (derived + content-hashed); the success token must be literal `gap` stdout, never a typed
   summary.
3. **The routing** — what each driven turn DOES. This is the hierarchy Kjetil asked to see:

```
native /goal                      ← the OUTER loop engine (turn continuation + evaluation)
  └─ each turn, the Speck agent (per AGENTS.md "Drive to done" doctrine):
       1. run  speck_graph.py check + gap     ← surface evidence; find the top unmet item
       2. route that item to its owning Speck skill (never reimplement — delegate):
            untraced / undischarged promise → /story-specify → /story-plan → /story-tasks
                                              → /story-implement → /audit → /story-validate
            phantom promise (no delivering story) → create the delivering story (same chain)
            audit P0/P1 finding                   → /harden
            uncovered FELT-GOOD / unjudged MM      → /larp (naive-hostile Job A + connoisseur Job B)
            forks-open TASTE · contract pivot ·
              price lock · deploy                  → STOP-BLOCKED: surface as an owner decision
            stale graph                            → speck_graph.py build
       3. re-run check + gap; the SPECK-GAP: line is what the evaluator reads
  └─ evaluator sees `SPECK-GAP: none` at the target → clears the goal (done)
```

**The workflow / sequence for a session:**

1. `/speck-graph-up` has established the graph + road (one-time, per migration).
2. Engagement: First Actions runs `build && check` (the forcing gate).
3. User runs the primer (`/speck-goal`, a THIN condition-generator — NOT a loop): it runs
   `gap --emit-goal`, prints the ready-to-paste `/goal <condition>` command + loads the routing doctrine.
4. User runs native **`/goal <condition>`** (+ auto mode for unattended turns).
5. The native loop drives; each turn routes gap→skill via the doctrine; every gate (validate, audit,
   larp) stays authoritative — `/goal` never bypasses a gate, it drives work UNTIL the gates pass at the
   target.
6. Terminates on `SPECK-GAP: none` at the target, or STOP-BLOCKED at an owner-gated inch.

**Hierarchy in one line:** `/goal` is the conductor (loop); Speck's lifecycle skills are the players
(work); the graph is the score (condition + evidence). `/goal` adds **no new discipline** — it is an
autopilot over the existing gates. It is **user-initiated** with a mandatory turn bound, because the tail
of the ladder (taste forks, contract pivots, price, deploy) is owner-gated by Speck's own doctrine.

For tools without native `/goal`, Speck directs the user to the manual iterate-until-`SPECK-GAP: none`
loop (or `/loop` for a timed variant). The condition + evidence + routing are identical; only the outer
engine differs.

## 7. Build sequence (each a committed, tested, parity-gated arc)

- **v9.0** — graph becomes the spine (additive; forcing wired at 4 boundaries, migration marker +
  engagement gate, `/speck-graph-up` core). No deletions.
- **v9.1** — retire-and-prove: parity tests, then delete `compute-cascade.sh` + the conservation branch;
  CI asserts the count drop.
- **v9.2** — `road-to-completion.md` + project-state renders from the graph.
- **v9.3** — `gap` + the `/goal` drive doctrine + the thin `/speck-goal` primer.
- **v9.4** — verdict extraction → real `UNJUDGED_SURFACE`; grain teeth migrate off the last parser.
- **v9.5** — tests-as-join → real `ORPHAN_CODE` (may slip to v10; stays honestly not-evaluated until then).

## 8. What v9 is NOT

Not a second source of truth (the graph is derived, never authored). Not a rubber stamp (structural only;
faithful/good/excellent stay with `/audit` + LARP). Not a reimplementation of `/goal` (it leverages the
native engine). Not a wall that bricks greenfield work (the adoption signal makes it a guide-rail there).
Not a net addition of machinery (parity-gated to strictly reduce).
