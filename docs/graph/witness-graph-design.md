# The Speck Witness Graph — design

*Owner: Kjetil · Arc: identity → extractor → forcing gates → context packs → tests-as-join*

**Status (v9.4):** Shipped — the witness graph is the **spine** (v9). `build`/`lint-refs`/`query`/
`context`/`check`/`gate`/`road`/`gap`/`cascade`/`migrate` subcommands; forcing at 4 boundaries
(First-Actions, story-prereqs reachability, validate, pre-commit) with the block-vs-guide adoption
signal; the `.v9-graph-needed` migration marker + `/speck-graph-up` skill; `road-to-completion.md`
(TIDY→REMOVE→BUILD→PROVE); native-`/goal` drive via `gap --emit-goal`; conservation (`UNMAPPED_PROMISE`,
parity-proven), cycle (`DEP_CYCLE`), and verdict (`UNJUDGED_SURFACE`, v9.4) gates. Proven on Streb +
Splang (real dangling refs, a renumbered AC discharge, a duplicate story-id, and open-row parity = 0).

**Remaining (the honest edge):** `ORPHAN_CODE` (tests-as-join) stays **not-evaluated** — never a false
pass. It needs data the methodology repo can't provide generically: a per-repo test-tagging convention
(a test named/tagged with the spec id it covers, e.g. `S013/AC-2`) + coverage data mapping the passing
test to the code entity. A consuming repo *opts in* by adopting the convention and pointing the extractor
at its coverage output; until then the gate honestly reports "not evaluated" (design §9). Also pending:
project-state fully rendering from the graph (P4 render), and running `/speck-graph-up` on the live repos
(a per-repo gated gesture — the dry-run diff goes to Kjetil first).

## 1. The problem (from evidence, not intuition)

Speck v8 **already is a knowledge graph** — a connection-model sweep found ~35 distinct edge types
(promise→story, AC→discharge, gate→CI, evidence→SHA, DEC→artifact, seam→screen…) totalling ~138
instances across the artifacts. But it is **stored as prose tables and enforced piecewise** by ~30
bespoke bash regex-parsers, and enforcement is sharply bimodal:

- **The spine has teeth** — promise conservation, grain caps, gate-liveness + mutation canaries,
  SHA/profile/market/settings drift all BLOCK via named scripts. The #86–#88 arc hardened exactly
  the edges that had bled in the field. That half is real; the graph does **not** re-solve it.
- **Everything else is agent memory.** Every ID and name — `S###`, `AC-N`, `PRM`, magic moments,
  personas, JTBD — is free text string-matched across 3–6 artifacts with **no resolver**. `AC-N`,
  the key the entire conservation law points at, was not defined by *any* template. `S001` exists
  in a dozen epics; `PRM-016` means two different things in one project. Renames break every
  downstream reference silently.

Field evidence (Streb, Splang, live repos):

- A regenerated `project-state.md` still listed defect F1 as open a day *after* a DEC + harden
  report locked its fix. **Digest/mirror rot** despite regeneration.
- `template-manifest.json` — Speck's *one* machine-readable schema — had itself drifted from the
  v8 templates it checks (Three-Axis vs Four-Axis readiness). The drift detector's reference rotted.
