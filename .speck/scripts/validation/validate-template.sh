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

# Computed early (not just before the routing switch below) because STEP 1
# needs it too: the sanctioned-markers allowlist lives in ../lib, and STEP 1
# passes its path into the Python scanner as argv[2].
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANCTIONED_MARKERS_FILE="$SCRIPT_DIR/../lib/sanctioned-markers.txt"

# === STEP 1: Run Python-based Template Placeholder Scanner ===
if command -v python3 >/dev/null 2>&1; then
  if ! python3 - "$file_path" "$SANCTIONED_MARKERS_FILE" << 'EOF'
import sys
import re

file_path = sys.argv[1]
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

errors = []

# SANCTIONED_MARKERS — bracket tokens Speck's OWN templates mandate agents to
# emit as a FEATURE (e.g. project-state-template.md instructs agents to write
# [NEEDS USER REVIEW] and then greps for it to build the "Sections Awaiting
# User Review" section). Rejecting a marker Speck itself mandates makes
# Speck's own generated output uncommittable under strict validation (#92).
# Read from the SAME file the marker-emitting templates document, sourced by
# path (argv[2]) rather than duplicated here, so whatever emits a marker and
# whatever rejects one cannot drift apart. Exact string match only (a
# sanctioned marker is checked before, and short-circuits, the generic
# all-caps heuristic below).
SANCTIONED_MARKERS = set()
if len(sys.argv) > 2:
    try:
        with open(sys.argv[2], "r", encoding="utf-8") as mf:
            for raw_line in mf:
                raw_line = raw_line.strip()
                if not raw_line or raw_line.startswith("#"):
                    continue
                if raw_line.startswith("[") and raw_line.endswith("]"):
                    SANCTIONED_MARKERS.add(raw_line[1:-1])
    except OSError:
        pass

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
    # This validator's OWN remediation message ("...and replacing every
    # [PLACEHOLDER] with real content...", printed below on failure) has
    # itself been observed quoted back inside a downstream analysis-report
    # explaining what happened — which then re-triggered this same scanner
    # on the quote (#92). The clause is specific enough that it doesn't
    # collide with a genuine unfilled [PLACEHOLDER] line, which never reads
    # this way.
    "replacing every",
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


def is_legend_definition(line, local_start, local_end, bracket_content):
    """A legend/key line DEFINES an all-caps convention tag rather than
    containing a live, unfilled instance of it, e.g. a provenance legend:
        **[FROM RESEARCH]** — content sourced from due-diligence research.
    (#92: this over-match is real — the ALL-CAPS-with-space fallback above
    convicts it exactly like a genuine unreplaced placeholder.)

    Scoped deliberately tight, because a broad version of this rule recreates
    the #89 trap in a new spot: turning a real false positive into a false
    negative. Three guards, all required:
      (a) bracket_content is ALL-CAPS. Every glossary/legend tag Speck's own
          templates use — [NEEDS USER REVIEW] among them — takes this shape;
          no genuine unfilled placeholder in any current Speck template does
          (verified: mixed-case placeholders like [Option A name] and
          [Item] fall through this guard untouched).
      (b) the bracket sits at the very start of the line once leading
          bullet/numbering and bold decoration are stripped — a definition
          names its subject first. A numbered list item ("1. **[Option A
          name]** — ...", project-decisions-log-template.md) or a preceding
          sibling bracket ("- [ ] [Consumer FELT-GOOD] — ...",
          project-v8-reprove-report-template.md) both leave a non-empty
          remainder here and are correctly NOT treated as a legend.
      (c) it is followed specifically by a TYPOGRAPHIC dash (— or –) — never
          a plain hyphen and never a colon. Colon is the live separator in
          genuine "[LABEL]: [value]" template rows (feedback/template.md's
          `- **[SIGNAL_ID]**: [description]`) — accepting colon here would
          silently blind exactly that kind of real unfilled field.
    """
    if not bracket_content.isupper():
        return False
    prefix = line[:local_start]
    suffix = line[local_end:]
    prefix_stripped = re.sub(r'^[\s]*[-*]?\s*\*{0,2}', '', prefix).strip()
    if prefix_stripped != '':
        return False
    suffix_stripped = re.sub(r'^\*{0,2}', '', suffix).lstrip()
    return bool(re.match(r'^[—–]', suffix_stripped))


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
    line, line_start = line_at(content, m.start())

    # Skip matches inside fenced code blocks — those are literal code,
    # not template placeholders.
    if is_in_code_block(m.start()):
        continue

    # SANCTIONED MARKERS short-circuit BEFORE every other heuristic (#92) —
    # see SANCTIONED_MARKERS above for why this is a shared-list allowlist
    # rather than a hardcoded exception.
    if bracket_content in SANCTIONED_MARKERS:
        continue

    # Legend/glossary definition of an ALL-CAPS tag, not a live unfilled
    # instance of it (#92) — see is_legend_definition for the tight scoping.
    if is_legend_definition(line, m.start() - line_start, m.end() - line_start, bracket_content):
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
  *seam-contract-*.md|*seam-contract.md)
    validation_type="seam-contract"
    ;;
  *)
    # Not a tracked template, skip
    exit 0
    ;;
esac

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
    # BOTH run, and the exit codes are COMBINED. Under `set -e` a sequential pair means the second
    # check is unreachable whenever the first aborts: a report claiming SHIP-RC with no LARP
    # evidence printed only the readiness failure, and its MISSING Mutation Record section was
    # never reported at all — the section-level defect hid behind an unrelated one, and surfaced
    # only once the claim was lowered to IMPL-GREEN. A validator you cannot reach is not a gate.
    rc=0
    bash "$SCRIPT_DIR/validators/validate-readiness-evidence.sh" "$(dirname "$file_path")" "$strict" || rc=1
    # The §🧬 Mutation Record lives in the SAME primitive as the harden report's Mutation-Proof
    # line, so it is enforced by the SAME script rather than by a second copy that drifts. Binds
    # only to v10-vintage reports (see validate-harden-report.sh) — every report already on disk
    # is exempt, which is why this needs no data migration.
    bash "$SCRIPT_DIR/validators/validate-harden-report.sh" --mutation-record-only $strict_flag "$file_path" || rc=1
    exit $rc
    ;;
  traceability-matrix)
    # Default (conservation) mode here; epic-validate invokes the validator directly with --require-evidence.
    bash "$SCRIPT_DIR/validators/validate-traceability-matrix.sh" "$file_path"
    ;;
  harden-report)
    # WAS: exempt from ALL structural validation ("passed placeholder check, no additional
    # structural sub-validator needed"). That exemption made every section /harden's own template
    # declares unenforceable by construction — an agent could delete §2b and the Mutation-Proof
    # line and every gate stayed green. This is the chokepoint the mutation-record work needed.
    bash "$SCRIPT_DIR/validators/validate-harden-report.sh" $strict_flag "$file_path"
    ;;
  story-adjust-report|epic-adjust-report|project-adjust-report|seam-contract)
    # Passed placeholder check, no additional structural sub-validator needed
    exit 0
    ;;
esac
