#!/usr/bin/env bash
# lint-staged wrapper for banned-language-lint.sh
# Auto-detects PROJECT_DIR from cwd; forwards staged file paths as arguments.
#
# Usage in lint-staged / Husky:
#   "bash .speck/scripts/banned-language-lint-staged.sh"
#
# Equivalent to:
#   bash -c 'bash .speck/scripts/banned-language-lint.sh "" "$@"' _ "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/banned-language-lint.sh"

# lint-staged hands us the matched files. With an EMPTY list the old `lint "" "$@"` form
# passed rg a "" path; drop the placeholder instead and the same invocation degenerates
# into the no-targets branch — silently escalating a diff-scoped pre-commit check into a
# full-repo scan that convicts files this commit never touched.
#
# Neither is honest. With nothing handed to us we delegate to `--staged`, so the SUBJECT
# is the gate's own definition of the staged product surface (git-derived, scope- and
# exclude-filtered) rather than lint-staged's, and the run still publishes a real
# SPECK_GATE_PREDICATES count. An empty subject then means "this commit has none",
# EMPTY-LEGITIMATE — never "the declared scope cannot reach the subject" (#98 §1).
if [[ $# -eq 0 ]]; then
  exec bash "$LINT" --staged
fi

# --advisory-parse-defects, because this wrapper IS the pre-commit surface Speck documents
# (.speck/patterns/constitution-as-code.md wires it into Husky/lint-staged) but the file
# list sends us down the explicit-targets path, not --staged. Without it, one typo'd §7 row
# — a defect in product-contract.md, not in the files being committed — blocks every commit
# in the repo, including the commit that would fix the row. The diagnostic still prints in
# full; only the exit is advisory. The full-scan / CI run still fails on it.
exec bash "$LINT" --advisory-parse-defects "" "$@"
