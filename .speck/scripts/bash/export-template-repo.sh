#!/usr/bin/env bash
set -euo pipefail

# Export Speck methodology files into a clean folder suitable for a template repository.
#
# This script intentionally excludes product code (e.g. backend/, frontend/, specs/ content)
# and excludes project-owned Cursor rules (`.cursor/rules/**`).
#
# Output is a standalone directory you can `git init` + push to a new repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

OUT_DIR="$REPO_ROOT/_speck-template-repo"
CLEAN=false
JSON_MODE=false

usage() {
  cat <<'EOF'
Usage:
  bash .speck/scripts/bash/export-template-repo.sh [--out <dir>] [--clean] [--json]

Defaults:
  --out   ./_speck-template-repo

Notes:
  - This does not touch any product application code.
  - This excludes `.cursor/rules/**` so each product repo can define its own rules.
  - The exported folder includes a fresh README.md, .gitignore, and empty specs/ scaffold.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT_DIR="${2:-}"; shift 2 ;;
    --clean) CLEAN=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$CLEAN" = true && -d "$OUT_DIR" ]]; then
  rm -rf "$OUT_DIR"
fi

mkdir -p "$OUT_DIR"

copy_file() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

copy_dir() {
  local src="$1"
  local dest="$2"
  mkdir -p "$dest"
  # Use tar to preserve executable bits without relying on rsync.
  (cd "$src" && tar -cf - .) | (cd "$dest" && tar -xf -)
}

# Core files
copy_file "$REPO_ROOT/AGENTS.md" "$OUT_DIR/AGENTS.md"

# Speck methodology
copy_dir "$REPO_ROOT/.speck" "$OUT_DIR/.speck"

# Cursor skills, agents, hooks
mkdir -p "$OUT_DIR/.cursor"
copy_dir "$REPO_ROOT/.cursor/skills" "$OUT_DIR/.cursor/skills"
copy_dir "$REPO_ROOT/.cursor/agents" "$OUT_DIR/.cursor/agents"
copy_dir "$REPO_ROOT/.cursor/hooks" "$OUT_DIR/.cursor/hooks"
copy_file "$REPO_ROOT/.cursor/MCP-SETUP.md" "$OUT_DIR/.cursor/MCP-SETUP.md"
copy_file "$REPO_ROOT/.cursor/mcp.json.example" "$OUT_DIR/.cursor/mcp.json.example"
copy_file "$REPO_ROOT/.cursor/mcp.project.json.example" "$OUT_DIR/.cursor/mcp.project.json.example"

# Cross-tool symlinks (.claude and .codex point to .cursor)
for runtime_dir in .claude .codex; do
  mkdir -p "$OUT_DIR/$runtime_dir"
  ln -s ../.cursor/skills "$OUT_DIR/$runtime_dir/skills"
  ln -s ../.cursor/agents "$OUT_DIR/$runtime_dir/agents"
done

# Workflows (methodology-only)
mkdir -p "$OUT_DIR/.github/workflows"
copy_file "$REPO_ROOT/.github/workflows/speck-validation.yml" "$OUT_DIR/.github/workflows/speck-validation.yml"
copy_file "$REPO_ROOT/.github/workflows/speck-orchestrator.yml" "$OUT_DIR/.github/workflows/speck-orchestrator.yml"
copy_file "$REPO_ROOT/.github/workflows/speck-update-check.yml" "$OUT_DIR/.github/workflows/speck-update-check.yml"
copy_file "$REPO_ROOT/.github/workflows/copilot-setup-steps.yml" "$OUT_DIR/.github/workflows/copilot-setup-steps.yml"

# GitHub repo hygiene (methodology-only)
mkdir -p "$OUT_DIR/.github"
copy_file "$REPO_ROOT/.github/copilot-instructions.md" "$OUT_DIR/.github/copilot-instructions.md"
copy_dir "$REPO_ROOT/.github/instructions" "$OUT_DIR/.github/instructions"
copy_dir "$REPO_ROOT/.github/ISSUE_TEMPLATE" "$OUT_DIR/.github/ISSUE_TEMPLATE"
copy_file "$REPO_ROOT/.github/pull_request_template.md" "$OUT_DIR/.github/pull_request_template.md"

# Template repo root README.md
cat > "$OUT_DIR/README.md" <<'EOF'
# Speck 🥓 Template

Speck is a spec-driven development methodology for building digital products via:
- **Skills** (`.cursor/skills/`)
- **Templates** (`.speck/templates/`)
- **Automation hooks** (`.cursor/hooks/`)
- **Validation workflows** (`.github/workflows/`)

## Getting Started

In Cursor, start with:
- `/speck` or `@speck` followed by what you want to build

Speck will route you through **project → epic → story** levels.

## MCP Setup (Recommended)

See: `.cursor/MCP-SETUP.md`

## Specs live here

Speck project artifacts are written under:
- `specs/projects/`

## Keeping Speck up to date (recommended)

This template includes the Speck update workflow:
- `.github/workflows/speck-update-check.yml` (daily)

It runs:
- `npx github:telum-ai/speck upgrade`

This applies smart merging rules and preserves project customizations where intended.
EOF

# Template repo .gitignore (minimal + Speck-specific)
cat > "$OUT_DIR/.gitignore" <<'EOF'
# Cursor local MCP config may include secrets
.cursor/mcp.json

# Speck learning capture logs are not committed
**/.learning.log

# Logs
logs/
*.log

# OS
.DS_Store
EOF

# Empty specs scaffold (do not include product specs)
mkdir -p "$OUT_DIR/specs/projects"
cat > "$OUT_DIR/specs/README.md" <<'EOF'
# Specs

Speck project artifacts live under:

- `specs/projects/<project-id>/...`

Start with `/speck [idea]` to generate and populate these.
EOF

# Ensure hook scripts are executable in exported repo
chmod +x "$OUT_DIR/.cursor/hooks/hooks/"*.sh 2>/dev/null || true
chmod +x "$OUT_DIR/.cursor/hooks/hooks/validators/"*.sh 2>/dev/null || true
chmod +x "$OUT_DIR/.speck/scripts/bash/"*.sh 2>/dev/null || true

if [[ "$JSON_MODE" = true ]]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY
import json
print(json.dumps({"status":"success","out_dir":"$OUT_DIR"}, indent=2))
PY
  else
    echo "{\"status\":\"success\",\"out_dir\":\"$OUT_DIR\"}"
  fi
else
  echo "✅ Exported Speck template repo to: $OUT_DIR"
  echo "Next:"
  echo "  cd \"$OUT_DIR\""
  echo "  git init && git add . && git commit -m \"chore: initial Speck template\""
  echo "  # create a GitHub repo and push"
fi

