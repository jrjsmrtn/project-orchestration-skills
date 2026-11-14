---
name: harden-github-actions
description: Harden GitHub Actions CI/CD workflows for supply-chain security — SHA-pin actions, least-privilege token permissions, verified toolchain installs, OpenSSF Scorecard, and SLSA provenance. Use when adding or auditing GitHub Actions workflows, before making a repository public, when a supply-chain review flags CI gaps, or when standardizing CI hardening across GitHub projects. GitHub-specific by design — GitLab CI and Forgejo Actions are out of scope.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.46"
license: MIT
---

# Harden GitHub Actions

Harden GitHub Actions CI/CD workflows against supply-chain attack: pin what runs, minimise what it can do, and verify what it fetches.

> **GitHub-specific by design.** Unlike most orchestration skills, this one is deliberately bound to
> one forge. The hardening controls below are not portable concepts wearing GitHub syntax — they are
> properties of the GitHub Actions execution model itself: third-party actions resolved by mutable
> git ref, an ambient `GITHUB_TOKEN` with **repository-wide default scopes**, and OIDC-backed SLSA
> provenance. It has a **sibling**, `harden-gitlab-ci`, which is not a translation of this skill:
> GitLab's risks sit in different places (`include:`/CI-Catalog components, and a `CI_JOB_TOKEN` that
> defaults to *own-project-only* — so there the work is keeping it scoped, the opposite posture from
> here). Forgejo Actions is Actions-compatible in shape but resolves actions against its instance's
> configured registry, so pinning guidance does not transfer unchanged (roadmap H9).

## When to Use

- When adding GitHub Actions workflows to a project (after `setup-git-hooks`)
- When auditing existing `.github/workflows/` before making a repository public
- When a supply-chain review (or the `supply-chain` skill) flags CI hardening gaps
- When standardising CI hardening across GitHub projects

**Not for:** GitLab CI — use `harden-gitlab-ci`. Not for Forgejo/Gitea Actions — the controls do not carry over unchanged. Say so rather than approximating.

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

Keep pins current automatically with a Dependabot `github-actions` update block (see `bootstrap-project` / the dependency-update config).

**Dependabot keeps the `# vX.Y.Z` comment as it was — that is the hazard, not a convenience.** It is
only safe *within* a major. Observed (August 2026): Dependabot moved a `github/codeql-action/upload-sarif`
pin from a `v3` SHA to the SHA that `v4.37.6` resolves to, and left the comment reading `# v3`. The
workflow then ran v4 code labelled v3. It is invisible in review — the diff shows a SHA change and an
unchanged comment, which is exactly what a normal bump looks like. Only resolving the tag catches it.

So:

- Label each pin with an **exact patch tag** (`# v4.37.6`), not a floating major (`# v4`). A major alias
  *moves*, so a comment naming it can never be shown wrong.
- **Assert the label is true** in CI (Step 2b), rather than trusting a comment.
- **Never write a SHA by hand or from memory.** Resolve it with the `gh api` command above. A wrong SHA
  is precisely the failure pinning exists to prevent.

### Step 2b: Audit the pin labels

A pin's comment is a claim. This check resolves it: every `uses:` must be a 40-hex SHA, carry a tag
comment, and that tag must resolve to that SHA.

The script is [`scripts/check-action-pins.sh`](scripts/check-action-pins.sh), in this skill's directory. Copy it into the project as `scripts/check-action-pins.sh` rather than retyping it, and run it from the repository root.

Run it as a CI job so it gates the merge (it needs `gh`, which the GitHub-hosted Ubuntu runner image includes):

```yaml
  action-pins:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha of the exact tag> # vX.Y.Z   # resolve it; do not type it
        with:
          persist-credentials: false
      - run: scripts/check-action-pins.sh
        env:
          GH_TOKEN: ${{ github.token }}   # `gh api` resolves each tag to its commit
```

Exit codes: **0** all pins true; **1** an unpinned, unlabelled or mislabelled action; **2** it could not
run (no `gh`, no auth, no `uses:` found) — a checker that checked nothing must not pass. A floating-major
label is reported as a warning, not an error. It skips local (`./`) and `docker://` references and the SLSA generator, whose tag reference is the sanctioned exception below.

Proven before it was written down, against live GitHub tags: a correct pin → 0; a `v3.6.0` SHA labelled
`v4.2.2` (the Dependabot case) → 1; a mutable tag → 1; no comment → 1; an unresolvable tag → 1; no
`uses:` at all → 2; `gh` off `PATH` → 2. Not yet run as a GitHub Actions job.

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
4. **Hash-verified install** where the ecosystem has one — see below for Python. It is the strongest
   form of 3, and the easiest to claim without having.

#### Python: `--require-hashes` needs a lockfile you generate

