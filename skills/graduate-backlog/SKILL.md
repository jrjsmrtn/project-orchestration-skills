---
name: graduate-backlog
description: Graduate a project's in-repo backlog (roadmap phases, sprint deliverables, ADRs) onto a forge issue tracker at a thin-hybrid default, once the backlog outgrows a single contributor. Use when a team needs to see and claim work that currently lives only in docs/roadmap and docs/sprints, when a repo has a mature in-repo roadmap but an empty tracker, when open-sourcing a project, or when deciding what work should stay in-repo versus live on a GitHub, GitLab, Codeberg/Forgejo, or self-hosted internal tracker.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.30"
license: MIT
---

# Backlog Graduation

Bridge a project's **in-repo backlog** onto a **forge issue tracker** at the moment the backlog
outgrows a single contributor. The orchestration skills author a rich in-repo backlog —
`docs/roadmap/roadmap.md` (phases → target versions → task lists), `docs/sprints/*.md`
(plans/retrospectives), a Nygard ADR sequence, and a Keep-a-Changelog `CHANGELOG.md`. Once more
than one person needs to see and claim that work, they need a tracker — but that transform is
manual and uncodified.

This skill performs it **conservatively**. The default is **thin-hybrid**: planning stays in-repo,
and the tracker holds only incoming/reactive work plus — at most — the current milestone's tactical
items. That is *light externalization*, not a board build-out. A richer board is opt-in (the
`roadmap-visible` level), justified by a real need for roadmap visibility.

