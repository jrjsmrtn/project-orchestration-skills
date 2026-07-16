---
name: setup-container-security
description: Harden container images (Containerfile/Dockerfile) for supply-chain security — digest-pinned bases, non-root runtime, verified artifact fetches, hadolint/shellcheck linting, and grype + syft SBOM scanning. Use when a project builds a container image, before publishing an image to a registry, or when auditing container security.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.23"
license: MIT
---

# Setup Container Security

Harden a project's container image against supply-chain attack: pin the base, verify what you fetch, drop privileges, and scan what you ship. **OCI-compliant first** — target the OCI image spec so the artifact runs on any conformant runtime (podman, Docker, containerd). Build and test distributable images with **podman** (rootless, daemonless, OCI output by default), and stay Docker-compatible (`Dockerfile`/`Containerfile` are interchangeable below).

## When to Use

- When a project builds a container image (has a `Containerfile`/`Dockerfile`)
- Before publishing an image to a registry (a project that ships the image as a release artifact)
- When auditing container security, or when a supply-chain review flags container gaps

## Required Inputs

1. The project's `Containerfile`/`Dockerfile`(s)
2. Base image(s) and target registry
3. Whether the project **publishes** the image (ships it as a release artifact) — gates SBOM-as-release-asset + signing, delegated to `wrapup-sprint`

## The Threat

A container bakes in a base image, fetched packages/binaries, and a runtime user. A mutable base tag can be repointed upstream; an unverified `curl … | install` can be swapped; a root runtime turns any escape into host-level access. Hardening: **pin, verify, minimize, drop privileges, scan.**

## Workflow

### Step 1: Triage

```bash
ls Containerfile Dockerfile **/Dockerfile 2>/dev/null
# Mutable base tags (should be digest-pinned):
grep -nE '^FROM .*:[^@]*$' Containerfile Dockerfile 2>/dev/null
# Runs as root? (no USER, or USER root):
grep -nE '^USER ' Containerfile Dockerfile 2>/dev/null || echo "no USER — root unless the entrypoint drops privileges"
# Unverified fetch-and-install:
grep -nE 'curl.*\|\s*(sh|bash)|wget .*http' Containerfile Dockerfile 2>/dev/null
```

The recurring "looks fine at a glance" anti-pattern (a real-world example): a `-slim` base on a **mutable tag**, **no `USER`** (root runtime), and a build-time binary/model download with **no checksum** — despite otherwise-good habits (`--no-install-recommends`, a HEALTHCHECK, a `.containerignore`). It fails the three load-bearing checks: digest pinning, non-root, and artifact integrity.

### Step 2: Pin the base image by digest

Pin every `FROM` to the base's **multi-arch OCI index digest** (keep the tag for readability; preserves arm64/amd64):

```dockerfile
# To bump: skopeo inspect --raw docker://docker.io/apache/age:<tag> | sha256sum
FROM apache/age:release_PG18_1.7.0@sha256:e7de1717…baf00
```

For a rolling minimal base (e.g. Chainguard), the `:latest@sha256:…` form lets Dependabot re-pin the digest while tracking the tag:

```dockerfile
FROM cgr.dev/chainguard/node:latest@sha256:5280e6…22b3f AS runtime
```

Confirm you pinned the **index**, not a per-arch manifest:

```bash
podman image inspect <tag> --format '{{range .RepoDigests}}{{println .}}{{end}}'
skopeo inspect --raw docker://…@<digest>   # mediaType must be application/vnd.oci.image.index.v1+json
```

### Step 3: Minimal base, multi-stage build

Keep the build toolchain out of the shipped image. Either a two-stage split with a distroless/Chainguard runtime:

```dockerfile
FROM node:22-slim@sha256:… AS build
RUN npm ci --omit=dev --omit=optional --no-audit --no-fund && npm cache clean --force

FROM cgr.dev/chainguard/node:latest@sha256:… AS runtime
COPY --from=build --chown=65532:65532 /app /app
```

…or, when you must patch libs in place (distroless has no apt), a single stage that purges the toolchain in the **same `RUN` layer**, always with `--no-install-recommends` and apt-cache cleanup:

```dockerfile
RUN set -eux; apt-get update; \
    apt-get install -y --no-install-recommends build-essential …; \
    make && make install; \
    apt-get purge -y --auto-remove build-essential …; \
    rm -rf /var/lib/apt/lists/*
```

### Step 4: Run as non-root

Drop privileges with a `USER` before `CMD`. Distroless/Chainguard ships a `nonroot` uid (65532) you can switch to directly:

```dockerfile
COPY --from=build --chown=65532:65532 /data /data
USER 65532
```

**Context matters**: some official bases (e.g. `postgres`) legitimately start as root and `gosu`-drop to a service user via their entrypoint — a "runs as root" finding there needs context, not a blind `USER` that breaks the entrypoint. Document that exception in an ADR rather than forcing a fix.

### Step 5: Verify fetched artifacts

Anything downloaded at build time is attack surface — pin and verify:

- **Distro/binary `.deb`** — sha256-verify **per arch** before install:
  ```dockerfile
  RUN set -eux; arch="$(dpkg --print-architecture)"; \
      case "$arch" in \
        arm64) sha256=59dbe75a… ;; amd64) sha256=7637a18a… ;; \
        *) echo "no pinned checksum for $arch" >&2; exit 1 ;; esac; \
      curl -fsSL -o /tmp/x.deb "https://…/${VERSION}/…_${arch}.deb"; \
      echo "${sha256}  /tmp/x.deb" | sha256sum -c -; \
      apt-get install -y --no-install-recommends /tmp/x.deb
  ```
