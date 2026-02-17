---
name: visual-testing-extension
description: Load when running visual validation for browser extensions (Chrome, Firefox, Edge). Provides Puppeteer and Playwright patterns for popup, options, and content script contexts.
---

# Browser Extension Visual Testing

**Platform**: `extension`  
**Applicable Recipes**: chrome-extension  
**Primary Tools**: Puppeteer, Playwright, Chrome DevTools Protocol

---

## 🔄 Tight Loop (Default)

**Goal**: Validate the most visible UX surfaces (popup + options) quickly in a headed browser.

**Start Small**:
- **Surfaces**: Popup default + one key state (logged-in, error, permission request)
- **Options**: Default state only (if changed by story)
- **Browser**: Chrome first; add Edge only if store support requires it

**Run Order**:
1. Build extension: `npm run build`
2. Run visual tests (headed): `npx jest tests/` or Playwright equivalent
3. If diffs occur: decide intended vs bug, update baselines or fix UI

**Expand Only When**:
- Story affects content scripts (need page-level testing)
- Story affects background service worker visuals (rare)
- Release requires multi-browser testing

---

## ⚠️ Extension Context Challenges

Browser extensions have unique contexts that require special handling:
- **Popup**: Small overlay window, fixed dimensions
- **Options page**: Full tab, standard web page
- **Content scripts**: Injected into web pages
- **Background**: No visual UI (service worker)

Standard browser automation doesn't access extension contexts by default.

---

## 🎭 Puppeteer Setup

### Loading Extension

```javascript
const puppeteer = require('puppeteer');
const path = require('path');

async function launchWithExtension() {
  const extensionPath = path.resolve('./dist');
  
  const browser = await puppeteer.launch({
    headless: false,  // Extensions require headed mode
    args: [
      `--disable-extensions-except=${extensionPath}`,
      `--load-extension=${extensionPath}`,
    ],
  });
  
  return browser;
}
```

### Getting Extension ID

```javascript
async function getExtensionId(browser) {
  const targets = await browser.targets();
  const extensionTarget = targets.find(
    target => target.type() === 'service_worker' && 
              target.url().startsWith('chrome-extension://')
  );
  
  const extensionUrl = extensionTarget.url();
  const [, , extensionId] = extensionUrl.split('/');
  return extensionId;
}
```

### Capturing Popup

```javascript
async function capturePopup(browser, extensionId) {
  const popupUrl = `chrome-extension://${extensionId}/popup.html`;
  
  const page = await browser.newPage();
  await page.setViewport({ width: 400, height: 600 }); // Typical popup size
  await page.goto(popupUrl);
  
  // Wait for content to load
  await page.waitForSelector('[data-testid="popup-content"]');
  
  await page.screenshot({ path: 'screenshots/popup-default.png' });
  
  return page;
}
```

### Capturing Options Page

```javascript
async function captureOptions(browser, extensionId) {
  const optionsUrl = `chrome-extension://${extensionId}/options.html`;
  
  const page = await browser.newPage();
  await page.setViewport({ width: 1024, height: 768 });
  await page.goto(optionsUrl);
  
  await page.screenshot({ path: 'screenshots/options-default.png' });
  
  return page;
}
```

---

## 🧪 Complete Test Example

```javascript
// tests/visual.test.js
const puppeteer = require('puppeteer');
const path = require('path');

