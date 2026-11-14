#!/usr/bin/env bash
# scripts/check-action-pins.sh
# Every `uses: owner/repo@<sha> # <tag>` must pin a 40-hex commit SHA, and that SHA must be
# the commit <tag> actually resolves to. A comment is a claim; this resolves it.
# <tag> is resolved as a TAG (git/ref/tags/<tag>, annotated tags followed to their commit), never
# through commits/<ref>, which accepts any ref: a comment that repeats the SHA, or names a branch, would
# resolve to itself and pass. A comment that is a 40-hex SHA, or is not a valid tag name, fails.
#   usage: scripts/check-action-pins.sh [workflow-dir]        (default .github/workflows)
# Exit: 0 all pins true | 1 unpinned, unlabelled or mislabelled | 2 could not run
# (2, not 0, when it cannot run or finds no `uses:` — a checker that checked nothing passed nothing.)
# Needs `gh` authenticated (GH_TOKEN in CI).
set -u
DIR="${1:-.github/workflows}"

command -v gh >/dev/null 2>&1 || {
  echo "FAIL: gh not on PATH — pins NOT checked" >&2
  exit 2
}
gh auth status >/dev/null 2>&1 || {
  echo "FAIL: gh not authenticated (set GH_TOKEN in CI) — pins NOT checked" >&2
  exit 2
}
[ -d "$DIR" ] || {
  echo "FAIL: no workflow directory '$DIR'" >&2
  exit 2
}

# External actions only: skip local (./) and docker:// references, and the SLSA generator,
# which must be tag-referenced (Step 7) and so can never be a SHA pin.
lines=$(grep -rhE '^[[:space:]]*-?[[:space:]]*uses:' "$DIR" \
  | sed -E 's/^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*//' \
  | grep -vE '^(\./|docker://|slsa-framework/slsa-github-generator/)' | sort -u)
if [ -z "$lines" ]; then
  echo "FAIL: no 'uses:' entries under $DIR — wrong path, or the grep broke" >&2
  exit 2
fi

# resolve_tag REPO TAG: print the commit SHA the tag points at; return 1 if it is not a tag or cannot be
# followed. An annotated tag points at a tag object, which is followed (a bounded number of hops).
resolve_tag() {
  local repo=$1 tag=$2 obj type sha
  obj=$(gh api "repos/$repo/git/ref/tags/$tag" --jq '.object.type + " " + .object.sha' 2>/dev/null) || return 1
  for _ in 1 2 3 4 5; do
    type=${obj%% *}
    sha=${obj##* }
    case $type in
      commit)
        printf '%s' "$sha" | grep -qE '^[0-9a-f]{40}$' || return 1
        printf '%s\n' "$sha"
        return 0
        ;;
      tag) obj=$(gh api "repos/$repo/git/tags/$sha" --jq '.object.type + " " + .object.sha' 2>/dev/null) || return 1 ;;
      *) return 1 ;;
    esac
  done
  return 1
}

bad=0 checked=0
while IFS= read -r line; do
  spec=$(printf '%s' "${line%%#*}" | tr -d '[:space:]')
  tag=$(printf '%s' "$line" | sed -nE 's/^[^#]*#[[:space:]]*([^[:space:]]+).*/\1/p')
  ref=${spec##*@}
  path=${spec%@*}
  repo=$(printf '%s' "$path" | cut -d/ -f1,2) # drop a subpath: owner/repo/sub -> owner/repo
  checked=$((checked + 1))

  if ! printf '%s' "$ref" | grep -qE '^[0-9a-f]{40}$'; then
    echo "FAIL $path — pinned to '$ref', not a 40-hex commit SHA"
    bad=$((bad + 1))
    continue
  fi
  if [ -z "$tag" ]; then
    echo "FAIL $path — SHA pin has no '# <tag>' comment, so nothing says which version it is"
    bad=$((bad + 1))
    continue
  fi
  if printf '%s' "$tag" | grep -qE '^[0-9a-f]{40}$'; then
    echo "FAIL $path — the comment is a commit SHA, not a tag: it would only restate the pin"
    bad=$((bad + 1))
    continue
  fi
  if printf '%s' "$tag" | grep -qE '[^A-Za-z0-9._/+-]|^[-/]|/$|//|\.\.'; then
    echo "FAIL $path — '$tag' is not a valid tag name"
    bad=$((bad + 1))
    continue
  fi
  real=$(resolve_tag "$repo" "$tag") || real=""
  if [ -z "$real" ]; then
    echo "FAIL $path — '$tag' is not a tag in $repo (a branch name or a commit SHA is not a tag)"
    bad=$((bad + 1))
  elif [ "$real" != "$ref" ]; then
    echo "FAIL $path — labelled '$tag' but that tag is ${real:0:12}, pinned ${ref:0:12}"
    bad=$((bad + 1))
  elif printf '%s' "$tag" | grep -qE '^v?[0-9]+$'; then
    # True today, but a major alias MOVES: the comment can go stale with no way to show it.
    echo "WARN $path — '$tag' is a floating major; prefer an exact tag (vX.Y.Z)"
  fi
done <<<"$lines"

if [ "$bad" -gt 0 ]; then
  echo "action pins: $bad of $checked bad. Resolve, never write from memory:" >&2
  echo "  gh api repos/<owner>/<repo>/git/ref/tags/<tag> --jq .object   # an annotated tag: follow git/tags/<sha> to its commit" >&2
  exit 1
fi
echo "action pins: all $checked pinned to a SHA matching their stated tag"
