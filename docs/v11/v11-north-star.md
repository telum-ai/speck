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

Progressive disclosure ([agentskills.io](https://agentskills.io/specification)): metadata always → body on invoke → `references/` on demand.

## 3. Locked policies

1. **Hybrid fitness**: hard corpus budget CI + A1-lite seeded scorecard.
2. **Invocation**: `disable-model-invocation: true` only on `speck`, `story`, `epic`. All other skills auto-invocable.
3. **Domain skills deleted**: Stripe/Clerk/Supabase/… pack removed. Stack start = `.speck/recipes/`. Vendor APIs = Context7 / official docs JIT.
4. **Agent prose**: AGENTS.md, SKILL.md, `.speck/reference/*` are imperative, dense, no emoji headers, no tutorial filler. Humans read CHANGELOG / this doc / README.
5. **Meta-methodology**: every always-on expansion needs ADR + budget room (or equal retirement) + scorecard for gates. See `docs/decisions/`.

## 4. Corpus budget ceilings

| Metric | Ceiling |
|--------|---------|
| AGENTS.md bytes | ≤ 16384 |
| AGENTS.md lines | ≤ 200 |
| `disable-model-invocation: true` | allowlist `{speck, story, epic}` only |
| Per auto skill description chars | ≤ 120 |
| Sum auto skill description chars | ≤ 10000 |
| SKILL.md body lines (ex-frontmatter) | ≤ 200 (grandfather shrink-only) |
| Skill `references/**/*.md` lines | ≤ 280 (same agent-prose bar; ADR-0004) |
| Agent-prose lint | AGENTS + SKILL.md + skill refs + `.speck/reference/` |

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

*[as of speck 11.0.0]*
