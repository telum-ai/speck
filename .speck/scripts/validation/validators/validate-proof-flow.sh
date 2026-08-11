#!/usr/bin/env bash
set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)}"
FAILURES=0

require() {
  local file="$1" pattern="$2" message="$3"
  if ! grep -Eqi "$pattern" "$ROOT/$file"; then
    echo "PROOF_FLOW.P1: $message ($file)"
    FAILURES=$((FAILURES + 1))
  fi
}

forbid() {
  local file="$1" pattern="$2" message="$3"
  if grep -Eqi "$pattern" "$ROOT/$file"; then
    echo "PROOF_FLOW.P1: $message ($file)"
    FAILURES=$((FAILURES + 1))
  fi
}

# Producer order is interface-independent; visual evidence is the UI-only branch.
require "AGENTS.md" 'Epic:.*speck-audit\(epic\).*speck-larp\(\+ visual-testing if UI\).*epic-validate' "epic validation is not preceded by job evidence"
require "AGENTS.md" 'Story:.*speck-audit.*speck-larp\(\+ visual-testing if UI\).*story-validate' "story validation is not preceded by job evidence"
require "AGENTS.md" 'Project close:.*speck-larp\(\+ visual-testing if UI\).*project-validate' "project validation is not preceded by job evidence"
require "AGENTS.md" 'Validation follows and only adjudicates checked-in evidence' "validation role boundary is missing"

# The always-loaded spines own entry gates only. JIT nodes own their procedures.
forbid ".cursor/skills/epic-validate/references/spine.md" '^## .*Four axes|validate-traceability-matrix|^## .*Write outputs|^## NEVER / ALWAYS' "epic spine duplicates a JIT validation procedure"
forbid ".cursor/skills/epic-validate/references/mutation.md" '^## .*Four axes' "mutation node duplicates rollup axes"
require ".cursor/skills/epic-validate/references/rollup.md" 'Judge the axes independently' "epic rollup does not own axis adjudication"
require ".cursor/skills/epic-validate/references/matrix-graph.md" 'validate-traceability-matrix' "matrix node does not own promise conservation"
require ".cursor/skills/epic-validate/references/post-write.md" 'validate-felt-axis.*strict' "post-write node does not own output closure"

forbid ".cursor/skills/project-validate/references/spine.md" '^## .*Four axes|^## .*Write outputs' "project spine duplicates a JIT validation procedure"
forbid ".cursor/skills/project-validate/references/gate-liveness.md" '^## .*Readiness states|^## .*Four axes|^## NEVER / ALWAYS' "gate-liveness node duplicates core validation"
forbid ".cursor/skills/project-validate/references/commercial.md" '^## NEVER / ALWAYS|validate-gate-liveness|gate-liveness-probe' "commercial node duplicates another validation procedure"
require ".cursor/skills/project-validate/references/rollup.md" '^## .*Four axes' "project rollup does not own axis adjudication"
require ".cursor/skills/project-validate/references/post-write.md" 'validate-felt-axis.*strict' "project post-write node does not own output closure"

# UI and nonvisual projects produce different evidence, then enter the same judge.
require ".cursor/skills/project-validate/references/spine.md" 'UI projects require every epic at `UX-RC`' "UI project readiness branch is missing"
require ".cursor/skills/project-validate/references/spine.md" 'nonvisual/API projects require `API-RC`' "nonvisual project readiness branch is missing"
require ".cursor/skills/project-validate/references/spine.md" 'nonvisual/API requires.*operational scenario' "nonvisual project evidence is missing"
require ".cursor/skills/project-validate/references/jtbd-smoke.md" 'Do not run the job here' "project validation still produces its own job evidence"
require ".cursor/skills/project-validate/references/jtbd-smoke.md" 'routes back to `speck-larp`' "missing project evidence does not route to its producer"

# Premise challenge is generic; only UI-specific evidence may be skipped.
forbid ".cursor/skills/story-validate/references/backend-skip.md" 'Skip (LARP, )?Premise-Challenge|skip.*`speck-premise-challenge`' "backend story validation waives generic premise challenge"
forbid ".cursor/skills/epic-validate/references/spine.md" 'skip LARP \+ Premise-Challenge' "backend epic validation waives generic premise challenge"
require ".cursor/skills/story-validate/references/backend-skip.md" 'high-impact nonvisual commitment' "backend story premise trigger is missing"
require ".cursor/skills/story-validate/references/backend-skip.md" 'speck-premise-challenge' "backend story premise route is missing"
require ".cursor/skills/epic-validate/references/backend-skip.md" 'high-impact nonvisual commitments' "backend epic premise trigger is missing"
require ".cursor/skills/epic-validate/references/backend-skip.md" 'speck-premise-challenge' "backend epic premise route is missing"

if (( FAILURES > 0 )); then
  echo "proof-flow: FAILED findings=$FAILURES"
  exit 1
fi

echo "proof-flow: PASS"