describe('Extension Visual Tests', () => {
  let browser;
  let extensionId;

  beforeAll(async () => {
    const extensionPath = path.resolve('./dist');
    
    browser = await puppeteer.launch({
      headless: false,
      args: [
        `--disable-extensions-except=${extensionPath}`,
        `--load-extension=${extensionPath}`,
      ],
    });

    // Get extension ID
    const targets = await browser.targets();
    const extensionTarget = targets.find(
      t => t.type() === 'service_worker'
    );
    extensionId = extensionTarget.url().split('/')[2];
  });

  afterAll(async () => {
    await browser.close();
  });

  describe('Popup', () => {
    it('should match default state', async () => {
      const page = await browser.newPage();
      await page.setViewport({ width: 400, height: 600 });
      await page.goto(`chrome-extension://${extensionId}/popup.html`);
      
      await page.screenshot({ path: 'screenshots/popup-default.png' });
      // Compare with baseline
    });

    it('should match logged-in state', async () => {
      const page = await browser.newPage();
      await page.setViewport({ width: 400, height: 600 });
      await page.goto(`chrome-extension://${extensionId}/popup.html`);
      
      // Simulate logged-in state
      await page.evaluate(() => {
        localStorage.setItem('auth_token', 'test-token');
      });
      await page.reload();
      
      await page.screenshot({ path: 'screenshots/popup-logged-in.png' });
    });

    it('should match error state', async () => {
      const page = await browser.newPage();
      await page.setViewport({ width: 400, height: 600 });
      await page.goto(`chrome-extension://${extensionId}/popup.html`);
      
      // Trigger error state
      await page.click('[data-testid="action-button"]');
      await page.waitForSelector('[data-testid="error-message"]');
      
      await page.screenshot({ path: 'screenshots/popup-error.png' });
    });
  });

  describe('Options Page', () => {
    it('should match default state', async () => {
      const page = await browser.newPage();
      await page.setViewport({ width: 1024, height: 768 });
      await page.goto(`chrome-extension://${extensionId}/options.html`);
      
      await page.screenshot({ path: 'screenshots/options-default.png' });
    });
  });
});
```

---

## 🎭 Playwright Alternative

Playwright also supports extension testing:

```javascript
const { chromium } = require('playwright');
const path = require('path');

async function testExtension() {
  const extensionPath = path.resolve('./dist');
  
  const context = await chromium.launchPersistentContext('', {
    headless: false,
    args: [
      `--disable-extensions-except=${extensionPath}`,
      `--load-extension=${extensionPath}`,
    ],
  });

  // Get extension ID from service worker
  let extensionId;
  const serviceWorker = await context.waitForEvent('serviceworker');
  extensionId = serviceWorker.url().split('/')[2];

  // Test popup
  const popup = await context.newPage();
  await popup.setViewportSize({ width: 400, height: 600 });
  await popup.goto(`chrome-extension://${extensionId}/popup.html`);
  await popup.screenshot({ path: 'screenshots/popup.png' });

  await context.close();
}
```

---

## 📏 Standard Popup Sizes

| Type | Width | Height | Notes |
|------|-------|--------|-------|
| Minimal | 300 | 400 | Compact tools |
| Standard | 400 | 600 | Most extensions |
| Wide | 500 | 600 | Data-rich popups |
| Tall | 400 | 800 | List-heavy UIs |

**Note**: Popup dimensions are constrained by Chrome. Max is typically ~800×600.

---

## 🌐 Multi-Browser Support

If your extension supports multiple browsers:

### Firefox

```javascript
const { firefox } = require('playwright');

// Firefox uses web-ext for extension loading
// Run with: web-ext run --source-dir=./dist
```

### Edge

```javascript
// Edge uses same Chromium approach
const browser = await chromium.launch({
  channel: 'msedge',
  args: [
    `--disable-extensions-except=${extensionPath}`,
    `--load-extension=${extensionPath}`,
  ],
});
```

---

## ✅ Validation Checklist

Verify these for each validation:

- [ ] Popup default state captured
- [ ] Popup key interaction state captured (logged-in/error/etc.)
- [ ] Options page captured (if changed)
- [ ] Content script injection works (if applicable)
- [ ] No console errors in extension contexts
- [ ] Popup dimensions feel appropriate
- [ ] Icons render correctly at all sizes
- [ ] Dark mode tested (if supported)

---

## 📁 Screenshot Organization

```
screenshots/
├── popup/
│   ├── default.png
│   ├── logged-in.png
│   ├── error.png
│   └── loading.png
├── options/
│   ├── default.png
│   └── configured.png
└── content-script/
    ├── injected-panel.png
    └── overlay.png
```

---

## 🔗 Content Script Testing

For testing injected content scripts:

```javascript
it('should inject content correctly', async () => {
  const page = await browser.newPage();
  await page.goto('https://example.com');
  
  // Wait for content script to inject
  await page.waitForSelector('[data-extension-injected]');
  
  // Capture the injected UI
  const element = await page.$('[data-extension-injected]');
  await element.screenshot({ path: 'screenshots/content-script.png' });
});
```

**Note**: Content script testing requires navigating to actual web pages.
