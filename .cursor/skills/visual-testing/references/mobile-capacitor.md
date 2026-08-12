# Capacitor-wrapped web

Build the production web bundle, sync it into the native shells, and exercise at least one iOS or Android runtime. Browser screenshots alone do not prove native safe areas, keyboard behavior, permissions, deep links, back navigation, or bridge failures.

- iOS: run the synced app in Simulator; capture the changed flow, rotation if supported, keyboard-open state, and safe-area edges.
- Android: run the synced app in Emulator; capture system-back behavior, keyboard-open state, and permission prompts.
- Inspect native and web console logs. A missing plugin, bridge exception, or stale synced bundle is a runtime finding.
- When both platforms ship and the change touches native behavior, exercise both. For web-only layout changes, one native host plus responsive browser coverage may be representative if the rationale is recorded.
