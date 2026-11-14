---
name: setup-git-hooks
description: Configure two-stage git hooks (pre-commit + pre-push) for quality automation, with either pre-commit or lefthook as the hook manager. Use after bootstrap-project and setup-adrs, when adding quality gates to an existing project, or when standardizing quality automation.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.43"
license: MIT
---

# Setup Git Hooks

Configure two-stage git hooks — fast checks on commit, thorough checks on push — using either `pre-commit` or `lefthook` as the hook manager.

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

The list above is asserted, not just recommended: `scripts/check-hygiene.sh` (Step 5, *Hygiene check*) fails when
a pattern is missing, and when `.env.example` is ignored because the `!.env.example` line is absent.

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

Ship the check below as a pre-push and CI gate: the lockfile must be present **and committed** (present in the index — a lockfile that exists on disk but is git-ignored passes a plain `ls`), and it fails a manifest with no committed lock whatever its constraints say, which is stricter than flagging lower-bound (`>=` / `~>`) constraints only: anyone installing without the lock resolves loosely. In a Containerfile, avoid `COPY mix.lock*` (optional glob): it silently masks a missing lockfile, and the check fails it.

#### Hygiene check — `.gitignore` and lockfiles

```bash
#!/usr/bin/env bash
# scripts/check-hygiene.sh — the mechanical half of setup-git-hooks' Step 3 (.gitignore) and its
# "Lockfile and frozen installs" rule.
#   usage: scripts/check-hygiene.sh            run from the repository root
#   exit:  0 every check passed | 1 at least one FAILED
# .gitignore: judged by the tracked file alone in a scratch repository (your global excludes file is not
#   the project's). It must ignore .env .env.local .envrc .envrc.local *.pem *.key credentials.json
#   secrets.yaml CLAUDE.local.md, and must NOT ignore .env.example.
# Lockfiles: for each manifest found (pyproject.toml, mix.exs, Cargo.toml, package.json) a lockfile must
#   be COMMITTED — present in the index, not just on disk, and not git-ignored.
# Frozen installs, in CI files (.github/workflows, .gitlab-ci.yml) and Containerfile*/Dockerfile*, for an
#   ecosystem that has a lockfile: `uv sync` needs --frozen or --locked; `npm install` must be `npm ci`
#   (npm install -g is exempt); `cargo build` needs --locked; `mix deps.get` needs --check-locked. A
#   `COPY` of a lockfile through an optional glob (`mix.lock*`) is a failure: it masks a missing lockfile.
# Not checked: shell scripts the CI calls, other ecosystems (Go, for one), and lines continued across
#   backslashes (the command and its flag are judged on one physical line).
set -u
fail=0
ok()   { echo "ok    $*"; }
bad()  { echo "FAIL  $*"; fail=1; }
note() { echo "note  $*"; }

git rev-parse --git-dir >/dev/null 2>&1 || { echo "FAIL  not inside a git repository"; exit 1; }
tracked() { git ls-files --error-unmatch -- "$@" >/dev/null 2>&1; }

# ------------------------------------------------------------------ .gitignore
if [ ! -f .gitignore ]; then bad ".gitignore is missing"
else
  tmp=$(mktemp -d) && git -C "$tmp" init -q && cp .gitignore "$tmp/.gitignore"
  miss=""
  for p in .env .env.local .envrc .envrc.local server.pem server.key credentials.json secrets.yaml CLAUDE.local.md; do
    git -C "$tmp" -c core.excludesFile=/dev/null check-ignore -q --no-index "$p" 2>/dev/null || miss="$miss $p"
  done
  if git -C "$tmp" -c core.excludesFile=/dev/null check-ignore -q --no-index .env.example 2>/dev/null; then
    bad ".gitignore ignores .env.example, which is meant to be committed (add '!.env.example' after '.env.*')"
  fi
  rm -rf "$tmp"
  if [ -z "$miss" ]; then ok ".gitignore covers the secret-bearing files of Step 3"; else bad ".gitignore does not ignore:$miss"; fi
fi

# ------------------------------------------------------------------ lockfiles
eco=""
lock_check() {   # $1 ecosystem key  $2 manifest  $3.. acceptable lockfiles
  local key=$1 manifest=$2; shift 2
  [ -f "$manifest" ] || return 0
  local found="" l
  for l in "$@"; do
    if tracked "$l"; then found=$l; break; fi
  done
  if [ -n "$found" ]; then ok "$manifest has a committed lockfile ($found)"; eco="$eco $key"; return 0; fi
  for l in "$@"; do
    if [ -f "$l" ]; then
      if git check-ignore -q "$l" 2>/dev/null; then bad "$manifest: $l exists but is git-ignored — commit it"
      else bad "$manifest: $l exists but is not committed (git add it)"; fi
      eco="$eco $key"; return 0
    fi
  done
  bad "$manifest has no committed lockfile (one of: $*)"; eco="$eco $key"
}
lock_check uv     pyproject.toml uv.lock poetry.lock pdm.lock pylock.toml
lock_check mix    mix.exs        mix.lock
lock_check cargo  Cargo.toml     Cargo.lock
lock_check npm    package.json   package-lock.json pnpm-lock.yaml yarn.lock
[ -n "$eco" ] || note "no pyproject.toml, mix.exs, Cargo.toml or package.json: no lockfile to check"

# ------------------------------------------------------------------ frozen installs
files=$( { ls .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml 2>/dev/null; ls Containerfile* Dockerfile* 2>/dev/null; find . -maxdepth 3 \( -name 'Containerfile*' -o -name 'Dockerfile*' \) -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null | sed 's#^\./##'; } | sort -u)
has() { case " $eco " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
# (grep -e below: an exemption pattern such as --locked must not be read as an option)
scan() {   # $1 ecosystem  $2 message  $3 grep -E pattern for the offending line  $4 grep -E pattern that EXEMPTS a line
  has "$1" || return 0
  local f hits
  for f in $files; do
    [ -f "$f" ] || continue
    hits=$(grep -nE "$3" "$f" | grep -vE '^[0-9]+:[[:space:]]*#' | { if [ -n "${4:-}" ]; then grep -vE -e "$4"; else cat; fi; })
    [ -z "$hits" ] || { while IFS= read -r h; do bad "$f:${h%%:*}: $2 — $(printf '%s' "${h#*:}" | sed -E 's/^[[:space:]]+//')"; done <<< "$hits"; }
  done
}
scan uv    "uv sync without --frozen or --locked"   'uv sync'                      '(--frozen|--locked)'
scan npm   "npm install in CI/container, use npm ci" 'npm (install|i)([[:space:]]|$)' '(npm (install|i) .*(-g|--global)|npm ci)'
scan cargo "cargo build without --locked"            'cargo build'                   '--locked'
scan mix   "mix deps.get without --check-locked"     'mix deps\.get'                 '--check-locked'
if has mix || has npm || has cargo || has uv; then
  for f in $files; do
    case "$f" in */Containerfile*|*/Dockerfile*|Containerfile*|Dockerfile*) ;; *) continue ;; esac
    hits=$(grep -nE '^[[:space:]]*COPY[[:space:]].*(mix\.lock|package-lock\.json|Cargo\.lock|uv\.lock|yarn\.lock)\*' "$f" | grep -vE '^[0-9]+:[[:space:]]*#')
    [ -z "$hits" ] || { while IFS= read -r h; do bad "$f:${h%%:*}: COPY of a lockfile through an optional glob masks a missing lockfile — $(printf '%s' "${h#*:}" | sed -E 's/^[[:space:]]+//')"; done <<< "$hits"; }
  done
fi
[ -n "$files" ] || note "no CI workflow or Containerfile found: frozen installs not checked"

[ "$fail" -eq 0 ] && ok "all checks passed"
exit "$fail"
```

