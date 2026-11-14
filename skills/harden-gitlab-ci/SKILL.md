---
name: harden-gitlab-ci
description: Harden GitLab CI/CD pipelines for supply-chain security — SHA-pin `include:` and CI/CD components, scope the `CI_JOB_TOKEN` allowlist, protect and mask variables, pin job image digests, and use `id_tokens`/OIDC instead of long-lived secrets. Use when adding or auditing a `.gitlab-ci.yml`, before making a GitLab project public, when a supply-chain review flags CI gaps, or when standardizing pipeline hardening across GitLab projects (gitlab.com or self-hosted). GitLab-specific by design — for GitHub Actions use `harden-github-actions`; Forgejo/Gitea Actions are out of scope.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.47"
license: MIT
---

# Harden GitLab CI

Harden GitLab CI/CD pipelines against supply-chain attack: pin what runs, minimise what it can reach, and stop long-lived secrets from existing at all.

> **GitLab-specific by design.** Like `harden-github-actions`, this skill is deliberately bound to one
> forge. The controls are properties of the GitLab CI execution model — `include:` resolution, the
> `CI_JOB_TOKEN` allowlist, project/group variable scoping, `id_tokens` — not portable concepts in
> GitLab syntax. It is a **sibling** of `harden-github-actions`, not a translation of it: the two
> forges differ in what the risks *are*, not merely in how they are spelled.

## When to Use

- When adding a `.gitlab-ci.yml` to a project (after `setup-git-hooks`)
- When auditing an existing pipeline before making a GitLab project public
- When a supply-chain review (or the `supply-chain` skill) flags CI hardening gaps
- When standardising pipeline hardening across GitLab projects

**Not for:** GitHub Actions (use `harden-github-actions`) or Forgejo/Gitea Actions. The controls do not carry over — say so rather than approximating.

## Required Inputs

1. **Repository** — a GitLab project (auto-detected from git remotes). **Self-hosted GitLab is a
   first-class target**, not an exception: authenticate once and every control below is identical.
2. **Project visibility** — public/internal or private. Phases 3 and 4 branch on it: public and
   internal projects expose pipeline artifacts to unauthenticated users, and fork merge requests are
   the main variable-exfiltration route.
3. **Scope** — what to run:
   - `audit` — report findings against the checklist below; **no writes** (default)
   - `fix` — apply the mechanical fixes (pin includes/components/images), leave judgment calls to the maintainer
   - `full` — `audit`, then `fix` after confirmation

## The GitLab Threat Model — What Actually Differs

Where the risk sits differs from GitHub Actions; the controls are not one-for-one equivalents:

| Concern | GitHub Actions | GitLab CI |
|---|---|---|
| Third-party code execution | `uses: actions/x@ref` from the Marketplace | **`include:` + CI/CD Catalog components** — same class of risk, different keyword |
| Ambient credential | `GITHUB_TOKEN` with repo-wide default scopes | **`CI_JOB_TOKEN`** — defaults to *own project only*; risk is a widened allowlist |
| Secret exfiltration surface | workflow can read all repo secrets | **variable scoping** — protected/masked/environment-scoped, plus fork-MR exposure |
| Provenance / keyless auth | OIDC via `id-token: write` | **`id_tokens:` with an `aud` claim** |
| Runner trust | GitHub-hosted vs self-hosted | **shared vs group/project runners**, `privileged` Docker, `shell` executor |

> **GitLab has a marketplace-shaped supply chain**: the **CI/CD Catalog** of components. Assuming
> otherwise — that only GitHub has this problem — skips the pinning discipline entirely. GitLab's
> own docs (*CI/CD components → Best practices*) say to "Pin CI/CD components to a specific commit
> SHA (preferred) or release version tag to ensure the integrity of the component used in a
> pipeline."

## Workflow

### Phase 1: Detect Context

