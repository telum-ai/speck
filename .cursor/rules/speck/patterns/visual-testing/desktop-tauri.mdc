---
name: visual-testing-desktop-tauri
description: Load when running visual validation for Tauri desktop applications. Provides WebdriverIO and tauri-driver patterns with platform-specific baseline guidance.
---

# Tauri Visual Testing

**Platform**: `desktop-tauri`  
**Applicable Recipes**: tauri-react  
**Primary Tools**: WebdriverIO, tauri-driver, Storybook

---

## 🔄 Tight Loop (Default)

**Goal**: Validate the key changed UI flow on the current OS, fast, with minimal flake.

**Start Small**:
- **Flows**: Run WebdriverIO suite for 1–2 flows touched by the story
- **Sizes**: Normal window size first
- **Platform**: Current OS only (Tauri renders differently per OS)

**Run Order**:
1. Build: `cargo tauri build`
2. Visual test: `npx wdio run wdio.conf.js`
3. If diffs occur: Update only the baseline for current platform when intended

**Expand Only When**:
- Story covers window resize behavior
- Release requires all three platforms (macOS, Windows, Linux)
- Epic validation requires cross-platform consistency

---

## ⚠️ Platform Rendering Differences

**Critical**: Tauri uses native platform WebViews:
- **macOS**: Safari/WebKit
- **Windows**: Edge WebView2
- **Linux**: WebKitGTK

This means **visual output differs per platform**. Maintain separate baselines for each.

```
screenshots/
├── darwin/
│   ├── main-window.png
│   └── settings.png
├── win32/
│   ├── main-window.png
│   └── settings.png
└── linux/
    ├── main-window.png
    └── settings.png
```

---

## 🔧 WebdriverIO Setup

### Configuration

```javascript
// wdio.conf.js
const path = require('path');

exports.config = {
  specs: ['./tests/**/*.spec.js'],
  capabilities: [{
    'tauri:options': {
      application: path.resolve('./src-tauri/target/release/bundle/macos/MyApp.app'),
    },
  }],
  services: ['tauri'],
  framework: 'mocha',
  reporters: ['spec'],
};
```

### Installing tauri-driver

```bash
# Install tauri-driver
cargo install tauri-driver

# Or via npm (if using the wrapper)
npm install --save-dev @tauri-apps/driver
```

---

## 🧪 Writing Visual Tests

### Basic Screenshot Test

```javascript
// tests/visual.spec.js
describe('Visual Tests', () => {
  it('should match main window', async () => {
    const screenshot = await browser.takeScreenshot();
    await expect(screenshot).toMatchScreenshot('main-window', {
      // Platform-specific baseline
      baselineFolder: `./baselines/${process.platform}`,
    });
  });

  it('should match settings page', async () => {
    await $('[data-testid="settings-btn"]').click();
    await browser.pause(500); // Wait for navigation
    
    const screenshot = await browser.takeScreenshot();
    await expect(screenshot).toMatchScreenshot('settings', {
      baselineFolder: `./baselines/${process.platform}`,
    });
  });
});
```

### Window State Testing

```javascript
describe('Window States', () => {
  it('should handle resize', async () => {
    // Normal size
    await browser.setWindowSize(1280, 800);
    await browser.pause(300);
    let screenshot = await browser.takeScreenshot();
    await expect(screenshot).toMatchScreenshot('window-normal');

    // Small size
    await browser.setWindowSize(800, 600);
    await browser.pause(300);
    screenshot = await browser.takeScreenshot();
    await expect(screenshot).toMatchScreenshot('window-small');
  });
});
```

---

## 🖥️ Platform-Specific Builds

Build for each platform before testing:

```bash
# macOS
cargo tauri build --target universal-apple-darwin

# Windows
cargo tauri build --target x86_64-pc-windows-msvc

# Linux
cargo tauri build --target x86_64-unknown-linux-gnu
```

### CI Matrix Example

```yaml
# .github/workflows/visual-tests.yml
jobs:
  visual-test:
    strategy:
      matrix:
        os: [macos-latest, windows-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: cargo tauri build
      - name: Visual Tests
        run: npx wdio run wdio.conf.js
      - name: Upload screenshots
        uses: actions/upload-artifact@v4
        with:
          name: screenshots-${{ matrix.os }}
          path: ./screenshots/
```

---

## 📸 Native Screenshot Commands

For manual validation or when WebdriverIO isn't suitable:

### macOS

```bash
# Full screen
screencapture -x ~/screenshots/macos-full.png

# Window only (interactive click)
screencapture -w ~/screenshots/macos-window.png

# Specific window by name (requires additional tooling)
screencapture -l $(osascript -e 'tell app "MyApp" to id of window 1') ~/screenshots/macos-app.png
```

### Windows (PowerShell)

```powershell
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::PrimaryScreen | ForEach-Object {
    $bitmap = New-Object System.Drawing.Bitmap($_.Bounds.Width, $_.Bounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($_.Bounds.Location, [System.Drawing.Point]::Empty, $_.Bounds.Size)
    $bitmap.Save("$HOME\screenshots\windows-screen.png")
}
```

### Linux

```bash
# Using scrot
scrot ~/screenshots/linux-screen.png

# Using gnome-screenshot
gnome-screenshot -f ~/screenshots/linux-screen.png

# Using import (ImageMagick)
import -window root ~/screenshots/linux-screen.png
```

---

## ✅ Validation Checklist

Verify these for each validation:

- [ ] Main window captured on current platform
- [ ] Key routes/screens captured
- [ ] Platform-specific baseline used
- [ ] Window resize behavior tested (if in scope)
- [ ] No visual regressions from baseline
- [ ] Text renders correctly (check font rendering)
- [ ] Colors match design system tokens
- [ ] Cross-platform CI configured for release

---

## 🔗 Storybook Integration

If using Storybook for the frontend (React/Vue/Svelte):

```bash
# Run Storybook for frontend components
npm run storybook
```

Test components in isolation before Tauri integration. Use Percy or Chromatic for Storybook visual regression.

---

## 📝 Notes on Font Rendering

Fonts render differently across platforms:
- **macOS**: Subpixel antialiasing (smooth)
- **Windows**: ClearType (sharper)
- **Linux**: Variable by distro/config

Consider using:
1. Platform-specific baselines (recommended)
2. Higher tolerance thresholds for font areas
3. Web-safe fonts with consistent cross-platform rendering
