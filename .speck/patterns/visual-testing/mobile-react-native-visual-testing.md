# React Native / Expo Visual Testing Pattern

**Platform**: `mobile-rn`  
**Applicable Recipes**: expo-fastapi  
**Primary Tools**: Maestro, Detox, ADB, xcrun simctl, Fastlane

---

## 🎯 Overview

React Native visual testing combines E2E testing frameworks with platform-specific screenshot capture. **Maestro** is the recommended tool for autonomous agent testing due to its YAML-based declarative syntax.

---

## 🎭 Maestro (Recommended for Agents)

Maestro uses YAML-based flows that are perfect for autonomous agent generation and execution.

### Installation

```bash
# macOS
curl -Ls "https://get.maestro.mobile.dev" | bash

# Verify installation
maestro --version
```

### Basic Flow

```yaml
# flows/login_flow.yaml
appId: com.myapp
---
- launchApp
- assertVisible: "Welcome"
- takeScreenshot: "01_welcome_screen"

- tapOn: "Sign In"
- assertVisible: "Email"
- takeScreenshot: "02_login_form"

- inputText:
    id: "email-input"
    text: "test@example.com"
- inputText:
    id: "password-input"
    text: "password123"
- takeScreenshot: "03_form_filled"

- tapOn: "Submit"
- assertVisible: "Dashboard"
- takeScreenshot: "04_dashboard"
```

### Visual Regression Flow

```yaml
# flows/visual_regression.yaml
appId: com.myapp
---
- launchApp
- assertVisible: "Home"

# Capture all main screens
- takeScreenshot: "home_screen"

- tapOn: "Profile"
- takeScreenshot: "profile_screen"

- tapOn: "Settings"
- takeScreenshot: "settings_screen"

- tapOn: "Help"
- takeScreenshot: "help_screen"
```

### State Testing

```yaml
# flows/button_states.yaml
appId: com.myapp
---
- launchApp
- tapOn: "Components"
- tapOn: "Button"

# Default state
- takeScreenshot: "button_default"

# Pressed state (long press)
- longPressOn: "Primary Button"
- takeScreenshot: "button_pressed"

# Disabled state
- tapOn: "Toggle Disabled"
- takeScreenshot: "button_disabled"

# Loading state
- tapOn: "Toggle Loading"
- takeScreenshot: "button_loading"
```

### Agent Commands

```bash
# Run single flow
maestro test flows/login_flow.yaml

# Run all flows
maestro test flows/

# Run on specific device
maestro test --device "iPhone 15" flows/

# Run with output directory
maestro test --output ./screenshots flows/

# Record flow interactively (agent can then modify YAML)
maestro studio
```

---

## 🧪 Detox Testing

Detox provides synchronized, reliable E2E testing for React Native:

### Setup

```bash
npm install --save-dev detox
detox init
```

### Visual Test

```javascript
// e2e/visual.test.js
describe('Visual Tests', () => {
  beforeAll(async () => {
    await device.launchApp();
  });

  it('should capture home screen', async () => {
    await expect(element(by.text('Welcome'))).toBeVisible();
    await device.takeScreenshot('home_screen');
  });

  it('should capture login flow', async () => {
    await element(by.id('login-button')).tap();
    await device.takeScreenshot('login_form');

    await element(by.id('email-input')).typeText('test@example.com');
    await element(by.id('password-input')).typeText('password123');
    await device.takeScreenshot('form_filled');

    await element(by.id('submit-button')).tap();
    await expect(element(by.text('Dashboard'))).toBeVisible();
    await device.takeScreenshot('dashboard');
  });

  it('should test button states', async () => {
    await element(by.id('nav-components')).tap();
    
    // Default state
    await device.takeScreenshot('button_default');
    
    // Hover/focus simulation
    await element(by.id('primary-button')).longPress();
    await device.takeScreenshot('button_pressed');
  });
});
```

### Agent Commands

