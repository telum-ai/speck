# Browser Extension Visual Testing Pattern

**Platform**: `extension`  
**Applicable Recipes**: chrome-extension  
**Primary Tools**: Puppeteer, Playwright, Chrome DevTools Protocol

---

## 🎯 Overview

Browser extensions operate in privileged contexts with access to browser APIs, popup windows, content scripts, and background workers. Visual testing requires specialized approaches to access and screenshot these different contexts.

---

## Tight Loop (Default)

**Goal**: Validate the most visible UX surfaces (popup + options) quickly, in a headed browser.

**Start Small**:
- Test **popup** default + one key state (logged-in / permission request / error)
- Test **options** default (if changed)
- Run on **Chrome** first; add Edge only if store support requires it

**Run**:
1. Build extension: `npm run build`
2. Run visual tests (headed): `npx jest tests/` (Puppeteer) or Playwright equivalent
3. If diffs occur: decide intended vs bug, then update baselines or fix UI

---

## 🧩 Extension Architecture

Extensions have multiple visual contexts to test:

| Context | Description | How to Access |
|---------|-------------|---------------|
| **Popup** | Toolbar popup window | Navigate to `chrome-extension://{id}/popup.html` |
| **Options** | Settings page | Navigate to `chrome-extension://{id}/options.html` |
| **Content Script** | Injected into web pages | Screenshot the web page with extension active |
| **DevTools Panel** | Developer tools integration | Open DevTools, navigate to panel |
| **Side Panel** | Chrome side panel | Trigger side panel open |

---

## 🎭 Puppeteer Approach

### Setup

```javascript
// puppeteer.config.js
const path = require('path');

const extensionPath = path.resolve('./dist'); // Built extension

module.exports = {
  extensionPath,
  launchOptions: {
    headless: false, // Extensions require non-headless
    args: [
      `--disable-extensions-except=${extensionPath}`,
      `--load-extension=${extensionPath}`,
    ],
  },
};
```

### Detect Extension

```javascript
// tests/utils.js
async function getExtensionId(browser) {
  // Wait for extension to load
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Find extension target
  const targets = await browser.targets();
  const extensionTarget = targets.find(target => 
    target.type() === 'service_worker' && 
    target.url().startsWith('chrome-extension://')
  );
  
  if (!extensionTarget) {
    throw new Error('Extension not found');
  }
  
  // Extract extension ID from URL
  const extensionId = extensionTarget.url().split('/')[2];
  return extensionId;
}

module.exports = { getExtensionId };
```

### Popup Visual Test

```javascript
// tests/popup.test.js
const puppeteer = require('puppeteer');
const { extensionPath, launchOptions } = require('./puppeteer.config');
const { getExtensionId } = require('./utils');

describe('Extension Popup', () => {
  let browser;
  let extensionId;
  
  beforeAll(async () => {
    browser = await puppeteer.launch(launchOptions);
    extensionId = await getExtensionId(browser);
  });
  
  afterAll(async () => {
    await browser.close();
  });
  
  it('should capture popup default state', async () => {
    const page = await browser.newPage();
    await page.goto(`chrome-extension://${extensionId}/popup.html`);
    
    // Wait for popup to render
    await page.waitForSelector('[data-testid="popup-content"]');
    
    await page.screenshot({ 
      path: './screenshots/popup-default.png',
      fullPage: true 
    });
  });
  
  it('should capture popup logged in state', async () => {
    const page = await browser.newPage();
    await page.goto(`chrome-extension://${extensionId}/popup.html`);
    
    // Simulate login
    await page.type('[data-testid="email"]', 'test@example.com');
    await page.type('[data-testid="password"]', 'password');
    await page.click('[data-testid="login-btn"]');
    
    // Wait for dashboard
    await page.waitForSelector('[data-testid="dashboard"]');
    
    await page.screenshot({ 
      path: './screenshots/popup-logged-in.png' 
    });
  });
});
```

### Content Script Visual Test

```javascript
// tests/content-script.test.js
describe('Content Script', () => {
  it('should capture page with content script overlay', async () => {
    const page = await browser.newPage();
    
    // Navigate to a test page
    await page.goto('https://example.com');
    
    // Wait for content script to inject
    await page.waitForSelector('[data-extension="my-extension"]', {
      timeout: 5000
    });
    
    // Screenshot showing extension overlay
    await page.screenshot({ 
      path: './screenshots/content-script-overlay.png',
      fullPage: true 
    });
  });
  
  it('should capture highlighted elements', async () => {
    const page = await browser.newPage();
    await page.goto('https://example.com');
    
    // Trigger extension highlighting
    await page.click('[data-extension="highlight-btn"]');
    
    // Wait for highlighting to apply
    await page.waitForTimeout(500);
    
    // Capture specific region
    const element = await page.$('.highlighted-section');
    await element.screenshot({ 
      path: './screenshots/highlighted-element.png' 
    });
  });
});
```

### Agent Commands

```bash
# Run Puppeteer tests
npm test

