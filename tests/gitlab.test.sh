#!/usr/bin/env bash
# usage: tests-gitlab.sh SCRIPT
K=$1; fails=0; D64=$(printf '0%.0s' $(seq 64)); S40=$(printf 'a%.0s' $(seq 40))
t(){ name=$1; want=$2; pat=$3; shift 3; out=$("$@" 2>&1); rc=$?; res=PASS; [ $rc -eq $want ] || res="BAD-RC($rc)"
  if [ "${pat:0:1}" = "!" ]; then echo "$out" | grep -qE "${pat:1}" && res="$res+UNEXPECTED-MATCH"; else echo "$out" | grep -qE "$pat" || res="$res+MISSING-MATCH"; fi
  echo "$res  $name"; [ "$res" = PASS ] || { fails=$((fails+1)); echo "$out" | head -6 | sed 's/^/      /'; }; }
# scratch: a fresh temporary directory, entered. Refuses to continue anywhere else: an empty $T makes `cd ""`
# succeed in bash 3.2, and these suites run `git reset --hard` and `git clean -fd`.
scratch() {
  T=$(mktemp -d) || exit 1
  [ -d "$T" ] || exit 1
  cd "$T" || exit 1
}
scratch
w(){ cat > .gitlab-ci.yml; }
w <<Y
include:
  - component: \$CI_SERVER_FQDN/o/c/sd@$S40
  - project: g/t
    ref: $S40
    file: /a.yml
  - template: Jobs/SAST.gitlab-ci.yml
  - local: /ci/x.yml
default:
  image: python:3.13@sha256:$D64
job:
  image:
    name: node:20@sha256:$D64
  services:
    - postgres:18@sha256:$D64
    - name: redis:7@sha256:$D64
  artifacts:
    name: not-an-image
  script:
    - !reference [.setup, script]
Y
mkdir -p ci; echo 'x: {script: [echo]}' > ci/x.yml
t "good config" 0 'all [0-9]+ references pinned' $K
w <<Y
include: {component: o/c@~latest}
Y
t "component ~latest" 1 '~latest' $K
for r in 1 1.2 main; do w <<Y
include:
  - component: o/c@$r
Y
t "component @$r" 1 "ref '$r'" $K; done
w <<Y
include:
  - component: o/c
Y
t "component without @" 1 'no @version' $K
w <<Y
include:
  - component: o/c@1.2.3
Y
t "component exact tag is a warning" 0 'WARN.*tag' $K
w <<Y
include:
  - component: o/c@\$VER
Y
t "component @\$VAR cannot be verified" 1 'variable' $K
w <<Y
include:
  - project: g/t
    file: /a.yml
Y
t "project without ref" 1 'no ref:' $K
w <<Y
include:
  - project: g/t
    ref: main
    file: /a.yml
Y
t "project ref main" 1 "'main'" $K
w <<Y
include:
  - project: g/t
    ref: v1.0.0
    file: /a.yml
Y
t "project exact tag warns" 0 'WARN' $K
w <<Y
include: https://example.com/raw/main/x.yml
Y
t "remote string without sha" 1 'no commit SHA' $K
w <<Y
include:
  - remote: https://example.com/raw/$S40/x.yml
Y
t "remote embedding a sha ok" 0 '!FAIL' $K
w <<Y
include: [{template: Jobs/SAST.gitlab-ci.yml}]
Y
t "template only counts as examined" 0 'all 1 references pinned' $K
w <<Y
image: python:3.13
job: {script: [echo]}
Y
t "global image, no digest" 1 'python:3.13' $K
w <<Y
default:
  image: {name: python:3.13}
Y
t "default image map form" 1 'python:3.13' $K
w <<Y
job:
  image: python:3.13@sha256:abc
Y
t "short digest is not a pin" 1 'python:3.13' $K
w <<Y
job:
  services:
    - postgres:18
    - name: redis:7
Y
t "services string and map" 1 'redis:7' $K; $K | grep -c FAIL | sed 's/^/      FAIL lines: /'
w <<Y
job:
  image: \$CI_REGISTRY_IMAGE/builder:latest
Y
t "variable image fails" 1 'CI_REGISTRY_IMAGE' $K
t "allow-listed own registry" 0 '!FAIL' env GITLAB_PINS_ALLOW='^\$CI_REGISTRY_IMAGE' $K
w <<Y
include:
  - local: /ci/*.yml
Y
echo 'j: {image: bad:1}' > ci/y.yml
t "unpinned image reached through a glob include" 1 'ci/y.yml' $K
rm ci/y.yml
w <<Y
include:
  - local: /ci/a.yml
Y
echo 'include: [{local: /.gitlab-ci.yml}]' > ci/a.yml
t "include cycle terminates" 0 '!FAIL' $K
w <<Y
job: {script: [echo]}
Y
t "no third-party refs at all" 0 'nothing third-party' $K
printf 'a: [unclosed\n' > .gitlab-ci.yml; t "unparsable yaml -> 2" 2 'does not parse' $K
t "missing config -> 2" 2 'no config' $K nonexistent.yml
w <<Y
include: [{component: o/c@~latest}]
Y
sh0=$(mktemp -d); for x in bash env grep sed printf seq cat; do ln -s "$(command -v $x)" $sh0/$x; done
printf '#!/bin/sh\n[ "$1" = "--version" ] && { echo "yq (https://github.com/mikefarah/yq/) version 4.0.0"; exit 0; }\nexit 0\n' > $sh0/yq; chmod +x $sh0/yq
t "extraction silently empty -> 2, never a clean pass" 2 'none was extracted' env PATH=$sh0 $K
sh=$(mktemp -d); for x in bash env grep sed printf seq; do ln -s "$(command -v $x)" $sh/$x; done
t "yq absent -> 2" 2 'yq not on PATH' env PATH=$sh $K
printf '#!/bin/sh\necho "yq 3.4.1 (python wrapper)"\n' > $sh/yq; chmod +x $sh/yq; t "wrong yq -> 2" 2 'not mikefarah' env PATH=$sh $K
cd /; rm -rf "$T" "$sh"; echo "failures: $fails"; exit $fails
