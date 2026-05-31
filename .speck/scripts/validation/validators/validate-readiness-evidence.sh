#!/usr/bin/env bash

# Speck Readiness Evidence Validator
# Programmatically enforces that any claims of UX-RC or higher are backed by real, verifiable evidence files.
# Checks that if readiness_state_verified or readiness_state_claimed is UX-RC, COMMERCIAL-RC, or SHIP-RC,
# there must be at least one asset file under specs/projects/PROJECT_ID/larp-recordings/ or STORY_DIR/larp-recordings/
# containing screenshots, AX trees, or videos.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_DIR="${1:-}"
strict="${2:-false}"

if [[ -z "$TARGET_DIR" ]]; then
  echo -e "${RED}Error: Please specify the story/epic directory path.${NC}"
  exit 1
fi

val_report=""
if [[ -f "${TARGET_DIR}/validation-report.md" ]]; then
  val_report="${TARGET_DIR}/validation-report.md"
elif [[ -f "${TARGET_DIR}/epic-validation-report.md" ]]; then
  val_report="${TARGET_DIR}/epic-validation-report.md"
fi

if [[ -z "$val_report" || ! -f "$val_report" ]]; then
  # No validation report exists yet, so nothing to enforce
  exit 0
fi

echo -e "🏁 Validating Readiness-State Evidence for $(basename "$TARGET_DIR")...\n"