Exit codes: **0** every check passed; **1** at least one failed. The `.gitignore` is judged in a scratch repository
holding only that file, with your global excludes file off: yours is not the project's, and in a real project a
missing `.DS_Store` pattern passed only because of it. A lockfile counts only if it is tracked; `poetry.lock`,
`pdm.lock`, `pylock.toml`, `pnpm-lock.yaml` and `yarn.lock` are accepted alongside the table's `uv.lock` and
`package-lock.json`. It scans `.github/workflows`, `.gitlab-ci.yml` and `Containerfile*`/`Dockerfile*` for
`uv sync` without `--frozen`/`--locked`, `npm install` (use `npm ci`), `cargo build` without `--locked` and
`mix deps.get` without `--check-locked`, for the ecosystems that have a lockfile. It does **not** read shell scripts
the CI calls, other ecosystems, or a command and its flag split over a backslash-continued line; a flag named
only in a trailing comment on the same line still exempts it.

Wire it as `hygiene: run: scripts/check-hygiene.sh` in the pre-push stage and as a CI step (not exercised here:
the script was run from the command line).

Tested against fixtures with each fault planted (26 cases, bash 5 and 3.2). A first version silently passed three
faults: `grep -vE '--locked'` reads the pattern as an option and fails quietly, so `cargo build` and `mix deps.get`
were never reported; the fixtures caught it, and the script now passes the pattern with `-e`. Run against 12 real
projects, two pass; the rest show gaps in the `.gitignore` list, a git-ignored `package-lock.json` or `uv.lock`
(some projects ignore a lockfile on purpose, which this rule does not allow for), `mix deps.get` without
`--check-locked` in CI and Containerfiles, and the exact `COPY mix.exs mix.lock*` this section warns about. Not yet
run in CI.

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

