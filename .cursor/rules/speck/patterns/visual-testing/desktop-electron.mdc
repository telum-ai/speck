---
name: visual-testing-desktop-electron
description: Load when running visual validation for Electron desktop apps. Provides Playwright Electron API patterns.
---

# Electron Visual Testing

**Platform**: `desktop-electron`  
**Applicable Recipes**: electron-react  
**Primary Tools**: Playwright Electron, Storybook, Percy

---

## 🔄 Tight Loop (Default)

**Goal**: One command to validate the main window and key changed flows with screenshots.

**Start Small**:
- **Windows**: Main window + 1–2 windows/routes touched by the story
- **Sizes**: Normal size (1280×800) first; add small/maximized only if layout is in scope
- **Themes**: Light mode first; add dark mode only if story affects theming

**Run Order**:
1. Launch Electron app via Playwright
2. Capture main window screenshot
3. Navigate to changed routes, capture each
4. If diffs occur: determine intended vs unintended, update snapshots or fix UI

**Expand Only When**:
- Story explicitly covers multiple window sizes
- Story involves multi-window interactions
- Epic validation requires full window state matrix

---

## ⚡ Playwright Electron API

Electron bundles Chromium, ensuring consistent rendering. Playwright provides first-class support.

### Launching the App

```typescript
import { _electron as electron } from 'playwright';

const electronApp = await electron.launch({
  args: ['path/to/your/app']
});

// Get the first window
const window = await electronApp.firstWindow();

// Wait for app to load
await window.waitForLoadState('domcontentloaded');
```

### Taking Screenshots

```typescript
// Full window screenshot
await window.screenshot({ path: 'screenshots/main-window.png' });

// Element screenshot
const header = window.locator('[data-testid="header"]');
await header.screenshot({ path: 'screenshots/header.png' });

// Visual assertion (for CI)
await expect(window).toHaveScreenshot('main-window.png');
```

### Window State Testing

```typescript
// Normal size
await window.setViewportSize({ width: 1280, height: 800 });
await window.screenshot({ path: 'screenshots/normal.png' });

// Small window
await window.setViewportSize({ width: 800, height: 600 });
await window.screenshot({ path: 'screenshots/small.png' });

// Maximized (platform-specific)
await electronApp.evaluate(async ({ BrowserWindow }) => {
  const win = BrowserWindow.getAllWindows()[0];
  win.maximize();
});
await window.screenshot({ path: 'screenshots/maximized.png' });
```

### Theme Testing

```typescript
// Force dark mode
await electronApp.evaluate(async ({ nativeTheme }) => {
  nativeTheme.themeSource = 'dark';
});
await window.screenshot({ path: 'screenshots/dark-mode.png' });

// Force light mode
await electronApp.evaluate(async ({ nativeTheme }) => {
  nativeTheme.themeSource = 'light';
});
await window.screenshot({ path: 'screenshots/light-mode.png' });
```

---

## 🪟 Multi-Window Testing

If the app opens multiple windows:

```typescript
// Wait for second window to open
const [secondWindow] = await Promise.all([
  electronApp.waitForEvent('window'),
  window.click('[data-testid="open-settings"]')
]);

// Capture secondary window
await secondWindow.screenshot({ path: 'screenshots/settings-window.png' });

// Test modal dialogs
await window.click('[data-testid="open-dialog"]');
await window.screenshot({ path: 'screenshots/dialog-open.png' });
```

---

## 🖥️ Cross-Platform Considerations

Electron renders consistently due to bundled Chromium, but test on:
- **macOS**: Primary development
- **Windows**: Most users
- **Linux**: CI environment

**Platform-Specific Baselines** (if needed):
```
screenshots/
├── main-window-darwin.png
├── main-window-win32.png
└── main-window-linux.png
```

```typescript
// Dynamic baseline selection
const platform = process.platform;
await expect(window).toHaveScreenshot(`main-window-${platform}.png`);
```

---

## 🔧 Test Commands

```bash
# Run Electron visual tests
npx playwright test --project=electron

# Update baselines when changes are intentional
npx playwright test --project=electron --update-snapshots

# Run specific test file
npx playwright test tests/visual/main-window.spec.ts
```

---

## ✅ Validation Checklist

Verify these for each validation:

- [ ] Main window captured in normal size
- [ ] Key routes/screens captured
- [ ] Light mode tested (dark if story touches theming)
- [ ] Window resize behavior works (if in scope)
- [ ] Secondary windows/dialogs captured (if applicable)
- [ ] No console errors in main process
- [ ] No console errors in renderer process

---

## 🔗 Storybook Integration

If using Storybook for component development:

```bash
# Run Storybook for Electron renderer components
npm run storybook

# Visual regression with Chromatic
npx chromatic --project-token=xxx
```

Components can be tested in isolation before full app integration.