> **The trigger is team scale, not exposure.** Graduation is driven by *who needs to see the work*
> — the same signal as the t0→t1 tier bump ("more than one contributor"). It is **not** gated on
> the **Public** distribution profile: a corporate team on an internal GitLab needs a board without
> ever open-sourcing, and a solo public repo may never need one. Exposure gates *compliance
> controls*, not *work organization*. (Workspace decision records: "Distribution-Profile Axis for
> Compliance Qualification", "Work-Organization Graduation: Thin-Hybrid Backlog Externalization",
> "Plugin Taxonomy by Lifecycle, Not Exposure" — cited by title because bare numbers would collide
> with the *target project's* own ADR sequence, which Phase 3 writes into.)

> **Establish vs operate.** This skill *establishes* tracker structure from the backlog;
> `incoming-issue` (**project-maintenance-skills**) *operates* it afterward. Where that plugin is
> installed it owns the richer contributor-facing setup — issue templates, `good first issue`, the
> full triage taxonomy. This skill creates only the minimal labels it needs, so it works standalone
> in contexts where the maintenance plugin is absent.

## When to Use

- When a project's backlog outgrows one contributor and the team needs claimable work items
- When a repo has a mature in-repo roadmap but an empty or default-only tracker
- When deciding the **hybrid boundary** — what stays canonical in-repo vs what the tracker owns
- At the `public-release` go/no-go gate (project-maintenance-skills), deciding how work is organized publicly
- Re-running incrementally after new phases or sprints land (the skill is idempotent)

**Not for:** Solo projects with no collaborators — the backlog stays in-repo; say so and stop.
Building a heavy Projects-v2 board unless roadmap visibility is an explicit goal. Re-cutting
already-shipped work as issues.

## Required Inputs

1. **Repository** — the forge and `owner/repo`, auto-detected from git remotes.
2. **Scope** — what to run:
   - `plan` — Phases 1–2: analyze the in-repo backlog and emit the hybrid-boundary decision; **no writes** (dry run)
   - `milestones` — Phase 4: seed milestones from **open** roadmap phases
   - `issues` — Phase 5: create labels, then issues from **current-sprint open deliverables**
   - `full` — Phases 1–6 in sequence: plan → confirm → record the boundary ADR (Phase 3) → milestones → issues → reconcile (Phase 6). Phases 3 and 6 are what produce the skill's headline output and anti-drift rule, so `full` is the only scope that satisfies this skill's own Validation.
3. **Externalization level** (default `thin`):
   - `thin` — milestones for open phases + issues for current-sprint deliverables only (default)
   - `roadmap-visible` — Phase 5b: additionally mirror open roadmap phases as tracked issues, for team and stakeholder visibility of the longer arc

## Workflow

### Phase 1: Detect Context & Confirm Eligibility

1. **Detect the forge** from remotes:
   ```bash
   git remote -v
   ```
   - `github.com` → `gh`
   - `gitlab.com` / self-hosted GitLab → `glab`
   - `codeberg.org` / self-hosted Forgejo/Gitea → `tea` (the Gitea/Forgejo CLI), or the Gitea REST API

   The hybrid-boundary decision (Phases 2–3, 6) is **forge-independent** — only the seeding commands in
   Phases 4–5 branch by forge. See the [Forge Command Reference](#forge-command-reference) for the
   per-forge equivalents.
   A **self-hosted** GitLab or Forgejo/Gitea instance is a first-class target: point the CLI at it
   (`glab auth login --hostname gitlab.internal.example`, `tea login add --url …`) — the workflow is
   identical. An internal corporate forge is a normal case, not an exception.

2. **Confirm the backlog has outgrown one contributor.** Graduation is triggered by **team scale**,
   not exposure — do *not* check the distribution profile:
   ```bash
   git shortlog -sn --since="6 months ago" HEAD | head
   ```
   Proceed if any of these hold: more than one recent committer; the project accepts contributions
   from beyond the maintainer (an open contributor base is a team, whatever the exposure); or the
   maintainer states that collaborators need claimable work.
   **If it is a genuinely solo project with no collaborators, stop** — a tracker adds ceremony
   without a reader. Say so plainly rather than seeding an audience-free board.

3. **Locate source artifacts** (skip gracefully if absent):
   - `docs/roadmap/roadmap.md` — phases, target versions, task lists, Sprint History
   - `docs/sprints/` — current sprint plan (open deliverables) + `README.md` index
   - `docs/adr/` (+ `index.yml` if present) — decision log (back-link targets)
   - `CHANGELOG.md` — the `[Unreleased]` section (authoritative shipped-work record)

4. **Check tracker preconditions:** do the labels this skill maps onto exist?
   ```bash
   gh label list   # glab label list | tea labels ls
   ```
   Type labels (`enhancement` / `bug` / `documentation`) are GitHub defaults and usually exist
   already; on GitLab/Forgejo they may not. The `priority: *` labels rarely exist anywhere.
   **Create only what is missing** (Phase 5) — this skill is self-sufficient and must not assume
   another plugin has run.

   If `incoming-issue` (project-maintenance-skills) *is* available and the project is **Public**,
   prefer running it (scope: `setup`) first: it establishes the full contributor-facing taxonomy and
   issue templates, of which these labels are a subset. Treat it as an **enrichment, not a
   prerequisite** — a corporate consumer may not have that plugin installed at all.

### Phase 2: Analyze the In-Repo Backlog (scope: `plan`)

Parse and classify — **read-only**, no forge writes:

- **Roadmap phases** → each `{title, target version, status}`. Split into **open** (candidate
  milestones) and **completed** (never re-cut).
- **Current sprint deliverables** → the open, discrete, titled items from the latest
  `docs/sprints/sprint-NNNN-plan.md` (candidate issues).
- **ADR index** → id/title/status, for back-linking.
- **CHANGELOG `[Unreleased]`** → the trustworthy record of what actually shipped.

> **Trust the changelog over checkboxes.** Roadmap `- [ ]` checkbox state is frequently stale
> (shipped features left unticked). Corroborate any "done" against `CHANGELOG.md` before excluding it,
> and derive issues from **sprint deliverables**, not from roadmap checkboxes.

Output a plan: candidate milestones, candidate issues, and the proposed hybrid boundary. In `plan`
scope, stop here and present it for confirmation.

### Phase 3: Decide & Record the Hybrid Boundary

Adopt the **thin-hybrid** default and record it as a **project-local** ADR in the target project's
own `docs/adr/` (use its `setup-adrs` adrtools numbering — title `# N. Work-Organization Boundary`).
This is the target project's decision, distinct from the workspace ADR that defines the stance:

| Concern | Canonical home | Rationale |
|---|---|---|
| Strategic roadmap (phases, target versions) | **in-repo** `roadmap.md` | version-controlled north star |
| Architecture decisions | **in-repo** `docs/adr/` | the "why"; back-link target for issues |
| Sprint retrospectives | **in-repo** `docs/sprints/` | narrative record |
| Incoming / community / reactive work | **tracker** | contributor-facing |
| Current-milestone tactical items | **tracker** (thin) | claimable by contributors |
| Per-issue / milestone status | **tracker** (single source of truth) | avoids table drift |

Record the **single source of truth for tactical status** explicitly, so hand-maintained tables
(roadmap Sprint History, `docs/sprints/README.md`) don't drift against the board.

### Phase 4: Seed Milestones — Open Phases Only (scope: `milestones`)

Create one milestone per **open** roadmap phase. **Idempotent** — check for an existing milestone of
the same title before creating:

```bash
# List existing milestone titles
gh api "repos/{owner}/{repo}/milestones?state=open" --jq '.[].title'

# Create only if absent
gh api "repos/{owner}/{repo}/milestones" \
  -f title="Phase 3 — v0.2.0" \
  -f state="open" \
  -f description="Graduated from docs/roadmap/roadmap.md Phase 3. Canonical roadmap stays in-repo."
```

- **Skip completed phases** — no retroactive re-cut.
- A roadmap phase maps to a **milestone**, never a label.
- On GitLab (`glab`) or Forgejo (`tea`), use the equivalent from the [Forge Command Reference](#forge-command-reference); the open-phases-only and idempotency rules are unchanged.

### Phase 5: Seed Issues — Current-Sprint Deliverables (scope: `issues`)

Create issues from **current-sprint open deliverables** (Phase 2), each **back-linked** and
**idempotent** (search by a stable title before creating).

#### Step 1 — Create the labels first

Applying a label that does not exist fails the issue creation, so **this step precedes Step 2**.
Idempotent — each `label create` no-ops if the label is already there:

```bash
# Type labels: GitHub defaults, but absent on a fresh GitLab/Forgejo project
gh label create "enhancement"   --color a2eeef --description "New feature or request"                 2>/dev/null || true
gh label create "bug"           --color d73a4a --description "Something isn't working"                2>/dev/null || true
gh label create "documentation" --color 0075ca --description "Improvements or additions to documentation" 2>/dev/null || true

# Priority labels: rarely present on any forge
gh label create "priority: high"   --color d93f0b --description "Severe impact"   2>/dev/null || true
gh label create "priority: medium" --color e4e669 --description "Moderate impact" 2>/dev/null || true
gh label create "priority: low"    --color c2e0c6 --description "Minor impact"    2>/dev/null || true
```

> **Colours are part of the contract, not decoration.** They match `incoming-issue`'s taxonomy
> exactly. Because `label create` is made idempotent with `|| true`, **first writer wins** — a wrong
> colour here would survive silently forever once this skill runs first, and the two plugins would
> disagree with no error ever surfacing. Do not "improve" them.

See the [Forge Command Reference](#forge-command-reference) for the `glab`/`tea` equivalents.

#### Step 2 — Seed the issues

```bash
# Idempotency guard
gh issue list --search "in:title \"Wire the audit CI job\"" --state all --json number --jq '.[].number'

# Create, attach to milestone, apply the mapped priority/type labels (see the table below)
gh issue create \
  --title "Wire the audit CI job" \
  --milestone "Phase 3 — v0.2.0" \
  --label "enhancement" --label "priority: high" \
  --body "$(cat <<'BODY'
Graduated from docs/sprints/sprint-0004-plan.md (Deliverable 2).

**Back-links**
- Roadmap: docs/roadmap/roadmap.md → Phase 3
- ADR: docs/adr/0005-…
- Sprint: docs/sprints/sprint-0004-plan.md

Canonical strategic context stays in-repo; this issue tracks the tactical item only.
BODY
)"
```

**Vocabulary mapping** — do not invent new label names; these are the shared taxonomy:

| Internal (sprint plan) | Tracker |
|---|---|
| Story **Priority: High** | `priority: high` |
| Story **Priority: Medium** | `priority: medium` |
| Story **Priority: Low** | `priority: low` |
| Roadmap **phase** | **milestone** (not a label) |
| Deliverable kind (feature/bug/docs) | `enhancement` / `bug` / `documentation` |

> Exact names matter: bare type labels, and a **space** after `priority:`. Do not add a `type:`
> prefix or drop the space. These names are shared with `incoming-issue`
> (project-maintenance-skills), so a project that later adopts the maintenance plugin converges
> instead of ending up with two vocabularies — but nothing here *depends* on that plugin.

On GitLab (`glab`) or Forgejo (`tea`), swap the `gh issue create` line for the equivalent in the [Forge Command Reference](#forge-command-reference); the back-linking, idempotency, and vocabulary mapping are identical.

### Phase 5b: Mirror Roadmap Phases (only when level = `roadmap-visible`)

**Skip this at the `thin` default.** Only run it when the maintainer has explicitly asked for the
longer arc to be visible on the tracker — a team coordinating across phases, or stakeholders who
will not read `docs/roadmap/roadmap.md`.

For each **open** roadmap phase, create one tracked issue that mirrors it, attached to that phase's
milestone from Phase 4:

```bash
gh issue create \
  --title "Phase 3 — Knowledge-Formats Combination" \
  --milestone "Phase 3 — v0.2.0" \
  --label "documentation" \
  --body "Mirror of docs/roadmap/roadmap.md → Phase 3, for tracker visibility.

**The roadmap remains canonical.** This issue is a pointer, not the source of truth: do not
maintain phase scope here. Close it when the milestone closes."
```

- **Still no retroactive re-cut**: open phases only, exactly as Phase 4.
- These are **pointers, not a second backlog**. The moment someone edits phase scope in the issue
  rather than the roadmap, the boundary recorded in Phase 3 has been violated — that is the failure
  mode this level trades away, and why `thin` is the default.

### Phase 6: Reconcile & Anti-Drift

- State the **single source of truth** in the recorded ADR: the tracker owns per-issue/milestone
  status; the roadmap Sprint History remains the **narrative/version ledger** and *links out* rather
  than re-tallying open items.
- Note that `wrapup-sprint` should honour this boundary when it next updates status tables.
- **Re-run guidance:** the skill is idempotent — a later run adds only *new* open phases and *new*
  current-sprint deliverables; it never duplicates milestones/issues or resurrects closed ones.

## Forge Command Reference

The workflow above shows GitHub (`gh`). The decision logic is identical on every forge — only the
Phase 4/5 seeding commands change:

| Operation | GitHub — `gh` | GitLab — `glab` | Forgejo/Gitea — `tea` |
|---|---|---|---|
| List open milestones | `gh api "repos/{owner}/{repo}/milestones?state=open" --jq '.[].title'` | `glab api "projects/:fullpath/milestones?state=active" --jq '.[].title'` | `tea milestones ls --state open` |
| Create milestone | `gh api "repos/{owner}/{repo}/milestones" -f title="…" -f state=open` | `glab api --method POST "projects/:fullpath/milestones" -f title="…"` | `tea milestones create --title "…"` |
| Find issue by title | `gh issue list --search "in:title \"…\"" --state all` | `glab issue list --search "…"` | `tea issues ls --state all` |
| Create issue (+ milestone, labels) | `gh issue create --title "…" --milestone "…" --label "…"` | `glab issue create --title "…" --milestone "…" --label "…"` | `tea issues create --title "…" --milestone "…" --labels "…"` |
| List labels | `gh label list` | `glab label list` | `tea labels ls` |
| Create label | `gh label create "priority: high" --color d93f0b` | `glab label create --name "priority: high" --color "#d93f0b"` | `tea labels create --name "priority: high" --color d93f0b` |

- `glab`/`tea` act on the current repo, including **self-hosted instances** — authenticate once
  (`glab auth login --hostname gitlab.internal.example`, `tea login add --url https://forge.internal`)
  and every command below is unchanged. For `glab api`, `:fullpath` is the placeholder glab expands to
  the current project's URL-encoded path (`:id`, the numeric project ID, also works).
- `tea` has no server-side title search, so for idempotency list issues and filter by title locally;
  use the Gitea REST API via `curl` + token (`/api/v1/repos/{owner}/{repo}/…`) for anything `tea`
  doesn't expose (there is no `tea api` passthrough). Flags vary across `tea` versions — the table
  above is verified against `glab` 1.107.0 and a `tea` build reporting go-sdk v0.15.1 — note that
  `tea --version` reports an empty CLI version, so the go-sdk string is the only identifier it
  offers; confirm with `tea <command> --help` if yours differs.
- **Conceptual mapping** (informational — this skill seeds **milestones and issues only**, never
  iterations or epics): the roadmap→tracker analogues differ by forge:

  | In-repo concept | GitHub | GitLab | Forgejo/Gitea |
  |---|---|---|---|
  | Roadmap **phase** | Milestone | Milestone (or group-level **Epic**) | Milestone |
  | **Sprint** | Projects Iteration | **Iteration / Iteration Cadence** | Milestone (no native iteration) |

## Outputs

- A **Work-Organization Boundary ADR** in the project's `docs/adr/`, recording the hybrid split and
  the single source of truth.
- Either (thin default) **milestones** for open phases + **back-linked issues** for current-sprint
  deliverables, **or** a recorded deliberate decision that *"the tracker stays thin; the backlog
  remains in-repo."*
- `CLAUDE.md` note: graduation performed, canonical-source rule.

## Validation

- [ ] Team-scale trigger confirmed before any forge writes (genuinely solo → stopped). Distribution profile **not** consulted — exposure does not gate work organization
- [ ] Forge detected and the matching CLI used (`gh` / `glab` / `tea`), including self-hosted GitLab/Forgejo; only the seeding commands branch by forge, the decision logic does not
- [ ] Required labels present — created here if missing; no dependency on another plugin having run
- [ ] Label names **and colours** match the Vocabulary mapping and label-creation block exactly (bare type labels; space after `priority:`) — first writer wins, so a divergence here is permanent and silent
- [ ] Only **open** phases seeded as milestones; completed phases not re-cut
- [ ] Issues sourced from **current-sprint open deliverables**, not stale roadmap checkboxes
- [ ] Every created issue **back-links** to its roadmap phase / ADR id / sprint doc
- [ ] Internal Priority mapped onto `priority: *`; phase mapped onto milestone (not a label)
- [ ] Hybrid boundary recorded as an ADR with an explicit single source of truth
- [ ] Re-run is idempotent (no duplicate milestones/issues or labels)

## Related Skills

- `bootstrap-project` — authors the in-repo backlog this migrates *from*, and owns the tier axis whose "more than one contributor" trigger this shares
- `plan-sprint` / `wrapup-sprint` — define the sprint deliverables (issue source) and the roadmap Sprint History ledger; `wrapup-sprint` honours the single-source-of-truth boundary recorded here
- `setup-adrs` — the ADR mechanism used to record the hybrid-boundary decision
- `incoming-issue` (**project-maintenance-skills**) — operates the tracker afterward (establish → operate) and owns the full contributor-facing taxonomy; an optional enrichment for Public projects, never a prerequisite
- `public-release` (**project-maintenance-skills**) — the Private→Public gate, which invokes this skill when a graduating project also needs a contributor-facing tracker
