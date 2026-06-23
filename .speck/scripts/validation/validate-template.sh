#!/usr/bin/env bash

# Central Automated Template Validation Router
# Routes Speck artifacts to their respective validators.
#
# Usage:
#   bash validate-template.sh <file_path> [--strict]
#
# Accepts:
#   file_path: Relative or absolute path to the file to validate.
#   --strict:  Exit with non-zero code on validation errors.

set -euo pipefail

# Auto-detect AI Agent environment to enforce strictness on agents while remaining gentle on manual human edits.
# Checks indicators across Claude Code, Cursor, Codex, and CI/CD environments.
is_agent=false
if [[ -n "${CLAUDE_CODE:-}" || -n "${CLAUDE_AGENT_ID:-}" || -n "${CURSOR_AGENT:-}" || -n "${COMPOSER_AGENT:-}" || -n "${SPECK_STRICT:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
  is_agent=true
fi

strict=$is_agent
file_path=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      strict=true
      shift
      ;;
    *)
      if [[ -z "$file_path" ]]; then
        file_path="$1"
      else
        echo "ERROR: Unknown or duplicate argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$file_path" ]]; then
  echo "ERROR: Missing file path argument" >&2
  exit 1
fi

# Skip if file doesn't exist
if [[ ! -f "$file_path" ]]; then
  exit 0
fi

# Only validate Speck artifacts (not code, not .cursor, not .speck)
if [[ "$file_path" == *".cursor/"* ]] || [[ "$file_path" == *".speck/"* ]]; then
  exit 0
fi

# Only validate markdown files in specs/ directory
if [[ "$file_path" != *"specs/"* ]] || [[ "$file_path" != *".md" ]]; then
  exit 0
fi

# === STEP 1: Run Python-based Template Placeholder Scanner ===
if command -v python3 >/dev/null 2>&1; then
  if ! python3 - "$file_path" << 'EOF'
import sys
import re

file_path = sys.argv[1]
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

errors = []

SHA_STAMP_LINE = re.compile(
    r'^\s*\*?\[?as of SHA\b.*\bverified\b.*\bspeck\b',
    re.IGNORECASE,
)
SHA_STAMP_BRACKET = re.compile(
    r'^as of SHA\b.*\bverified\b',
    re.IGNORECASE,
)

CITATION_LINE_PHRASES = (
    "no outstanding",
    "none introduced",
    "none present",
    "not actively present",
    "documented as",
    "being cited",
    "cited descriptively",
    "we use ",
    "for open items",
    "(was ",
    "(resolved",
    "markers (",
    "marker is being",
)

TEMPLATE_BRACKET_MARKERS = (
    "NEEDS CLARIFICATION",
    "REPLACE_BEFORE_SHIP",
    "TEMPLATE:",
    "PLACEHOLDER:",
)

def line_at(content, pos):
    start = content.rfind("\n", 0, pos) + 1
    end = content.find("\n", pos)
    if end == -1:
        end = len(content)
    return content[start:end], start


def is_sha_stamp_line(line):
    stripped = line.strip()
    if SHA_STAMP_LINE.search(stripped):
        return True
    if stripped.startswith("*[as of SHA") and "verified" in stripped and "speck" in stripped.lower():
        return True
    return False


def is_citation_context(line, bracket_content):
    lower_line = line.lower()
    if any(phrase in lower_line for phrase in CITATION_LINE_PHRASES):
        return True
    upper = bracket_content.upper()
    for marker in TEMPLATE_BRACKET_MARKERS:
        if marker in line and upper == marker:
            return True
    return False


def is_prose_annotation(bracket_content):
    if is_template_bracket(bracket_content):
        return False
    if re.match(r'^(moved|powers|see|ref|via|from|to|was|now)\s+[ES]\d{3}', bracket_content, re.IGNORECASE):
        return True
    if re.match(r'^[ES]\d{3}(\s|/|-|—)', bracket_content, re.IGNORECASE):
        return True
    if re.match(r'^[ES]\d{3}$', bracket_content, re.IGNORECASE):
        return True
    if re.match(r'^[a-z].*\s+E\d{3}', bracket_content):
        return True
    if bracket_content and bracket_content[0].islower():
        return True
    return False


def is_code_or_syntax_construct(bracket_content):
    """Skip bracketed code tokens in prose (e.g. [BULK_MODEL, ESCALATION_MODEL], [\"scripts/foo.mjs\", target])."""
    if any(char in bracket_content for char in ('"', "'", '`', ',', '=', '(', ')', '{', '}', '[', ']')):
        return True
    if '/' in bracket_content or '\\' in bracket_content:
        return True
    if re.search(r'\.[a-zA-Z0-9]+$', bracket_content):
        return True
    return False