# Parse claimed or verified readiness state
claimed_state=""
if grep -q -i "readiness_state_verified:" "$val_report"; then
  claimed_state=$(grep -i "readiness_state_verified:" "$val_report" | head -n 1 | sed -E 's/.*:[[:space:]]*["'\'']?([^"'\''[:space:]]+)["'\'']?.*/\1/' || true)
elif grep -q -i "readiness_state_claimed:" "$val_report"; then
  claimed_state=$(grep -i "readiness_state_claimed:" "$val_report" | head -n 1 | sed -E 's/.*:[[:space:]]*["'\'']?([^"'\''[:space:]]+)["'\'']?.*/\1/' || true)
fi

# Standardise to uppercase
claimed_state=$(echo "$claimed_state" | tr '[:lower:]' '[:upper:]')

if [[ -z "$claimed_state" || "$claimed_state" == "NO-SHIP" || "$claimed_state" == "IMPL-GREEN" ]]; then
  echo -e "ℹ️  State is ${claimed_state:-NO-SHIP} (or lower). No visual/runtime evidence files are required."
  exit 0
fi

# Detect Project Archetype
project_archetype="consumer_product" # Default fallback
project_json=""
# Find project.json by climbing up
dir="$TARGET_DIR"
while [[ "$dir" != "/" && -n "$dir" ]]; do
  if [[ -f "${dir}/project.json" ]]; then
    project_json="${dir}/project.json"
    break
  elif [[ -f "${dir}/.speck/project.json" ]]; then
    project_json="${dir}/.speck/project.json"
    break
  fi
  dir=$(dirname "$dir")
done

if [[ -f "$project_json" ]]; then
  archetype=$(grep -o '"project_archetype"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || true)
  if [[ -n "$archetype" ]]; then
    project_archetype="$archetype"
  fi
fi

# If project_archetype is infra_service or backend_api, larp evidence is not required (but integration test logs are required instead, we can check for those if we want)
if [[ "$project_archetype" == "infra_service" || "$project_archetype" == "backend_api" ]]; then
  echo -e "ℹ️  Project Archetype is ${project_archetype}. LARP recordings are bypassed."
  # Optionally check if there is an integration test log in the validation folder
  exit 0
fi

echo -e "👉 Claimed Readiness State: ${BLUE}${claimed_state}${NC}"

# Find larp-recordings directories
recordings_dirs=()

# 1. Look in STORY_DIR/larp-recordings/
if [[ -d "${TARGET_DIR}/larp-recordings" ]]; then
  recordings_dirs+=("${TARGET_DIR}/larp-recordings")
fi

# 2. Look in specs/projects/PROJECT_ID/larp-recordings/
# Find the project directory
project_dir=""
dir="$TARGET_DIR"
while [[ "$dir" != "/" && -n "$dir" ]]; do
  if [[ -f "${dir}/project.md" ]]; then
    project_dir="$dir"
    break
  fi
  dir=$(dirname "$dir")
done

if [[ -n "$project_dir" && -d "${project_dir}/larp-recordings" ]]; then
  recordings_dirs+=("${project_dir}/larp-recordings")
fi

# Count files under the recordings directories matching png, json, mp4, etc.
evidence_count=0
for d in "${recordings_dirs[@]}"; do
  # Count files ending with png, json, or mp4
  count=$(find "$d" -type f \( -name "*.png" -o -name "*.json" -o -name "*.mp4" -o -name "*.mov" \) 2>/dev/null | wc -l | tr -d ' ' || echo 0)
  evidence_count=$((evidence_count + count))
done

if [[ $evidence_count -eq 0 ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}EVIDENCE ERROR: Claim of state '${claimed_state}' rejected.${NC}"
  echo -e "\n${YELLOW}Enforcing Always-On Discipline:${NC}"
  echo -e "  You claimed a high readiness state (${claimed_state}) but NO verifiable runtime evidence"
  echo -e "  files (screenshots, accessibility trees, or video captures) were found under"
  echo -e "  'larp-recordings/'."
  echo -e "\n${BLUE}To resolve this:${NC}"
  echo -e "  1. Run ${GREEN}npx speck larp-play${NC} or manual walkthroughs to capture the visual evidence."
  echo -e "  2. Ensure captured screenshots/AX trees are saved in 'larp-recordings/'."
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  if [[ "$strict" == "true" ]]; then
    exit 1
  fi
else
  echo -e "   ${GREEN}✅ Verified: Found ${evidence_count} evidence files backing state claim '${claimed_state}'!${NC}"
  
  # Run scorecard validation using python
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 - "$val_report" "$strict" << 'EOF'
import sys
import re

val_report = sys.argv[1]
strict = sys.argv[2].lower() == "true"

with open(val_report, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Parse JTBD Scorecard table
# Look for rows like: | **Functional** | 10 | path | distinct note | cap |
scorecard_rows = []
for line in content.split("\n"):
    if re.search(r'\|\s*\*\*(Functional|Emotional|Social|Trust|Commercial)\*\*\s*\|', line):
        parts = [p.strip() for p in line.split("|")[1:-1]]
        if len(parts) >= 4:
            scorecard_rows.append({
                "dimension": parts[0].replace("**", ""),
                "score": parts[1],
                "evidence": parts[2],
                "note": parts[3],
                "cap": parts[4] if len(parts) > 4 else ""
            })

if scorecard_rows:
    print("📋 Validating JTBD Quality Scorecard...")
    
    # Check for identical skeptical notes
    notes = {}
    for row in scorecard_rows:
        try:
            score = int(row["score"])
        except ValueError:
            score = 0
            
        note = row["note"].strip()
        # Skip placeholders
        if note and not note.startswith("[") and not note.endswith("]"):
            if score >= 9:
                if note in notes:
                    notes[note].append(row["dimension"])
                else:
                    notes[note] = [row["dimension"]]
                    
    reused_notes_found = False
    for note, dimensions in notes.items():
        if len(dimensions) > 1:
            print(f"\033[0;31mSCORECARD ERROR: Skeptical note reused across dimensions: {', '.join(dimensions)}\033[0m")
            print(f"  Note: \"{note}\"")
            print("  Fix: Each dimension >= 9 requires a DISTINCT, non-reused skeptical note.")
            reused_notes_found = True
            
    if reused_notes_found:
        if strict:
            sys.exit(1)
        
    # Check for "all 10s" / "perfect" inflation
    all_tens = len(scorecard_rows) > 0 and all(row["score"] == "10" for row in scorecard_rows)
    if all_tens:
        # Check if there are active findings
        has_active_findings = False
        findings_section = re.search(r'## 🛑 Blocking Issues[\s\S]*?(##|$)', content)
        if findings_section:
            findings_text = findings_section.group(0)
            rows = [line.strip() for line in findings_text.split("\n") if line.strip().startswith("|")]
            for r in rows:
                if "audit-report.md" in r and not "-" in r:
                    has_active_findings = True
                    break
                    
        if has_active_findings:
            print("\033[0;31mSCORECARD ERROR: Claimed 'all 10s' but active findings are present in the report!\033[0m")
            print("  Fix: Grade cannot be 10 with active P0/P1/P2 findings.")
            if strict:
                sys.exit(1)
EOF
    then
      exit 1
    fi
  fi

  exit 0
fi