# Run specific test file
npx jest tests/popup.test.js

# Run with headed browser (required for extensions)
HEADLESS=false npm test
```

---

## 🎭 Playwright Approach

Playwright also supports Chrome extensions:

### Setup

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';
import path from 'path';

const extensionPath = path.resolve('./dist');

export default defineConfig({
  testDir: './e2e',
  use: {
    headless: false, // Required for extensions
  },
  projects: [
    {
      name: 'chromium-extension',
      use: {
        browserName: 'chromium',
        launchOptions: {
          args: [
            `--disable-extensions-except=${extensionPath}`,
            `--load-extension=${extensionPath}`,
          ],
        },
      },
    },
  ],
});
```

### Extension Test

```typescript
// e2e/extension.spec.ts
import { test, expect, chromium } from '@playwright/test';
import path from 'path';

const extensionPath = path.resolve('./dist');

test.describe('Extension Visual', () => {
  test('popup screenshot', async () => {
    const browser = await chromium.launch({
      headless: false,
      args: [
        `--disable-extensions-except=${extensionPath}`,
        `--load-extension=${extensionPath}`,
      ],
    });
    
    // Wait for service worker
    const serviceWorker = await browser.waitForEvent('serviceworker');
    const extensionId = serviceWorker.url().split('/')[2];
    
    // Open popup
    const context = await browser.newContext();
    const popup = await context.newPage();
    await popup.goto(`chrome-extension://${extensionId}/popup.html`);
    
    await popup.waitForLoadState('networkidle');
    await expect(popup).toHaveScreenshot('popup.png');
    
    await browser.close();
  });
});
```

---

## 🔧 Testing Different Extension States

### Storage State Testing

```javascript
// Set extension storage state before test
it('should show premium features for paid user', async () => {
  const page = await browser.newPage();
  
  // Set storage to simulate premium user
  await page.evaluate(() => {
    chrome.storage.sync.set({ 
      isPremium: true,
      plan: 'pro'
    });
  });
  
  await page.goto(`chrome-extension://${extensionId}/popup.html`);
  await page.waitForSelector('[data-testid="premium-badge"]');
  
  await page.screenshot({ path: './screenshots/popup-premium.png' });
});
```

### Permission States

```javascript
it('should show permission request UI', async () => {
  const page = await browser.newPage();
  await page.goto(`chrome-extension://${extensionId}/popup.html`);
  
  // Extension in state needing permissions
  await page.waitForSelector('[data-testid="permission-request"]');
  
  await page.screenshot({ 
    path: './screenshots/popup-permission-request.png' 
  });
});
```

---

## 📦 Manifest V3 Considerations

### Service Worker Testing

```javascript
// Manifest V3 uses service workers instead of background pages
async function getExtensionIdV3(browser) {
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  const targets = await browser.targets();
  const serviceWorkerTarget = targets.find(
    target => target.type() === 'service_worker' &&
              target.url().includes('chrome-extension://')
  );
  
  if (!serviceWorkerTarget) {
    throw new Error('Extension service worker not found');
  }
  
  return serviceWorkerTarget.url().split('/')[2];
}
```

---

## 🎨 Options Page Testing

```javascript
it('should capture options page', async () => {
  const page = await browser.newPage();
  await page.goto(`chrome-extension://${extensionId}/options.html`);
  
  await page.waitForSelector('[data-testid="options-form"]');
  
  // Default state
  await page.screenshot({ 
    path: './screenshots/options-default.png' 
  });
  
  // Fill form
  await page.click('[data-testid="dark-mode-toggle"]');
  await page.selectOption('[data-testid="language-select"]', 'es');
  
  // Saved state
  await page.screenshot({ 
    path: './screenshots/options-configured.png' 
  });
});
```

---

## 📱 Responsive Testing

Extension popups have fixed sizes, but you can test different dimensions:

```javascript
it('should capture popup at different sizes', async () => {
  const page = await browser.newPage();
  await page.goto(`chrome-extension://${extensionId}/popup.html`);
  
  // Standard popup size
  await page.setViewport({ width: 400, height: 600 });
  await page.screenshot({ path: './screenshots/popup-standard.png' });
  
  // Compact size
  await page.setViewport({ width: 300, height: 400 });
  await page.screenshot({ path: './screenshots/popup-compact.png' });
  
  // Wide size
  await page.setViewport({ width: 600, height: 400 });
  await page.screenshot({ path: './screenshots/popup-wide.png' });
});
```

---

## 📦 Storybook for Extension UI

Build extension UI components in Storybook:

### Setup

```bash
cd src  # Extension source
npx storybook@latest init
```

### Component Stories

```typescript
// src/components/PopupHeader.stories.tsx
export default {
  title: 'Extension/PopupHeader',
  component: PopupHeader,
};

