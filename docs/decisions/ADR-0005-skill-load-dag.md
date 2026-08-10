# ADR-0005: Skill-as-router load DAG (real JIT)

- **Date**: 2026-08-09
- **Status**: accepted
- **Class**: skill-catalog
- **Amends**: ADR-0003, ADR-0004

## Context

v11 relocated oversized bodies into `references/procedure.md` with a thin SKILL that always said “read procedure.md”. Every such skill had exactly one reference file. That is relocation theater: invoke still loads the whole blob; progressive disclosure is not conditional load.

## Decision

1. **Honest always-path** — if every successful run needs the whole procedure, put it in `SKILL.md` (dense, ≤200 lines). Do not keep a single always-loaded `references/procedure.md`.
2. **Load DAG** — if runs diverge on cheap branch keys (`play_level`, epic count, archetype, claimed readiness state, host, lens id), `SKILL.md` is a **router**. Reference files are **nodes** loaded only on taken edges.
3. **Subagent = one ref** — parallel units (e.g. analyze lenses) each receive one self-contained lens file; the conductor does not preload sibling lenses.
4. **Router-owned edges** — every ref node must be named directly by `SKILL.md`; ref-to-ref routing is forbidden. This makes every load decision inspectable before any node is loaded.
5. **Anti-theater CI** — corpus-budget fails single-procedure pointers, router-orphaned nodes, hidden continuation edges, and declared branch paths that exceed their pre-v11 inline byte ceiling.
6. **Ceilings** — router `SKILL.md` body ≤80 lines; each ref node ≤120 lines and ≤8 KiB; declared hot paths are capped in `.speck/reference/skill-load-budgets.json`; essay bans from ADR-0004 still apply.
7. **Invocation surface** — ADR-0007 decides which router or specialists may auto-trigger. A DAG implementation and its compatibility aliases never compete automatically.

## Decomposition rules

- Split only on branch keys the router can compute cheaply.
- One concern per ref (spine | tier | lens | state | axis | host).
- Required edges: `MUST Read X before Y`. Optional: `Read X only if …`.
- No essay nodes or part1/part2 continuations. A reference never routes to another reference.
- **Predicates live in the router.** `SKILL.md` must state the cheap key and the branch (`If archetype is backend: Read backend-skip; Do not Read larp`). Forbidden: `Read X when that domain applies` — loading X to learn whether X applies is not JIT.
- **Always-path → inline.** If every successful run MUST Read every ref, delete `references/` and put the dense procedure in `SKILL.md`. A multi-ref folder of unconditional MUSTs is theater.

## Budget delta

Cuts invoke tokens on Build-tier analyze (3 lenses not 7), backend validate (no LARP/felt/visual), and any path that skips commercial/visual nodes. Platform solo without dispatch still loads most nodes eventually — win is dispatch + skipped branches.

## Consequences

More files per DAG skill; agents follow only router-declared edges. Byte caps make “smaller” an execution-path property, not a file-count or line-count proxy.

## Complete inventory

See [`docs/decisions/skill-load-map.md`](skill-load-map.md) for the full classification of every Speck skill (`dag` | `domain-refs` | `inline` | `shim`). That map is the source of truth for “done.”
