---
name: bootstrap-project
description: Bootstrap a new project at a chosen graduation tier (t0 minimum, t1 decision-tracked, t2 full pattern language) following AI-Assisted Project Orchestration best practices. Use when starting a new software project, promoting an existing project to a higher tier, or converting an existing project for AI-assisted development.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.41"
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
| **`ships-artifacts`** (marker) | publishes built packages/images to a registry, or signed release binaries | + SLSA provenance, SBOM, signing, trusted publishing (via `harden-github-actions`, `wrapup-sprint`) |

Going Public *is* making the source redistributable (licensing is part of the gate), so there is no separate "distributed" level. **`ships-artifacts` is a boolean, not a rung** — set it when going public, later, or never. Controls attach to the profile, not the tier, so a project pays only for its actual exposure. Record the profile in CLAUDE.md `## Project Context`; promotion to Public is the `public-release` graduation gate (`project-maintenance-skills`).

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
| 8. Invoke related skills | — | `setup-adrs`, `setup-git-hooks` | all |

At **t0**, only Phases 2 (minimal `.gitignore`) and 3 (CLAUDE.md) are required. README is optional. No `docs/` tree, no ADR scaffolding, no changelog — those come with promotion to t1.

At **t1**, add Phase 4 (CHANGELOG) and invoke `setup-adrs` (creates ADR-0001/0002/0003) and `setup-git-hooks`. Still no Diátaxis tree or C4 model.

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

   > **Interacts with OpenSSF Scorecard** (if you add `harden-github-actions`' Scorecard workflow).
   > Scorecard's content analysis runs against the **default branch**, so making `develop` the default
   > means the published score describes the **integration** branch, not the `main` releases are cut
   > from. (The `Branch-Protection` check is the exception — it also inspects release branches — but
   > `Pinned-Dependencies`, `Dangerous-Workflow`, `Token-Permissions`, etc. read the default branch.)
   > Two honest resolutions: keep `develop` default and protect/harden it as the graded branch, or make
   > `main` the default and treat `develop` as a long-lived branch. Decide deliberately — see
   > `harden-github-actions` Step 6.

#### Commit message content

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specifies the **grammar** —
`type(scope)!: description`, uppercase `BREAKING CHANGE`, a blank line before the body, footers as
git trailers. Its Rule 7 makes the body *"free-form"*, and that is a vacuum rather than an
endorsement. These rules fill it.

**Scale them by tier.** Loading a solo t0 project with a five-rule commit policy is how conventions
get ignored wholesale.

| Tier | Applies |
|---|---|
| **t0** | Rule 1 — subject discipline |
| **t1** | + Rules 2 and 3 |
| **t2** | + Rule 2 wired as a hook (`setup-git-hooks`), + trailer grammar stated |

**1. The subject says what changed. The body says why — or there is no body.**
The diff already shows what. A body restating the subject in longer words is worse than none,
because it looks like rationale and is not. *Test: delete the body. If nothing is lost, it should not
have been there.*

**2. A commit message MUST NOT claim more than the commit contains.**
The sharpest rule, because a wrong message is worse than a thin one: a thin message is merely
unhelpful, a wrong one is a false record that outlives everyone who could correct it, and `git log`
is where people go precisely when the code no longer explains itself.

This failure is easy to commit and hard to notice. An edit silently does nothing — a pattern that
did not match, a file already in the target state — while the message, written beforehand, describes
it confidently. **The risk is highest when the message is generated**, since fluent prose about an
intended change reads identically whether or not the change landed.

> Before committing, re-read the message against `git diff --cached` and not against your intent.

`setup-git-hooks` can enforce the mechanical half — see *Commit message honesty* there.

**3. Record what would otherwise be lost.**
Why this approach rather than the one you rejected; what you tried that failed; what constraint
forced the shape. Not the diff in prose — the reasoning that cannot be recovered from the tree. This
is the highest-value content in any commit and the first thing omitted under time pressure.

**Two supporting rules**

- **Corrections belong in the message of the commit that fixes them**, naming *what the old state
  would have misled someone into believing*. A CHANGELOG entry reaches readers; a commit message
  reaches whoever runs `git blame` in two years, which is a different and usually more desperate
  person.
- **Trailers are structured metadata, not decoration.** Git standardises the *shape* of a trailer
  block and nothing about which tokens mean what, so any project using `Assisted-by:`,
  `Co-authored-by:` or similar must state its own grammar. Pick one spelling and stay with it —
  a trailer emitted in a format the project never defined parses as prose.

**What is deliberately not here**: line-wrap width, capitalisation, imperative mood. Real
conventions, but nothing in this practice set has been damaged by ignoring them, and every unenforced
rule dilutes the ones that matter.

#### Code comment content

Comments serve **two distinct jobs**, and conflating them is why most comment advice reads as
contradictory. Ousterhout's formulation, from his published comparison with *Clean
Code*:[^aposd-vs-cc]

1. **Abstraction.** *"Without comments there is no way to have abstraction or modularity… It should
  be possible to use a method without reading its code. The way we achieve this is by writing a
  header comment that describes the method's interface."*
2. **Information not obvious from the code.**

**Write interface comments so callers need not read the implementation.** This is the job most
in-house comment rules omit — including an earlier version of this section — because it is not about
explaining tricky code. It is what makes a module usable without opening it, and no naming scheme
substitutes for it.

For **implementation** comments, the bar is different and much higher. Both Ousterhout and Martin
agree here, which is worth knowing given how little else they agree on: *"implementation code only
needs comments when the code is nonobvious."*[^aposd-vs-cc]

**The test for an implementation comment: would deleting it let someone reintroduce a bug, or repeat
an approach already rejected?** If yes it earns its place permanently. If no, it is a second copy of
the code that drifts out of sync and is believed anyway — worse than absence, because a wrong comment
is trusted while missing code is read.

> **Note the scope.** That test governs implementation comments only. Applying it to interface
> comments would delete most of them, since an interface comment usually prevents *misuse* rather
> than a specific bug. Ousterhout would write **"5-10x more lines of comments"** than Martin for the
> same code; this section sits nearer Martin on implementation and nearer Ousterhout on
> interfaces.[^aposd-vs-cc]

**Write these:**

- **Order or shape that looks arbitrary and is not.** *"ORDER MATTERS — testing `/modules/` first
  labels a worktree-of-a-submodule as a submodule, hiding that it shares history with another entry."*
  Without it, the next reader tidies the branches into a "cleaner" order and silently restores the
  bug.
- **The alternative you rejected, and why.** Prevents the change being "simplified" back.
- **Why a check is shaped the way it is** — what it measures and what it deliberately does not. A
  check whose reasoning is undocumented gets relaxed the first time it is inconvenient.
- **A fact verified against an external source** — with the date. *"Verified against cosign 3.1.1,
  2026-08-04."* Undated, it is unfalsifiable and will be trusted forever.

**Do not write these:**

- **Restatements of the code.** `i++  // increment i`, or a docstring repeating the signature.
- **Commented-out code.** Git already has it, with authorship and a reason. Commented-out code has
  neither and is never deleted, because nobody knows if it is load-bearing.
- **Anything a type, a name or a test states better.** A comment explaining what a badly-named
  variable holds is a rename waiting to happen.

**Comments that make a claim carry the same obligation as commit messages: they must not claim more
than the code does.** A comment saying a function validates X, where it does not, is a defect that
no test catches and every reader inherits.

##### Where these rules come from, and what checking them changed

The "do not write" list and the implementation test are **house-derived**, from observed failures in
this portfolio. They were then checked against
[**A Philosophy of Software Design vs Clean Code**](https://github.com/johnousterhout/aposd-vs-clean-code/blob/main/README.md)[^aposd-vs-cc]
— a long recorded exchange between **John Ousterhout** and **Robert C. Martin**, published by
Ousterhout, in which the two work through their disagreement directly. **Three things changed as a
result**, recorded here because the earlier version stated them wrongly:

- **A whole category was missing.** The section covered only implementation comments and did not say
  so. Ousterhout's *first* reason for comments is abstraction — interface documentation — which the
  original test would have deleted wholesale.
- **"The code shows what, comments carry why" is too narrow.** The rule is *not obvious from the
  code*, which includes non-obvious **what**: an algorithm's mechanism can need explaining even when
  nobody asks why it exists.
- **The disagreement is real and unresolved, so it is shown rather than settled.** *Clean Code* holds
  that *"comments are always failures… compensate for our failure to express ourselves in code"*;
  Ousterhout calls that stigmatising and warns juniors will read it as "write no comments". Martin's
  reply is that he is *"not hostile to comments in general. I **am** very hostile to gratuitous
  comments."* They close with: *"we struggled to find areas of agreement on this topic."*

**Where they do agree, treat it as settled**: implementation comments only when the code is
nonobvious, and gratuitous comments are a cost. Where they disagree — interface comments for internal
APIs, comments versus very long method names, whether to trust a comment without reading the code —
**pick per project and say which you picked**, rather than inheriting one camp silently.

**Still unread**: the book itself (not obtainable here — the extract PDF is image-only and the
volume is not in this library), and Naur's *Programming as Theory Building*. The standing
instruction holds: if a source contradicts a rule above, the source wins.

[^aposd-vs-cc]: [A Philosophy of Software Design vs Clean Code](https://github.com/johnousterhout/aposd-vs-clean-code/blob/main/README.md) — John Ousterhout and Robert C. Martin, read 2026-08-05.

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
- [list per current tier — e.g., "CLAUDE.md, conventional commits (grammar + content rules by tier)" at t0]

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

**Attestations are never delegated.** Do not run `git commit -s` or write a
`Signed-off-by:` trailer — if this project adopts the DCO, that trailer is a statement by
a *person* about their right to submit, and a `commit-msg` hook demanding it is asking a
human to certify, not asking a tool for a formatting fix. When a hook blocks you for a
missing sign-off, hand the work back unsigned and say so. The same holds for a CLA, a
release approval, or a published provenance statement. `Co-Authored-By:` and
`Assisted-by:` are fine — they record assistance and assert no right to submit.

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

## Tracker Boundary

_Single source of truth for tactical status._ While the backlog lives **in-repo only**, this
roadmap is canonical. Once more than one contributor needs to see and claim work, the backlog may
graduate to a forge issue tracker (`graduate-backlog`) — public, or an internal/self-hosted one.
Record the split here: what stays canonical in-repo (this roadmap, ADRs, sprint retrospectives) vs.
what the tracker owns (per-issue/milestone status). Default once moved: the tracker owns tactical
status; this Sprint History stays the narrative/version ledger.
```

The roadmap is a living document — update it as phases complete and new ones emerge.

### Phase 6: Create README.md

A README is the **front door**, not documentation. Its job is to let a reader answer three questions
in under a minute: *what is this, is it for me, how do I start?*

> **Diátaxis does not address READMEs** (checked 2026-08-05 — the framework describes four modes and
> says nothing about where a README sits). Treating it as a router *into* those modes rather than as
> one of them is an inference from this portfolio's practice, not a claim the framework makes.

Generate a README.md with:
- Project name and description
- Installation instructions (placeholder)
- Quick start (placeholder)
- Documentation links
- License
- Contributing guidelines reference

**The rule that matters most: a README MUST NOT assert a number a command can derive.**

Counts, tallies and status lines are the fastest-decaying content in any repository, and nothing
validates them. A bundle README read *"Status: skeleton. One verified record"* while the bundle held
fifteen — the sentence was true when written, nothing objected, and it stayed wrong for as long as
nobody looked. **Point at the command instead**:

```markdown
Run `okf list knowledge` for what is actually in here. This file deliberately quotes no
count — a hand-written total is the kind of claim that goes stale silently.
```

The same applies to version numbers, supported-platform lists, dependency counts and "N of M
complete" progress. If a generator can derive it, the README should invoke the generator or say
nothing.

**Say what the project is *not*.** The cheapest paragraph in any README, and the one that saves the
most reader time — scope boundaries, adjacent things it is confused with, and where those live
instead. A reader who bounces in ten seconds because you told them it is not what they want is a
success, not a loss.

**Tier the rest:**

| Tier | README carries |
|---|---|
| **t0** | what it is, how to run it, one working example |
| **t1** | + what it is *not*; + status stated as a **date or a link**, never a count |
| **t2** | + install, contributing, licence, security-reporting pointers |

**Every command in a README is a claim.** Run them, in a clean checkout, before committing —
install instructions rot faster than prose and fail in front of exactly the audience you were trying
to reach.

##### Where these rules come from

**The derive-don't-assert rule is house-derived**, from an observed failure in this portfolio rather
than from published guidance. No external source below states it. It is kept because the failure was
real and recurred, but it should be read as local evidence, not established practice.

**Established references, for the structure this section does not cover:**

- **[Standard Readme](https://github.com/RichardLitt/standard-readme/blob/main/spec.md)** — a
  genuine specification: required sections and their order (Title, Short Description, TOC, Install,
  Usage, Contributing, License-last), a **120-character** short description that must match the
  repository and package-manager description, and a rule against broken links. Use it when you want
  a checkable structure; it is silent on staleness.
  - Its matching-description rule is the same instinct as derive-don't-assert — **one source of
    truth, restated nowhere** — arrived at from a different direction.
- **[Make a README](https://www.makeareadme.com/)** — section suggestions (Name, Description,
  Badges, Visuals, Installation, Usage, Support, Roadmap, Contributing, Authors, License, Project
  status) and the one piece of staleness guidance either source offers: *"If you have run out of
  energy or time for your project, put a note at the top of the README saying that development has
  slowed down or stopped completely."*

**A tension worth stating rather than hiding**: Make a README holds that *"while a README can be too
long and detailed, too long is better than too short"*, which pulls against the tiering above. Both
positions are defensible — the tiering optimises for a reader deciding in under a minute, that
guidance optimises for a reader who has already decided. Choose per project rather than assuming
this skill settled it.

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
│   └── getting-started.md     # Primary audience (end users)
├── howto/
│   └── deployment.md          # Operational audience (operators)
├── reference/
│   └── api.md                 # Integration audience (API consumers)
└── explanation/
    └── architecture.md        # Contribution audience (contributors)
```

**4. Documentation Frontmatter Template**:
```markdown
---
audience: A1  # audience ID defined in docs/reference/audience-registry.md (A1 = primary audience)
title: Getting Started
---
```

> **Pattern Reference**: See [AUDIENCE-DRIVEN ARTIFACTS](https://github.com/jrjsmrtn/ai-assisted-project-orchestration/blob/develop/docs/patterns/inception/audience-driven-artifacts.md)

### Phase 8: Invoke Related Skills

After completing the bootstrap, suggest invoking based on tier:

**Tier 0** — none required. Optionally suggest promotion path: "When you're ready to promote to t1, run this skill again with `tier: t1`."

**Tier 1**:
1. **setup-adrs** - Create ADR-0001, 0002, 0003 (and 0004 for Infrastructure/Hybrid)
2. **setup-git-hooks** - Configure quality gates

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

Then enable **private vulnerability reporting** on the repo (GitHub: Settings → Code security → Private vulnerability reporting) so the Advisories link works. Verify it is on with (substitute `{owner}`/`{repo}`):

```bash
gh api repos/{owner}/{repo}/private-vulnerability-reporting --jq ".enabled"   # -> true
```

The fuller go-public checklist (CONTRIBUTING, CODE_OF_CONDUCT, LICENSE verification, CI) is owned by the `public-release` skill (`project-maintenance-skills`) at the Private→Public graduation gate — this phase covers only the security policy.

### Phase 10: Dependency Update Automation (Dependabot)

For any project with a GitHub remote, generate `.github/dependabot.yml` so dependencies, GitHub Actions, and base images get automatic update PRs. This is the OpenSSF Scorecard `Dependency-Update-Tool` control, and it keeps SHA-pinned actions (`harden-github-actions`) and digest-pinned images (`setup-container-security`) current. Cover every ecosystem the project uses — the package manager, **`github-actions`** (if there is CI), and **`docker`** (if there is a Containerfile):

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "mix"          # or pip / uv / npm / cargo / gomod
    directory: "/"
    schedule: { interval: "weekly" }
    groups:
      deps: { patterns: ["*"] }
    target-branch: "develop"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly" }
  - package-ecosystem: "docker"       # only if a Containerfile/Dockerfile exists
    directory: "/"
    schedule: { interval: "weekly" }
    ignore:
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]   # digest re-pin only
```

Limits worth documenting: run-step images invoked *inside* a workflow or Makefile (not a `FROM`/`uses:`) are invisible to Dependabot and must be hand-pinned. This phase generates **config**; PR *triage* (reviewing and merging update PRs) is the `project-maintenance-skills` workflow's job, not this skill's.

## Graduation (Tier Promotion)

When promoting an existing project from a lower tier to a higher one, this skill should **reformat existing artifacts**, not recreate them. The decision rationale is already captured at the lower tier; promotion makes it formal.

### t0 → t1 graduation

1. Read the existing CLAUDE.md and `git log --oneline` history
2. Invoke `setup-adrs` to scaffold ADR-0001, 0002, 0003 (+ 0004 if Infrastructure/Hybrid)
3. Populate ADR content **from existing CLAUDE.md sections and commit history** — do not invent new rationale
4. Initialize CHANGELOG.md with the current state derived from commit history
5. Invoke `setup-git-hooks` for quality gates
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
- [ ] (Via `setup-git-hooks`) Two-stage git hooks (pre-commit + pre-push)

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

**With a GitHub remote**:
- [ ] `.github/dependabot.yml` covering the package ecosystem + `github-actions` (if CI) + `docker` (if Containerfile)

## Validation

Run the check; do not read the list. Save this as `scripts/check-bootstrap.sh` in the new project (it
only reads, so running it from a copy elsewhere works too) and run it from the project root:
`scripts/check-bootstrap.sh` reads the tier from CLAUDE.md's `Current tier: **tN**` line (the form
Phase 3 writes), or pass `t0`, `t1` or `t2`; add `--public` for the Public profile, or let it read
`Distribution profile: Public` from CLAUDE.md. Tiers are cumulative, and an argument that disagrees
with what CLAUDE.md declares is itself a failure.

```bash
#!/usr/bin/env bash
# scripts/check-bootstrap.sh — the mechanical half of bootstrap-project's Validation.
#   usage: scripts/check-bootstrap.sh [t0|t1|t2] [--public]       run from the repository root
#   The tier defaults to the one CLAUDE.md states ("Current tier: **t1**"); --public defaults to
#   CLAUDE.md's "Distribution profile: Public". Tiers are cumulative: t2 runs the t0 and t1 checks too.
#   exit:  0 every check passed | 1 at least one FAILED | 2 the tier could not be determined
# Not checked here, because they need a person, a container runtime or a forge:
#   - that the pre-commit hooks RUN successfully (run them: `lefthook run pre-commit` or
#     `pre-commit run --all-files`), only that they are configured and installed;
#   - that architecture/workspace.dsl validates (run the Structurizr validate for your runtime);
#   - that SECURITY.md's Scope is a good threat model, only that it is filled in;
#   - that private vulnerability reporting is on (GitHub: gh api repos/{owner}/{repo}/private-vulnerability-reporting --jq .enabled).
set -u
fail=0
ok()   { echo "ok    [$1] $2"; }
bad()  { echo "FAIL  [$1] $2"; fail=1; }
note() { echo "note  $*"; }

tier=""; public=0
for a in "$@"; do
  case "$a" in t0|t1|t2) tier=$a ;; --public) public=1 ;; *) echo "usage: $0 [t0|t1|t2] [--public]" >&2; exit 2 ;; esac
