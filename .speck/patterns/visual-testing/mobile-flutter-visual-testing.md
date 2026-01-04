# Flutter Visual Testing Pattern

**Platform**: `mobile-flutter`  
**Applicable Recipes**: flutter-firebase  
**Primary Tools**: Flutter Golden Tests, Alchemist, Widgetbook, Fastlane

---

## 🎯 Overview

Flutter's golden testing system captures widget renders as images and compares them against baseline "golden files". This pattern covers widget visual regression, responsive testing, and theme variations.

---

## Tight Loop (Default)

**Goal**: Catch UI regressions immediately via goldens before doing full device screenshot runs.

**Start Small**:
- Add/update goldens for the 1–3 widgets/screens changed in this story
- Cover **light + dark** if the app supports it
- Cover **one “phone-sized” constraint** first; add tablet constraints only if layout changes

**Run**:
1. Run goldens: `flutter test test/goldens/`
2. If failures: fix UI or update baselines (only when change is intended)
3. Only then (optional): capture emulator/simulator screenshots for app-store-level visuals

---

## 🧪 Flutter Golden Tests

### Basic Golden Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/button.dart';

void main() {
  testWidgets('Button renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyButton(label: 'Click me'),
        ),
      ),
    );

    await expectLater(
      find.byType(MyButton),
      matchesGoldenFile('goldens/button_default.png'),
    );
  });
}
```

### Agent Commands

```bash
# Generate/update golden files
flutter test --update-goldens

# Run golden tests
flutter test test/goldens/

# Run specific test file
flutter test test/goldens/button_test.dart --update-goldens
```

---

## 🧪 Alchemist Framework

Alchemist provides a declarative, terse API for golden tests with better organization:

### Installation

```yaml
# pubspec.yaml
dev_dependencies:
  alchemist: ^0.7.0
```

### Usage

```dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  goldenTest(
    'Button variants',
    fileName: 'button_variants',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default',
          child: MyButton(label: 'Default'),
        ),
        GoldenTestScenario(
          name: 'primary',
          child: MyButton(label: 'Primary', variant: ButtonVariant.primary),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: MyButton(label: 'Disabled', disabled: true),
        ),
        GoldenTestScenario(
          name: 'loading',
          child: MyButton(label: 'Loading', loading: true),
        ),
      ],
    ),
  );
}
```

### Theme Variations

```dart
goldenTest(
  'Button in themes',
  fileName: 'button_themes',
  builder: () => GoldenTestGroup(
    scenarioConstraints: BoxConstraints(maxWidth: 300),
    children: [
      GoldenTestScenario(
        name: 'light_theme',
        child: Theme(
          data: ThemeData.light(),
          child: MyButton(label: 'Light'),
        ),
      ),
      GoldenTestScenario(
        name: 'dark_theme',
        child: Theme(
          data: ThemeData.dark(),
          child: MyButton(label: 'Dark'),
        ),
      ),
    ],
  ),
);
```

### Screen Size Testing

```dart
goldenTest(
  'Dashboard responsive',
  fileName: 'dashboard_responsive',
  builder: () => GoldenTestGroup(
    children: [
      GoldenTestScenario(
        name: 'mobile',
        constraints: BoxConstraints(maxWidth: 375, maxHeight: 667),
        child: DashboardScreen(),
      ),
      GoldenTestScenario(
        name: 'tablet',
        constraints: BoxConstraints(maxWidth: 768, maxHeight: 1024),
        child: DashboardScreen(),
      ),
      GoldenTestScenario(
        name: 'desktop',
        constraints: BoxConstraints(maxWidth: 1280, maxHeight: 800),
        child: DashboardScreen(),
      ),
    ],
  ),
);
```

### Agent Commands

```bash
# Generate goldens
flutter test --update-goldens

# Run tests with Alchemist
flutter test test/goldens/

# CI mode (platform-agnostic)
flutter test --dart-define=CI=true
```

---

## 📚 Widgetbook Integration

Widgetbook provides a component catalog that auto-generates golden tests:

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  widgetbook: ^3.0.0
  widgetbook_annotation: ^3.0.0
  widgetbook_generator: ^3.0.0
  build_runner: ^2.0.0
```

### Define Use Cases

```dart
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: MyButton)
Widget defaultButton(BuildContext context) {
  return MyButton(label: 'Click me');
}

@UseCase(name: 'Primary', type: MyButton)
Widget primaryButton(BuildContext context) {
  return MyButton(label: 'Primary', variant: ButtonVariant.primary);
}
```

### Run Widgetbook

```bash
# Generate code
flutter pub run build_runner build

# Run Widgetbook locally
flutter run -d chrome -t lib/widgetbook.dart
```

### Widgetbook Cloud (Visual Regression)

```bash
# Run visual regression in cloud
widgetbook-cli upload --api-key=xxx
```

---

## 📱 Device Testing

### Android Emulator Screenshots

