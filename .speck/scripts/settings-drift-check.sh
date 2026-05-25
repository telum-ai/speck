#!/usr/bin/env bash
# settings-drift-check.sh — SETTINGS_DRIFT detection for /recheck
#
# Usage: .speck/scripts/settings-drift-check.sh [WORKSPACE_ROOT]
#
# Exit: 0 in sync, 1 P0 drift found, 2 missing example (no Claude settings shipped)

set -euo pipefail

WORKSPACE="${1:-$(pwd)}"
EXAMPLE="$WORKSPACE/.claude/settings.json.example"
ACTIVE="$WORKSPACE/.claude/settings.json"

if [[ ! -f "$EXAMPLE" ]]; then
  exit 2
fi

if [[ ! -f "$ACTIVE" ]]; then
  echo "SETTINGS_DRIFT.P0: .claude/settings.json missing (Speck-managed hooks not installed)"
  echo "  Action: run \`npx github:telum-ai/speck reconcile-settings\`"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SETTINGS_DRIFT.P2: jq not installed — cannot verify Claude settings drift" >&2
  exit 0
fi

P0=0

# Default managed blocks when _speck_managed absent (pre-v7.8 workspaces)
mapfile -t BLOCKS < <(jq -r '._speck_managed.blocks[]? // empty' "$EXAMPLE" 2>/dev/null || true)
if [[ ${#BLOCKS[@]} -eq 0 ]]; then
  BLOCKS=(hooks.Stop hooks.SessionStart hooks.PostToolUse)
fi

for block in "${BLOCKS[@]}"; do
  [[ -z "$block" ]] && continue
  jqpath=".${block//./.}"
  ex="$(jq -c "$jqpath" "$EXAMPLE" 2>/dev/null || echo "null")"
  ac="$(jq -c "$jqpath" "$ACTIVE" 2>/dev/null || echo "null")"
  if [[ "$ex" != "$ac" ]]; then
    echo "SETTINGS_DRIFT.P0: Speck-managed block differs — $block"
    echo "  Action: run \`npx github:telum-ai/speck reconcile-settings\`"
    P0=$((P0 + 1))
  fi
done

# Detect legacy prompt-type Stop hook (infinite-loop class)
if jq -e '.hooks.Stop[]?.hooks[]? | select(.type == "prompt")' "$ACTIVE" >/dev/null 2>&1; then
  echo "SETTINGS_DRIFT.P0: legacy prompt-type Stop hook detected (use command hook stop-gate.sh)"
  echo "  Action: run \`npx github:telum-ai/speck reconcile-settings\`"
  P0=$((P0 + 1))
fi

if [[ $P0 -gt 0 ]]; then
  exit 1
fi

exit 0
