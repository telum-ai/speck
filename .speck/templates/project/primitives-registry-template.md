---
speck_version: 8.0
artifact_type: primitives-registry
---

# UI Primitives Registry

<!--
This is an EAGERLY MAINTAINED list of required UI primitives.

The primitives registry prevents drift: when every page is allowed to inline its own
header / section / empty state / loading state, the result is "seven different apps."

The /audit skill greps for inline-styled re-implementations against this list.
The /story-ui-spec skill refuses to spec a UI that doesn't use registered primitives.

Update this file whenever a new primitive is recognized, and update existing pages
to consume it (this is part of the eagerly-maintain discipline).
-->

**Project**: [PROJECT_NAME]
**Project ID**: `[PROJECT_ID]`
**Last Updated**: [YYYY-MM-DD]

---

## How Primitives Work

1. Every shared UI surface (page header, section, eyebrow, stat grid, empty state, error state, loading state, form field, etc.) is represented by ONE registered primitive.
2. UI stories MUST consume registered primitives — NOT inline `<div className="...">` re-implementations.
3. The `/audit` skill greps for inline-styled patterns matching primitive responsibilities and flags them.
4. New primitive needed? Add it here, implement it, refactor existing usage, then ship the dependent story.

---

## Registered Primitives

### Required Primitives (must exist for any UI project)

| Primitive | Purpose | Required props | Source path |
|-----------|---------|----------------|-------------|
| `PageHeader` | Single per-page header — eyebrow + title + subtitle + actions | `eyebrow?`, `title`, `subtitle?`, `actions?` | `src/design-system/PageHeader.tsx` |
| `Section` | One section per logical block — title + subtitle + padding | `title?`, `subtitle?`, `tone?` | `src/design-system/Section.tsx` |
| `Eyebrow` | Above-title small label, often signaling step / phase | `children`, `tone?` | `src/design-system/Eyebrow.tsx` |
| `StatGrid` | Stat / metric / number group with consistent rhythm | `items[]` (label/value pairs) | `src/design-system/StatGrid.tsx` |
| `EmptyState` | When a list/page has no items — icon + title + body + cta | `icon?`, `title`, `body?`, `cta?` | `src/design-system/EmptyState.tsx` |
| `ErrorState` | When something went wrong — title + body + retry | `title`, `body?`, `onRetry?` | `src/design-system/ErrorState.tsx` |
| `LoadingState` | While data loads — preferably skeleton, not spinner | `variant: 'skeleton' \| 'spinner'`, `count?` | `src/design-system/LoadingState.tsx` |
| `FormField` | Label + input + help + error wrapper for any form field | `label`, `name`, `error?`, `help?`, `children` | `src/design-system/FormField.tsx` |
| `ActionGroup` | Primary / secondary / tertiary action row with spacing | `primary`, `secondary?`, `tertiary?` | `src/design-system/ActionGroup.tsx` |
| `MetaList` | Key/value metadata rows (no-table) | `items[]` (label/value pairs) | `src/design-system/MetaList.tsx` |

### Project-Specific Primitives

Add primitives that emerged from this project's domain (e.g., `WorkoutBlock`, `SessionTimer`, `OfferCard`):

| Primitive | Purpose | Required props | Source path |
|-----------|---------|----------------|-------------|
| | | | |

---

## Anti-Patterns Detected by `/audit`

The audit skill greps for these in story implementations and flags them:

### Page header re-implementations
- ❌ `<div className="page-header">` with `<h1>` + `<p>`
- ❌ Component-local `Header` component when `PageHeader` primitive exists
- ✅ `<PageHeader eyebrow="Onboarding · Step 2" title="..." />`

### Section re-implementations
- ❌ `<div className="section"><h2>...</h2>...</div>`
- ❌ Component-local `Card` styled like a section
- ✅ `<Section title="...">...</Section>`

### Empty state re-implementations
- ❌ `<div>No items yet.</div>`
- ❌ Inline `<div><Image /><span>...</span></div>` empty placeholders
- ✅ `<EmptyState title="No bookings yet" body="..." cta={...} />`

### Form field re-implementations
- ❌ `<label><input/><span className="error">...</span></label>`
- ❌ Component-local `Field` wrapper
- ✅ `<FormField label="..." name="..."><Input /></FormField>`

### Stat / metric re-implementations
- ❌ Component-local `<div className="stat-grid">` with hand-rolled grid
- ✅ `<StatGrid items={[{label: ..., value: ...}]} />`

---

## Rendering Gotchas

Rendering recipes that look correct in code/DOM but produce wrong pixels in the target runtime. Unlike component anti-patterns above, these survive unit tests and code review — only screenshots or grep catch them.

`/audit` and the visual-quality pass grep for the **Grep signature** column against changed UI files. Any raw anti-pattern match outside the **Canonical safe form** is a P1 finding.

| Anti-pattern | Why it looks fine but isn't | Canonical safe form | Grep signature |
|--------------|----------------------------|---------------------|----------------|
| Raw gradient text (`bg-clip-text` + `text-transparent` + tight line-height) | DOM/classes are correct; descenders (g, p, y, j, Å, Ø) clip unfilled on iOS WKWebView | Project utility e.g. `.gradient-text-safe` bundling clip + padding + `-webkit-` prefixes | `bg-clip-text` |
| [Add project-specific gotcha] | [Failure mode in target runtime] | [Safe utility or component] | `[regex or literal]` |

**When to add a row**: A bug recurred 2+ times, passed non-visual gates, and has a grep-able anti-pattern signature.

**When adding**:
1. Add the row here with a working grep signature
2. Implement the canonical safe form (utility or primitive)
3. Replace all raw usages in the codebase
4. Add a unit test asserting the safe form on affected components

---

## How `/audit` Detects Drift

```bash
# Pseudocode — actual audit runs this against changed files
rg -t tsx -t jsx 'className=".*(page-header|section-header|stat-grid|empty-state|error-state)"'
# → Each match is a finding: replace with the registered primitive
```

Story-implementation tasks that introduce non-primitive UI patterns fail `/audit`.

---

## When to Add a New Primitive

A pattern earns primitive status when:
1. It appears in 2+ stories
2. The visual treatment is intended to be uniform across the app
3. It carries semantic meaning the user will rely on (e.g., "this is always a stat, not body text")

When adding:
1. Add the row in this registry
2. Implement the primitive (in `src/design-system/`)
3. Refactor existing usages
4. Update `/story-ui-spec` outputs going forward
5. Re-stamp this file

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck vX.Y.Z]*