`pip install --require-hashes -r requirements-ci.txt` is only a control if `requirements-ci.txt`
carries a hash for **every** package, transitive ones included. A hand-written list of pins is not
that, and writing the flag without the file produces a control that does not exist. Measured with
pip 26.2.2:

```text
$ pip install --require-hashes jsonschema==4.23.0
ERROR: Hashes are required in --require-hashes mode, but they are missing from some requirements.
```

Generate the file; never write it:

```bash
# requirements.in lists your direct dependencies, unpinned.
uv pip compile requirements.in --generate-hashes --universal --no-header -o requirements-ci.txt
python -m pip install --require-hashes -r requirements-ci.txt      # in CI
```

**`--universal` matters, and the reason is dependency markers, not wheels.** A lockfile compiled for
one platform omits the dependencies other platforms need. Measured on `ipykernel`: the lockfile
compiled for `x86_64-unknown-linux-gnu` had no `appnope` (a macOS-only dependency), and installing
it on macOS failed with *"all requirements must have their versions pinned with =="*. The
`--universal` file kept `appnope` under `; sys_platform == 'darwin'` and installed cleanly on macOS.
Hashes were not the issue: the lockfile hashed every wheel of a release (128 for `rpds-py`) whether
compiled for Linux or universally. Tested on macOS arm64 only; installing the universal file on Linux
was not run. `uv` 0.13.0 was used; `pip-compile --generate-hashes` from pip-tools is the other common
route and was not tested here.

**Assert the lockfile is not stale** — otherwise it quietly stops matching `requirements.in`:

```bash
cp requirements-ci.txt /tmp/lock.check
uv pip compile requirements.in --generate-hashes --universal --no-header -q -o /tmp/lock.check
diff -q requirements-ci.txt /tmp/lock.check     # non-zero (and a message) means regenerate and commit
```

Compiling into a copy of the existing lockfile keeps its pins, so the diff is empty unless
`requirements.in` changed. Measured: unchanged → exit 0; a dependency added to the `.in` → non-zero.

**If you cannot generate the lockfile, say so.** Pin the exact version (`tool==1.2.3`), record in
`quality-configuration.md` that hashes are *not* verified, and do not claim `--require-hashes`.

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

On a **private** repo set `publish_results: false` — but note that several Scorecard *checks* also fail to run while private (`Resource not accessible by integration`); prefer gating the whole job on visibility so it self-activates at the public gate (see **Step 7b**).

**Scorecard grades the default branch — mind gitflow.** Scorecard's content analysis runs against the
repository's **default branch** (a `workflow_dispatch` against another ref is refused with `only default
branch is supported` — observed directly). If the project follows the gitflow that `bootstrap-project`
sets up, `develop` is the default, so the published score describes the **integration** branch, not the
`main` that releases are cut from — the repo is graded on a branch its consumers never fetch. The one
documented exception is the **`Branch-Protection`** check, which evaluates a project's *default **and**
release* branches (verified against the Scorecard docs); the content-analysis checks
(`Pinned-Dependencies`, `Dangerous-Workflow`, `Token-Permissions`, …) do not. Two honest resolutions:
accept that `develop` is graded and protect/harden it accordingly, or make `main` the default and treat
`develop` as a long-lived branch. Pick one on purpose — this gap lives only where the gitflow
recommendation and the Scorecard workflow meet, so neither skill alone would surface it.

### Step 7: Release provenance (if the project ships artifacts)

For projects that publish artifacts/images/packages, attach SLSA build provenance at release. Hash the build outputs, then hand off to the generator — referenced **by tag** (the sanctioned exception to Step 2):

```yaml
  provenance:
    # MUST run after the job that creates the release: with upload-assets:true the generator
    # creates the release itself when absent, racing publish and producing a bare, notesless one.
    needs: [build, publish]
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

Provenance, SBOM (syft), and keyless signing (cosign) at release time are owned by `wrapup-sprint`'s release step — this skill wires the workflow permissions and the tag-pin exception that make them safe. Note the `needs: [build, publish]` above: because `upload-assets: true` makes the generator *create* the release when it runs first, provenance must follow the job that publishes it with changelog notes — the idempotent create-release step is detailed in `wrapup-sprint`.

### Step 7b: Private repositories — gate visibility-sensitive controls

