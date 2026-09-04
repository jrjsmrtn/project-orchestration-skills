# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
During development the patch level is bumped per change (`0.1.x`).

## [Unreleased]

### Fixed

- **The `gitleaks` gate failed open.** When `gitleaks` was not on `PATH` the hook printed
  `secret scan SKIPPED` and exited 0, so a machine without it committed unscanned — and the scan a
  person believes is running is what makes it safe to stage a file without reading it. It now
  blocks the commit. Verified by hiding `gitleaks` from `PATH`: the hook exits 1 where it
  previously exited 0. One of thirteen repositories carrying the same copied guard; the
  fail-closed pattern already existed in `macports-scripts` and had never propagated.

## [0.1.34] - 2026-08-10

**A repository with three remotes ran its pre-push gates on two of them and reported a
clean summary for the third.** lint, format and 284 test assertions on `origin` and
`github`; on `gitlab`, three `(skip) no matching push files` lines and a green tick.

### Added

- **`setup-git-hooks`** — *lefthook: pre-push gates belong in `scripts:`, not `commands:`*.
  lefthook derives the pre-push file set from **`@{push}`**, which git resolves per *branch*
  and not per *remote*, so the first push advances it and every later remote computes an
  empty diff. Git hands the hook the correct remote refs on stdin; lefthook does not use
  them. `scripts:` are not subject to the skip.

  Two non-fixes are recorded so they are not retried: **`skip_empty:` is not a recognised
  key** in lefthook 2.1.10 — setting it changes nothing, silently — and a `files:` override
  is consulted after the skip is already decided.

  Includes a four-command reproduction (two bare remotes, an upstream, push twice) because
  the failure is invisible in a summary: the gate that did nothing looks exactly like the
  gate that passed.

### Changed

- All four lefthook `pre-push` examples now carry a *SINGLE-REMOTE SHAPE* annotation
  pointing at the finding, so the examples do not quietly contradict it.

### Notes

- **Scoping pre-push gates to changed files was never buying anything.** A full test run, a
  type check and a dependency audit are whole-repo checks; the `glob:` was costing
  correctness for no benefit. `glob:` stays right for **pre-commit** `commands:`, where
  staged-file scoping is the point.
- **lefthook only.** The `pre-commit` framework runs `stages: [pre-push]` hooks per
  invocation and does not derive files from `@{push}`.

## [0.1.33] - 2026-08-10

**An agent signed a DCO attestation in a maintainer's name, and the skills that stand up
projects said nothing against it.** A `commit-msg` hook rejected a commit for a missing
`Signed-off-by:`; the agent reached for `git commit -s`, which satisfied the hook and
asserted, in the maintainer's name, a legal certification of the right to submit. Caught
before any push. The gap was that every rule about this lived in `CONTRIBUTING.md` — a
file an agent may never open — while the file an agent actually loads said nothing.

### Added

- **`setup-git-hooks`** — *A DCO sign-off hook is not an agent's to satisfy*. A hook
  rejecting a missing sign-off is asking a **person** to certify, not asking a tool for a
  formatting fix; the instruction is to hand the work back unsigned rather than route
  around it. Carries the distinction that makes the rule usable: `Co-Authored-By:` and
  `Assisted-by:` record assistance and assert no right to submit, so an agent may add
  those freely. Also says to write the rule into the project's `CLAUDE.md` and not only
  into `CONTRIBUTING.md`, since the two audiences read different files.
- **`bootstrap-project`** — the generated `CLAUDE.md` template now carries *Attestations
  are never delegated*, so a project bootstrapped today starts with the rule in the file
  an agent loads. Generalised beyond the DCO: a CLA, a release approval, a published
  provenance statement.

### Notes

- `analyze-project` already reasoned about this from the other direction — it warns that
  `Co-developed-by:` is structurally invalid for a tool because the Linux kernel requires
  a matching `Signed-off-by:` "which the same project forbids an AI agent from adding".
  The concept was present for *evaluating* an upstream and absent for *setting up* a
  project; the three skills now agree.
- **The hook still cannot tell a human from an agent.** This ships as an instruction, not
  an assertion, and says so. A real guard compares committer against signer, or refuses
  when an agent environment marker is present.

