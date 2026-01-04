# Visual Testing Pattern

**Purpose**: Guide the Speck agent to autonomously capture, compare, and validate visual implementation against UI/UX specifications across all platform types.

**Last Updated**: January 2026

---

## 🎯 Core Principle

The Speck agent has powerful autonomous visual testing capabilities that should be leveraged during validation. Visual testing ensures that:
1. Implementation matches design specifications (ui-spec.md, wireframes.md)
2. Design system tokens are used correctly (no hardcoded values)
3. Responsive behavior works across breakpoints
4. Accessibility requirements are met (color contrast, touch targets)
5. Voice/tone in UI copy matches ux-strategy.md

**Visual testing is NOT optional for UI-heavy stories** - it catches bugs that functional tests miss.

---

## 🔍 Platform Detection

The agent determines the testing platform from:

1. **`_active_recipe`** in project.md frontmatter (preferred)
2. **Recipe's `visual_testing.platform`** field
3. **Stack detection** from architecture.md (fallback)

### Platform Categories

| Platform | Recipes | Pattern File |
|----------|---------|--------------|
| `web` | nextjs-supabase, sveltekit-supabase, t3-stack, django-htmx, go-templ-htmx, react-fastapi-postgres, static-site | [web-visual-testing.md](visual-testing/web-visual-testing.md) |
| `mobile-flutter` | flutter-firebase | [mobile-flutter-visual-testing.md](visual-testing/mobile-flutter-visual-testing.md) |
| `mobile-rn` | expo-fastapi | [mobile-react-native-visual-testing.md](visual-testing/mobile-react-native-visual-testing.md) |
| `desktop-electron` | electron-react | [desktop-electron-visual-testing.md](visual-testing/desktop-electron-visual-testing.md) |
| `desktop-tauri` | tauri-react | [desktop-tauri-visual-testing.md](visual-testing/desktop-tauri-visual-testing.md) |
| `extension` | chrome-extension | [extension-visual-testing.md](visual-testing/extension-visual-testing.md) |
| `cli` | cli-tool, api-service | No visual testing (terminal output only) |

---

## 🤖 Agent Capabilities by Platform

### Web Platform
- **Browser MCP tools**: Screenshots, snapshots, navigation, interaction
- **Audits**: Accessibility, performance, SEO, best practices
- **Responsive testing**: Viewport resizing at breakpoints

### Mobile Platforms
- **Android Emulator**: ADB commands for screenshots, screen recording, display override
- **iOS Simulator**: xcrun simctl for screenshots, video recording, status bar control
- **Maestro**: YAML-based E2E testing (agent-friendly!)
- **Fastlane**: Automated app store screenshot generation

### Desktop Platforms
- **Electron**: Playwright Electron API for full automation
- **Tauri**: WebdriverIO with tauri-driver for WebDriver-based testing
- **Cross-platform screenshots**: Python mss library or native commands

### Browser Extensions
- **Puppeteer/Playwright**: Chrome DevTools Protocol for extension automation
- **Extension context detection**: Navigate to popup, background, content scripts

---

## 🔄 Visual Testing Workflow

```
┌─────────────────────────────────────────────────┐
│ 1. DETECT PLATFORM                              │
│    - Read _active_recipe from project.md        │
│    - Load recipe's visual_testing config        │
│    - Load platform-specific pattern             │
└──────────────────────┬──────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│ 2. CHECK CAPABILITIES                           │
│    Web: Browser MCP tools available?            │
│    Mobile: Emulator/simulator running?          │
│    Desktop: Can access application window?      │
│    If unavailable: Generate manual checklist    │
└──────────────────────┬──────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│ 3. LOAD SPECIFICATIONS                          │
│    - design-system.md (tokens, breakpoints)     │
│    - ui-spec.md (states, components, Testing    │
│      Checklist)                                 │
│    - wireframes.md (layouts)                    │
│    - ux-strategy.md (voice/tone, accessibility) │
└──────────────────────┬──────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│ 4. CAPTURE SCREENSHOTS                          │
│    - Navigate to each screen/component          │
│    - Capture at each breakpoint/device          │
│    - Trigger and capture each state             │
│    - Store in {STORY_DIR}/screenshots/          │
└──────────────────────┬──────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│ 5. RUN PLATFORM AUDITS                          │
│    Web: Accessibility, performance audits       │
│    Mobile: Check console errors                 │
│    All: Verify design token usage               │
└──────────────────────┬──────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│ 6. VALIDATE AGAINST SPECS                       │
│    - Compare screenshots to wireframes          │
│    - Verify ui-spec.md Testing Checklist        │
│    - Check voice/tone in UI copy                │
│    - Verify accessibility requirements          │
└──────────────────────┬──────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────┐
│ 7. GENERATE VISUAL VALIDATION REPORT            │
│    - Screenshot gallery with annotations        │
│    - Design token compliance %                  │
│    - Accessibility audit results                │
│    - Responsive behavior assessment             │
│    - Voice/tone compliance notes                │
└─────────────────────────────────────────────────┘
```

