---
name: wrapup-sprint
description: Complete a sprint with retrospective, changelog update, release tagging, and (for `ships-artifacts` projects) release provenance — SBOM, SLSA, and signing. Use when sprint work is done, at the end of a sprint cycle, or before starting a new sprint.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.45"
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

In the commands below, substitute the placeholders throughout: `NNNN` is the zero-padded
sprint number in filenames (e.g. `sprint-0003-plan.md`), `N` is the bare sprint number in
messages (e.g. `Sprint 3`), and `0.1.x` / `0.1.y` are the version being released and the
previous version (e.g. `0.1.5` / `0.1.4`). They are not literal.

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

**Single source of truth for tactical status.** If the project has graduated its backlog to a forge
tracker (via the `graduate-backlog` skill), honour the boundary recorded in
its **Work-Organization Boundary ADR** (the `graduate-backlog` hybrid boundary) — do **not**
double-maintain status. By default the
**tracker** owns per-issue/milestone status: close the corresponding milestone/issues there, and let
the roadmap **Sprint History** stay the narrative/version ledger (one row per sprint: phase, version,
summary) that *links out* to the milestone rather than re-tallying open items. If no tracker exists
(the common in-repo-only case), the roadmap remains canonical — update it as above.

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

**SBOM — catalogue the *released artifact*, one SBOM per artifact, not the source tree.** Scanning the
repo (`syft scan .`) catalogues your CI config, not what you ship: a tree with GitHub Actions
workflows yields `pkg:github/…` components and **no** ecosystem or standard-library packages at all
(verified against syft 1.36.0). Scan the **built artifact** — the compiled binary, the image archive,
the wheel — so the SBOM carries the linked dependency graph and, for compiled languages, the standard
library (`pkg:golang/stdlib@…`, which is what stdlib advisories match on). One syft pass emits both
formats, daemonless (export an image to an archive first, then scan from disk):

```bash
syft scan <built-binary|image-archive|wheel> -q \
  -o spdx-json=sbom.spdx.json \
  -o cyclonedx-json=sbom.cdx.json
```

**Assert the subject in CI so the wrong one cannot regress silently** (ADR-0009 — a gate, not a note).
Fail the release if the SBOM carries the source-tree tell-tale, or (for a compiled language) lacks its
standard library:

```bash
jq -e '[.components[].purl // empty] | any(startswith("pkg:github"))' sbom.cdx.json >/dev/null \
  && { echo "SBOM catalogued the repo, not the artifact"; exit 1; } || true
# compiled languages only — expect the stdlib in a binary's SBOM:
jq -e '[.components[].purl // empty] | any(startswith("pkg:golang/stdlib"))' sbom.cdx.json >/dev/null \
  || { echo "no stdlib — did you scan the source tree instead of the binary?"; exit 1; }
```

Two syft quirks worth pinning: on PE (Windows) binaries it adds an `application` component with
`version=UNKNOWN` and dozens of CPEs permuted from the filename (false-positive fuel) — restrict with
`--select-catalogers`; and a `file:` scan records the **absolute scan path** in the `file` component
(verified), so run it from a stable path. Attach both formats to the release (or upload as a CI
artifact). Covers the EU CRA SBOM expectation.

**Binary / source-tarball releases → SLSA provenance.** In the release workflow, hash the build outputs and hand off to the **tag-pinned** generator (the sanctioned exception to SHA-pinning):

```yaml
# build job:  outputs: { hashes: ${{ steps.hash.outputs.hashes }} }
- id: hash
  run: cd dist && echo "hashes=$(sha256sum * | base64 -w0)" >> "$GITHUB_OUTPUT"

provenance:
  needs: [build, publish]   # AFTER the job that creates the release — see the ordering note
  permissions: { actions: read, id-token: write, contents: write }
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v2.1.0
  with:
    base64-subjects: ${{ needs.build.outputs.hashes }}
    upload-assets: true
    # private-repository: true   # add if the repo is private
```

> **Ordering — do not let the generator create your release.** With `upload-assets: true` the
> generator **creates the GitHub release if one does not already exist**, and the release it creates
> is bare: `prerelease=false`, **no changelog notes** (observed on a real tag). If the provenance job
> only `needs: [build]`, it races the job that publishes the release and often wins — you get a
> notesless release that the publish job then finds already present and leaves unconfigured. The
> mirror failure is `release not found`, when a publish job instead assumes a release it did not
> create. Fix both directions: create the release in a **`publish`** job with an **idempotent** step
> (set notes from the CHANGELOG *whether or not* the release already exists — e.g. `gh release create
> … || gh release edit …`), and order provenance **after** it (`needs: [build, publish]`). The
> generator then uploads `.intoto.jsonl` to the already-configured release instead of creating a bare
> one. Neither failure is visible until a real tag is pushed — exercise it on a throwaway tag first.

This attaches a `.intoto.jsonl` to the release. **Verify it in CI before the release is done — a
required gate, not only a consumer guide:** run `slsa-verifier verify-artifact` against the built
output in the release run, so provenance that no one could verify fails the release (same ADR-0009
rung-1 reason as the cosign verify step below). Ship the identical command as a consumer guide at
`docs/howto/verifying-releases.md`:

```bash
slsa-verifier verify-artifact \
  --provenance-path <artifact>.intoto.jsonl \
  --source-uri github.com/{owner}/{repo} \
  <artifact>
```

> **Signing a raw blob with cosign (optional — SLSA already covers build provenance).** If a release
> additionally wants a detached cosign signature over a binary/tarball, use the **cosign v3 bundle
> form** — the pre-v3 `cosign sign-blob --output-signature … --output-certificate …` flag pair was
> **removed** and now fails with `create bundle file: open :` (verified against cosign 3.1.1). Sign,
> then verify back as a gate:
>
> ```bash
> cosign sign-blob   --yes --bundle <artifact>.sigstore.json <artifact>
> cosign verify-blob --bundle <artifact>.sigstore.json \
>   --certificate-identity-regexp '^https://github.com/{owner}/{repo}/\.github/workflows/<wf>\.yml@refs/' \
>   --certificate-oidc-issuer   'https://token.actions.githubusercontent.com' \
>   <artifact>
> ```

**Container images → cosign keyless signing** (OIDC, no keys). Sign the image **by digest** in the publish job:

```yaml
publish:
  if: startsWith(github.ref, 'refs/tags/v')
  permissions: { contents: read, packages: write, id-token: write }
  steps:
    - uses: sigstore/cosign-installer@<sha>   # v3, SHA-pinned
    - run: cosign sign --yes "${IMAGE}@${DIGEST}"     # DIGEST from the build-push step
    - run: |                                          # verify the signature just made — required gate
        cosign verify "${IMAGE}@${DIGEST}" \
          --certificate-oidc-issuer https://token.actions.githubusercontent.com \
          --certificate-identity-regexp '^https://github.com/{owner}/{repo}/\.github/workflows/<wf>\.yml@refs/tags/v'
```

**Verify in the same job — signing is not the control; a *verifiable* signature is.** Producing a
signature and never checking it back means a signature no consumer could verify ships silently; the
`cosign verify` step above (by **digest**, same job) fails the release instead (ADR-0009 rung 1).
Document the same command by tag for consumers in the README (note the issuer is a full `https://`
URL, the source-uri is not):

```bash
cosign verify {registry}/{owner}/{repo}:<tag> \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/{owner}/{repo}/\.github/workflows/<wf>\.yml@refs/tags/v'
```

The release **workflow** itself (job permissions, the SLSA-generator tag-pin exception, SHA-pinned `cosign-installer`) is hardened by `harden-github-actions`. This step's job at wrap-up is to confirm the release carries an SBOM + provenance/signing appropriate to its artifact type, that the **release run verifies its own signature/attestation** as a gate (not merely that a consumer guide exists), and that a verification guide exists.

> **Grounding**: SLSA + EU CRA (build integrity, SBOM) and EEF Ægis trusted publishing (Hex/BEAM). These are the `ships-artifacts` controls from the distribution-profile axis (see `bootstrap-project`). Note: signing and SLSA provenance are per-artifact-type — cosign for images, slsa-verifier for tarballs/binaries; don't conflate them — and **each must be verified back in the release run**, since a signature or attestation is a control only once something checks it.

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
- [ ] SBOM attached (syft: `sbom.spdx.json` + `sbom.cdx.json`), scanned from the **built artifact** not the source tree, with a CI subject assertion (no `pkg:github`; stdlib present for compiled langs)
- [ ] SLSA provenance (`.intoto.jsonl`) for binary/tarball releases, **or** cosign signature for container images
- [ ] Release created by an **idempotent `publish` job** (notes from CHANGELOG whether or not it exists), with `provenance: needs: [build, publish]` so the SLSA generator uploads to it rather than creating a bare, notesless release
- [ ] Release run **verifies its own** signature/attestation as a gate — `cosign verify` by digest (image) / `slsa-verifier verify-artifact` (tarball/binary) / `cosign verify-blob --bundle` (raw blob) — not only a consumer guide
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

**`ships-artifacts` profile**: confirm the release attached an SBOM and the right integrity evidence for its artifact type — a `.intoto.jsonl` that `slsa-verifier` accepts (tarball/binary) or a signature that `cosign verify` accepts (image) — that **the release run itself performed that verification as a gate** (not only that a consumer guide exists), and that a verification guide exists. For any cosign **blob** signature, confirm it uses the v3 `--bundle` form (the removed `--output-signature`/`--output-certificate` flags fail with `create bundle file: open :`).

## Related Skills

- `plan-sprint` - Create next sprint plan
- `bootstrap-project` - Initial project setup; declares the distribution profile / `ships-artifacts` marker
- `harden-github-actions` - Harden the release workflow that produces provenance (permissions, SLSA-generator tag exception, SHA-pinned cosign-installer)
- `setup-adrs` - ADR-0002 documents sprint practices
- `graduate-backlog` - once a project's backlog graduates to a forge tracker, defines the tracker boundary and single source of truth that Step 7 honours