## [0.1.32] - 2026-08-05

**The comment rules were checked against a source, and the source won on three counts.** 0.1.31
shipped them marked house-derived with a standing instruction that a contradicting source wins. One
was read — [A Philosophy of Software Design vs Clean Code](https://github.com/johnousterhout/aposd-vs-clean-code/blob/main/README.md),
a recorded exchange between **John Ousterhout** and **Robert C. Martin**, published by Ousterhout —
and it contradicted three.

### Fixed

- **A whole category was missing.** The section covered only *implementation* comments without
  saying so. Ousterhout's **first** reason for comments is **abstraction**: *"without comments there
  is no way to have abstraction or modularity… It should be possible to use a method without reading
  its code. The way we achieve this is by writing a header comment that describes the method's
  interface."* The original test — *would deleting this let someone reintroduce a bug* — would have
  deleted interface documentation wholesale, since an interface comment prevents **misuse** rather
  than a specific bug
- **"The code shows what, comments carry why" is too narrow.** The rule is *not obvious from the
  code*, which includes non-obvious **what** — an algorithm's mechanism can need explaining even
  when nobody asks why it exists. The why-not-what phrasing is the popular formulation, not the
  precise one
- **The disagreement is now shown rather than settled silently.** *Clean Code* holds comments are
  *"always failures"*; Ousterhout calls that stigmatising and predicts juniors will read it as "write
  no comments"; Martin replies he is hostile to *gratuitous* comments rather than to comments. They
  close: *"we struggled to find areas of agreement on this topic."* Ousterhout would write **5–10×
  more comment lines** than Martin for the same code
  - Where they **agree** is marked settled — *implementation comments only when the code is
    nonobvious* — which was the one original rule the sources support outright
  - Where they disagree, the instruction is to choose per project **and say which you chose**. This
    section now sits **nearer Martin on implementation, nearer Ousterhout on interfaces**, stated as
    a position rather than inherited

### Notes

**Still unread, recorded as such**: the book itself (not obtainable here — the extract PDF is
image-only) and Naur's *Programming as Theory Building*. The standing instruction holds: a
contradicting source wins.

## [0.1.31] - 2026-08-05

**Content conventions for the three artifacts Conventional Commits does not reach.** The spec
governs commit *grammar* — `type(scope)!: description`, footers as git trailers — and its Rule 7
makes the body *"free-form"*. That is a vacuum, and `bootstrap-project` cited the spec without
filling it.

### Added

- **Commit message content rules**, tier-scaled so a solo t0 project is not handed a five-rule
  policy. Subject says what changed, body says *why* or there is no body; **a message must not claim
  more than the commit contains**; and record what cannot be recovered from the tree
  - Rule 2 leads because a wrong message is worse than a thin one — a thin message is unhelpful, a
    wrong one is a false record in the exact place people look when the code stops explaining itself.
    **The risk is highest when the message is generated**, since fluent prose about an intended
    change reads identically whether or not the change landed
- **`setup-git-hooks`: a `commit-msg` check** for the mechanical half — fails when the message names
  a **backticked** path that exists but is not staged. Scoped narrowly to keep false positives near
  zero, shipped with its planted-bad self-test, and explicit about what it does *not* catch
- **Code comment content rules.** One test rather than a style list: *would deleting this comment let
  someone reintroduce a bug, or repeat an approach already rejected?* A wrong comment is worse than a
  missing one, because it is trusted while absent code is read
- **README content rules.** The one that matters: **a README must not assert a number a command can
  derive.** A bundle README read *"Status: skeleton. One verified record"* while the bundle held
  fifteen — true when written, unvalidated, wrong for as long as nobody looked

### Fixed

- **A misattribution to Diátaxis.** The README section claimed *"under Diátaxis it is none of the
  four modes"*. **Diátaxis says nothing about READMEs at all** (checked 2026-08-05). The router
  framing is an inference from this portfolio's practice and is now labelled as one
- **Missing provenance on both new sections.** Each shipped as established practice while grounded
  entirely in one portfolio, one author, one day
  - README gains real references — [Standard Readme](https://github.com/RichardLitt/standard-readme/blob/main/spec.md)
    (required sections, 120-character description matching the repo and package-manager fields) and
    [Make a README](https://www.makeareadme.com/). Standard Readme's matching-description rule is the
    same *one source of truth, restated nowhere* instinct as derive-don't-assert, reached
    independently
  - A tension is stated rather than hidden: Make a README holds *"too long is better than too
    short"*, which pulls against the tiering here
  - Code comments are marked **house-derived in full**, with Ousterhout, Naur and Martin named as
    further reading and **explicitly not as support** — and a standing instruction that if any of
    them contradicts a rule, the source wins

## [0.1.30] - 2026-08-05

### Changed

- **`analyze-project`: the AI-contribution-policy check is now findable and shaped.** It said "read
  `CONTRIBUTING`", which is where the check usually stops and not where the policy usually lives.
  Reading fifteen projects' actual policies found it in **five** places: a dedicated policy or
  in-tree process doc (Linux kernel, QEMU), the **Code of Conduct** (Zig — where a violation is
  *misconduct*, not a rejected patch), the contribution guide's own AI section (Git, Ansible,
  Python), the **security page** (curl, where disclosure is mandatory for AI-found vulnerabilities),
  and the project's **foundation** (Linux Foundation, Apache, OpenInfra — which are *floors* a
  project may exceed, so checking only the foundation is a reliable way to be wrong about the
  project)
- **It now asks for the shape, not the verdict.** "Banned or allowed?" produces wrong answers: most
  restrictive policies carry a route, and the route is the operative part. Gentoo's ban is
  revisitable, NetBSD's is a rebuttable presumption with a named approver, QEMU runs a documented
  exceptions process, Rust's draft requires a pre-arranged reviewer — all filed as "complete ban" by
  the summary this replaced
- **The CLA warning names its mechanism.** Previously "may be a hard stop for some contributors or
  employers"; now **ICLA §4**, the employer representation — and the operational conclusion that
  follows, which is to start it *before writing code*. A DCO problem is fixable by amending a
  commit; a §4 problem may not be yours to fix at all, since it needs your employer's signature

### Added

- **A warning against `Co-developed-by:` for AI attribution.** Widely recommended before project
  policies landed, and structurally invalid for a tool: it denotes *authorship*, so the Linux kernel
  requires each one be immediately followed by a `Signed-off-by:` from that co-author — which the
  same project's policy forbids an AI agent from adding. The trailer demands a sign-off no tool may
  give
- **A citation to [`ai-contribution-policies`](https://github.com/jrjsmrtn/ai-contribution-policies)**
  — sourced per-organisation records with per-record expiry, published 2026-08-05. Framed as *what to
  look for*, not as an answer: the bundle is curated rather than exhaustive, and a record past its
  `stale_after` is a prompt to re-read the source

## [0.1.29] - 2026-08-03

### Changed

- **BREAKING: `setup-pre-commit` renamed to `setup-git-hooks`** (workspace ADR-0013). Invoke
  `setup-git-hooks` from now on.

  A **deprecation stub remains at the old name until 0.2.0**, carrying no procedure — only a pointer
  to the new one. The skill, plugin and marketplace manifests provide no rename, alias or redirect
  field (verified across all three), so content-level deprecation is the only graceful path the
  format offers, and it is what the official guidance prescribes.

  The old name was wrong on two axes at once. It named **one of the two stages** the skill sets up:
  the skill's thesis is the two-stage split (fast pre-commit, thorough pre-push), and pre-push is
  roughly a third of its content, carrying the checks that catch the expensive defects. And it named
  **one of the two supported hook managers**, when the skill already documents both — Step 4
  (Install Hook Framework) mentions `lefthook` more often than `pre-commit`, and Steps 1, 2, 3 and 7
  (138 lines of `.editorconfig`, secret-detection architecture, `.gitignore` hardening and
  multi-remote protection) mention neither.

  Roughly half the skill is manager-neutral. The practical effect of the old name was that a
  maintainer on an Elixir, Go or Rust project read "pre-commit", correctly inferred "that is the
  Python hook framework", and never reached the content that had nothing to do with it — the same
  failure as ADR-0008's `oss-maintenance` install boundary, one level down.

  **Splitting into `setup-pre-commit` + `setup-lefthook` was considered and rejected**: it would
  duplicate ~340 lines of manager-neutral content, and the manager-specific depth now lives in two
  sibling how-to guides in the pattern-language repo instead.

- Description now states the full scope: two-stage git hooks, either manager.
- Plugin keyword `pre-commit` → `git-hooks`; `lefthook` added.
- Cross-references updated in `bootstrap-project`, `setup-adrs`, `setup-container-security`,
  `validate-quality-config`, `harden-github-actions` and `harden-gitlab-ci`, plus `README.md` and
  `CLAUDE.md`. Historical CHANGELOG entries keep the old name deliberately — they record what
  shipped at the time.

## [0.1.28] - 2026-08-02

Workspace **Sprint 2 — Inception & Establishment** (roadmap H11; the po half — H24 shipped the new
`workspace-skills` plugin separately).

### Added

- `analyze-project` — **upstream acceptance criteria at inception** (H11). SPARK's Analysis phase
  modelled dependencies you *consume* but had no place for obligations you must *satisfy* to be
  *accepted* by a third party. Phase 3 gains an **Upstream Acceptance** subsection (when viability
  rests on an external party accepting a contribution, model what they require *of you* — DCO vs CLA,
  AI-contribution policy, inbound licence compatibility, governance/responsiveness — answerable before
  any code), and Phase 5 an **Upstream Acceptance Gaps** category (obligations to satisfy, distinct
  from build-knowledge gaps). Grounded in a real case: a distribution strategy resting on an upstream
  cataloger contribution analysed whether the upstream would *want* it but never what it *required of
  a contributor* — DCO sign-off and an (absent) AI-policy found only after the code was written.

## [0.1.27] - 2026-08-01

Workspace **Sprint 1 — Release & CI-Publishing Integrity** (roadmap H13, H14, H20, H21, H22): five
defects in the release/CI-publishing path, all surfaced by *exercising* `ansible-bom`'s first real
release rather than by reading the skills. Every claim verified against the installed tool
(cosign 3.1.1, syft 1.36.0) or the vendor docs, not asserted.

### Added

- `harden-github-actions` **Step 7b — private-repository matrix** (H13): three controls behave
  differently while a repo is private, for two distinct reasons. *Cannot run:* OpenSSF Scorecard
  (`Resource not accessible by integration`; the PAT workaround is a long-lived secret to grade an
  unpublishable repo) and dependency-review (needs GitHub Advanced Security). *Should not run:*
  keyless cosign/SLSA — they work, but Sigstore writes the repo name + workflow path to the **public
  Rekor transparency log**, publishing exactly what privacy protects. Fix is the reusable
  `if: ${{ !github.event.repository.private }}` gate so controls **self-activate at the public gate**.
- `harden-github-actions` / `bootstrap-project` — **Scorecard grades the default branch** note (H22).
  Scorecard's content analysis runs on the default branch, which gitflow makes `develop`, so the
  published score describes the integration branch, not the `main` releases are cut from. Verified
  against the Scorecard docs: the `Branch-Protection` check *does* also cover release branches, the
  content-analysis checks do not — so the note is precise, with the two honest resolutions.

### Fixed

- `wrapup-sprint` / (`supply-chain` in project-maintenance-skills) — **verify signatures back as a
  release gate** (H20). The guidance produced a signature but never verified it, so a signature no
  consumer could verify would ship silently. Every path now verifies in the release run
  (`cosign verify` by digest / `slsa-verifier` / `cosign verify-blob --bundle`). Also documents the
  **cosign v3 bundle** form for blob signing — the removed v2 `--output-signature`/`--output-certificate`
  flags now fail with `create bundle file: open :`. (Premise corrected: the broken v2 flags were never
  in the skills; the image path uses `cosign sign`, unbroken in v3.)
- `wrapup-sprint` / `harden-github-actions` — **release-job ordering** (H21). `slsa-github-generator`
  with `upload-assets: true` *creates* the release when absent, so `provenance: needs: [build]` races
  the publish job and often wins, producing a bare, notesless release (mirror failure: `release not
  found`). Fixed to an idempotent `publish` job + `provenance: needs: [build, publish]`; the ordering
  now travels with the copy-paste source in Step 7.
- `wrapup-sprint` / (`supply-chain`) — **SBOM must catalogue the built artifact, not the source tree**
  (H14). Scanning the repo dir yields `pkg:github/*` and no ecosystem/stdlib packages (what stdlib
  advisories match on); scan the binary/image/wheel instead. Adds a **runnable** CI subject assertion
  (fail on any `pkg:github`; require stdlib for compiled langs), tested end-to-end with syft + jq.

## [0.1.26] - 2026-07-31

### Added

- **Toolchain versions are now a first-class quality-configuration concern** (roadmap H12), split
  across the two skills that own the two halves of it:
  - `setup-pre-commit` — the Step 0 `quality-configuration.md` template gains a **Toolchain
    Versions** section: a three-role table (**Floor** = oldest runtime a consumer needs, from the
    language manifest; **Build** = what CI actually builds with; **Inherited** = a floor a
    dependency forces on you, not a choice), a per-ecosystem floor-vs-build table (Go, Rust,
    Python, Node, Elixir), and four rules — build with the current version and never the floor,
    prove the floor in a separate job, record the intent **per call site**, and record the
    maintenance obligation. Its Validation Checklist is now runnable commands rather than prose
    bullets, per workspace ADR-0009 (prefer a check that fails over a paragraph that instructs).
  - `validate-quality-config` — new **Step 6: Validate Toolchain Floor vs Build Version**. Every
    other check in that skill asserts two values *agree*; this one asserts they *differ*, which is
    why it is easy to omit. It reports an error when CI builds at the declared floor, and warns on
    `*-version-file` call sites outside the floor-compatibility job, on a floor nothing tests, and
    on moving aliases (`stable`, `latest`). The error case is also wired into the skill's
    automated validation script.

  Drawn from a real failure: lowering a Go module's floor to widen compatibility silently moved
  *every* build onto it, so release binaries were built against a standard library carrying two
  known advisories — and the accompanying SBOM recorded that fact. A targeted fix then missed two
  of the five workflows, because nothing recorded what each call site was supposed to read.

## [0.1.25] - 2026-07-16

### Fixed

- `graduate-backlog` review pass (`skill-reviewer` gate). It had been rewritten and moved between
  plugins without a fresh review; the gate found real defects:
  - **Silent permanent label divergence**: the three `priority: *` colours did not match
    `incoming-issue`'s taxonomy — and each collided with a *different* label in it
    (`priority: high`→`b60205` is **`priority: critical`**; `priority: medium`→`fbca04` is
    **`needs-info`**; `priority: low`→`0e8a16` is **`confirmed`**). Because label creation is
    `|| true`-idempotent, **first writer wins**: graduate first and the wrong colours would survive
    forever with no error, producing exactly the two-vocabularies outcome the skill claims to
    prevent. Aligned to `d93f0b`/`e4e669`/`c2e0c6`, in both the Phase 5 block and the Forge Command
    Reference, with a note that the colours are contract rather than decoration.
  - **First run would fail**: Phase 5 created labels *after* the `gh issue create` that applies
    them. Split into Step 1 (create labels) → Step 2 (seed issues).
  - **Self-contradiction**: Phase 1 said "do *not* check the distribution profile" and then made
    "the project is **Public**" an eligibility clause — re-coupling the trigger to the exact axis
    the move was meant to sever, and making a Validation item untickable. Restated exposure-free.
  - **`full` could not satisfy the skill's own Validation**: it ran Phases 2/4/5, omitting Phase 3
    (the boundary ADR — the headline Output) and Phase 6 (anti-drift). Now Phases 1–6.
  - **`roadmap-visible` was advertised but unimplemented** — selecting it silently gave `thin`
    behaviour. Implemented as Phase 5b (mirror open phases as pointer issues), keeping the richer
    path the thin-hybrid decision record requires.
  - Workspace ADRs were cited by bare number, which would resolve against the *consumer's* own
    `docs/adr/` — the sequence this skill writes into. Now cited by title.
  - Validation no longer makes a skill from another plugin the authority for a self-contained check.

## [0.1.24] - 2026-07-16

### Fixed

- `harden-gitlab-ci` review pass (`skill-reviewer` gate). Substantive fixes:
  - **Security gap**: Phase 3 asserted that `CI_JOB_TOKEN` "reaches only its own project" by default
    and never checked whether that default still holds. A project can be set to **"All groups and
    projects"**, where — in GitLab's words — "jobs from any project can access your project with a
    job token". That is the worst case *and* the one with no allowlist to audit. Confirming the
    access mode is now the first step of the phase, before any entry review.
  - **`audit` was advisory, not actionable**: the default scope had no executable detection. Added
    tested `grep` patterns for moving-target components, `include: project` without a pinned `ref:`,
    remote includes, undigested images/services, deprecated `CI_JOB_JWT*`, and `privileged`/`shell`
    runners.
  - **`fix` couldn't do what it promised**: no way to resolve a component/template tag → SHA. Added
    `glab api ".../repository/commits/<tag>" --jq '.id'` (the API's `:sha` accepts a branch or tag
    name), plus a `git ls-remote` fallback.
  - `--hidden` variables: documented the create-only constraint ("you cannot update an existing
    variable to be hidden") — making one hidden means recreating it, i.e. rotating the secret.
  - `glab ci lint` defaults to `.gitlab-ci.yml` in the *current directory*, which contradicted the
    skill's own note that the config may be relocated; now says to `cd` or pass the path.
  - Split the malformed BAD/GOOD image block (it was one line, so copy-paste produced invalid YAML);
    kept the tag alongside the digest; extended pinning to `services:`.
  - Added the missing **project visibility** input (Phases 3 and 4 branch on it), a `setup-adrs`
    pointer for the decisions this surfaces, an Outputs checklist per house convention, and doc-page
    citations for the two quoted GitLab passages.

## [0.1.23] - 2026-07-16

### Added

- New skill **`harden-gitlab-ci`** (workspace roadmap H8) — GitLab CI/CD supply-chain hardening:
  SHA-pinned `include:`/CI-Catalog components, `CI_JOB_TOKEN` allowlist scoping, masked **and**
  protected variables, digest-pinned job images, `id_tokens`/OIDC in place of long-lived secrets,
  and runner-trust checks (`privileged`, `shell` executor). Works on gitlab.com and self-hosted
  alike. Plugin roster 11 → 12 skills.
- `harden-gitlab-ci` is a **sibling** of `harden-github-actions`, not a translation: it builds
  GitLab's *equivalent* controls rather than transliterating GitHub's, because the risks differ in
  kind. Notably GitLab's `CI_JOB_TOKEN` defaults to own-project-only, so the work is *keeping* it
  scoped — the opposite posture from GitHub's repo-wide-by-default `GITHUB_TOKEN`.
- po's `CLAUDE.md` now records the `harden-*` family as the sanctioned exception to
  forge-agnosticism: one skill per forge, named for its coupling, closed at 3 (Forgejo is H9).

### Fixed

- `harden-github-actions` claimed GitLab has "no marketplace-action supply chain". **That is false**
  — GitLab has a **CI/CD Catalog** of components, whose own docs say to "Pin CI/CD components to a
  specific commit SHA (preferred)". The claim was a plausible assumption written without checking;
  it is corrected, and the same-class risk is now handled in `harden-gitlab-ci` Phase 2.

## [0.1.22] - 2026-07-16

### Changed

- **Renamed `harden-ci-workflows` → `harden-github-actions`** (workspace roadmap H7). The skill was
  GitHub-Actions-specific by definition while living in a plugin that the workspace decision record
  "Plugin Taxonomy by Lifecycle, Not Exposure" affirms is forge-agnostic — the last known violation
  of that invariant. Renaming owns the coupling
  rather than hiding it: its controls are properties of the GitHub Actions execution model (actions
  resolved by mutable git ref, an ambient repo-scoped `GITHUB_TOKEN`, OIDC-backed SLSA provenance),
  not portable concepts wearing GitHub syntax. GitLab CI and Forgejo Actions need different
  controls, not a translation, and are declared explicitly out of scope.
- `harden-github-actions` is now the **one sanctioned forge-bound exception** in this plugin,
  recorded in `CLAUDE.md`; a second exception should require an ADR. The remaining lesser coupling
  (`bootstrap-project` writing `.github/dependabot.yml`, `wrapup-sprint` calling `gh api repos`) is
  noted as unsanctioned and to be fixed when touched.
- Cross-references updated in `bootstrap-project`, `setup-pre-commit`, `setup-container-security`,
  `wrapup-sprint`, README, and CLAUDE.md.

### Breaking

- The skill's invocation name changes: `/harden-ci-workflows` → `/harden-github-actions`. Update any
  scripts, docs, or muscle memory that reference the old name. The old name is not aliased.

## [0.1.21] - 2026-07-16

### Added

- New skill **`graduate-backlog`** (moved from `oss-maintenance`, now `project-maintenance-skills` —
  workspace ADR-0008 + ADR-0007 amendment). Graduates an in-repo backlog (roadmap phases, sprint
  deliverables, ADRs) onto a forge issue tracker at a **thin-hybrid** default: milestones from open
  phases, back-linked issues from current-sprint deliverables, and a recorded Work-Organization
  Boundary ADR naming the single source of truth. Works on GitHub (`gh`), GitLab (`glab`), and
  Forgejo/Gitea (`tea`), including **self-hosted/internal instances**. Plugin roster 10 → 11 skills.
- `graduate-backlog` creates the minimal `enhancement`/`bug`/`documentation` + `priority: *` labels
  it needs, so it works standalone. `incoming-issue` (project-maintenance-skills) becomes an
  optional enrichment for Public projects rather than a hard prerequisite.

### Changed

- **`graduate-backlog`'s trigger is decoupled from the Public distribution profile.** Graduation is
  driven by **team scale** — the same signal as the t0→t1 tier bump ("more than one contributor") —
  not by exposure. The old `Not for: Private projects` refusal is removed: a corporate team on an
  internal GitLab needs a board without ever open-sourcing. Exposure gates *compliance controls*,
  not *work organization* (ADR-0006).
- `wrapup-sprint` Step 7 and `bootstrap-project`'s roadmap "Tracker Boundary" template now reference
  `graduate-backlog` within this plugin rather than reaching into the maintenance plugin, resolving
  a dependency inversion: this plugin owned the tracker-boundary rule while the skill establishing
  it lived a layer up.
- `bootstrap-project`: `oss-maintenance` references renamed to `project-maintenance-skills`.

### Fixed

- `graduate-backlog`'s Forge Command Reference verified against the installed CLIs (`glab` 1.107.0,
  `tea` go-sdk v0.15.1) rather than asserted — the `tea` guidance was previously hedged because the
  binary wasn't available when it was written. Added verified `label list`/`label create` rows for
  all three forges.

### Changed

- `setup-container-security`: reframed the containerization stance from "Podman-first,
  Docker-compatible" to **OCI-compliant first** — target the OCI image spec so the artifact
  runs on any conformant runtime; build/test distributables with podman, stay Docker-compatible.
- `setup-architecture-as-code`: normalised the Structurizr `inspect` severity flag `-severity` →
  `-s`/`--severity` in the `inspect-architecture` Makefile target (matches the verified vNext CLI,
  `structurizr v2026.03.06`).

## [0.1.19] - 2026-07-10

### Fixed

- Portfolio-review quality pass across all 10 skills: replaced broken workspace-relative
  `../../../docs/patterns/…` links with absolute upstream GitHub URLs; corrected the Structurizr CLI
  flag `-workspace` → `-w` and mounted the project root with `:z` for both `validate` and the `local`
  viewer (`setup-architecture-as-code`); fixed the `set -e` + `((errors++))` counter in
  `validate-quality-config` and added Required Inputs / Validation sections; pointed `setup-adrs`
  validation at `docs/adr/index.yml` (not `README.md`); added the correct `gh`
  private-vulnerability-reporting check; glossed author-internal jargon for portability.

## [0.1.18] - 2026-07-10

### Fixed

- `wrapup-sprint`: reference the tracker-boundary decision by its real ADR title
  ("Work-Organization Boundary") so it resolves in `docs/adr/`.

## [0.1.17] - 2026-07-10

### Added

- Work-organization **tracker boundary** (single source of truth for tactical status): `wrapup-sprint`
  Step 7 honours a public forge tracker as canonical for per-issue/milestone status once a project has
  graduated its backlog, keeping the roadmap Sprint History as the narrative/version ledger;
  `bootstrap-project`'s roadmap template gains a "Tracker Boundary" section.

## [0.1.16] - 2026-07-10

### Changed

- README skill roster synced to the full 10 skills — added `harden-ci-workflows` and
  `setup-container-security` to the skill tables and the slash-command list.

## [0.1.15] - 2026-07-04

### Added

- `setup-adrs`: Third-Party / Aggregate Licensing guidance and a `LICENSING.md` template —
  per-component SPDX table, copyleft-floor identification (static-linking a GPL-3.0 library, or
  an AGPL-only container component), and obligations mapped to usage mode (self-host / redistribute
  / SaaS), with an accompanying ADR.
- `validate-quality-config`: Step 6 version-consistency check — the declared version must agree
  across the package manifest, README, CHANGELOG, and `SECURITY.md`.

## [0.1.14] - 2026-07-04

### Added

- `setup-pre-commit`: lockfile + frozen-install enforcement (uv/mix/cargo/npm) with a check for
  lower-bound-only manifests missing a lockfile; and a Public-profile REUSE license-compliance
  gate — `REUSE.toml` + `LICENSES/` + `reuse lint` as a git hook and a CI job.
- `bootstrap-project`: Phase 10 generates a multi-ecosystem `.github/dependabot.yml`
  (package manager + `github-actions` + `docker`). Config generation only — PR triage stays with
  the `oss-maintenance` workflow.

### Changed

- `setup-adrs`: ADR-0002 §11 (Licensing) now points at enforced `reuse lint` (hook + CI) and marks
  licensing a Public-profile control, rather than prescribing REUSE abstractly.

## [0.1.13] - 2026-07-04

### Added

- New skill `setup-container-security`: harden container images — digest-pinned bases
  (multi-arch index + skopeo bump procedure), minimal/multi-stage builds, non-root
  runtime, sha256-verified artifact fetches, `.dockerignore`, hadolint/shellcheck,
  grype (fixable-only `.grype.yaml` policy) + syft SBOM, `HEALTHCHECK`, and Dependabot
  digest bumps. `ships-artifacts` publishing (SBOM release asset + cosign) delegates to
  `wrapup-sprint`.

## [0.1.12] - 2026-07-04

### Added

- `wrapup-sprint`: profile-gated release-provenance step for `ships-artifacts` projects —
  SBOM (syft, SPDX + CycloneDX), SLSA provenance for binary/tarball releases
  (slsa-github-generator + a slsa-verifier consumer guide), and cosign keyless signing for
  container images. Presented per artifact type, aligned with SLSA / EU CRA / EEF Ægis.

## [0.1.11] - 2026-07-04

### Added

- `bootstrap-project`: distribution-profile axis (**Private**/**Public** plus a
  `ships-artifacts` marker), orthogonal to the t0/t1/t2 tiers, so compliance controls
  attach by exposure rather than process maturity.
- `bootstrap-project` Phase 9: profile-gated `SECURITY.md` scaffold at the **Public**
  profile — coordinated disclosure, supported-versions, and a project-specific Scope,
  aligned with the OpenSSF Scorecard `Security-Policy` check and EU CRA steward duties.
- Community health files: `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and
  this changelog.

## [0.1.10] - 2026-07-04

### Changed

- `setup-pre-commit`: hardened dependency auditing — documented the `:mix_audit`
  prerequisite for `mix deps.audit`, fixed config parity across the pre-commit-framework
  and multi-language configs, added CVE-vs-retirement guidance, a CI enforcement job with
  a scheduled re-run, and OpenSSF / EEF Ægis grounding.

## [0.1.9] - 2026-07-04

### Added

- New skill `harden-ci-workflows`: GitHub Actions CI/CD supply-chain hardening — SHA-pin
  actions (with the SLSA-generator tag exception), least-privilege token permissions,
  verified toolchain installs, OpenSSF Scorecard, and SLSA provenance.

---

Releases prior to this changelog are recorded in the repository's git history.
Run `git tag --sort=-creatordate` to list tagged versions.