#### Commit message honesty (t2)

Enforces the mechanical half of `bootstrap-project`'s Rule 2 — *a commit message must not claim more
than the commit contains*.

**The failure it catches**: an edit silently does nothing (a pattern that did not match, a file
already in the target state) while the message, written beforehand, describes it confidently. The
message is then a false record in `git log`, which is exactly where people look when the code no
longer explains itself. The risk is highest when the message is **generated**, because fluent prose
about an intended change reads identically whether or not the change landed.

**The rule, narrowly scoped to stay honest**: a path in backticks that **exists in the working tree
but is not staged** fails the commit. Backticks mean "I am naming this file"; prose references and
non-existent paths are ignored, which keeps false positives near zero.

`.githooks/commit-msg` — no framework needed, and deliberately dependency-free:

```bash
#!/usr/bin/env bash
# Fail when the message names a file in backticks that exists but is not staged.
set -uo pipefail
msg_file="$1"
staged="$(git diff --cached --name-only)"

# Backticked tokens that look like repo-relative paths.
mentioned="$(grep -oE '`[A-Za-z0-9._/-]+`' "$msg_file" 2>/dev/null \
             | tr -d '`' | grep -E '/' | sort -u || true)"

unstaged=""
while IFS= read -r pathname; do
    [ -n "$pathname" ] || continue
    [ -e "$pathname" ] || continue                      # not a real path: prose, ignore
    grep -qxF "$pathname" <<<"$staged" && continue      # staged: fine
    unstaged="${unstaged}${pathname}"$'\n'
done <<<"$mentioned"

if [ -n "$unstaged" ]; then
    echo "✗ commit message names files it does not change:" >&2
    printf '    %s\n' $unstaged >&2
    echo "  Stage them, or drop the backticks if you are only referring to them." >&2
    exit 1
fi
```

Install with `git config core.hooksPath .githooks` (or wire it as lefthook's `commit-msg`).

**Prove it fails before trusting it.** A check that has only ever passed is unproven:

```bash
# Planted bad: name a real, unstaged file in backticks.
other=$(git ls-files | grep -v "$(git diff --cached --name-only | head -1)" | head -1)
printf 'chore: test\n\nTouches `%s`.\n' "$other" > /tmp/m
.githooks/commit-msg /tmp/m; echo "exit=$?   # must be 1"

