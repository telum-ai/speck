# Electron Visual Testing Pattern

**Platform**: `desktop-electron`  
**Applicable Recipes**: electron-react  
**Primary Tools**: Playwright Electron, Storybook, Percy

---

## 🎯 Overview

Electron bundles Chromium with every app, ensuring consistent rendering across platforms. Playwright provides first-class Electron automation through its `_electron` API, enabling full control over both renderer and main processes.

---

## 🎭 Playwright Electron API

### Basic Setup

```javascript
// playwright.config.js
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  use: {
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'electron',
      testMatch: '**/*.electron.spec.ts',
    },
  ],
});
```

### Launch and Screenshot

```typescript
// e2e/visual.electron.spec.ts
import { test, expect, _electron as electron } from '@playwright/test';

test('main window visual', async () => {
  // Launch Electron app
  const electronApp = await electron.launch({ args: ['.'] });
  
  // Wait for first window
  const window = await electronApp.firstWindow();
  
  // Wait for app to be ready
  await window.waitForLoadState('domcontentloaded');
  await window.waitForTimeout(500); // Allow render to settle
  
  // Take screenshot
  await window.screenshot({ path: 'screenshots/main-window.png' });
  
  // Visual assertion
  await expect(window).toHaveScreenshot('main-window.png');
  
  // Clean up
  await electronApp.close();
});
```

### Main Process Access

```typescript
test('app info from main process', async () => {
  const electronApp = await electron.launch({ args: ['.'] });
  
  // Evaluate in main process
  const appPath = await electronApp.evaluate(async ({ app }) => {
    return app.getAppPath();
  });
  
  const isPackaged = await electronApp.evaluate(async ({ app }) => {
    return app.isPackaged;
  });
  
  console.log('App path:', appPath);
  console.log('Is packaged:', isPackaged);
  
  await electronApp.close();
});
```

### Multi-Window Testing

```typescript
test('multiple windows', async () => {
  const electronApp = await electron.launch({ args: ['.'] });
  
  // Get main window
  const mainWindow = await electronApp.firstWindow();
  await expect(mainWindow).toHaveScreenshot('main-window.png');
  
  // Trigger new window (e.g., settings)
  await mainWindow.click('[data-testid="open-settings"]');
  
  // Wait for new window
  const settingsWindow = await electronApp.waitForEvent('window');
  await settingsWindow.waitForLoadState();
  
  await expect(settingsWindow).toHaveScreenshot('settings-window.png');
  
  await electronApp.close();
});
```

### Agent Commands

```bash
# Run Electron visual tests
npx playwright test --project=electron

# Update snapshots
npx playwright test --project=electron --update-snapshots

# Run with trace
npx playwright test --project=electron --trace on

# Show report
npx playwright show-report
```

---

## 🖼️ Window State Testing

### Window Sizes

```typescript
test('window resize states', async () => {
  const electronApp = await electron.launch({ args: ['.'] });
  const window = await electronApp.firstWindow();
  
  // Get BrowserWindow handle
  const browserWindow = await electronApp.browserWindow(window);
  
  // Normal size
  await browserWindow.evaluate((win) => win.setSize(1280, 800));
  await window.waitForTimeout(300);
  await expect(window).toHaveScreenshot('window-normal.png');
  
  // Small size
  await browserWindow.evaluate((win) => win.setSize(800, 600));
  await window.waitForTimeout(300);
  await expect(window).toHaveScreenshot('window-small.png');
  
  // Maximized
  await browserWindow.evaluate((win) => win.maximize());
  await window.waitForTimeout(300);
  await expect(window).toHaveScreenshot('window-maximized.png');
  
  await electronApp.close();
});
```

### Dark Mode

```typescript
test('dark mode', async () => {
  const electronApp = await electron.launch({ 
    args: ['.'],
    colorScheme: 'dark'  // Force dark mode
  });
  
  const window = await electronApp.firstWindow();
  await window.waitForLoadState();
  
  await expect(window).toHaveScreenshot('dark-mode.png');
  
  await electronApp.close();
});

test('light mode', async () => {
  const electronApp = await electron.launch({ 
    args: ['.'],
    colorScheme: 'light'
  });
  
  const window = await electronApp.firstWindow();
  await window.waitForLoadState();
  
  await expect(window).toHaveScreenshot('light-mode.png');
  
  await electronApp.close();
});
```

---

## 📚 Storybook Integration

For component-level testing, use Storybook with Chromatic:

### Setup

```bash
# Initialize Storybook
npx storybook@latest init

# Add Chromatic
npm install --save-dev chromatic
```

