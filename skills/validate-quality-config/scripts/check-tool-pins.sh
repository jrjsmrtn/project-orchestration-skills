#!/usr/bin/env bash
# scripts/check-tool-pins.sh
# Every pin of a lint/format/compliance tool must be EXACT, and every place must agree.
#   usage: scripts/check-tool-pins.sh TOOL [TOOL...]     e.g.  check-tool-pins.sh reuse hadolint
# Exit: 0 all pins exact and identical | 1 floating or differing pins | 2 no pin found for a tool
# (2, not 0, when nothing matches: a checker that finds nothing has checked nothing.)
set -u
files=$({
  ls .lefthook.yml lefthook.yml Makefile justfile .gitlab-ci.yml 2>/dev/null
  find scripts .lefthook .github/workflows -type f 2>/dev/null
} | sort -u)
rc=0
for tool in "$@"; do
  t=${tool//./\\.}
  # forms read:  tool:1.2.3   tool==1.2.3   tool@v1.2.3   and the space form  tool 1.2.3
  ver="((:|==|@)v?[A-Za-z0-9][A-Za-z0-9._-]*|[[:space:]]+v?[0-9][0-9.]*)"
  re="(^|[^A-Za-z0-9_-])${t}${ver}"
  # shellcheck disable=SC2086   # $files is a newline list of plain paths
  hits=$(grep -nHE "$re" $files 2>/dev/null | grep -v 'uses:' || true) # action pins: harden-github-actions
  if [ -z "$hits" ]; then
    echo "✗ $tool: no version pin found anywhere — unpinned, or a form this check does not read" >&2
    [ $rc -lt 2 ] && rc=2
    continue
  fi
  versions=""
  while IFS= read -r line; do
    v=$(printf '%s' "$line" | grep -oE "${t}${ver}" | head -n1 | sed -E "s/^${t}(:|==|@|[[:space:]]+)v?//")
    if printf '%s' "$v" | grep -qE '^[0-9]+(\.[0-9]+){2,}'; then
      versions="$versions $v"
    else
      echo "✗ $tool: floating pin '$v' — $(printf '%s' "$line" | cut -d: -f1,2)" >&2
      rc=1
    fi
  done <<<"$hits"
  distinct=$(printf '%s\n' $versions | sort -u | grep -c . || true)
  if [ "$distinct" -gt 1 ]; then
    echo "✗ $tool: $distinct different exact versions in use: $(printf '%s\n' $versions | sort -u | tr '\n' ' ')" >&2
    rc=1
  elif [ "$distinct" -eq 1 ] && [ $rc -eq 0 ]; then
    echo "✓ $tool: pinned to $(printf '%s\n' $versions | sort -u) everywhere"
  fi
done
exit $rc
