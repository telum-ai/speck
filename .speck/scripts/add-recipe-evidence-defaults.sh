#!/usr/bin/env bash
# Append evidence_contract: defaults to each recipe.yaml based on platform.
# Idempotent: skips recipes that already have an evidence_contract block.
#
# Usage: ./add-recipe-evidence-defaults.sh

set -euo pipefail

RECIPES_DIR="${RECIPES_DIR:-$(pwd)/.speck/recipes}"
if [[ ! -d "$RECIPES_DIR" ]]; then
  echo "Error: $RECIPES_DIR not found"
  exit 1
fi

# Block builders by platform category

read -r -d '' WEB_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — what counts as proof for this platform.
# Override per-project in evidence-contract.md.
evidence_contract:
  platform: web
  valid_proof_sources:
    - "Production build (npm run build && start) screenshot via Playwright/Browser MCP"
    - "Production build accessibility tree via axe-playwright"
    - "Lighthouse run against production build"
    - "Live deployed URL screenshot + HAR"
    - "Network trace (HAR) showing real API responses"
  invalid_proof_sources:
    - "next dev / vite dev server screenshot (dev-mode evidence ≠ ship evidence)"
    - "Storybook screenshot (component evidence ≠ integrated evidence)"
    - "Screenshot from localhost without HAR"
    - "Curl of API without browser render"
    - "Screenshot of editor preview"
  required_larp_scope:
    impl_green: "Unit + integration tests pass"
    ux_rc: "Production build LARP: primary user flow recorded end-to-end with screenshots + AX tree at each step"
    commercial_rc: "Stripe checkout / paywall flow exercised against test mode, webhook delivery verified"
    ship_rc: "Live preview URL LARP recorded with HAR; auth flow on real provider"
    ship: "Production URL smoke screenshots checked in post-deploy"
  required_static_evidence:
    - "tests passing in CI"
    - "Lighthouse score >=85 for performance, accessibility"
    - "axe-core 0 critical, 0 serious"
    - "Sentry test event roundtrip"
  required_live_service_evidence:
    - "Production deploy URL responding 200"
    - "Auth callback flow against real OAuth provider"
    - "Email sending verified (test inbox)"
    - "Stripe webhook delivery verified (if billing in scope)"
EOF

read -r -d '' MOBILE_RN_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — React Native / Expo
evidence_contract:
  platform: mobile-react-native
  valid_proof_sources:
    - "Native iOS Simulator screenshot via xcrun simctl io booted screenshot"
    - "Native Android emulator screenshot via adb shell screencap"
    - "Maestro recorded flow on real device or simulator"
    - "Detox test run on simulator with screenshot capture"
    - "TestFlight build install + manual LARP"
  invalid_proof_sources:
    - "Expo Go screenshot (sandbox runtime ≠ ship runtime)"
    - "Browser-based Expo web preview (different runtime)"
    - "Metro bundler error screen"
    - "React Native dev menu open in screenshot"
    - "Screenshot from Snack/web preview"
  required_larp_scope:
    impl_green: "Jest unit + Detox integration tests pass"
    ux_rc: "Maestro flow recorded on simulator covering primary persona path; native screenshots at each step"
    commercial_rc: "IAP test purchase via RevenueCat sandbox, receipt validation verified"
    ship_rc: "TestFlight (iOS) and Internal Testing (Android) builds installed + manual LARP recorded"
    ship: "App Store / Play Store live, post-release crash rate <1%"
  required_static_evidence:
    - "Bundle builds with no warnings"
    - "Native build (Xcode/Gradle) succeeds for release config"
    - "TestFlight / Internal Testing upload succeeds"
  required_live_service_evidence:
    - "Firebase/Supabase backend reachable from device build"
    - "Push notifications delivered via FCM/APNs"
    - "Deep links open in installed build"
EOF