---

## 📱 Standard Device Matrix

### Mobile Devices

| Category | iOS | Android |
|----------|-----|---------|
| **Small Phone** | iPhone SE (375×667) | Pixel 4a (360×760) |
| **Standard Phone** | iPhone 15 (393×852) | Pixel 8 (411×915) |
| **Large Phone** | iPhone 15 Pro Max (430×932) | Pixel 8 Pro (448×998) |
| **Tablet** | iPad (768×1024) | Pixel Tablet (800×1280) |

### Web Breakpoints

| Token | Width | Target |
|-------|-------|--------|
| `mobile` | 375px | Small phones |
| `tablet` | 768px | Tablets, small laptops |
| `desktop` | 1024px | Standard desktop |
| `wide` | 1280px | Large monitors |
| `ultrawide` | 1536px | Ultra-wide displays |

### Desktop Platforms

| Platform | Primary Resolution | Secondary |
|----------|-------------------|-----------|
| macOS | 1920×1080 | 2560×1440 (Retina) |
| Windows | 1920×1080 | 1366×768 (laptops) |
| Linux | 1920×1080 | CI baseline generation |

---

## 🎨 Design Token Validation

During visual validation, check that implementation uses design system tokens:

### What to Check

| Property | Good (Token) | Bad (Hardcoded) |
|----------|--------------|-----------------|
| Color | `var(--primary-500)` | `#0EA5E9` |
| Typography | `text-lg` or `var(--text-lg)` | `font-size: 18px` |
| Spacing | `space-4` or `var(--space-4)` | `margin: 16px` |
| Border Radius | `rounded-lg` | `border-radius: 8px` |
| Shadows | `shadow-md` | `box-shadow: 0 4px 6px...` |

### How to Detect

1. **Grep for hardcoded values** in changed files:
   ```bash
   grep -r "#[0-9A-Fa-f]\{6\}" src/  # Hex colors
   grep -r "px" src/components/      # Pixel values
   ```

2. **Check CSS/style files** for raw values vs tokens

3. **Compare computed styles** against design-system.md tokens

---

## 🔊 Voice/Tone Validation

Check UI copy against ux-strategy.md voice attributes:

### What to Validate

| Element | Check Against |
|---------|---------------|
| Error messages | ux-strategy.md → Tone → Error situations |
| Success messages | ux-strategy.md → Tone → Success moments |
| Button labels | ux-strategy.md → Voice attributes |
| Empty states | ux-strategy.md → Content guidelines |
| Loading text | ux-strategy.md → Voice attributes |

### Common Issues

| Voice Attribute | ❌ Bad | ✅ Good |
|-----------------|--------|---------|
| "Friendly" | "Error: Invalid input" | "Oops! That doesn't look right" |
| "Professional" | "lol ur data saved" | "Your changes have been saved" |
| "Encouraging" | "Form submitted" | "Great job! You're all set" |
| "Concise" | "Please click the button below to continue" | "Continue" |

---

## ♿ Accessibility Validation

### Automated Checks

| Check | Tool/Method | Target |
|-------|-------------|--------|
| Color contrast | `runAccessibilityAudit` | WCAG 2.1 AA (4.5:1 text, 3:1 UI) |
| Touch targets | Manual/computed styles | 44×44px minimum |
| Focus indicators | Visual inspection | 2px+ visible outline |
| ARIA labels | DOM inspection | All interactive elements |
| Heading hierarchy | DOM inspection | h1 → h2 → h3 sequence |

### Manual Checks

- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Screen reader announces correctly
- [ ] Focus visible on all interactive elements
- [ ] No information conveyed by color alone

---

## 🖼️ Screenshot Storage Convention

Store screenshots in a consistent location for validation:

```
{STORY_DIR}/
├── screenshots/
│   ├── {screen}-{breakpoint}.png
│   ├── {screen}-{state}.png
│   └── {screen}-{device}.png
```

### Naming Convention

| Pattern | Example | Use Case |
|---------|---------|----------|
| `{screen}-{breakpoint}` | `dashboard-mobile.png` | Responsive testing |
| `{screen}-{state}` | `button-hover.png` | State testing |
| `{screen}-{device}` | `login-iphone15.png` | Device-specific |
| `{screen}-dark` | `settings-dark.png` | Dark mode |

---

## 🔧 Dynamic Content Handling

Dynamic content causes false positives. Use these strategies:

### Masking

```javascript
// Playwright - mask dynamic elements
await expect(page).toHaveScreenshot({
  mask: [
    page.getByTestId('timestamp'),
    page.getByTestId('avatar'),
    page.getByTestId('ad-slot')
  ]
})
```

### CSS Injection

