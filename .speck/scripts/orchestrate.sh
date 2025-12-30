#!/usr/bin/env bash
# .speck/scripts/orchestrate.sh
#
# Speck Story Orchestrator - Core logic for finding and routing stories
#
# Environment Variables:
#   SPECS_ROOT      - Root path for specs (default: specs)
#   EPIC_PATH       - Specific epic to process (optional)
#   DRY_RUN         - Output JSON actions without executing (default: false)
#   TEST_MODE       - Add test:orchestrator label (default: false)
#   SINGLE_STORY    - Only process this one story (optional)
#   GH_TOKEN        - GitHub token for API calls
#   REPO            - Repository in owner/repo format
#
# Output:
#   In DRY_RUN mode: JSON lines with action details
#   In real mode: JSON with issue numbers created/updated

set -euo pipefail

# Defaults
SPECS_ROOT="${SPECS_ROOT:-specs}"
DRY_RUN="${DRY_RUN:-false}"
TEST_MODE="${TEST_MODE:-false}"
SINGLE_STORY="${SINGLE_STORY:-}"
EPIC_PATH="${EPIC_PATH:-}"
REPO="${REPO:-}"

# Output an action (dry-run outputs JSON, real mode executes)
output_action() {
  local action="$1"
  local story="$2"
  local phase="$3"
  local cmd="$4"
  local blocked="$5"
  local epic_id="$6"
  local title="$7"
  local extra="${8:-}"
  
  local json
  json=$(jq -n \
    --arg action "$action" \
    --arg story "$story" \
    --arg phase "$phase" \
    --arg cmd "$cmd" \
    --argjson blocked "$blocked" \
    --arg epic_id "$epic_id" \
    --arg title "$title" \
    --arg extra "$extra" \
    '{action: $action, story: $story, phase: $phase, cmd: $cmd, blocked: $blocked, epic_id: $epic_id, title: $title, extra: $extra}')
  
  if [ "$DRY_RUN" = "true" ]; then
    echo "$json"
  fi
}

# Determine story phase based on existing files
detect_phase() {
  local story_dir="$1"
  local story_id="$2"
  
  local phase="unspecced"
  local cmd="story-specify"
  
  if [ -d "$story_dir" ]; then
    if [ -f "$story_dir/validation-report.md" ]; then
      if grep -q "Status.*PASS" "$story_dir/validation-report.md" 2>/dev/null; then
        phase="validated"
        cmd=""
      else
        phase="implemented"
        cmd="story-validate"
      fi
    elif [ -f "$story_dir/tasks.md" ]; then
      # Check implementation status from YAML frontmatter
      local impl_status
      impl_status=$(sed -n '/^---$/,/^---$/p' "$story_dir/tasks.md" 2>/dev/null | grep "^status:" | sed 's/status://' | tr -d ' ' || echo "pending")
      
      if [ "$impl_status" = "completed" ]; then
        # Implementation marked complete, run validation
        phase="implemented"
        cmd="story-validate"
      elif [ "$impl_status" = "in_progress" ]; then
        # Implementation in progress, continue it
        phase="implementing"
        cmd="story-implement"
      elif [ -f "$story_dir/analysis-report.md" ]; then
        # Analysis done, ready to implement
        phase="analyzed"
        cmd="story-implement"
      else
        # Tasks exist but not analyzed yet
        phase="tasked"
        cmd="story-analyze"
      fi
    elif [ -f "$story_dir/plan.md" ]; then
      phase="planned"
      cmd="story-tasks"
    elif [ -f "$story_dir/spec.md" ]; then
      if grep -q "## Acceptance Criteria" "$story_dir/spec.md" 2>/dev/null; then
        phase="clarified"
        cmd="story-plan"
      else
        phase="specified"
        cmd="story-clarify"
      fi
    fi
  fi
  
  echo "$phase|$cmd"
}

