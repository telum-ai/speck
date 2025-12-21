#!/usr/bin/env bash

set -e

# Scale Analysis Script - Provides basic metrics for LLM to analyze
# 
# This script provides METRICS ONLY. The LLM uses its judgment to:
# - Detect brainstorm needs (vague/exploratory input)
# - Match to recipes (based on tech stack keywords)
# - Determine appropriate Speck level (story/epic/project)
#
# Levels:
# 0 - Single atomic change
# 1 - Small feature (1-10 stories, 1 epic)
# 2 - Moderate feature (5-15 stories, 1-2 epics) 
# 3 - Major feature (12-40 stories, 2-5 epics)
# 4 - Full platform (40+ stories, 5+ epics)

JSON_MODE=false
DESCRIPTION=""
ARGS=()

for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
        --help|-h) 
            echo "Usage: $0 [--json] <description>"
            echo "Provides metrics for LLM to analyze and suggest appropriate Speck workflow level"
            exit 0 
            ;;
        *) ARGS+=("$arg") ;;
    esac
done

DESCRIPTION="${ARGS[*]}"
if [ -z "$DESCRIPTION" ]; then
    echo "Usage: $0 [--json] <description>" >&2
    exit 1
fi

# Basic metrics for LLM analysis
WORD_COUNT=$(echo "$DESCRIPTION" | wc -w | tr -d ' ')
CHAR_COUNT=$(echo "$DESCRIPTION" | wc -c | tr -d ' ')

# Count potential complexity indicators (LLM interprets these)
CONJUNCTION_COUNT=$(echo "$DESCRIPTION" | grep -o -i -E '\b(and|with|plus|also|including)\b' | wc -l | tr -d ' ')
QUESTION_MARKS=$(echo "$DESCRIPTION" | grep -o '?' | wc -l | tr -d ' ')
HAS_NUMBERS=$(echo "$DESCRIPTION" | grep -q '[0-9]' && echo "true" || echo "false")

# List available recipes (LLM will match based on content)
# NOTE: Resolve paths from the script location so this works from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RECIPES_DIR="$SPECK_ROOT/recipes"
AVAILABLE_RECIPES=""
if [ -d "$RECIPES_DIR" ]; then
    AVAILABLE_RECIPES=$(find "$RECIPES_DIR" -name "recipe.yaml" -exec dirname {} \; | xargs -I {} basename {} 2>/dev/null | tr '\n' ',' | sed 's/,$//')
fi

# Output results
if [ "$JSON_MODE" = true ]; then
    cat <<EOF
{
    "input": $(echo "$DESCRIPTION" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'),
    "metrics": {
        "word_count": $WORD_COUNT,
        "char_count": $CHAR_COUNT,
        "conjunction_count": $CONJUNCTION_COUNT,
        "question_marks": $QUESTION_MARKS,
        "has_numbers": $HAS_NUMBERS
    },
    "available_recipes": "$AVAILABLE_RECIPES",
    "note": "LLM should analyze input to determine: needs_brainstorm, recipe_match, suggested_level, and workflow_type"
}
EOF
else
    echo "Scale Analysis Metrics"
    echo "====================="
    echo ""
    echo "Input: \"$DESCRIPTION\""
    echo ""
    echo "Metrics:"
    echo "- Word count: $WORD_COUNT"
    echo "- Character count: $CHAR_COUNT"
    echo "- Conjunctions (and/with/plus/also/including): $CONJUNCTION_COUNT"
    echo "- Question marks: $QUESTION_MARKS"
    echo "- Contains numbers: $HAS_NUMBERS"
    echo ""
    echo "Available Recipes: $AVAILABLE_RECIPES"
    echo ""
    echo "Note: LLM analyzes input to determine workflow level, brainstorm needs, and recipe matches."
fi
