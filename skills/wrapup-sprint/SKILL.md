---
name: wrapup-sprint
description: Complete a sprint with retrospective, changelog update, release tagging, and (for `ships-artifacts` projects) release provenance — SBOM, SLSA, and signing. Use when sprint work is done, at the end of a sprint cycle, or before starting a new sprint.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.16"
license: MIT
---

# Wrap Up Sprint

Complete a sprint with retrospective, changelog update, and release tagging.

## When to Use

- When all planned work in a sprint is completed or explicitly deferred
- At the end of a sprint cycle
- Before starting a new sprint

## Required Inputs

1. **Sprint number** (e.g., 3)
2. **Version to release** (e.g., 0.1.5)

## Prerequisites

Before running this skill, verify:
- [ ] All planned work is complete OR explicitly deferred
- [ ] All tests passing
- [ ] Pre-commit and pre-push hooks pass

## Workflow

### Step 1: Review Sprint Plan

Read the sprint plan to understand what was committed:

```bash
cat docs/sprints/sprint-NNNN-plan.md
```

Identify:
- What was delivered
- What was dropped or deferred (and why)
- Key decisions or insights from the sprint

### Step 2: Update Sprint Plan Status

Mark the sprint plan as complete. Update the status field and check off completed acceptance criteria.

### Step 3: Create Sprint Retrospective

Two formats are available. Choose based on sprint complexity:

- **Minimal** — for routine sprints, single-feature sprints, or sprints without notable issues (default)
- **Expanded** — for integration work, multi-sprint efforts, or sprints with notable challenges

Create `docs/sprints/sprint-NNNN-retrospective.md` (markdown) or `sprint-NNNN-retrospective.yml` (YAML):

#### Minimal Format (Markdown)

```markdown
# Sprint [N] Retrospective

**Delivered**: yes / partial / no — [one line summary]
**Dropped**: [anything intentionally cut, and why — or "nothing"]
**Key insight**: [one thing learned that future sprints should know]
**Next candidate**: [what this sprint implies about what comes next]
```

#### Minimal Format (YAML)

```yaml
sprint: N
version: v0.1.x
status: complete
goal: "[sprint goal]"

what_went_well:
  - "[success 1]"
  - "[success 2]"

what_went_wrong:
  - "[problem 1]"

lessons_learned:
  - "[actionable insight 1]"

technical_notes:
  - "[implementation pattern or debugging insight worth preserving]"
```

#### Expanded Format (Markdown)

Use for integration work against live systems, multi-sprint efforts, or notable issues:

```markdown
# Sprint [N] Retrospective

**Delivered**: yes / partial / no — [one line summary]
**Version**: v0.1.x
**Completed**: [Date]

## What Went Well

1. **[Success 1]**
   - [Evidence and impact]

2. **[Success 2]**
   - [Evidence and impact]

## What Could Be Improved

1. **[Challenge 1]**
   - Root cause: [why it happened]
   - Action: [how to address]

## Key Learnings

1. [Actionable insight 1]
2. [Actionable insight 2]

## Technical Notes

- [Implementation pattern or debugging insight worth preserving for future sessions]
- [Performance finding, workaround, or library quirk]

## Action Items for Next Sprint

- [ ] [Process improvement or follow-up]
- [ ] [Technical debt item]

## Next Candidate

[What this sprint implies should come next — chains sprint sequencing]
```

### Step 4: Propagate Key Insights to CLAUDE.md

Review the retrospective's lessons learned and technical notes. If any insight would change how future sessions approach the codebase, add it to the project's CLAUDE.md (e.g., under "AI Collaboration Notes" or "Development Practices").

Examples of insights worth propagating:
- "AshSqlite generates OR chains not IN — batch Ash.load!/2 in chunks of ~200"
- "Module X requires injectable roles for test isolation"
- "Batch processing provides 18-20x speedup over single-item processing"

The retrospective captures the insight; CLAUDE.md makes it actionable in every future session.

### Step 5: Update CHANGELOG.md

Add new version section at the top of CHANGELOG.md (after `## [Unreleased]`):

```markdown
## [0.1.x] - YYYY-MM-DD

### Added
- [New feature or capability from this sprint]

### Changed
- [Changes to existing functionality]

### Fixed
- [Bug fixes]
```

Update version comparison links at bottom:
```markdown
[0.1.x]: https://github.com/[user]/[repo]/compare/v0.1.y...v0.1.x
```

### Step 6: Update Sprint Index

Update `docs/sprints/README.md` — mark current sprint complete, remove "Active Sprint" or set to next.

### Step 7: Update Roadmap

Update `docs/roadmap/roadmap.md`:
- Check off completed milestones in the current phase
- Add the sprint to the Sprint History table
- If this sprint completes a phase, mark the phase as done and note the start of the next phase

### Step 8: Update CLAUDE.md

Update the "Current Development Status" section:

```markdown
## Current Development Status

- **Current Sprint**: Between sprints (Sprint [N] complete)
- **Latest Release**: v0.1.x
- **Next Sprint**: Sprint [N+1] (planning)
```

### Step 9: Create Sprint Wrap-up Commit

```bash
git add docs/sprints/sprint-NNNN-plan.md
git add docs/sprints/sprint-NNNN-retrospective.md  # or .yml
git add docs/sprints/README.md
git add docs/roadmap/roadmap.md
git add CHANGELOG.md
git add CLAUDE.md

git commit -m "chore: complete Sprint N wrap-up (v0.1.x)"
```

### Step 10: Tag Release