read -r -d '' MOBILE_FLUTTER_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — Flutter
evidence_contract:
  platform: mobile-flutter
  valid_proof_sources:
    - "Native iOS Simulator screenshot via xcrun simctl io booted screenshot"
    - "Native Android emulator screenshot via adb shell screencap"
    - "Golden test output (widget rendering) with current SHA"
    - "integration_test E2E with screenshots"
    - "TestFlight / Internal Testing build manual LARP"
  invalid_proof_sources:
    - "Flutter web preview screenshot (different renderer)"
    - "DartPad screenshot (sandbox)"
    - "Flutter Inspector screenshot (debug overlay)"
    - "Hot-reload mid-state screenshot"
  required_larp_scope:
    impl_green: "Unit + golden tests pass"
    ux_rc: "integration_test flow covering primary persona path with simulator screenshots"
    commercial_rc: "IAP test purchase via RevenueCat sandbox or Apple/Google sandbox"
    ship_rc: "TestFlight + Internal Testing builds installed; manual LARP recorded"
    ship: "App Store / Play Store live, post-release crash rate <1%"
  required_static_evidence:
    - "flutter analyze: 0 warnings"
    - "Release builds succeed for iOS + Android"
  required_live_service_evidence:
    - "Firebase backend reachable from device build"
    - "Push notifications delivered (FCM/APNs)"
EOF

read -r -d '' DESKTOP_ELECTRON_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — Electron
evidence_contract:
  platform: desktop-electron
  valid_proof_sources:
    - "Packaged app screenshot (.dmg/.exe installed and run)"
    - "Playwright Electron API screenshot of packaged app"
    - "Auto-updater test run with old version → new version"
    - "Code-signed + notarized build install (macOS) / signed install (Windows)"
  invalid_proof_sources:
    - "electron-forge start / npm run dev screenshot (dev mode)"
    - "DevTools open in screenshot"
    - "Unpacked app screenshot"
    - "Unsigned build screenshot (signing matters for entitlements)"
  required_larp_scope:
    impl_green: "Unit + integration tests pass; packaged build succeeds for target OS"
    ux_rc: "Packaged app LARP recorded; primary flow with screenshots"
    commercial_rc: "License key validation tested against live licensing backend"
    ship_rc: "Signed + notarized build installed on clean OS; LARP recorded"
    ship: "Auto-updater confirmed working; post-deploy crash reports clean"
  required_static_evidence:
    - "Code signing succeeds"
    - "Notarization succeeds (macOS)"
    - "Installer/uninstaller flow works"
EOF

read -r -d '' DESKTOP_TAURI_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — Tauri
evidence_contract:
  platform: desktop-tauri
  valid_proof_sources:
    - "Packaged Tauri build screenshot (.dmg/.msi/.deb installed)"
    - "WebdriverIO + tauri-driver run on packaged build"
    - "Code-signed build install on each target OS"
  invalid_proof_sources:
    - "tauri dev screenshot"
    - "DevTools open in screenshot"
    - "WebView preview without native shell"
  required_larp_scope:
    impl_green: "Unit + WebdriverIO tests pass"
    ux_rc: "Packaged build LARP recorded with screenshots"
    commercial_rc: "License/auth flow tested against real backend"
    ship_rc: "Signed build installed on clean OS; LARP recorded"
    ship: "Auto-updater confirmed; crash reports clean"
  required_static_evidence:
    - "Tauri build succeeds for all target platforms"
    - "Code signing succeeds"
EOF

read -r -d '' CLI_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — CLI tool
evidence_contract:
  platform: cli
  valid_proof_sources:
    - "Binary built and invoked via shell — recorded transcript (asciinema or plain log)"
    - "Exit code + stdout/stderr captured for each documented command"
    - "Integration test running compiled binary via subprocess"
    - "Installed via published package (npm/cargo/brew) and re-tested"
  invalid_proof_sources:
    - "node src/cli.ts or cargo run --bin without packaging"
    - "Output from inside test harness only"
    - "REPL screenshot (different invocation context)"
  required_larp_scope:
    impl_green: "Unit + integration tests pass; binary builds"
    ux_rc: "Documented primary use case recorded as asciinema with annotated steps"
    commercial_rc: "License key validation if paid; telemetry/analytics opt-in respected"
    ship_rc: "Binary installed via published package, re-LARP confirms identical behavior"
    ship: "Published; install count and bug reports tracked"
  required_static_evidence:
    - "Binary builds for all target platforms"
    - "--help output matches documented commands"
    - "Exit codes documented and tested"
EOF

