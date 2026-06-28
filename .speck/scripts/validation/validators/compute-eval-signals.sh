#!/usr/bin/env bash
# compute-eval-signals.sh — Git/VCS as an evaluation engine (Speck v7.17).
#
# Analyzes the git commit history of the repository to calculate agent metric signals:
#   - Agent vs Human commit distribution
#   - Agent commit override/reversion rate (Agent commits reverted or corrected by subsequent human edits)
#   - Agent code survival rate (proportion of agent commits that remain intact)
#
# Usage:
#   bash compute-eval-signals.sh [--limit <count>] [--threshold <percent>] [--strict] [REPO_ROOT]
#
# Exit codes:
#   0 = evaluation signals pass or informational mode
#   1 = evaluation signals show drift (high override rate under --strict)
#   2 = execution error
#
# Portable bash 3.2.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

LIMIT=100
THRESHOLD=20
STRICT=false
REPO_ROOT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --limit requires an integer argument." >&2
        exit 2
      fi
      LIMIT="$2"
      shift 2
      ;;
    --threshold)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --threshold requires a percentage argument (0-100)." >&2
        exit 2
      fi
      THRESHOLD="$2"
      shift 2
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    -*)
      echo "ERROR: Unknown option $1" >&2
      exit 2
      ;;
    *)
      REPO_ROOT="$1"
      shift
      ;;
  esac
done

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "ERROR: Directory does not exist: $REPO_ROOT" >&2
  exit 2
fi

cd "$REPO_ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: $REPO_ROOT is not a git repository." >&2
  exit 2
fi

# Ensure git log is not empty
if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "INFO: Git history is empty. No commits to evaluate."
  echo "EVAL_SIGNAL_DRIFT_SUMMARY P2=0 override_rate=0"
  exit 0
fi

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}🔍  Speck VCS-as-Eval Signal Computer (v7.17.0)${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Repository Root : $REPO_ROOT"
echo -e "Commit Limit    : $LIMIT"
echo -e "Failure Limit   : $THRESHOLD%"
echo -e "Strict Mode     : $STRICT"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

# Read commits and classify
# Format: hash|author_name|author_email|subject
commits_file=$(mktemp)
trap 'rm -f "$commits_file"' EXIT

git log -n "$LIMIT" --format="%h|%an|%ae|%s" > "$commits_file"

total_commits=0
agent_commits=0
human_commits=0
reverted_commits=0

# Lists of agent and revert hashes/subjects
agent_hashes=""
agent_subjects=""
revert_subjects=""

# Read line-by-line to categorize
while IFS='|' read -r hash name email subject || [[ -n "$hash" ]]; do
  # Skip header or malformed empty entries
  if [[ -z "$hash" ]]; then continue; fi
  total_commits=$((total_commits + 1))

  # Lowercase for pattern matching
  lower_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
  lower_email=$(echo "$email" | tr '[:upper:]' '[:lower:]')
  lower_subject=$(echo "$subject" | tr '[:upper:]' '[:lower:]')

  is_agent=false
  # Agent pattern matches
  if [[ "$lower_name" == *"bot"* || "$lower_name" == *"agent"* || "$lower_name" == *"claude"* || \
        "$lower_name" == *"copilot"* || "$lower_name" == *"ai"* || "$lower_name" == *"gpt"* || \
        "$lower_name" == *"composer"* || "$lower_name" == *"speck"* || \
        "$lower_email" == *"bot"* || "$lower_email" == *"agent"* || "$lower_email" == *"claude"* || \
        "$lower_email" == *"copilot"* || "$lower_email" == *"ai"* || "$lower_email" == *"gpt"* || \
        "$lower_email" == *"composer"* ]]; then
    is_agent=true
  fi

  if [[ "$is_agent" == true ]]; then
    agent_commits=$((agent_commits + 1))
    agent_hashes="$agent_hashes $hash"
    agent_subjects="$agent_subjects|$lower_subject"
  else
    human_commits=$((human_commits + 1))
    if [[ "$lower_subject" == *"revert"* ]]; then
      revert_subjects="$revert_subjects|$lower_subject"
    fi
  fi
done < "$commits_file"

# Compute reverted agent commits
# We scan human revert subjects to see if they reference any agent commit subjects or hashes.
# Standard string splitting on pipe character to stay 100% portable on older bash
# without set -u empty array warnings.
old_ifs="$IFS"
IFS='|'
for rev in $revert_subjects; do
  IFS="$old_ifs"
  if [[ -z "$rev" ]]; then continue; fi
  # Check if this revert references any agent commit hash
  for h in $agent_hashes; do
    if [[ "$rev" == *"$h"* ]]; then
      reverted_commits=$((reverted_commits + 1))
      continue 2
    fi
  done
  # Check if this revert references any agent commit subject
  old_ifs2="$IFS"
  IFS='|'
  for ag_subj in $agent_subjects; do
    IFS="$old_ifs2"
    if [[ -z "$ag_subj" ]]; then continue; fi
    # Try to clean common prefixes/suffixes for matching
    if [[ "$rev" == *"$ag_subj"* ]]; then
      reverted_commits=$((reverted_commits + 1))
      continue 2
    fi
  done
done
IFS="$old_ifs"

override_rate=0
if [[ $agent_commits -gt 0 ]]; then
  # Integer math for percentage
  override_rate=$(( (reverted_commits * 100) / agent_commits ))
fi

survival_rate=$((100 - override_rate))

echo -e "Total commits checked : $total_commits"
echo -e "Agent commits found   : $agent_commits"
echo -e "Human commits found   : $human_commits"
echo -e "Agent commits reverted: $reverted_commits"
echo -e "Agent Override Rate   : ${override_rate}%"
echo -e "Agent Code Survival   : ${survival_rate}%"
echo -e "${BLUE}----------------------------------------------------------------------${NC}"

if [[ $override_rate -gt $THRESHOLD ]]; then
  echo -e "${RED}⚠️  EVAL DRIFT DETECTED: EVAL_SIGNAL_DRIFT.P2${NC}"
  echo -e "Override rate of ${override_rate}% exceeds acceptable threshold of ${THRESHOLD}%."
  echo -e "Autonomous code survival is too low. Review agent trajectories for quality."
  echo "EVAL_SIGNAL_DRIFT_SUMMARY P2=1 override_rate=$override_rate"
  if [[ "$STRICT" == true ]]; then
    exit 1
  fi
else
  echo -e "${GREEN}✅ EVAL SIGNAL STABLE: Code survival matches quality threshold.${NC}"
  echo "EVAL_SIGNAL_DRIFT_SUMMARY P2=0 override_rate=$override_rate"
  exit 0
fi