```bash
# Build for testing
detox build --configuration ios.sim.debug

# Run tests
detox test --configuration ios.sim.debug

# Run with screenshots
detox test --configuration ios.sim.debug --take-screenshots all

# Run specific test file
detox test --configuration ios.sim.debug e2e/visual.test.js
```

---

## 📱 Android Emulator Control (ADB)

### Emulator Management

```bash
# List available AVDs
emulator -list-avds

# Start emulator
emulator -avd Pixel_6_API_33 &

# Wait for device to be ready
adb wait-for-device
adb shell getprop sys.boot_completed | grep -q 1
```

### Screenshot Capture

```bash
# Take screenshot (fast method)
adb exec-out screencap -p > screenshot.png

# Take screenshot with device storage
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png
adb shell rm /sdcard/screen.png
```

### Video Recording

```bash
# Start recording (max 180 seconds default)
adb shell screenrecord /sdcard/recording.mp4 --time-limit 60

# Pull recording
adb pull /sdcard/recording.mp4
```

### Demo Mode (Consistent Status Bar)

```bash
# Enable Demo Mode
adb shell settings put global sysui_demo_allowed 1

# Set clean status bar
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e level 4 -e datatype none
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false

# Take clean screenshot
adb exec-out screencap -p > clean_screenshot.png

# Disable Demo Mode
adb shell am broadcast -a com.android.systemui.demo -e command exit
```

### Screen Size Override (Responsive Testing)

```bash
# Override display size
adb shell wm size 1080x1920  # Standard phone
adb shell wm size 1080x2340  # Tall phone
adb shell wm size 1600x2560  # Tablet

# Reset to default
adb shell wm size reset
```

---

## 🍎 iOS Simulator Control (xcrun simctl)

### Simulator Management

```bash
# List available simulators
xcrun simctl list devices

# Boot specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Shutdown simulator
xcrun simctl shutdown booted
```

### Screenshot Capture

```bash
# Take screenshot
xcrun simctl io booted screenshot screenshot.png

# Take screenshot with mask (for notch handling)
xcrun simctl io booted screenshot --type=png --mask=black screenshot.png

# Supported formats: png, tiff, bmp, gif, jpeg
xcrun simctl io booted screenshot --type=jpeg screenshot.jpg
```

### Video Recording

```bash
# Start recording
xcrun simctl io booted recordVideo --codec=hevc recording.mp4

# Press Ctrl+C to stop

# With specific codec
xcrun simctl io booted recordVideo --codec=h264 recording.mp4
```

### Status Bar Override

```bash
# Set clean status bar
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --dataNetwork wifi

# Take clean screenshot
xcrun simctl io booted screenshot clean_screenshot.png

# Clear status bar override
xcrun simctl status_bar booted clear
```

### Dark Mode Testing

```bash
# Enable dark mode
xcrun simctl ui booted appearance dark

# Enable light mode
xcrun simctl ui booted appearance light
```

---

## 🚀 Fastlane Integration

### iOS Screenshots (snapshot)

```ruby
# fastlane/Snapfile
devices([
  "iPhone SE (3rd generation)",
  "iPhone 15",
  "iPhone 15 Pro Max",
  "iPad Pro (12.9-inch) (6th generation)"
])

languages(["en-US", "de-DE", "ja"])

scheme("MyAppUITests")
output_directory("./screenshots/ios")
clear_previous_screenshots(true)

# Override status bar
override_status_bar(true)
override_status_bar_arguments("--time 9:41 --batteryState charged --batteryLevel 100")
```

### Android Screenshots (screengrab)

```ruby
# fastlane/Screengrabfile
locales(['en-US', 'de-DE', 'ja'])
clear_previous_screenshots(true)

app_package_name('com.myapp')
tests_package_name('com.myapp.test')
use_tests_in_classes(['com.myapp.ScreenshotTests'])

output_directory('./screenshots/android')
```