# Check if story is blocked by dependencies
check_blocked() {
  local story_dir="$1"
  local specs_root="$2"
  
  local blocked="false"
  local blocking=""
  local deps=""
  
  # Priority 1: Check spec.md YAML frontmatter (primary source of truth)
  if [ -f "$story_dir/spec.md" ]; then
    deps=$(sed -n '/^---$/,/^---$/p' "$story_dir/spec.md" 2>/dev/null | grep "depends_on:" | sed 's/depends_on://' | tr -d '[],' || true)
  fi
  
  # Priority 2: Check spec-draft.md (early in the flow, before story-specify)
  if [ -z "$deps" ] && [ -f "$story_dir/spec-draft.md" ]; then
    deps=$(sed -n '/^---$/,/^---$/p' "$story_dir/spec-draft.md" 2>/dev/null | grep "depends_on:" | sed 's/depends_on://' | tr -d '[],' || true)
  fi
  
  # Priority 3: Fall back to tasks.md (legacy/backwards compatibility)
  if [ -z "$deps" ] && [ -f "$story_dir/tasks.md" ]; then
    deps=$(sed -n '/^---$/,/^---$/p' "$story_dir/tasks.md" 2>/dev/null | grep "depends_on:" | sed 's/depends_on://' | tr -d '[],' || true)
  fi
  
  # Check each dependency
  for dep in $deps; do
    dep=$(echo "$dep" | tr -d ' "')
    [ -z "$dep" ] && continue
    
    local dep_dir
    dep_dir=$(find "$specs_root" -type d -name "*$dep*" 2>/dev/null | head -1)
    
    if [ -z "$dep_dir" ] || [ ! -f "$dep_dir/validation-report.md" ]; then
      blocked="true"
      blocking="$blocking $dep"
    elif ! grep -q "Status.*PASS" "$dep_dir/validation-report.md" 2>/dev/null; then
      blocked="true"
      blocking="$blocking $dep"
    fi
  done
  
  echo "$blocked|$blocking"
}

# Get story title from spec.md or directory name
get_story_title() {
  local story_dir="$1"
  local story_id="$2"
  
  local title=""
  
  if [ -f "$story_dir/spec.md" ]; then
    title=$(grep -m1 "^# " "$story_dir/spec.md" 2>/dev/null | sed 's/^# //' || echo "")
  fi
  
  if [ -z "$title" ]; then
    if [[ "$story_id" =~ ^[Ss][0-9]{3}-(.+)$ ]]; then
      title=$(echo "${BASH_REMATCH[1]}" | tr '-' ' ')
    else
      title="(needs spec)"
    fi
  fi
  
  echo "$title"
}

# Build issue body
build_issue_body() {
  local epic_id="$1"
  local story_id="$2"
  local title="$3"
  local phase="$4"
  local cmd="$5"
  local epic_context="$6"
  local blocked="$7"
  local blocking="$8"
  local template_file="$9"
  
  {
    echo "## Story Details"
    echo ""
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| **Epic** | $epic_id |"
    echo "| **Story** | $story_id |"
    echo "| **Title** | $title |"
    echo "| **Phase** | $phase |"
    echo "| **Start Command** | \`$cmd\` |"
    echo ""
    echo "### Epic Context"
    echo ""
    echo "$epic_context"
    echo ""
    
    if [ -f "$template_file" ]; then
      cat "$template_file"
    fi
    
    if [ "$blocked" = "true" ]; then
      echo ""
      echo "---"
      echo "⚠️ **BLOCKED** - Waiting for validated:$blocking"
      echo ""
      echo "Do not start until dependencies are validated (have PASS in validation-report.md)."
    fi
  }
}

