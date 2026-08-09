# speck-audit / chain

## 0. When to run

| Trigger | Target |
|---------|--------|
| `/story-implement` completed | That story |
| All stories validated in epic | Epic (cross-story) |
| User: audit / are we sure | Current context |
| Before `/recheck` → LARP | Current scope |
| Banned phrase in implementer summary | Auto-trigger |

## 1. Locate target + prereqs

- `--story <id>` → story dir; `--epic <id>` → epic dir; default → active story.
- Story: `spec.md`, `plan.md`, `tasks.md`, implementation done, `evidence-contract.md`.
- Epic: every story has completed `/audit` + `/story-validate`.
- STOP if prereqs missing.

## 3. Load context (parallel)

- `spec.md`, `plan.md`, `tasks.md`, `evidence-contract.md`, `product-contract.md`
- Changed files; implementer commit messages / handoff notes

## 11. UI stories

**11a. Reachability** — real nav path, no dev shortcuts, real auth. **Non-Surrogate Rule**: no API/programmatic substitute for UI interaction → **P0 surrogate-proof drift**.

**11b. Rendering gotchas** — if `design-system/primitives.md` has `## Rendering Gotchas`: grep each signature on changed UI files; match without canonical safe form → **P1**.

**11c. Form Validation Matrix** — if `ui-spec.md` has matrix: interactive tests/LARP assert exact inline messages; generic page error without field highlight → **P1**; submit pending disables inputs + CTA; double-submit protection.
