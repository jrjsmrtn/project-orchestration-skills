---
name: setup-container-security
description: Harden container images (Containerfile/Dockerfile) for supply-chain security — digest-pinned bases, non-root runtime, verified artifact fetches, hadolint/shellcheck linting, and grype + syft SBOM scanning. Use when a project builds a container image, before publishing an image to a registry, or when auditing container security.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.44"
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

These greps explore; the gating form is `scripts/check-containerfile.sh` (Validation). The `FROM` pattern is
unreliable in both directions: `^FROM .*:[^@]*$` flags a correctly pinned `FROM node:22@sha256:… AS build`
(the last `:` is the one inside `sha256:`), and misses `FROM ubuntu`, which has no `:` at all.

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
- **Language deps** — install from a committed lockfile (`npm ci`, mix from `mix.lock`) — see `setup-git-hooks`.

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

- [ ] Every `FROM` digest-pinned (multi-arch index), with a bump-command comment — `scripts/check-containerfile.sh` exits 0
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

Run the check; do not read the list. Save this as `scripts/check-containerfile.sh` and run it from the repository
root (`scripts/check-containerfile.sh`, or name the files). It only reads, and it runs under the bash 3.2 macOS ships.

```bash
#!/usr/bin/env bash
# scripts/check-containerfile.sh — the mechanical half of setup-container-security.
#   usage: scripts/check-containerfile.sh [file...]     default: every Containerfile*/Dockerfile* under
#                                                        the repo root (3 levels deep); run from the root
#   exit:  0 every check passed | 1 at least one FAILED | 2 no Containerfile found (nothing was checked)
# Per file (instructions are read as logical lines, backslash continuations joined):
#   FROM        every FROM names a digest (@sha256:<64 hex>); `scratch` and an earlier stage are exempt. A
#               ${VARIABLE} base is expanded from its global ARG default (ARG NAME=value before the first
#               FROM) and that is checked; one with no default fails, because it cannot be verified
#   USER        the final stage ends on a USER that is not root or 0; an exception is declared with a
#               comment line `# root-ok: <reason>` in that stage (reported, not failed)
#   RUN         `curl|wget ... | sh|bash` and `sh -c "$(curl ...)"` fail; a RUN that downloads from a URL
#               must verify it in the same RUN (sha256sum/sha512sum/shasum -c, gpg --verify, cosign verify),
#               or sit under a comment line `# unverified-ok: <reason>`; `apt-get install` needs
#               --no-install-recommends
# Per repository: a .dockerignore or .containerignore (beside the file or at the root) that excludes .git
#   and .env; hadolint named in lefthook.yml, .pre-commit-config.yaml or a CI file; .grype.yaml present and
#   grype named in a CI file; a docker ecosystem in .github/dependabot.yml when that file exists.
# Not checked: that a digest is the multi-arch INDEX rather than a per-arch manifest (needs the registry:
#   skopeo inspect --raw docker://IMAGE@DIGEST must say application/vnd.oci.image.index.v1+json), the
#   scan itself, SBOM contents, HEALTHCHECK, and what an ENTRYPOINT does after start.
set -u
fail=0
ok()   { echo "ok    $*"; }
bad()  { echo "FAIL  $*"; fail=1; }
info() { echo "info  $*"; }

if [ "$#" -gt 0 ]; then files="$*"
else files=$(find . -maxdepth 3 \( -name 'Containerfile*' -o -name 'Dockerfile*' \) -type f \
               -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null | sed 's#^\./##' | sort); fi
[ -n "$files" ] || { echo "FAIL  no Containerfile or Dockerfile found — nothing was checked" >&2; exit 2; }

