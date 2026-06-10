#!/usr/bin/env bash

# Speck Git Pre-Commit Hook Guard
# Intercepts git commit and validates staged markdown specifications + root README.
#
# To skip intentionally: git commit --no-verify (Git prints a bypass warning).
# Use only for chore commits with known false positives or emergency fixes.

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🥓 Running Speck Git pre-commit validation...${NC}"

staged_specs=()
staged_readme=false

while IFS= read -r file; do
  if [[ "$file" == "README.md" && -f "$file" ]]; then
    staged_readme=true
  elif [[ "$file" == *"specs/"* && "$file" == *".md" && -f "$file" ]]; then
    staged_specs+=("$file")
  fi
done < <(git diff --cached --name-only --diff-filter=ACM || true)

errors=0

# Early-exit when nothing staged, before referencing the array (set -u safe)
if [[ ${#staged_specs[@]} -eq 0 && "$staged_readme" == false ]]; then
  echo -e "${GREEN}✓ No Speck specifications or README staged for commit.${NC}"
  exit 0
fi

# Bash 3+ safe array expansion when the array may be empty under `set -u`
# Note: traceability-matrix.md is covered here too — validate-template.sh routes it to
# validate-traceability-matrix.sh (default/conservation mode) by filename.
if [[ ${#staged_specs[@]} -gt 0 ]]; then
  for spec in "${staged_specs[@]}"; do
    echo -e "${BLUE}🔍 Validating: $spec...${NC}"
    if ! bash .speck/scripts/validation/validate-template.sh --strict "$spec"; then
      echo -e "${RED}❌ Validation failed for $spec.${NC}"
      errors=$((errors + 1))
    fi
  done
fi

if [[ "$staged_readme" == true ]]; then
  echo -e "${BLUE}🔍 Validating: README.md (PROFILE)...${NC}"
  if ! bash .speck/scripts/validation/validate-profile.sh --strict; then
    echo -e "${RED}❌ Validation failed for README.md.${NC}"
    errors=$((errors + 1))
  fi
fi

# Staged-scoped banned-language lint (advisory at pre-commit; full-repo scan remains manual/CI)
if [[ -f ".speck/scripts/banned-language-lint.sh" ]]; then
  echo -e "${BLUE}🔍 Running staged banned-language lint...${NC}"
  if ! bash .speck/scripts/banned-language-lint.sh --staged; then
    echo -e "${RED}❌ Banned-language violations in staged files.${NC}"
    errors=$((errors + 1))
  fi
fi

if [[ "$errors" -gt 0 ]]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}ERROR: Commit rejected. Found $errors non-compliant file(s).${NC}"
  echo -e "${YELLOW}Please fix the validation errors shown above before committing.${NC}"
  echo -e "${BLUE}Note: If this is a migrated project with legacy failures, run:${NC}"
  echo -e "  ${GREEN}/speck-catch-up --phase=refresh${NC} or use ${GREEN}speck validate --active-only${NC} to isolate active work."
  echo -e "${BLUE}Note: If you need to force-commit (not recommended), use 'git commit --no-verify'.${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
  exit 1
fi

echo -e "${GREEN}✓ All staged Speck artifacts are valid! Allow commit.${NC}"
exit 0