1. Confirm the forge is GitLab and the CLI is authenticated:
   ```bash
   git remote -v
   glab auth status                      # self-hosted: glab auth login --hostname gitlab.internal.example
   ```
   If the remote is GitHub or Forgejo, **stop** and point at the right sibling skill.
2. Locate the pipeline config. `glab ci lint` **defaults to `.gitlab-ci.yml` in the current
   directory**, but a project may relocate it (Settings → CI/CD → General pipelines → CI/CD
   configuration file). If it is relocated, `cd` to its directory or pass its path/URL — a bare
   lint would silently validate the wrong file, or nothing.
3. Validate it parses before changing anything:
   ```bash
   glab ci lint                      # or: glab ci lint <path-or-url>
   ```
4. Inventory the third-party surface — run these and triage every hit (`CONFIG` = the config path).
   **These greps explore; they do not gate**, and they are noisy: the image/service pattern also
   matches the `name:` of an artifact (a real config produced `name: "current-${CI_COMMIT_TAG}"` as a
   hit), and the `include: project` one only lists the lines to read. The gating form of the
   pin checks is `scripts/check-gitlab-pins.sh` (Phase 2b), which reads the YAML instead of the text.

   ```bash
   # Components/includes on a moving target: ~latest, a partial semver, or a branch
   grep -nE '@(~latest|[0-9]+(\.[0-9]+)?$|main|master)' "$CONFIG"

   # include: project blocks — then confirm each has a `ref:` pinned to a 40-char SHA.
   # A missing ref: is a finding: it silently defaults to the target project's HEAD.
   grep -nA3 'include:' "$CONFIG" | grep -E 'project:|ref:'
   grep -nE '^\s*ref:\s*(?![0-9a-f]{40}\s*$)' -P "$CONFIG"   # ref: present but not a SHA

   # Remote includes — no auth, no ref to pin; each one is a trust-boundary decision
   grep -nE '^\s*-?\s*remote:' "$CONFIG"

   # Images/services not pinned by digest (covers `image:` and `- name:` service entries;
   # the negative lookahead is what keeps already-pinned `foo:1@sha256:…` from false-positiving)
   grep -nPE '^\s*-?\s*(image|name):\s*(?!.*@sha256:)' "$CONFIG"

   # Deprecated JWTs (see Phase 5) and inline secrets
   grep -nE 'CI_JOB_JWT' "$CONFIG"

   # Runner isolation escapes
   grep -nE 'privileged:\s*true|executor:\s*shell' "$CONFIG" .gitlab-runner/*.toml 2>/dev/null
   ```

   Treat every hit as a finding to justify or fix — not as noise to skim.

### Phase 2: Pin the Third-Party Supply Chain

This is the highest-value control — the direct analogue of SHA-pinning actions.

**CI/CD components** (`include: component`) — pin to a **commit SHA**:

```yaml
include:
  # BAD — a moving target; ~latest re-resolves on every run
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@~latest

  # GOOD — immutable
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@e3262fdd0914fa823210cdb79a8c421e2cef79d8
```

Version resolution precedence, and why `~latest` is unsafe: a **commit SHA** is exact; a **tag**
(`1.0.0`) is mutable unless the project protects its tags — and if a tag and SHA share a name, the
SHA wins; a **branch** is fully mutable; `~latest`/partial semver re-resolves to whatever the Catalog
last published. Prefer SHA; accept a release tag only when the component project protects tags.

**`include: project`** — `ref:` accepts a branch, tag, **or commit SHA**. Pin it:

```yaml
include:
  - project: 'my-group/ci-templates'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b   # not `main`
    file: '/templates/build.yml'
```

`ref:` is optional and **defaults to the project's HEAD** — an unpinned `include: project` silently
tracks someone else's default branch. Treat a missing `ref:` as a finding, not a style nit.

**`include: remote`** — a public URL fetched over HTTP(S) with **no authentication support**. It is
the weakest link: whoever controls that URL controls your pipeline, and there is no ref to pin.
Prefer `component` or `project`. If a remote include is unavoidable, use a URL that embeds an
immutable revision (a raw file path containing a commit SHA, not `/raw/main/`), and treat the host as
part of your trust boundary.

