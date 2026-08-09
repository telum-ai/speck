#!/usr/bin/env bash
set -euo pipefail
FIXDIR="$(cd "$(dirname "$0")" && pwd)"
rg -q "UX-RC" "$FIXDIR/validation-report.md" && ! rg -qi "adjudicat|IS-IT-GOOD|per-screen critique" "$FIXDIR/validation-report.md"