```javascript
// Hide dynamic content before screenshot
await page.addStyleTag({
  content: `
    .timestamp, .avatar, .dynamic-content {
      visibility: hidden !important;
    }
    *, *::before, *::after {
      animation-duration: 0s !important;
      transition-duration: 0s !important;
    }
  `
})
```

### Tolerance Thresholds

```javascript
// Allow minor pixel differences
await expect(page).toHaveScreenshot({
  maxDiffPixels: 100,           // Allow up to 100 different pixels
  maxDiffPixelRatio: 0.01,      // Or 1% of total pixels
  threshold: 0.2                // Per-pixel color threshold
})
```

---

## 📊 Visual Validation Report Section

Add this section to validation-report.md:

```markdown
## Visual/UX Validation

### Platform: [web | mobile-flutter | mobile-rn | desktop-electron | desktop-tauri | extension]

### Screenshots Captured

| Screen | Breakpoint/Device | Screenshot | Status |
|--------|-------------------|------------|--------|
| [Name] | [Size/Device] | [Link to file] | ✅/⚠️/❌ |

### Design Token Compliance

| Property | Specified | Implemented | Status |
|----------|-----------|-------------|--------|
| Primary color | `primary-500` | ✅ Token used | ✅ PASS |
| Button padding | `space-4` | ❌ Hardcoded `16px` | ❌ FAIL |

**Token Compliance**: [X/Y] properties use tokens ([Z]%)

### Responsive Behavior

| Breakpoint | Expected | Actual | Status |
|------------|----------|--------|--------|
| Mobile (375px) | Stack layout | ✅ Stacks | ✅ PASS |
| Tablet (768px) | 2-column | ✅ 2-column | ✅ PASS |
| Desktop (1024px) | 3-column | ❌ 2-column | ❌ FAIL |

### Accessibility Audit

| Requirement | Target | Status | Notes |
|-------------|--------|--------|-------|
| Color contrast | 4.5:1 (AA) | ✅ 5.2:1 | |
| Touch targets | 44×44px | ✅ 48×48px | |
| Keyboard nav | Full | ⚠️ Partial | Modal trap missing |
| ARIA labels | Required | ✅ Present | |

### Voice/Tone Compliance

| Element | Expected | Actual | Status |
|---------|----------|--------|--------|
| Error messages | Helpful | "Error 500" | ❌ FAIL - Too technical |
| Success state | Encouraging | "Saved!" | ✅ PASS |
| Button labels | Action-oriented | "Submit" → "Save Changes" | ⚠️ WARN |

### ui-spec.md Testing Checklist

[Copy and check off items from ui-spec.md Testing Checklist section]

- [x] All states render correctly
- [ ] Responsive at all breakpoints
- [x] Animations perform smoothly
- [ ] Design tokens applied correctly
```

---

## 🔗 Integration Points

### With /story-validate

Visual validation runs as step 10.5 in story-validate, after code quality gates but before code audit:

1. Detect platform from recipe
2. Load platform-specific pattern
3. Execute visual testing workflow
4. Generate visual validation section in report

### With /epic-validate

Epic visual validation aggregates story visual results:

1. Collect screenshots from all story validations
2. Check cross-story visual consistency
3. Validate against epic wireframes.md
4. Check user journey touchpoints are visually complete

### With /story-ui-spec

The Testing Checklist in ui-spec.md becomes the validation checklist:

1. Copy Testing Checklist items to validation report
2. Agent checks off items during validation
3. Unchecked items become validation failures

---

## 📚 Platform-Specific Patterns

For detailed implementation guidance, see:

- [Web Visual Testing](visual-testing/web-visual-testing.md) - Browser MCP tools, Playwright, Percy
- [Flutter Visual Testing](visual-testing/mobile-flutter-visual-testing.md) - Golden tests, Alchemist
- [React Native Visual Testing](visual-testing/mobile-react-native-visual-testing.md) - Maestro, Detox, ADB/simctl
- [Electron Visual Testing](visual-testing/desktop-electron-visual-testing.md) - Playwright Electron
- [Tauri Visual Testing](visual-testing/desktop-tauri-visual-testing.md) - WebdriverIO
- [Extension Visual Testing](visual-testing/extension-visual-testing.md) - Puppeteer, CDP

---

## 🚦 When Visual Testing is Required

| Story Type | Visual Testing | Reason |
|------------|----------------|--------|
| UI components | **REQUIRED** | Core purpose |
| Forms/inputs | **REQUIRED** | States, validation |
| Pages/screens | **REQUIRED** | Layout, responsive |
| API-only | SKIP | No visual output |
| CLI commands | SKIP | No visual output |
| Data migrations | SKIP | No visual output |
| Config changes | SKIP | No visual output |

**Rule**: If ui-spec.md exists for a story, visual testing is REQUIRED.

---

*Generated by Speck methodology*
*Pattern Version: 1.0.0*
