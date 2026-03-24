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
| ADR-0004 | HOW TO OPERATE | Operations practices | Infrastructure, Hybrid (optional) |

**Note**: ADR-0004 is only needed for Infrastructure and Hybrid projects. Skip it for pure development projects (libraries, CLI tools, web apps without self-hosting concerns).

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

**Filename**: `NNNN-title-with-hyphens.md` (e.g., `0001-record-architecture-decisions.md`)
**Title**: `# N. Title` using adr-tools format (e.g., `# 1. Record Architecture Decisions`). This format is required for Structurizr `!adrs` integration.

## Workflow

### ADR-0001: Record Architecture Decisions

Create `docs/adr/0001-record-architecture-decisions.md`:

```markdown
# 1. Record Architecture Decisions

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

**Scale the detail to the project.** A small CLI tool needs ~100 lines; a multi-subsystem application may need 300-700 lines. Include only sections that apply.

```markdown
# 2. Adopt Development Best Practices

Date: [YYYY-MM-DD]

## Status

Accepted

## Context

[Project name] is a [type] project using [technology stack]. We need consistent development practices that enable high-quality, maintainable code while supporting AI-assisted development workflows.

This project follows [AI-Assisted Project Orchestration patterns](https://github.com/jrjsmrtn/ai-assisted-project-orchestration).

## Decision

### 1. Testing Strategy

- **Framework**: [ecosystem-specific: ExUnit, pytest, cargo test, etc.]
- **Approach**: TDD — Red-Green-Refactor cycle
- **Coverage target**: >80% for core logic
- **Test organization**:
  - `test/unit/` or `test/[app]/` — unit tests (fast, isolated)
  - `test/integration/` — integration tests (slower, may require external services)

[For Elixir: add property-based testing with StreamData if applicable]
[For Elixir: add contract tests if defining behaviours]

### 2. BDD with Gherkin (user-facing projects)

[Include this section for Web, GUI, TUI, CLI projects. Omit for libraries and infrastructure.]

- **Gherkin feature files**: `features/` or `test/features/`
- **Step definitions**: `features/step_definitions/` or `test/features/step_definitions/`
- **BDD framework**: [confirm during bootstrap — e.g., Cucumber for Elixir, Behave or pytest-bdd for Python]
- **Browser automation**: [Playwright for web projects]
- **Tagging**: `@wip`, `@smoke`, `@slow` for selective execution

### 3. Semantic Versioning

- Follow [SemVer 2.0.0](https://semver.org/)
- During development: 0.1.x (increment patch per sprint/milestone)
- No stable 1.0 until [condition: "Phase N complete", "production-ready", etc.]
- Version location: [where the version is defined in the project]

### 4. Git Workflow

- **Gitflow-based**: `main`, `develop`, `feature/*`, `release/*`, `hotfix/*`
- **Conventional Commits**: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- `main` tracks releases, `develop` is the integration branch

### 5. Change Documentation

- **Keep a Changelog** format in `CHANGELOG.md`
- Categories: Added, Changed, Deprecated, Removed, Fixed, Security
- Updated with each version bump

### 6. Architecture as Code

- **C4 DSL** models in `docs/architecture/`
- Validated with structurizr/cli container
- Rendered with structurizr/lite for review

### 7. Documentation Framework

**Diátaxis** structure in `docs/`:
- `tutorials/` — learning-oriented
- `howto/` — problem-oriented
- `reference/` — information-oriented
- `explanation/` — understanding-oriented

ADRs in `docs/adr/`, sprint plans in `docs/sprints/`, roadmap in `docs/roadmap/`.

### 8. Sprint-Based Development

- Lightweight sprints aligned with roadmap phases
- Sprint plans in `docs/sprints/sprint-NNNN-plan.md`
- Retrospectives in `docs/sprints/sprint-NNNN-retrospective.md` (or `.yml`)
- Roadmap in `docs/roadmap/roadmap.md`

### 9. Formatting and Editor Configuration

- **Editor configuration**: `.editorconfig` for consistent whitespace across editors
- **Markdown formatting**: dprint (preferred) or prettier
- **Code formatting**: [ecosystem-specific: mix format, ruff format, cargo fmt, etc.]

### 10. Quality Automation

**Git hooks** — lefthook (preferred) or pre-commit framework:

**Pre-commit** (fast, <30s):
- Code formatting check
- Markdown formatting check (dprint)
- Secret scanning (gitleaks)

**Pre-push** (thorough):
- Linting / static analysis ([mix credo, ruff check, eslint, etc.])
- Type checking ([Dialyzer, mypy, tsc, etc.])
- Dependency scanning ([mix deps.audit, pip-audit, npm audit, cargo audit, etc.])
- Fast tests (exclude slow/integration)

**CI** should run all pre-commit + pre-push checks, plus integration tests and coverage.

### 11. Licensing and Copyright

- **REUSE compliance** ([reuse.software](https://reuse.software/)) for machine-readable copyright and license declarations
- SPDX headers (`SPDX-FileCopyrightText`, `SPDX-License-Identifier`) on source files
- License texts in `LICENSES/` directory

### 12. Code Conventions

[Project-specific patterns that AI and human contributors should follow. Examples:]
- [Struct definition ordering, validation patterns, error handling conventions]
- [Test addresses: RFC 5737 for IPs, RFC 7042 for MACs, RFC 2606 for domains]
- [Naming conventions, module organization]

[Omit this section if no project-specific conventions exist yet.]

## Consequences

**Positive**:
- Consistent practices across development sessions
- AI assistants have clear guidance on standards
- Quality gates catch issues early
- Automated enforcement reduces review burden

**Negative**:
- Initial setup overhead for tooling
- [Ecosystem-specific: Dialyzer PLT build time, mypy strictness ramp-up, etc.]

## References

- [AI-Assisted Project Orchestration](https://github.com/jrjsmrtn/ai-assisted-project-orchestration)
- [Ecosystem-specific documentation links]
```

**Ecosystem-specific guidance** (confirm choices during project bootstrap):

For **Elixir** projects, expand sections with:
- ExUnit + StreamData (property-based testing)
- BDD with Cucumber + Playwright (if user-facing)
- usage_rules for Ash-based projects (AI documentation lookup)
- mix format, mix credo --strict, Dialyzer
- JUnit XML test reports

For **Python** projects, expand sections with:
- pytest + pytest-asyncio
- BDD with Behave or pytest-bdd + Playwright (if user-facing)
- ruff (format + lint), mypy (strict mode)

For **Rust** projects, expand sections with:
- cargo test + proptest (property-based)
- cargo fmt, cargo clippy

For mature/security-sensitive projects, add:
- Supply Chain Security (SLSA, EEF Ægis, OpenSSF)

### ADR-0003: Technology Stack Decision

Create `docs/adr/0003-[technology-stack-name].md`:

```markdown
# 3. Use [Technology Stack]

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

### ADR-0004: Operations Best Practices (Optional)

**Skip for pure development projects.** Only create for Infrastructure or Hybrid projects.

Create `docs/adr/0004-operations-best-practices.md`:

**Scope varies by project type:**
- **Infrastructure projects**: Comprehensive (backup, monitoring, change management)
- **Hybrid projects**: Moderate depth based on operational complexity

```markdown
# 4. Operations Best Practices

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

### ADR Index

Create `docs/adr/index.yml` — YAML is safe inside the ADR directory because Structurizr's `!adrs` importer only processes `*.md` files:

```yaml
# Architecture Decision Records — [Project Name]

foundational:
  - id: 1
    file: 0001-record-architecture-decisions.md
    title: Record Architecture Decisions
    purpose: HOW TO DECIDE
    status: Accepted
  - id: 2
    file: 0002-adopt-development-best-practices.md
    title: Adopt Development Best Practices
    purpose: HOW TO DEVELOP
    status: Accepted
  - id: 3
    file: 0003-[tech-stack].md
    title: "Use [Technology Stack]"
    purpose: WHAT TECH
    status: Accepted
  # ADR-0004 only for Infrastructure/Hybrid projects:
  # - id: 4
  #   file: 0004-operations-best-practices.md
  #   title: Operations Best Practices
  #   purpose: HOW TO OPERATE
  #   status: Accepted
```

**Do not create a README.md inside `docs/adr/`** — the adrtools importer parses every `.md` file and will fail on non-ADR markdown files.

## Outputs

This skill creates:
- [ ] `docs/adr/index.yml` (ADR index — YAML is safe inside adr/, only *.md is parsed by !adrs)
- [ ] `docs/adr/0001-record-architecture-decisions.md` (HOW TO DECIDE)
- [ ] `docs/adr/0002-adopt-development-best-practices.md` (HOW TO DEVELOP)
- [ ] `docs/adr/0003-[technology-stack].md` (WHAT TECH)
- [ ] `docs/adr/0004-operations-best-practices.md` (HOW TO OPERATE — Infrastructure/Hybrid only)

## Validation

Verify successful ADR creation:
1. All four foundational ADRs exist with correct numbering
2. ADR-0002 is customized for the project's technology stack
3. ADR-0003 includes alternatives considered and rationale
4. ADR-0004 exists only for Infrastructure/Hybrid projects
5. README.md index is accurate
6. Dates are correct (use `date +%Y-%m-%d`)

## Related Skills

- `bootstrap-project` - Should be run first
- `setup-pre-commit` - Implements practices from ADR-0002
- `setup-architecture-as-code` - Implements architecture-as-code from ADR-0002
