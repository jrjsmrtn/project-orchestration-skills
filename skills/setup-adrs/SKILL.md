---
# SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com>
# SPDX-License-Identifier: MIT
name: setup-adrs
description: Create the foundational Architecture Decision Record (ADR) sequence for a new project. Use after bootstrap-project, when establishing decision documentation, or when standardizing ADR practices.
---

# Foundation ADRs

Create the foundational Architecture Decision Record (ADR) sequence for a new project.

## When to Use

- After running `bootstrap-project` skill
- When establishing decision documentation for an existing project
- When standardizing ADR practices across projects

## Required Inputs

1. **Project name** and description (from CLAUDE.md or user)
2. **Project type**: Development, Infrastructure, or Hybrid
3. **Technology stack** decision and rationale
4. **Development practices** to adopt (can use defaults)
5. **Operations requirements** (critical for Infrastructure projects)
6. **Project-specific constraints** or requirements

## Foundational ADR Framework

Every project should have these foundational ADRs:

| ADR | Purpose | Scope | Critical For |
|-----|---------|-------|--------------|
| ADR-0001 | HOW TO DECIDE | Decision methodology | All projects |
| ADR-0002 | HOW TO DEVELOP | Development practices | All projects |
| ADR-0003 | WHAT TECH | Technology stack | All projects |
| ADR-0004 | HOW TO OPERATE | Operations practices | Infrastructure, Hybrid |

**Note**: ADR-0004 is lightweight for pure development projects but comprehensive for infrastructure projects.

### Audience Traceability

ADRs serve the **Contribution** audience category (maintainers, contributors, future architects). They provide the "understanding-oriented" content in Diátaxis terms, explaining *why* decisions were made.

If an Audience Registry exists from SPARK analysis, ADRs should be tagged:
```markdown
---
audience: A4  # Contribution audience
---
```

> **Pattern Reference**: See [AUDIENCE-DRIVEN ARTIFACTS](../../../docs/patterns/inception/audience-driven-artifacts.md)

## ADR Numbering Convention

Before creating ADRs, check for existing ones to prevent conflicts:

```bash
# Check highest ADR number
ls docs/adr/*.md 2>/dev/null | grep -E '[0-9]{4}-' | sort -V | tail -1

# If no ADRs exist, start with 0001
```

**Format**: `NNNN-title-with-hyphens.md` (e.g., `0001-record-architecture-decisions.md`)
**Internal Title**: `# ADR-NNNN: Title` (e.g., `# ADR-0001: Record Architecture Decisions`)

## Workflow

### ADR-0001: Record Architecture Decisions

Create `docs/adr/0001-record-architecture-decisions.md`:

```markdown
# ADR-0001: Record Architecture Decisions

Date: [YYYY-MM-DD]

## Status

Accepted

## Context

[Project name] requires a systematic approach to documenting significant architectural and technical decisions. As the project evolves, we need to maintain a clear record of why decisions were made, what alternatives were considered, and what trade-offs were accepted.

This is especially important for AI-assisted development, where decisions made in one session need to be understood in future sessions.

## Decision

We will use Architecture Decision Records (ADRs) to document significant architectural decisions.

**ADR Location**: All ADRs stored in `docs/adr/` directory

**ADR Format**: Following the format established by Michael Nygard:
- **Title**: Short noun phrase (ADR-NNNN: Title)
- **Status**: Proposed, Accepted, Deprecated, Superseded
- **Context**: Forces at play, including technical, business, and social
- **Decision**: The response to these forces
- **Consequences**: Resulting context after applying the decision

**Numbering**: Sequential four-digit format (0001, 0002, ...) with no gaps

**What Warrants an ADR**:
- Technology stack choices
- Architectural patterns adopted
- Build/deployment approaches
- Integration decisions
- Security-related choices
- Decisions that would be costly to reverse

## Consequences

**Positive**:
- Clear record of why decisions were made
- Context preserved for future maintainers and AI assistants
- Reduced repeated discussions about settled decisions
- Audit trail for architectural evolution

**Negative**:
- Overhead of writing and maintaining ADRs
- Risk of ADRs becoming outdated if not maintained

## References

- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) - Michael Nygard
- [ADR GitHub Organization](https://adr.github.io/)
```