# logical instructions: "start-line<TAB>preceding-comment-or-dash<TAB>text"
logical() {
  awk '
    function flush() { if (buf != "") { print start "\t" (w == "" ? "-" : w) "\t" buf; buf = "" } }
    cont { sub(/^[[:space:]]+/, "", $0); if ($0 ~ /^#/) next
           if ($0 ~ /\\[[:space:]]*$/) { sub(/\\[[:space:]]*$/, "", $0); buf = buf " " $0; next }
           buf = buf " " $0; cont = 0; flush(); prev = ""; next }
    /^[[:space:]]*#/ { prev = $0; next }
    /^[[:space:]]*$/ { prev = ""; next }
    { start = NR; w = prev; prev = ""; line = $0; sub(/^[[:space:]]+/, "", line)
      if (line ~ /\\[[:space:]]*$/) { sub(/\\[[:space:]]*$/, "", line); buf = line; cont = 1; next }
      buf = line; flush() }
    END { flush() }' "$1"
}

for f in $files; do
  [ -f "$f" ] || { bad "$f: no such file"; continue; }
  stages=" "; gargs=""; last_from=0; user=""; user_line=0; rootok=""; nfrom=0; n_fail_before=$fail
  while IFS=$'\t' read -r n w text; do
    instr=$(printf '%s' "$text" | awk '{print toupper($1)}')
    case "$instr" in
      ARG)
        # global ARGs (before the first FROM) are what a FROM line can expand: remember NAME=default
        if [ "$nfrom" -eq 0 ]; then a=$(printf '%s' "$text" | sed -E 's/^[Aa][Rr][Gg][[:space:]]+//; s/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/\1\t\2/'); gargs="$gargs$a"$'\n'; fi ;;
      FROM)
        nfrom=$((nfrom + 1)); last_from=$n; user=""; user_line=0; rootok=""
        img=""; alias=""; prev_tok=""
        for tok in $text; do
          case "$tok" in FROM|from|From) continue ;; --*) continue ;; esac
          if [ -z "$img" ]; then img=$tok; elif [ "$prev_tok" = AS ] || [ "$prev_tok" = as ]; then alias=$tok; fi
          prev_tok=$tok
        done
        # expand ${NAME} / $NAME from the global ARG defaults, repeatedly: a default may name another ARG
        for _pass in 1 2 3 4 5; do
          while IFS=$'\t' read -r an av; do
            [ -n "$an" ] || continue; av=${av#\"}; av=${av%\"}; av=${av#\'}; av=${av%\'}
            case "$an" in *[!A-Za-z0-9_]*) continue ;; esac
            [ -n "$av" ] || continue    # `ARG NAME` (or `ARG NAME=`): no default to expand
            img=${img//\$\{$an\}/$av}; img=${img//\$$an/$av}
          done <<< "$gargs"
        done
        case "$img" in
          scratch) ;;
          *@sha256:[0-9a-f]*) printf '%s' "$img" | grep -qE '@sha256:[0-9a-f]{64}$' || bad "$f:$n: FROM $img — digest is not 64 hex characters" ;;
          *'$'*) bad "$f:$n: FROM $img — a variable with no default in a global ARG cannot be verified; give it a pinned default or write the digest" ;;
          *) case "$stages" in *" $img "*) ;; *) bad "$f:$n: FROM $img is not pinned by digest (name:tag@sha256:...)" ;; esac ;;
        esac
        [ -z "$alias" ] || stages="$stages$alias " ;;
      USER) user=$(printf '%s' "$text" | awk '{print $2}'); user_line=$n ;;
      RUN)
        if printf '%s' "$text" | grep -qE '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash|zsh|ash)([[:space:]]|;|&|$)|(sh|bash)[[:space:]]+-c[[:space:]]+["'"'"']?\$\([[:space:]]*(curl|wget)'; then
          bad "$f:$n: pipes a download into a shell (curl | sh)"
        fi
        if printf '%s' "$text" | grep -qE '(curl|wget)[^|;&]*https?://'; then
          if ! printf '%s' "$text" | grep -qE '(sha256sum|sha512sum|sha1sum|shasum|md5sum)[[:space:]]+(-c|--check)|(sha256sum|sha512sum|shasum)[^|;&]*-c([[:space:]]|$)|gpg[[:space:]]+--verify|gpgv|cosign[[:space:]]+verify'; then
            case "$w" in *unverified-ok:*) info "$f:$n: unverified download waived (${w#*unverified-ok:})" ;;
              *) bad "$f:$n: downloads from a URL with no checksum or signature check in the same RUN" ;; esac
          fi
        fi
        if printf '%s' "$text" | grep -qE 'apt(-get)?[[:space:]]+install' && ! printf '%s' "$text" | grep -q -e '--no-install-recommends'; then
          bad "$f:$n: apt-get install without --no-install-recommends"
        fi ;;
    esac
  done < <(logical "$f")
  # a root-ok comment may sit anywhere in the final stage, including above USER
  if [ "$nfrom" -eq 0 ]; then bad "$f: has no FROM instruction"
  else
    final=$(awk -v s="$last_from" 'NR >= s' "$f")
    printf '%s\n' "$final" | grep -qE '^[[:space:]]*#[[:space:]]*root-ok:' && rootok=$(printf '%s\n' "$final" | sed -nE 's/^[[:space:]]*#[[:space:]]*root-ok:(.*)/\1/p' | head -1)
    case "$user" in
      ""|root|0|root:*|0:*)
        if [ -n "$rootok" ]; then info "$f: final stage runs as root, declared acceptable:$rootok"
        else bad "$f: the final stage has no USER, or ends as root (declare an exception with '# root-ok: <reason>' and an ADR)"; fi ;;
    esac
  fi
  [ "$fail" -eq "$n_fail_before" ] && ok "$f: base pinned, non-root, no unverified fetch"