read -r -d '' API_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — API service (backend-only)
evidence_contract:
  platform: api-service
  valid_proof_sources:
    - "HTTP request/response logs from deployed environment"
    - "Postman/Bruno collection run against deployed URL with assertions"
    - "Integration test hitting deployed API"
    - "Load test results (k6/Artillery) against deployed environment"
    - "OpenAPI spec verified against actual responses"
  invalid_proof_sources:
    - "Local server (npm run dev / uvicorn) request/response"
    - "Mocked test response (unit tests are signal, not proof)"
    - "Swagger UI screenshot without actual call"
  required_larp_scope:
    impl_green: "Unit + integration tests pass against local server"
    ux_rc: "Postman/Bruno collection passes against staging deployment"
    commercial_rc: "Rate limiting + auth tested against live IdP; billing webhooks exercised"
    ship_rc: "Production deployment smoke tests pass; load test meets target"
    ship: "Production responding, monitoring dashboards green for 24h"
  required_static_evidence:
    - "API tests passing in CI"
    - "OpenAPI spec valid and matches behavior"
    - "Error responses follow documented schema"
  required_live_service_evidence:
    - "Production health endpoint 200"
    - "Database migrations applied to production"
    - "Sentry / observability backend receiving events from prod"
EOF

read -r -d '' EXTENSION_BLOCK <<'EOF' || true

# v7 Evidence Contract defaults — Browser extension
evidence_contract:
  platform: browser-extension
  valid_proof_sources:
    - "Packaged extension (.zip) loaded as unpacked + tested"
    - "Puppeteer/Playwright test on extension popup + content script context"
    - "Screenshots of popup, options page, content script-modified DOM"
    - "Store-published build (Chrome Web Store / AMO) install + LARP"
  invalid_proof_sources:
    - "Vite/webpack dev server preview (extension isn't loaded as extension)"
    - "Component-level screenshot without browser context"
    - "Manifest preview without actual install"
  required_larp_scope:
    impl_green: "Unit + integration tests pass; manifest valid"
    ux_rc: "Unpacked extension LARP: popup + options + content script behavior recorded with screenshots"
    commercial_rc: "License/auth flow tested if paid; permissions justified in manifest"
    ship_rc: "Store-review build uploaded; pre-publish LARP confirms identical behavior"
    ship: "Published in store, install count tracked, no critical reviews"
  required_static_evidence:
    - "Manifest v3 valid"
    - "Store-required assets (icons, screenshots) present"
    - "Privacy policy URL valid"
EOF

# Recipe → platform-block lookup (bash 3.2 compatible, no associative arrays)
get_block_for_recipe() {
  case "$1" in
    nextjs-supabase|sveltekit-supabase|react-fastapi-postgres|django-htmx|go-templ-htmx|t3-stack|static-site)
      printf '%s\n' "$WEB_BLOCK" ;;
    expo-fastapi)
      printf '%s\n' "$MOBILE_RN_BLOCK" ;;
    flutter-firebase)
      printf '%s\n' "$MOBILE_FLUTTER_BLOCK" ;;
    electron-react)
      printf '%s\n' "$DESKTOP_ELECTRON_BLOCK" ;;
    tauri-react)
      printf '%s\n' "$DESKTOP_TAURI_BLOCK" ;;
    cli-tool)
      printf '%s\n' "$CLI_BLOCK" ;;
    api-service)
      printf '%s\n' "$API_BLOCK" ;;
    chrome-extension)
      printf '%s\n' "$EXTENSION_BLOCK" ;;
    *)
      return 1 ;;
  esac
}

RECIPE_NAMES="nextjs-supabase sveltekit-supabase react-fastapi-postgres django-htmx go-templ-htmx t3-stack static-site expo-fastapi flutter-firebase electron-react tauri-react cli-tool api-service chrome-extension"

UPDATED=0
SKIPPED=0
MISSING=0

for recipe_name in $RECIPE_NAMES; do
  recipe_file="$RECIPES_DIR/$recipe_name/recipe.yaml"
  if [[ ! -f "$recipe_file" ]]; then
    echo "⚠️  Recipe file missing: $recipe_file"
    MISSING=$((MISSING + 1))
    continue
  fi
  if grep -q "^evidence_contract:" "$recipe_file"; then
    echo "↩️  Skipping $recipe_name (already has evidence_contract)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  if BLOCK=$(get_block_for_recipe "$recipe_name"); then
    printf '%s\n' "$BLOCK" >> "$recipe_file"
    echo "✅ Updated $recipe_name"
    UPDATED=$((UPDATED + 1))
  fi
done

echo ""
echo "Summary: $UPDATED updated, $SKIPPED skipped, $MISSING missing"
