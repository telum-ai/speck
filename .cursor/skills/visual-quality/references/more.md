# visual-quality / more

## Common Anti-Patterns to Reject

-  All text the same size/weight (no hierarchy)
-  Default browser focus rings with no custom styling
-  Solid flat backgrounds with no texture or depth
-  Components that look like they came from a generic UI kit
-  Padding/margin that's uniform everywhere (no rhythm)
-  Animations added "because" rather than to communicate
-  Color palette used but without emphasis/drama
-  Hover states that are just opacity changes
-  Empty states with just text and no design
-  Forms that feel like spreadsheets instead of conversations

## Rendering Gotchas Check (before commit)

If `design-system/primitives.md` has a `## Rendering Gotchas` section:

1. Parse each row's **Grep signature** and **Canonical safe form**.
2. Grep changed UI files for each signature.
3. Any match without the canonical safe form → fix before marking UI done (do not rely on unit tests — these bugs are pixel-level).

Skip if the section is absent or empty.
