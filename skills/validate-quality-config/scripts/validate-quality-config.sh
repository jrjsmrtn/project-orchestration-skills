#!/bin/bash
# Validate quality configuration consistency
# Usage: ./scripts/validate-quality-config.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

check() {
  if eval "$1"; then
    echo -e "${GREEN}✓${NC} $2"
  else
    echo -e "${RED}✗${NC} $2"
    errors=$((errors + 1))
  fi
}

warn() {
  if eval "$1"; then
    echo -e "${GREEN}✓${NC} $2"
  else
    echo -e "${YELLOW}⚠${NC} $2"
    warnings=$((warnings + 1))
  fi
}

echo "Quality Configuration Validation"
echo "================================="
echo ""

# Check reference exists
check "[ -f docs/reference/quality-configuration.md ]" "quality-configuration.md exists"
check "[ -f .editorconfig ]" ".editorconfig exists"
check "[ -f .pre-commit-config.yaml ]" ".pre-commit-config.yaml exists"

echo ""
echo "Checking value consistency..."

# Toolchain floor vs build version — the one check that asserts a DIFFERENCE.
# See Step 6; this is the highest-value single check in the script, because getting it
# wrong ships artifacts built on the least-patched runtime the project supports.
floor=$(grep -m1 -oE '^go[[:space:]]+[0-9.]+' go.mod 2>/dev/null | grep -oE '[0-9.]+')
if [ -n "$floor" ]; then
  if grep -rqE "version:[[:space:]]*\"?${floor}([^0-9.]|$)" .github/workflows/ 2>/dev/null; then
    echo "✗ CI builds at the declared floor ($floor)"
    errors=$((errors + 1))
  fi
  n_manifest=$(grep -rc 'version-file' .github/workflows/ 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
  if [ "$n_manifest" -gt 1 ]; then
    echo "⚠ $n_manifest call sites read the toolchain from a manifest; only the floor job should"
    warnings=$((warnings + 1))
  fi
fi

# Lint-tool pins: exact, and the same on both sides (Step 6b). List the project's tools.
# Capture the status itself -- under `set -e` a bare failing call would abort the script
# before the report. Any non-zero (1 floating/differing, 2 nothing found) is an error.
if [ -x scripts/check-tool-pins.sh ]; then
  scripts/check-tool-pins.sh reuse gitleaks && rc=0 || rc=$?
  if [ "$rc" -ne 0 ]; then errors=$((errors + 1)); fi
fi

# Add technology-specific checks here based on project type

echo ""
echo "================================="
echo "Errors: $errors"
echo "Warnings: $warnings"
echo ""

if [ $errors -gt 0 ]; then
  echo -e "${RED}Validation FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}Validation PASSED${NC}"
fi
