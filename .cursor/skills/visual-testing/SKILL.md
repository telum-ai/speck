---
name: visual-testing
description: UI visual testing coordinator. Use at story/epic validate with UI.
---

# visual-testing

1. Detect platform from story/epic `visual_testing.platform` or recipe / architecture. If `api` or `cli`: STOP — skip visual testing.
2. MUST Read `references/procedure.md` (coordinator workflow only).
3. MUST Read **exactly one** host file:
   - `web` → `references/web.md`
   - `mobile-flutter` → `references/mobile-flutter.md`
   - `mobile-rn` → `references/mobile-react-native.md`
   - `desktop-electron` → `references/desktop-electron.md`
   - `desktop-tauri` → `references/desktop-tauri.md`
   - `extension` → `references/extension.md`
4. Do NOT preload other host files.
5. STOP if procedure/host says STOP.
