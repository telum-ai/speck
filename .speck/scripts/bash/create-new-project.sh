#!/usr/bin/env bash
set -euo pipefail

# Speck project initializer.
#
# Creates a new project directory under specs/projects/ using the next available
# numeric prefix (001, 002, ...) and a slug derived from the provided description.
#
# This script is intentionally "dumb": it scaffolds structure only.
# Content is authored by the /project-* commands using templates.

JSON_MODE=false
DRY_RUN=false
FORCE=false
PROJECT_ID_OVERRIDE=""
ARGS=()

usage() {
  cat <<'EOF'
Usage:
  .speck/scripts/bash/create-new-project.sh [--json] [--dry-run] [--force] <project description>

Flags:
  --json      Output JSON with resolved paths and IDs (for agents/automation)
  --dry-run   Print what would be created, but do not write to disk
  --force     If the target directory already exists, do not fail
  --project-id <id>  Use an already-declared canonical project ID
  -h, --help  Show this help

Examples:
  .speck/scripts/bash/create-new-project.sh "Build a task manager"
  .speck/scripts/bash/create-new-project.sh --json "Import existing Rails app"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    --project-id) PROJECT_ID_OVERRIDE="${2:-}"; shift 2 ;;
    --project-id=*) PROJECT_ID_OVERRIDE="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; ARGS+=("$@"); break ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

DESCRIPTION="${ARGS[*]:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROJECTS_DIR="$REPO_ROOT/specs/projects"
PROJECT_JSON="$REPO_ROOT/.speck/project.json"

