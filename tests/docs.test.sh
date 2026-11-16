#!/usr/bin/env bash
# usage: tests/docs.test.sh      run from anywhere; exits non-zero if the docs are broken or the check is blind.
# Checks the documentation under docs/ (and README.md) against the tree it describes:
#   1. every relative link resolves to a file or directory, and a #anchor resolves to a heading;
#   2. every `check-*.sh` named in backticks is a script shipped under skills/*/scripts/;
#   3. every backticked name that starts like a skill (setup-, harden-, ...) is a directory under skills/.
# It then plants one fault of each kind in a copy of the tree and asserts the check reports it,
# so a green run on the real docs means something.
here=$(cd "$(dirname "$0")" && pwd)
root=$(dirname "$here")
fails=0

# shellcheck disable=SC2016  # backticks in patterns and printf text are literal
# slug: GitHub's heading anchor: lowercase, drop punctuation, spaces to hyphens.
slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9 _-]//g' -e 's/ /-/g'; }
has_anchor() { # file anchor
  local line
  grep -E '^#{1,6} ' "$1" | sed -E 's/^#+ +//; s/`//g' | while IFS= read -r line; do
    slug "$line"
    echo
  done | grep -qxF -- "$2"
}

# check_docs ROOT: prints one FAIL line per fault; returns the number found. Also prints
# "scanned N links" so a check that found nothing to scan cannot pass.
check_docs() {
  local r=$1 n=0 links=0 f dir target path anchor name
  local files
  files=$(find "$r/docs" -name '*.md' 2>/dev/null)
  [ -n "$files" ] || {
    echo "FAIL: no markdown found under $r/docs"
    return 1
  }
  [ -f "$r/README.md" ] && files=$files$'\n'$r/README.md
  while IFS= read -r f; do
    dir=$(dirname "$f")
    while IFS= read -r target; do
      case $target in http://* | https://* | mailto:*) continue ;; esac
      links=$((links + 1))
      path=${target%%#*}
      anchor=
      case $target in *'#'*) anchor=${target#*#} ;; esac
      if [ -z "$path" ]; then path=$f; else path=$dir/$path; fi
      if [ ! -e "$path" ]; then
        echo "FAIL: ${f#"$r"/}: link target missing: $target"
        n=$((n + 1))
        continue
      fi
      if [ -n "$anchor" ] && [ -f "$path" ] && ! has_anchor "$path" "$anchor"; then
        echo "FAIL: ${f#"$r"/}: no heading for anchor: $target"
        n=$((n + 1))
      fi
    done < <(grep -oE '\]\([^)[:space:]]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//')
    while IFS= read -r name; do
      case $name in
        check-*.sh) [ -n "$(find "$r/skills" -path "*/scripts/$name" 2>/dev/null)" ] \
          || {
            echo "FAIL: ${f#"$r"/}: script not shipped: $name"
            n=$((n + 1))
          } ;;
        *) [ -d "$r/skills/$name" ] \
          || {
            echo "FAIL: ${f#"$r"/}: no such skill: $name"
            n=$((n + 1))
          } ;;
      esac
    done < <(grep -oE '`(check-[a-z0-9-]+\.sh|(setup|harden|bootstrap|analyze|plan|wrapup|graduate|validate)-[a-z0-9-]+)`' "$f" | tr -d '`' | sort -u)
  done <<<"$files"
  echo "scanned $links links"
  [ "$links" -gt 0 ] || {
    echo "FAIL: scanned no links"
    n=$((n + 1))
  }
  return $n
}

# scratch: a fresh temporary directory, entered. Refuses to continue anywhere else.
scratch() {
  T=$(mktemp -d) || exit 1
  [ -d "$T" ] || exit 1
  cd "$T" || exit 1
}

t() { # name want-nonzero(0|1) pattern  (runs check_docs on $T/tree)
  local out rc
  out=$(check_docs "$T/tree" 2>&1)
  rc=$?
  if [ "$2" = 0 ]; then
    if [ $rc -eq 0 ]; then echo "PASS  $1"; else
      echo "BAD  $1"
      echo "$out" | sed 's/^/      /' | head -5
      fails=$((fails + 1))
    fi
  else
    if [ $rc -ne 0 ] && echo "$out" | grep -qF -- "$3"; then
      echo "PASS  $1"
    else
      echo "BAD  $1 (rc=$rc, wanted '$3')"
      echo "$out" | sed 's/^/      /' | head -5
      fails=$((fails + 1))
    fi
  fi
}

echo "== docs links and names"
out=$(check_docs "$root")
rc=$?
if [ $rc -eq 0 ]; then echo "PASS  the real docs ($(echo "$out" | tail -1))"; else
  echo "BAD  the real docs"
  echo "$out" | sed 's/^/      /'
  fails=$((fails + 1))
fi

scratch
reset() {
  rm -rf "$T/tree"
  mkdir "$T/tree"
  (cd "$root" && cp -R docs skills tests README.md CHANGELOG.md CONTRIBUTING.md "$T/tree/")
}
reset
t "clean copy passes" 0
d=$T/tree/docs/explanation
reset
printf '\nSee [x](no-such-page.md).\n' >>"$d/why-projects-graduate-through-tiers.md"
t "missing link target is reported" 1 "link target missing: no-such-page.md"
reset
printf '\nSee [x](../../skills/bootstrap-project/SKILL.md#no-such-heading).\n' >>"$d/why-projects-graduate-through-tiers.md"
t "missing anchor is reported" 1 "no heading for anchor"
reset
printf '\nSee `setup-nothing`.\n' >>"$d/how-the-skills-fit-together.md"
t "unknown skill name is reported" 1 "no such skill: setup-nothing"
reset
printf '\nRun `check-nothing.sh`.\n' >>"$d/how-the-skills-fit-together.md"
t "unshipped script name is reported" 1 "script not shipped: check-nothing.sh"
reset
printf '\nSee [ok](../../skills/bootstrap-project/SKILL.md#tier-selection) and [web](https://example.com/x).\n' >>"$d/how-the-skills-fit-together.md"
t "valid anchor link and external link pass" 0
reset
rm -rf "$T/tree/docs"
mkdir -p "$T/tree/docs"
t "an empty docs tree cannot pass" 1 "no markdown found"
reset
find "$T/tree/docs" -name '*.md' -exec sh -c 'sed -i.bak -E "s/\]\([^)]*\)/]/g" "$1"; rm "$1.bak"' _ {} \;
find "$T/tree" -maxdepth 1 -name README.md -exec sh -c 'sed -i.bak -E "s/\]\([^)]*\)/]/g" "$1"; rm "$1.bak"' _ {} \;
t "a tree with no links cannot pass" 1 "scanned no links"

cd "$root" && rm -rf "$T"
echo "docs failures: $fails"
exit $fails
