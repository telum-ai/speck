---
name: visual-testing-mobile-react-native
description: Load when running visual validation for React Native/Expo mobile applications. Provides Maestro flows, Detox patterns, and ADB/simctl commands for device screenshots.
---

# React Native / Expo Visual Testing

**Platform**: `mobile-rn`  
**Applicable Recipes**: expo-fastapi  
**Primary Tools**: Maestro, Detox, ADB, xcrun simctl, Fastlane

---

## 🔄 Tight Loop (Default)

**Goal**: Get deterministic screenshots quickly using Maestro flows (agent-friendly, low flake).

**Start Small**:
- **Flows**: Create/extend 1–2 Maestro flows for the story's main user journey
- **States**: Capture default + error/empty + loading (as applicable)
- **Devices**: One iOS simulator + one Android emulator first

**Run Order**:
1. Execute flows: `maestro test flows/`
2. Review captured screenshots for obvious regressions
3. If differences are intended: update baselines; otherwise fix UI

**Expand Only When**:
- Story covers multiple device sizes
- Need full device matrix for release
- Epic validation requires cross-device consistency

---

## 🎭 Maestro (Recommended)

Maestro is YAML-based, making it ideal for agent generation and execution.

### Basic Flow with Screenshots

```yaml
# flows/login-flow.yaml
appId: com.example.myapp
---
- launchApp
- assertVisible: "Welcome"
- takeScreenshot: screenshots/login-screen

- tapOn: "Email"
- inputText: "user@example.com"
- tapOn: "Password"
- inputText: "password123"
- takeScreenshot: screenshots/login-filled

- tapOn: "Sign In"
- assertVisible: "Dashboard"
- takeScreenshot: screenshots/dashboard
```

### Running Maestro

```bash
# Run all flows
maestro test flows/

# Run specific flow
maestro test flows/login-flow.yaml

# Record a new flow interactively
maestro record flows/new-flow.yaml
```

### State Testing with Maestro

```yaml
# flows/error-states.yaml
appId: com.example.myapp
---
# Network error state
- launchApp:
    clearState: true
- runScript: 
    file: scripts/mock-network-error.js
- tapOn: "Refresh"
- takeScreenshot: screenshots/network-error

# Empty state
- launchApp:
    clearState: true
- assertVisible: "No items yet"
- takeScreenshot: screenshots/empty-state

# Loading state
- launchApp
- takeScreenshot: screenshots/loading-state
```

---

## 📱 Device Commands

### iOS Simulator

```bash
# List simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"

# Take screenshot
xcrun simctl io booted screenshot ~/screenshots/ios-screen.png

# Clean status bar for app store quality
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --cellularMode active \
  --cellularBars 4
xcrun simctl io booted screenshot ~/screenshots/ios-clean.png

# Dark mode toggle
xcrun simctl ui booted appearance dark
xcrun simctl io booted screenshot ~/screenshots/ios-dark.png

# Reset to light mode
xcrun simctl ui booted appearance light
```

### Android Emulator

```bash
# List emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_8_API_34 &

# Wait for boot
adb wait-for-device

# Take screenshot
adb exec-out screencap -p > ~/screenshots/android-screen.png

# Demo mode for clean status bar
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb exec-out screencap -p > ~/screenshots/android-clean.png

# Exit demo mode
adb shell am broadcast -a com.android.systemui.demo -e command exit

# Screen size override
adb shell wm size 1080x2340
adb exec-out screencap -p > ~/screenshots/android-custom-size.png
adb shell wm size reset
```

---

## 🧪 Detox (E2E Testing)

For more complex testing scenarios:

### Test with Screenshots

```javascript
// e2e/login.test.js
describe('Login', () => {
  beforeAll(async () => {
    await device.launchApp();
  });

  it('should show login screen', async () => {
    await expect(element(by.text('Welcome'))).toBeVisible();
    await device.takeScreenshot('login-screen');
  });

  it('should show error on invalid login', async () => {
    await element(by.id('email')).typeText('invalid@email');
    await element(by.id('password')).typeText('wrong');
    await element(by.text('Sign In')).tap();
    
    await expect(element(by.text('Invalid credentials'))).toBeVisible();
    await device.takeScreenshot('login-error');
  });
});
```

### Running Detox

```bash
# Build for testing
detox build --configuration ios.sim.debug

# Run tests
detox test --configuration ios.sim.debug

# Run specific test file
detox test --configuration ios.sim.debug e2e/login.test.js
```

---

## 📸 Fastlane Screenshots

For automated app store screenshots:

### iOS

```ruby
# fastlane/Snapfile
devices([
  "iPhone 15 Pro Max",
  "iPhone SE (3rd generation)",
  "iPad Pro 12.9-inch"
])

languages(["en-US"])
scheme("MyApp")
output_directory("./screenshots/ios")
```

```bash
fastlane snapshot
```

### Android

```ruby
# fastlane/Screengrabfile
locales(['en-US'])
app_package_name('com.example.myapp')
use_adb_root(true)
```

```bash
fastlane screengrab
```

---

## 📏 Standard Device Matrix

### iOS Devices

| Category | Device | Resolution |
|----------|--------|------------|
| Small Phone | iPhone SE | 375×667 |
| Standard Phone | iPhone 15 | 393×852 |
| Large Phone | iPhone 15 Pro Max | 430×932 |
| Tablet | iPad | 768×1024 |

### Android Devices

| Category | Device | Resolution |
|----------|--------|------------|
| Small Phone | Pixel 4a | 360×760 |
| Standard Phone | Pixel 8 | 411×915 |
| Large Phone | Pixel 8 Pro | 448×998 |
| Tablet | Pixel Tablet | 800×1280 |

**Tight Loop**: Start with iPhone 15 + Pixel 8 only.

---

## ✅ Validation Checklist

Verify these for each validation:

- [ ] Maestro flows execute without errors
- [ ] Key screens captured on iOS simulator
- [ ] Key screens captured on Android emulator
- [ ] Error/empty states tested
- [ ] No visual regressions from baselines
- [ ] Text renders correctly (no truncation)
- [ ] Touch targets are appropriately sized (44×44pt minimum)
- [ ] Dark mode tested (if app supports it)

---

## 📁 Screenshot Organization

```
screenshots/
├── ios/
│   ├── login-iphone15.png
│   ├── dashboard-iphone15.png
│   └── settings-ipad.png
├── android/
│   ├── login-pixel8.png
│   ├── dashboard-pixel8.png
│   └── settings-tablet.png
└── flows/
    ├── login-flow/
    │   ├── step-1-welcome.png
    │   ├── step-2-filled.png
    │   └── step-3-dashboard.png
    └── error-states/
        ├── network-error.png
        └── empty-state.png
```

---

## 🔗 Storybook Integration

If using React Native Storybook:

```bash
# Run Storybook
npm run storybook:native

# Or with Expo
expo start --dev-client
```

Capture component stories for isolated testing.
