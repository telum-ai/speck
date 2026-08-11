#!/usr/bin/env bash
# A1-lite: fail-closed seeded defects + candidate-corpus reachability.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
exec python3 "$ROOT/tests/eval/score.py" --root "$ROOT" "$@"