# Main orchestration logic
main() {
  local epics
  
  if [ -n "$EPIC_PATH" ]; then
    epics="$EPIC_PATH"
  else
    epics=$(find "$SPECS_ROOT" -name "epic-breakdown.md" -exec dirname {} \; 2>/dev/null | sort -t/ -k6 -V || true)
  fi
  
  # Extract template instructions if available
  local template_file="/tmp/template_instructions.md"
  local template_src=".github/ISSUE_TEMPLATE/speck-story.yml"
  if [ -f "$template_src" ]; then
    # Extract template instructions (portable: avoid BSD head -n -1)
    sed -n '/value: |/,/^[^ ]/p' "$template_src" 2>/dev/null | \
      tail -n +2 | \
      sed '$d' | \
      sed 's/^        //' > "$template_file" 2>/dev/null || true
  else
    echo "See AGENTS.md for the Speck methodology." > "$template_file"
  fi
  
  for epic_dir in $epics; do
    [ -z "$epic_dir" ] && continue
    [ ! -d "$epic_dir" ] && continue
    
    local epic_id
    epic_id=$(basename "$epic_dir")
    
    local epic_context
    epic_context=$(sed -n '/^## Overview/,/^##/p' "$epic_dir/epic.md" 2>/dev/null | head -10 | tail -9 || echo "See epic.md for details")
    
    # Get planned stories from epic-breakdown.md
    local planned_stories=""
    if [ -f "$epic_dir/epic-breakdown.md" ]; then
      planned_stories=$(grep -oE '(S[0-9]{3}|story-[0-9]{3})' "$epic_dir/epic-breakdown.md" 2>/dev/null | sort -u | tr '\n' ' ' || true)
    fi
    
    local stories_dir="$epic_dir/stories"
    [ ! -d "$stories_dir" ] && mkdir -p "$stories_dir" 2>/dev/null
    
    # Build list of all stories (planned + existing directories)
    local all_stories=""
    
    for story_id in $planned_stories; do
      if [[ "$story_id" =~ ^S([0-9]{3})$ ]]; then
        local full_dir
        full_dir=$(ls -d "$stories_dir/$story_id"-* 2>/dev/null | head -1 || echo "")
        if [ -n "$full_dir" ]; then
          story_id=$(basename "$full_dir")
        fi
      fi
      all_stories="$all_stories $story_id"
    done
    
    for story_path in $(ls -d "$stories_dir"/*/ 2>/dev/null || true); do
      all_stories="$all_stories $(basename "$story_path")"
    done
    
    all_stories=$(echo "$all_stories" | tr ' ' '\n' | grep -v '^$' | sort -u -V | tr '\n' ' ')
    
    for story_id in $all_stories; do
      [ -z "$story_id" ] && continue
      
      # Filter to single story if specified
      if [ -n "$SINGLE_STORY" ]; then
        if [[ "$story_id" != *"$SINGLE_STORY"* ]]; then
          continue
        fi
      fi
      
      local story_dir="$stories_dir/$story_id"
      
      # Detect phase
      local phase_result
      phase_result=$(detect_phase "$story_dir" "$story_id")
      local phase="${phase_result%%|*}"
      local cmd="${phase_result##*|}"
      
      # Skip validated stories
      if [ "$phase" = "validated" ]; then
        output_action "skip" "$story_id" "$phase" "" "false" "$epic_id" "" "validated"
        continue
      fi
      
      # Check dependencies
      local blocked_result
      blocked_result=$(check_blocked "$story_dir" "$SPECS_ROOT")
      local blocked="${blocked_result%%|*}"
      local blocking="${blocked_result##*|}"
      
      # Get title
      local title
      title=$(get_story_title "$story_dir" "$story_id")
      
      if [ "$DRY_RUN" = "true" ]; then
        output_action "create" "$story_id" "$phase" "$cmd" "$blocked" "$epic_id" "$title" "$blocking"
      else
        # Check for existing issue
        local existing_issue=""
        if [ -n "$REPO" ]; then
          existing_issue=$(gh issue list --repo "$REPO" --label "speck:story" --search "in:title $story_id" --state open --json number,labels --jq '.[0]' 2>/dev/null || echo "")
        fi
        
        # Skip if in progress
        if [ -n "$existing_issue" ] && [ "$existing_issue" != "null" ]; then
          local is_in_progress
          is_in_progress=$(echo "$existing_issue" | jq -r '.labels | map(.name) | any(. == "speck:in-progress")')
          if [ "$is_in_progress" = "true" ]; then
            continue
          fi
        fi
        
        # Build issue body
        local body
        body=$(build_issue_body "$epic_id" "$story_id" "$title" "$phase" "$cmd" "$epic_context" "$blocked" "$blocking" "$template_file")
        echo "$body" > /tmp/issue_body.md
        
        # Set labels
        local labels="speck:story,automated"
        if [ "$TEST_MODE" = "true" ]; then
          labels="$labels,test:e2e"
        fi
        if [ "$blocked" = "true" ]; then
          labels="$labels,speck:blocked"
        else
          labels="$labels,speck:queued"
        fi
        
        # Create or update issue
        if [ -n "$existing_issue" ] && [ "$existing_issue" != "null" ]; then
          local issue_num
          issue_num=$(echo "$existing_issue" | jq -r '.number')
          gh issue edit "$issue_num" --repo "$REPO" --body-file /tmp/issue_body.md
          if [ "$blocked" = "false" ]; then
            gh issue edit "$issue_num" --repo "$REPO" --remove-label "speck:blocked" --add-label "speck:queued" 2>/dev/null || true
          fi
          echo "{\"action\":\"update\",\"issue_number\":$issue_num,\"story\":\"$story_id\"}"
        else
          local result
          result=$(gh issue create \
            --repo "$REPO" \
            --title "[$epic_id] $story_id: $title" \
            --body-file /tmp/issue_body.md \
            --label "$labels" 2>&1)
          local issue_num
          issue_num=$(echo "$result" | grep -oE '[0-9]+$' || echo "0")
          echo "{\"action\":\"create\",\"issue_number\":$issue_num,\"story\":\"$story_id\"}"
        fi
      fi
    done
  done
}

# Run main
main
