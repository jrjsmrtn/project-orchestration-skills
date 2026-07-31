---
name: setup-pre-commit
description: Configure two-stage pre-commit hooks for quality automation. Use after bootstrap-project and setup-adrs, when adding quality gates to an existing project, or when standardizing quality automation.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.26"
license: MIT
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

## Toolchain Versions

Three roles, and conflating them ships defects. Record all three even when two coincide today.

| Role | Version | Declared in | Meaning |
|------|---------|-------------|---------|
| **Floor** | [oldest supported] | [manifest] | the oldest a *consumer* needs — a compatibility claim |
| **Build** | [current] | [CI config] | what CI and releases are actually built with |
| **Inherited** | [if any] | [sub-module manifest] | a floor a dependency forces on you, not one you chose |

Per ecosystem, the floor lives in:

| Ecosystem | Floor | Build version |
|-----------|-------|---------------|
| Go | `go` directive in `go.mod` | `go-version:` in the workflow |
| Rust | `rust-version` (MSRV) in `Cargo.toml` | toolchain file / CI |
| Python | `requires-python` in `pyproject.toml` | `python-version:` in CI |
| Node | `engines.node` in `package.json` | `node-version:` in CI |
| Elixir | `elixir` requirement in `mix.exs` | CI matrix |

**Build with the current version, never the floor.** The floor states what a consumer needs;
building at it means building against the least-patched runtime. Released artifacts embed that
runtime — and if you publish an SBOM, they *record* it — so building at the floor can publish a
known-vulnerable runtime and document the fact in the accompanying BOM.

**Prove the floor separately.** One CI job builds and tests at exactly the declared floor, so the
compatibility claim is verified rather than aspirational. Do **not** run vulnerability scanning
there: an old toolchain has old advisories by definition, which is a reason not to *ship* it, not a
reason to stop supporting it.

**Record the per-call-site intent.** List every place a toolchain version is selected and why it
reads what it reads. A partial fix is the common failure — updating the two obvious workflows and
missing the scheduled scan.

**Record the maintenance obligation.** Pin the build *line* rather than tracking `latest`, so a new
major release cannot change what you ship without a commit; patch releases within the line still
arrive, which is how runtime security fixes reach you. Nothing automates the major bump — dependency
bots do not manage CI toolchain versions — so name it as a periodic, deliberate act. Its failure
mode is silent.

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

Commands with expected output, not reminders — a reader or an agent should be able to run these
and compare. Substitute the ecosystem's own commands; the shape is what matters.

```bash
# Every build-version selector in CI names the same pinned line (expect ONE distinct value):
grep -rhoE '(go|python|node|otp|elixir)-version:[[:space:]]*"?[^"[:space:]]+' .github/workflows/ \
  | tr -d '"' | sort -u

# Only the floor-compatibility job reads the floor from the manifest (expect exactly the jobs
# listed in the per-call-site table above — nothing else):
grep -rn 'version-file' .github/workflows/

# The floor still builds and tests (Go shown; use the ecosystem's pinning mechanism):
GOTOOLCHAIN=go[FLOOR] go build ./... && GOTOOLCHAIN=go[FLOOR] go test ./...

# Vulnerability scanning is clean ON THE BUILD VERSION, not the floor:
[govulncheck ./... | pip-audit | cargo audit | mix deps.audit]

# Local hooks and CI run the same commands (expect the same tool invocations on both sides):
grep -oE '(gofmt|go vet|go test|ruff|mix format|cargo fmt)[^"]*' .lefthook.yml | sort -u
grep -oE '(gofmt|go vet|go test|ruff|mix format|cargo fmt)[^"]*' .github/workflows/ci.yml | sort -u
```

- [ ] `.editorconfig` matches Formatting Standards
- [ ] Linter configs match line length and indent
```

> **Pattern Reference**: See [CONSISTENT-QUALITY-GATES](https://github.com/jrjsmrtn/ai-assisted-project-orchestration/blob/develop/docs/patterns/quality/consistent-quality-gates.md)

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

### Step 2: Secret Detection Architecture

Secret detection works in three layers:

**Layer 1: Global gitleaks config** (`~/.gitleaks.toml`)
- Infrastructure-specific patterns (hostnames, domains, private IPs, custom ports)
- Allowlists for git-ignored files (CLAUDE.local.md, .envrc, vault files)
- RFC 5737/7042 documentation addresses excluded from false positives

**Layer 2: Project gitleaks config** (`.gitleaks.toml`, `.gitleaksignore`)
- Test fixture allowlists (generated keys, X.509 elements, mock data)
- Documentation allowlists (demo credentials in tutorials)
- Stop words for test data: test, example, sample, dummy, fake, mock, stub

**Layer 3: Git hooks** (pre-commit stage)
- `gitleaks protect --staged` on every commit
- Catches secrets before they enter git history

Create `.gitleaks.toml` if the project has test fixtures or documentation with intentional fake credentials:

```toml
[extend]
useDefault = true

