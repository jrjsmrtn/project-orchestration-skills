---
name: analyze-project
description: Conduct SPARK methodology analysis for new project inception. Use at the beginning of a new project, when evaluating significant features, before bootstrap-project to validate viability, or when pivoting an existing project.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.43"
license: MIT
---

# SPARK Analysis

Conduct SPARK methodology analysis for new project inception.

## When to Use

- At the very beginning of a new project
- When evaluating a significant new feature or system
- Before running `bootstrap-project` to validate project viability
- When pivoting or reassessing an existing project

## What is SPARK?

SPARK is a structured inception methodology for validating project viability:

- **S**takeholders: Who is affected and who has influence?
- **P**roblem: What problem are we solving? What's the scope?
- **A**nalysis: What exists? What are the options? What are the constraints?
- **R**isks: What could go wrong? How do we mitigate?
- **K**nowledge: What do we know? What gaps exist?

## Required Inputs

1. **Project idea/concept** (initial description)
2. **Context** (why now? what triggered this?)
3. **Initial stakeholder list** (who asked for this?)
4. **Time constraints** (deadline pressures?)
5. **Budget/resource constraints** (if known)

## Workflow

### Phase 1: Stakeholder Analysis

Identify and analyze all stakeholders:

```markdown
## Stakeholders

### Primary Stakeholders (Direct Users)

| Stakeholder | Role | Needs | Influence | Engagement |
|-------------|------|-------|-----------|------------|
| [Name/Role] | [What they do] | [What they need] | High/Med/Low | [How to engage] |

### Secondary Stakeholders (Indirect Impact)

| Stakeholder | Interest | Impact | Communication |
|-------------|----------|--------|---------------|
| [Name/Role] | [Their interest] | [How affected] | [How to inform] |

### Key Questions to Answer
- Who will use this system daily?
- Who will maintain/operate it?
- Who funds/sponsors it?
- Who could block or derail the project?
- Who has domain expertise we need?
```

**AI Assistance**: Use Explore agent to research similar projects and identify commonly overlooked stakeholders.

### Phase 1b: Create Audience Registry

Transform stakeholders into an **Audience Registry** - a standalone reference document that becomes the anchor for all downstream artifacts.

Create `docs/reference/audience-registry.md`:

```markdown
# Audience Registry

Single source of truth for project audiences and their artifact needs.

## Audiences

| ID | Audience | Category | Needs | Derived Artifacts |
|----|----------|----------|-------|-------------------|
| A1 | [Role] | Primary | [Use the system for...] | BDD:user-*, Tutorial:*, C4:Person |
| A2 | [Role] | Integration | [Connect via...] | BDD:api-*, Reference:*, C4:ExternalSystem |
| A3 | [Role] | Operational | [Deploy/maintain...] | BDD:ops-*, Howto:*, C4:Operator |
| A4 | [Role] | Contribution | [Extend/maintain code...] | Explanation:*, C4:Component view |

## Category Definitions

| Category | Focus | Typical Roles | Primary Artifacts |
|----------|-------|---------------|-------------------|
| **Primary** | Using the system | End-users, consumers | Tutorials, User BDD, SystemContext |
| **Integration** | Connecting to the system | Developers, API consumers | Reference docs, API BDD, Container view |
| **Operational** | Running the system | Sysadmins, operators, SREs | How-tos, Ops BDD, Deployment view |
| **Contribution** | Extending the system | Contributors, maintainers | Explanation, ADRs, Component view |

## Traceability

Every artifact should reference an audience ID:
- BDD features: `@audience:A1`
- Documentation frontmatter: `audience: A1`
- C4 persons/actors map to Primary/Integration audiences

## Artifact Coverage Matrix

| Audience | BDD | Tutorial | How-to | Reference | Explanation | C4 Element |
|----------|-----|----------|--------|-----------|-------------|------------|
| A1 | [ ] | [ ] | - | - | - | [ ] |
| A2 | [ ] | - | - | [ ] | - | [ ] |
| A3 | [ ] | - | [ ] | - | - | [ ] |
| A4 | - | - | - | - | [ ] | [ ] |

---
*Created from SPARK analysis on [date]*
*Last updated: [date]*
```

