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
  OUT_ABS="$(cd "$(dirname "$OUT_DIR")" && pwd)/$(basename "$OUT_DIR")"
  if [[ -z "$OUT_ABS" || "$OUT_ABS" == "/" || "$OUT_ABS" == "$REPO_ROOT" ]]; then
    echo "ERROR: refusing to clean unsafe output path: $OUT_ABS" >&2
    exit 1
  fi
  find "$OUT_ABS" -depth -mindepth 1 -delete
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
  (cd "$src" && tar --exclude='__pycache__' --exclude='*/__pycache__' --exclude='*.pyc' --exclude='.DS_Store' -cf - .) | (cd "$dest" && tar -xf -)
}

# Core files
copy_file "$REPO_ROOT/AGENTS.md" "$OUT_DIR/AGENTS.md"
copy_file "$REPO_ROOT/CLAUDE.md" "$OUT_DIR/CLAUDE.md"

# Shipped Speck runtime. Methodology tests, reports, feedback, and release history stay
# in the framework repository; downstream agents load only executable runtime context.
for runtime_path in README.md VERSION mcp recipes reference scripts templates; do
  source_path="$REPO_ROOT/.speck/$runtime_path"
  target_path="$OUT_DIR/.speck/$runtime_path"
  if [[ -d "$source_path" ]]; then
    copy_dir "$source_path" "$target_path"
  else
    copy_file "$source_path" "$target_path"
  fi
done

# Cursor skills, agents, hooks
mkdir -p "$OUT_DIR/.cursor"
copy_dir "$REPO_ROOT/.cursor/skills" "$OUT_DIR/.cursor/skills"
copy_dir "$REPO_ROOT/.cursor/agents" "$OUT_DIR/.cursor/agents"
copy_dir "$REPO_ROOT/.cursor/hooks" "$OUT_DIR/.cursor/hooks"
copy_file "$REPO_ROOT/.cursor/MCP-SETUP.md" "$OUT_DIR/.cursor/MCP-SETUP.md"
copy_file "$REPO_ROOT/.cursor/mcp.json.example" "$OUT_DIR/.cursor/mcp.json.example"
copy_file "$REPO_ROOT/.cursor/mcp.project.json.example" "$OUT_DIR/.cursor/mcp.project.json.example"

# Generated agents use host-specific file formats and model names.
copy_dir "$REPO_ROOT/.claude/agents" "$OUT_DIR/.claude/agents"
copy_dir "$REPO_ROOT/.codex/agents" "$OUT_DIR/.codex/agents"
copy_dir "$REPO_ROOT/.claude/hooks" "$OUT_DIR/.claude/hooks"
copy_file "$REPO_ROOT/.claude/loop.md" "$OUT_DIR/.claude/loop.md"
copy_file "$REPO_ROOT/.claude/settings.json.example" "$OUT_DIR/.claude/settings.json.example"

# Cross-tool skill discovery points to the canonical Cursor skill tree.
for runtime_dir in .claude .codex .agents; do
  mkdir -p "$OUT_DIR/$runtime_dir"
  ln -s ../.cursor/skills "$OUT_DIR/$runtime_dir/skills"
done

# Template repo root README.md
cat > "$OUT_DIR/README.md" <<'EOF'
# Speck 🥓 Template

Speck is a spec-driven development methodology for building digital products via:
- **Skills** (`.cursor/skills/`)
- **Templates** (`.speck/templates/`)
- **Automation hooks** (`.cursor/hooks/`)
- **Local validation scripts** (`.speck/scripts/validation/`)

## Getting Started

In your agent host, describe what you want to build. The managed root `AGENTS.md`
routes the request automatically; `/speck` remains an optional compatibility alias.

Speck will route you through **project → epic → story** levels.

## MCP Setup (Recommended)

See: `.cursor/MCP-SETUP.md`

## Specs live here

Speck project artifacts are written under:
- `specs/projects/`
EOF

# Template repo .gitignore (minimal + Speck-specific)
cat > "$OUT_DIR/.gitignore" <<'EOF'
# Cursor local MCP config may include secrets
.cursor/mcp.json

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

Describe your idea to the agent to generate and populate these. Root `AGENTS.md` routes it.
EOF

# Ensure hook scripts are executable in exported repo
chmod +x "$OUT_DIR/.cursor/hooks/hooks/"*.sh 2>/dev/null || true
chmod +x "$OUT_DIR/.claude/hooks/"*.sh 2>/dev/null || true
chmod +x "$OUT_DIR/.speck/scripts/bash/"*.sh 2>/dev/null || true
chmod +x "$OUT_DIR/.speck/scripts/validation/"*.sh 2>/dev/null || true
chmod +x "$OUT_DIR/.speck/scripts/validation/validators/"*.sh 2>/dev/null || true

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
