---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: bootstrap-project
description: Bootstrap a new project with foundational artifacts following AI-Assisted Project Orchestration best practices. Use when starting a new software project, converting existing projects, or setting up for AI-assisted development.
---

# Project Bootstrap

Bootstrap a new project with foundational artifacts following AI-Assisted Project Orchestration best practices.

## When to Use

- Starting a new software project
- Converting an existing project to follow best practices
- Setting up a project for AI-assisted development

## Required Inputs

Before running this skill, gather from the user:

1. **Project name** (kebab-case, e.g., `my-awesome-project`)
2. **Project description** (1-2 sentences)
3. **Project category**:
   - **Development**: Software (applications, libraries, services)
   - **Infrastructure**: Operations (homelab, deployment, monitoring)
   - **Hybrid**: Both development and operations components
4. **Project type** (library, web application, CLI tool, API service, infrastructure automation)
5. **Technology stack** (e.g., "Elixir/Phoenix/Ash", "Python/FastAPI", "Ansible")
6. **License** (MIT, Apache-2.0, proprietary)
7. **Git remotes** (private origin only, or multi-remote with public GitHub/GitLab)

**Why project category matters:**
- **Development**: ADR-0004 (Operations) is skipped
- **Infrastructure**: ADR-0004 is created (backup, monitoring, change management)
- **Hybrid**: ADR-0004 is created, covering both application and infrastructure operations

## Workflow

### Phase 1: Directory Structure

Create the Diátaxis documentation structure:

```
docs/
├── tutorials/           # Learning-oriented
│   └── .gitkeep
├── howto/              # Problem-oriented (or how-to/)
│   └── .gitkeep
├── reference/          # Information-oriented
│   └── .gitkeep
├── explanation/        # Understanding-oriented
│   └── .gitkeep
├── adr/                # Architecture Decision Records
│   └── .gitkeep
├── architecture/       # C4 DSL models
│   └── .gitkeep
├── sprints/            # Sprint planning and tracking
│   └── .gitkeep
└── roadmap/            # Project roadmap and phase planning
    └── .gitkeep
```

For BDD projects, also create:
```
features/               # or test/features/ depending on ecosystem
└── step_definitions/
```

### Phase 2: Git Initialization

1. Initialize git if not already: `git init`
2. Create appropriate .gitignore using gitignore.io for the technology stack
3. Add common security patterns to .gitignore:
   ```
   # Secrets and credentials
   .env
   .env.*
   !.env.example
   *.pem
   *.key
   credentials.json
   secrets.yaml

   # Claude Code local files
   CLAUDE.local.md
   ```
4. Set up gitflow branches:
   - Create initial commit on `main`
   - Create `develop` branch from `main`
   - Set `develop` as default working branch

### Phase 3: Create CLAUDE.md

Generate a project-specific CLAUDE.md with:

```markdown
# [Project Name]

[Project description]

## Project Context

- **Category**: [Development/Infrastructure/Hybrid]
- **Type**: [library/application/service/infrastructure]
- **Stack**: [technology stack]
- **License**: [license]

## Current Development Status

- **Current Sprint**: Sprint 1 (see docs/sprints/sprint-0001-plan.md)
- **Sprint Goal**: [initial goal]
- **Status**: Not started
- **Next Milestone**: v0.1.0

## Foundational ADRs

Read these at the start of each AI session for complete context:

| ADR | Purpose | Summary |
|-----|---------|---------|
| [ADR-0001](docs/adr/0001-record-architecture-decisions.md) | HOW TO DECIDE | Decision methodology |
| [ADR-0002](docs/adr/0002-adopt-development-best-practices.md) | HOW TO DEVELOP | Development practices |
| [ADR-0003](docs/adr/0003-*.md) | WHAT TECH | Technology stack |
| [ADR-0004](docs/adr/0004-operations-best-practices.md) | HOW TO OPERATE | Operations practices (Infrastructure/Hybrid only) |

## Development Practices

This project follows [AI-Assisted Project Orchestration patterns](https://github.com/jrjsmrtn/ai-assisted-project-orchestration):

- **Testing**: [TDD/BDD approach based on project type]
- **Versioning**: Semantic versioning (0.x.x during development)
- **Git Workflow**: Gitflow (main, develop, feature/*, release/*, hotfix/*)
- **Documentation**: Diátaxis framework
- **Architecture**: C4 DSL models in architecture/

## Quick Commands

```bash
# Run tests
[ecosystem-specific test command]

# Run quality checks
[ecosystem-specific lint/format commands]