# Planted good: same message, prose instead of backticks.
printf 'chore: test\n\nTouches %s.\n' "$other" > /tmp/m
.githooks/commit-msg /tmp/m; echo "exit=$?   # must be 0"
```

**What it does not catch**, stated so its silence is not read as approval: a message that overclaims
without naming a path — *"fixed both call sites"* when one edit no-op'd. No hook catches that. The
practice is to re-read the message against `git diff --cached` rather than against your intent, and
the hook only removes the most mechanical slice of the problem.

#### A gate whose tool is missing must fail, not skip

**A gate that cannot run must fail.** The natural template does the opposite:

```bash
if command -v luacheck >/dev/null; then luacheck .; else echo "luacheck not installed — skipping"; fi
```

That exits 0, and lefthook renders exit 0 as a green `✔️` — **indistinguishable from a clean run**.
Measured on lefthook 2.2.2 with `luacheck` off `PATH`: the skipping gate printed `✔️ silent` and the
push proceeded; the failing gate printed `✗ luacheck not found` and lefthook exited 1. On a machine
that never had the tool, the skipping form reports success indefinitely, and the person reading
`✔️` believes a scan ran. Same reasoning as the `gitleaks` hook in the canonical QA baseline: a gate
that quietly does nothing is worse than no gate, because it is trusted.

Source one helper from every gate script, and call it before the tool:

```bash
# scripts/need.sh
# Source from any gate script:  . scripts/need.sh
# need TOOL GATE INSTALL-HINT — fail the gate when its tool is absent; never skip.
need() {
  command -v "$1" >/dev/null 2>&1 && return 0
  {
    echo "✗ $1 not found: the $2 gate cannot run, so this is BLOCKED, not skipped."
    echo "  install: $3"
    echo "  deliberate override (this one time): --no-verify"
  } >&2
  exit 1
}
```

```bash
#!/usr/bin/env bash
# .lefthook/pre-push/gates.sh
. "$(dirname "$0")/../../scripts/need.sh"
need luacheck lint "luarocks install luacheck"
need stylua   format "cargo install stylua"
luacheck . && stylua --check .
```

`--no-verify` is the deliberate override, named in the message so bypassing is a decision rather
than an accident. A project that must not block contributors who lack a *non-essential* tool should
say so in `quality-configuration.md` and enforce that check in CI instead — it should not skip it
quietly in the hook.

**Verify it by taking the tool away.** A gate that has only ever been observed passing is unproven.
Run the hook with the tool off `PATH` and require a non-zero exit **and** the message:

```bash
# lefthook itself must stay reachable; everything else is stripped.
mkdir -p /tmp/bare && ln -sf "$(command -v lefthook)" /tmp/bare/lefthook
PATH=/tmp/bare:/usr/bin:/bin lefthook run pre-push
echo "exit $?"        # expect non-zero, and "not found … BLOCKED" in the output
```

If the exit is 0, a silent-skip form is still in the config: `grep -rnE 'skipping|not installed' .lefthook* lefthook.yml scripts`.

#### Pinned lint tools: a local binary or a container

Contributors and CI may each have neither, one, or the other, at differing versions. A target
hard-coded to `podman run` fails where there is no container runtime; one hard-coded to a local
binary fails where it is absent; and preferring a local binary *of any version* lets the hook and CI
disagree (`validate-quality-config` Step 6b). Select the runner in a fixed order:

1. a **local binary, only if its version equals the pin**;
2. else the **pinned container**, `podman` first, then `docker` (`CONTAINER_RUNTIME` overrides);
3. else **fail**, naming both ways out. Never fall back to a local binary at the wrong version.

```bash
# scripts/pinned-tool.sh
#!/usr/bin/env bash
# Run a lint tool at its PINNED version: a local binary only if its version matches,
# else the pinned container, else fail naming both ways out.
#   usage: pinned-tool.sh TOOL VERSION IMAGE [ARGS...]
#   e.g.:  pinned-tool.sh reuse 6.2.0 docker.io/fsfe/reuse lint
# CONTAINER_RUNTIME overrides the search order (default: podman, then docker).
set -u
tool=$1 version=$2 image=$3
shift 3

if command -v "$tool" >/dev/null 2>&1; then
  # First dotted number in the tool's version output; adjust the flag for tools that
  # spell it differently (`go version`, `-V`). Compared for EQUALITY, never >=.
  have=$("$tool" --version 2>&1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1)
  [ "$have" = "$version" ] && exec "$tool" "$@"
  echo "note: local $tool is ${have:-of unknown version}, pin is $version — not using it" >&2
fi

for rt in ${CONTAINER_RUNTIME:-podman docker}; do
  command -v "$rt" >/dev/null 2>&1 || continue
  # Assumes the image's ENTRYPOINT is the tool; if not, put the tool name first in ARGS.
  exec "$rt" run --rm -v "$PWD:/data" -w /data "$image:$version" "$@"
done