### ADR-0002: Adopt Development Best Practices

Create `docs/adr/0002-adopt-development-best-practices.md`:

**Customize based on project type and technology stack.**

**For Elixir projects**, include:
- TDD with ExUnit
- BDD with Cabbage/Cucumber (if applicable)
- Semantic versioning (0.x.x during development)
- Gitflow workflow
- Keep a Changelog
- C4 DSL architecture
- Diátaxis documentation
- Sprint-based development
- Pre-commit hooks (mix format, mix credo, gitleaks)
- Dialyzer type checking

**For Python projects**, include:
- TDD with pytest
- BDD with Behave + Playwright (if applicable)
- Semantic versioning (0.x.x during development)
- Gitflow workflow
- Keep a Changelog
- C4 DSL architecture
- Diátaxis documentation
- Sprint-based development
- Pre-commit hooks (ruff, mypy, gitleaks)
- Type hints with mypy

**Key Sections** (adapt from CLAUDE.template.md or project ADRs):
1. Testing Strategy (TDD, BDD if applicable)
2. Semantic Versioning Strategy
3. Git Workflow (Gitflow-based)
4. Change Documentation (Keep a Changelog)
5. Architecture as Code (C4 DSL)
6. Sprint-Based Development Lifecycle
7. Documentation Framework (Diátaxis)
8. CI/CD and Quality Automation
9. Conventional Commits

**Reference**: Use ragù's ADR-0002 (775 lines) as the comprehensive example, or pasture-management-system's ADR-0002 for detailed sprint procedures.

### ADR-0003: Technology Stack Decision

Create `docs/adr/0003-[technology-stack-name].md`:

```markdown
# ADR-0003: Use [Technology Stack]

Date: [YYYY-MM-DD]

## Status

Accepted

## Context

[Project name] requires [describe the technical needs].

Key requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

We evaluated several technology options for [specific technical domain].

## Decision

We will use [Technology Stack] for [project name].

**Core Technologies**:
- **Language**: [e.g., Elixir 1.18+, Python 3.12+]
- **Framework**: [e.g., Phoenix 1.7+, FastAPI]
- **Database**: [e.g., PostgreSQL 16+]
- **Additional**: [other key technologies]

**Rationale**:
- [Reason 1 with evidence]
- [Reason 2 with evidence]
- [Reason 3 with evidence]

**Alternatives Considered**:

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| [Option A] | [pros] | [cons] | Selected |
| [Option B] | [pros] | [cons] | Rejected |
| [Option C] | [pros] | [cons] | Rejected |

## Consequences

**Positive**:
- [Benefit 1]
- [Benefit 2]

**Negative**:
- [Trade-off 1]
- [Trade-off 2]

**Risks**:
- [Risk and mitigation]

## References

- [Relevant documentation links]
- [Comparison articles if applicable]
```

### ADR-0004: Operations Best Practices

Create `docs/adr/0004-operations-best-practices.md`:

**Scope varies by project type:**
- **Development projects**: Lightweight (deployment, monitoring basics)
- **Infrastructure projects**: Comprehensive (full operational practices)
- **Hybrid projects**: Moderate depth based on operational complexity

