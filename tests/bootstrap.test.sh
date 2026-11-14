#!/usr/bin/env bash
# usage: tests-bootstrap.sh SCRIPT
K=$1; fails=0
t(){ name=$1; want=$2; pat=$3; shift 3; out=$("$@" 2>&1); rc=$?; res=PASS; [ $rc -eq $want ] || res="BAD-RC($rc)"
  if [ "${pat:0:1}" = "!" ]; then echo "$out" | grep -qE "${pat:1}" && res="$res+UNEXPECTED-MATCH"; else echo "$out" | grep -qE "$pat" || res="$res+MISSING-MATCH"; fi
  echo "$res  $name"; [ "$res" = PASS ] || { fails=$((fails+1)); echo "$out" | grep -E '^(FAIL|note)' | head -5 | sed 's/^/      /'; }; }
# scratch: a fresh temporary directory, entered. Refuses to continue anywhere else: an empty $T makes `cd ""`
# succeed in bash 3.2, and these suites run `git reset --hard` and `git clean -fd`.
scratch() {
  T=$(mktemp -d) || exit 1
  [ -d "$T" ] || exit 1
  cd "$T" || exit 1
}
scratch; git init -q -b main; git config user.email t@example.com; git config user.name t; git config core.hooksPath "$T/.git/hooks"; git config commit.gpgsign false
mkdir -p docs/adr docs/tutorials docs/howto docs/reference docs/explanation docs/architecture docs/sprints docs/roadmap architecture .github
cat > CLAUDE.md <<'Y'
# P

## Project Context

- **Category**: Development
- **Tier**: t2
- **Distribution profile**: Public  (ships-artifacts: no)

## Project Tier

Current tier: **t2**

## Current Development Status

