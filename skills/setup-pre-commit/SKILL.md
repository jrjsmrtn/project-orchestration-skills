---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: setup-pre-commit
description: Configure two-stage pre-commit hooks for quality automation. Use after bootstrap-project and setup-adrs, when adding quality gates to an existing project, or when standardizing quality automation.
---

# Setup Pre-commit Hooks

Configure two-stage pre-commit hooks for quality automation.

## When to Use

- After running `bootstrap-project` and `setup-adrs` skills
- When adding quality gates to an existing project
- When standardizing quality automation across projects

## Required Inputs

1. **Technology stack** (Elixir, Python, TypeScript, etc.)
2. **Quality tools preference** (can use defaults for each ecosystem)
3. **Multi-remote strategy** (if using private + public remotes)

## Two-Stage Strategy

**Stage 1: Pre-commit (Fast, <30 seconds)**
- File hygiene (whitespace, line endings, merge conflicts)
- Secret detection (critical security gate)
- Code formatting check

**Stage 2: Pre-push (Thorough, <3 minutes)**
- Linting with strict rules
- Type checking
- Security audit (dependencies)
- Fast tests (exclude slow/integration)

## Workflow

### Step 0: Create Quality Configuration Reference

Before configuring tools, create the single source of truth: `docs/reference/quality-configuration.md`

```markdown
# Quality Configuration

Single source of truth for all quality settings.

## Formatting Standards

| Setting | Value | Applies To |
|---------|-------|------------|
| Indent style | spaces | All files |
| Indent size | [2 or 4] | [Language-specific] |
| Line length | [80/100/120] | All code |
| End of line | lf | All files |
| Final newline | yes | All files |
| Trim trailing whitespace | yes | All files |

## Quality Checks by Stage

| Check | Pre-commit | Pre-push | CI | Notes |
|-------|------------|----------|-----|-------|
| Formatting | Yes | - | Yes | Auto-fix locally |
| Linting (fast) | Yes | - | Yes | Syntax, imports |
| Linting (slow) | - | Yes | Yes | Complex analysis |
| Type checking | - | Yes | Yes | Full type analysis |
| Unit tests | - | Yes | Yes | Fast tests locally |
| Integration tests | - | - | Yes | CI only |
| Security scanning | - | Yes | Yes | Secrets, deps |
| Coverage | - | - | Yes | CI only |

## Validation Checklist

- [ ] .editorconfig matches Formatting Standards
- [ ] Linter configs match line length and indent
- [ ] Pre-commit runs all "Pre-commit: Yes" checks
- [ ] Pre-push runs all "Pre-push: Yes" checks
- [ ] CI runs all checks marked "CI: Yes"
```

> **Pattern Reference**: See [CONSISTENT-QUALITY-GATES](../../../docs/patterns/quality/consistent-quality-gates.md)

### Step 1: Create .editorconfig

Create `.editorconfig` matching the quality-configuration:

```ini
root = true

[*]
indent_style = space
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8

[*.{ex,exs,js,ts,jsx,tsx,yaml,yml,json,md}]
indent_size = 2

[*.py]
indent_size = 4

[*.{ex,exs,py,js,ts}]
max_line_length = 120
```

### Step 2: Install Pre-commit Framework

```bash
# Python (recommended for all projects - it's a generic tool)
pipx install pre-commit

# Verify installation
pre-commit --version
```

### Step 3: Create Configuration

Create `.pre-commit-config.yaml` based on technology stack:

#### Elixir Configuration

```yaml
# .pre-commit-config.yaml
repos:
  # File hygiene
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-toml
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key

  # Secret detection (critical)
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  # Elixir-specific
  - repo: local
    hooks:
      # Stage 1: Pre-commit (fast)
      - id: mix-format
        name: mix format
        entry: mix format --check-formatted
        language: system
        files: \.exs?$
        pass_filenames: false

      # Stage 2: Pre-push (thorough)
      - id: mix-credo
        name: mix credo
        entry: mix credo --strict
        language: system
        files: \.exs?$
        pass_filenames: false
        stages: [pre-push]

      - id: mix-dialyzer
        name: mix dialyzer
        entry: mix dialyzer
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: mix-deps-audit
        name: mix deps.audit
        entry: mix deps.audit
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: mix-test-fast
        name: mix test (fast)
        entry: mix test --exclude slow --exclude integration
        language: system
        pass_filenames: false
        stages: [pre-push]
```

#### Python Configuration

