---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: plan-sprint
description: Create a new sprint plan with backlog, goals, and AI collaboration strategy. Use when starting a new 2-week sprint, after completing wrapup-sprint, or when initializing Sprint 0/1 for a new project.
---

# Setup Sprint

Create a new sprint plan with backlog, goals, and AI collaboration strategy.

## When to Use

- Starting a new sprint (typically every 2 weeks)
- After completing `wrapup-sprint` for previous sprint
- When initializing Sprint 0/1 for a new project

## Required Inputs

1. **Sprint number** (e.g., 1, 2, 3)
2. **Sprint duration** (default: 2 weeks)
3. **Sprint goal** (1-2 sentence objective)
4. **User stories** with acceptance criteria
5. **Story point estimates** (optional, can be added during planning)

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
```

Calculate:
- **Sprint number**: Previous + 1, or 1 if first sprint
- **Target version**: Current minor + 1 (e.g., v0.3.0 → v0.4.0)
- **Start date**: Today or next Monday
- **End date**: Start + 14 days (2 weeks)

### Step 2: Create Sprint Plan

Create `docs/sprints/sprint-N-plan.md`:

```markdown
# Sprint [N] Plan

**Target Version**: v0.x.0
**Duration**: [Start Date] - [End Date] (2 weeks)
**Status**: 🔄 In Progress

## Sprint Goal

[Clear, measurable 1-2 sentence goal that defines success for this sprint]

## Story Points Summary

| Category | Points |
|----------|--------|
| Total Planned | XX |
| Completed | 0 |
| In Progress | 0 |
| Remaining | XX |

## User Stories

### Story [N.1]: [Story Title]

**Points**: [X] | **Priority**: High | **Status**: 📋 Planned

**User Story**:
> As a [role], I want [feature/capability] so that [benefit/value].

**Acceptance Criteria**:
- [ ] [Criterion 1 - specific, testable]
- [ ] [Criterion 2 - specific, testable]
- [ ] [Criterion 3 - specific, testable]

**BDD Scenarios** (if applicable):
- [ ] Scenario: [Happy path scenario]
- [ ] Scenario: [Edge case scenario]
- [ ] Scenario: [Error handling scenario]

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

- [ ] **Task 1**: [Description] (X pts)
- [ ] **Task 2**: [Description] (X pts)

## AI Collaboration Strategy

Define how AI assistance will be used this sprint:

| Task Type | AI Role | Human Role |
|-----------|---------|------------|
| Code generation | Lead | Review |
| Test generation | Lead | Validate |
| Architecture decisions | Assist | Lead |
| Documentation | Lead | Review |
| Security review | Assist | Lead |
| Code review | Assist | Final approval |

**AI Delegation Guidelines for This Sprint**:
- **AI leads**: [specific tasks AI should drive]
- **Human leads**: [specific tasks requiring human judgment]
- **Collaborative**: [tasks requiring close AI-human partnership]

## Dependencies

### External Dependencies
- [ ] [External dependency 1]
- [ ] [External dependency 2]

### Internal Dependencies
- Story N.2 depends on Story N.1 completion

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Medium | High | [Mitigation strategy] |
| [Risk 2] | Low | Medium | [Mitigation strategy] |

## Definition of Done

Sprint is complete when:
- [ ] All user stories meet acceptance criteria
- [ ] All BDD scenarios passing (if applicable)
- [ ] All tests passing (unit + integration)
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No critical bugs outstanding
- [ ] Sprint retrospective completed

## Daily Standup Template

Track daily progress:

### Day 1 ([Date])
- **Completed**:
- **In Progress**:
- **Blockers**:
- **AI Collaboration Notes**:

[Add entries as sprint progresses]

## Notes

[Space for additional notes, decisions made during sprint, etc.]
```

### Step 3: Create Sprint Backlog (Alternative Format)

Some projects prefer a separate backlog file. Create `docs/sprints/sprint-N-backlog.md` if using that convention:

```markdown
# Sprint [N] Backlog

**Target Version**: v0.x.0
**Status**: 🔄 Active
**Dates**: [Start] - [End]

## Sprint Goal

[Goal from plan]

## Backlog

| # | Story | Points | Priority | Status |
|---|-------|--------|----------|--------|
| N.1 | [Story title] | X | High | 📋 Planned |
| N.2 | [Story title] | X | High | 📋 Planned |
| N.3 | [Story title] | X | Medium | 📋 Planned |

**Total**: XX pts | **Completed**: 0 pts

## Detailed Stories

[Link to sprint-N-plan.md for full details]
```

### Step 4: Update CLAUDE.md

Update the "Current Development Status" section:

```markdown
## Current Development Status

- **Current Sprint**: Sprint [N] (see docs/sprints/sprint-[N]-plan.md)
- **Sprint Goal**: [Sprint goal]
- **Status**: Day 1 of 14, starting
- **Next Milestone**: v0.x.0
```

### Step 5: Update Sprint Index

Update `docs/sprints/README.md`:

```markdown
## Current Status

- **Active Sprint**: Sprint [N]
- **Target Version**: v0.x.0
- **Sprint Goal**: [Goal]

## Sprint Index

| Sprint | Version | Status | Plan | Retrospective |
|--------|---------|--------|------|---------------|
| [N] | v0.x.0 | 🔄 Active | [Plan](sprint-N-plan.md) | - |
| [N-1] | v0.[x-1].0 | ✅ Complete | [Plan](sprint-[N-1]-plan.md) | [Retro](sprint-[N-1]-retrospective.md) |
```

### Step 6: Commit Sprint Plan

```bash
git add docs/sprints/sprint-N-plan.md
git add docs/sprints/README.md
git add CLAUDE.md

git commit -m "docs: add Sprint N plan (v0.x.0)"
```

## Story Point Guidelines

If using story points, apply consistent estimation:

| Points | Complexity | Typical Duration | Example |
|--------|------------|------------------|---------|
| 1 | Trivial | < 2 hours | Config change, small fix |
| 2 | Simple | 2-4 hours | Single function, simple feature |
| 3 | Medium | 4-8 hours | Multiple functions, moderate feature |
| 5 | Complex | 1-2 days | New module, significant feature |
| 8 | Very Complex | 2-3 days | Major feature, integration work |
| 13 | Epic-sized | > 3 days | Should be split into smaller stories |

**Sprint Capacity**: Typically 20-40 points per 2-week sprint (varies by team/individual).

## Outputs

This skill creates:
- [ ] `docs/sprints/sprint-N-plan.md`
- [ ] `docs/sprints/sprint-N-backlog.md` (optional)
- [ ] Updated `docs/sprints/README.md`
- [ ] Updated `CLAUDE.md` (current sprint reference)
- [ ] Git commit: `docs: add Sprint N plan`

## Validation

```bash
# Verify sprint plan exists
cat docs/sprints/sprint-N-plan.md | head -20

# Verify CLAUDE.md updated
grep "Current Sprint" CLAUDE.md

# Verify sprint index updated
grep "Sprint N" docs/sprints/README.md
```

## Sprint Planning Tips

1. **Start with the goal**: What's the one thing that defines success?
2. **Be realistic**: Don't overcommit; 70-80% capacity is sustainable
3. **Include buffer**: Reserve 10-20% for unexpected issues
4. **Define AI strategy**: Decide upfront what AI leads vs. assists
5. **Identify dependencies**: Surface blockers early
6. **Keep stories small**: If >8 points, consider splitting

## Related Skills

- `wrapup-sprint` - Complete sprint with retrospective
- `bootstrap-project` - Initial project setup (includes Sprint 1)
- `create-adrs` - ADR-0002 documents sprint practices
