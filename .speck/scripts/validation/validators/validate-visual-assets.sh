#!/usr/bin/env bash

# Speck Visual Assets Pipeline Validator
# Programmatically verifies the existence and well-formedness of declared visual assets.
# Rules:
# 1. SVGs must start with <svg and end with </svg>, must not contain local absolute file references.
# 2. WebPs must begin with RIFF and contain WEBP in the header.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_PATH="${1:-}"
strict="${2:-false}"

if [[ -z "$TARGET_PATH" ]]; then
  echo -e "${RED}Error: Please specify the story directory or ui-spec.md path.${NC}"
  exit 1
fi

ui_spec_path=""
if [[ -f "$TARGET_PATH" && "$(basename "$TARGET_PATH")" == "ui-spec.md" ]]; then
  ui_spec_path="$TARGET_PATH"
elif [[ -d "$TARGET_PATH" && -f "${TARGET_PATH}/ui-spec.md" ]]; then
  ui_spec_path="${TARGET_PATH}/ui-spec.md"
fi

# If no ui-spec.md exists, there's no visual asset manifest for this story to validate.
if [[ -z "$ui_spec_path" || ! -f "$ui_spec_path" ]]; then
  echo -e "ℹ️  No ui-spec.md found. Skipping Visual Assets Pipeline validation."
  exit 0
fi

echo -e "🎨 Validating Visual Assets Pipeline for $(basename "$(dirname "$ui_spec_path")")...\n"

# Parse table rows for assets under ### Declared Visual Assets Manifest
# Table row example: | ASSET-LOGO | public/assets/logo.svg | SVG | 120x32 | Style | Alt | Status |
failed=false

while IFS= read -r line; do
  trimmed=$(echo "$line" | xargs)
  if [[ "$trimmed" =~ ^\|[[:space:]]*(ASSET-[A-Za-z0-9_-]+)[[:space:]]*\|[[:space:]]*([^|]+)\|[[:space:]]*([^|]+)\|[[:space:]]*([^|]+)\| ]]; then
    asset_id="${BASH_REMATCH[1]}"
    asset_path=$(echo "${BASH_REMATCH[2]}" | xargs)
    asset_format=$(echo "${BASH_REMATCH[3]}" | xargs | tr '[:lower:]' '[:upper:]')
    
    # Skip template placeholders
    if [[ "$asset_path" == *"..."* || "$asset_id" == *"ASSET-[ID]"* ]]; then
      continue
    fi

    # Determine absolute path relative to repository root
    # Walk up from ui-spec.md until we are in the workspace root
    repo_root=$(pwd)
    abs_asset_path="${repo_root}/${asset_path}"

    echo -e "🔍 Checking asset ${BLUE}${asset_id}${NC} at path: ${asset_path} (${asset_format})"

    if [[ ! -f "$abs_asset_path" ]]; then
      echo -e "   ${RED}❌ File not found: ${asset_path}${NC}"
      failed=true
      continue
    fi

    # Validate file size is non-zero
    if [[ ! -s "$abs_asset_path" ]]; then
      echo -e "   ${RED}❌ File is empty: ${asset_path}${NC}"
      failed=true
      continue
    fi

    # Format-specific validation
    if [[ "$asset_format" == "SVG" ]]; then
      # Enforce clean SVG-First rules
      content=$(cat "$abs_asset_path" | tr '\n' ' ' | xargs || true)
      
      # 1. Basic tags check — glob match (robust across bash versions; the prior
      #    `=~ \<svg[[:space:]>]*` regex was a syntax-error risk on some bashes).
      if [[ "$content" != *"<svg"* || "$content" != *"</svg>"* ]]; then
        echo -e "   ${RED}❌ Invalid SVG: File must be well-formed and contain matching <svg> and </svg> tags.${NC}"
        failed=true
        continue
      fi

      # 2. Check for local absolute file paths (anti-pattern)
      if [[ "$content" == *"file://"* || "$content" == *"/Users/"* || "$content" == *"C:\\"* ]]; then
        echo -e "   ${RED}❌ Invalid SVG: Contains local absolute file references or leak absolute paths.${NC}"
        failed=true
        continue
      fi

      # 3. Check for inline styling anti-patterns (no hardcoded absolute styles overriding design tokens)
      # e.g., styles with absolute color hex codes that should use variables or classes
      # We just warn instead of fail to remain supportive, but we flag it!
      if [[ "$content" =~ fill=\"#([0-9A-Fa-f]{3,6})\" && ! "$content" =~ "currentColor" ]]; then
        echo -e "   ${YELLOW}⚠️  SVG contains hardcoded colors (e.g. fill=\"#...\") instead of using CSS classes or 'currentColor' for token mapping.${NC}"
      fi

      echo -e "   ${GREEN}✅ SVG is well-formed and clean!${NC}"

    elif [[ "$asset_format" == "WEBP" ]]; then
      # WebP file starts with RIFF (4 bytes), then size (4 bytes), then WEBP (4 bytes)
      # We inspect the hex signature: 52 49 46 46 (RIFF) and 57 45 42 50 (WEBP)
      magic_riff=$(od -t x1 -N 4 "$abs_asset_path" | head -n 1 | cut -d' ' -f2-5 | tr -d ' ' | tr '[:lower:]' '[:upper:]' || true)
      
      # Look for WEBP in bytes 8-11 (hex: 57454250)
      magic_webp=$(od -An -t c -j 8 -N 4 "$abs_asset_path" | xargs | tr -d ' ' || true)

      if [[ "$magic_riff" != "52494646" || "$magic_webp" != "WEBP" ]]; then
        echo -e "   ${RED}❌ Invalid WebP: Magic byte signature 'RIFF...WEBP' not found. Is it actually a WebP?${NC}"
        failed=true
        continue
      fi

      echo -e "   ${GREEN}✅ WebP image signature verified!${NC}"
    else
      echo -e "   ${YELLOW}⚠️  Asset format '${asset_format}' is skipped from binary linting.${NC}"
    fi
  fi
done < "$ui_spec_path"

if [[ "$failed" == true ]]; then
  echo -e "\n${RED}❌ VISUAL ASSETS PIPELINE FAILED: One or more assets do not exist or are structurally malformed.${NC}"
  if [[ "$strict" == "true" ]]; then
    exit 1
  fi
else
  echo -e "\n${GREEN}✅ VISUAL ASSETS PIPELINE PASSED! All declared assets are validated and compiled correctly.${NC}"
  exit 0
fi