export const LoggedOut = {
  args: { user: null },
};

export const LoggedIn = {
  args: { user: { name: 'John', plan: 'free' } },
};

export const Premium = {
  args: { user: { name: 'Jane', plan: 'premium' } },
};
```

### Agent Commands

```bash
# Run Storybook
npm run storybook

# Chromatic for visual regression
npx chromatic --project-token=xxx
```

---

## 🔄 CI/CD Configuration

```yaml
# .github/workflows/visual-tests.yml
name: Extension Visual Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      
      - run: npm ci
      
      - name: Build extension
        run: npm run build
      
      - name: Run visual tests
        run: xvfb-run --auto-servernum npm test
        # xvfb required for headed browser on CI
      
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: screenshots
          path: screenshots/
```

---

## 📝 Recipe Configuration

Add to recipe.yaml:

```yaml
visual_testing:
  platform: extension
  strategy: puppeteer
  contexts:
    - popup
    - options
    - content_script
  tools:
    primary: puppeteer
    alternative: playwright
    component_testing: storybook
    visual_regression: chromatic
  viewport_sizes:
    popup:
      standard: [400, 600]
      compact: [300, 400]
      wide: [600, 400]
  agent_commands:
    build: "npm run build"
    test: "npm test"
    puppeteer_test: "npx jest tests/"
    storybook: "npm run storybook"
    chromatic: "npx chromatic --project-token=xxx"
  ci_integration:
    requires_xvfb: true  # For headed browser on CI
```

---

## 🚨 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Extension not found | Not loaded | Check `--load-extension` path |
| Headless not working | Extensions need UI | Use `headless: false` |
| Service worker not ready | Async initialization | Add delay or wait for target |
| Content script not injecting | Permissions | Check manifest permissions |
| CI fails | No display | Use `xvfb-run` on Linux CI |

---

## 📋 Validation Checklist

- [ ] Extension builds successfully
- [ ] Popup screenshots in all states
- [ ] Options page screenshots
- [ ] Content script effects captured
- [ ] Different viewport sizes tested
- [ ] Storage state variations tested
- [ ] Component Storybook exists
- [ ] CI configured with xvfb

---

*Platform Pattern Version: 1.0.0*
