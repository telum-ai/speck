#!/usr/bin/env bash

# Speck Git Pre-Commit Hook Guard
# Intercepts git commit and validates all staged markdown specifications.
# Ensures that no malformed specifications or unreplaced template placeholders ever reach the branch.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🥓 Running Speck Git pre-commit validation...${NC}"

# Find staged markdown files in the specs/ directory
staged_specs=()
while IFS= read -r file; do
  if [[ "$file" == *"specs/"* && "$file" == *".md" && -f "$file" ]]; then
    staged_specs+=("$file")
  fi
done < <(git diff --cached --name-only --diff-filter=ACM || true)

if [ ${#staged_specs[@]} -eq 0 ]; then
  echo -e "${GREEN}✓ No Speck specifications staged for commit.${NC}"
  exit 0
fi

errors=0
for spec in "${staged_specs[@]}"; do
  echo -e "${BLUE}🔍 Validating: $spec...${NC}"
  # Run validation in strict mode so errors cause a non-zero exit code
  if ! bash .speck/scripts/validation/validate-template.sh --strict "$spec"; then
    echo -e "${RED}❌ Validation failed for $spec.${NC}"
    errors=$((errors + 1))
  fi
done

if [ "$errors" -gt 0 ]; then
  echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}ERROR: Commit rejected. Found $errors non-compliant Speck specification(s).${NC}"
  echo -e "${YELLOW}Please fix the validation errors shown above before committing.${NC}"
  echo -e "${BLUE}Note: If you need to force-commit (not recommended), use 'git commit --no-verify'.${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
  exit 1
fi

echo -e "${GREEN}✓ All staged Speck specifications are valid! Allow commit.${NC}"
exit 0