- **Current Sprint**: Sprint 1
Y
printf '.env\n.env.*\n!.env.example\n*.pem\n*.key\ncredentials.json\nCLAUDE.local.md\n' > .gitignore
printf '# C\n\n## [Unreleased]\n' > CHANGELOG.md; echo '# P' > README.md
for n in 0001 0002 0003; do echo "# $n" > docs/adr/$n-x.md; done
echo 'pre-commit: {}' > lefthook.yml; echo wd > architecture/workspace.dsl; echo r > docs/roadmap/roadmap.md; echo s > docs/sprints/sprint-0001-plan.md
echo "version: 2" > .github/dependabot.yml
for d in tutorials howto reference explanation architecture sprints roadmap; do touch docs/$d/.gitkeep; done
mkdir -p .git/hooks; printf '#!/bin/sh\n' > .git/hooks/pre-commit; printf '#!/bin/sh\n' > .git/hooks/pre-push; chmod +x .git/hooks/*
cat > SECURITY.md <<'Y'
# Security Policy

## Reporting a Vulnerability

Please report privately via https://github.com/o/r/security/advisories/new or security@example.com.

## Supported Versions

| 1.x | yes |

## Scope

This tool parses untrusted diagram input from users; shell escaping of node labels and path traversal in include directives are in scope, while the rendering engine itself is not.
Y
git add -A; git commit -qm "feat: initial" ; git branch develop; git remote add github https://github.com/o/r.git
base=$(git rev-parse HEAD)
rs(){ git reset -q --hard $base; git clean -qfd; git checkout -q main 2>/dev/null; git branch -q develop 2>/dev/null; }
t "good t2 + public" 0 '!FAIL' $K
t "good: tier inferred from CLAUDE.md" 0 'ok    \[t2\]' $K
sed -i.b 's/t2/t0/g' CLAUDE.md; t "good: t0 subset runs only t0 (+public/remote)" 0 '!\[t1\]|\[t2\]' $K t0; rs
t "tier argument must match what CLAUDE.md declares" 1 "does not state 'Current tier: \*\*t0" $K t0
t "bad arg" 2 'usage' $K t9
mv CLAUDE.md C.bak; t "no CLAUDE.md and no tier arg -> 2" 2 'tier unknown' $K; t "no CLAUDE.md with t0 -> FAIL" 1 'CLAUDE.md is missing' $K t0; mv C.bak CLAUDE.md
sed -i.b 's/^Current tier: \*\*t2\*\*/Current tier: **t1**/' CLAUDE.md; t "tier line disagrees with arg" 1 "does not state 'Current tier: \*\*t2" $K t2; rs
sed -i.b 's/^- \*\*Tier\*\*: t2/- **Tier**: t1/' CLAUDE.md; t "Context Tier disagrees" 1 'Project Context says Tier: t1' $K; rs
git commit -q --amend -m "initial commit" ; t "no conventional commit" 1 'no commit subject is a conventional' $K; rs
printf '.env\n' > .gitignore; t ".gitignore gaps" 1 'does not ignore: .*CLAUDE.local.md' $K; rs
rm .gitignore; t "no .gitignore" 1 '.gitignore is missing' $K; rs
printf '# C\n' > CHANGELOG.md; t "no Unreleased" 1 'no .## \[Unreleased\]' $K; rs
git branch -q -D develop; t "no develop" 1 'branch develop does not exist' $K; rs
rm docs/adr/0002-x.md; t "ADR-0002 missing" 1 'docs/adr/0002' $K; rs
rm docs/adr/0003-x.md; t "ADR-0003 missing" 1 'docs/adr/0003' $K; rs
t "ADR-0004 not required for Development" 0 '!0004' $K
sed -i.b 's/\*\*Category\*\*: Development/**Category**: Hybrid/' CLAUDE.md; t "ADR-0004 required for Hybrid" 1 'docs/adr/0004' $K; rs
rm README.md; t "no README at t1" 1 'README.md is missing' $K; rs
# README: derive-don't-assert, and the short description
printf '# P\n\n## Status\n\nSkeleton. 15 verified records.\n' > README.md; t "Status quotes a count" 1 'Status quotes a count' $K; rs
printf '# P\n\n## Status\n\nSkeleton as of 2026-11-14.\n' > README.md; t "Status with a date" 0 'Status states a date or a link' $K; rs
printf '# P\n\nStatus: see [the roadmap](docs/roadmap/roadmap.md).\n' > README.md; t "Status as a link, inline form" 0 'Status states a date or a link' $K; rs
printf '# P\n\n## Status\n\nEarly days.\n' > README.md; t "Status with neither date nor link" 1 'neither a date nor a link' $K; rs
printf '# P\n\n## Status\n\nSkeleton as of 2026-11-14.\n\n## Usage\n\nRuns 3 checks.\n' > README.md; t "a count after the Status section is not Status" 0 '!quotes a count' $K; rs
printf '# P\n\nWork is 3 of 9 complete.\n' > README.md; t "N of M complete anywhere" 1 "'N of M complete'" $K; rs
t "no Status: noted, not failed" 0 'no Status line or section' $K
printf '[project]\nname = "p"\ndescription = "A short description."\n' > pyproject.toml
printf '# P\n\nA short description.\n' > README.md; t "manifest description verbatim" 0 'carries the manifest description verbatim' $K
printf '# P\n\nA shorter, reworded description.\n' > README.md; t "description reworded" 1 'does not carry the manifest description' $K
long=$(printf 'x%.0s' $(seq 121)); printf '[project]\ndescription = "%s"\n' "$long" > pyproject.toml; printf '# P\n\n%s\n' "$long" > README.md; t "description of 121 characters" 1 'is 121 characters' $K
ok120=$(printf 'x%.0s' $(seq 120)); printf '[project]\ndescription = "%s"\n' "$ok120" > pyproject.toml; printf '# P\n\n%s\n' "$ok120" > README.md; t "description of exactly 120 characters" 0 'verbatim \(120 characters\)' $K
printf '[project]\ndescription = "Wrapped across lines: with a link."\n' > pyproject.toml; printf '# P\n\nWrapped across\nlines: with a [link](https://example.org/x)\n' > README.md; t "wrap, link markup and trailing stop tolerated" 0 'verbatim' $K
printf '[project]\ndescription = "Wrapped across lines."\n' > pyproject.toml; printf '# P\n\nWrapped across lines, but then more words.\n' > README.md; t "trailing stop followed by more text still matches" 0 'verbatim' $K
printf '[project]\ndescription = "Wrapped across lines."\n' > pyproject.toml; printf '# P\n\nWrapped across other words.\n' > README.md; t "reworded middle still fails" 1 'does not carry' $K
rm pyproject.toml; printf '[package]\ndescription = "From Cargo."\n' > Cargo.toml; printf '# P\n\nFrom Cargo.\n' > README.md; t "Cargo.toml description" 0 'verbatim' $K; rm Cargo.toml
printf '{\n  "name": "p",\n  "description": "From npm.",\n  "version": "1.0.0"\n}\n' > package.json; printf '# P\n\nOther words.\n' > README.md; t "package.json description mismatch" 1 'does not carry the manifest description' $K; rm package.json; rs
t "no manifest: noted, not failed" 0 'no manifest description' $K
rm lefthook.yml; t "no hook manager" 1 'no hook manager config' $K; rs
rm .git/hooks/pre-push; t "pre-push not installed" 1 'pre-push hook not installed' $K; mkdir -p .git/hooks; printf '#!/bin/sh\n' > .git/hooks/pre-push; chmod +x .git/hooks/pre-push; rs
chmod -x .git/hooks/pre-commit; t "pre-commit not executable" 1 'pre-commit hook not installed' $K; chmod +x .git/hooks/pre-commit
t "note says hooks not proven to pass" 0 'note  hooks are installed, not proven' $K
rm -rf docs/howto; t "docs/howto missing at t2" 1 "docs/howto/ is missing" $K; mkdir -p docs/howto; touch docs/howto/.gitkeep
rm architecture/workspace.dsl; t "no workspace.dsl" 1 'workspace.dsl is missing' $K; echo wd > architecture/workspace.dsl
rm docs/sprints/sprint-0001-plan.md; t "no sprint 1 plan" 1 'sprint-0001-plan' $K; echo s > docs/sprints/sprint-0001-plan.md
sed -i.b 's/^## Current Development Status/## Status/' CLAUDE.md; t "no Current Development Status at t2" 1 'Current Development Status' $K; rs
sed -i.b 's/t2/t1/g' CLAUDE.md; rmdir -p docs/howto 2>/dev/null; rm -f docs/howto/.gitkeep; rmdir docs/howto 2>/dev/null; t "t1 does not require the t2 tree" 0 '!docs/howto|FAIL' $K t1; rs
rm .github/dependabot.yml; t "github remote without dependabot" 1 'dependabot.yml does not' $K; git remote remove github; t "no github remote: dependabot not required" 0 '!dependabot' $K; git remote add github https://github.com/o/r.git; rs
rm SECURITY.md; t "public: no SECURITY.md" 1 'SECURITY.md is missing' $K; rs
sed -i.b 's/security\/advisories\/new//; s/security@example.com//' SECURITY.md; t "public: no private channel" 1 'names no private channel' $K; rs
python3 - <<'PY'
import re
s=open("SECURITY.md").read(); s=re.sub(r"## Scope\n.*","## Scope\n\n[Author-filled — the point of this file.]\n",s,flags=re.S); open("SECURITY.md","w").write(s)
PY
t "public: Scope is the placeholder" 1 'Scope is still the template' $K; rs
python3 - <<'PY'
import re
s=open("SECURITY.md").read(); s=re.sub(r"## Scope\n.*","## Scope\n\nNone really.\n",s,flags=re.S); open("SECURITY.md","w").write(s)
PY
t "public: Scope too short" 1 'under 20 words' $K; rs
sed -i.b 's/## Supported Versions/## Supported {latest-minor}/' SECURITY.md; t "public: leftover {placeholder}" 1 'template placeholders' $K; rs
sed -i.b 's/\*\*Distribution profile\*\*: Public/**Distribution profile**: Private/' CLAUDE.md; t "private profile: SECURITY.md not required" 0 '!public' $K; rm SECURITY.md; t "private profile without SECURITY.md passes" 0 '!FAIL' $K; t "--public forces the check" 1 'SECURITY.md is missing' $K --public; rs
cd /; rm -rf "$T"; mkdir -p /tmp/nb-$$; cd /tmp/nb-$$ || exit 1; t "not a git repo" 1 'not inside a git' $K t0; cd /; rmdir /tmp/nb-$$
echo "failures: $fails"; exit $fails
