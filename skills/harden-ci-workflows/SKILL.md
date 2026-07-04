---
name: harden-ci-workflows
description: Harden GitHub Actions CI/CD workflows for supply-chain security — SHA-pin actions, least-privilege token permissions, verified toolchain installs, OpenSSF Scorecard, and SLSA provenance. Use when adding or auditing CI workflows, before making a repository public, when a supply-chain review flags CI gaps, or when standardizing CI hardening across projects.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.14"
license: MIT
---

# Harden CI Workflows

Harden GitHub Actions CI/CD workflows against supply-chain attack: pin what runs, minimise what it can do, and verify what it fetches.

## When to Use

- When adding CI workflows to a project (after `setup-pre-commit`)
- When auditing existing `.github/workflows/` before making a repository public
- When a supply-chain review (or the `supply-chain` skill) flags CI hardening gaps
- When standardising CI hardening across projects

This skill *hardens* CI workflows. `validate-quality-config` only *reads* CI to confirm parity with local hooks — it does not check pinning, permissions, or provenance. The two are complementary.

## Required Inputs

1. **Workflow files** — the project's `.github/workflows/*.yml`
2. **Release model** — does the project publish artifacts/images/packages (needs provenance + signing), or is it internal-only?
3. **Repository visibility** — public or private (affects Scorecard `publish_results` and OSSF publishing)

## The Threat

A CI job runs third-party code (actions, installed tools) with a `GITHUB_TOKEN` and often OIDC. A mutable action tag (`@v4`) can be repointed to malicious code; an over-privileged token can push commits, publish packages, or exfiltrate secrets; an unverified `curl | sh` install can be swapped upstream. Hardening closes all three: **pin**, **least-privilege**, **verify**.

## Workflow

### Step 1: Inventory and triage

Find every workflow and the hardening gaps in it:

```bash
ls .github/workflows/
# Mutable action refs (should be zero — all must be SHA-pinned):
grep -rnE 'uses:.*@(v[0-9]|main|master|latest)' .github/workflows/
# Workflows missing a top-level permissions block:
for f in .github/workflows/*.yml; do grep -q '^permissions:' "$f" || echo "no permissions: $f"; done
# Floating tool versions:
grep -rnE 'version:\s*latest|@latest' .github/workflows/
```

Aim for a clean 3-way split: **`ci.yml`** (lint/test/build on push + PR), **`scorecard.yml`** (OpenSSF Scorecard on a schedule), and — only if the project ships artifacts — **`release.yml`** (SBOM + SLSA provenance + signing).

### Step 2: SHA-pin every action

Pin every `uses:` to a **full 40-character commit SHA** with a trailing `# vX.Y.Z` comment for readability. Never rely on a mutable tag.

```yaml
# Good — immutable, human-readable, Dependabot-updatable
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
- uses: actions/setup-java@ad2b38190b15e4d6bdf0c97fb4fca8412226d287 # v5.3.0
- uses: gradle/actions/setup-gradle@3f131e8634966bd73d06cc69884922b02e6faf92 # v6.2.0

# Bad — mutable tag, can be repointed upstream
- uses: actions/checkout@v4
```

Resolve a tag to its commit SHA:

```bash
gh api repos/actions/checkout/commits/v4.2.2 --jq '.sha'
```

Keep pins current automatically with a Dependabot `github-actions` update block (see `bootstrap-project` / the dependency-update config). Dependabot preserves the `# vX.Y.Z` comment when it bumps a SHA.

**The one sanctioned exception**: reusable workflows that verify their own release tag — notably `slsa-framework/slsa-github-generator` — **must** be referenced by semantic version tag, not SHA (see Step 7). Document the exception in an ADR and in a comment on the line.

### Step 3: Least-privilege token permissions

Set a read-only default at the top of every workflow, then elevate **per job** only where a job genuinely needs to write.

```yaml
# top of the workflow
permissions:
  contents: read
```

Elevate narrowly, in the specific job:

```yaml
jobs:
  # OpenSSF Scorecard
  analysis:
    permissions:
      security-events: write   # upload the SARIF result
      id-token: write          # publish results to the OSSF API
      contents: read

  # Release provenance / publish
  provenance:
    permissions:
      actions: read            # read the workflow path
      id-token: write          # mint the OIDC token for signing
      contents: write          # attach provenance to the release
      # packages: write        # add only if publishing to GHCR / a registry
```

Rule of thumb: default `contents: read`; add `id-token: write` only for OIDC signing/publish; add `contents: write` only for jobs that create releases/tags; add `packages: write` only for registry publish; add `security-events: write` only for SARIF upload.

### Step 4: Harden the checkout

On any workflow that runs with elevated permissions or handles releases (Scorecard, release), stop the checkout from leaving credentials on disk:

```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
  with:
    persist-credentials: false
```

### Step 5: Verify what you install

Every tool a job installs is attack surface. In order of preference:

1. **SHA-pinned setup action** (best) — toolchains via pinned actions:
   ```yaml
   - uses: actions/setup-java@ad2b38190b15e4d6bdf0c97fb4fca8412226d287 # v5.3.0
     with: { distribution: temurin, java-version: "21" }
   - uses: xu-cheng/texlive-action@22c04326a5d855880f9d39bb955138bf11c6df80 # v3
   ```