**`include: template`** and **`include: local`** are GitLab-shipped or in-repo — no pinning needed.

**Resolving a tag to a SHA** — for a component or template project:

```bash
# .id is the full commit SHA; :sha accepts a branch or tag name
glab api "projects/my-org%2Fsecurity-components/repository/commits/1.0.0" --jq '.id'
```

`:fullpath` also works in place of the URL-encoded path when acting on the current project. For a
non-GitLab-hosted template, `git ls-remote <url> refs/tags/<tag>` resolves the same thing.

**Job images and services** — pin by digest, keeping the tag for readability:

```yaml
# BAD — mutable
image: python:3.13
services:
  - postgres:18
```

```yaml
# GOOD — immutable, still readable
image: python:3.13@sha256:<digest>
services:
  - name: postgres:18@sha256:<digest>
```

Resolve digests with `skopeo inspect docker://python:3.13 --format '{{.Digest}}'`. This mirrors
`setup-container-security`'s base-image rule; the reasoning and the bump procedure are the same.

### Phase 2b: Audit the pins

A pin is a claim until something reads it. This script reads the YAML — `include:` in every shape
(a string, a list, a single map; `component`, `project`, `remote`, `local`, `template`), following
`include: local` files and globs, and `image:` / `services:` anywhere in the file (global, `default:`,
per job, string or `name:` map) — and fails on anything not pinned. It needs mikefarah `yq` v4,
because `grep` cannot tell a service's `name:` from an artifact's.

The script is [`scripts/check-gitlab-pins.sh`](scripts/check-gitlab-pins.sh), in this skill's directory. Copy it into the project as `scripts/check-gitlab-pins.sh` rather than retyping it, and run it from the repository root.

Exit codes: **0** every reference is pinned; **1** at least one is not; **2** it could not run — `yq`
missing or the wrong one, a file missing or unparsable, or the file mentions `include:`/`image:`/
`services:` yet nothing was extracted (a checker that checked nothing must not pass). An exact release
tag on a component or project is a warning, not an error: it is mutable unless the project protects its
tags. A `$VARIABLE` ref or image is a failure because it cannot be verified. Set `GITLAB_PINS_ALLOW` to
an ERE of references to skip — your own registry (`'^\$CI_REGISTRY_IMAGE'`) — because they are yours.

Gate the merge with a job on an image that has `bash`, `git`, `grep` and `yq` v4, pinned by digest (resolve
it with `skopeo`, as above; do not type it):

```yaml
pins:
  stage: test
  image: <image with bash, git, grep and mikefarah yq v4>@sha256:<resolve it>
  script:
    - scripts/check-gitlab-pins.sh
```

Proven against fixtures before it was written down: a correct config → 0; `@~latest`, a partial semver,
a branch, a `$VARIABLE`, no `@`, a `project:` with no `ref:` or `ref: main`, a remote URL with no SHA, an
image or service with no digest or a short digest, and an unpinned image reached only through a
glob-matched `include: local` file → 1; an exact tag → 0 with a warning; a config with no third-party
references → 0; `yq` missing, the wrong `yq`, a missing file, unparsable YAML, and an extractor that
silently returns nothing → 2. Run against seven real configurations from this portfolio it found every
`image:` line a text search found (14 of 14) and none of the artifact `name:` lines. **Not yet exercised:**
a real config that uses `include:` (none of the seven did), and the job above in GitLab CI.

### Phase 3: Scope the Job Token

`CI_JOB_TOKEN` is minted per job, scoped to the triggering user's access level, masked in logs, and
revoked when the job ends. **By default it reaches only its own project** — so the work here is
mostly *keeping* it that way. But verify the default actually holds before auditing anything else:

