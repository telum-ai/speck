#!/usr/bin/env bash
set -euo pipefail
FIXDIR="$(cd "$(dirname "$0")" && pwd)"
rg -q "\| open \|" "$FIXDIR/traceability-matrix.md"
