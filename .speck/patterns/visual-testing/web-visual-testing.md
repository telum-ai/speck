# Web Visual Testing Pattern

**Platform**: `web`  
**Applicable Recipes**: nextjs-supabase, sveltekit-supabase, t3-stack, django-htmx, go-templ-htmx, react-fastapi-postgres, static-site  
**Primary Tools**: Browser MCP tools, Playwright, Percy, Chromatic

---

## 🎯 Overview

Web visual testing leverages the Speck agent's browser MCP tools for autonomous screenshot capture, interaction, and auditing. This pattern covers responsive testing, component state validation, and accessibility verification.

---

## Tight Loop (Default)

**Goal**: Get high-signal visual feedback fast (minutes, not hours) with minimal flake.

**Start Small**:
- **Screens**: 1–3 screens/components most impacted by the story
- **Breakpoints**: `mobile` + `desktop` first (expand to `tablet`/`wide` only if responsive behavior is in scope)
- **States**: default + loading + empty + error (as applicable) + one interaction state (hover/focus)

**Run (recommended order)**:
1. Stabilize UI (disable animations/transitions, wait for network idle)
2. Capture screenshots for the scoped screens at scoped breakpoints
3. Run accessibility audit (`runAccessibilityAudit`) and capture console errors
4. If diffs occur: decide “expected change” vs “bug”, then either update baselines or fix UI

---

## 🤖 Agent Capabilities

### Browser MCP Tools Available

| Tool | Purpose | Example Use |
|------|---------|-------------|
| `browser_navigate` | Go to URL | Navigate to pages/routes |
| `browser_snapshot` | Accessibility tree | Get element refs for interaction |
| `browser_take_screenshot` | Capture current state | Visual evidence |
| `browser_resize` | Set viewport size | Responsive testing |
| `browser_click` | Click elements | Trigger states |
| `browser_hover` | Hover elements | Capture hover states |
| `browser_type` | Enter text | Form testing |
| `browser_wait_for` | Wait for content | Dynamic content |

### Audit Tools

| Tool | Purpose | When to Run |
|------|---------|-------------|
| `runAccessibilityAudit` | WCAG compliance | Every visual validation |
| `runPerformanceAudit` | Core Web Vitals | Performance-sensitive stories |
| `runBestPracticesAudit` | General best practices | Every validation |
| `runSEOAudit` | SEO compliance | Public/marketing pages |

---

## 📋 Visual Testing Workflow

### 1. Navigate and Prepare

```
1. browser_navigate(url: "http://localhost:3000/page")
2. browser_wait_for(text: "Expected content")
3. browser_snapshot() → Get element refs
```

### 2. Responsive Testing

```
For each breakpoint in design-system.md:
  1. browser_resize(width: breakpoint, height: 800)
  2. browser_wait_for(time: 0.5)  # Layout settle
  3. browser_take_screenshot(filename: "page-{breakpoint}.png")
```

**Standard Breakpoints:**
- Mobile: 375×667
- Tablet: 768×1024
- Desktop: 1024×768
- Wide: 1280×800
- Ultrawide: 1536×864

### 3. State Testing

```
For each state in ui-spec.md:
  1. browser_snapshot() → Find element ref
  2. Trigger state:
     - Hover: browser_hover(ref: "element-ref")
     - Focus: browser_click(ref: "element-ref")
     - Active: browser_click + hold (if supported)
  3. browser_take_screenshot(filename: "component-{state}.png")
```

### 4. Run Audits

```
1. runAccessibilityAudit() → Check WCAG compliance
2. runPerformanceAudit() → Check Core Web Vitals
3. runBestPracticesAudit() → General checks
```

---

## 🔧 Playwright Integration

For CI/CD and advanced visual regression, use Playwright:

### Visual Snapshot Testing

```javascript
import { test, expect } from '@playwright/test'

test('visual regression', async ({ page }) => {
  await page.goto('/dashboard')
  
  // Full page screenshot
  await expect(page).toHaveScreenshot('dashboard.png')
  
  // Component screenshot
  const card = page.getByTestId('stats-card')
  await expect(card).toHaveScreenshot('stats-card.png')
})
```

### Responsive Testing

```javascript
const breakpoints = [
  { name: 'mobile', width: 375, height: 667 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 800 }
]

for (const bp of breakpoints) {
  test(`responsive - ${bp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: bp.width, height: bp.height })
    await page.goto('/dashboard')
    await expect(page).toHaveScreenshot(`dashboard-${bp.name}.png`)
  })
}
```

### State Testing

```javascript
test('button states', async ({ page }) => {
  await page.goto('/components/button')
  const button = page.getByRole('button', { name: 'Submit' })
  
  // Default state
  await expect(button).toHaveScreenshot('button-default.png')
  
  // Hover state
  await button.hover()
  await expect(button).toHaveScreenshot('button-hover.png')
  
  // Focus state
  await button.focus()
  await expect(button).toHaveScreenshot('button-focus.png')
  
  // Disabled state
  await page.evaluate(() => {
    document.querySelector('button').disabled = true
  })
  await expect(button).toHaveScreenshot('button-disabled.png')
})
```

### Agent Commands

```bash
# Run visual tests
npx playwright test --project=chromium

