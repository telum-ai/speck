---
name: visual-testing-web
description: Load when running visual validation for web applications - Next.js, SvelteKit, React, Django, Go+HTMX, or static sites. Provides Browser MCP tool usage and Playwright patterns.
---

# Web Visual Testing

**Platform**: `web`  
**Applicable Recipes**: nextjs-supabase, sveltekit-supabase, t3-stack, django-htmx, go-templ-htmx, react-fastapi-postgres, static-site  
**Primary Tools**: Browser MCP tools, Playwright, Percy, Chromatic

---

## 🔄 Tight Loop (Default)

**Goal**: Get high-signal visual feedback fast (minutes, not hours) with minimal flake.

**Start Small**:
- **Screens**: Focus on 1–3 screens/components most impacted by the story
- **Breakpoints**: Start with `mobile` (375px) + `desktop` (1024px) only
- **States**: Cover default + loading + empty + error + one interaction state (hover/focus)

**Run Order**:
1. Stabilize UI (disable animations, wait for network idle)
2. Capture screenshots for scoped screens at scoped breakpoints
3. Run accessibility audit + check console errors
4. If diffs occur: decide "expected change" vs "bug", update baselines or fix UI

**Expand Only When**:
- Initial findings reveal responsive issues → add tablet/wide
- Story explicitly covers all breakpoints
- Epic validation requires full matrix

---

## 🌐 Browser MCP Tools

Use these tools for live validation.

> ⚠️ **PRODUCTION BUILD REQUIREMENT FOR UX-RC+ CLAIMS**: While rapid tight-loop testing during implementation can run against the hot-reloading dev server (e.g. `http://localhost:3000`), all formal validation for UX-RC or higher **MUST** navigate and validate against a serving local production build (e.g., compiled with `next build` and served via `next start` or standard reverse-proxy). 
> - **Hydration Flake**: Hot Module Replacement (HMR) websocket reconnection errors on dev servers can cause temporary client hydration splits (where click handlers are completely dead). If a flow is BLOCKED on a dev server, always verify against the production build.
> - **Inlined Build-Time Env (Split-Brain)**: Variables prefixed with `NEXT_PUBLIC_*` or `PUBLIC_*` are permanently inlined into the client-side JS bundles **at build time** from `.env` files. Runtime environment overrides on the server will not change the compiled client bundles, causing a silent split-brain. Check browser network calls to verify the correct API endpoint is targeted.

| Tool | Purpose | Example |
|------|---------|---------|
| `browser_navigate` | Navigate to pages | `browser_navigate("http://localhost:3000/dashboard")` |
| `browser_resize` | Set viewport for responsive | `browser_resize(375, 667)` |
| `browser_take_screenshot` | Capture current state | `browser_take_screenshot("dashboard-mobile.png")` |
| `browser_snapshot` | Get element refs for interaction | Before clicks/hovers |
| `browser_hover` | Trigger hover states | `browser_hover(element, ref)` |
| `browser_click` | Trigger click states | `browser_click(element, ref)` |
| `browser_wait_for` | Wait for content to load | `browser_wait_for(text="Dashboard")` |

### Audit Tools

| Tool | When to Run | What It Checks |
|------|-------------|----------------|
| `runAccessibilityAudit` | Every validation | WCAG violations, ARIA issues |
| `runPerformanceAudit` | When perf targets specified | LCP, CLS, TTI |
| `runBestPracticesAudit` | Every validation | Security, modern APIs |
| `runSEOAudit` | Public/marketing pages | Meta tags, structure |
| `getConsoleErrors` | Every validation | Runtime errors, warnings |

---

## 📱 Standard Breakpoints

| Name | Width | Height | When to Test |
|------|-------|--------|--------------|
| Mobile | 375 | 667 | **Always** (Tight Loop) |
| Tablet | 768 | 1024 | When responsive scope |
| Desktop | 1024 | 768 | **Always** (Tight Loop) |
| Wide | 1280 | 800 | When wide layouts in scope |
| Ultrawide | 1536 | 864 | Admin dashboards only |

---

## 🔧 Validation Sequence

Follow this exact sequence for each page:

```
1. NAVIGATE
   browser_navigate(url)
   browser_wait_for(text="expected content")

2. STABILIZE (before any screenshots)
   - Inject CSS to disable animations
   - Wait for network idle
   - Mask dynamic content if needed

3. RESPONSIVE CAPTURE (Tight Loop: mobile + desktop only)
   For each breakpoint:
     browser_resize(width, height)
     browser_take_screenshot("{page}-{breakpoint}.png")

4. STATE CAPTURE
   For each interactive component:
     browser_snapshot()  # Get refs
     browser_hover(element, ref)
     browser_take_screenshot("{component}-hover.png")

5. AUDITS
   runAccessibilityAudit()
   getConsoleErrors()
   runPerformanceAudit()  # If targets specified

6. VALIDATE
   Compare screenshots to wireframes
   Check ui-spec.md Testing Checklist
   Report findings
```

---

## 🎭 Dynamic Content Handling

Before taking screenshots, stabilize dynamic content:

**CSS Injection** (via `browser_evaluate`):
```javascript
// Disable all animations
document.head.insertAdjacentHTML('beforeend', `
  <style>
    *, *::before, *::after {
      animation-duration: 0s !important;
      transition-duration: 0s !important;
    }
  </style>
`);
```

**Masking** (for Playwright CI):
```javascript
await expect(page).toHaveScreenshot({
  mask: [
    page.getByTestId('timestamp'),
    page.getByTestId('avatar'),
    page.getByTestId('ad-slot')
  ]
});
```

**Tolerance** (for minor differences):
```javascript
await expect(page).toHaveScreenshot({
  maxDiffPixels: 100,        // Allow up to 100 different pixels
  maxDiffPixelRatio: 0.01,   // Or 1% of total
  threshold: 0.2             // Per-pixel color threshold
});
```

---

## 🧪 Playwright for CI

For CI/CD visual regression, set up Playwright:

```bash
# Run visual tests
npx playwright test --project=chromium

# Update baselines when changes are intentional
npx playwright test --update-snapshots
```

**Key Patterns**:
```typescript
// Visual assertion
await expect(page).toHaveScreenshot('dashboard.png');

// Component screenshot
await expect(page.getByTestId('header')).toHaveScreenshot('header.png');

// Full page
await expect(page).toHaveScreenshot('page.png', { fullPage: true });
```

---

## ✅ Validation Criteria

| Check | Pass Criteria | Blocking? |
|-------|---------------|-----------|
| Responsive layout | Correct at mobile + desktop | Yes |
| Design tokens | No hardcoded colors/spacing in changed files | Yes |
| Accessibility | 0 critical/serious issues | Yes |
| Console errors | 0 errors (warnings OK) | Yes |
| Performance | LCP < 2.5s, CLS < 0.1 (if targets specified) | No |
| Voice/tone | Matches ux-strategy.md | No |

---

## 🔗 Integration with Storybook

If the project uses Storybook:
1. Run Storybook: `npm run storybook`
2. Navigate to component stories
3. Capture screenshots of each state
4. Use Chromatic or Percy for automated regression

```bash
# Chromatic (if configured)
npx chromatic --project-token=xxx

# Percy (if configured)  
npx percy storybook
```