[allowlist]
description = "Project-specific allowlist for test data and documentation"

# Test fixtures with intentional fake data
paths = [
    '''test/fixtures/.*''',
    '''test/support/.*''',
]

# Stop words — values containing these are not secrets
stopwords = [
    "test",
    "example",
    "sample",
    "dummy",
    "fake",
    "mock",
]
```

Use `.gitleaksignore` for specific false positives that can't be handled by rules:

```
# Explain why each entry is not a real secret
path/to/file.ex:rule-id:line-number
```

### Step 3: Sensitive Files in .gitignore

Ensure `.gitignore` covers all secret-bearing files:

```
# Secrets and credentials
.env
.env.*
!.env.example
.envrc
.envrc.local
*.pem
*.key
credentials.json
secrets.yaml

# Claude Code local files
CLAUDE.local.md
```

`.envrc` and `.envrc.local` (direnv) are treated like `.env` — they may contain or derive secrets (e.g., Keychain lookups). If a project needs a committed `.envrc` for non-secret PATH setup, use `.envrc.local` for the secret overrides and source it from `.envrc`:

```bash
# .envrc (committed — no secrets)
PATH_add bin
source_env_if_exists .envrc.local
```

```bash
# .envrc.local (git-ignored — secrets here)
export API_KEY="$(security find-internet-password -w -s example.com -a user 2>/dev/null)"
```

### Step 4: Install Hook Framework

**Preferred: lefthook** (fast, no Python dependency, parallel execution):

```bash
# macOS
port install lefthook  # or: brew install lefthook

# Verify
lefthook version
```

**Alternative: pre-commit** (Python-based, wider ecosystem of third-party hooks):

```bash
pipx install pre-commit
pre-commit --version
```

### Step 5: Create Configuration

Create hook configuration based on framework choice and technology stack:

#### Dependency vulnerability auditing

The pre-push stage runs a dependency vulnerability audit per ecosystem — this satisfies the
OpenSSF Scorecard `Vulnerabilities` check and the Best Practices Badge's dependency-vulnerability
criterion. The tools are **not interchangeable**; know what each checks:

| Ecosystem | Tool | Checks | Prerequisite |
|-----------|------|--------|--------------|
| Elixir | `mix deps.audit` | Known **CVEs** in dependencies | add `{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}` to `mix.exs` |
| Elixir | `mix hex.audit` | **Retired** Hex packages | built into Hex |
| Python | `pip-audit` | Known CVEs (PyPI / OSV) | `pip install pip-audit` (or `uv`) |
| Rust | `cargo audit` | RustSec advisory DB | `cargo install cargo-audit` |

For Elixir, run **both**: `mix hex.audit` flags retired/deprecated packages, while `mix deps.audit`
(via the `mix_audit` package) flags packages with known CVEs — different failure modes, both needed.
Elixir/BEAM advisories are increasingly issued by the **Erlang Ecosystem Foundation**, now a CVE
Numbering Authority (CNA) for Hex.pm and the BEAM ecosystem under the **EEF Ægis** initiative — so
`mix deps.audit` is only as good as the advisory feed it consumes, which the EEF now curates.

#### Lockfile and frozen installs

Commit the ecosystem lockfile and install from it deterministically — the OpenSSF Scorecard `Pinned-Dependencies` control, which makes builds reproducible and tamper-evident.

| Ecosystem | Lockfile (commit it) | Frozen/locked install (CI + containers) |
|-----------|----------------------|------------------------------------------|
| Python (uv) | `uv.lock` | `uv sync --frozen` |
| Elixir | `mix.lock` | `mix deps.get --check-locked` (CI) |
| Rust | `Cargo.lock` | `cargo build --locked` |
| Node | `package-lock.json` | `npm ci` |

Add a pre-push/CI check that the lockfile is present and committed, and flag a manifest that declares only lower-bound (`>=` / `~>`) constraints with **no** committed lock — anyone installing from sdist/wheel without the lock then resolves loosely. In a Containerfile, avoid `COPY mix.lock*` (optional glob): it silently masks a missing lockfile.

#### License compliance — REUSE (public projects)

For **public** open-source projects, make licensing machine-readable and *enforced*, not just prescribed in prose. Provides the SPDX data an SBOM/CRA review expects. Scaffold a `LICENSES/` directory (one SPDX license text each), inline `SPDX-FileCopyrightText` + `SPDX-License-Identifier` headers, and a `REUSE.toml` to bulk-annotate docs and correctly attribute vendored/upstream fixtures (kept byte-pristine yet attributed):

```toml
# REUSE.toml
version = 1