```bash
# Create annotated tag
git tag -a v0.1.x -m "Sprint N: [brief description]"

# Push to origin (private)
git push origin develop --tags

# If multi-remote and ready for public release:
# git checkout main
# git merge develop
# git push origin main --tags
# git push github main --tags
```

### Step 11: Release Provenance (`ships-artifacts` profile)

**Skip unless the project's distribution profile carries the `ships-artifacts` marker** (publishes packages/images to a registry, or signed release binaries — see `bootstrap-project`). For source-only Public projects and Private projects, tagging (Step 10) *is* the end of the release.

For `ships-artifacts` projects the release must carry integrity evidence. The controls depend on the **artifact type** — they are separate patterns, not one pipeline:

**SBOM (any artifact type)** — one syft pass emits both formats, daemonless (export an image to an archive first, then scan from disk):

```bash
syft scan <dir|archive> -q \
  -o spdx-json=sbom.spdx.json \
  -o cyclonedx-json=sbom.cdx.json
```

Attach both to the release (or upload as a CI artifact). Covers the EU CRA SBOM expectation.

**Binary / source-tarball releases → SLSA provenance.** In the release workflow, hash the build outputs and hand off to the **tag-pinned** generator (the sanctioned exception to SHA-pinning):

```yaml
# build job:  outputs: { hashes: ${{ steps.hash.outputs.hashes }} }
- id: hash
  run: cd dist && echo "hashes=$(sha256sum * | base64 -w0)" >> "$GITHUB_OUTPUT"

provenance:
  needs: [build]
  permissions: { actions: read, id-token: write, contents: write }
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
  with:
    base64-subjects: ${{ needs.build.outputs.hashes }}
    upload-assets: true
    # private-repository: true   # add if the repo is private
```

This attaches a `.intoto.jsonl` to the release. Ship a consumer guide at `docs/howto/verifying-releases.md`:

```bash
slsa-verifier verify-artifact \
  --provenance-path <artifact>.intoto.jsonl \
  --source-uri github.com/{owner}/{repo} \
  <artifact>
```

**Container images → cosign keyless signing** (OIDC, no keys). Sign the image **by digest** in the publish job:

```yaml
publish:
  if: startsWith(github.ref, 'refs/tags/v')
  permissions: { contents: read, packages: write, id-token: write }
  steps:
    - uses: sigstore/cosign-installer@<sha>   # v3, SHA-pinned
    - run: cosign sign --yes "${IMAGE}@${DIGEST}"   # DIGEST from the build-push step
```

Document consumer verification in the README (note the issuer is a full `https://` URL, the source-uri above is not):

```bash
cosign verify {registry}/{owner}/{repo}:<tag> \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/{owner}/{repo}/\.github/workflows/<wf>\.yml@refs/tags/v'
```

The release **workflow** itself (job permissions, the SLSA-generator tag-pin exception, SHA-pinned `cosign-installer`) is hardened by `harden-ci-workflows`. This step's job at wrap-up is to confirm the release carries an SBOM + provenance/signing appropriate to its artifact type, and that a verification guide exists.

> **Grounding**: SLSA + EU CRA (build integrity, SBOM) and EEF Ægis trusted publishing (Hex/BEAM). These are the `ships-artifacts` controls from the distribution-profile axis (see `bootstrap-project`). Note: signing and SLSA provenance are per-artifact-type — cosign for images, slsa-verifier for tarballs/binaries; don't conflate them.

### Step 12: Prepare Next Sprint

Suggest running `plan-sprint` skill to create Sprint N+1 plan.

## Outputs

This skill creates/updates:
- [ ] `docs/sprints/sprint-NNNN-plan.md` (status updated)
- [ ] `docs/sprints/sprint-NNNN-retrospective.md` (or `.yml`)
- [ ] `docs/sprints/README.md` (status update)
- [ ] `docs/roadmap/roadmap.md` (milestones and sprint history updated)
- [ ] `CHANGELOG.md` (new version section)
- [ ] `CLAUDE.md` (current sprint reference + propagated insights)
- [ ] Git commit: `chore: complete Sprint N wrap-up`
- [ ] Git tag: `v0.1.x`

**`ships-artifacts` profile** (release-time):
- [ ] SBOM attached (syft: `sbom.spdx.json` + `sbom.cdx.json`)
- [ ] SLSA provenance (`.intoto.jsonl`) for binary/tarball releases, **or** cosign signature for container images
- [ ] Consumer verification guide (`docs/howto/verifying-releases.md` and/or a README `cosign verify` block)

## Validation

```bash
# Verify all tests pass
mix test  # or pytest, cargo test, etc.

# Verify changelog has new version
grep "## \[0.1.x\]" CHANGELOG.md

# Verify tag exists
git tag -l "v0.1.x"

# Verify retrospective exists
ls docs/sprints/sprint-NNNN-retrospective.*
```

**`ships-artifacts` profile**: confirm the release attached an SBOM and the right integrity evidence for its artifact type — a `.intoto.jsonl` that `slsa-verifier` accepts (tarball/binary) or a signature that `cosign verify` accepts (image) — and that a verification guide exists.

## Related Skills

- `plan-sprint` - Create next sprint plan
- `bootstrap-project` - Initial project setup; declares the distribution profile / `ships-artifacts` marker
- `harden-ci-workflows` - Harden the release workflow that produces provenance (permissions, SLSA-generator tag exception, SHA-pinned cosign-installer)
- `setup-adrs` - ADR-0002 documents sprint practices
