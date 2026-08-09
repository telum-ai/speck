# story-implement / ui

1. Require `ui-spec.md` for UI-heavy work. Read it plus project `design-system.md`, epic journey/wireframes, and active recipe `visual_testing:`.
2. Hold product-relative intent: Design Philosophy, Bold Choices, success feel, tokens, primitives, exact states, accessibility, responsive behavior, and declared assets.
3. Reuse canonical primitives. Implement every specified state: loading, empty, error, success, disabled, focus/hover/pressed, narrow/wide, keyboard/screen-reader.
4. Create and verify every asset in the UI spec manifest at its declared path. Stable selectors/keys are part of the implementation.
5. Run the recipe's development visual smoke test on the 1–3 affected surfaces against a built or representative runtime; this is iteration evidence, not readiness proof.
6. Inspect the rendered pixels yourself. Check hierarchy, spacing, clipping, overlap, target size, copy, iconography, brand rules, and responsive geometry. Fix named-rule and hard-objective defects now.
7. Record a self-review grade and remaining aesthetic forks. The implementer cannot adjudicate FELT-GOOD/TASTE or replace the later hostile LARP.
