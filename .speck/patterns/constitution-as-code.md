# Pattern: Constitution-as-Code (Platform archetype)

**When to use**: Platform-level projects with ≥2 binding constitution principles that are **textually detectable** (banned terms, hardcoded values, structural import patterns, accessibility rules).

**Play level**: Platform (recommended). Build projects with strong `constitution.md` may adopt selectively.

**Problem**: Constitution principles in markdown are honor-system unless something mechanical enforces them on every PR. AI-paired authoring reintroduces drift quickly.

**Solution**: Map each enforceable principle to automated gates:

```
constitution.md Principles
  ↓
custom ESLint rules / banned-language scan / runtime hooks
  ↓
CI gates on every PR
  ↓
Mechanical drift-prevention (vs honor-system)
```

---

## Implementation checklist

1. **Inventory principles** — From `constitution.md` + `product-contract.md` banned language, list rules that can be expressed as:
   - Substring bans (copy, identifiers)
   - AST patterns (imports, hardcoded colors, forbidden APIs)
   - File-structure rules (secrets in repo, env var naming)

2. **Choose enforcement layer**

   | Principle type | Typical enforcement |
   |----------------|---------------------|
   | Banned user-facing copy | `.speck/scripts/banned-language-lint.sh` + pre-commit |
   | Hardcoded colors / tokens | Custom ESLint rule or stylelint |
   | Forbidden imports / APIs | ESLint `no-restricted-imports` or custom plugin |
   | Security invariants | Semgrep / custom grep in CI |

3. **Pass-fixture-first** — For each rule, add:
   - ✅ Valid fixture (should pass)
   - ❌ Invalid fixture (should fail with clear message)
   - RuleTester / unit test for the rule logic

4. **Wire CI** — Fail PR on violation; document in `evidence-contract.md` as valid proof source.

5. **Document in epic** — E000-style infrastructure epic story should own the substrate; reference this pattern in `epic-tech-spec.md`.

---

## Cost benchmarks (from field data)

| Rule complexity | Typical effort |
|-----------------|----------------|
| Simple substring / regex ban | ~10 min/rule |
| AST pattern (single node type) | ~20 min/rule |
| Stateful rule (imports + context) | ~30 min/rule |
| Full custom ESLint plugin (8+ rules) | ~75 min focused block |

---

## Speck artifacts to update

- `constitution.md` — link each principle to its mechanical enforcement (file + CI step)
- `evidence-contract.md` — list constitution-as-code CI as valid evidence for IMPL-GREEN+
- `tasks.md` (infra story) — tasks for rule authoring, fixtures, CI wiring
- `design-system/primitives.md` — if principles govern UI tokens

---

## lint-staged integration

Use `.speck/scripts/banned-language-lint-staged.sh` in Husky/lint-staged configs — it auto-detects project dir and forwards staged files:

```json
{
  "*.{tsx,ts,jsx,js,vue,svelte}": [
    "bash .speck/scripts/banned-language-lint-staged.sh"
  ]
}
```

---

## Verification

- [ ] Each constitution principle has ≥1 automated gate OR explicit "not automatable" rationale in `project-decisions-log.md`
- [ ] Invalid fixtures fail locally before CI
- [ ] `/audit` adversarial probe includes a deliberate violation attempt
- [ ] Story retro captures `PATTERN:` / `GOTCHA:` tags for rule authoring learnings
