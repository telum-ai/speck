#!/usr/bin/env bash
# regenerate-project-state.sh — Hint script invoked from post-command hooks
#
# This script does NOT regenerate project-state.md itself (that requires an AI agent
# because project-state.md synthesizes from multiple sources). Instead, it prints
# the trigger reason and the recommended next command for an AI agent watching
# command output.
#
# Usage:
#   .speck/scripts/regenerate-project-state.sh <reason>
#
# Where <reason> is one of:
#   story-validate-pass
#   epic-validate-complete
#   project-validate-complete
#   recheck-complete
#   manual-request

REASON="${1:-manual-request}"

cat <<EOF
🔁 PROJECT_STATE_REGENERATION_REQUESTED

Reason: $REASON
Recommended next action for the agent: invoke /project-state to regenerate the single-page status doc.

This script is a marker for hook-based regeneration. The AI agent should detect this
output and run the project-state skill before completing the current command.
EOF

exit 0
