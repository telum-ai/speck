#!/usr/bin/env bash
# validate-visual-assets.test.sh — characterization + regression tests for the Visual
# Assets Pipeline validator.
#
# WHY CHARACTERIZATION COMES FIRST (#91):
# The validator had no test at all before this file. Its row-trimming used
# `$(echo "$line" | xargs)`, which under `set -euo pipefail` aborts the whole run on any
# apostrophe (xargs does shell-style quote processing — a lone `'` is an unterminated
# quote). The fix is to swap that trim for `sp_trim`. But the match regex at line 46 does
# its OWN `[[:space:]]*` handling around each cell, so a trim-strategy change could shift
# what BASH_REMATCH sees in ways nothing today would catch. So: Tests 1-6 below pin the
# CURRENT, CORRECT parsing behaviour (asset discovery, format normalisation, missing-asset
# reporting, placeholder skipping, indentation tolerance) on the unmodified script — proof
# the fix changes nothing but the crash. Test 7 is the #91 regression itself.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-visual-assets.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The validator resolves declared asset paths against `pwd`, not against the ui-spec.md
# location — so every fixture below is written under $TMP and the validator is invoked
# with $TMP as the working directory.
mkdir -p "$TMP/public/assets"

# A minimal, well-formed, token-clean SVG (no hardcoded fill hex, no absolute paths).
cat > "$TMP/public/assets/logo.svg" <<'EOF'
<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="10" fill="currentColor"/></svg>
EOF

story_dir() {
  # Fresh story directory per test so ui-spec.md manifests don't collide.
  local d="$TMP/stories/$1"
  mkdir -p "$d"
  printf '%s' "$d"
}

