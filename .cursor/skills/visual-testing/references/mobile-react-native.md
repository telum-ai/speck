# React Native host

1. Build and launch the production-like app on one representative simulator/emulator.
2. Run or add 1–2 Maestro flows for the changed journey; use Detox only where lower-level control is required.
3. Capture default plus relevant loading/empty/error and the key interaction result.
4. Exercise both iOS and Android when platform behavior or release scope differs; otherwise start with the available primary host and name the coverage boundary.
5. Check runtime warnings, touch targets, text scaling, keyboard overlap, safe areas, and dark mode when supported.
6. Record flow files/commands, device/runtime identity, screenshot paths, and verdicts.
