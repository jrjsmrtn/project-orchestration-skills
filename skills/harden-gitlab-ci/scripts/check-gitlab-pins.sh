#!/usr/bin/env bash
# scripts/check-gitlab-pins.sh — every third-party reference in a GitLab CI config is pinned.
#   usage: scripts/check-gitlab-pins.sh [config]            (default .gitlab-ci.yml; run from the repo root)
#   env:   GITLAB_PINS_ALLOW   ERE of image references to skip — your own registry, say
#                              '^\$CI_REGISTRY_IMAGE' — because they are yours to pin or not
#   exit:  0 every reference is pinned | 1 at least one is not | 2 could not run
#          (2, not 0, when `yq` is missing or the wrong one, a file is missing or does not parse, or the file
#           mentions include:/image:/services: yet none was extracted — a checker that checked nothing passed nothing)
# Checks, following `include: local` files (globs too):
#   include: component   ref after the last '@' must be a 40-hex commit SHA (exact tag: WARN; ~latest, partial
#                         semver, branch, a $VARIABLE or no '@': FAIL)
#   include: project      `ref:` must be a 40-hex SHA (exact tag: WARN; absent — it defaults to the target's
#                         HEAD — or a branch or $VARIABLE: FAIL)
#   include: remote / URL no ref exists to pin: FAIL unless the URL embeds a 40-hex revision
#   image: / services:    must carry @sha256:<64 hex> (anywhere in the file: global, default:, per job)
# Needs mikefarah `yq` v4 (a structured read: grep cannot tell `name:` of a service from `name:` of an artifact).
set -u
CONFIG="${1:-.gitlab-ci.yml}"
ALLOW="${GITLAB_PINS_ALLOW:-}"

command -v yq >/dev/null 2>&1 || {
  echo "FAIL: yq not on PATH — pins NOT checked" >&2
  exit 2
}
yq --version 2>&1 | grep -q mikefarah || {
  echo "FAIL: yq is not mikefarah/yq v4 — pins NOT checked" >&2
  exit 2
}
[ -f "$CONFIG" ] || {
  echo "FAIL: no config '$CONFIG'" >&2
  exit 2
}

bad=0 checked=0 warned=0
fail() {
  echo "FAIL $*"
  bad=$((bad + 1))
}
warn() {
  echo "WARN $*"
  warned=$((warned + 1))
}

classify() { # $1 ref -> sha | tag | var | other
  case "$1" in
    *'$'*) echo var ;;
    *) if printf '%s' "$1" | grep -qE '^[0-9a-f]{40}$'; then
      echo sha
    elif printf '%s' "$1" | grep -qE '^v?[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.+-]*)?$'; then
      echo tag
    else echo other; fi ;;
  esac
}

check_ref() { # $1 file  $2 what  $3 ref
  checked=$((checked + 1))
  case "$(classify "$3")" in
    sha) ;;
    tag) warn "$1: $2 pinned to tag '$3' — a tag moves unless the project protects its tags; prefer the commit SHA" ;;
    var) fail "$1: $2 ref '$3' is a variable — cannot be verified; write the SHA" ;;
    *) fail "$1: $2 ref '$3' is not a 40-hex commit SHA (moving target)" ;;
  esac
}

queue=("$CONFIG")
seen=" "
while [ "${#queue[@]}" -gt 0 ]; do
  f=${queue[0]}
  queue=("${queue[@]:1}")
  case "$seen" in *" $f "*) continue ;; esac
  seen="$seen$f "
  yq '.' "$f" >/dev/null 2>&1 || {
    echo "FAIL: $f does not parse as YAML — pins NOT checked" >&2
    exit 2
  }

  while IFS=$'\t' read -r kind val ref; do
    [ -n "$kind" ] || continue
    case "$kind" in
      str | local)
        case "$val" in
          http://* | https://*) kind=remote ;;
          *)
            checked=$((checked + 1))
            p=${val#/}
            # shellcheck disable=SC2086  # intentional glob expansion of an include: local pattern
            for g in $p; do [ -f "$g" ] && queue+=("$g"); done
            continue
            ;;
        esac
        ;;
    esac
    case "$kind" in
      remote)
        checked=$((checked + 1))
        printf '%s' "$val" | grep -qE '/[0-9a-f]{40}/' \
          || fail "$f: remote include '$val' embeds no commit SHA — there is no ref to pin"
        ;;
      component)
        case "$val" in
          *@*) check_ref "$f" "component '${val%@*}'" "${val##*@}" ;;
          *)
            checked=$((checked + 1))
            fail "$f: component '$val' has no @version"
            ;;
        esac
        ;;
      project)
        if [ "$ref" = "-" ]; then
          checked=$((checked + 1))
          fail "$f: include project '$val' has no ref: — it silently tracks that project's HEAD"
        else check_ref "$f" "include project '$val'" "$ref"; fi
        ;;
      template) checked=$((checked + 1)) ;; # GitLab-shipped, nothing to pin
      *)
        checked=$((checked + 1))
        fail "$f: include entry of an unrecognised form ($kind: $val)"
        ;;
    esac
  done < <(yq -r '
    .include | select(. != null) | (if tag == "!!seq" then .[] else . end)
    | (if tag == "!!str" then ["str", ., "-"]
       elif has("component") then ["component", .component, "-"]
       elif has("project")   then ["project", .project, (.ref // "-")]
       elif has("remote")    then ["remote", .remote, "-"]
       elif has("local")     then ["local", .local, "-"]
       elif has("template")  then ["template", .template, "-"]
       else ["unknown", (. | tostring), "-"] end)
    | @tsv' "$f")

  while IFS= read -r img; do
    [ -n "$img" ] || continue
    checked=$((checked + 1))
    if [ -n "$ALLOW" ] && printf '%s' "$img" | grep -qE "$ALLOW"; then continue; fi
    printf '%s' "$img" | grep -qE '@sha256:[0-9a-f]{64}$' \
      || fail "$f: image/service '$img' is not pinned by @sha256 digest"
  done < <(yq -r '.. | select(tag == "!!map") | (.image, .services[]?) | select(. != null)
                  | ((select(tag == "!!str")) // .name) | select(. != null)' "$f")
done

# Fail closed if the file visibly mentions includes, images or services yet nothing was extracted:
# the YAML shape was one this script does not read, and a clean result would be false.
# shellcheck disable=SC2086   # $seen is a newline list of plain paths
if [ "$checked" -eq 0 ] && grep -qE '^[[:space:]]*(include|image|services):' $seen; then
  echo "FAIL: $CONFIG mentions include:/image:/services: but none was extracted — pins NOT checked" >&2
  exit 2
fi
if [ "$bad" -gt 0 ]; then
  echo "gitlab pins: $bad of $checked references not pinned ($warned warnings). Resolve, never write from memory:" >&2
  echo "  glab api \"projects/<url-encoded path>/repository/commits/<tag>\" --jq .id      # component / project" >&2
  echo "  skopeo inspect docker://<image:tag> --format '{{.Digest}}'                      # image / service" >&2
  exit 1
fi
if [ "$checked" -eq 0 ]; then
  echo "gitlab pins: no includes, images or services found in $CONFIG (nothing third-party to pin)"
else echo "gitlab pins: all $checked references pinned ($warned warnings)"; fi
