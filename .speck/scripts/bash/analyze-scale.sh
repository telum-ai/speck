#!/usr/bin/env bash

set -e

# Scale Analysis Script - Produces a deterministic routing suggestion plus inspectable signals
# 
# The suggestion is a starting point, not a hidden classifier. The agent reports the
# signals, applies conversation context, and honors explicit user scope overrides.
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

# Deterministic scope suggestion. Explicit markers win; otherwise use bounded semantic
# phrases before falling back to request length. This deliberately chooses workflow scope,
# never play level.
LOWER_DESCRIPTION="$(printf '%s' "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')"
COMPLEXITY=2
SUGGESTED_LEVEL="epic"
CONFIDENCE="low"
SIGNAL="length_fallback"

if printf '%s' "$LOWER_DESCRIPTION" | grep -Eq '(^|[^a-z])(project:|project scope|whole project)([^a-z]|$)'; then
    COMPLEXITY=3 SUGGESTED_LEVEL="project" CONFIDENCE="high" SIGNAL="explicit_project_scope"
elif printf '%s' "$LOWER_DESCRIPTION" | grep -Eq '(^|[^a-z])(epic:|epic scope)([^a-z]|$)'; then
    COMPLEXITY=2 SUGGESTED_LEVEL="epic" CONFIDENCE="high" SIGNAL="explicit_epic_scope"
elif printf '%s' "$LOWER_DESCRIPTION" | grep -Eq '(^|[^a-z])(story:|story scope)([^a-z]|$)'; then
    COMPLEXITY=1 SUGGESTED_LEVEL="story" CONFIDENCE="high" SIGNAL="explicit_story_scope"
elif printf '%s' "$LOWER_DESCRIPTION" | grep -Eq '(full|entire|whole|new)[ -](product|platform|system)|from scratch|multi-team|multi-quarter|new business|build an? [a-z0-9 -]*(app|application|platform|product)'; then
    COMPLEXITY=3 SUGGESTED_LEVEL="project" CONFIDENCE="medium" SIGNAL="project_scope_phrase"
elif printf '%s' "$LOWER_DESCRIPTION" | grep -Eq 'feature|capability|authentication|auth system|checkout|billing|payments|shopping cart|onboarding flow|search system'; then
    COMPLEXITY=2 SUGGESTED_LEVEL="epic" CONFIDENCE="medium" SIGNAL="capability_phrase"
# Atomic keywords run LAST among the phrase branches (after project- and capability-scope
# phrases) and only on a request that is itself short: a keyword like "color" or "rename"
# appearing once inside a long, multi-clause request describes one clause, not the whole
# ask, and must not outrank a bigger signal or silently stand in for one that never fired.
# Word-bounded like the explicit-marker branches above, so "colors" and "namespacing" no
# longer trip "color" and "spacing" as bare substrings.
elif [ "$WORD_COUNT" -le 12 ] && printf '%s' "$LOWER_DESCRIPTION" | grep -Eq '(^|[^a-z])(typo|copy change|rename|colour|color|spacing|single field|one field|one form|small change|minor change|one validated)([^a-z]|$)'; then
    COMPLEXITY=1 SUGGESTED_LEVEL="story" CONFIDENCE="medium" SIGNAL="atomic_change_phrase"
elif [ "$WORD_COUNT" -le 12 ]; then
    COMPLEXITY=1 SUGGESTED_LEVEL="story" CONFIDENCE="low" SIGNAL="short_request_fallback"
elif [ "$WORD_COUNT" -gt 35 ]; then
    COMPLEXITY=3 SUGGESTED_LEVEL="project" CONFIDENCE="low" SIGNAL="large_request_fallback"
fi

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
    python3 - "$DESCRIPTION" "$WORD_COUNT" "$CHAR_COUNT" "$CONJUNCTION_COUNT" \
      "$QUESTION_MARKS" "$HAS_NUMBERS" "$COMPLEXITY" "$SUGGESTED_LEVEL" \
      "$CONFIDENCE" "$SIGNAL" "$AVAILABLE_RECIPES" <<'PY'
import json, sys

(description, words, chars, conjunctions, questions, has_numbers, complexity,
 level, confidence, signal, recipes) = sys.argv[1:]
print(json.dumps({
    "input": description,
    "metrics": {
        "word_count": int(words),
        "char_count": int(chars),
        "conjunction_count": int(conjunctions),
        "question_marks": int(questions),
        "has_numbers": has_numbers == "true",
    },
    "routing": {
        "complexity": int(complexity),
        "suggested_level": level,
        "confidence": confidence,
        "signal": signal,
    },
    "available_recipes": [item for item in recipes.split(",") if item],
    "note": "Complexity chooses story, epic, or project scope; it never chooses play level.",
}, indent=2))
PY
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
    echo "Suggested Complexity: $COMPLEXITY"
    echo "Suggested Level: $SUGGESTED_LEVEL"
    echo "Confidence: $CONFIDENCE ($SIGNAL)"
    echo ""
    echo "Note: Apply conversation context and explicit user scope overrides; complexity never selects play level."
fi
