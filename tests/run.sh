#!/usr/bin/env bash
# usage: tests/run.sh      run from anywhere; exits non-zero if any suite fails or a script is missing.
# Each suite plants faults in a throwaway repository and asserts the check reports them (see docs/explanation/how-a-check-is-built-and-proved.md).
# The suites run the scripts shipped in skills/<name>/scripts/, not copies.
here=$(cd "$(dirname "$0")" && pwd); root=$(dirname "$here"); fails=0
run() { # skill script-name suite mode(runner|path)
  f=$root/skills/$1/scripts/$2
  [ -x "$f" ] || { echo "FAIL: $f is missing or not executable"; fails=$((fails + 1)); return; }
  echo "== $2"
  if [ "$4" = runner ]; then bash "$here/$3" "/bin/bash $f"; else bash "$here/$3" "$f"; fi
  [ $? -eq 0 ] || fails=$((fails + 1))
}
run setup-adrs check-adrs.sh adrs.test.sh runner
run bootstrap-project check-bootstrap.sh bootstrap.test.sh path
run setup-container-security check-containerfile.sh containerfile.test.sh runner
run harden-gitlab-ci check-gitlab-pins.sh gitlab.test.sh path
run setup-git-hooks check-hygiene.sh hygiene.test.sh runner
run harden-github-actions check-action-pins.sh action-pins.test.sh runner
run validate-quality-config check-tool-pins.sh tool-pins.test.sh runner
echo "== docs.test.sh"
bash "$here/docs.test.sh"
[ $? -eq 0 ] || fails=$((fails + 1))
echo "== diagrams.test.sh"
bash "$here/diagrams.test.sh"
[ $? -eq 0 ] || fails=$((fails + 1))
echo "suites failed: $fails"
exit $fails
