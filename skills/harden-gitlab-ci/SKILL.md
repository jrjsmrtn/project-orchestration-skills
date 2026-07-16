---
name: harden-gitlab-ci
description: Harden GitLab CI/CD pipelines for supply-chain security — SHA-pin `include:` and CI/CD components, scope the `CI_JOB_TOKEN` allowlist, protect and mask variables, pin job image digests, and use `id_tokens`/OIDC instead of long-lived secrets. Use when adding or auditing a `.gitlab-ci.yml`, before making a GitLab project public, when a supply-chain review flags CI gaps, or when standardizing pipeline hardening across GitLab projects. GitLab-specific by design — GitHub Actions is `harden-github-actions`.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.23"
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

- When adding a `.gitlab-ci.yml` to a project (after `setup-pre-commit`)
- When auditing an existing pipeline before making a GitLab project public
- When a supply-chain review (or the `supply-chain` skill) flags CI hardening gaps
- When standardising pipeline hardening across GitLab projects
- On **self-hosted GitLab** as much as gitlab.com — the controls are identical

**Not for:** GitHub Actions (use `harden-github-actions`) or Forgejo/Gitea Actions. The controls do not carry over — say so rather than approximating.

## Required Inputs

1. **Repository** — a GitLab project (auto-detected from git remotes; `gitlab.com` or self-hosted)
2. **Scope** — what to run:
   - `audit` — report findings against the checklist below; **no writes** (default)
   - `fix` — apply the mechanical fixes (pin includes/components/images), leave judgment calls to the maintainer
   - `full` — `audit`, then `fix` after confirmation

## The GitLab Threat Model — What Actually Differs

Do **not** port `harden-github-actions`' controls one-for-one. Where the risk sits differs:

| Concern | GitHub Actions | GitLab CI |
|---|---|---|
| Third-party code execution | `uses: actions/x@ref` from the Marketplace | **`include:` + CI/CD Catalog components** — same class of risk, different keyword |
| Ambient credential | `GITHUB_TOKEN` with repo-wide default scopes | **`CI_JOB_TOKEN`** — defaults to *own project only*; risk is a widened allowlist |
| Secret exfiltration surface | workflow can read all repo secrets | **variable scoping** — protected/masked/environment-scoped, plus fork-MR exposure |
| Provenance / keyless auth | OIDC via `id-token: write` | **`id_tokens:` with an `aud` claim** |
| Runner trust | GitHub-hosted vs self-hosted | **shared vs group/project runners**, `privileged` Docker, `shell` executor |

> **A correction worth stating plainly:** GitLab *does* have a marketplace-shaped supply chain — the
> **CI/CD Catalog** of components. It is easy to assume otherwise and skip the pinning discipline
> entirely. GitLab's own documentation says to "Pin CI/CD components to a specific commit SHA
> (preferred) or release version tag."

## Workflow

### Phase 1: Detect Context

1. Confirm the forge is GitLab and the CLI is authenticated:
   ```bash
   git remote -v
   glab auth status                      # self-hosted: glab auth login --hostname gitlab.internal.example
   ```
   If the remote is GitHub or Forgejo, **stop** and point at the right sibling skill.
2. Locate the pipeline config — `.gitlab-ci.yml` by default; a project may relocate it
   (Settings → CI/CD → General pipelines → CI/CD configuration file).
3. Validate it parses before changing anything:
   ```bash
   glab ci lint
   ```
4. Inventory the third-party surface: every `include:` and `component`, every job `image:`/`services:`.

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

**Job images** — pin by digest, not tag:

```yaml
# BAD                      # GOOD
image: python:3.13         image: python@sha256:<digest>
```

Resolve digests with `skopeo inspect docker://python:3.13 --format '{{.Digest}}'`. This mirrors
`setup-container-security`'s base-image rule; the reasoning and the bump procedure are the same.

### Phase 3: Scope the Job Token

`CI_JOB_TOKEN` is minted per job, scoped to the triggering user's access level, masked in logs, and
revoked when the job ends. **By default it reaches only its own project** — which is already the
secure default, so the work here is *keeping* it that way.

- Audit the allowlist: **Settings → CI/CD → Job token permissions → CI/CD job token allowlist**.
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
- **Masking is not a security boundary.** GitLab states plainly that it "is not a guaranteed way to
  prevent malicious users from accessing variable values" — it defeats accidental logging, not an
  attacker running code in the job.
- **The fork/MR path is the real exposure.** A merge request that edits `.gitlab-ci.yml` can
  exfiltrate both masked and protected variables — GitLab's guidance is to review every
  `.gitlab-ci.yml` change before merging. For public projects, require approval before running
  pipelines on fork MRs.
- Use `--hidden` for variables that should not be readable back in the UI after creation.

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

Re-run the Phase 2 inventory and confirm nothing resolves to a moving target.

## Outputs

- An audit report: unpinned includes/components/images, allowlist entries, unmasked/unprotected
  variables, deprecated `CI_JOB_JWT*` use, `privileged`/`shell` runners.
- (`fix` scope) Pinned `include:`/`component`/`image:` references, with the resolved SHAs recorded.
- A list of **judgment calls left to the maintainer** — allowlist trimming, runner choice, and
  fork-MR policy are decisions, not mechanical fixes.

## Validation

- [ ] Forge confirmed GitLab; GitHub/Forgejo projects redirected to the sibling skill, not approximated
- [ ] Every `include: component` pinned to a commit SHA (or a release tag on a tag-protected project) — no `~latest`
- [ ] Every `include: project` has an explicit `ref:` pinned to a SHA — no implicit HEAD
- [ ] Every `include: remote` justified, and its host treated as part of the trust boundary
- [ ] Job `image:`/`services:` pinned by digest
- [ ] `CI_JOB_TOKEN` allowlist reviewed entry-by-entry; fine-grained permissions preferred
- [ ] No secrets in `.gitlab-ci.yml`; every secret variable both masked **and** protected
- [ ] Any secret that cannot satisfy the masking constraints regenerated, not shipped unmasked
- [ ] `id_tokens` with an explicit `aud` used instead of long-lived credentials; no `CI_JOB_JWT*`
- [ ] `privileged` / `shell` executors justified or removed
- [ ] `glab ci lint` passes after changes

## Related Skills

- `harden-github-actions` — the sibling for GitHub Actions. Same intent, different execution model; neither is a translation of the other
- `setup-container-security` — base-image digest pinning and the skopeo bump procedure this reuses for job images
- `setup-pre-commit` — local quality gates; this skill hardens the CI that enforces them
- `validate-quality-config` — *reads* CI to confirm parity with local hooks; it does not check pinning, permissions, or provenance. Complementary
- `supply-chain` (**project-maintenance-skills**) — the audit that flags CI hardening gaps; this skill closes them
- `wrapup-sprint` — release provenance for `ships-artifacts` projects, which consumes the OIDC path established here