```bash
# List emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_6_API_33 &

# Wait for boot
adb wait-for-device

# Take screenshot
adb exec-out screencap -p > screenshot.png

# Enable Demo Mode (consistent status bar)
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4

# Take clean screenshot
adb exec-out screencap -p > screenshot_clean.png

# Disable Demo Mode
adb shell am broadcast -a com.android.systemui.demo -e command exit
```

### iOS Simulator Screenshots

```bash
# List simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"

# Override status bar (consistent for screenshots)
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --wifiBars 3 \
  --cellularBars 4

# Take screenshot
xcrun simctl io booted screenshot screenshot.png

# Clear status bar override
xcrun simctl status_bar booted clear
```

---

## 🚀 Fastlane Integration

### iOS Screenshots (Snapfile)

```ruby
# fastlane/Snapfile
devices([
  "iPhone SE (3rd generation)",
  "iPhone 15",
  "iPhone 15 Pro Max",
  "iPad Pro (12.9-inch) (6th generation)"
])

languages(["en-US", "de-DE", "ja", "es"])

scheme("Runner")
output_directory("./screenshots")
clear_previous_screenshots(true)
```

### Android Screenshots (Screengrabfile)

```ruby
# fastlane/Screengrabfile
locales(['en-US', 'de-DE', 'ja', 'es'])
clear_previous_screenshots(true)
app_package_name('com.example.myapp')
tests_package_name('com.example.myapp.test')
use_tests_in_classes(['com.example.myapp.Screenshots'])
```

### Agent Commands

```bash
# iOS screenshots
cd ios && fastlane snapshot

# Android screenshots
cd android && fastlane screengrab

# Both platforms
fastlane screenshots
```

---

## 🔧 Integration Testing

### Flutter Integration Test with Screenshots

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Screenshot flow', (tester) async {
    await tester.pumpWidget(MyApp());

    // Wait for app to load
    await tester.pumpAndSettle();

    // Take screenshot
    await binding.takeScreenshot('home_screen');

    // Navigate and screenshot
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('login_screen');
  });
}
```

### Agent Commands

```bash
# Run integration tests
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d "iPhone 15"

# Run on Android emulator
flutter test integration_test/ -d emulator-5554
```

---

## 📊 Platform-Specific Baselines

Flutter renders differently on macOS, Windows, and Linux due to font rendering. Use platform-specific baselines:

### CI Configuration

```yaml
# .github/workflows/golden_tests.yml
jobs:
  golden-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
      - run: flutter test test/goldens/ --update-goldens
      - uses: actions/upload-artifact@v3
        with:
          name: goldens-linux
          path: test/goldens/**/goldens/

  golden-macos:
    runs-on: macos-latest
    steps:
      - uses: subosito/flutter-action@v2
      - run: flutter test test/goldens/
```

### Directory Structure

```
test/
├── goldens/
│   ├── button_test.dart
│   └── goldens/
│       ├── ci/          # CI baselines (Linux)
│       │   └── button_variants.png
│       └── local/       # Local baselines (macOS/Windows)
│           └── button_variants.png
```

---

## 📝 Recipe Configuration

Add to recipe.yaml:

```yaml
visual_testing:
  platform: mobile-flutter
  strategy: golden-tests
  tools:
    primary: alchemist
    component_catalog: widgetbook
    screenshot_automation: fastlane
  devices:
    ios:
      - "iPhone SE (3rd generation)"
      - "iPhone 15"
      - "iPhone 15 Pro Max"
      - "iPad Pro (12.9-inch)"
    android:
      - "Pixel 4a"
      - "Pixel 8"
      - "Pixel Fold"
  agent_commands:
    update_goldens: "flutter test --update-goldens"
    run_goldens: "flutter test test/goldens/"
    ios_screenshot: "xcrun simctl io booted screenshot"
    android_screenshot: "adb exec-out screencap -p"
    fastlane_ios: "cd ios && fastlane snapshot"
    fastlane_android: "cd android && fastlane screengrab"
  ci_integration:
    platform_baselines: true
    runs_on: ubuntu-latest
```

---

## 🚨 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Golden mismatch on CI | Font rendering differences | Use platform-specific baselines |
| Flaky animation tests | Unfinished animations | Use `pumpAndSettle()` |
| Text rendering varies | System fonts | Bundle custom fonts |
| Status bar inconsistent | Dynamic content | Use Demo Mode (Android) or status_bar override (iOS) |
| Large golden files | High resolution | Use appropriate constraints |

---

## 📋 Validation Checklist

- [ ] Golden tests exist for all custom widgets
- [ ] Theme variations tested (light/dark)
- [ ] Responsive layouts tested (mobile/tablet/desktop)
- [ ] Integration tests capture key flows
- [ ] Fastlane configured for app store screenshots
- [ ] CI pipeline includes golden test validation
- [ ] Platform-specific baselines managed correctly

---

*Platform Pattern Version: 1.0.0*