2. **Pinned version + checksum verification** for a downloaded binary:
   ```yaml
   - run: |
       curl -fsSL -o tool.tar.gz "https://example.com/tool/v1.2.3/tool.tar.gz"
       echo "abc123...  tool.tar.gz" | sha256sum -c -
       tar xzf tool.tar.gz
   ```
3. **Pinned package version** for distro/language packages.

Anti-patterns to eliminate (all seen in real workflows):

```yaml
- run: luarocks install luacheck            # no version pin
- run: apt-get install -y -qq pandoc        # unversioned distro package
  with: { version: latest }                 # floating action release
- run: curl -fsSL https://x/install.sh | sh # unverified remote script — never
```

Digest-pin any container image referenced in a `run`/service step (`image@sha256:…`, not `:latest`); base-image and artifact-checksum hardening for the images themselves belongs to `setup-container-security`.

### Step 6: OpenSSF Scorecard

Add a Scorecard workflow to continuously grade the repo's supply-chain posture. Canonical `scorecard.yml`:

```yaml
name: Scorecard
on:
  branch_protection_rule:
  schedule:
    - cron: "26 7 * * 1"   # weekly, Mondays
  workflow_dispatch:

permissions: read-all

jobs:
  analysis:
    runs-on: ubuntu-latest
    permissions:
      security-events: write   # upload the SARIF result
      id-token: write          # publish results to the OSSF API
      contents: read
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
        with:
          persist-credentials: false
      - uses: ossf/scorecard-action@4eaacf0543bb3f2c246792bd56e8cdeffafb205a # v2.4.3
        with:
          results_file: results.sarif
          results_format: sarif
          publish_results: true   # requires a PUBLIC repo; keep false while private
      - uses: github/codeql-action/upload-sarif@dd903d2e4f5405488e5ef1422510ee31c8b32357 # v3
        with:
          sarif_file: results.sarif
```

On a **private** repo set `publish_results: false` and flip it to `true` at public release.

### Step 7: Release provenance (if the project ships artifacts)

For projects that publish artifacts/images/packages, attach SLSA build provenance at release. Hash the build outputs, then hand off to the generator — referenced **by tag** (the sanctioned exception to Step 2):

```yaml
  provenance:
    needs: [build]
    permissions:
      actions: read
      id-token: write
      contents: write
    # slsa-github-generator MUST be tag-pinned (it verifies its own release tag) — the
    # documented exception to the SHA-pin rule; record it in an ADR.
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
    with:
      base64-subjects: ${{ needs.build.outputs.hashes }}
      upload-assets: true
```

Provenance, SBOM (syft), and keyless signing (cosign) at release time are owned by `wrapup-sprint`'s release step — this skill wires the workflow permissions and the tag-pin exception that make them safe.

### Step 8: Remaining hardening

- **Dependency review** on PRs:
  ```yaml
  dependency-review:
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/dependency-review-action@3b139cfc5fae8b618d3eae3675e383bb1769c019 # v4.5.0
  ```
- **Cancel superseded runs** — add a `concurrency` block per workflow:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: true
  ```
- **Bound every job** with `timeout-minutes:` (a runaway job holds a token).
- **Short artifact retention**: `retention-days: 5` on `upload-artifact`.
- **Optional egress control**: `step-security/harden-runner` (SHA-pinned) to audit/block network egress.
- **CodeQL** code scanning (`codeql-action/init` + `analyze`) for compiled/scripted languages — note: uploading a Scorecard SARIF is *not* code scanning.

## Outputs

This skill produces/updates:
- [ ] All `uses:` in `.github/workflows/*` SHA-pinned with `# vX.Y.Z` comments (grep for `@v[0-9]`/`@main` returns nothing except the SLSA generator)
- [ ] Top-level `permissions:` (read-only default) on every workflow, with narrow per-job elevation
- [ ] `persist-credentials: false` on release/Scorecard checkouts
- [ ] Verified/pinned toolchain installs; no `curl | sh`, no `version: latest`
- [ ] `.github/workflows/scorecard.yml`
- [ ] `.github/workflows/release.yml` provenance job (if the project ships artifacts)
- [ ] `concurrency` + `timeout-minutes` on workflows/jobs
- [ ] An ADR line documenting the SHA-pin policy and the SLSA-generator tag exception

## Validation

```bash
# No mutable action refs remain (SLSA generator is the only allowed tag ref):
grep -rnE 'uses:.*@(v[0-9]|main|master|latest)' .github/workflows/ | grep -v slsa-github-generator
# Every workflow declares permissions:
for f in .github/workflows/*.yml; do grep -q '^permissions:' "$f" || echo "MISSING permissions: $f"; done
# No unverified remote installs:
grep -rnE 'curl.*\|\s*(sh|bash)' .github/workflows/
```

Optionally run `actionlint` for workflow-syntax validation, and check the repo's OpenSSF Scorecard once the workflow has run.

## Related Skills

- `setup-pre-commit` — local quality gates that CI mirrors
- `validate-quality-config` — verifies CI/local parity (reads CI; does not harden it)
- `wrapup-sprint` — release-time SBOM, SLSA provenance, and signing
- `setup-container-security` — base-image digest pinning and image scanning
- `setup-adrs` — record the SHA-pin policy and the SLSA-generator exception
