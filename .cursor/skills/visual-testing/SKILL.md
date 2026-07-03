---
name: visual-testing
description: Load when running /story-validate or /epic-validate for stories with UI components, when ui-spec.md exists, or when validating design token usage and accessibility.
---

# Visual Testing

When validating UI stories, capture screenshots, run audits, and compare against design specifications.

---

## 🎯 Core Principle

Visual testing ensures that:
1. Implementation matches design specifications (`ui-spec.md`, `wireframes.md`)
2. Design system tokens are used correctly (no hardcoded values)
3. Responsive behavior works across breakpoints
4. Accessibility requirements are met (color contrast, touch targets)
5. Voice/tone in UI copy matches `ux-strategy.md`

**Visual testing is NOT optional for UI-heavy stories** - it catches bugs that functional tests miss.

---

## 🔄 Tight Loop (Default)

**Goal**: Get high-signal visual feedback fast (minutes, not hours) with minimal flake.

**Start Small**:
- **Screens**: Focus on 1–3 screens/components most impacted by the story
- **Breakpoints**: Start with `mobile` + `desktop` (expand only if responsive behavior is in scope)
- **States**: Cover default + loading + empty + error (as applicable) + one interaction state

**Expand Only When**:
- Initial findings reveal more issues
- Story explicitly covers responsive edge cases
- Epic validation requires cross-story consistency check

---

## 🔍 Platform Detection

Determine the testing platform from:

1. Read `_active_recipe` from `project.md` frontmatter
2. Load the recipe's `visual_testing.platform` field
3. Fallback: detect stack from `architecture.md`

Based on platform, **Read** the appropriate host rule (these are lazy sub-rules of this skill — `disable-model-invocation: true` — so they don't occupy the always-on skill surface; this coordinator loads exactly the one your platform needs):

| Platform | Host rule to Read | Tools |
|----------|-------------------|-------|
| `web` | `.cursor/skills/visual-testing-web/SKILL.md` | Browser MCP, Playwright |
| `mobile-flutter` | `.cursor/skills/visual-testing-mobile-flutter/SKILL.md` | Golden tests, Alchemist |
| `mobile-rn` | `.cursor/skills/visual-testing-mobile-react-native/SKILL.md` | Maestro, Detox |
| `desktop-electron` | `.cursor/skills/visual-testing-desktop-electron/SKILL.md` | Playwright Electron |
| `desktop-tauri` | `.cursor/skills/visual-testing-desktop-tauri/SKILL.md` | WebdriverIO |
| `extension` | `.cursor/skills/visual-testing-extension/SKILL.md` | Puppeteer/Playwright |
| `cli` / `api` | None | Skip visual testing |

---

## 📋 Validation Workflow

### 1. Load Design Specifications

Read these files to understand what to validate:
- `design-system.md` → tokens, breakpoints, components
- `ui-spec.md` → component specs, states, Testing Checklist
- `wireframes.md` → layouts (if exists)
- `ux-strategy.md` → voice/tone, accessibility requirements

### 2. Check Capabilities

Before attempting visual testing, verify:
- **Web**: Are Browser MCP tools available?
- **Mobile**: Is emulator/simulator running?
- **Desktop**: Can you access the application window?

If tools unavailable, generate a manual validation checklist instead.

### 3. Capture Screenshots (Tight Loop Scope)

For 1–3 key screens/components in the story:
- Navigate to the page/component
- Capture at `mobile` + `desktop` breakpoints
- Trigger and capture key states (default, hover, error, empty)
- Store in `{STORY_DIR}/screenshots/`

### 4. Run Platform Audits

- **Web**: Run `runAccessibilityAudit()`, `getConsoleErrors()`
- **Mobile**: Check for runtime warnings
- **All**: Grep source for hardcoded hex colors and pixel values

### 5. Validate Against Specs

Compare findings to specifications:
- Screenshots match wireframes/layouts?
- `ui-spec.md` Testing Checklist items pass?
- Voice/tone matches `ux-strategy.md`?
- Accessibility requirements met?

### 6. Generate Report Section

Add a "Visual/UX Validation" section to `validation-report.md`:
- Screenshot gallery with annotations
- Design token compliance percentage
- Accessibility audit results
- Issues found (with severity)

---

## 🎨 Design Token Validation

Check that implementation uses tokens, not hardcoded values:

| Property | ✅ Token | ❌ Hardcoded |
|----------|----------|--------------|
| Color | `var(--primary-500)` | `#0EA5E9` |
| Spacing | `space-4` | `16px` |
| Typography | `text-lg` | `font-size: 18px` |
| Border Radius | `rounded-lg` | `border-radius: 8px` |

**Detection**:
```bash
# Find hardcoded hex colors
grep -r "#[0-9A-Fa-f]\{6\}" src/

# Find pixel values
grep -r "[0-9]\+px" src/components/
```

Flag violations in the validation report.

---

## ♿ Accessibility Requirements

Run accessibility audit and verify:

| Check | Target | Tool |
|-------|--------|------|
| Color contrast | 4.5:1 text, 3:1 UI (WCAG AA) | `runAccessibilityAudit` |
| Touch targets | 44×44px minimum | Manual/computed styles |
| Focus indicators | 2px+ visible outline | Visual inspection |
| ARIA labels | All interactive elements | DOM inspection |

**Block validation on critical accessibility failures.**

---

## 🖼️ Screenshot Storage

Store screenshots consistently:

```
{STORY_DIR}/
├── screenshots/
│   ├── {screen}-mobile.png
│   ├── {screen}-desktop.png
│   ├── {screen}-hover.png
│   └── {screen}-error.png
```

---

## 🔄 Feedback Loop

Visual testing findings must flow back into the methodology:

| Finding | Immediate Action | Commit Tag |
|---------|------------------|------------|
| Design token violation | Flag in report, fix code | `GOTCHA` |
| Voice/tone mismatch | Note for ux-strategy.md update | - |
| Accessibility failure | Block validation, add to tasks.md | `GOTCHA` |
| New UI pattern discovered | Flag for design-system.md addition | `PATTERN` |

After validation, findings feed into `story-retro.md`.

---

## ⏭️ When to Skip Visual Testing

Skip for:
- API-only stories (no UI)
- CLI commands
- Data migrations
- Configuration changes

**Rule**: If `ui-spec.md` exists, visual testing is REQUIRED.

---

## 📚 Platform-Specific Rules (lazy sub-rules of this skill)

The 6 host rules below are consolidated under this one coordinator skill (v8): they carry `disable-model-invocation: true`, so they are **Read on demand** by this skill for the detected platform rather than auto-loaded. For detailed implementation, Read the matching file:

- `.cursor/skills/visual-testing-web/SKILL.md` — Browser MCP tools, Playwright, Percy
- `.cursor/skills/visual-testing-mobile-flutter/SKILL.md` — Golden tests, Alchemist
- `.cursor/skills/visual-testing-mobile-react-native/SKILL.md` — Maestro, Detox
- `.cursor/skills/visual-testing-desktop-electron/SKILL.md` — Playwright Electron
- `.cursor/skills/visual-testing-desktop-tauri/SKILL.md` — WebdriverIO
- `.cursor/skills/visual-testing-extension/SKILL.md` — Puppeteer, CDP