def is_template_bracket(bracket_content):
    upper = bracket_content.upper()
    if upper in TEMPLATE_BRACKET_MARKERS:
        return True
    if upper.startswith("TEMPLATE:") or upper.startswith("PLACEHOLDER:"):
        return True
    lower = bracket_content.lower()
    template_terms = (
        "user type", "action", "benefit", "description", "initial state", "outcome",
        "name", "service", "framework", "language", "entity", "relationship", "how to verify",
        "metric", "target", "security", "approach", "what this", "how the", "how to", "topic",
        "placeholder", "xxx", "project_name", "project-id", "project_id",
    )
    if any(term in lower for term in template_terms):
        return True
    if bracket_content.isupper() and "_" in bracket_content:
        return True
    if re.match(r'^[A-Z][A-Z0-9_ ]+$', bracket_content) and " " in bracket_content:
        return True
    return False


# Pre-compute byte ranges of fenced code blocks (```...```). The placeholder
# scanner should never flag content inside fenced code blocks — that's literal
# code/JSON/config, not template placeholders.
CODE_BLOCK_RE = re.compile(r'```.*?```', re.DOTALL)
code_block_ranges = [(m.start(), m.end()) for m in CODE_BLOCK_RE.finditer(content)]


def is_in_code_block(pos):
    for start, end in code_block_ranges:
        if start <= pos < end:
            return True
    return False


# Find suspected bracketed placeholders.
# Constrain bracket content to a single line so multi-line code blocks
# (e.g. JSON config arrays, TypeScript array literals) don't get treated
# as one giant bracket-placeholder — real template placeholders are
# always single-line.
matches = re.finditer(r'\\?\[([^\]\n]+)\]', content)
for m in matches:
    full_match = m.group(0)
    bracket_content = m.group(1).strip()
    line, _ = line_at(content, m.start())

    # Skip matches inside fenced code blocks — those are literal code,
    # not template placeholders.
    if is_in_code_block(m.start()):
        continue

    if is_sha_stamp_line(line):
        continue
    if SHA_STAMP_BRACKET.search(bracket_content):
        continue

    # Ignore escaped brackets or empty/checkbox styles
    if re.match(r'^[ xXP]$', bracket_content):
        continue

    # Ignore short numeric/citation styles, e.g. [1], [^1]
    if re.match(r'^(\^?[0-9]+|[a-zA-Z0-9_-]+)$', bracket_content) and len(bracket_content) <= 5:
        if not any(p in bracket_content.lower() for p in ["id", "name", "topic", "type", "action", "benefit", "desc"]):
            continue

    # Check if followed by markdown link/ref chars: `(`, `[`, or `:`
    end_idx = m.end()
    if end_idx < len(content):
        after_text = content[end_idx:end_idx + 20].strip()
        if after_text.startswith('(') or after_text.startswith('[') or after_text.startswith(':'):
            continue

    if is_citation_context(line, bracket_content):
        continue
    if is_prose_annotation(bracket_content):
        continue
    if is_code_or_syntax_construct(bracket_content):
        continue
    if not is_template_bracket(bracket_content):
        continue

    line_num = content[:m.start()].count('\n') + 1
    errors.append(f"Line {line_num}: Unreplaced placeholder '{full_match}' found.")

# Look for generic ID patterns
generic_id_patterns = [
    (r'\bT(X{2,}|[A-Za-z0-9_]*XXX[A-Za-z0-9_]*)\b', "Generic task ID (e.g. TXXX, T000)"),
    (r'\bFR-[A-Za-z0-9_]*XXX[A-Za-z0-9_]*\b', "Generic functional requirement ID (e.g. FR-XXX)"),
    (r'\bS(X{2,}|[A-Za-z0-9_]*XXX[A-Za-z0-9_]*)\b', "Generic story ID (e.g. SXXX)"),
    (r'\bE(X{2,}|[A-Za-z0-9_]*XXX[A-Za-z0-9_]*)\b', "Generic epic ID (e.g. EXXX)"),
]

