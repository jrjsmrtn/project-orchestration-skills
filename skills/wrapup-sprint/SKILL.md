---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: wrapup-sprint
description: Complete a sprint with retrospective, changelog update, and release tagging. Use when sprint work is done, at the end of a sprint cycle, or before starting a new sprint.
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
cat docs/sprints/sprint-NN-plan.md
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

Create `docs/sprints/sprint-NN-retrospective.md` (markdown) or `sprint-NN-retrospective.yml` (YAML):

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
git add docs/sprints/sprint-NN-plan.md
git add docs/sprints/sprint-NN-retrospective.md  # or .yml
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

### Step 11: Prepare Next Sprint

Suggest running `plan-sprint` skill to create Sprint N+1 plan.

## Outputs

This skill creates/updates:
- [ ] `docs/sprints/sprint-NN-plan.md` (status updated)
- [ ] `docs/sprints/sprint-NN-retrospective.md` (or `.yml`)
- [ ] `docs/sprints/README.md` (status update)
- [ ] `docs/roadmap/roadmap.md` (milestones and sprint history updated)
- [ ] `CHANGELOG.md` (new version section)
- [ ] `CLAUDE.md` (current sprint reference + propagated insights)
- [ ] Git commit: `chore: complete Sprint N wrap-up`
- [ ] Git tag: `v0.1.x`

## Validation

```bash
# Verify all tests pass
mix test  # or pytest, cargo test, etc.

# Verify changelog has new version
grep "## \[0.1.x\]" CHANGELOG.md

# Verify tag exists
git tag -l "v0.1.x"

# Verify retrospective exists
ls docs/sprints/sprint-NN-retrospective.*
```

## Related Skills

- `plan-sprint` - Create next sprint plan
- `bootstrap-project` - Initial project setup
- `setup-adrs` - ADR-0002 documents sprint practices