### Component Story

```typescript
// src/components/Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  component: Button,
};

export default meta;

export const Primary: StoryObj<typeof Button> = {
  args: { variant: 'primary', children: 'Primary' },
};

export const Secondary: StoryObj<typeof Button> = {
  args: { variant: 'secondary', children: 'Secondary' },
};

export const Disabled: StoryObj<typeof Button> = {
  args: { disabled: true, children: 'Disabled' },
};
```

### Agent Commands

```bash
# Run Storybook locally
npm run storybook

# Build Storybook
npm run build-storybook

# Run Chromatic
npx chromatic --project-token=xxx
```

---

## 🔧 Cross-Platform Testing

Electron apps need testing on Windows, macOS, and Linux:

### CI Matrix

```yaml
# .github/workflows/visual-tests.yml
name: Visual Tests

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      
      - run: npm ci
      
      - run: npx playwright install
      
      - run: npm run build
      
      - run: npx playwright test --project=electron
        env:
          CI: true
      
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: screenshots-${{ matrix.os }}
          path: screenshots/
```

### Platform-Specific Baselines

```typescript
// playwright.config.js
import { defineConfig } from '@playwright/test';
import os from 'os';

const platform = os.platform(); // 'darwin', 'linux', 'win32'

export default defineConfig({
  snapshotDir: `./snapshots/${platform}`,
  // ...
});
```

---

## 🔍 Percy Integration

### Setup

```bash
npm install --save-dev @percy/cli @percy/playwright
```

### Usage

```typescript
import { test } from '@playwright/test';
import { _electron as electron } from '@playwright/test';
import { percySnapshot } from '@percy/playwright';

test('Percy snapshot', async () => {
  const electronApp = await electron.launch({ args: ['.'] });
  const window = await electronApp.firstWindow();
  await window.waitForLoadState();
  
  // Percy captures and compares in cloud
  await percySnapshot(window, 'Main Window');
  
  await electronApp.close();
});
```

### Agent Commands

```bash
# Run with Percy
PERCY_TOKEN=xxx npx percy exec -- npx playwright test --project=electron
```

---

## 📸 Native Screenshot Alternatives

For cases where Playwright isn't suitable:

### macOS

```bash
# Full screen
screencapture screenshot.png

# Specific window (by title)
screencapture -l $(osascript -e 'tell app "MyApp" to id of window 1') screenshot.png

# Region
screencapture -R 0,0,1280,800 screenshot.png
```

### Windows (PowerShell)

```powershell
# Full screen
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::PrimaryScreen | ForEach-Object {
    $bitmap = New-Object System.Drawing.Bitmap($_.Bounds.Width, $_.Bounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($_.Bounds.Location, [System.Drawing.Point]::Empty, $_.Bounds.Size)
    $bitmap.Save("screenshot.png")
}
```

### Linux

```bash
# Full screen (X11)
scrot screenshot.png

# Active window
scrot -u screenshot.png

# GNOME
gnome-screenshot -f screenshot.png

# KDE
spectacle -b -n -o screenshot.png
```

---

## 📝 Recipe Configuration

Add to recipe.yaml:

```yaml
visual_testing:
  platform: desktop-electron
  strategy: playwright-electron
  tools:
    primary: playwright
    component_testing: storybook
    visual_regression: chromatic
  window_sizes:
    small: [800, 600]
    normal: [1280, 800]
    large: [1920, 1080]
  themes:
    - light
    - dark
  agent_commands:
    playwright_test: "npx playwright test --project=electron"
    playwright_update: "npx playwright test --project=electron --update-snapshots"
    storybook: "npm run storybook"
    chromatic: "npx chromatic --project-token=xxx"
  ci_integration:
    platforms: [ubuntu-latest, windows-latest, macos-latest]
    platform_baselines: true
```

---

## 🚨 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Window not ready | Async initialization | Use `waitForLoadState()` + timeout |
| Different fonts per OS | System font rendering | Use bundled fonts |
| Snapshot mismatch on CI | Platform differences | Use platform-specific baselines |
| IPC not working | Main process timing | Wait for IPC ready signal |
| Menu bar included | Window chrome | Use `page.screenshot()` not window capture |

---

## 📋 Validation Checklist

- [ ] Main window screenshot captured
- [ ] All dialog/modal windows captured
- [ ] Window resize states tested
- [ ] Dark mode / light mode tested
- [ ] Component Storybook stories exist
- [ ] Cross-platform CI configured
- [ ] Platform-specific baselines managed

---

*Platform Pattern Version: 1.0.0*