- `epic-breakdown.md` rotted identically in two mature repos (story map stops before shipped stories).
- The validator scar history (#76.3, #83, #85, #87) is *entirely* format-drift bugs in
  regex-over-markdown. Every new edge with teeth costs a new hand-rolled parser plus its bugs.

**The named failure mode (Kjetil):** Speck "is not capable enough of always having the right context
and tracing everything it needs to trace." That is a context-assembly problem, not only an
enforcement one.

## 2. The core distinction (what makes this safe)

**Authored graph vs derived graph.**

- A graph *database the agent writes into* would be a ninth copy of every fact, a new Goodhart
  surface (a fabricated graph edge is a fabricated PRM row in different syntax), and a head-on
  collision with the v8 thesis — *enumeration infrastructure IS the context rot*. Rejected.
- A **derived** graph — one extractor compiling the markdown, test runs, and coverage data into a
  regenerated, never-hand-edited, content-hashed index — keeps markdown as the **only authored
  truth**. To fake an edge you must fake the reality it is extracted from, which is exactly what the
  evidence/canary machinery already guards. **Automatic derivation is the precondition for a loud,
  un-gameable forcing function.** This is what we build.

The witness graph is the generalization of `generate-coverage-matrix.sh`: extract structured facts
from markdown → emit a generated artifact with an honesty stamp → **cap (never raise)** the
claimable readiness state.

## 3. What the graph forces — and what it must never claim

The forcing function is **structural only**. Graph gates own:

- **Build the right thing** — *orphan detection*: every code entity above a grain threshold must
  trace back through the graph to a promise. Code no JTBD asked for → LOUD.
- **Build the thing right** — *phantom-promise detection*: every promise node must have a live
  discharge path down to grain-sufficient evidence. A promise with no path → LOUD.
- **Un-judged surface** — a magic moment / screen / seam with no IS-IT-GOOD verdict node → BLOCK.
  The excellence machinery *must have run*, everywhere.
- **Dangling refs & per-edge staleness** — renames, dead links, stale evidence, pinpointed to the
  edge (not the commit, as the coarse SHA stamp does today).

**The anti-rubber-stamp law (Kjetil, explicit):** the graph proves *traceable · complete · fresh*.
It CANNOT prove *faithful · good · excellent* — those stay owned by `/audit`, LARP, and the
canaries. #87's 13 false discharges and #88's disarmed gates were **semantic** failures a graph
would render as perfectly well-formed edges. So the graph must never say "everything is connected,
therefore it's good." It does the opposite: it makes *skipping* the excellence machinery a
queryable, blocking hole, and it *feeds* the adversary (weakest-grain-first targeting; context packs
that give the taste judge the intent behind the flow). Graph gates **cap or block — none can grant.**

## 4. Architecture

```
authored markdown  ──►  extractor (python, stdlib)  ──►  witness.json  ──►  { gates · queries · context packs }
(single source of truth)   speck_graph.py build          (derived,          validators become queries;
                                                           content-hashed,    project-state renders from it;
                                                           per-project)       skills load packs, not tree-walks
```

- **`.speck/scripts/graph/speck_graph.py`** — stdlib-only Python. Subcommands:
  - `build <PROJECT_DIR>` → writes `specs/projects/<id>/graph/witness.json` (nodes, typed edges,
    per-node content hash, per-edge staleness vs HEAD, `generator_completeness` stamp).
  - `check <PROJECT_DIR>` → runs the forcing gates; emits typed findings
    (`ORPHAN_CODE.P?`, `PHANTOM_PROMISE.P?`, `UNJUDGED_SURFACE.P1`, `DANGLING_REF.P1`,
    `GRAPH_STALE.P2`); prints `GRAPH_CAP` = the readiness ceiling the graph can back.
  - `query <PROJECT_DIR> <q>` → inverse/aggregate lookups (story→PRMs, DEC blast radius,
    which gates guard a story, MIN grain over discharged rows).
  - `context <PROJECT_DIR> <node-id>` → the agent context pack (upstream promises + MMs, ACs +
    discharge state, adjacent seams, constraining DECs, guarding gates, prior GOTCHAs on files).
- **Identity resolver** — the node-id scheme below. Bare ids resolve within their owning scope;
  cross-scope references MUST qualify. A failed resolve is `DANGLING_REF.P1`.
- **Node/edge model** — nodes: `job`, `magic-moment`, `persona`, `contract-clause`, `epic`, `story`,
  `ac`, `task`, `dec`, `gate`, `evidence`, `verdict` (v9.4), `test`, `code`, `pattern`. Typed edges:
  `sources · discharges · proves · guards · constrains · covers · judges · supersedes · depends-on`.

## 5. Identity model (Phase 1 — the prerequisite)

Extraction over today's ambiguous free-text keys yields a *confidently wrong* graph, so identity is
hardened first. Canonical **qualified** reference form (bare form allowed only inside the owning scope):

| Entity | Canonical id | Bare (scope-local) | Defined in |
|--------|--------------|--------------------|-----------|
| Epic | `E011` | — (project-global) | epic dir name |
| Story | `E011/S038` | `S038` (own epic) | story dir name |
| Acceptance criterion | `E011/S038/AC-2` | `AC-2` (own story) | **story-template §2b (NEW)** |
| Promise row | `E011/PRM-016` | `PRM-016` (own epic) | traceability-matrix §2 |
| Magic moment | `MM-3` | — (project-global) | **product-contract §5 (NEW id)** |
| Job (JTBD) | `JOB-2` | — (project-global) | **product-contract §2/§4 (NEW id)** |
| Decision | `DEC-0207` | — (project-global) | project-decisions-log |
| Requirement | `FR-E011-014` / `NFR-003` | — | epic.md |

`readiness_state_verified: <enum>` (frontmatter) is the single canonical machine field for a story's
verified state; prose restatements render from it.

## 6. Non-negotiable rules (inherited from the evidence)

1. **The index is derived and disposable.** No agent or human edits `witness.json`. If it is dirty
   relative to its sources (content hash mismatch vs HEAD), every graph gate fails — its freshness
   is *computed*, never asserted. Delete the generator and nothing authored is lost.
2. **The arc must RETIRE code, not add it.** Conservation → anti-join; cascade → reverse
   reachability; grain cap → MIN() query; dangling ref → failed resolve. The bespoke parsers those
   replace get deleted. **The arc fails if net script count does not go down.**
3. **Structural edges only.** Fidelity, taste, and enumeration completeness stay with `/audit` and
   the canaries. The docs say so, loudly, so the graph is never a false-confidence surface.
4. **Kill criterion (Speck's own FTR-A1 bar), fixed up front.** The layer must show measured wins —
   scripts retired, context tokens saved per session, defects caught — vs the #86–#88 status quo,
   measured on Streb as the live testbed. Misses the bar → reverted.

## 7. Migration

Generic to **any** live Speck project (not Streb-specific). Ships with Phase 1: an ID-qualification
reconcile + extractor bootstrap that upgrades Streb, Splang, keegt, and every future repo — same
family as `reconcile-matrix-grain.sh` (idempotent, `--dry-run`, never destructive).

## 8. Phasing (each a shippable arc, verified + committed)

- **P1** — identity model + AC-N definition + shared parse/resolve library + generic migration + fix
  the live `template-manifest.json` drift.
- **P2** — the extractor + `witness.json` + `query`, and retire the first redundant parsers.
- **P3** — the forcing gates (orphan, phantom, un-judged, dangling, staleness) wired to the validate
  gates as cap/block.
- **P4** — agent-facing context packs; `project-state.md` renders from the graph; revive the dead
  learning edge (just-in-time GOTCHA retrieval).
- **P5** — tests-as-join: an AC↔code edge exists only when a *passing* test tagged with the spec id
  covers that code (unfakeable without faking a test; composes with #88 canaries).

## 9. Explicitly NOT building

A graph database or any daemon (Speck ships static files, runs zero processes); an agent-authored
graph artifact; an MCP server as the primary home (at most a thin optional query layer later, over
the checked-in file); and no re-solving discharge/grain/gate-liveness — those edges already have
probed teeth.
