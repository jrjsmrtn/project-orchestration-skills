# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
During development the patch level is bumped per change (`0.1.x`).

## [Unreleased]

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
