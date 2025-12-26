---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: wrapup-sprint
description: Complete a sprint with proper documentation, retrospective, and release tagging. Use when all sprint stories are completed, at the end of a sprint cycle, or before starting a new sprint.
---

# Sprint Completion

Complete a sprint with proper documentation, retrospective, and release tagging.

## When to Use

- When all user stories in a sprint are completed
- At the end of a sprint cycle (typically 2 weeks)
- Before starting a new sprint

## Required Inputs

1. **Sprint number** (e.g., 3)
2. **Version to release** (e.g., 0.4.0)
3. **Sprint goal** (from sprint plan)
4. **Completed stories** with points and BDD scenario counts
5. **Any stories deferred** to next sprint

## Prerequisites

Before running this skill, verify:
- [ ] All planned stories are complete OR explicitly deferred
- [ ] All tests passing (`mix test` or `pytest`)
- [ ] All pre-commit and pre-push hooks pass
- [ ] Code reviewed and merged to develop branch

## Workflow

### Step 1: Create/Update Sprint Backlog

If `docs/sprints/sprint-N-backlog.md` doesn't exist, create it. Otherwise, update it.

**Sprint Backlog Structure**:

```markdown
# Sprint [N] Backlog

**Target Version**: v0.x.0
**Status**: ✅ Complete
**Dates**: [Start Date] - [End Date] ([duration])

## Sprint Goal

[One-sentence sprint goal]

## Story Points Summary

| Category | Points |
|----------|--------|
| Total Planned | XX |
| Completed | XX |
| Deferred | 0 |

## Backlog Items

### Epic: [Epic Name]

#### Story [N.1]: [Story Title]
- **Points**: X
- **Priority**: High/Medium/Low
- **Status**: ✅ Complete

**User Story**: As a [role], I want [feature] so that [benefit].

**Acceptance Criteria**:
- [x] Criterion 1
- [x] Criterion 2
- [x] Criterion 3

**BDD Scenarios**: X scenarios - **ALL PASSING** ✅

---

[Repeat for each story]

## Definition of Done

- [x] All acceptance criteria met
- [x] All BDD scenarios passing
- [x] Code reviewed
- [x] Tests passing (unit + integration)
- [x] Documentation updated
- [x] No critical bugs outstanding
```

### Step 2: Create Sprint Retrospective

Create `docs/sprints/sprint-N-retrospective.md`:

```markdown
# Sprint [N] Retrospective

**Duration**: [Start] - [End] ([X] days)
**Goal**: [Sprint goal]
**Completed**: [Date]
**Version**: v0.x.0

## Sprint Summary

[2-3 sentence narrative summary of what was accomplished]

| Metric | Value |
|--------|-------|
| Stories Completed | X/X (100%) |
| Story Points | XX/XX (100%) |
| BDD Scenarios | XX total |
| Test Coverage | XX% |

## Sprint Backlog Completion

| Story | Points | Status | Scenarios | Notes |
|-------|--------|--------|-----------|-------|
| [Story 1] | X | ✅ | X | [brief note] |
| [Story 2] | X | ✅ | X | [brief note] |
| **Total** | **XX** | **100%** | **XX** | |

## What Went Well

1. **[Success 1]**
   - Evidence: [specific outcome]
   - Impact: [benefit achieved]

2. **[Success 2]**
   - Evidence: [specific outcome]
   - Impact: [benefit achieved]

3. **[Success 3]**
   - Evidence: [specific outcome]
   - Impact: [benefit achieved]

## What Could Be Improved

1. **[Challenge 1]**
   - Root Cause: [why it happened]
   - Solution: [how to address]

2. **[Challenge 2]**
   - Root Cause: [why it happened]
   - Solution: [how to address]

## Key Learnings

1. **[Learning 1]**: [insight gained]
2. **[Learning 2]**: [insight gained]
3. **[Learning 3]**: [insight gained]

## Action Items for Next Sprint

### Process Improvements
- [ ] [Action item 1]
- [ ] [Action item 2]

### Technical Debt
- [ ] [Tech debt item if any]

### Documentation
- [ ] [Doc improvement if any]

## AI Collaboration Effectiveness

| Task Type | Effectiveness | Notes |
|-----------|---------------|-------|
| Code generation | High/Medium/Low | [observation] |
| Test generation | High/Medium/Low | [observation] |
| Documentation | High/Medium/Low | [observation] |
| Architecture | High/Medium/Low | [observation] |

## Sprint Highlights

- **Most Valuable Deliverable**: [what and why]
- **Best Innovation**: [new approach that worked well]
- **Key Metric**: [impressive statistic]

## Looking Ahead

**Potential Sprint [N+1] Focus Areas**:
- [Area 1]
- [Area 2]
- [Area 3]

## Final Assessment

**Overall Rating**: ⭐⭐⭐⭐⭐ (X/5)

[Brief final thoughts on the sprint]
```