[[annotations]]
path = "docs/**"
SPDX-FileCopyrightText = "2026 Georges Martin <jrjsmrtn@gmail.com>"
SPDX-License-Identifier = "MIT"

[[annotations]]
path = "vendor/upstream/**"
SPDX-FileCopyrightText = "Upstream authors"
SPDX-License-Identifier = "Apache-2.0"
```

Enforce `reuse lint` in both stages — a git hook and a CI job:

```yaml
# .lefthook.yml
reuse:
  run: reuse lint
```

```yaml
# .github/workflows/ci.yml — SHA-pin per harden-github-actions
- uses: fsfe/reuse-action@<sha>   # v5
```

#### Lefthook — Elixir Configuration

```yaml
# .lefthook.yml
pre-commit:
  parallel: true
  commands:
    gitleaks:
      run: gitleaks protect --staged --verbose
    format-elixir:
      run: mix format --check-formatted
      glob: "*.{ex,exs}"
    format-markdown:
      run: dprint check
      glob: "*.md"

pre-push:
  parallel: true
  commands:
    compile:
      run: mix compile --warnings-as-errors
    credo:
      run: mix credo --strict
      glob: "*.{ex,exs}"
    test:
      run: mix test --exclude slow --exclude integration
    dialyzer:
      run: mix dialyzer
    deps-audit:
      run: mix deps.audit
    hex-audit:
      run: mix hex.audit
```

#### Lefthook — Python Configuration

```yaml
# .lefthook.yml
pre-commit:
  parallel: true
  commands:
    gitleaks:
      run: gitleaks protect --staged --verbose
    ruff-format:
      run: ruff format --check .
      glob: "*.py"
    ruff-check:
      run: ruff check .
      glob: "*.py"
    format-markdown:
      run: dprint check
      glob: "*.md"

pre-push:
  parallel: true
  commands:
    mypy:
      run: mypy .
    pip-audit:
      run: pip-audit
    test:
      run: pytest -m "not slow and not integration"
```

#### Lefthook — Multi-Language Configuration (Elixir + Rust NIFs)

```yaml
# .lefthook.yml
pre-commit:
  parallel: true
  commands:
    gitleaks:
      run: gitleaks protect --staged --verbose
    format-elixir:
      run: mix format --check-formatted
      glob: "*.{ex,exs}"
    format-rust:
      run: cargo fmt -- --check
      root: "native/{nif_name}/"
    format-markdown:
      run: dprint check
      glob: "*.md"

pre-push:
  parallel: true
  commands:
    compile:
      run: mix compile --warnings-as-errors
    credo:
      run: mix credo --strict
    test-elixir:
      run: mix test
    dialyzer:
      run: mix dialyzer
    deps-audit:
      run: mix deps.audit
    hex-audit:
      run: mix hex.audit
    clippy:
      run: cargo clippy -- -D warnings
      root: "native/{nif_name}/"
    test-rust:
      run: cargo test
      root: "native/{nif_name}/"
    cargo-audit:
      run: cargo audit
      root: "native/{nif_name}/"
```

#### Alternative: pre-commit Framework — Elixir

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  - repo: local
    hooks:
      - id: mix-format
        name: mix format
        entry: mix format --check-formatted
        language: system
        files: \.exs?$
        pass_filenames: false

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

      - id: mix-hex-audit
        name: mix hex.audit
        entry: mix hex.audit
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

#### Alternative: pre-commit Framework — Python

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: local
    hooks:
      - id: mypy
        name: mypy
        entry: mypy .
        language: system
        types: [python]
        pass_filenames: false
        stages: [pre-push]

      - id: pip-audit
        name: pip-audit
        entry: pip-audit
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: pytest-fast
        name: pytest (fast)
        entry: pytest -m "not slow and not integration"
        language: system
        pass_filenames: false
        stages: [pre-push]
```