done

# ---- repository level
ign=0
for d in . $(for f in $files; do dirname "$f"; done | sort -u); do
  for i in "$d/.dockerignore" "$d/.containerignore"; do
    [ -f "$i" ] || continue
    if grep -qE '^/?\.git/?$' "$i" && grep -qE '^/?\.env(\*|\.\*)?$|^/?\.env\*$' "$i"; then ign=1; fi
  done
done
[ "$ign" -eq 1 ] && ok ".dockerignore/.containerignore excludes .git and .env" || bad "no .dockerignore or .containerignore that excludes both .git and .env"

ci=$( { ls .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml 2>/dev/null; } )
hooks=$( { ls lefthook.yml lefthook.yaml .lefthook.yml .pre-commit-config.yaml 2>/dev/null; } )
if [ -n "$hooks$ci" ] && grep -qs hadolint $hooks $ci; then ok "hadolint is wired (hook or CI)"; else bad "hadolint appears in no lefthook/pre-commit config or CI file"; fi
if [ -f .grype.yaml ] || [ -f .grype.yml ]; then ok ".grype.yaml present"; else bad ".grype.yaml is missing"; fi
if [ -n "$ci" ] && grep -qs grype $ci; then ok "grype runs in CI"; else bad "grype appears in no CI file"; fi
if [ -f .github/dependabot.yml ] || [ -f .github/dependabot.yaml ]; then
  grep -qsE 'package-ecosystem:[[:space:]]*"?docker"?' .github/dependabot.y*ml && ok "dependabot has a docker ecosystem" || bad ".github/dependabot.yml has no docker ecosystem for digest bumps"
fi

exit "$fail"
```

Exit codes: **0** every check passed; **1** at least one failed; **2** no Containerfile or Dockerfile found (nothing
was checked). Per file it fails on:

- a `FROM` without `@sha256:<64 hex>` (`scratch` and an earlier stage are exempt). A `${VARIABLE}` base is expanded
  from its global `ARG` default, repeatedly, and the result is checked; one with no default fails, since nothing can
  verify it;
- a final stage with no `USER`, or whose last `USER` is root or `0` (a stage earlier in the file does not count).
  Declare a legitimate exception, such as `gosu` dropping to a service user, with a comment line `# root-ok: <reason>`
  in that stage: it is reported, not failed, and the reason belongs in the ADR as Step 4 says;
- `curl|wget … | sh` (also `| sudo sh`, `| bash`, and `sh -c "$(curl …)"`);
- a `RUN` that downloads from a URL with no `sha256sum -c`, `sha512sum -c`, `shasum -c`, `gpg --verify`, `gpgv` or
  `cosign verify` in the same `RUN`. A download that is knowingly unverified sits under `# unverified-ok: <reason>`;
- `apt-get install` without `--no-install-recommends`.

Per repository it fails on: no `.dockerignore`/`.containerignore` that excludes both `.git` and `.env`; `hadolint`
named in no hook config or CI file; no `.grype.yaml`; `grype` named in no CI file; and a `.github/dependabot.yml`
with no `docker` ecosystem.

What it does **not** check: that a digest is the multi-arch **index** and not a per-arch manifest (that needs the
registry: `skopeo inspect --raw docker://IMAGE@DIGEST` must report `application/vnd.oci.image.index.v1+json`), that
the scan or SBOM actually ran, `HEALTHCHECK`, and what an `ENTRYPOINT` does once the container starts. A file named
`Dockerfile.bak` is checked like any other, because the glob matches it.

Tested against fixtures with each fault planted (44 cases, bash 5 and 3.2). Run against real projects, it found
unpinned bases and no `USER` in `ragu-embedder` and `ragu-embedder-python`, an `apache/age` (PostgreSQL) base ending as root with
no declared exception in `ragu-postgresql`, and, after expanding the `ARG` defaults, the unpinned images behind
`FROM ${BUILDER_IMAGE}` in `fosdem` and `dsx`; two Containerfiles pass the per-file checks (`mock-mikrotik-api`,
`pulp-ci`). Not yet run in CI or as a hook.

## Related Skills

- `harden-github-actions` - harden the image build/publish workflow (SHA-pin actions, least-privilege, cosign-installer)
- `wrapup-sprint` - release-time SBOM + cosign signing for published images
- `setup-git-hooks` - lockfile enforcement and the hadolint/shellcheck hooks
- `bootstrap-project` - the distribution profile (whether the project publishes artifacts); Dependabot config
- `setup-adrs` - record the container-security checks and documented exceptions
