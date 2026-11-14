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
ok() { echo "ok    [$1] $2"; }
bad() {
  echo "FAIL  [$1] $2"
  fail=1
}
note() { echo "note  $*"; }

tier=""
public=0
for a in "$@"; do
  case "$a" in t0 | t1 | t2) tier=$a ;; --public) public=1 ;; *)
    echo "usage: $0 [t0|t1|t2] [--public]" >&2
    exit 2
    ;;
  esac
done
if [ -z "$tier" ] && [ -f CLAUDE.md ]; then
  tier=$(sed -nE 's/^Current tier: \*\*(t[012])\*\*.*/\1/p' CLAUDE.md | head -1)
fi
[ -n "$tier" ] || {
  echo "FAIL  tier unknown: pass t0|t1|t2, or state 'Current tier: **tN**' in CLAUDE.md" >&2
  exit 2
}
if [ "$public" -eq 0 ] && [ -f CLAUDE.md ] && grep -qE 'Distribution profile\*\*: *Public' CLAUDE.md; then public=1; fi
rank=${tier#t}

git rev-parse --git-dir >/dev/null 2>&1 || {
  echo "FAIL  [t0] not inside a git repository"
  exit 1
}

# ---------------------------------------------------------------- t0
if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
  if git log --format=%s | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)]+\))?!?: .+'; then
    ok t0 "at least one conventional commit"
  else bad t0 "no commit subject is a conventional commit (type(scope): subject)"; fi
else bad t0 "no commits yet"; fi

if [ ! -f CLAUDE.md ]; then
  bad t0 "CLAUDE.md is missing"
else
  if grep -qE "^Current tier: \*\*$tier\*\*" CLAUDE.md; then
    ok t0 "CLAUDE.md states 'Current tier: **$tier**'"
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
  if [ -z "$miss" ]; then
    ok t0 ".gitignore covers .env, *.pem, *.key, credentials.json, CLAUDE.local.md"
  else bad t0 ".gitignore does not ignore:$miss"; fi
else bad t0 ".gitignore is missing"; fi