echo "error: $tool $version is required and neither is available." >&2
echo "  install it locally at exactly $version, or install a container runtime (podman or docker)." >&2
exit 1
```

Call it from the Makefile, the hook and CI alike, so all three name the same pin:

```makefile
reuse-lint:
	scripts/pinned-tool.sh reuse 6.2.0 docker.io/fsfe/reuse lint
```

Two limits. The version is compared for **equality**, because a newer tool is what makes a gate
disagree with CI. And `--version` output and image entrypoints vary by tool: run the script once
per tool before trusting it. Verified with stub tools for each branch (matching local, wrong local,
podman, docker only, both, neither, `CONTAINER_RUNTIME` override); the real images were not pulled.

#### lefthook: pre-push gates belong in `scripts:`, not `commands:`

**A repository with more than one remote silently loses its pre-push gates on every remote
after the first.** Measured on lefthook 2.1.10, pushing one branch to three remotes: the
first ran lint, format and 284 test assertions; the second ran them again; the **third ran
nothing** and printed a clean summary —

```text
│  luacheck (skip) no matching push files
│  stylua-check (skip) no matching push files
│  test (skip) no matching push files
```

**Why.** lefthook derives the pre-push file set from **`@{push}`**, which git resolves per
*branch*, not per *remote* — it does not vary with the remote named on the command line.
The first push advances `@{push}`, so every later remote computes an empty diff, and
`commands:` with an empty file set are skipped. Git hands the hook the correct remote refs
on stdin; lefthook does not use them.

Narrowed by reproduction: with no upstream configured both pushes ran; the skip appeared
only once an upstream existed and the first push advanced it.

**Two fixes that do not work**, recorded so they are not retried:

- `skip_empty: false` — **not a recognised key**. lefthook 2.1.10 accepts `commands env
  exclude fail_text files follow glob group interactive jobs only parallel piped priority
  root run scripts skip stage_fixed tags use_stdin`. Setting it changes nothing, silently.
- a `files:` override — the skip is decided before lefthook consults it.

**The fix**: put pre-push gates in `scripts:`, which are not subject to the file-set skip.

```yaml
pre-push:
  parallel: false
  scripts:
    "gates.sh":
      runner: bash
```

with the checks in `.lefthook/pre-push/gates.sh`, each guarded so a missing tool **fails**
rather than passes quietly — see "A gate whose tool is missing must fail, not skip" above.

This is also the more honest shape. Pre-push gates are typically whole-repo checks — a full
test run, a type check, a dependency audit — that never needed a file set, so scoping them
to changed files was buying nothing and costing correctness. Keep `glob:` for **pre-commit**
`commands:`, where staged-file scoping is the point.

**Verify it, do not assume it.** Clone the repo, add two bare local remotes, set an
upstream, commit, and push to both — the gate must run twice:

```bash
git init -q --bare /tmp/R1.git && git init -q --bare /tmp/R2.git
git clone -q . /tmp/probe && cd /tmp/probe
git remote add R1 /tmp/R1.git && git remote add R2 /tmp/R2.git
git push -q R1 HEAD && git push -q R2 HEAD
git branch --set-upstream-to=R1/$(git branch --show-current)
git commit -q --allow-empty -m "probe"
git push R1 HEAD && git push R2 HEAD    # both must run the gate
```

**Applies to lefthook only.** `pre-commit` (the framework) runs `stages: [pre-push]` hooks
per invocation and does not derive files from `@{push}`.

#### Enforcing the DCO: a `commit-msg` gate that rejects

A project that chooses the Developer Certificate of Origin needs the choice enforced, and `public-release`
stops at the decision. The hook **rejects** an unsigned commit; it must never append the trailer for
you. Git deliberately has no `commit.signoff` setting: its FAQ ("Why not have commit.signoff…") argues that
automating the sign-off makes it arguable the trailer was "added out of habit or by automation, without the
committer's full awareness", which undermines what the DCO is for, and calls `format.signoff` "a historical
mistake". So the person types `git commit -s`, and the hook makes forgetting impossible to miss.

```yaml
commit-msg:
  commands:
    dco-signoff:
      # {1} is the path to the prepared commit message
      run: >
        if [ -f "$(git rev-parse --git-dir)/MERGE_HEAD" ]; then
          exit 0;
        elif grep -qiE '^Signed-off-by: .+ <[^>]+@[^>]+>' "{1}"; then
          exit 0;
        else
          echo "FAIL: no Signed-off-by trailer — this project uses the DCO.";
          echo "  sign off:  git commit -s";
          echo "  fix last:  git commit -s --amend --no-edit";
          exit 1;
        fi