### Fastlane Lane

```ruby
# fastlane/Fastfile
desc "Capture all screenshots"
lane :screenshots do
  # iOS
  capture_screenshots(scheme: "MyAppUITests")
  
  # Android
  screengrab
  
  # Upload to cloud (optional)
  upload_to_app_store(skip_metadata: true, skip_binary_upload: true)
end
```

### Agent Commands

```bash
# iOS screenshots
cd ios && fastlane snapshot

# Android screenshots
cd android && fastlane screengrab

# Full screenshot workflow
fastlane screenshots
```

---

## 🔍 Percy Integration

### Setup

```bash
npm install --save-dev @percy/cli @percy/webdriver-utils
```

### With Detox

```javascript
// e2e/percy.test.js
const { percyScreenshot } = require('@percy/webdriver-utils');

describe('Percy Visual Tests', () => {
  it('should capture screens with Percy', async () => {
    await device.launchApp();
    
    // Capture with Percy (cloud comparison)
    await percyScreenshot('Home Screen');
    
    await element(by.id('login')).tap();
    await percyScreenshot('Login Screen');
  });
});
```

### Agent Commands

```bash
# Run with Percy
PERCY_TOKEN=xxx npx percy app:exec -- detox test
```

---

## 📊 Device Matrix

### Recommended Test Devices

| Category | iOS | Android |
|----------|-----|---------|
| Small | iPhone SE (375×667) | Pixel 4a (360×760) |
| Standard | iPhone 15 (393×852) | Pixel 8 (411×915) |
| Large | iPhone 15 Pro Max (430×932) | Pixel 8 Pro (448×998) |
| Tablet | iPad (768×1024) | Pixel Tablet (800×1280) |

### Maestro Device Selection

```bash
# List connected devices
maestro devices

# Run on specific device
maestro test --device "iPhone 15" flows/
maestro test --device "Pixel 8" flows/
```

---

## 📝 Recipe Configuration

Add to recipe.yaml:

```yaml
visual_testing:
  platform: mobile-rn
  strategy: maestro
  tools:
    primary: maestro
    e2e: detox
    screenshot_automation: fastlane
    visual_regression: percy
  devices:
    ios:
      - "iPhone SE (3rd generation)"
      - "iPhone 15"
      - "iPhone 15 Pro Max"
    android:
      - "Pixel 4a"
      - "Pixel 8"
      - "Pixel 8 Pro"
  agent_commands:
    maestro_test: "maestro test flows/"
    maestro_studio: "maestro studio"
    detox_build: "detox build --configuration ios.sim.debug"
    detox_test: "detox test --configuration ios.sim.debug"
    ios_screenshot: "xcrun simctl io booted screenshot"
    android_screenshot: "adb exec-out screencap -p"
    ios_status_bar: "xcrun simctl status_bar booted override"
    android_demo_mode: "adb shell am broadcast -a com.android.systemui.demo"
    fastlane_ios: "cd ios && fastlane snapshot"
    fastlane_android: "cd android && fastlane screengrab"
  ci_integration:
    on_pr: true
    block_on_diff: true
```

---

## 🚨 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Flaky tests | Async rendering | Use Maestro's built-in waiting |
| Status bar varies | Dynamic content | Use Demo Mode / status_bar override |
| Screenshots differ | Font rendering | Use consistent device/simulator |
| Slow tests | Cold start | Keep emulator/simulator running |
| Permission dialogs | First launch | Dismiss in test setup |

---

## 📋 Validation Checklist

- [ ] Maestro flows exist for all key user journeys
- [ ] Screenshots captured on all target devices
- [ ] Status bar normalized before screenshots
- [ ] Dark mode variations tested
- [ ] Tablet layouts tested (if supported)
- [ ] Fastlane configured for app store screenshots
- [ ] CI pipeline includes visual tests

---

*Platform Pattern Version: 1.0.0*
