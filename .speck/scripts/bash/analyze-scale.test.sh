#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT="$ROOT/.speck/scripts/bash/analyze-scale.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

assert_route() {
  local expected_level="$1" expected_complexity="$2" request="$3"
  bash "$SCRIPT" --json "$request" > "$TMP/out.json"
  python3 - "$TMP/out.json" "$expected_level" "$expected_complexity" <<'PY'
import json, pathlib, sys
path, level, complexity = pathlib.Path(sys.argv[1]), sys.argv[2], int(sys.argv[3])
data = json.loads(path.read_text())
assert data["routing"]["suggested_level"] == level, data
assert data["routing"]["complexity"] == complexity, data
assert "play_level" not in data and "play_level" not in data["routing"], data
PY
}

assert_route project 3 "Build a new multi-team subscription product from this clear business idea; the whole product needs specification."
assert_route epic 2 "Add a complete authentication capability spanning login, recovery, and session handling."
assert_route story 1 "Change one validated settings form so a single field is required."
assert_route project 3 "project: modernize the existing billing capability"
assert_route epic 2 "epic: modernize the billing capability"
assert_route story 1 "story: modernize the billing button"

# L11.5 — atomic keywords must not outrank capability/project-sized requests that merely
# mention one in passing. All four are reproduced findings: each used to route to
# story/1/medium/atomic_change_phrase on a request an unscoped agent would then enter at
# story-specify, skipping epic/project foundation entirely.
assert_route epic 2 "Build a design system with color tokens, dark mode toggle, component library, and documentation site for the whole engineering org"
assert_route epic 2 "Build a full authentication and billing capability with SSO, MFA, audit logs, and a rename of the legacy user table"
assert_route epic 2 "Ship a complete billing capability with invoices, dunning, proration and colors"

# L11.5b — "namespacing" must not match the bare, unbounded "spacing" atomic keyword (no
# word boundaries, unlike the explicit-marker branches). This request has no capability
# keyword either, so it lands in the honest low-confidence length fallback rather than a
# false, confident "atomic_change_phrase" claim.
assert_route story 1 "Add namespacing across all microservices for every team this year and next"
bash "$SCRIPT" --json "Add namespacing across all microservices for every team this year and next" > "$TMP/namespacing.json"
python3 - "$TMP/namespacing.json" <<'PY'
import json, pathlib, sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
routing = data["routing"]
assert routing["signal"] != "atomic_change_phrase", f"'namespacing' still false-matched bare 'spacing': {routing}"
assert routing["confidence"] == "low", f"expected an honestly-hedged low confidence, got: {routing}"
PY

# L11.5c — still-genuinely-atomic requests keep routing to story with medium confidence;
# the ordering/gating fix must not regress the true-positive case.
assert_route story 1 "Change one validated settings form so a single field is required."
bash "$SCRIPT" --json "Fix a typo in the login page" > "$TMP/typo.json"
python3 - "$TMP/typo.json" <<'PY'
import json, pathlib, sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
routing = data["routing"]
assert routing["signal"] == "atomic_change_phrase", routing
assert routing["suggested_level"] == "story" and routing["complexity"] == 1, routing
PY

echo "analyze-scale routing tests passed"
