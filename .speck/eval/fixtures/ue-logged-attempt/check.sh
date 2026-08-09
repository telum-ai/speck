#!/usr/bin/env bash
set -euo pipefail
FIXDIR="$(cd "$(dirname "$0")" && pwd)"
rg -qi "named infra blocker|cannot reach" "$FIXDIR/validation-report.md" && ! rg -qi "attempt log|reproduced" "$FIXDIR/validation-report.md"