echo "Test 1: Well-formed manifest — declared SVG asset exists and validates clean"
d="$(story_dir t1)"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-LOGO | public/assets/logo.svg | SVG | 120x32 | Primary brand mark | Company logo | Created |
EOF
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"
echo "$out" | grep -q "SVG is well-formed and clean" || { echo "ERROR: Test 1 — expected clean-SVG pass line"; echo "$out"; exit 1; }
echo "$out" | grep -q "VISUAL ASSETS PIPELINE PASSED" || { echo "ERROR: Test 1 — expected overall PASS banner"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 1"

echo "Test 2: Format normalisation — lowercase 'svg' in the table cell still enters the SVG branch"
d="$(story_dir t2)"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-LOGO | public/assets/logo.svg | svg | 120x32 | Primary brand mark | Company logo | Created |
EOF
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"
echo "$out" | grep -q "(SVG)" || { echo "ERROR: Test 2 — expected format normalised to upper-case SVG in the check line"; echo "$out"; exit 1; }
echo "$out" | grep -q "SVG is well-formed and clean" || { echo "ERROR: Test 2 — expected clean-SVG pass line despite lower-case declared format"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 2"

echo "Test 3: Format normalisation — an unrecognised format (e.g. PNG) is read, upper-cased, and skipped from binary linting rather than failing"
d="$(story_dir t3)"
echo "not a real image, just needs to be non-empty" > "$TMP/public/assets/raster.png"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-RASTER | public/assets/raster.png | png | 64x64 | Fallback raster | Raster alt | Created |
EOF
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"
echo "$out" | grep -q "Asset format 'PNG' is skipped from binary linting" || { echo "ERROR: Test 3 — expected PNG format normalised and skipped"; echo "$out"; exit 1; }
echo "$out" | grep -q "VISUAL ASSETS PIPELINE PASSED" || { echo "ERROR: Test 3 — a skipped format must not fail the pipeline"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 3"

echo "Test 4: Missing asset — reported as a failure; strict mode fails the process, non-strict does not"
d="$(story_dir t4)"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-GHOST | public/assets/does-not-exist.webp | WEBP | 32x32 | Never created | Ghost alt | Pending |
EOF
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" false 2>&1)"; rc=$?
echo "$out" | grep -q "File not found: public/assets/does-not-exist.webp" || { echo "ERROR: Test 4 — expected file-not-found line naming the declared (WEBP) asset"; echo "$out"; exit 1; }
[[ "$rc" == "0" ]] || { echo "ERROR: Test 4 — non-strict mode must exit 0 even with a failed asset"; echo "$out"; exit 1; }
set +e
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" true 2>&1)"; rc=$?
set -e
[[ "$rc" == "1" ]] || { echo "ERROR: Test 4 — strict mode must exit 1 on a failed asset"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 4"

echo "Test 5: Template placeholder rows are skipped, not reported as missing assets"
d="$(story_dir t5)"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-[ID] | public/assets/... | [SVG/WebP] | [WxH] | [Description] | [Aria label] | [Pending/Created] |
EOF
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"
echo "$out" | grep -q "Checking asset" && { echo "ERROR: Test 5 — placeholder row should never reach the asset-checking step"; echo "$out"; exit 1; }
echo "$out" | grep -q "VISUAL ASSETS PIPELINE PASSED" || { echo "ERROR: Test 5 — an all-placeholder manifest must pass"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 5"

echo "Test 6: Indented table row (leading whitespace before the pipe) still matches — pins that the outer trim must keep serving the ^\\| anchor"
d="$(story_dir t6)"
printf '### Declared Visual Assets Manifest\n\n| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |\n|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|\n   | ASSET-LOGO | public/assets/logo.svg | SVG | 120x32 | Primary brand mark | Company logo | Created |\n' > "$d/ui-spec.md"
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"
echo "$out" | grep -q "SVG is well-formed and clean" || { echo "ERROR: Test 6 — an indented row must still be recognised as a manifest row"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 6"

echo "Test 7 (#91 regression): an apostrophe anywhere in the row — including columns the regex never captures, like Visual Intent — must not abort the validator, and must not silently corrupt the asset path/format it goes on to match"
d="$(story_dir t7)"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-HERO | public/assets/logo.svg | SVG | 120x32 | Friendly, approachable — it's got warmth | User's avatar | Don't ship yet |
EOF
set +e
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"; rc=$?
set -e
[[ "$rc" == "0" ]] || { echo "ERROR: Test 7 — an apostrophe in an uncaptured column must not abort the validator (was #91), rc=$rc"; echo "$out"; exit 1; }
echo "$out" | grep -q "unterminated quote" && { echo "ERROR: Test 7 — xargs quote-processing error leaked through"; echo "$out"; exit 1; }
echo "$out" | grep -q "Checking asset .*ASSET-HERO.* at path: public/assets/logo.svg (SVG)" || { echo "ERROR: Test 7 — asset id/path/format must reach the check step unaltered despite the apostrophes elsewhere on the line"; echo "$out"; exit 1; }
echo "$out" | grep -q "SVG is well-formed and clean" || { echo "ERROR: Test 7 — the declared asset must still validate"; echo "$out"; exit 1; }
echo "$out" | grep -q "VISUAL ASSETS PIPELINE PASSED" || { echo "ERROR: Test 7 — the pipeline must pass, not abort"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 7"

echo "Test 8 (#91 site: SVG content, line ~93): an apostrophe INSIDE the SVG file content — not the manifest row — must not abort the validator and the asset must still validate clean"
d="$(story_dir t8)"
cat > "$TMP/public/assets/apostrophe.svg" <<'EOF'
<svg viewBox="0 0 32 32"><!-- Kjetil's icon --><circle cx="16" cy="16" r="10" fill="currentColor"/></svg>
EOF
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-APOS | public/assets/apostrophe.svg | SVG | 120x32 | Primary brand mark | Company logo | Created |
EOF
set +e
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"; rc=$?
set -e
[[ "$rc" == "0" ]] || { echo "ERROR: Test 8 — an apostrophe inside the SVG's own content must not abort the validator (was #91: xargs 'unterminated quote'), rc=$rc"; echo "$out"; exit 1; }
echo "$out" | grep -q "unterminated quote" && { echo "ERROR: Test 8 — xargs quote-processing error leaked through"; echo "$out"; exit 1; }
echo "$out" | grep -q "SVG is well-formed and clean" || { echo "ERROR: Test 8 — the SVG must still validate despite the apostrophe in its content"; echo "$out"; exit 1; }
echo "$out" | grep -q "VISUAL ASSETS PIPELINE PASSED" || { echo "ERROR: Test 8 — the pipeline must pass, not abort"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 8"

echo "Test 9 (#91 sites: asset_path line ~57, asset_format line ~58): an apostrophe in the Target Path AND in the Format cell must not abort the validator, and both must reach the check step UNALTERED — not silently stripped or crashed on"
d="$(story_dir t9)"
mkdir -p "$TMP/public/assets"
printf 'not a real image, just needs to be non-empty' > "$TMP/public/assets/user's-avatar.png"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-USER | public/assets/user's-avatar.png | PNG's | 64x64 | User avatar | Avatar alt | Created |
EOF
set +e
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"; rc=$?
set -e
[[ "$rc" == "0" ]] || { echo "ERROR: Test 9 — an apostrophe in the path or format cell must not abort the validator (was #91), rc=$rc"; echo "$out"; exit 1; }
echo "$out" | grep -q "unterminated quote" && { echo "ERROR: Test 9 — xargs quote-processing error leaked through"; echo "$out"; exit 1; }
echo "$out" | grep -q "at path: public/assets/user's-avatar.png (PNG'S)" || { echo "ERROR: Test 9 — the asset path and format must reach the check step unaltered (not quote-stripped, not crashed on)"; echo "$out"; exit 1; }
echo "$out" | grep -q "VISUAL ASSETS PIPELINE PASSED" || { echo "ERROR: Test 9 — the pipeline must pass, not abort"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 9"

echo "Test 10 (#91 site: WebP magic bytes, line ~130): a real WebP fixture must exercise the magic-byte check and validate clean"
d="$(story_dir t10)"
# Minimal 12-byte WebP: 'RIFF' + 4 arbitrary size bytes + 'WEBP'. The validator only
# inspects the magic-byte signature (bytes 0-3 and 8-11), not the RIFF chunk payload.
printf 'RIFF\x00\x00\x00\x00WEBP' > "$TMP/public/assets/sample.webp"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-WEBP | public/assets/sample.webp | WEBP | 64x64 | Photographic hero | Hero alt | Created |
EOF
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1)"
echo "$out" | grep -q "WebP image signature verified" || { echo "ERROR: Test 10 — expected the WebP magic-byte check to pass on a well-formed fixture"; echo "$out"; exit 1; }
echo "$out" | grep -q "VISUAL ASSETS PIPELINE PASSED" || { echo "ERROR: Test 10 — expected overall PASS banner"; echo "$out"; exit 1; }
echo "  ✓ Passed Test 10"

echo "Test 11 (#91 site: WebP magic bytes with an APOSTROPHE in the window): the validator reports an ordinary invalid signature, it does not crash"
d="$(story_dir t11)"
# Test 10's fixture spells bytes 8-11 as the literal characters WEBP — no quote character,
# so `xargs` never chokes on it and Test 10 passes whether or not this site uses sp_trim.
# That made Test 10 vacuous AS A DEFENCE OF THIS SITE, while reading as proof of it.
#
# `od -An -t c` renders a printable byte as ITSELF, so an apostrophe byte inside the 8-11
# window reaches the trim step as a bare `'`. Under the old `$(echo … | xargs)` idiom that
# is an unterminated quote: xargs writes a diagnostic and the value is destroyed. The file
# below is a deliberately INVALID WebP whose signature window is `WE'P`, so the honest
# outcome is the ordinary "Invalid WebP" line — and crucially NOT a quoting crash.
printf 'RIFF\x00\x00\x00\x00WE\x27P' > "$TMP/public/assets/apostrophe.webp"
cat > "$d/ui-spec.md" <<'EOF'
### Declared Visual Assets Manifest

| Asset ID | Target Path | Format (SVG/WebP) | Dimensions | Visual Intent & Brand Personality Alignment | Alt Text / Aria-Label | Status |
|----------|-------------|--------------------|------------|----------------------------------------------|------------------------|--------|
| ASSET-APOS | public/assets/apostrophe.webp | WEBP | 64x64 | Photographic hero | Hero alt | Created |
EOF
out="$(cd "$TMP" && bash "$VALIDATOR" "$d/ui-spec.md" 2>&1 || true)"
if grep -q "unterminated quote" <<<"$out"; then
  echo "ERROR: Test 11 — an apostrophe in the WebP magic-byte window crashed the trim step (#91 regression)"
  echo "$out"; exit 1
fi
grep -q "Invalid WebP" <<<"$out" || {
  echo "ERROR: Test 11 — expected the ordinary 'Invalid WebP' verdict on a fixture whose signature window is WE'P"
  echo "$out"; exit 1
}
echo "  ✓ Passed Test 11"

echo "All validate-visual-assets tests passed successfully!"
exit 0
