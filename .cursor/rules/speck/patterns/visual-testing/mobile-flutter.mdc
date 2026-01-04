---
name: visual-testing-mobile-flutter
description: Load when running visual validation for Flutter mobile applications. Provides Golden Tests, Alchemist, and Fastlane patterns for widget rendering and theme variations.
---

# Flutter Visual Testing

**Platform**: `mobile-flutter`  
**Applicable Recipes**: flutter-firebase  
**Primary Tools**: Flutter Golden Tests, Alchemist, Widgetbook, Fastlane

---

## 🔄 Tight Loop (Default)

**Goal**: Catch UI regressions immediately via goldens before doing full device screenshot runs.

**Start Small**:
- **Widgets**: Add/update goldens for 1–3 widgets/screens changed in this story
- **Themes**: Cover light + dark if the app supports both
- **Sizes**: One "phone-sized" constraint first; add tablet only if layout changes

**Run Order**:
1. Run goldens: `flutter test test/goldens/`
2. If failures: Fix UI or update baselines (only when change is intended)
3. Only then (optional): Capture emulator/simulator screenshots for app-store visuals

**Expand Only When**:
- Story explicitly covers tablet layouts
- Need app store screenshots (Fastlane)
- Epic validation requires device matrix

---

## 🧪 Golden Tests

Flutter's golden testing captures widget renders as images and compares against baselines.

### Basic Golden Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/button.dart';

void main() {
  testWidgets('MyButton golden', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyButton(label: 'Click me'),
        ),
      ),
    );
    
    await expectLater(
      find.byType(MyButton),
      matchesGoldenFile('goldens/my_button.png'),
    );
  });
}
```

### Running Golden Tests

```bash
# Run golden tests
flutter test test/goldens/

# Update goldens when changes are intentional
flutter test --update-goldens test/goldens/
```

---

## 🎨 Theme Variation Testing

Test both light and dark themes:

```dart
void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('MyWidget ${brightness.name} theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: MyWidget(),
        ),
      );
      
      await expectLater(
        find.byType(MyWidget),
        matchesGoldenFile('goldens/my_widget_${brightness.name}.png'),
      );
    });
  }
}
```

---

## 📱 Device Size Constraints

Test different screen sizes:

```dart
void main() {
  final devices = {
    'phone': Size(375, 667),
    'tablet': Size(768, 1024),
  };
  
  for (final entry in devices.entries) {
    testWidgets('Screen on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      
      await tester.pumpWidget(MyApp());
      
      await expectLater(
        find.byType(MyApp),
        matchesGoldenFile('goldens/screen_${entry.key}.png'),
      );
    });
  }
}
```

---

## ⚗️ Alchemist (Advanced Golden Testing)

Alchemist provides more sophisticated golden testing with scenarios:

```dart
import 'package:alchemist/alchemist.dart';

void main() {
  goldenTest(
    'MyButton states',
    fileName: 'my_button_states',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'default',
          child: MyButton(label: 'Default'),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: MyButton(label: 'Disabled', enabled: false),
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

---

## 📲 Emulator/Simulator Screenshots

For app store or integration testing, capture from real devices:

### iOS Simulator

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 15 Pro"

# Take screenshot
xcrun simctl io booted screenshot ~/Desktop/screenshot.png

# With status bar cleaned up
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100
xcrun simctl io booted screenshot screenshot.png
```

### Android Emulator

```bash
# List available emulators
emulator -list-avds

# Start emulator
emulator -avd Pixel_8_API_34 &

# Take screenshot
adb exec-out screencap -p > screenshot.png

# Set demo mode for clean status bar
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb exec-out screencap -p > screenshot.png
```

---

## 📸 Fastlane Screenshots

For automated app store screenshots:

### iOS (Fastlane Snapshot)

```ruby
# Snapfile
devices([
  "iPhone 15 Pro Max",
  "iPhone SE (3rd generation)",
  "iPad Pro (12.9-inch)"
])

languages(["en-US"])

scheme("MyApp")
output_directory("./screenshots")
clear_previous_screenshots(true)
```

```bash
fastlane snapshot
```

### Android (Fastlane Screengrab)

```ruby
# Screengrabfile
locales(['en-US'])
app_package_name('com.example.myapp')
app_apk_path('build/app/outputs/apk/debug/app-debug.apk')
tests_apk_path('build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk')
```

```bash
fastlane screengrab
```

---

## ✅ Validation Checklist

Verify these for each validation:

- [ ] Golden tests pass for changed widgets
- [ ] Light and dark themes tested
- [ ] Key screen sizes covered (phone at minimum)
- [ ] No golden file regressions
- [ ] Widget states tested (default, disabled, loading, error)
- [ ] Text renders correctly (no overflow)
- [ ] Colors match design system tokens

---

## 📁 Golden File Organization

```
test/
├── goldens/
│   ├── widgets/
│   │   ├── button_light.png
│   │   ├── button_dark.png
│   │   └── button_states.png
│   ├── screens/
│   │   ├── home_phone.png
│   │   ├── home_tablet.png
│   │   └── settings.png
│   └── components/
│       └── header.png
```

---

## 🔗 Widgetbook Integration

If using Widgetbook for component documentation:

```bash
# Run Widgetbook
flutter run -d chrome -t lib/widgetbook.dart
```

Capture screenshots of catalogued components for comprehensive coverage.
