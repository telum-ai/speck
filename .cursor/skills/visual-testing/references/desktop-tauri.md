# Tauri host

1. Build the app with `cargo tauri build`; formal evidence must exercise the built desktop artifact.
2. Run the changed flow through WebdriverIO/tauri-driver or the available native window automation.
3. Capture the normal window first; add small/maximized sizes only when resize behavior is in scope.
4. Keep OS-specific baselines because WebKit, WebView2, and WebKitGTK render differently.
5. Check renderer console output, native errors, keyboard/focus behavior, menus/dialogs, and window state.
6. Record OS/build identity, commands, screenshot paths, and verdicts; name any untested OS boundary.
