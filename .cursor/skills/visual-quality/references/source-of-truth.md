# visual-quality / source-of-truth

## Source of Truth

Before implementing any UI, load the project's `design-system.md` and extract:
1. **Design Philosophy** — Core principle, emotional keywords, visual vibe, what-it-is-NOT
2. **Bold Choices (Non-Negotiable)** — The 10-15 rules that DEFINE this product's personality
3. **What Success Looks Like** — The feel test that determines if implementation is done

If `design-system.md` doesn't have these sections, flag it — the project needs a design system upgrade.

Also load `design-system/primitives.md` → **`## Rendering Gotchas`** table (if present). These are anti-patterns that look correct in code but break in the target runtime (e.g., gradient text clipping descenders on iOS WKWebView).
