#!/usr/bin/env bash
set -euo pipefail
FIXDIR="$(cd "$(dirname "$0")" && pwd)"
rg -qi "same-session-implementer|skills_invoked: \[\]" "$FIXDIR/audit-report.md"