**AI Assistance**: AI can suggest audience consolidation and identify gaps in artifact coverage.

> **Pattern Reference**: See [AUDIENCE-DRIVEN ARTIFACTS](https://github.com/jrjsmrtn/ai-assisted-project-orchestration/blob/develop/docs/patterns/inception/audience-driven-artifacts.md)

### Phase 2: Problem Definition

Define the problem clearly and scope boundaries:

```markdown
## Problem Definition

### Problem Statement
[1-2 sentence clear statement of the problem]

### Current State
- How is this problem handled today?
- What pain points exist?
- What workarounds are people using?

### Desired Future State
- What does success look like?
- How will we measure success?
- What capabilities will exist that don't exist now?

### Scope Boundaries

**In Scope**:
- [Capability 1]
- [Capability 2]
- [Capability 3]

**Out of Scope** (explicitly excluded):
- [Excluded item 1 and why]
- [Excluded item 2 and why]

**Deferred** (future consideration):
- [Deferred item 1]
- [Deferred item 2]

### Success Criteria
1. [Measurable criterion 1]
2. [Measurable criterion 2]
3. [Measurable criterion 3]
```

**AI Assistance**: Use AI to challenge assumptions, identify edge cases, and ensure problem is well-defined.

### Phase 3: Analysis

Analyze the landscape, options, and constraints:

```markdown
## Analysis

### Existing Solutions

| Solution | Pros | Cons | Why Not Sufficient |
|----------|------|------|-------------------|
| [Existing 1] | [pros] | [cons] | [gap] |
| [Existing 2] | [pros] | [cons] | [gap] |

### Technology Options

| Option | Fit | Maturity | Team Experience | Decision |
|--------|-----|----------|-----------------|----------|
| [Tech 1] | High/Med/Low | [status] | [experience] | Consider/Reject |
| [Tech 2] | High/Med/Low | [status] | [experience] | Consider/Reject |

### Constraints

**Technical Constraints**:
- [Constraint 1: e.g., must integrate with existing system X]
- [Constraint 2: e.g., must run on infrastructure Y]

**Business Constraints**:
- [Constraint 1: e.g., budget limit]
- [Constraint 2: e.g., timeline requirement]

**Organizational Constraints**:
- [Constraint 1: e.g., team skills]
- [Constraint 2: e.g., approval processes]

### Dependencies

| Dependency | Type | Status | Risk if Unavailable |
|------------|------|--------|---------------------|
| [Dep 1] | Technical/Organizational | Available/Pending | [impact] |
| [Dep 2] | Technical/Organizational | Available/Pending | [impact] |

### Upstream Acceptance (if the plan depends on a third party *accepting* something)

When viability rests on an **external party accepting a contribution** — an upstream merge, a
registry/standard entry, a partner integration — model what they **require of you**, not only whether
they would want it. *"Will they want it?"* and *"what do they require of me?"* are two questions; the
second is usually cheaper and answerable **before any code is written**.

| Upstream | What we need accepted | Acceptance requirement | Met? | Cost to meet |
|----------|-----------------------|------------------------|------|--------------|
| [e.g. anchore/syft] | [a new cataloger] | DCO / CLA / AI-policy / inbound licence / test bar | Yes/No/Unknown | Low/Med/High |

Confirm each, before building — read `CONTRIBUTING`, the DCO/CLA, and a few recent merged PRs:

- **Contribution agreement** — DCO (`Signed-off-by`, retroactive-fixable) vs a **CLA**. Which, and can you sign it?
  - A DCO problem is fixable in minutes by amending a commit. **A CLA problem may not be yours to fix**: the standard employer clause (ICLA §4) requires you to represent that your employer has waived rights to your contributions, or has itself executed a Corporate CLA. If your employer has rights to what you create, that is *their* signature to obtain — weeks, if it happens. Start it before writing code, not before opening the PR.
  - A Corporate CLA does not remove the need for each developer's individual one.
  - CLAs differ per steward: some license, some assign, some take relicensing rights. **Read the specific agreement** — the category name tells you nothing about the terms.
- **AI-contribution policy** — some projects restrict, ban, or require *disclosure* of AI-generated contributions. Against a project that bans them, unaware work is wasted **entirely**; disclosure is cheap only if known up front. See *Finding the AI-contribution policy* below — `CONTRIBUTING` is the wrong place to stop looking.
- **Inbound licence compatibility** — your contribution must be licensable under *their* terms. This is the **opposite direction** from the `Dependencies` check (you consuming their licence) and is easy to conflate.
- **Governance & responsiveness** — who decides, how long merges take, whether the maintainer is active. A technically-welcome contribution can still stall for months.

### Competitive Analysis (if applicable)

| Competitor | Strengths | Weaknesses | Differentiation |
|------------|-----------|------------|-----------------|
| [Comp 1] | [strengths] | [weaknesses] | [how we differ] |
```

**Why Upstream Acceptance is its own subsection**: `Dependencies` models what the project *consumes* and needs to stay *available*; Upstream Acceptance models what the project must *satisfy* to be *accepted* — a different failure mode. Grounding (a real case): a project whose distribution strategy rested on contributing a cataloger to an upstream analysed thoroughly whether the upstream would *want* it, but never what it *required of a contributor* — DCO sign-off, and an (absent, that time) AI-contribution policy, were discovered only after the code was written and the PR opened. Benign there; against a project that bans AI contributions the whole effort would have been wasted, and surfaced at submission rather than at decision time.

#### Finding the AI-contribution policy

Reading `CONTRIBUTING` is where this check usually stops, and it is not where the policy usually
lives. Across projects that have written one, it has been found in **five** different places:

| Where | Seen in |
|---|---|
| A dedicated policy page or in-tree process doc | Linux kernel (`Documentation/process/coding-assistants.rst`), QEMU (`code-provenance`) |
| The **Code of Conduct** | Zig — placement matters: a violation is *misconduct*, not a rejected patch |
| The contribution guide's own AI section | Git (`SubmittingPatches`), Ansible, Python devguide |
| The **security / reporting** page | curl — disclosure is mandatory for AI-found vulnerabilities |
| The project's **foundation** | Linux Foundation, Apache, OpenInfra — these are *floors*; the project may be stricter |

Check the foundation **as well as** the project, never instead of it. A permissive foundation
baseline says nothing about a project that has written its own rule, and the more active the
project, the likelier it has.

**Ask the shape, not the verdict.** "Banned or allowed?" is the wrong question and produces wrong
answers — most restrictive policies carry a route, and the route is the operative part:

- **Is there a permitted path, and who decides?** Bans are frequently conditional — a named approver,
  a documented exceptions process, a pre-arranged reviewer.
- **Is disclosure required, encouraged, or unwanted?** And **above what threshold** — any assistance,
  or unmodified bulk?
- **In what format?** `Assisted-by:` and `Generated-by:` are both in use and are *not* synonyms —
  one names predictive assistance, the other generative authorship, and value grammars differ
  between projects that share a field name. Copy the target project's spelling; do not assume.
  **Do not reach for `Co-developed-by:`** — widely recommended for AI attribution before project
  policies landed, and structurally invalid for a tool: it denotes *authorship*, so the Linux kernel
  requires each one be immediately followed by a `Signed-off-by:` from that co-author — which the
  same project forbids an AI agent from adding. The trailer would demand a sign-off no tool may
  give.
- **Does it cover prose and conversation, or only code?** Several policies govern issue comments,
  PR descriptions and forum posts, not just patches.
- **Can you explain every line under review?** This is the one test nearly every policy applies,
  however it is worded, and it is failable with no AI involved.

**An absent policy is not permission.** It may mean a policy is in progress, or a vote is live, and
work submitted now can be judged under a rule adopted next month. When nothing is published,
disclose voluntarily and ask on the project's list — that is safe under every outcome.

**Do not rely on a summary of someone else's policy**, including a summary in this skill. Compression
reliably drops the qualifier that decides what you must do. Read the project's own page, and record
the date you read it — these change without announcement.

**Sourced records for specific organisations** — what each policy says, quoted from its own text,
with who verified it and when — are in
[`ai-contribution-policies`](https://github.com/jrjsmrtn/ai-contribution-policies), whose
[overview](https://github.com/jrjsmrtn/ai-contribution-policies/blob/main/knowledge/overview.md) is
the map the guidance above condenses. It is **curated, not exhaustive**, and carries per-record
expiry: a record past its `stale_after` is a prompt to re-read the source, not an answer. Use it to
know *what to look for*; confirm against the project's own page before deciding.

**AI Assistance**: Use web search and Explore agents to research existing solutions, competitors, and technology options — and, for any Upstream Acceptance row, to read the upstream's `CONTRIBUTING`, DCO/CLA, and AI-contribution policy before work starts, checking each of the five locations above.

### Phase 4: Risk Assessment

Identify and plan for risks:

```markdown
## Risk Assessment

### Risk Register

| ID | Risk | Category | Likelihood | Impact | Score | Mitigation |
|----|------|----------|------------|--------|-------|------------|
| R1 | [Risk description] | Technical | H/M/L | H/M/L | [L×I] | [Strategy] |
| R2 | [Risk description] | Schedule | H/M/L | H/M/L | [L×I] | [Strategy] |
| R3 | [Risk description] | Resource | H/M/L | H/M/L | [L×I] | [Strategy] |
| R4 | [Risk description] | External | H/M/L | H/M/L | [L×I] | [Strategy] |

### Risk Categories
- **Technical**: Technology unknowns, integration challenges, performance
- **Schedule**: Timeline pressures, dependencies, estimation uncertainty
- **Resource**: Skills gaps, availability, budget
- **External**: Vendor dependencies, regulatory, market changes
- **Organizational**: Stakeholder alignment, change management

### Top 3 Risks (Prioritized)

1. **[Highest Risk]**
   - Why critical: [explanation]
   - Mitigation plan: [specific actions]
   - Contingency: [if mitigation fails]

2. **[Second Risk]**
   - Why critical: [explanation]
   - Mitigation plan: [specific actions]
   - Contingency: [if mitigation fails]

3. **[Third Risk]**
   - Why critical: [explanation]
   - Mitigation plan: [specific actions]
   - Contingency: [if mitigation fails]

### Risk Monitoring
- How will risks be tracked?
- When will risks be reviewed?
- Who owns risk management?
```

**AI Assistance**: Use AI to brainstorm risks, especially technical risks based on technology choices.

### Phase 5: Knowledge Assessment

Identify what's known and what gaps exist:

```markdown
## Knowledge Assessment

### What We Know (Validated)
- [Known fact 1 with source/evidence]
- [Known fact 2 with source/evidence]
- [Known fact 3 with source/evidence]

### What We Assume (Needs Validation)
| Assumption | Basis | How to Validate | Priority |
|------------|-------|-----------------|----------|
| [Assumption 1] | [why we believe this] | [validation method] | High/Med/Low |
| [Assumption 2] | [why we believe this] | [validation method] | High/Med/Low |

### Knowledge Gaps (Research Needed)
| Gap | Impact if Not Filled | Research Approach | Owner |
|-----|---------------------|-------------------|-------|
| [Gap 1] | [impact] | [how to research] | [who] |
| [Gap 2] | [impact] | [how to research] | [who] |

### Upstream Acceptance Gaps (obligations to satisfy, not dependencies to consume)
For every party the plan needs to *accept* something (Phase 3 → Upstream Acceptance), the cheapest gap
to close **first** is what they require of a contributor — resolve it before building, not at
submission. A standing category because the rest of Phase 5 assesses knowledge for *building*; this
assesses knowledge for *being accepted*, and it is the one gap that is both cheap to answer and able to
invalidate the whole plan.

| Upstream | Requirement to confirm | How to check | Blocks the plan if unmet? |
|----------|------------------------|--------------|---------------------------|
| [upstream] | DCO vs CLA; AI-policy; inbound licence; review/test bar | read `CONTRIBUTING` / DCO / CLA / recent merged PRs | Yes/No |

### Domain Expertise Needed
- [Domain 1]: [current capability] → [needed capability]
- [Domain 2]: [current capability] → [needed capability]

### Proof of Concept Needs
| POC | Purpose | Success Criteria | Effort |
|-----|---------|------------------|--------|
| [POC 1] | [what we're validating] | [how we know it works] | [estimate] |
```

**AI Assistance**: AI can help identify knowledge gaps and suggest research approaches.

### Phase 6: Synthesis and Recommendation

Bring it all together:

```markdown
## SPARK Synthesis

### Project Viability Assessment

| Dimension | Score (1-5) | Notes |
|-----------|-------------|-------|
| Stakeholder Alignment | X | [brief note] |
| Problem Clarity | X | [brief note] |
| Solution Feasibility | X | [brief note] |
| Risk Manageability | X | [brief note] |
| Knowledge Readiness | X | [brief note] |
| **Overall** | **X.X** | |

### Recommendation

**Proceed / Proceed with Conditions / Do Not Proceed**

[2-3 sentence recommendation with rationale]

### Conditions for Success (if proceeding)
1. [Condition 1]
2. [Condition 2]
3. [Condition 3]

### Immediate Next Steps
1. [Action 1] - [Owner] - [Deadline]
2. [Action 2] - [Owner] - [Deadline]
3. [Action 3] - [Owner] - [Deadline]

### Open Questions for Stakeholder Review
1. [Question requiring stakeholder input]
2. [Question requiring stakeholder input]
```

## Output Document

Create `docs/inception/spark-analysis.md` with all sections above.

## Outputs

This skill creates:
- [ ] `docs/inception/` directory
- [ ] `docs/inception/spark-analysis.md` (complete SPARK analysis)
- [ ] `docs/reference/audience-registry.md` (standalone, used by downstream skills)

## Validation

SPARK analysis is valid when:
- [ ] All 5 dimensions (S-P-A-R-K) are addressed
- [ ] Stakeholders are identified and prioritized
- [ ] Audience Registry covers all four categories (or documents why not)
- [ ] Problem is clearly scoped with boundaries
- [ ] At least 3 technology options evaluated
- [ ] Top risks identified with mitigations
- [ ] Knowledge gaps have research plans
- [ ] Clear recommendation with rationale

## AI Collaboration Strategy

| SPARK Phase | AI Role | Human Role |
|-------------|---------|------------|
| Stakeholders | Suggest overlooked stakeholders | Validate relevance, prioritize |
| Problem | Challenge assumptions, find edge cases | Define scope, set success criteria |
| Analysis | Research solutions, compare technologies | Make strategic decisions |
| Risks | Brainstorm risks, suggest mitigations | Prioritize, assign ownership |
| Knowledge | Identify gaps, suggest research | Validate assumptions, fill gaps |
| Synthesis | Draft summary | Make go/no-go recommendation |

## Related Skills

- `bootstrap-project` - Run after SPARK if proceeding
- `setup-adrs` - Document key decisions from SPARK
- `setup-architecture-as-code` - Architecture emerges from SPARK analysis
