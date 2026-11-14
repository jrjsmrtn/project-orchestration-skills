#!/usr/bin/env bash
# usage: tool-pins.test.sh "RUNNER SCRIPT"      e.g.  tool-pins.test.sh "/bin/bash /path/check-tool-pins.sh"
K=$1
fails=0
t() {
  name=$1 want=$2 pat=$3
  shift 3
  out=$("$@" 2>&1)
  rc=$?
  res=PASS
  [ $rc -eq "$want" ] || res="BAD-RC($rc)"
  if [ "${pat:0:1}" = "!" ]; then echo "$out" | grep -qE "${pat:1}" && res="$res+UNEXPECTED-MATCH"; else echo "$out" | grep -qE "$pat" || res="$res+MISSING-MATCH"; fi
  echo "$res  $name"
  [ "$res" = PASS ] || {
    fails=$((fails + 1))
    echo "$out" | head -6 | sed 's/^/      /'
  }
}
# scratch: a fresh temporary directory, entered. Refuses to continue anywhere else: an empty $T makes `cd ""`
# succeed in bash 3.2, and these suites run `git reset --hard` and `git clean -fd`.
scratch() {
  T=$(mktemp -d) || exit 1
  [ -d "$T" ] || exit 1
  cd "$T" || exit 1
}
scratch
mkdir -p scripts .github/workflows
reset() {
  rm -rf lefthook.yml Makefile justfile .gitlab-ci.yml .lefthook scripts .github
  mkdir -p scripts .github/workflows
}
printf 'repos:\n  - hook: reuse==3.1.0\n' >lefthook.yml
printf 'lint:\n\tpip install reuse==3.1.0\n' >Makefile
t "the same exact version in two files" 0 'reuse: pinned to 3.1.0 everywhere' $K reuse
printf 'lint:\n\tpip install reuse==3.2.0\n' >Makefile
t "two different exact versions" 1 'reuse: 2 different exact versions in use: 3.1.0 3.2.0' $K reuse
printf 'lint:\n\tpip install reuse==3\n' >Makefile
t "a floating pin (major only)" 1 "reuse: floating pin '3'" $K reuse
printf 'lint:\n\tpip install reuse==3.1\n' >Makefile
t "a floating pin (minor only)" 1 "reuse: floating pin '3.1'" $K reuse
printf 'lint:\n\tpip install reuse==latest\n' >Makefile
t "a floating pin (latest)" 1 "reuse: floating pin 'latest'" $K reuse
printf 'lint:\n\tpip install reuse==3.1.0\n' >Makefile
t "an unknown tool: no pin found, exit 2" 2 'nothing|no version pin found anywhere' $K hadolint
t "no tool named at all" 0 '!✗' $K
printf '  - uses: reuse@v9\n' >.github/workflows/ci.yml
t "a uses: line is another check's business" 0 'reuse: pinned to 3.1.0 everywhere' $K reuse
rm .github/workflows/ci.yml
printf 'x: hadolint:v2.12.0\n' >.gitlab-ci.yml
t "two tools, both exact" 0 'hadolint: pinned to 2.12.0 everywhere' $K reuse hadolint
printf 'x: hadolint:v2\n' >.gitlab-ci.yml
t "one tool floating, the other fine: exit 1" 1 "hadolint: floating pin" $K reuse hadolint
printf 'x: hadolint:v2.12.0\n' >.gitlab-ci.yml
printf 'x: hadolint:v2.13.0\n' >scripts/tools.sh
t "different versions across files" 1 'hadolint: 2 different exact versions in use: 2.12.0 2.13.0' $K hadolint
rm scripts/tools.sh
printf 'reuse 3.1.0\n' >justfile
t "the space form (tool 1.2.3)" 0 'reuse: pinned to 3.1.0 everywhere' $K reuse
printf 'reuse@v3.1.0\n' >justfile
t "the @v form" 0 'reuse: pinned to 3.1.0 everywhere' $K reuse
reset
printf 'a: re.use==1.0.0\n' >Makefile
t "a dot in a tool name is not a wildcard" 2 'no version pin found' $K reXuse
printf 'a: reuse==1.0.0-rc1\n' >Makefile
t "a pre-release suffix is still an exact pin" 0 'reuse: pinned to 1.0.0-rc1 everywhere' $K reuse
reset
printf 'a: tool==1.2.3\nb: tool==1.2.3\nc: tool==1.2.3\n' >Makefile
t "the same version on three lines counts once" 0 'tool: pinned to 1.2.3 everywhere' $K tool
cd / || exit 1
rm -rf "$T"
echo "failures: $fails"
exit $fails
