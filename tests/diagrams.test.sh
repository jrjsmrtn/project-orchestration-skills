#!/usr/bin/env bash
# usage: tests/diagrams.test.sh      run from anywhere; exits non-zero if a diagram in docs/ does not render.
# Renders every ```mermaid block under docs/ and in README.md with Pele (pinned in tests/diagrams/package-lock.json),
# after proving the validator can fail: a malformed diagram must exit 1, and a file with no diagram must exit 2.
# Pele is a dependency-free Mermaid renderer, not GitHub's: a pass means "parses and lays out in Pele", not
# "looks right on GitHub". Setup, once:  npm ci --ignore-scripts --prefix tests/diagrams
here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
fails=0
v=$here/diagrams/validate-mermaid.mjs
type -P node >/dev/null || {
  echo "FAIL: node is not installed"
  exit 1
}
[ -d "$here/diagrams/node_modules/pele" ] || {
  echo "FAIL: Pele is not installed. Run: npm ci --ignore-scripts --prefix tests/diagrams"
  exit 1
}
T=$(mktemp -d) || exit 1
[ -d "$T" ] || exit 1
expect() { # name want-rc file...
  local name=$1 want=$2 out rc
  shift 2
  out=$(node "$v" "$@" 2>&1)
  rc=$?
  if [ $rc -eq "$want" ]; then
    echo "PASS  $name"
  else
    echo "BAD  $name (rc=$rc, wanted $want)"
    echo "$out" | head -5 | sed 's/^/      /'
    fails=$((fails + 1))
  fi
}
printf '# t\n\n```mermaid\nflowchart TD\n  a --> b\n```\n' >"$T/good.md"
printf '# t\n\n```mermaid\nflowchart TD\n  a --> [b\n  c ---> ((\n```\n' >"$T/bad.md"
printf '# t\n\nno diagram here\n' >"$T/none.md"
echo "== docs diagrams"
expect "a valid diagram renders" 0 "$T/good.md"
expect "a malformed diagram is reported" 1 "$T/bad.md"
expect "a file with no diagram cannot pass" 2 "$T/none.md"
expect "a good file with a bad one fails" 1 "$T/good.md" "$T/bad.md"
files=$(find "$root/docs" -name '*.md')
# shellcheck disable=SC2086  # the list is newline-separated paths without spaces in this repo
expect "the real docs render" 0 $files "$root/README.md"
rm -rf "$T"
echo "diagram failures: $fails"
exit $fails