- **First, confirm the allowlist is enforced at all.** Under **Settings → CI/CD → Job token
  permissions**, the project may be set to either *"This project and any groups and projects in the
  allowlist"* (restricted — the default) or **"All groups and projects"** (permissive). GitLab's
  warning is unambiguous: *"If you disable the CI/CD job token allowlist, jobs from any project can
  access your project with a job token… You should only disable this setting for testing or a
  similar reason."* A project in the permissive mode has **no allowlist to audit** — that is the
  worst case and the finding. Fix it before reviewing entries. (Self-managed admins can force the
  restricted mode instance-wide via *Enable and enforce job token allowlist for all projects*.)
- Then audit the allowlist: **Settings → CI/CD → Job token permissions → CI/CD job token allowlist**.
  Every entry is a project that may authenticate *into* this one. Justify each; remove the rest.
  (Limit: 200 entries — an allowlist near that size is a finding in itself.)
- Adding to the allowlist **grants no new permissions** — the user must already have access. It
  widens *reachability*, not authority. Do not treat allowlist membership as an access grant.
- Prefer the **fine-grained permissions** setting (limiting the token to a specific set of REST
  endpoints) over all-or-nothing allowlisting.
- **Public/internal projects**: unauthenticated users can fetch artifacts from public pipelines
  regardless of the allowlist. If artifacts are sensitive, set feature visibility to
  *Only project members*.
- Review the authentication log periodically for unexpected cross-project token use.

### Phase 4: Variables and Secrets

- **Never put secrets in `.gitlab-ci.yml`.** It is readable by anyone with repo access; it holds
  non-sensitive configuration only. Secrets live in project/group settings or a secrets manager.
- **Protected** = available only to pipelines on protected branches/tags. **Masked** = redacted as
  `[MASKED]` in job logs. They solve different problems — set both for real secrets:
  ```bash
  # Read the secret into a variable; never inline it or echo it
  read -rs SECRET_VALUE
  glab variable set DEPLOY_TOKEN "$SECRET_VALUE" --masked --protected
  glab variable list -F json --jq '.[] | select(.masked==false or .protected==false) | .key'
  ```
  That second command is the audit: any secret-shaped key it prints is a finding.
- **Masking has hard constraints** — the value must be a single line, no spaces, ≥ 8 characters, and
  (with expansion enabled) use only `_ : @ - + . ~ = /` beyond alphanumerics. A secret that cannot be
  masked is a secret that will eventually appear in a log; regenerate it in a maskable format rather
  than shipping it unmasked.
- **Masking is not a security boundary.** GitLab's own docs (*CI/CD variables → Mask a CI/CD
  variable*) state it "is not a guaranteed way to prevent malicious users from accessing variable
  values" — it defeats accidental logging, not an attacker running code in the job.
- **The fork/MR path is the real exposure.** A merge request that edits `.gitlab-ci.yml` can
  exfiltrate both masked and protected variables — GitLab's guidance is to review every
  `.gitlab-ci.yml` change before merging. For public projects, require approval before running
  pipelines on fork MRs.
- Use `--hidden` for variables that should not be readable back in the UI. **Set it at creation —
  it cannot be added later**: "Hiding a variable is only possible when creating a new variable, you
  cannot update an existing variable to be hidden." Hidden values must also satisfy the masking
  requirements above. Making an existing variable hidden means deleting and recreating it, which in
  practice means rotating the secret — plan for that rather than discovering it mid-audit.

### Phase 5: Replace Long-Lived Secrets with OIDC (`id_tokens`)

A static cloud credential in CI is a permanent liability. `id_tokens` mints a short-lived JWT per
job that a third party can verify:

```yaml
deploy:
  id_tokens:
    DEPLOY_TOKEN:
      aud: https://deploy.internal.example      # set it — services should reject a mismatched aud
  script:
    - ./authenticate.sh "$DEPLOY_TOKEN"
```

- `aud` defaults to the GitLab instance domain. Set it explicitly to the consuming service, and
  configure that service to **reject tokens whose `aud` does not match** — that is what limits the
  blast radius if a token leaks.
