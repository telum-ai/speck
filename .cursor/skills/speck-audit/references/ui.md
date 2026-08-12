# UI audit branch

1. Reach each changed surface through the real navigation, authentication, and data path. An API call or direct route that bypasses the user path is surrogate proof and a P0 finding when used to claim UI reachability.
2. Compare changed UI files with `design-system/primitives.md`, including any documented rendering gotchas. A known unsafe rendering signature without the canonical safe form is P1.
3. If `ui-spec.md` defines a form-validation matrix, verify exact inline messages, field association, focus behavior, pending-state input/CTA disabling, and double-submit protection.
4. Inspect loading, empty, error, permission, and degraded states that implementation could have omitted while still passing the happy path.
5. Record defects and reachability findings in the audit report. Runtime screenshots, accessibility trees, and experience verdicts belong to the subsequent LARP plus visual-testing pass.