### Step 6: Install Hooks

```bash
# lefthook
lefthook install

# OR pre-commit
pre-commit install
pre-commit install --hook-type pre-push

# Verify installation
ls -la .git/hooks/pre-commit .git/hooks/pre-push
```

### Step 7: Optional - Multi-Remote Protection

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

### Step 8: Initial Run

```bash
# lefthook — run all pre-commit hooks
lefthook run pre-commit

# OR pre-commit — run against all files
pre-commit run --all-files

# Fix any issues found, then commit the configuration
git add .lefthook.yml  # or .pre-commit-config.yaml
git add .gitleaks.toml .gitleaksignore  # if created
git commit -m "chore: add pre-commit hooks configuration"
```

### Step 9: Enforce dependency audits in CI

Pre-push hooks are local and bypassable (`git push --no-verify`). For real enforcement, run the
same dependency audit **server-side** in a dedicated CI job — this is what the OpenSSF Scorecard
`Vulnerabilities` check expects. Add an `audit` job (Elixir shown; mirror for `pip-audit` / `cargo audit`):

```yaml
# .github/workflows/ci.yml (excerpt)
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha> # v4
      - uses: erlef/setup-beam@<sha> # v1
        with: { otp-version: "27", elixir-version: "1.18" }
      - run: mix deps.get
      - run: mix deps.audit   # known CVEs (needs :mix_audit)
      - run: mix hex.audit    # retired packages
```

Run it on a schedule too, so newly-disclosed CVEs are caught on branches that aren't seeing commits:

```yaml
on:
  schedule:
    - cron: "0 6 * * 1"   # weekly
```

Harden this job (SHA-pin the actions, `permissions: contents: read`) with `harden-github-actions`.

## Outputs

This skill creates:
- [ ] `docs/reference/quality-configuration.md` (single source of truth)
- [ ] `.editorconfig` (editor formatting)
- [ ] `.lefthook.yml` or `.pre-commit-config.yaml` (two-stage hook configuration)
- [ ] `.gitleaks.toml` (project-specific allowlist, if needed)
- [ ] `.gitleaksignore` (specific false positives, if needed)
- [ ] `.git/hooks/pre-commit` (installed by hook framework)
- [ ] `.git/hooks/pre-push` (installed by hook framework)
- [ ] `.git/hooks/pre-push-remote-check` (optional, for multi-remote)
- [ ] `{:mix_audit, ...}` added to `mix.exs` deps (Elixir CVE-audit prerequisite)
- [ ] Dependency audit enforced in a CI `audit` job (not hook-only) + scheduled re-run
- [ ] Ecosystem lockfile committed; frozen/locked installs in CI + containers
- [ ] (Public projects) REUSE: `LICENSES/` + `REUSE.toml` + `reuse lint` hook and CI job

## Validation

Verify successful setup:

```bash
# Check hooks are installed
ls -la .git/hooks/pre-commit .git/hooks/pre-push

# Test Stage 1 (pre-commit)
lefthook run pre-commit          # or: pre-commit run --all-files

# Test Stage 2 (pre-push)
lefthook run pre-push            # or: pre-commit run --all-files --hook-stage pre-push

# Verify timing
time lefthook run pre-commit     # Should be <30s
time lefthook run pre-push       # Should be <3min
```

## Troubleshooting

**Hook not running?**
```bash
# lefthook
lefthook install

# pre-commit
pre-commit install --force
pre-commit install --hook-type pre-push --force
```

**Bypassing hooks (emergency only)**
```bash
git commit --no-verify -m "message"  # Skip pre-commit
git push --no-verify                  # Skip pre-push
```

**Updating hook versions (pre-commit only)**
```bash
pre-commit autoupdate
git add .pre-commit-config.yaml
git commit -m "chore: update pre-commit hook versions"
```

## Related Skills

- `setup-adrs` - establishes the development-practices ADR that documents these quality gates
- `validate-quality-config` - Validate configuration consistency
- `harden-github-actions` - harden the CI audit job (SHA-pin actions, least-privilege permissions)