```

A merge in progress is exempt. The hook checks only that a well-formed trailer is **present**; it
does not compare signer to author, which needs the commit's metadata. That comparison, the bot exemption
and the pull-request side (a contributor runs none of your hooks) live in `check-dco.sh`, in
`harden-github-actions` Step 8b.

Tested with `lefthook run commit-msg <message-file>` on lefthook 2.2.2: unsigned → exit 1; signed → 0; a
trailer with no email → 1; a merge in progress → 0. A lowercase `signed-off-by:` is accepted by the hook, and by `check-dco.sh`, which reads trailers
through git's own parser.

#### A DCO sign-off hook is not an agent's to satisfy

A project using the **Developer Certificate of Origin** enforces it with a `commit-msg`
hook that rejects any commit lacking a `Signed-off-by:` trailer. If you are an assistant
working in such a repository, that rejection is **not** a lint failure to route around.

**Never run `git commit -s`. Never write the trailer.** The DCO is an attestation by a
*person* that they have the right to submit the work under the project's licence. An agent
adding it asserts something it has no standing to assert, in the maintainer's name, and
records that claim permanently in a public history — which is precisely where a future
licence audit will read it as a human's word.

**Hand the work back unsigned.** Stage it, or commit to a scratch branch, say plainly that
it needs a sign-off, and let the human run `git commit -s` or
`git rebase --signoff <base>` after reading the diff. Losing a few seconds is the whole
cost; the alternative is a false attestation that is expensive to unwind once pushed.

`Co-Authored-By:` and `Assisted-by:` are different in kind — they record tool assistance
and assert no right to submit, so an agent may add those freely.

**Write the rule down where an agent will meet it**, not only in `CONTRIBUTING.md`, which
an agent may never open. The project's `CLAUDE.md` (or equivalent agent instructions) is
the file that is actually loaded, and the two should agree:

```markdown
### Never sign off on the human's behalf

Do not run `git commit -s`. Do not write a `Signed-off-by:` trailer. When the commit-msg
hook blocks you for a missing sign-off, hand the work back unsigned and say so.
```

**The hook cannot tell a human from an agent**, so this remains an instruction rather than
an assertion — the gap worth knowing about. A stronger guard compares the committer
identity against the signer, or refuses when an agent's environment marker is present.

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
  # SINGLE-REMOTE SHAPE. With more than one remote, move these into `scripts:` —
  # `commands:` are skipped on every remote after the first. See "pre-push gates
  # belong in scripts:, not commands:" above.
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
  # SINGLE-REMOTE SHAPE. With more than one remote, move these into `scripts:` —
  # `commands:` are skipped on every remote after the first. See "pre-push gates
  # belong in scripts:, not commands:" above.
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
  # SINGLE-REMOTE SHAPE. With more than one remote, move these into `scripts:` —
  # `commands:` are skipped on every remote after the first. See "pre-push gates
  # belong in scripts:, not commands:" above.
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
- [ ] (DCO projects) a `commit-msg` gate that rejects an unsigned commit — and the PR-side job from `harden-github-actions` Step 8b
- [ ] `scripts/need.sh` (a missing tool fails the gate) and, where a lint tool is pinned, `scripts/pinned-tool.sh`
- [ ] `{:mix_audit, ...}` added to `mix.exs` deps (Elixir CVE-audit prerequisite)
- [ ] Dependency audit enforced in a CI `audit` job (not hook-only) + scheduled re-run
- [ ] `scripts/check-hygiene.sh` exits 0 — ecosystem lockfile committed, frozen/locked installs in CI + containers, `.gitignore` covering Step 3
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

# Prove each gate can fail: run it with its tool off PATH (see "A gate whose tool is missing")
PATH=/tmp/bare:/usr/bin:/bin lefthook run pre-push; echo "exit $?"   # expect non-zero

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