for pattern, desc in generic_id_patterns:
    for m in re.finditer(pattern, content):
        # Skip matches inside fenced code blocks — example code may contain
        # things like "FR-XXX" as a literal pattern reference, not a placeholder.
        if is_in_code_block(m.start()):
            continue
        # Also skip descriptive mentions like "FR-XXX-shaped" or
        # "(e.g. FR-XXX)" — citation context, not unreplaced placeholder.
        line, _ = line_at(content, m.start())
        if any(phrase in line.lower() for phrase in (
            "(e.g.", "(e.g ", "format", "naming", "convention", "-shaped", "-style",
            "(see", " per ", "no formal", "appears", "because", "descriptive",
            "not " + m.group(0).lower(),
            "no " + m.group(0).lower(),
        )):
            continue
        line_num = content[:m.start()].count('\n') + 1
        errors.append(f"Line {line_num}: Found unreplaced {desc} '{m.group(0)}'.")

if errors:
    print(f"\033[0;31mTEMPLATE NOT YET COMPLIANT: {file_path}\033[0m")
    for err in errors:
        print(f"  \033[1;33m- {err}\033[0m")
    print("\033[0;34mThis is NOT a block on writing files. The artifact still has unfilled template")
    print("  placeholders. Produce it by invoking the skill that fills this template (e.g.")
    print("  /story-specify, /story-validate) and replacing every [PLACEHOLDER] with real content —")
    print("  do not hand-write around the check. If you are seeing this, the producing skill likely")
    print("  did not run to completion.\033[0m")
    sys.exit(1)
sys.exit(0)
EOF
  then
    if [[ "$strict" == true ]]; then
      exit 1
    fi
  fi
fi

# Determine validation type by filename
filename=$(basename "$file_path")
case "$filename" in
  spec.md)
    validation_type="story-spec"
    ;;
  epic.md)
    validation_type="epic-spec"
    ;;
  plan.md)
    validation_type="story-plan"
    ;;
  tasks.md)
    validation_type="story-tasks"
    ;;
  epic-tech-spec.md)
    validation_type="epic-tech-spec"
    ;;
  product-contract.md)
    validation_type="product-contract"
    ;;
  evidence-contract.md)
    validation_type="evidence-contract"
    ;;
  ui-spec.md)
    validation_type="visual-assets"
    ;;
  validation-report.md|epic-validation-report.md)
    validation_type="readiness-evidence"
    ;;
  traceability-matrix.md)
    validation_type="traceability-matrix"
    ;;
  *harden-report-*.md|*harden-report.md)
    validation_type="harden-report"
    ;;
  *story-adjust-report-*.md|*story-adjust-report.md)
    validation_type="story-adjust-report"
    ;;
  *epic-adjust-report-*.md|*epic-adjust-report.md)
    validation_type="epic-adjust-report"
    ;;
  *project-adjust-report-*.md|*project-adjust-report.md)
    validation_type="project-adjust-report"
    ;;
  *)
    # Not a tracked template, skip
    exit 0
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
strict_flag=""
if [[ "$strict" == true ]]; then
  strict_flag="--strict"
fi

# Run validator
case "$validation_type" in
  story-spec)
    bash "$SCRIPT_DIR/validators/validate-story-spec.sh" $strict_flag "$file_path"
    ;;
  epic-spec)
    bash "$SCRIPT_DIR/validators/validate-epic-spec.sh" $strict_flag "$file_path"
    ;;
  story-plan)
    bash "$SCRIPT_DIR/validators/validate-story-plan.sh" $strict_flag "$file_path"
    ;;
  story-tasks)
    bash "$SCRIPT_DIR/validators/validate-story-tasks.sh" $strict_flag "$file_path"
    ;;
  epic-tech-spec)
    bash "$SCRIPT_DIR/validators/validate-epic-tech-spec.sh" $strict_flag "$file_path"
    ;;
  product-contract)
    bash "$SCRIPT_DIR/validators/validate-product-contract.sh" $strict_flag "$file_path"
    ;;
  evidence-contract)
    bash "$SCRIPT_DIR/validators/validate-evidence-contract.sh" $strict_flag "$file_path"
    ;;
  visual-assets)
    bash "$SCRIPT_DIR/validators/validate-visual-assets.sh" "$file_path" "$strict"
    ;;
  readiness-evidence)
    bash "$SCRIPT_DIR/validators/validate-readiness-evidence.sh" "$(dirname "$file_path")" "$strict"
    ;;
  traceability-matrix)
    # Default (conservation) mode here; epic-validate invokes the validator directly with --require-evidence.
    bash "$SCRIPT_DIR/validators/validate-traceability-matrix.sh" "$file_path"
    ;;
  harden-report|story-adjust-report|epic-adjust-report|project-adjust-report)
    # Passed placeholder check, no additional structural sub-validator needed
    exit 0
    ;;
esac
