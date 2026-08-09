# desktop-electron — host steps

Platform: `desktop-electron`. Recipes: `electron-react`. Tools: Playwright Electron, Storybook, Percy.

Read after `references/procedure.md` §2 selects this host.

## Tight loop

| Dimension | Start | Expand |
|-----------|-------|--------|
| Windows | Main + 1–2 changed routes | Multi-window in scope |
| Size | 1280×800 normal | Small/maximized if layout in scope |
| Theme | Light | Dark if theming in scope |

Order: launch → main screenshot → changed routes → diff intended vs bug → fix or update baseline.

## Launch and capture

```typescript
import { _electron as electron } from 'playwright';

const electronApp = await electron.launch({ args: ['path/to/app'] });
const window = await electronApp.firstWindow();
await window.waitForLoadState('domcontentloaded');

await window.setViewportSize({ width: 1280, height: 800 });
await window.screenshot({ path: 'screenshots/main-window.png' });

// Element
await window.locator('[data-testid="header"]').screenshot({ path: 'screenshots/header.png' });

// CI assertion
await expect(window).toHaveScreenshot('main-window.png');
```

## Theme

```typescript
await electronApp.evaluate(async ({ nativeTheme }) => {
  nativeTheme.themeSource = 'dark'; // or 'light'
});
await window.screenshot({ path: 'screenshots/dark-mode.png' });
```

## Multi-window (if in scope)

```typescript
const [secondWindow] = await Promise.all([
  electronApp.waitForEvent('window'),
  window.click('[data-testid="open-settings"]')
]);
await secondWindow.screenshot({ path: 'screenshots/settings-window.png' });
```

Platform baselines when OS chrome differs: `main-window-${process.platform}.png`.

## Commands

```bash
npx playwright test --project=electron
npx playwright test --project=electron --update-snapshots
npx playwright test tests/visual/main-window.spec.ts
```

Storybook (if used): `npm run storybook`; Chromatic optional for component isolation.

## Checklist

- [ ] Main window normal size
- [ ] Changed routes captured
- [ ] Light (+ dark if theming touched)
- [ ] Resize behavior if in scope
- [ ] Secondary windows/dialogs if applicable
- [ ] No main-process console errors
- [ ] No renderer console errors

Store under `{STORY_DIR}/screenshots/` per parent procedure.
