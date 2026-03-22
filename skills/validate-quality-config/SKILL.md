---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: validate-quality-config
description: Validate consistency across quality configuration files. Use after setup-pre-commit, when debugging "works locally, fails in CI" issues, before major releases, or when onboarding.
---

# Validate Quality Configuration

Validate consistency across quality configuration files.

## When to Use

- After running `setup-pre-commit` skill
- When debugging "works locally, fails in CI" issues
- Before major releases or audits
- When onboarding to understand quality setup
- After updating any quality-related configuration

## What It Validates

The consistency chain:

```
docs/reference/quality-configuration.md  ← Single source of truth
         ↓ must match
.editorconfig                            ← Editor formatting
         ↓ must match
Linter configs                           ← Code analysis
         ↓ must match
.pre-commit-config.yaml                  ← Local hooks
         ↓ must match
.github/workflows/*.yml                  ← CI pipeline
.gitlab-ci.yml
```

## Workflow

### Step 1: Check Reference Document Exists

```bash
# Verify single source of truth exists
if [ -f docs/reference/quality-configuration.md ]; then
    echo "✓ quality-configuration.md exists"
else
    echo "✗ Missing docs/reference/quality-configuration.md"
    echo "  Run: quality/setup-pre-commit skill first"
    exit 1
fi
```

### Step 2: Extract Canonical Values

Parse the quality-configuration.md for key settings:

```bash
# Example: Extract indent size for Python
grep -A1 "indent_size.*4" docs/reference/quality-configuration.md
```

Expected values to extract:
- Indent style (spaces/tabs)
- Indent size per language
- Line length
- End of line (lf/crlf)

### Step 3: Validate .editorconfig

```bash
echo "Checking .editorconfig..."

# Check indent_style
grep -q "indent_style = space" .editorconfig && echo "✓ indent_style" || echo "✗ indent_style mismatch"

# Check Python indent
grep -A1 "\[*.py\]" .editorconfig | grep -q "indent_size = 4" && echo "✓ Python indent" || echo "✗ Python indent mismatch"

# Check line length (if supported by editorconfig)
grep -q "max_line_length" .editorconfig && echo "✓ max_line_length defined" || echo "⚠ max_line_length not in editorconfig"
```

### Step 4: Validate Linter Configs

#### Elixir (.credo.exs, .formatter.exs)

```bash
echo "Checking Elixir configs..."

# Check .formatter.exs line_length
grep -q "line_length: 120" .formatter.exs && echo "✓ formatter line_length" || echo "✗ formatter line_length mismatch"

# Check .credo.exs max_line_length
grep -q "max_line_length" .credo.exs && echo "✓ credo line_length defined" || echo "⚠ credo line_length not found"
```

#### Python (ruff.toml, pyproject.toml)

```bash
echo "Checking Python configs..."

# Check ruff line-length
if [ -f ruff.toml ]; then
    grep -q "line-length = 120" ruff.toml && echo "✓ ruff line-length" || echo "✗ ruff line-length mismatch"
    grep -q "indent-width = 4" ruff.toml && echo "✓ ruff indent-width" || echo "✗ ruff indent-width mismatch"
elif [ -f pyproject.toml ]; then
    grep -A5 "\[tool.ruff\]" pyproject.toml | grep -q "line-length = 120" && echo "✓ ruff line-length" || echo "✗ ruff line-length mismatch"
fi
```

#### TypeScript (eslint.config.js, prettier)

```bash
echo "Checking TypeScript configs..."

# Check prettier config
if [ -f .prettierrc ] || [ -f .prettierrc.json ]; then
    grep -q '"tabWidth": 2' .prettierrc* && echo "✓ prettier tabWidth" || echo "✗ prettier tabWidth mismatch"
    grep -q '"printWidth": 120' .prettierrc* && echo "✓ prettier printWidth" || echo "✗ prettier printWidth mismatch"
fi
```

### Step 5: Validate Pre-commit vs CI Alignment

```bash
echo "Checking pre-commit vs CI alignment..."

# Extract checks from pre-commit
pre_commit_hooks=$(grep "id:" .pre-commit-config.yaml | sed 's/.*id: //' | sort)

# Check CI has superset
if [ -f .github/workflows/ci.yml ]; then
    echo "GitHub Actions detected"
    # Verify key checks are in CI
    grep -q "ruff\|credo\|mix format" .github/workflows/ci.yml && echo "✓ Linting in CI" || echo "✗ Linting missing from CI"
    grep -q "mypy\|dialyzer\|tsc" .github/workflows/ci.yml && echo "✓ Type checking in CI" || echo "✗ Type checking missing from CI"
    grep -q "pytest\|mix test\|npm test" .github/workflows/ci.yml && echo "✓ Tests in CI" || echo "✗ Tests missing from CI"
fi

if [ -f .gitlab-ci.yml ]; then
    echo "GitLab CI detected"
    # Similar checks for GitLab
    grep -q "lint\|format" .gitlab-ci.yml && echo "✓ Linting in CI" || echo "✗ Linting missing from CI"
fi
```

### Step 6: Generate Validation Report

```bash
echo ""
echo "=== Quality Configuration Validation Report ==="
echo ""
echo "Reference: docs/reference/quality-configuration.md"
echo ""
echo "Files checked:"
echo "  - .editorconfig"
echo "  - [linter configs]"
echo "  - .pre-commit-config.yaml"
echo "  - [CI config]"
echo ""
echo "Issues found: [count]"
echo ""
echo "Recommendations:"
echo "  - [any mismatches to fix]"
```

## Automated Validation Script

Create `scripts/validate-quality-config.sh`:

```bash
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
        ((errors++))
    fi
}

warn() {
    if eval "$1"; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${YELLOW}⚠${NC} $2"
        ((warnings++))
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
```

## Outputs

This skill produces:
- [ ] Validation report (stdout)
- [ ] (Optional) `scripts/validate-quality-config.sh` for automation

## Integration

### Makefile Target

Add to project Makefile:

```makefile
.PHONY: validate-quality-config

validate-quality-config:
	@echo "Validating quality configuration consistency..."
	@./scripts/validate-quality-config.sh
```

### Pre-commit Hook (Optional)

Add validation to pre-commit for config files:

```yaml
- repo: local
  hooks:
    - id: validate-quality-config
      name: validate quality config
      entry: ./scripts/validate-quality-config.sh
      language: script
      files: '(\.editorconfig|\.pre-commit-config\.yaml|ruff\.toml|\.credo\.exs|quality-configuration\.md)$'
      pass_filenames: false
```

## Related Skills

- `setup-pre-commit` - Creates the configs this validates
- `setup-adrs` - ADR-0002 documents quality practices

> **Pattern Reference**: See [CONSISTENT-QUALITY-GATES](../../../docs/patterns/quality/consistent-quality-gates.md)
