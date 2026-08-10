---
name: visual-testing
description: Coordinates visual and accessibility evidence. Use during story or epic validation when UI or ui-spec.md exists.
paths:
  - "**/*.{tsx,jsx,vue,svelte,css,scss}"
  - "specs/projects/**/**/ui-spec.md"
  - "specs/projects/**/**/wireframes.md"
  - "specs/projects/**/design-system.md"
---

# visual-testing

Prereq: UI story/epic validate; `ui-spec.md` exists. Output: screenshots + adjudication in `validation-report.md`.

1. Detect platform from story/epic `visual_testing.platform`, active recipe, then architecture. If `api` or `cli`: STOP — skip.
2. MUST Read **exactly one** host file:
   - `web` → `references/web.md`
   - `mobile-flutter` → `references/mobile-flutter.md`
   - `mobile-rn` → `references/mobile-react-native.md`
   - `desktop-electron` → `references/desktop-electron.md`
   - `desktop-tauri` → `references/desktop-tauri.md`
   - `extension` → `references/extension.md`
3. Do NOT preload other host files.
4. Read `design-system.md`, `ui-spec.md`, optional `wireframes.md`, and `ux-strategy.md`.
5. Verify runtime + capture capability. If unavailable, log the attempted command/tool and blocker; generate a manual checklist. Do not claim visual evidence.
6. Start with 1–3 changed screens, mobile + desktop (or one representative device/window), default + applicable loading/empty/error + one interaction. Expand when findings or scope require it.
7. Stabilize animation/network/dynamic content. Capture into `{STORY_DIR}/screenshots/{screen}-{viewport-or-state}.png`.
8. Run host audits plus changed-file token checks. Critical accessibility or console/runtime errors block validation.
9. Adjudicate each screenshot against layout, state, copy, accessibility, and design-token promises. A screenshot without a verdict is not proof.
10. Record screenshot paths, runtime/build SHA, commands, findings, and verdicts in `validation-report.md`; route defects back to implementation.
