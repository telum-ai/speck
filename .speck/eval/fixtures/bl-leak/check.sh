#!/usr/bin/env bash
set -euo pipefail
FIXDIR="$(cd "$(dirname "$0")" && pwd)"
rg -qi "ready for launch|premium polish complete|tests pass therefore done" "$FIXDIR/copy.md"
