# Web host

1. Serve a production build for formal UX-RC+ evidence. Dev-server captures are implementation feedback only.
2. Use the available browser automation host or Playwright. Visit every changed route; wait for settled content; disable animations.
3. Capture 375×667 and 1024×768 first; add breakpoints only for responsive scope or observed defects.
4. Capture default plus applicable loading, empty, error, hover/focus, and one end-to-end interaction.
5. Run accessibility and console checks. For public pages, run SEO; run performance only when contracted.
6. For Playwright, prefer `toHaveScreenshot`; mask only genuinely nondeterministic content and document masks/tolerances.
7. Record the production-build command, URL, viewport, screenshot paths, audit output, and visual verdicts.