```yaml
# .pre-commit-config.yaml
repos:
  # File hygiene
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-toml
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key

  # Secret detection (critical)
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  # Python formatting and linting (ruff - fast all-in-one)
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      # Stage 1: Pre-commit (fast)
      - id: ruff
        args: [--fix]
      - id: ruff-format

  # Stage 2: Pre-push (thorough)
  - repo: local
    hooks:
      - id: mypy
        name: mypy
        entry: uv run mypy .
        language: system
        types: [python]
        pass_filenames: false
        stages: [pre-push]

      - id: pip-audit
        name: pip-audit
        entry: uv run pip-audit
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: pytest-fast
        name: pytest (fast)
        entry: uv run pytest -m "not slow and not integration"
        language: system
        pass_filenames: false
        stages: [pre-push]
```

#### TypeScript/Node Configuration

```yaml
# .pre-commit-config.yaml
repos:
  # File hygiene
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key

  # Secret detection (critical)
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  # Stage 1 & 2 via local hooks
  - repo: local
    hooks:
      # Stage 1: Pre-commit (fast)
      - id: prettier
        name: prettier
        entry: npx prettier --check .
        language: system
        pass_filenames: false

      - id: eslint
        name: eslint
        entry: npx eslint .
        language: system
        pass_filenames: false

      # Stage 2: Pre-push (thorough)
      - id: typecheck
        name: typecheck
        entry: npx tsc --noEmit
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: npm-audit
        name: npm audit
        entry: npm audit --audit-level=moderate
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: test-fast
        name: test (fast)
        entry: npm test -- --testPathIgnorePatterns=integration
        language: system
        pass_filenames: false
        stages: [pre-push]
```

### Step 4: Install Hooks

```bash
# Install pre-commit hooks
pre-commit install

# Install pre-push hooks
pre-commit install --hook-type pre-push

# Verify installation
ls -la .git/hooks/pre-commit .git/hooks/pre-push
```

### Step 5: Optional - Multi-Remote Protection

If using multi-remote strategy (private origin + public GitHub/GitLab), add protection hook.

Create `.git/hooks/pre-push-remote-check` (will be sourced by pre-push):

```bash
#!/bin/bash
# Prevent pushing non-main branches to public remotes

remote="$1"
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

public_remotes="github gitlab"

for pub_remote in $public_remotes; do
    if [[ "$remote" == "$pub_remote" ]]; then
        if [[ "$current_branch" != "main" ]]; then
            echo "ERROR: Only push 'main' branch to public remote '$remote'"
            echo "Current branch: $current_branch"
            exit 1
        fi

        # Run additional security checks for public push
        echo "Pushing to public remote - running security scan..."
        gitleaks detect --source . --verbose || exit 1
    fi
done
```

### Step 6: Initial Run

```bash
# Run against all files to establish baseline
pre-commit run --all-files

# Fix any issues found
# Then commit the configuration
git add .pre-commit-config.yaml
git commit -m "chore: add pre-commit hooks configuration"
```

## Outputs

This skill creates:
- [ ] `docs/reference/quality-configuration.md` (single source of truth)
- [ ] `.editorconfig` (editor formatting)
- [ ] `.pre-commit-config.yaml` (two-stage configuration)
- [ ] `.git/hooks/pre-commit` (installed by pre-commit)
- [ ] `.git/hooks/pre-push` (installed by pre-commit)
- [ ] `.git/hooks/pre-push-remote-check` (optional, for multi-remote)

## Validation

Verify successful setup:

```bash
# Check hooks are installed
pre-commit --version
ls -la .git/hooks/pre-commit

# Test Stage 1 (pre-commit)
pre-commit run --all-files

# Test Stage 2 (pre-push)
pre-commit run --all-files --hook-stage pre-push

# Verify timing
time pre-commit run --all-files  # Should be <30s
time pre-commit run --all-files --hook-stage pre-push  # Should be <3min
```

## Troubleshooting

**Hook not running?**
```bash
pre-commit install --force
pre-commit install --hook-type pre-push --force
```

**Bypassing hooks (emergency only)**
```bash
git commit --no-verify -m "message"  # Skip pre-commit
git push --no-verify                  # Skip pre-push
```

**Updating hook versions**
```bash
pre-commit autoupdate
git add .pre-commit-config.yaml
git commit -m "chore: update pre-commit hook versions"
```

## Related Skills

- `setup-adrs` - ADR-0002 documents these practices
- `validate-quality-config` - Validate configuration consistency
