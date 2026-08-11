# ADR-0012: Role adapters, rework closure, and output ownership

- **Date**: 2026-08-11
- **Status**: accepted
- **Class**: always-on-contract + skill-catalog + JIT
- **Amends**: ADR-0003, ADR-0007, ADR-0008

## Context

Custom agents had grown into parallel methodology prompts, `adjust` sounded like post-hoc documentation repair, story planning lacked an independent pre-implementation challenge, and several skills spent context on uniform completion messages already implied by the work. These surfaces duplicated authority without strengthening artifacts or gates.

## Decision

1. Custom agents are thin role adapters. `.speck/reference/agent-dispatch.json` owns role-to-skill mapping, execution mode, model tier, independence, and a compact machine-consumed integration return. Artifact owners execute the selected skill; contributors supply bounded input; evaluators remain separate. Root `AGENTS.md` plus the selected canonical skill own methodology and artifact format.
2. `adjust` is an end-to-end re-engineering loop: downgrade the old claim, re-spec and conserve promises, re-plan, rebuild, audit, revalidate, and restore truth/evidence. It is not complete when documents alone change.
3. Story planning analysis is a branch of generic `analyze`: Sprint skips, Build uses one independent reviewer, and Platform uses three. It runs after `story-tasks` and gates `story-implement` for v11 task artifacts.
4. Remove `project-adjust`, `epic-adjust`, `story-adjust`, and `story-analyze`. They had no observed user invocation contract, and the canonical generic routes are unambiguous. Upgrade sync deletes stale installed copies.
5. Artifact schemas live in `.speck/templates`; machine-consumed agent returns live in the dispatch contract. Skills may surface blockers, decisions, and readiness, but do not prescribe decorative chat completion formats.

## Enforcement

- Agent generation tests require the exact dispatch roster, existing canonical skill targets, thin prompts, valid model tiers, and a bounded AGENTS + dispatch + role overlay.
- Story prerequisite and analysis-validator tests prove missing, stale, self-verified, or under-lensed analysis fails closed.
- Corpus validation rejects chat-only output-schema headings and keeps description/load budgets green.
- Routing and sync tests cover story analysis selection and removal of stale aliases.

## Consequences

Roles become useful through canonical skills rather than a second doctrine. Deliberate redesign cannot stop after re-speccing. Story analysis adds quality pressure only at the planning-to-build boundary, and chat formatting no longer consumes agent context.
