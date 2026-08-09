# visual-testing — procedure

Prereq: UI story/epic validate; `ui-spec.md` exists → visual testing REQUIRED.
Output: screenshots + audit results → `validation-report.md` **Visual/UX Validation** section.

Read exactly one host reference under `references/` (see §2).

## 1. Tight loop (default)

Scope before expanding:

| Dimension | Start | Expand when |
|-----------|-------|-------------|
| Screens | 1–3 most impacted | More issues or story scope |
| Breakpoints | mobile + desktop | Responsive in scope |
| States | default + loading + empty + error + one interaction | Epic cross-story check |

Skip entirely: `cli` / `api` archetype; API-only, CLI, migrations, config stories without UI.

## 2. Platform detection

1. `project.md` frontmatter `_active_recipe`
2. Recipe `visual_testing.platform`
3. Fallback: `architecture.md` stack

| Platform | Read | Tools |
|----------|------|-------|
| `web` | `references/web.md` | Browser MCP, Playwright |
| `mobile-flutter` | `references/mobile-flutter.md` | Golden tests, Alchemist |
| `mobile-rn` | `references/mobile-react-native.md` | Maestro, Detox |
| `desktop-electron` | `references/desktop-electron.md` | Playwright Electron |
| `desktop-tauri` | `references/desktop-tauri.md` | WebdriverIO |
| `extension` | `references/extension.md` | Puppeteer/Playwright |
| `cli` / `api` | None | Skip |

Execute host-specific steps from chosen reference only.

## 3. Load specs

Read before capture:

| File | Use |
|------|-----|
| `design-system.md` | Tokens, breakpoints, components |
| `ui-spec.md` | States, Testing Checklist |
| `wireframes.md` | Layouts (if exists) |
| `ux-strategy.md` | Voice/tone, a11y |

## 4. Capability check

Verify runtime + tools (browser MCP, emulator, app window). Unavailable → generate manual validation checklist instead of blocking silently.

## 5. Capture

Navigate; screenshot at scoped breakpoints/states. Store:

```
{STORY_DIR}/screenshots/{screen}-{breakpoint|state}.png
```

## 6. Audits

| Platform | Run |
|----------|-----|
| Web | `runAccessibilityAudit()`, console errors |
| Mobile | Runtime warnings |
| All | Grep hardcoded colors/sizes |

Token violations:

```bash
grep -r '#[0-9A-Fa-f]\{6\}' src/
grep -r '[0-9]\+px' src/components/
```

| Property | Token | Hardcoded |
|----------|-------|-----------|
| Color | `var(--primary-500)` | `#0EA5E9` |
| Spacing | `space-4` | `16px` |
| Typography | `text-lg` | `font-size: 18px` |
| Radius | `rounded-lg` | `border-radius: 8px` |

## 7. Validate against specs

- Layout vs wireframes/ui-spec
- `ui-spec.md` Testing Checklist pass
- Copy vs `ux-strategy.md`
- A11y: contrast 4.5:1 text / 3:1 UI; 44×44 touch; focus visible; ARIA on interactives

Critical a11y failure → block validation.

## 8. Report section

Add to `validation-report.md`:

- Screenshot gallery + annotations
- Token compliance %
- A11y audit results
- Issues with severity

## 9. Feedback loop

| Finding | Action | Tag |
|---------|--------|-----|
| Token violation | Fix + report | `GOTCHA` |
| Voice mismatch | Note for ux-strategy | — |
| A11y failure | Block; add tasks | `GOTCHA` |
| New UI pattern | Flag design-system | `PATTERN` |

Feed into `story-retro.md`.

## NEVER / ALWAYS

- NEVER skip when `ui-spec.md` exists
- NEVER expand scope before tight loop runs
- NEVER block on missing tools without manual checklist fallback
- ALWAYS read one host reference for platform steps
- ALWAYS store screenshots under story dir
