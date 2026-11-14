#!/usr/bin/env bash
# usage: action-pins.test.sh "RUNNER SCRIPT"      e.g.  action-pins.test.sh "/bin/bash /path/check-action-pins.sh"
# `gh` is a stub that answers from fixture files, so the suite needs no network. The fixtures also answer the
# commits/<ref> endpoint the way GitHub does (any SHA, branch or tag resolves), which the script must not use.
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
T=$(mktemp -d)
mkdir -p "$T/bin" "$T/tools" "$T/fix" "$T/w"
for tool in bash grep sed tr cut sort env head cat; do ln -s "$(command -v $tool)" "$T/tools/$tool"; done
cat >"$T/bin/gh" <<'GH'
#!/bin/sh
# fixture-backed gh: `gh auth status`, and `gh api PATH [--jq EXPR]` answering the output the jq would print
case "$1" in
  auth) [ -z "${GH_UNAUTH:-}" ]; exit $? ;;
  api)
    f="$GH_FIX/$(printf %s "$2" | tr / _)"
    [ -f "$f" ] && { cat "$f"; exit 0; }
    echo '{"message":"Not Found","status":"404"}'
    echo "gh: Not Found (HTTP 404)" >&2
    exit 1
    ;;
esac
exit 1
GH
chmod +x "$T/bin/gh"
export GH_FIX="$T/fix"
fx() { printf '%s\n' "$2" >"$GH_FIX/$(printf %s "$1" | tr / _)"; }
A=$(printf 'a%.0s' $(seq 40))
B=$(printf 'b%.0s' $(seq 40))
C=$(printf 'c%.0s' $(seq 40))
D=$(printf 'd%.0s' $(seq 40))
E=$(printf 'e%.0s' $(seq 40))
# what GitHub's commits/<ref> would answer for anything: the bypass the old script fell for
fx "repos/o/r/commits/$A" "$A"
fx "repos/o/r/commits/main" "$A"
fx "repos/o/r/commits/v1.0.0" "$A"
# tags: v1.0.0 lightweight at A; v2.0.0 annotated (tag object B -> commit C); v3.0.0 a chain (D -> B -> C)
fx "repos/o/r/git/ref/tags/v1.0.0" "commit $A"
fx "repos/o/r/git/ref/tags/v2.0.0" "tag $B"
fx "repos/o/r/git/tags/$B" "commit $C"
fx "repos/o/r/git/ref/tags/v3.0.0" "tag $D"
fx "repos/o/r/git/tags/$D" "tag $B"
fx "repos/o/r/git/ref/tags/v1" "commit $A"
fx "repos/o/r/git/ref/tags/release/v1" "commit $A"
fx "repos/o/r/git/ref/tags/blob1" "blob $A"
fx "repos/o/r/git/ref/tags/short" "commit abc123"
# a tag object that keeps pointing at tag objects: the loop must give up
for _ in 1 2 3 4 5 6; do fx "repos/o/r/git/ref/tags/chain" "tag $E"; done
fx "repos/o/r/git/tags/$E" "tag $E"
fx "repos/o/other/git/ref/tags/v1.0.0" "commit $D"
fx "repos/o/r/commits/v9" "$A"
wf() { printf 'jobs:\n  j:\n    steps:\n' >"$T/w/ci.yml"; for u in "$@"; do printf '      - uses: %s\n' "$u" >>"$T/w/ci.yml"; done; }
run() { env PATH="$T/bin:$T/tools" $K "$T/w"; }
wf "o/r@$A # v1.0.0"
t "lightweight tag, correct" 0 'all 1 pinned' run
wf "o/r@$C # v2.0.0"
t "annotated tag, pinned to the commit" 0 'all 1 pinned' run
wf "o/r@$B # v2.0.0"
t "annotated tag, pinned to the TAG OBJECT, not the commit" 1 "labelled 'v2.0.0'" run
wf "o/r@$C # v3.0.0"
t "tag object pointing at a tag object, followed" 0 'all 1 pinned' run
wf "o/r@$A # chain"
t "a tag chain that never reaches a commit is not a tag" 1 "'chain' is not a tag" run
wf "o/r@$A # $A"
t "comment repeats the SHA (the old script passed this)" 1 'commit SHA, not a tag' run
wf "o/r@$A # main"
t "comment names a branch (the old script passed this)" 1 "'main' is not a tag" run
wf "o/r@$A # v9"
t "a name only the commits endpoint knows" 1 "'v9' is not a tag" run
wf "o/r@$B # v1.0.0"
t "right tag, wrong SHA" 1 "labelled 'v1.0.0' but that tag is" run
wf "o/r@$A # v7.7.7"
t "tag that does not exist" 1 "'v7.7.7' is not a tag" run
wf "o/other@$A # v1.0.0"
t "the same tag name in another repository is looked up there" 1 'labelled' run
wf "o/r@$A # v1.0.0" "o/r@$A # main"
t "one bad pin among good ones" 1 'action pins: 1 of 2 bad' run
wf "o/r/sub/dir@$A # v1.0.0"
t "an action in a subpath resolves against owner/repo" 0 'all 1 pinned' run
wf "o/r@$A # release/v1"
t "a tag name may contain a slash" 0 'all 1 pinned' run
wf "o/r@$A # v1"
t "a floating major warns, does not fail" 0 'WARN o/r' run
wf "o/r@$A # ../heads/main"
t "comment with .." 1 'not a valid tag name' run
wf "o/r@$A # -x"
t "comment starting with -" 1 'not a valid tag name' run
wf "o/r@$A # a//b"
t "comment with //" 1 'not a valid tag name' run
wf "o/r@$A # /v1"
t "comment starting with /" 1 'not a valid tag name' run
wf "o/r@$A # v1/"
t "comment ending with /" 1 'not a valid tag name' run
wf "o/r@$A # v1;id"
t "comment with a shell metacharacter" 1 'not a valid tag name' run
wf "o/r@$A # $(printf 'A%.0s' $(seq 40))"
t "an upper-case 40-character comment is not a SHA, and not a tag" 1 "is not a tag" run
wf "o/r@$A # blob1"
t "a ref that points at a blob" 1 "'blob1' is not a tag" run
wf "o/r@$A # short"
t "a ref whose commit is not 40 hex" 1 "'short' is not a tag" run
wf "o/r@v4 # v4"
t "tag instead of SHA" 1 "not a 40-hex commit SHA" run
wf "o/r@$A"
t "SHA pin with no comment" 1 'no .# <tag>. comment' run
wf "./local-action" "docker://alpine:3.20" "slsa-framework/slsa-github-generator/.github/workflows/g.yml@v2.0.0"
t "only local, docker and SLSA references: nothing to check" 2 "no 'uses:' entries" run
rm "$T/w/ci.yml"
t "empty workflow directory" 2 "no 'uses:' entries" run
t "no such directory" 2 "no workflow directory" env PATH="$T/bin:$T/tools" $K "$T/nope"
wf "o/r@$A # v1.0.0"
t "gh not authenticated" 2 'not authenticated' env PATH="$T/bin:$T/tools" GH_UNAUTH=1 $K "$T/w"
t "gh not on PATH" 2 'gh not on PATH' env PATH="$T/tools" $K "$T/w"
rm -rf "$T"
echo "failures: $fails"
exit $fails
