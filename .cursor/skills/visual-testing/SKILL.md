---
name: visual-testing
description: Produces host-specific visual and accessibility evidence. Use during UI LARP after the target build becomes reachable.
---

# visual-testing

This is an evidence producer inside UI LARP. It does not declare readiness.

1. Detect `visual_testing.platform` from the active recipe, then project architecture. For `api` or `cli`, STOP: the surface is nonvisual.
2. Read exactly one host reference:
   - `web` → `references/web.md`
   - `mobile-flutter` → `references/mobile-flutter.md`
   - `mobile-rn` → `references/mobile-react-native.md`
   - `mobile-capacitor` → `references/mobile-capacitor.md`
   - `desktop-electron` → `references/desktop-electron.md`
   - `desktop-tauri` → `references/desktop-tauri.md`
   - `extension` → `references/extension.md`
3. Read the design system, UI spec, and any applicable wireframes or UX strategy. Do not preload other hosts.
4. Verify the real runtime and capture capability. If blocked, log the attempted command and blocker; a manual checklist is not visual evidence.
5. Capture changed screens across representative viewport/device, interaction, and applicable loading, empty, error, and success states. Expand when findings or scope require it.
6. Run the host audit plus changed-file token checks. Record screenshot paths, runtime/build SHA, commands, and findings in the LARP evidence manifest. Accessibility or runtime errors remain blocking findings for later validation.
