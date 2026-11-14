#!/usr/bin/env bash
# usage: tests/run.sh      run from anywhere; exits non-zero if any suite fails or a script cannot be extracted.
# Each suite plants faults in a throwaway repository and asserts the check reports them (see ADR-0009).
here=$(cd "$(dirname "$0")" && pwd); root=$(dirname "$here"); tmp=$(mktemp -d); fails=0
run(){ # skill script-name suite mode(runner|path)
  f=$tmp/$2; bash "$here/extract-script.sh" "$root/skills/$1/SKILL.md" "$2" > "$f"
  [ -s "$f" ] || { echo "FAIL: no $2 block in skills/$1/SKILL.md"; fails=$((fails+1)); return; }
  chmod +x "$f"; echo "== $2"
  if [ "$4" = runner ]; then bash "$here/$3" "/bin/bash $f"; else bash "$here/$3" "$f"; fi
  [ $? -eq 0 ] || fails=$((fails+1)); }
run setup-adrs check-adrs.sh adrs.test.sh runner
run bootstrap-project check-bootstrap.sh bootstrap.test.sh path
run setup-container-security check-containerfile.sh containerfile.test.sh runner
run harden-gitlab-ci check-gitlab-pins.sh gitlab.test.sh path
run setup-git-hooks check-hygiene.sh hygiene.test.sh runner
rm -rf "$tmp"; echo "suites failed: $fails"; exit $fails
