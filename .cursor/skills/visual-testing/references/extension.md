# Browser extension host

1. Build the unpacked extension and launch a headed persistent Chromium context with that exact build.
2. Resolve the runtime extension id; visit the changed popup/options/content-script surfaces directly.
3. Capture popup default plus the key state; capture options and injected-page UI only when changed.
4. Exercise permission prompts, logged-out/error states, service-worker reloads, and content-script isolation when in scope.
5. Check popup dimensions, console/service-worker errors, focus order, permissions, and host-page collisions.
6. Record browser/build identity, launch command, screenshot paths, and verdicts.
