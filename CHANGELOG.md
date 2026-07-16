# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
During development the patch level is bumped per change (`0.1.x`).

## [Unreleased]

## [0.1.20] - 2026-07-16

### Changed

- `setup-container-security`: reframed the containerization stance from "Podman-first,
  Docker-compatible" to **OCI-compliant first** — target the OCI image spec so the artifact
  runs on any conformant runtime; build/test distributables with podman, stay Docker-compatible.
- `setup-architecture-as-code`: normalised the Structurizr `inspect` severity flag `-severity` →
  `-s`/`--severity` in the `inspect-architecture` Makefile target (matches the verified vNext CLI,
  `structurizr v2026.03.06`).

## [0.1.19] - 2026-07-10

### Fixed

- Portfolio-review quality pass across all 10 skills: replaced broken workspace-relative
  `../../../docs/patterns/…` links with absolute upstream GitHub URLs; corrected the Structurizr CLI
  flag `-workspace` → `-w` and mounted the project root with `:z` for both `validate` and the `local`
  viewer (`setup-architecture-as-code`); fixed the `set -e` + `((errors++))` counter in
  `validate-quality-config` and added Required Inputs / Validation sections; pointed `setup-adrs`
  validation at `docs/adr/index.yml` (not `README.md`); added the correct `gh`
  private-vulnerability-reporting check; glossed author-internal jargon for portability.

## [0.1.18] - 2026-07-10

### Fixed

- `wrapup-sprint`: reference the tracker-boundary decision by its real ADR title
  ("Work-Organization Boundary") so it resolves in `docs/adr/`.

## [0.1.17] - 2026-07-10

### Added

- Work-organization **tracker boundary** (single source of truth for tactical status): `wrapup-sprint`
  Step 7 honours a public forge tracker as canonical for per-issue/milestone status once a project has
  graduated its backlog, keeping the roadmap Sprint History as the narrative/version ledger;
  `bootstrap-project`'s roadmap template gains a "Tracker Boundary" section.

## [0.1.16] - 2026-07-10

### Changed

- README skill roster synced to the full 10 skills — added `harden-ci-workflows` and
  `setup-container-security` to the skill tables and the slash-command list.

## [0.1.15] - 2026-07-04

### Added

- `setup-adrs`: Third-Party / Aggregate Licensing guidance and a `LICENSING.md` template —
  per-component SPDX table, copyleft-floor identification (static-linking a GPL-3.0 library, or
  an AGPL-only container component), and obligations mapped to usage mode (self-host / redistribute
  / SaaS), with an accompanying ADR.
- `validate-quality-config`: Step 6 version-consistency check — the declared version must agree
  across the package manifest, README, CHANGELOG, and `SECURITY.md`.

## [0.1.14] - 2026-07-04

### Added

- `setup-pre-commit`: lockfile + frozen-install enforcement (uv/mix/cargo/npm) with a check for
  lower-bound-only manifests missing a lockfile; and a Public-profile REUSE license-compliance
  gate — `REUSE.toml` + `LICENSES/` + `reuse lint` as a git hook and a CI job.
- `bootstrap-project`: Phase 10 generates a multi-ecosystem `.github/dependabot.yml`
  (package manager + `github-actions` + `docker`). Config generation only — PR triage stays with
  the `oss-maintenance` workflow.

### Changed

- `setup-adrs`: ADR-0002 §11 (Licensing) now points at enforced `reuse lint` (hook + CI) and marks
  licensing a Public-profile control, rather than prescribing REUSE abstractly.

## [0.1.13] - 2026-07-04

### Added

- New skill `setup-container-security`: harden container images — digest-pinned bases
  (multi-arch index + skopeo bump procedure), minimal/multi-stage builds, non-root
  runtime, sha256-verified artifact fetches, `.dockerignore`, hadolint/shellcheck,
  grype (fixable-only `.grype.yaml` policy) + syft SBOM, `HEALTHCHECK`, and Dependabot
  digest bumps. `ships-artifacts` publishing (SBOM release asset + cosign) delegates to
  `wrapup-sprint`.

## [0.1.12] - 2026-07-04

### Added

- `wrapup-sprint`: profile-gated release-provenance step for `ships-artifacts` projects —
  SBOM (syft, SPDX + CycloneDX), SLSA provenance for binary/tarball releases
  (slsa-github-generator + a slsa-verifier consumer guide), and cosign keyless signing for
  container images. Presented per artifact type, aligned with SLSA / EU CRA / EEF Ægis.

## [0.1.11] - 2026-07-04

### Added

- `bootstrap-project`: distribution-profile axis (**Private**/**Public** plus a
  `ships-artifacts` marker), orthogonal to the t0/t1/t2 tiers, so compliance controls
  attach by exposure rather than process maturity.
- `bootstrap-project` Phase 9: profile-gated `SECURITY.md` scaffold at the **Public**
  profile — coordinated disclosure, supported-versions, and a project-specific Scope,
  aligned with the OpenSSF Scorecard `Security-Policy` check and EU CRA steward duties.
- Community health files: `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and
  this changelog.

## [0.1.10] - 2026-07-04

### Changed

- `setup-pre-commit`: hardened dependency auditing — documented the `:mix_audit`
  prerequisite for `mix deps.audit`, fixed config parity across the pre-commit-framework
  and multi-language configs, added CVE-vs-retirement guidance, a CI enforcement job with
  a scheduled re-run, and OpenSSF / EEF Ægis grounding.

## [0.1.9] - 2026-07-04

### Added

- New skill `harden-ci-workflows`: GitHub Actions CI/CD supply-chain hardening — SHA-pin
  actions (with the SLSA-generator tag exception), least-privilege token permissions,
  verified toolchain installs, OpenSSF Scorecard, and SLSA provenance.

---

Releases prior to this changelog are recorded in the repository's git history.
Run `git tag --sort=-creatordate` to list tagged versions.