# Update baselines
npx playwright test --update-snapshots

# Run specific test
npx playwright test visual.spec.ts

# Generate report
npx playwright show-report
```

---

## 🎨 Percy Integration

For cloud-based visual regression with AI comparison:

### Setup

```bash
npm install --save-dev @percy/cli @percy/playwright
```

### Usage

```javascript
import { percySnapshot } from '@percy/playwright'

test('dashboard visual', async ({ page }) => {
  await page.goto('/dashboard')
  
  // Single snapshot
  await percySnapshot(page, 'Dashboard')
  
  // Responsive snapshot (multiple widths)
  await percySnapshot(page, 'Dashboard Responsive', {
    widths: [375, 768, 1280]
  })
  
  // With CSS to hide dynamic content
  await percySnapshot(page, 'Dashboard Clean', {
    percyCSS: `
      .timestamp { visibility: hidden; }
      .avatar { visibility: hidden; }
    `
  })
})
```

### Agent Commands

```bash
# Run Percy tests
PERCY_TOKEN=xxx npx percy exec -- npx playwright test

# Percy with specific browsers
npx percy exec -- npx playwright test --project=chromium
```

---

## 📚 Storybook + Chromatic

For component-level visual testing:

### Storybook Stories

```typescript
// Button.stories.tsx
export default {
  title: 'Components/Button',
  component: Button
}

export const Default = { args: { children: 'Click me' } }
export const Primary = { args: { variant: 'primary' } }
export const Disabled = { args: { disabled: true } }
export const Loading = { args: { loading: true } }
```

### Chromatic Integration

```bash
# Install Chromatic
npm install --save-dev chromatic

# Run Chromatic
npx chromatic --project-token=xxx
```

Chromatic automatically:
- Captures screenshots of every story
- Compares against baselines
- Provides visual diff review UI
- Integrates with GitHub PRs

### Agent Commands

```bash
# Build Storybook
npm run build-storybook

# Run Chromatic
npx chromatic --project-token=xxx --exit-zero-on-changes

# Accept all changes (update baselines)
npx chromatic --project-token=xxx --auto-accept-changes
```

---

## 🔍 Dynamic Content Handling

### Mask Dynamic Elements

```javascript
// Playwright
await expect(page).toHaveScreenshot({
  mask: [
    page.getByTestId('timestamp'),
    page.getByTestId('user-avatar'),
    page.locator('.ad-container')
  ]
})
```

### Disable Animations

```javascript
// Before screenshot
await page.addStyleTag({
  content: `
    *, *::before, *::after {
      animation-duration: 0s !important;
      animation-delay: 0s !important;
      transition-duration: 0s !important;
      transition-delay: 0s !important;
    }
  `
})
```

### Wait for Stable State

```javascript
// Wait for network idle
await page.waitForLoadState('networkidle')

// Wait for specific content
await page.waitForSelector('[data-loaded="true"]')

// Wait for animations to complete
await page.waitForTimeout(500) // Use sparingly
```

---

## 📊 Validation Checklist

### Before Validation

- [ ] App is running on local dev server
- [ ] Test data is seeded/mocked
- [ ] Browser MCP tools connected (or Playwright available)

### During Validation

- [ ] Screenshots captured at all breakpoints
- [ ] All component states captured
- [ ] Accessibility audit run
- [ ] Performance audit run (if targets specified)
- [ ] Console errors checked

### Validation Criteria

| Check | Pass Criteria |
|-------|---------------|
| Responsive | Layout correct at all breakpoints |
| Design tokens | 100% token usage (no hardcoded values) |
| Accessibility | 0 critical issues, 0 serious issues |
| Performance | LCP < 2.5s, FID < 100ms, CLS < 0.1 |
| States | All specified states render correctly |

---

## 📝 Recipe Configuration

Add to recipe.yaml:

```yaml
visual_testing:
  platform: web
  strategy: browser-mcp
  breakpoints:
    mobile: 375
    tablet: 768
    desktop: 1024
    wide: 1280
  tools:
    primary: playwright
    visual_regression: percy  # or chromatic
    storybook: true
  agent_commands:
    screenshot: "browser_take_screenshot"
    audit_a11y: "runAccessibilityAudit"
    audit_perf: "runPerformanceAudit"
    playwright_test: "npx playwright test"
    playwright_update: "npx playwright test --update-snapshots"
  ci_integration:
    on_pr: true
    block_on_diff: true
```

---

## 🚨 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Flaky screenshots | Animations | Disable animations before capture |
| Different baselines per OS | Font rendering | Use Docker for consistent CI environment |
| Dynamic content fails | Timestamps, avatars | Mask dynamic elements |
| Layout shift detected | Lazy loading | Wait for content to load |
| Color diff on different monitors | Color profiles | Use sRGB color space |

---

*Platform Pattern Version: 1.0.0*
