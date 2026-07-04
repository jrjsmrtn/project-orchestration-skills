---
name: bootstrap-project
description: Bootstrap a new project at a chosen graduation tier (t0 minimum, t1 decision-tracked, t2 full pattern language) following AI-Assisted Project Orchestration best practices. Use when starting a new software project, promoting an existing project to a higher tier, or converting an existing project for AI-assisted development.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.11"
license: MIT
---

# Project Bootstrap

Bootstrap a new project with foundational artifacts following AI-Assisted Project Orchestration best practices. Implements the **Tiered Bootstrap** pattern with three graduation tiers (t0/t1/t2) so that decision rationale is captured at decision-time and tier promotion is reformatting, not archaeology.

## When to Use

- Starting a new software project (pick a tier appropriate to scope)
- Promoting an existing project from a lower tier to a higher one
- Converting an existing project to follow best practices
- Setting up a project for AI-assisted development

> **Pattern Reference**: See [TIERED-BOOTSTRAP](https://github.com/jrjsmrtn/ai-assisted-project-orchestration/blob/develop/docs/patterns/inception/tiered-bootstrap.md) for the underlying pattern, including knowledge-preservation argument and the comparison with spec-driven development tools.

## Required Inputs

Before running this skill, gather from the user:

1. **Project name** (kebab-case, e.g., `my-awesome-project`)
2. **Project description** (1-2 sentences)
3. **Tier** (graduation level — see [Tier Selection](#tier-selection) below):
   - **t0** — minimum viable foundation (CLAUDE.md + git + conventional-commits)
   - **t1** — decision-tracked project (+ foundation ADRs + pre-commit + changelog)
   - **t2** — full pattern language (+ Diátaxis + C4 + sprint cadence + roadmap) — **default**
4. **Project category**:
   - **Development**: Software (applications, libraries, services)
   - **Infrastructure**: Operations (homelab, deployment, monitoring)
   - **Hybrid**: Both development and operations components
5. **Project type** (library, web application, CLI tool, API service, infrastructure automation)
6. **Technology stack** (e.g., "Elixir/Phoenix/Ash", "Python/FastAPI", "Ansible")
7. **License** (MIT, Apache-2.0, proprietary) — required at t1+, optional at t0
8. **Git remotes** (private origin only, or multi-remote with public GitHub/GitLab)
9. **Distribution profile** (exposure — orthogonal to the tier): **Private** (default — internal/homelab/WIP) or **Public** (open-sourced on a public forge *and* properly licensed). Set the **`ships-artifacts`** marker if the maintainer will publish built packages/images to a registry (Hex/PyPI/GHCR/containers) or signed release binaries. The profile governs which compliance controls apply — see [Distribution Profile](#distribution-profile) below.

**Why project category matters:**
- **Development**: ADR-0004 (Operations) is skipped
- **Infrastructure**: ADR-0004 is created (backup, monitoring, change management)
- **Hybrid**: ADR-0004 is created, covering both application and infrastructure operations

## Tier Selection

This skill implements the **Tiered Bootstrap** pattern. Each tier is a strict superset of the previous one. Pick the lowest tier that fits the project's current state — promotion is mechanical (reformat / reorganize), not archaeological.

| Project state | Recommended tier |
|---|---|
| Same-day exploration, weekend prototype | **t0** |
| Multi-week solo project, expected to outlive prototype | **t1** |
| Multi-contributor, professional, or upstream-OSS-bound | **t2** (default) |
| Existing prototype with chat-only history | **t0** immediately, then promote |

**Promotion triggers**:
- **t0 → t1**: more than one contributor, project survives two weeks, first decision deserves a numbered record
- **t1 → t2**: docs need structure beyond CLAUDE.md, architecture needs visual artifacts, work needs sprint-scale planning, project nears 1.0

**Knowledge-preservation property**: at every tier, decision rationale is captured at decision-time in durable, version-controlled artifacts (CLAUDE.md, conventional commits, ADRs). No tier requires recovering rationale from non-durable sources (chat logs, agent session memory).

## Distribution Profile

**Orthogonal to the tier.** The tier measures process *maturity*; the distribution profile measures *exposure* — how far the software travels — which is what actually gates compliance controls. A mature internal tool has no external obligations; an early public library incurs them the moment it ships. Set the profile at inception (default **Private**), and graduate it like the tier.

| Profile / marker | Trigger | Controls it adds |
|---|---|---|
| **Private** (default) | internal / homelab / WIP | baseline hygiene (secret scanning — already universal) |
| **Public** | open-sourced on a public forge **and** licensed | LICENSE/REUSE, `SECURITY.md` + coordinated disclosure (Phase 9), OpenSSF Scorecard aspirational |
| **`ships-artifacts`** (marker) | publishes built packages/images to a registry, or signed release binaries | + SLSA provenance, SBOM, signing, trusted publishing (via `harden-ci-workflows`, `wrapup-sprint`) |

Going Public *is* making the source redistributable (licensing is part of the gate), so there is no separate "distributed" level. **`ships-artifacts` is a boolean, not a rung** — set it when going public, later, or never. Controls attach to the profile, not the tier, so a project pays only for its actual exposure. Record the profile in CLAUDE.md `## Project Context`; promotion to Public is the `public-release` graduation gate (`oss-maintenance`).

This axis maps to recognized frameworks: **Public** → EU CRA "open-source steward" duties + OpenSSF Best Practices; **`ships-artifacts`** → SLSA / EEF Ægis trusted publishing. Treat these as guidance, not legal advice. The `commercial` case (placing on the EU market for pay), which triggers full CRA manufacturer obligations, is out of scope here.

## Phases by Tier

| Phase | t0 | t1 | t2 |
|---|---|---|---|
| 1. Directory structure (Diátaxis) | — | — | yes |
| 2. Git initialization | yes (minimal) | yes | yes |
| 3. CLAUDE.md | yes | yes | yes |
| 4. CHANGELOG.md | — | yes | yes |
| 5. Roadmap | — | — | yes |
| 6. README.md | optional | yes | yes |
| 7. Audience-traced artifacts | — | — | yes (if registry) |
| 8. Invoke related skills | — | `setup-adrs`, `setup-pre-commit` | all |

At **t0**, only Phases 2 (minimal `.gitignore`) and 3 (CLAUDE.md) are required. README is optional. No `docs/` tree, no ADR scaffolding, no changelog — those come with promotion to t1.

At **t1**, add Phase 4 (CHANGELOG) and invoke `setup-adrs` (creates ADR-0001/0002/0003) and `setup-pre-commit`. Still no Diátaxis tree or C4 model.

At **t2**, run all phases. This is the existing default behavior.

**Public profile (any tier)**: additionally run **Phase 9** (`SECURITY.md` + coordinated disclosure). This is gated on the distribution profile, not the tier — a t0 project that is Public still needs it, and a t2 Private project does not.

## Workflow

### Phase 1: Directory Structure

Create the Diátaxis documentation structure:

```
docs/
├── tutorials/           # Learning-oriented
│   └── .gitkeep
├── howto/              # Problem-oriented
│   └── .gitkeep
├── reference/          # Information-oriented
│   └── .gitkeep
├── explanation/        # Understanding-oriented
│   └── .gitkeep
├── adr/                # Architecture Decision Records
│   └── .gitkeep
├── architecture/       # Structurizr-specific docs (h2-first, for !docs directive)
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
   .envrc
   .envrc.local
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
- **Tier**: [t0 | t1 | t2]
- **Distribution profile**: [Private | Public]  (ships-artifacts: [yes | no])

## Project Tier

Current tier: **[t0 | t1 | t2]**

Tier-specific artifacts in this project:
- [list per current tier — e.g., "CLAUDE.md, conventional commits" at t0]

Promotion triggers being watched:
- [e.g., "t0 → t1 when first contributor joins" or "t1 → t2 when nearing v1.0"]

## Current Development Status

<!-- t2 only — at t0/t1, replace with a single "## Status" paragraph -->
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

After completing the bootstrap, suggest invoking based on tier:

**Tier 0** — none required. Optionally suggest promotion path: "When you're ready to promote to t1, run this skill again with `tier: t1`."

**Tier 1**:
1. **setup-adrs** - Create ADR-0001, 0002, 0003 (and 0004 for Infrastructure/Hybrid)
2. **setup-pre-commit** - Configure quality gates

**Tier 2** (all of t1 plus):
3. **setup-architecture-as-code** - Create `architecture/` directory, workspace.dsl, and docs symlink
4. **plan-sprint** - Create Sprint 1 plan

### Phase 9: Security Policy (Public profile)

Gated on the **distribution profile**, not the tier: any project whose profile is **Public** (or is being promoted to Public) gets a `SECURITY.md`. This satisfies the OpenSSF Scorecard `Security-Policy` check, the OpenSSF Best Practices vulnerability-reporting criterion, and the EU CRA "open-source steward" coordinated-disclosure duty. Private-profile projects skip this.

Scaffold a right-sized `SECURITY.md` — fill the bracketed parts; the **Scope** section is the important, non-boilerplate one:

```markdown
# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities **privately** — do not open a public issue.

- Preferred: [GitHub Security Advisories](https://github.com/{owner}/{repo}/security/advisories/new) (private)
- Or email: {maintainer-email}

We aim to acknowledge within [N business days] and to share a remediation timeline after
triage. We follow **coordinated disclosure**: please allow reasonable time for a fix before
public disclosure.

## Supported Versions

| Version | Supported |
|---------|-----------|
| {latest-minor}.x | ✅ |
| < {latest-minor} | ❌ |

## Scope

[Author-filled — the point of this file. State this project's realistic threat model: trust
boundaries, untrusted inputs, what is in and out of scope. Avoid boilerplate; an honest,
project-specific model is what makes the policy useful. e.g. "parses untrusted diagram input;
shell-escaping is in scope" or "no runtime, no network, no deps — the attack surface is the
integrity of the published artifact".]
```

Then enable **private vulnerability reporting** on the repo (GitHub: Settings → Code security → Private vulnerability reporting) so the Advisories link works. The fuller go-public checklist (CONTRIBUTING, CODE_OF_CONDUCT, LICENSE verification, CI) is owned by the `public-release` skill (`oss-maintenance`) at the Private→Public graduation gate — this phase covers only the security policy.

## Graduation (Tier Promotion)

When promoting an existing project from a lower tier to a higher one, this skill should **reformat existing artifacts**, not recreate them. The decision rationale is already captured at the lower tier; promotion makes it formal.

### t0 → t1 graduation

1. Read the existing CLAUDE.md and `git log --oneline` history
2. Invoke `setup-adrs` to scaffold ADR-0001, 0002, 0003 (+ 0004 if Infrastructure/Hybrid)
3. Populate ADR content **from existing CLAUDE.md sections and commit history** — do not invent new rationale
4. Initialize CHANGELOG.md with the current state derived from commit history
5. Invoke `setup-pre-commit` for quality gates
6. Update CLAUDE.md `## Project Tier` section to `t1` and list new artifacts

### t1 → t2 graduation

1. Create the Diátaxis `docs/` structure (Phase 1)
2. Sort existing documentation into the four quadrants — **do not duplicate**, move
3. Create roadmap (Phase 5) reflecting work already done as completed phases
4. Invoke `setup-architecture-as-code` to create the C4 workspace; derive the model from the codebase as it stands
5. Invoke `plan-sprint` for the next sprint cycle (do not retroactively create sprints for completed work; record it in the roadmap and changelog instead)
6. Update CLAUDE.md `## Project Tier` section to `t2`

## Outputs

This skill creates artifacts based on tier:

**Tier 0**:
- [ ] `.gitignore` (technology-specific + security patterns)
- [ ] `CLAUDE.md` with `## Project Tier` section set to `t0`
- [ ] Git initialized on `main`, first conventional commit

**Tier 1** (adds to t0):
- [ ] `CHANGELOG.md` (initialized, Keep a Changelog format)
- [ ] `develop` branch created from `main`
- [ ] `README.md` (skeleton)
- [ ] CLAUDE.md tier set to `t1`
- [ ] (Via `setup-adrs`) ADR-0001, 0002, 0003 [+ 0004 Infrastructure/Hybrid]
- [ ] (Via `setup-pre-commit`) Two-stage pre-commit hooks

**Tier 2** (adds to t1):
- [ ] `docs/` directory structure (Diátaxis): tutorials, howto, reference, explanation, adr, architecture, sprints, roadmap
- [ ] `docs/roadmap/roadmap.md` (initial phases)
- [ ] CLAUDE.md tier set to `t2`, `## Current Development Status` section populated
- [ ] (Via `setup-architecture-as-code`) `architecture/workspace.dsl` and validation harness
- [ ] (Via `plan-sprint`) `docs/sprints/sprint-0001-plan.md`
- [ ] (If Audience Registry) `features/` subdirectories per audience category
- [ ] (If Audience Registry) Diátaxis doc stubs with audience frontmatter

**Public profile** (any tier):
- [ ] `SECURITY.md` with private reporting, supported-versions, and a project-specific Scope/threat model
- [ ] Private vulnerability reporting enabled on the repo
- [ ] CLAUDE.md `## Project Context` records the distribution profile (+ `ships-artifacts` marker)

## Validation

Verify successful bootstrap based on tier:

**Tier 0**:
1. `git log` shows at least one conventional commit
2. CLAUDE.md exists with accurate project information and `## Project Tier: t0`
3. `.gitignore` covers security patterns (`.env`, credentials, `CLAUDE.local.md`)

**Tier 1** (adds to t0 checks):
4. CHANGELOG.md exists with `[Unreleased]` section
5. `main` and `develop` branches both exist
6. `docs/adr/0001-*.md`, `0002-*.md`, `0003-*.md` exist (and `0004-*.md` for Infrastructure/Hybrid)
7. Pre-commit hooks installed and run successfully on initial commit

**Tier 2** (adds to t1 checks):
8. `docs/` directory tree exists (tutorials, howto, reference, explanation, adr, architecture, sprints, roadmap)
9. `architecture/workspace.dsl` exists and validates
10. `docs/sprints/sprint-0001-plan.md` exists
11. (If Audience Registry) Traced artifacts align with audience categories

**Public profile** (any tier):
12. `SECURITY.md` exists with a private reporting channel and a filled-in Scope section (not boilerplate)

## Related Skills

- `analyze-project` - Run SPARK analysis before bootstrap
- `setup-adrs` - Next step: create foundational ADRs
- `setup-pre-commit` - Configure pre-commit hooks
- `setup-architecture-as-code` - Create architecture model
- `plan-sprint` - Create initial sprint plan
- `public-release` (oss-maintenance) - Private→Public graduation gate (full go-public checklist)
- `harden-ci-workflows` - CI hardening for Public + `ships-artifacts` projects
