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
4. **Anti-theater CI** — corpus-budget fails a skill whose `references/` contains exactly one `*.md` named `procedure.md` (or exactly one md) while SKILL only points at it. Skills must be **inline (0 refs)** or **multi-node DAG (≥2 refs with explicit branch Reads)**.
5. **Ceilings** — router `SKILL.md` body ≤80 lines for DAG skills; each ref node ≤120 lines; essay bans from ADR-0004 still apply.

## Decomposition rules

- Split only on branch keys the router can compute cheaply.
- One concern per ref (spine | tier | lens | state | axis | host).
- Required edges: `MUST Read X before Y`. Optional: `Read X only if …`.
- No essay nodes; no part1/part2 splits without a branch key.
- **Predicates live in the router.** `SKILL.md` must state the cheap key and the branch (`If archetype is backend: Read backend-skip; Do not Read larp`). Forbidden: `Read X when that domain applies` — loading X to learn whether X applies is not JIT.
- **Always-path → inline.** If every successful run MUST Read every ref, delete `references/` and put the dense procedure in `SKILL.md`. A multi-ref folder of unconditional MUSTs is theater.

## Budget delta

Cuts invoke tokens on Build-tier analyze (3 lenses not 7), backend validate (no LARP/felt/visual), and any path that skips commercial/visual nodes. Platform solo without dispatch still loads most nodes eventually — win is dispatch + skipped branches.

## Consequences

More files per DAG skill; agents must follow Read edges (discipline + CI shape checks). Fake single-procedure pointers are forbidden.

## Complete inventory

See [`docs/decisions/skill-load-map.md`](skill-load-map.md) for the full classification of every Speck skill (`dag` | `domain-refs` | `inline` | `shim`). That map is the source of truth for “done.”