# Validate architecture model
make validate-architecture
```

## AI Collaboration Notes

**Project-specific guidance:**
- [Domain-specific terminology and concepts]
- [Key architectural decisions to remember]
- [Common patterns used in this codebase]

**AI delegation in this project:**
- **AI leads**: [e.g., test generation, documentation, boilerplate]
- **Human leads**: [e.g., architecture decisions, security review]
- **Collaborative**: [e.g., feature implementation, code review]

**What AI should know:**
- [Critical constraints or requirements]
- [Non-obvious conventions]
- [Known limitations or tech debt]
```

### Phase 4: Create CHANGELOG.md

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Foundation ADRs (0001, 0002, 0003)
- Diátaxis documentation framework
- C4 DSL architecture skeleton

[Unreleased]: https://github.com/[username]/[project]/compare/v0.1.0...HEAD
```

### Phase 5: Create Roadmap

Create `docs/roadmap/roadmap.md` with an initial project roadmap:

```markdown
# [Project Name] Roadmap

## Vision

[1-2 sentence project vision — what the project achieves when complete]

## Phases

### Phase 1: Foundation
**Target**: v0.1.x
**Focus**: [Core infrastructure, initial capabilities]

- [ ] [Milestone 1]
- [ ] [Milestone 2]

### Phase 2: [Next Major Capability]
**Target**: v0.2.x
**Focus**: [What this phase delivers]

- [ ] [Milestone 1]
- [ ] [Milestone 2]

### Phase 3: [Production Readiness]
**Target**: v1.0.0
**Focus**: [Hardening, documentation, release]

- [ ] [Milestone 1]
- [ ] [Milestone 2]

## Sprint History

| Sprint | Phase | Version | Summary |
|--------|-------|---------|---------|
| 1 | Foundation | v0.1.0 | [Brief description] |
```

The roadmap is a living document — update it as phases complete and new ones emerge.

### Phase 6: Create README.md

Generate a README.md with:
- Project name and description
- Installation instructions (placeholder)
- Quick start (placeholder)
- Documentation links
- License
- Contributing guidelines reference

### Phase 7: Seed Traced Artifacts (if Audience Registry exists)

If SPARK analysis created `docs/reference/audience-registry.md`, seed initial artifacts:

**1. BDD Feature Directories** (if using BDD):
```
features/
├── user/           # Primary audience scenarios
│   └── .gitkeep
├── api/            # Integration audience scenarios
│   └── .gitkeep
└── ops/            # Operational audience scenarios
    └── .gitkeep
```

**2. C4 Model Skeleton** with persons from Audience Registry:
```dsl
# In architecture/workspace.dsl
model {
    # From Audience Registry
    user = person "User" "Primary audience" "Primary"
    # Add persons for each Primary/Integration audience
}
```

**3. Diátaxis Stubs** per audience:
```
docs/
├── tutorials/
│   └── getting-started.md     # A1: Primary audience
├── howto/
│   └── deployment.md          # A3: Operational audience
├── reference/
│   └── api.md                 # A2: Integration audience
└── explanation/
    └── architecture.md        # A4: Contribution audience
```

**4. Documentation Frontmatter Template**:
```markdown
---
audience: A1  # Reference to Audience Registry
title: Getting Started
---
```

> **Pattern Reference**: See [AUDIENCE-DRIVEN ARTIFACTS](../../../docs/patterns/inception/audience-driven-artifacts.md)

### Phase 8: Invoke Related Skills

After completing the bootstrap, suggest invoking:

1. **setup-adrs** - Create ADR-0001, 0002, 0003 (and 0004 for Infrastructure/Hybrid)
2. **setup-pre-commit** - Configure quality gates
3. **setup-architecture-as-code** - Create architecture model (C4/Structurizr)
4. **plan-sprint** - Create Sprint 1 plan

## Outputs

This skill creates:
- [ ] `docs/` directory structure (Diátaxis)
- [ ] `.gitignore` (technology-specific + security patterns)
- [ ] `CLAUDE.md` (project-specific)
- [ ] `CHANGELOG.md` (initialized)
- [ ] `docs/roadmap/roadmap.md` (initial phases)
- [ ] `README.md` (skeleton)
- [ ] Git branches (`main`, `develop`)
- [ ] (If Audience Registry) `features/` subdirectories per audience category
- [ ] (If Audience Registry) Diátaxis doc stubs with audience frontmatter

## Validation

Verify successful bootstrap:
1. All directories exist with .gitkeep files
2. CLAUDE.md contains accurate project information
3. Git is initialized with main and develop branches
4. .gitignore covers technology stack and security patterns
5. (If Audience Registry) Traced artifacts align with audience categories

## Related Skills

- `analyze-project` - Run SPARK analysis before bootstrap
- `setup-adrs` - Next step: create foundational ADRs
- `setup-pre-commit` - Configure pre-commit hooks
- `setup-architecture-as-code` - Create architecture model
- `plan-sprint` - Create initial sprint plan
