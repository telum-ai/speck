# Speck v11 — North Star: Subtraction with Teeth

**Status**: Canonical · **Target**: Speck v11.0.0 · **Supersedes**: always-on accretion post-v8/v9

## 1. Thesis

> Shrink the always-on surface. Keep truth-detection. Install an immune system so the corpus cannot silently re-bloat.

v8 installed principles over probes. v9 installed the witness graph over redundant parsers. Always-on context still grew: AGENTS.md re-expanded past host loader caps; skill descriptions burned catalog budget; unused domain skills sat in the discovery surface.

v11 subtracts context tax without weakening P1–P4, LARP axes, `/audit`, or graph hard `.P1`s.

## 2. Host loaders (non-negotiable constraints)

| Host | Always-on contract | Skill catalog |
|------|-------------------|---------------|
| Cursor | AGENTS.md / rules | `name`+`description` for auto skills; body on match ([docs](https://cursor.com/docs/skills)) |
| Claude Code | `CLAUDE.md` → `@AGENTS.md` | Listing ~1% context; `disable-model-invocation` removes listing ([docs](https://code.claude.com/docs/en/skills)) |
| Codex | AGENTS.md; default **32 KiB** `project_doc_max_bytes` | `.agents/skills` discovery; progressive disclosure |

Progressive disclosure ([agentskills.io](https://agentskills.io/specification)): metadata always → body on invoke → `references/` **only on taken branch edges** (ADR-0005). A single always-loaded `procedure.md` is forbidden theater.

## 3. Locked policies

1. **Hybrid fitness**: hard corpus/path budget CI + fail-closed A1-lite seeded contract smoke against the candidate corpus and an immutable baseline. It protects named gate capabilities; it does not substitute for runtime agent LARP.
2. **Invocation**: `disable-model-invocation: true` only on `speck`, `story`, `epic`. All other skills auto-invocable.
3. **Domain skills deleted**: Stripe/Clerk/Supabase/… pack removed. Stack start = `.speck/recipes/`. Vendor APIs = Context7 / official docs JIT.
4. **Judgment boundary**: encode high-stakes invariants as small executable interfaces and validators. For ordinary implementation choices, state the outcome and local constraints, then let the model use judgment. Do not repeat rules or constrain exploration with examples (ADR-0003/0004/0006).
5. **Skill load DAG** (ADR-0005): always-path → inline in `SKILL.md`; branching/multi-domain → router + multi-node refs; anti-theater CI. Complete inventory: `docs/decisions/skill-load-map.md`.
6. **Meta-methodology**: every always-on expansion needs ADR + budget room (or equal retirement) + scorecard for gates. See `docs/decisions/`.
7. **Cursor `paths:`**: story/epic/project/UI skills scoped to matching globs (see apply-skill-paths.py).

## 4. Corpus budget ceilings

| Metric | Ceiling |
|--------|---------|
| AGENTS.md bytes | ≤ 16384 |
| AGENTS.md lines | ≤ 200 |
| `disable-model-invocation: true` | allowlist `{speck, story, epic}` only |
| Per auto skill description chars | ≤ 120 |
| Sum auto skill description chars | ≤ 10000 |
| SKILL.md body (always-path) | ≤ 200 |
| SKILL.md body (DAG router) | ≤ 80 |
| Skill `references/**/*.md` | ≤ 120 lines / ≤8 KiB per node; every node directly router-owned |
| Declared execution paths | ≤ pre-v11 inline byte cap in `skill-load-budgets.json` |
| Agent-prose lint | AGENTS + SKILL.md + skill refs + `.speck/reference/` |
| Anti-theater | Fail single-procedure pointers, orphan nodes, and ref-to-ref edges |

Enforced by `.speck/scripts/validation/validators/validate-corpus-budget.sh`.

## 5. Spine (do not subtract)

P1–P4; four-axis honesty; first-actions ladder; readiness states; evidence-or-it-didn't-happen; `/audit` before validate; LARP DOES-IT-WORK + IS-IT-GOOD; verify-skills-before-accept; promise conservation; witness graph `check`/`gap`; banned-language; PROFILE drift; decision locks.

## 6. Evolution loop (anti-v12)

1. Classify change: `spine` | `always-on-contract` | `skill-catalog` | `jit` | `delete`
2. Prefer JIT (`references/`, templates, scripts)
3. Catalog entry needs ≤120-char description + budget room
4. ADR in `docs/decisions/` (+ scorecard for gates)
5. `validate-corpus-budget` green

## 7. Out of v11

Full metaharness evolve/fleet/embeddings; deep vendor recipe playbooks; hiding lifecycle skills behind `disable-model-invocation`; weakening prove gates for tokens.

## 8. Research informing v11

Anthropic reports removing more than 80% of Claude Code's system prompt for its newest models without measurable coding-evaluation loss. Its current guidance is to prefer judgment over broad rules, interfaces over examples, progressive disclosure over upfront context, and simple non-duplicated tool descriptions. V11 adopts those principles while retaining executable P1-P4 proof invariants at the few places where discretion would make evidence unauditable. ([Anthropic, 2026-07-24](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models))

*[as of speck 11.0.0]*