Several controls above behave differently while the repo is private, for **two distinct reasons** —
*cannot run* and *should not run* — and neither is obvious until you run them (the failures arrive at
the first scheduled Scorecard run and Dependabot's first PR). The honest default is to **self-activate
them at the public gate** rather than leave a manual step to remember. Gate the job (or step) on
visibility:

```yaml
if: ${{ !github.event.repository.private }}   # runs only when the repo is public
```

| Control | While private | Why | Public |
|---------|---------------|-----|--------|
| **OpenSSF Scorecard** (Step 6) | Several checks **cannot run** — `Resource not accessible by integration` (Branch-Protection / Contributors query an API the default `GITHUB_TOKEN` cannot reach on a private repo). The workaround is a **PAT**: a long-lived secret added only to grade a repo whose results can't be published anyway. | Elevated read scopes the default token lacks on private repos. | Runs on the default token; set `publish_results: true`. |
| **Keyless cosign / SLSA provenance** (Step 7) | *Works, but should not run.* Sigstore writes the signing identity — **repo name + workflow path** — to **Rekor, a public append-only transparency log**. Signing a private repo's artifacts publishes exactly what privacy protects. | Rekor is public by design; keyless certs embed the source identity. | Sign + attest freely — the identity is already public. |
| **dependency-review** (CI, owned by `public-release`) | Needs **GitHub Advanced Security** on private repos; errors without it (surfaces on Dependabot's first PR). | The dependency-review API is GHAS-gated for private repos. | Works on public repos with no GHAS. |

Prefer the `if:` gate over hard-coded toggles like `publish_results: false`: the control flips itself
the instant the repo goes public, with nothing to remember. (Scorecard's `publish_results` boolean is
the one field that still needs an explicit value alongside the gate.)

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

### Step 8b: DCO sign-off on pull requests (projects that use the DCO)

A `commit-msg` hook (see `setup-git-hooks`) covers the maintainer's own commits. **A contributor runs
none of your hooks**, so the enforcement point for pull requests is CI. Three details decide whether
it works:

- **Reject, never append.** The job fails an unsigned commit; it does not add a trailer.
- **Match the signer to the author**, case-insensitively. A sign-off by someone else certifies
  nothing about the commit's author.
- **Exempt bots from the match, not from the trailer.** Dependabot signs as
  `dependabot[bot] <support@github.com>` while authoring as
  `<id>+dependabot[bot]@users.noreply.github.com`, so a strict author match **blocks every dependency
  PR**. Observed on a live pull request, not predicted. Merge commits are exempt entirely: a merge
  certifies nothing about the merged work.

The script is [`scripts/check-dco.sh`](scripts/check-dco.sh), in this skill's directory. Copy it into the project as `scripts/check-dco.sh` rather than retyping it, and run it from the repository root.

```yaml
  dco:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha of the exact tag> # vX.Y.Z   # resolve it; do not type it
        with:
          fetch-depth: 0            # the script needs both PR endpoints; a shallow clone exits 2
          persist-credentials: false
      - env:
          BASE_SHA: ${{ github.event.pull_request.base.sha }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha }}
        run: scripts/check-dco.sh "$BASE_SHA" "$HEAD_SHA"
```

The refs go through `env:` rather than being interpolated into the command line — the shape the
workflow-injection guidance asks for, even though both are SHAs GitHub computes.

Proven locally against a scratch repository: unsigned → 1; signed → 0; signer differing from author → 1;
bot with a different signer → 0; bot with no trailer → 1; a case-differing email → 0; a merge commit
exempt; an unresolvable base → 2 (so a shallow clone fails instead of passing on zero commits).
Not yet run as a GitHub Actions job.

## Outputs

This skill produces/updates:
- [ ] All `uses:` in `.github/workflows/*` SHA-pinned with `# vX.Y.Z` comments (grep for `@v[0-9]`/`@main` returns nothing except the SLSA generator)
- [ ] `scripts/check-action-pins.sh` and an `action-pins` CI job: every pin's comment is the tag its SHA really is
- [ ] (DCO projects) `scripts/check-dco.sh` and a `dco` PR job
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
# Every pin's comment is true (expect exit 0; exit 2 means it did not run, which is a failure):
scripts/check-action-pins.sh
# Every workflow declares permissions:
for f in .github/workflows/*.yml; do grep -q '^permissions:' "$f" || echo "MISSING permissions: $f"; done
# No unverified remote installs:
grep -rnE 'curl.*\|\s*(sh|bash)' .github/workflows/
```

Optionally run `actionlint` for workflow-syntax validation, and check the repo's OpenSSF Scorecard once the workflow has run.

## Related Skills

- `harden-gitlab-ci` — the sibling for GitLab CI. Same intent, different execution model; neither is a translation of the other (GitLab's risks sit in `include:`/CI-Catalog components and the `CI_JOB_TOKEN` allowlist)
- `setup-git-hooks` — local quality gates that CI mirrors
- `validate-quality-config` — verifies CI/local parity (reads CI; does not harden it)
- `wrapup-sprint` — release-time SBOM, SLSA provenance, and signing
- `setup-container-security` — base-image digest pinning and image scanning
- `setup-adrs` — record the SHA-pin policy and the SLSA-generator exception
