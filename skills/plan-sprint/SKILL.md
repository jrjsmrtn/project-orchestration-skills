---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: plan-sprint
description: Create a sprint plan for a new development cycle. Use when starting a new sprint, after completing wrapup-sprint, or when initializing Sprint 1 for a new project.
---

# Plan Sprint

Create a sprint plan for a new development cycle.

## When to Use

- Starting a new sprint
- After completing `wrapup-sprint` for previous sprint
- When initializing Sprint 1 for a new project

## Required Inputs

1. **Sprint number** (e.g., 1, 2, 3)
2. **Sprint goal** (1-2 sentence objective)
3. **Deliverables or user stories** with acceptance criteria

## Workflow

### Step 1: Determine Sprint Context

Check current project state:

```bash
# Get current date
date +%Y-%m-%d

# Check latest version
git describe --tags --abbrev=0 2>/dev/null || echo "No tags yet"

# Check previous sprint (if any)
ls docs/sprints/sprint-*-plan.md 2>/dev/null | tail -1

# Check current roadmap phase
cat docs/roadmap/roadmap.md 2>/dev/null | head -30
```

Calculate:
- **Sprint number**: Previous + 1, or 1 if first sprint
- **Target version**: Current patch + 1 (e.g., v0.1.2 → v0.1.3)
- **Current phase**: From roadmap (e.g., "Phase 1: Foundation")
- **Start date**: Today

### Step 2: Choose Sprint Plan Format

Two formats are available. Choose based on project type:

- **Minimal** — for technical/infrastructure projects or highly focused sprints: deliverables with acceptance criteria, no user stories
- **Structured** — for user-facing projects or projects needing traceability: user stories with acceptance criteria

### Step 3: Create Sprint Plan

Create `docs/sprints/sprint-NNNN-plan.md` (4-digit zero-padded, e.g., `sprint-0001-plan.md`):

#### Minimal Format

```markdown
# Sprint [N] — [Goal Line]

**Target Version**: v0.1.x
**Phase**: [Current roadmap phase, e.g., "Phase 1: Foundation"]
**Status**: In Progress
**Started**: [Date]

## Goal

[1-2 sentence problem statement — what this sprint accomplishes and why]

## Context

[Only if this sprint builds on prior sprints or requires background. Otherwise omit.]

## Deliverables

### 1. [Component/Module Name]

- [Feature or change 1]
- [Feature or change 2]

### 2. [Another Component]

- [Feature or change 1]

## Files

| Action | File |
|--------|------|
| Create | `path/to/new/file` |
| Modify | `path/to/existing/file` |

## Acceptance Criteria

- [ ] [Specific, verifiable requirement 1]
- [ ] [Specific, verifiable requirement 2]
- [ ] All tests passing
- [ ] Code quality gates pass (format, lint, etc.)
```

#### Structured Format

```markdown
# Sprint [N] Plan

**Target Version**: v0.1.x
**Phase**: [Current roadmap phase, e.g., "Phase 1: Foundation"]
**Duration**: [Start Date] - [End Date]
**Status**: In Progress

## Sprint Goal

[Clear, measurable 1-2 sentence goal that defines success for this sprint]

## User Stories

### Story [N.1]: [Story Title]

**Priority**: High | **Status**: Planned

**User Story**:
> As a [role], I want [feature/capability] so that [benefit/value].

**Acceptance Criteria**:
- [ ] [Criterion 1 - specific, testable]
- [ ] [Criterion 2 - specific, testable]
- [ ] [Criterion 3 - specific, testable]

**BDD Scenarios** (for user-facing projects using Gherkin):
- [ ] Scenario: [Happy path]
- [ ] Scenario: [Edge case or error handling]

**Technical Notes**:
- [Implementation consideration]
- [Dependency or blocker]

**Files Likely Affected**:
- `path/to/file1.ex`
- `path/to/file2.ex`

---

### Story [N.2]: [Story Title]

[Repeat structure for each story]

---

## Technical Tasks

Tasks not tied to specific user stories:

- [ ] [Task 1]
- [ ] [Task 2]

## Dependencies

- [Dependency 1 — what it blocks]
- [Dependency 2 — what it blocks]

## Risks

- [Risk 1] → [Mitigation]
- [Risk 2] → [Mitigation]

## Definition of Done

- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No critical bugs outstanding
```

### Step 4: Update CLAUDE.md

Update the "Current Development Status" section:

```markdown
## Current Development Status

- **Current Sprint**: Sprint [N] (see docs/sprints/sprint-[NNNN]-plan.md)
- **Sprint Goal**: [Sprint goal]
- **Next Milestone**: v0.1.x
```

### Step 5: Update Sprint Index

Create or update `docs/sprints/README.md`:

```markdown
## Current Status

- **Active Sprint**: Sprint [N]
- **Target Version**: v0.1.x
- **Sprint Goal**: [Goal]

## Sprint Index

| Sprint | Phase | Version | Status | Plan | Retrospective |
|--------|-------|---------|--------|------|---------------|
| [N] | [Phase] | v0.1.x | In Progress | [Plan](sprint-NNNN-plan.md) | - |
| [N-1] | [Phase] | v0.1.y | Complete | [Plan](sprint-MMMM-plan.md) | [Retro](sprint-MMMM-retrospective.md) |
```

### Step 6: Commit Sprint Plan

```bash
git add docs/sprints/sprint-NNNN-plan.md
git add docs/sprints/README.md
git add CLAUDE.md

git commit -m "docs: add Sprint N plan (v0.1.x)"
```

## Sprint Planning Tips

1. **Start with the goal**: What's the one thing that defines success?
2. **Be realistic**: Don't overcommit — a focused sprint beats an ambitious one
3. **Keep deliverables small**: If something feels too large, split it
4. **Surface blockers early**: Dependencies and risks belong in the plan, not discovered mid-sprint

## Outputs

This skill creates:
- [ ] `docs/sprints/sprint-NNNN-plan.md`
- [ ] Updated `docs/sprints/README.md`
- [ ] Updated `CLAUDE.md` (current sprint reference)
- [ ] Git commit: `docs: add Sprint N plan`

## Validation

```bash
# Verify sprint plan exists
ls docs/sprints/sprint-NNNN-plan.md

# Verify CLAUDE.md updated
grep "Current Sprint" CLAUDE.md

# Verify sprint index updated
grep "Sprint N" docs/sprints/README.md
```

## Related Skills

- `wrapup-sprint` - Complete sprint with retrospective
- `bootstrap-project` - Initial project setup (includes Sprint 1)
- `setup-adrs` - ADR-0002 documents sprint practices