done
if [ -z "$tier" ] && [ -f CLAUDE.md ]; then
  tier=$(sed -nE 's/^Current tier: \*\*(t[012])\*\*.*/\1/p' CLAUDE.md | head -1)
fi
[ -n "$tier" ] || { echo "FAIL  tier unknown: pass t0|t1|t2, or state 'Current tier: **tN**' in CLAUDE.md" >&2; exit 2; }
if [ "$public" -eq 0 ] && [ -f CLAUDE.md ] && grep -qE 'Distribution profile\*\*: *Public' CLAUDE.md; then public=1; fi
rank=${tier#t}

git rev-parse --git-dir >/dev/null 2>&1 || { echo "FAIL  [t0] not inside a git repository"; exit 1; }

# ---------------------------------------------------------------- t0
if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
  if git log --format=%s | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?: .+'; then
    ok t0 "at least one conventional commit"
  else bad t0 "no commit subject is a conventional commit (type(scope): subject)"; fi
else bad t0 "no commits yet"; fi

if [ ! -f CLAUDE.md ]; then bad t0 "CLAUDE.md is missing"
else
  if grep -qE "^Current tier: \*\*$tier\*\*" CLAUDE.md; then ok t0 "CLAUDE.md states 'Current tier: **$tier**'"
  else bad t0 "CLAUDE.md does not state 'Current tier: **$tier**' under ## Project Tier"; fi
  ctx=$(sed -nE 's/^- \*\*Tier\*\*: *(t[012]).*/\1/p' CLAUDE.md | head -1)
  if [ -n "$ctx" ] && [ "$ctx" != "$tier" ]; then bad t0 "CLAUDE.md Project Context says Tier: $ctx but the tier is $tier"; fi
fi

# .gitignore, judged by itself in a scratch repository: your global excludes file is not the project's
if [ -f .gitignore ]; then
  tmp=$(mktemp -d) && git -C "$tmp" init -q && cp .gitignore "$tmp/.gitignore"
  miss=""
  for p in .env .env.local server.pem server.key credentials.json CLAUDE.local.md; do
    git -C "$tmp" -c core.excludesFile=/dev/null check-ignore -q --no-index "$p" 2>/dev/null || miss="$miss $p"
  done
  rm -rf "$tmp"
  if [ -z "$miss" ]; then ok t0 ".gitignore covers .env, *.pem, *.key, credentials.json, CLAUDE.local.md"
  else bad t0 ".gitignore does not ignore:$miss"; fi
else bad t0 ".gitignore is missing"; fi

# ---------------------------------------------------------------- t1
if [ "$rank" -ge 1 ]; then
  if [ -f CHANGELOG.md ] && grep -qE '^## \[Unreleased\]' CHANGELOG.md; then ok t1 "CHANGELOG.md has an [Unreleased] section"
  else bad t1 "CHANGELOG.md is missing or has no '## [Unreleased]' section"; fi

  for b in main develop; do
    if git show-ref --verify --quiet "refs/heads/$b"; then ok t1 "branch $b exists"; else bad t1 "branch $b does not exist"; fi
  done

  adrs="0001 0002 0003"
  if [ -f CLAUDE.md ] && grep -qE '\*\*Category\*\*: *(Infrastructure|Hybrid)' CLAUDE.md; then adrs="$adrs 0004"; fi
  for n in $adrs; do
    if compgen -G "docs/adr/$n-*.md" >/dev/null; then ok t1 "docs/adr/$n-*.md exists"; else bad t1 "docs/adr/$n-*.md is missing"; fi
  done

  if [ -f README.md ]; then ok t1 "README.md exists"; else bad t1 "README.md is missing"; fi

  cfg=""; for c in lefthook.yml lefthook.yaml .lefthook.yml .pre-commit-config.yaml; do [ -f "$c" ] && cfg=$c && break; done
  if [ -z "$cfg" ]; then bad t1 "no hook manager config (lefthook.yml or .pre-commit-config.yaml)"
  else
    ok t1 "hook manager configured ($cfg)"
    for h in pre-commit pre-push; do
      hp=$(git rev-parse --git-path "hooks/$h")
      if [ -x "$hp" ]; then ok t1 "$h hook installed ($hp)"; else bad t1 "$h hook not installed at $hp"; fi
    done
    note "hooks are installed, not proven to pass: run 'lefthook run pre-commit' (or 'pre-commit run --all-files')"
  fi
fi

# ---------------------------------------------------------------- t2
if [ "$rank" -ge 2 ]; then
  for d in tutorials howto reference explanation adr architecture sprints roadmap; do
    if [ -d "docs/$d" ]; then ok t2 "docs/$d/ exists"; else bad t2 "docs/$d/ is missing"; fi
  done
  for f in architecture/workspace.dsl docs/roadmap/roadmap.md docs/sprints/sprint-0001-plan.md; do
    if [ -f "$f" ]; then ok t2 "$f exists"; else bad t2 "$f is missing"; fi
  done
  if [ -f CLAUDE.md ] && grep -qE '^## Current Development Status' CLAUDE.md; then ok t2 "CLAUDE.md has '## Current Development Status'"
  else bad t2 "CLAUDE.md has no '## Current Development Status' section"; fi
  note "architecture/workspace.dsl exists, not proven to validate: run the Structurizr validate for your container runtime"
fi

# ---------------------------------------------------------------- Public profile
if [ "$public" -eq 1 ]; then
  if [ ! -f SECURITY.md ]; then bad public "SECURITY.md is missing"
  else
    grep -qE '^## Reporting a Vulnerability' SECURITY.md && ok public "SECURITY.md has '## Reporting a Vulnerability'" \
      || bad public "SECURITY.md has no '## Reporting a Vulnerability' section"
    if grep -qE 'security/advisories/new|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+' SECURITY.md; then ok public "SECURITY.md names a private reporting channel"
    else bad public "SECURITY.md names no private channel (a security/advisories/new link or an email address)"; fi
    scope=$(awk '/^## Scope/{f=1;next} /^## /{f=0} f' SECURITY.md)
    if [ -z "$scope" ]; then bad public "SECURITY.md has no '## Scope' section"
    elif printf '%s' "$scope" | grep -qE '\[Author-filled|\{[a-z-]+\}|\[N business days\]'; then bad public "SECURITY.md Scope is still the template placeholder"
    elif [ "$(printf '%s' "$scope" | wc -w | tr -d ' ')" -lt 20 ]; then bad public "SECURITY.md Scope is under 20 words — not a threat model"
    else ok public "SECURITY.md Scope is filled in"; fi
    if grep -qE '\{[a-z-]+\}|\[N business days\]' SECURITY.md; then bad public "SECURITY.md still has template placeholders ({owner}, [N business days], ...)"; fi
  fi
  if [ -f CLAUDE.md ] && grep -qE 'Distribution profile\*\*:' CLAUDE.md; then ok public "CLAUDE.md records the distribution profile"
  else bad public "CLAUDE.md ## Project Context does not record the distribution profile"; fi
  note "private vulnerability reporting must be on: gh api repos/{owner}/{repo}/private-vulnerability-reporting --jq .enabled   # -> true"
fi

# ---------------------------------------------------------------- GitHub remote
if git remote -v | grep -q 'github\.com'; then
  if [ -f .github/dependabot.yml ] || [ -f .github/dependabot.yaml ]; then ok remote ".github/dependabot.yml exists"
  else bad remote "a github.com remote exists but .github/dependabot.yml does not"; fi
fi

exit "$fail"
```

Exit codes: **0** every check passed; **1** at least one failed (each line names its tier); **2** the tier
could not be determined. It checks, by tier:

- **t0**: at least one conventional commit; CLAUDE.md states the tier and its Project Context agrees;
  `.gitignore` covers `.env`, `*.pem`, `*.key`, `credentials.json` and `CLAUDE.local.md` — judged
  by the file alone in a scratch repository, because your own global excludes file is not the project's.
- **t1**: `CHANGELOG.md` with `[Unreleased]`; `main` and `develop`; ADR-0001 to 0003 (and 0004 when the
  Category is Infrastructure or Hybrid); a README; a hook manager configured and both `pre-commit` and
  `pre-push` installed.
- **t2**: the `docs/` tree, `architecture/workspace.dsl`, the roadmap, the Sprint 1 plan, and a
  `## Current Development Status` section.
- **Public profile**: `SECURITY.md` with a reporting section, a private channel (an advisories link or an
  email address), no template placeholders left, and a Scope of at least 20 words that is not the
  template's; CLAUDE.md records the distribution profile.
- **A github.com remote**: `.github/dependabot.yml`.

What it does **not** check, and you must:

- That the hooks **run** and pass: it checks they are installed. Run `lefthook run pre-commit` (or
  `pre-commit run --all-files`) on the initial commit.
- That `architecture/workspace.dsl` **validates**: run the Structurizr validate for your container runtime.
- That audience-traced artifacts align with the audience categories (if a registry exists).
- That the Scope is a *good* threat model, only that it is filled in; and that private vulnerability
  reporting is on: `gh api repos/{owner}/{repo}/private-vulnerability-reporting --jq .enabled` → `true`.

Tested against fixtures with each check's fault planted (39 cases), and against real projects: two
bootstrapped with this skill (`bomdive`, `portfolio`) pass at t1, a third (`mmd2tex`) passes at t2, and two
more at t1 fail only on the `.github/dependabot.yml` their github.com remote calls for. Projects not
bootstrapped with this skill fail on the tier line and more, as they should. Not yet run in CI.

## Related Skills

- `analyze-project` - Run SPARK analysis before bootstrap
- `setup-adrs` - Next step: create foundational ADRs
- `setup-git-hooks` - Configure two-stage git hooks
- `setup-architecture-as-code` - Create architecture model
- `plan-sprint` - Create initial sprint plan
- `public-release` (project-maintenance-skills) - Private→Public graduation gate (full go-public checklist)
- `harden-github-actions` - CI hardening for Public + `ships-artifacts` projects
- `setup-container-security` - container image hardening (digest pins, non-root, grype/SBOM)
