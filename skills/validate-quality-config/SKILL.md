---
name: validate-quality-config
description: Validate consistency across quality configuration files. Use after setup-pre-commit, when debugging "works locally, fails in CI" issues, before major releases, or when onboarding.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.19"
license: MIT
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

## Required Inputs

- A project that already has quality configuration in place (run `setup-pre-commit` first)
- `docs/reference/quality-configuration.md` as the single source of truth for canonical values
- Read access to the config files being cross-checked (`.editorconfig`, linter configs such as `.credo.exs` / `ruff.toml` / `.prettierrc`, `.pre-commit-config.yaml`, and the CI workflow files under `.github/workflows/` or `.gitlab-ci.yml`)

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

### Step 6: Validate Version Consistency

The declared version must agree across every file that states it. Drift here is a real, common defect (e.g. a README badge or `SECURITY.md` left behind while the manifest moved on).

```bash
echo "Checking version consistency..."
# Canonical version from the package manifest (pick the one for the stack):
ver=$(grep -m1 -oE '"version":[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' package.json 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
ver=${ver:-$(grep -m1 -oE '@version[[:space:]]+"[0-9]+\.[0-9]+\.[0-9]+"' mix.exs 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')}
ver=${ver:-$(grep -m1 -oE '^version[[:space:]]*=[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' pyproject.toml 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')}
echo "manifest version: ${ver:-UNKNOWN}"

# The manifest version should appear in each of these; a *different* x.y.z is drift:
for f in README.md CHANGELOG.md SECURITY.md; do
  [ -f "$f" ] || continue
  if grep -q "$ver" "$f"; then echo "✓ $f mentions $ver"
  else echo "✗ $f does not mention $ver"; fi
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$f" | grep -v "^$ver$" | sort -u | sed "s/^/  ⚠ $f also states /"
done
```

Confirm the declared version agrees across the package manifest (`mix.exs` `@version`, `pyproject.toml` `version`, `package.json` `version`, `Cargo.toml`, `build.gradle.kts`), the `README.md` status line/badge, the latest released `CHANGELOG.md` section, and the `SECURITY.md` supported-versions table. Report any divergence as an error. If the project follows a during-development versioning rule (for example, staying on patch-level `0.1.x` releases until the first stable minor), honour it.

### Step 7: Generate Validation Report

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
- [ ] Version-consistency check across manifest / README / CHANGELOG / SECURITY.md
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

## Validation

The skill has done its job when:

- The reference document `docs/reference/quality-configuration.md` is found (or its absence is reported as an error and the run stops)
- Each canonical value (indent style/size, line length, EOL) is compared against every downstream config, and mismatches are flagged
- Pre-commit hooks are confirmed to be a subset of the CI checks (linting, type checking, and tests all present in CI)
- The declared version is confirmed identical across the package manifest, `README.md`, `CHANGELOG.md`, and `SECURITY.md`
- The validation report exits non-zero when any hard mismatch is found

## Related Skills

- `setup-pre-commit` - Creates the configs this validates
- `setup-adrs` - Documents quality practices in an ADR

> **Pattern Reference**: See [CONSISTENT-QUALITY-GATES](https://github.com/jrjsmrtn/ai-assisted-project-orchestration/blob/develop/docs/patterns/quality/consistent-quality-gates.md)