DECLARED_PROJECT_ID=""
DECLARED_PROJECT_ID_KEY=""
if [[ -f "$PROJECT_JSON" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required to read the declared project_id from .speck/project.json" >&2
    exit 1
  fi
  DECLARED_RAW=""
  if ! DECLARED_RAW="$(python3 - "$PROJECT_JSON" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except (OSError, json.JSONDecodeError) as exc:
    print(f"ERROR: Cannot read {path}: {exc}", file=sys.stderr)
    raise SystemExit(1)

value = data.get("project_id", "")
if value is None:
    value = ""
if not isinstance(value, str):
    print("ERROR: .speck/project.json project_id must be a string", file=sys.stderr)
    raise SystemExit(1)
value = value.strip()
key = "project_id"
# project-specify/SKILL.md documents and reads `project_id` back, so it stays the
# primary key. When it is absent, fall back to the SAME "_active_project" /
# "active_project" keys every other Speck resolver in this repo (profile-lib.sh,
# profile-surface-check.py, banned-language-lint.sh) reads as the declared canonical
# project, so a repo that followed THAT convention instead still gets the same
# single-project pin rather than silently having none.
if not value:
    for k in ("_active_project", "active_project"):
        alt = data.get(k)
        if isinstance(alt, str) and alt.strip():
            value = alt.strip()
            key = k
            break
print(key)
print(value)
PY
)"; then
    exit 1
  fi
  DECLARED_PROJECT_ID_KEY="$(printf '%s\n' "$DECLARED_RAW" | sed -n '1p')"
  DECLARED_PROJECT_ID="$(printf '%s\n' "$DECLARED_RAW" | sed -n '2p')"
fi

mkdir -p "$PROJECTS_DIR"

# Determine next numeric prefix (001, 002, ...).
max=0
shopt -s nullglob
for d in "$PROJECTS_DIR"/*; do
  [[ -d "$d" ]] || continue
  base="$(basename "$d")"
  if [[ "$base" =~ ^([0-9]{3})- ]]; then
    num="${BASH_REMATCH[1]}"
    num10=$((10#$num))
    if (( num10 > max )); then
      max=$num10
    fi
  fi
done
next=$((max + 1))
prefix=$(printf "%03d" "$next")

# Slugify description → directory suffix.
slug="project"
if [[ -n "$DESCRIPTION" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    slug="$(python3 - "$DESCRIPTION" <<'PY'
import re, sys
text = sys.argv[1].strip().lower()
text = re.sub(r'[^a-z0-9]+', '-', text)
text = re.sub(r'-+', '-', text).strip('-')
if not text:
    text = "project"
# Keep directory names short-ish.
text = text[:40].strip('-') or "project"
print(text)
PY
)"
  else
    # Fallback slugify (ASCII-only).
    slug="$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g; s/-+/-/g' | cut -c1-40)"
    [[ -n "$slug" ]] || slug="project"
  fi
fi

if [[ -n "$PROJECT_ID_OVERRIDE" && -n "$DECLARED_PROJECT_ID" && "$PROJECT_ID_OVERRIDE" != "$DECLARED_PROJECT_ID" ]]; then
  echo "ERROR: --project-id '$PROJECT_ID_OVERRIDE' conflicts with declared project_id '$DECLARED_PROJECT_ID'" >&2
  exit 1
fi

canonical_project_id="${PROJECT_ID_OVERRIDE:-$DECLARED_PROJECT_ID}"
if [[ -n "$canonical_project_id" ]]; then
  if [[ ! "$canonical_project_id" =~ ^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "ERROR: Invalid --project-id or declared project_id: $canonical_project_id" >&2
    exit 1
  fi
  project_id="$canonical_project_id"
else
  project_id="${prefix}-${slug}"
fi
project_rel="specs/projects/${project_id}"
project_abs="${PROJECTS_DIR}/${project_id}"

if [[ -d "$project_abs" && "$FORCE" != true ]]; then
  echo "ERROR: Project directory already exists: $project_rel" >&2
  if [[ -n "$DECLARED_PROJECT_ID" && -z "$PROJECT_ID_OVERRIDE" ]]; then
    # A different description CANNOT produce a different id here: canonical_project_id
    # overrode the slug derivation entirely, so "choose a different project description"
    # (the id-collision hint below) would be silently wrong advice.
    echo "Hint: .speck/project.json's \"$DECLARED_PROJECT_ID_KEY\" pins every project creation" >&2
    echo "  here regardless of description. Pass --project-id for a genuinely different" >&2
    echo "  project, or edit/remove \"$DECLARED_PROJECT_ID_KEY\" in .speck/project.json to stop pinning." >&2
  else
    echo "Hint: Re-run with --force or choose a different project description." >&2
  fi
  exit 1
fi

if [[ -d "$project_abs" && "$FORCE" == true && -n "$DECLARED_PROJECT_ID" && -z "$PROJECT_ID_OVERRIDE" ]]; then
  # --force means "do not fail", never "do not say why". Scaffolding a description for
  # a DIFFERENT product into the pinned project's directory is exactly the collision
  # the finding this comment cites reproduced end-to-end.
  echo "⚠️  --force is scaffolding \"$DESCRIPTION\" into $project_rel because .speck/project.json's" >&2
  echo "  \"$DECLARED_PROJECT_ID_KEY\" pins every project creation here — this is very likely NOT" >&2
  echo "  a fresh directory for this description." >&2
fi

if [[ "$DRY_RUN" != true ]]; then
  mkdir -p "$project_abs/epics"

  # Create a minimal stub project.md if missing. The /project-specify command will overwrite it.
  if [[ ! -f "$project_abs/project.md" ]]; then
    created_date="$(date -u +"%Y-%m-%d")"
    cat > "$project_abs/project.md" <<EOF
# Project Specification: [PROJECT NAME]

**Project ID**: ${project_id}  
**Created**: ${created_date}  
**Status**: Draft

> Created by \`.speck/scripts/bash/create-new-project.sh\`.
> Next: run \`/project-specify\` to fill in the full project specification.

---
EOF
  fi
fi

if [[ "$JSON_MODE" = true ]]; then
  export SPECK_PROJECT_ID="$project_id"
  export SPECK_PROJECT_REL="$project_rel"
  export SPECK_PROJECT_ABS="$project_abs"
  export SPECK_CREATED_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  export SPECK_DRY_RUN="$DRY_RUN"

  if command -v python3 >/dev/null 2>&1; then
    python3 - <<'PY'
import json, os
project_rel = os.environ["SPECK_PROJECT_REL"]
ensured = [
    f"{project_rel}/project.md",
]

print(json.dumps(
    {
        "project_id": os.environ["SPECK_PROJECT_ID"],
        "project_dir": os.environ["SPECK_PROJECT_REL"],
        "project_abs_path": os.environ["SPECK_PROJECT_ABS"],
        "created_utc": os.environ["SPECK_CREATED_UTC"],
        "dry_run": os.environ.get("SPECK_DRY_RUN") == "true",
        "ensured_files": ensured,
        "notes": [
            "Created project directory and epics/.",
            "Created minimal project.md stub (overwrite via /project-specify).",
        ],
    },
    indent=2,
))
PY
  else
    # Minimal JSON fallback.
    echo "{\"project_id\":\"$project_id\",\"project_dir\":\"$project_rel\",\"project_abs_path\":\"$project_abs\"}"
  fi
else
  echo "✅ Speck project initialized"
  echo "- Project: $project_id"
  echo "- Path: $project_rel"
fi