# ---------------------------------------------------------------- t1
if [ "$rank" -ge 1 ]; then
  if [ -f CHANGELOG.md ] && grep -qE '^## \[Unreleased\]' CHANGELOG.md; then
    ok t1 "CHANGELOG.md has an [Unreleased] section"
  else bad t1 "CHANGELOG.md is missing or has no '## [Unreleased]' section"; fi

  for b in main develop; do
    if git show-ref --verify --quiet "refs/heads/$b"; then ok t1 "branch $b exists"; else bad t1 "branch $b does not exist"; fi
  done

  adrs="0001 0002 0003"
  if [ -f CLAUDE.md ] && grep -qE '\*\*Category\*\*: *(Infrastructure|Hybrid)' CLAUDE.md; then adrs="$adrs 0004"; fi
  for n in $adrs; do
    if compgen -G "docs/adr/$n-*.md" >/dev/null; then ok t1 "docs/adr/$n-*.md exists"; else bad t1 "docs/adr/$n-*.md is missing"; fi
  done

  if [ -f README.md ]; then
    ok t1 "README.md exists"
    # derive-don't-assert (Phase 6): a Status section states a date or a link, never a count
    st=$(awk '
      /^[#>*_ -]*[Ss]tatus[*_:]*/ && !on { on=1; n=0; print; next }
      on && /^#/ { exit }
      on { print; if (++n >= 6) exit }' README.md)
    if [ -z "$st" ]; then
      note "README.md has no Status line or section, so its status claim was not checked"
    else
      if printf '%s\n' "$st" | grep -qE '(^|[^[:alnum:]])([0-9]+|one|two|three|four|five|six|seven|eight|nine|ten) (verified |draft |open |done |complete )?(records?|concepts?|skills?|patterns?|ADRs?|tests?|rules?|checks?|bundles?|entries|files|issues|plugins?)([^[:alnum:]]|$)|[0-9]+ (of|/) ?[0-9]+'; then
        bad t1 "README.md Status quotes a count: point at the command that derives it, or state a date or a link"
      elif printf '%s\n' "$st" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}|\]\(|https?://'; then
        ok t1 "README.md Status states a date or a link"
      else bad t1 "README.md Status states neither a date nor a link"; fi
    fi
    if grep -qE '[0-9]+ (of|/) ?[0-9]+ (complete|done|passing|verified)' README.md; then
      bad t1 "README.md carries an 'N of M complete' progress claim: derive it or drop it"
    fi
    # one source of truth for the short description: the manifest's, at most 120 characters, verbatim in the README
    # (line wraps, [text](url) markup and a trailing full stop are not rewording)
    desc=""
    for m in pyproject.toml Cargo.toml; do
      [ -f "$m" ] && desc=$(sed -nE 's/^description *= *"(.*)"[[:space:]]*$/\1/p' "$m" | head -1) && [ -n "$desc" ] && break
    done
    if [ -z "$desc" ] && [ -f package.json ]; then desc=$(sed -nE 's/^ *"description": *"(.*)",?[[:space:]]*$/\1/p' package.json | head -1); fi
    if [ -z "$desc" ]; then
      note "no manifest description (pyproject.toml, Cargo.toml, package.json), so the README short description was not matched"
    elif [ "${#desc}" -gt 120 ]; then
      bad t1 "manifest description is ${#desc} characters; the short description is at most 120"
    elif tr '\n' ' ' <README.md | sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g; s/  +/ /g' | grep -qF -- "${desc%.}"; then
      ok t1 "README.md carries the manifest description verbatim (${#desc} characters)"
    else bad t1 "README.md does not carry the manifest description verbatim: one source, copied, not reworded"; fi
  else bad t1 "README.md is missing"; fi

  cfg=""
  for c in lefthook.yml lefthook.yaml .lefthook.yml .pre-commit-config.yaml; do [ -f "$c" ] && cfg=$c && break; done
  if [ -z "$cfg" ]; then
    bad t1 "no hook manager config (lefthook.yml or .pre-commit-config.yaml)"
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
  if [ -f CLAUDE.md ] && grep -qE '^## Current Development Status' CLAUDE.md; then
    ok t2 "CLAUDE.md has '## Current Development Status'"
  else bad t2 "CLAUDE.md has no '## Current Development Status' section"; fi
  note "architecture/workspace.dsl exists, not proven to validate: run the Structurizr validate for your container runtime"
fi

# ---------------------------------------------------------------- Public profile
if [ "$public" -eq 1 ]; then
  if [ ! -f SECURITY.md ]; then
    bad public "SECURITY.md is missing"
  else
    if grep -qE '^## Reporting a Vulnerability' SECURITY.md; then
      ok public "SECURITY.md has '## Reporting a Vulnerability'"
    else
      bad public "SECURITY.md has no '## Reporting a Vulnerability' section"
    fi
    if grep -qE 'security/advisories/new|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+' SECURITY.md; then
      ok public "SECURITY.md names a private reporting channel"
    else bad public "SECURITY.md names no private channel (a security/advisories/new link or an email address)"; fi
    scope=$(awk '/^## Scope/{f=1;next} /^## /{f=0} f' SECURITY.md)
    if [ -z "$scope" ]; then
      bad public "SECURITY.md has no '## Scope' section"
    elif printf '%s' "$scope" | grep -qE '\[Author-filled|\{[a-z-]+\}|\[N business days\]'; then
      bad public "SECURITY.md Scope is still the template placeholder"
    elif [ "$(printf '%s' "$scope" | wc -w | tr -d ' ')" -lt 20 ]; then
      bad public "SECURITY.md Scope is under 20 words — not a threat model"
    else ok public "SECURITY.md Scope is filled in"; fi
    if grep -qE '\{[a-z-]+\}|\[N business days\]' SECURITY.md; then bad public "SECURITY.md still has template placeholders ({owner}, [N business days], ...)"; fi
  fi
  if [ -f CLAUDE.md ] && grep -qE 'Distribution profile\*\*:' CLAUDE.md; then
    ok public "CLAUDE.md records the distribution profile"
  else bad public "CLAUDE.md ## Project Context does not record the distribution profile"; fi
  note "private vulnerability reporting must be on: gh api repos/{owner}/{repo}/private-vulnerability-reporting --jq .enabled   # -> true"
fi

# ---------------------------------------------------------------- GitHub remote
if git remote -v | grep -q 'github\.com'; then
  if [ -f .github/dependabot.yml ] || [ -f .github/dependabot.yaml ]; then
    ok remote ".github/dependabot.yml exists"
  else bad remote "a github.com remote exists but .github/dependabot.yml does not"; fi
fi

exit "$fail"