- Claims available for policy include `project_path`, `ref`, `ref_protected`, `environment`,
  `runner_id`, `sha`, `user_login`. Scope the trust policy on the relying side with
  `ref_protected`/`environment`, not `project_path` alone.
- `CI_JOB_JWT` / `CI_JOB_JWT_V2` are **deprecated** — they now fail with `401 Unauthorized`. Any
  pipeline still referencing them is broken, not merely dated.

### Phase 6: Runner Trust

- Prefer **project or group runners** over shared runners for jobs that touch secrets.
- **`privileged: true`** Docker executors on a shared machine give a job the host — flag every use
  and demand a justification.
- The **`shell` executor** on a multi-job machine offers no isolation between jobs; flag it.
- Pin runner images by digest (Phase 2).

### Phase 7: Verify

```bash
glab ci lint                    # config still parses
glab ci lint --dry-run          # simulate creation against a real ref
```

Run `scripts/check-gitlab-pins.sh` and confirm it exits 0: nothing resolves to a moving target.

## Outputs

- [ ] An **audit report**: job-token enforcement mode, unpinned includes/components/images/services,
      allowlist entries, unmasked/unprotected variables, deprecated `CI_JOB_JWT*` use,
      `privileged`/`shell` runners — each with a file:line or settings path.
- [ ] (`fix` scope) Pinned `include:` / `component` / `image:` / `services:` references, with the
      resolved SHAs and digests recorded.
- [ ] (`fix` scope) `glab ci lint` re-run and passing after the changes, and `scripts/check-gitlab-pins.sh` exiting 0.
- [ ] A list of **judgment calls left to the maintainer** — job-token mode, allowlist trimming,
      accepted `include: remote` hosts, runner choice, and fork-MR policy are decisions, not
      mechanical fixes.
- [ ] Any decision worth keeping (an accepted `remote` include, a retained `privileged` runner)
      recorded as an ADR via `setup-adrs`.

## Validation

- [ ] Forge confirmed GitLab; GitHub/Forgejo projects redirected to the sibling skill, not approximated
- [ ] `scripts/check-gitlab-pins.sh` exits 0 — every `include: component` and `include: project` pinned (a commit SHA, or a release tag on a tag-protected project: the script warns on a tag), no `~latest`, no implicit HEAD, no unpinned image or service
- [ ] Every `include: remote` justified, and its host treated as part of the trust boundary
- [ ] **Job-token access mode confirmed restricted** (not "All groups and projects") *before* allowlist entries were reviewed — a permissive project has no allowlist to audit
- [ ] `CI_JOB_TOKEN` allowlist reviewed entry-by-entry; fine-grained permissions preferred
- [ ] No secrets in `.gitlab-ci.yml`; every secret variable both masked **and** protected
- [ ] Any secret that cannot satisfy the masking constraints regenerated, not shipped unmasked
- [ ] `id_tokens` with an explicit `aud` used instead of long-lived credentials; no `CI_JOB_JWT*`
- [ ] `privileged` / `shell` executors justified or removed
- [ ] `glab ci lint` passes after changes

## Related Skills

- `harden-github-actions` — the sibling for GitHub Actions. Same intent, different execution model; neither is a translation of the other
- `setup-adrs` — record the decisions this surfaces: an accepted `include: remote` host, retained allowlist entries, a justified `privileged` runner
- `setup-container-security` — base-image digest pinning and the skopeo bump procedure this reuses for job images
- `setup-git-hooks` — local quality gates; this skill hardens the CI that enforces them
- `validate-quality-config` — *reads* CI to confirm parity with local hooks; it does not check pinning, permissions, or provenance. Complementary
- `supply-chain` (**project-maintenance-skills**) — the audit that flags CI hardening gaps; this skill closes them
- `wrapup-sprint` — release provenance for `ships-artifacts` projects, which consumes the OIDC path established here
