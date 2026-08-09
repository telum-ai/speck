#!/usr/bin/env bash
set -euo pipefail
FIXDIR="$(cd "$(dirname "$0")" && pwd)"
path=$(rg -o "screenshots/[^ )]+" "$FIXDIR/validation-report.md" | head -1); [[ -n "$path" && ! -f "$FIXDIR/$path" ]]
