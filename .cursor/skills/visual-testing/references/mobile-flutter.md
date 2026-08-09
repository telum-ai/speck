# Flutter host

1. Run or add golden tests for the 1–3 changed widgets/screens; use a phone constraint first.
2. Cover light/dark when supported and default plus relevant loading/empty/error/disabled states.
3. Run `flutter test test/goldens/`. Update goldens only after adjudicating the change as intended.
4. For journey or native-shell behavior, boot a simulator/emulator and capture the shipped app, not Widgetbook alone.
5. Add tablet/device variants only when layout scope or a finding demands it.
6. Record golden commands/results, device/runtime identity, screenshot paths, and verdicts.