```markdown
# ADR-0004: Operations Best Practices

Date: [YYYY-MM-DD]

## Status

Accepted

## Context

[For Infrastructure]: This project manages infrastructure that requires systematic
operational practices for reliability, maintainability, and effective troubleshooting.

[For Development]: This application requires operational guidelines for deployment,
monitoring, and incident response.

## Decision

### Deployment

**Method**: [Ansible, Docker/Podman, Kubernetes, manual, etc.]
**Environments**: [production, staging, development]
**Process**:
1. [Deployment step 1]
2. [Deployment step 2]
**Rollback**: [How to rollback if deployment fails]

### Monitoring and Alerting

**What we monitor**:
- [Service health]
- [Resource utilization]
- [User-facing metrics]

**Tools**: [Prometheus, Grafana, etc.]
**Alerting**: [When and how alerts trigger]

### [Infrastructure Projects] Extended Operations

#### Backup and Recovery
- **Scope**: [What is backed up]
- **Frequency**: [Backup schedule]
- **Retention**: [How long kept]
- **Recovery testing**: [How often tested]

#### Security and Access
- **Access control**: [Who has access, how managed]
- **Authentication**: [Method]
- **Network security**: [Firewall, VPN, etc.]
- **Update management**: [Patching approach]

#### Troubleshooting
- **Logs**: [Where logs are, how to access]
- **Common issues**: [Link to runbooks]
- **Escalation**: [When to escalate, to whom]

#### Change Management
- **Process**: [How changes are planned and executed]
- **Documentation**: [Changes documented where]
- **Rollback plan**: [Required for each change]

### [Development Projects] Operational Basics

- **Environments**: dev, staging, production
- **Logging**: [Where logs go, log levels]
- **Error tracking**: [Error reporting service]
- **Health checks**: [Endpoint, expected response]

## Consequences

**Positive**:
- Systematic operational practices documented
- AI assistants consider operational constraints
- Troubleshooting guided by documentation
- Knowledge transfer for operations

**Negative**:
- Documentation overhead
- Requires discipline to maintain

## References

- [System Architecture](../architecture/) - C4 model
- [Runbooks](../howto/) - Operational procedures
```

### ADR Index (README.md)

Create `docs/adr/README.md`:

```markdown
# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for [Project Name].

## Foundational ADRs

| ADR | Title | Purpose | Status |
|-----|-------|---------|--------|
| [ADR-0001](0001-record-architecture-decisions.md) | Record Architecture Decisions | HOW TO DECIDE | Accepted |
| [ADR-0002](0002-adopt-development-best-practices.md) | Adopt Development Best Practices | HOW TO DEVELOP | Accepted |
| [ADR-0003](0003-[tech-stack].md) | Use [Technology Stack] | WHAT TECH | Accepted |
| [ADR-0004](0004-operations-best-practices.md) | Operations Best Practices | HOW TO OPERATE | Accepted |

## Project-Specific ADRs

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| ... | ... | ... | ... |

## ADR Process

1. Check highest ADR number: `ls docs/adr/*.md | sort -V | tail -1`
2. Create new ADR with next sequential number
3. Write ADR with Status: Proposed
4. Review with team/stakeholders
5. Update Status to Accepted (or Rejected)
6. Update this index

## References

- [ADR-0001](0001-record-architecture-decisions.md) defines our ADR process
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
```

## Outputs

This skill creates:
- [ ] `docs/adr/README.md` (ADR index)
- [ ] `docs/adr/0001-record-architecture-decisions.md` (HOW TO DECIDE)
- [ ] `docs/adr/0002-adopt-development-best-practices.md` (HOW TO DEVELOP)
- [ ] `docs/adr/0003-[technology-stack].md` (WHAT TECH)
- [ ] `docs/adr/0004-operations-best-practices.md` (HOW TO OPERATE)

## Validation

Verify successful ADR creation:
1. All four foundational ADRs exist with correct numbering
2. ADR-0002 is customized for the project's technology stack
3. ADR-0003 includes alternatives considered and rationale
4. ADR-0004 scope matches project type (comprehensive for infrastructure)
5. README.md index is accurate
6. Dates are correct (use `date +%Y-%m-%d`)

## Related Skills

- `bootstrap-project` - Should be run first
- `setup-pre-commit` - Implements practices from ADR-0002
- `setup-architecture-as-code` - Implements architecture-as-code from ADR-0002