- **Source builds** — clone a pinned git **tag**, not a branch: `git clone --branch "${VERSION}" --depth 1 …`, `VERSION` an `ARG`.
- **Language deps** — install from a committed lockfile (`npm ci`, mix from `mix.lock`) — see `setup-pre-commit`.

Never `curl … | sh` an installer, and never fetch a binary/model with no checksum gate.

### Step 6: .dockerignore

Keep `.git`, secrets, and tests out of the build context (Podman honours `.containerignore` too):

```
.git
.github
.env
.env.*
CLAUDE.local.md
test
```

### Step 7: Lint — hadolint + shellcheck

Lint the Dockerfile with hadolint and build scripts with shellcheck, in **both** the pre-push hook and CI:

```yaml
# .lefthook.yml (pre-push)
lint-dockerfile:
  glob: "Dockerfile*"
  run: hadolint {push_files}
lint-shell:
  glob: "*.sh"
  run: shellcheck {push_files}
```

Prefer **inline, justified waivers** over a blanket `.hadolint.yaml` — they document why each rule is suppressed, at the line it applies to:

```dockerfile
# hadolint ignore=DL3008,DL4006
```

### Step 8: Scan — grype + syft SBOM

Scan the built image for known CVEs and generate an SBOM. Export the image to an archive so both run **daemonless**:

```bash
podman save --format oci-archive -o img.tar "$IMAGE"      # src="oci-archive:img.tar"
grype "oci-archive:img.tar"                                # reads .grype.yaml from repo root
syft scan "oci-archive:img.tar" -q \
  -o spdx-json=sbom.spdx.json -o cyclonedx-json=sbom.cdx.json
```

Commit a `.grype.yaml` policy that fails only on **fixable** High/Critical — a defensible anti-alert-fatigue gate that auto-resurfaces a finding when a fix ships:

```yaml
fail-on-severity: "high"
ignore:
  - fix-state: wont-fix
  - fix-state: not-fixed
  - fix-state: unknown
```

Run the scan in CI on image build/PR, plus a weekly `cron` re-scan of the pinned image as a drift backstop.

### Step 9: HEALTHCHECK

Add a `HEALTHCHECK`. In a distroless image (no shell), probe with the runtime instead of `sh`:

```dockerfile
HEALTHCHECK --interval=10s --timeout=3s --retries=6 \
  CMD ["/usr/bin/node","-e","require('net').connect(PORT,'127.0.0.1').on('connect',c=>{c.end();process.exit(0)}).on('error',()=>process.exit(1))"]
```

Note: Podman's default OCI image format drops `HEALTHCHECK` — carry a duplicate in `compose.yaml` for Compose users.

### Step 10: Automate digest bumps

Add a `docker` ecosystem to `.github/dependabot.yml` so base-image digests get weekly bump PRs (see `bootstrap-project`), each validated by the grype scan job.

### Step 11: Publishing and ADR

For projects that publish the image: attach the SBOM as a release asset and sign the image with cosign keyless — delegated to `wrapup-sprint`'s release-provenance step. Record the container-security decisions (which checks run, the grype-policy rationale, and any documented exceptions like a base-digest-pin or gosu-drop root) in an ADR.

> **Grounding**: EU CRA (SBOM, integrity) and OpenSSF supply-chain hardening. The base-digest-pin + `.deb` sha256 + git-tag builds close the "install whatever arrives over the network" gap; the fixable-only grype policy keeps the gate actionable.

## Outputs

- [ ] Every `FROM` digest-pinned (multi-arch index), with a bump-command comment
- [ ] Multi-stage or same-layer-purge build; `--no-install-recommends` + apt cleanup
- [ ] `USER` drops privileges before `CMD` (or the root exception is ADR-documented)
- [ ] Fetched `.deb`/binaries sha256-verified; source builds git-tag-pinned; no `curl | sh`
- [ ] `.dockerignore` / `.containerignore` excludes `.git`, secrets, tests
- [ ] hadolint + shellcheck in pre-push + CI (inline justified ignores)
- [ ] `.grype.yaml` (fixable-only policy) + grype scan in CI + weekly re-scan
- [ ] syft SBOM (SPDX + CycloneDX)
- [ ] `HEALTHCHECK`
- [ ] `docker` Dependabot ecosystem for digest bumps
- [ ] ADR recording the container-security checks and documented exceptions

## Validation

```bash
# No mutable base tags:
grep -nE '^FROM .*:[^@]*$' Dockerfile Containerfile 2>/dev/null && echo "UNPINNED base above" || echo "bases pinned"
# Non-root (or documented exception):
grep -qE '^USER ' Dockerfile Containerfile || echo "no USER — confirm the entrypoint drops privileges"
# Scan passes under policy + SBOM produced:
grype "oci-archive:img.tar"
test -s sbom.spdx.json && test -s sbom.cdx.json && echo "SBOM ok"
```

## Related Skills

- `harden-github-actions` - harden the image build/publish workflow (SHA-pin actions, least-privilege, cosign-installer)
- `wrapup-sprint` - release-time SBOM + cosign signing for published images
- `setup-pre-commit` - lockfile enforcement and the hadolint/shellcheck hooks
- `bootstrap-project` - the distribution profile (whether the project publishes artifacts); Dependabot config
- `setup-adrs` - record the container-security checks and documented exceptions
