#!/usr/bin/env bash
# scripts/check-dco.sh
# DCO gate for incoming changes: every non-merge commit in BASE..HEAD must carry a
# `Signed-off-by:` trailer whose email matches the commit author's.
#   usage: scripts/check-dco.sh BASE [HEAD]            e.g.  check-dco.sh origin/main HEAD
# Exit: 0 all signed | 1 unsigned or mismatched | 2 could not run (unresolvable range)
# Contributors run none of the maintainer's hooks, so this is the enforcement point for PRs.
# Merge commits are exempt: a merge certifies nothing about the merged work's authorship.
set -u
BASE="${1:-}"
HEAD_REF="${2:-HEAD}"
[ -n "$BASE" ] || {
  echo "usage: $0 BASE [HEAD]" >&2
  exit 2
}

# An unresolvable base would yield zero commits and look like success — so it is an error.
git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null \
  || {
    echo "FAIL: cannot resolve '$BASE' (shallow clone? needs fetch-depth: 0) — DCO NOT checked" >&2
    exit 2
  }
git rev-parse --verify --quiet "$HEAD_REF^{commit}" >/dev/null \
  || {
    echo "FAIL: cannot resolve '$HEAD_REF' — DCO NOT checked" >&2
    exit 2
  }

commits=$(git rev-list --no-merges "$BASE..$HEAD_REF")
[ -n "$commits" ] || {
  echo "DCO: no non-merge commits in $BASE..$HEAD_REF — nothing to check"
  exit 0
}

n=0 bad=0
while IFS= read -r sha; do
  [ -n "$sha" ] || continue
  n=$((n + 1))
  author=$(git log -1 --format='%ae' "$sha")
  subject=$(git log -1 --format='%s' "$sha")
  signers=$(git log -1 --format='%(trailers:key=Signed-off-by,valueonly)' "$sha")
  if [ -z "$signers" ]; then
    echo "FAIL $(git rev-parse --short "$sha")  no Signed-off-by — $subject"
    bad=$((bad + 1))
    continue
  fi
  # Bots still need the trailer but are exempt from the author match: Dependabot signs as
  # `dependabot[bot] <support@github.com>` and authors as `…+dependabot[bot]@users.noreply.github.com`,
  # so a strict match blocks every dependency PR.
  case "$author" in *"[bot]"*) continue ;; esac
  if ! printf '%s\n' "$signers" | grep -qiF "<$author>"; then
    echo "FAIL $(git rev-parse --short "$sha")  sign-off does not match author <$author> — $subject"
    bad=$((bad + 1))
  fi
done <<<"$commits"

if [ "$bad" -gt 0 ]; then
  echo "DCO: $bad of $n commit(s) not signed off. Fix: git commit -s --amend --no-edit, or git rebase --signoff BASE" >&2
  exit 1
fi
echo "DCO: all $n commit(s) signed off"