### Step 3: Update CHANGELOG.md

Add new version section at the top of CHANGELOG.md (after `## [Unreleased]`):

```markdown
## [0.x.0] - YYYY-MM-DD

### Added
- **[Story 1]**: [Description]
  - [Key feature/capability]
  - [BDD scenario count] scenarios
- **[Story 2]**: [Description]
  - [Key feature/capability]
  - [BDD scenario count] scenarios

### Changed
- [Any changes to existing functionality]

### Fixed
- [Any bug fixes]

### Technical Details
- **Sprint**: [N]
- **Story Points**: [XX]
- **BDD Scenarios**: [XX] total
- **Test Coverage**: [XX]%
```

Update version comparison links at bottom:
```markdown
[0.x.0]: https://github.com/[user]/[repo]/compare/v0.[x-1].0...v0.x.0
```

### Step 4: Update Sprint Index

Update `docs/sprints/README.md`:

```markdown
## Current Status

- **Latest Release**: v0.x.0
- **Completed Sprint**: Sprint [N]
- **Next Sprint**: Sprint [N+1] (planning)

## Sprint History

| Sprint | Version | Status | Stories | Points |
|--------|---------|--------|---------|--------|
| [N] | v0.x.0 | ✅ Complete | X | XX |
| [N-1] | v0.[x-1].0 | ✅ Complete | X | XX |
```

### Step 5: Update CLAUDE.md

Update the "Current Development Status" section:

```markdown
## Current Development Status

- **Current Sprint**: Sprint [N+1] (see docs/sprints/sprint-[N+1]-plan.md)
- **Sprint Goal**: [Next sprint goal or "Planning"]
- **Status**: Planning
- **Latest Release**: v0.x.0
```

### Step 6: Create Sprint Wrap-up Commit

```bash
# Stage all sprint documentation updates
git add docs/sprints/sprint-N-backlog.md
git add docs/sprints/sprint-N-retrospective.md
git add docs/sprints/README.md
git add CHANGELOG.md
git add CLAUDE.md

# Commit with conventional format
git commit -m "chore: complete Sprint N wrap-up (v0.x.0)"
```

### Step 7: Tag Release

```bash
# Create annotated tag
git tag -a v0.x.0 -m "Sprint N Complete: [brief description]"

# Push to origin (private)
git push origin develop --tags

# If multi-remote and ready for public release:
# git checkout main
# git merge develop
# git push origin main --tags
# git push github main --tags  # public
```

### Step 8: Prepare Next Sprint

Suggest running `plan-sprint` skill to create Sprint N+1 plan.

## Quality Checklist

Before marking sprint complete, verify all items:

- [ ] All user stories marked complete in sprint backlog
- [ ] All BDD scenarios passing
- [ ] All documentation deliverables completed
- [ ] Sprint backlog document created/updated
- [ ] Sprint retrospective written
- [ ] CHANGELOG.md updated with new version
- [ ] docs/sprints/README.md current status updated
- [ ] CLAUDE.md current sprint reference updated
- [ ] Version bumped appropriately (0.x.0)
- [ ] Sprint wrap-up commit created
- [ ] Git tag created for release
- [ ] All commits follow conventional commit format
- [ ] Pre-commit and pre-push hooks pass

## Outputs

This skill creates/updates:
- [ ] `docs/sprints/sprint-N-backlog.md`
- [ ] `docs/sprints/sprint-N-retrospective.md`
- [ ] `docs/sprints/README.md` (status update)
- [ ] `CHANGELOG.md` (new version section)
- [ ] `CLAUDE.md` (current sprint reference)
- [ ] Git commit: `chore: complete Sprint N wrap-up (v0.x.0)`
- [ ] Git tag: `v0.x.0`

## Validation

```bash
# Verify all tests pass
mix test  # or pytest

# Verify changelog has new version
grep "## \[0.x.0\]" CHANGELOG.md

# Verify tag exists
git tag -l "v0.x.0"

# Verify CLAUDE.md updated
grep "Latest Release" CLAUDE.md
```

## Related Skills

- `plan-sprint` - Create next sprint plan
- `bootstrap-project` - Initial project setup
- `create-adrs` - ADR-0002 documents sprint practices
