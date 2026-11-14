#!/usr/bin/env bash
# usage: tests-hygiene.sh "RUNNER SCRIPT"
K=$1; fails=0
t(){ name=$1; want=$2; pat=$3; shift 3; out=$("$@" 2>&1); rc=$?; res=PASS; [ $rc -eq $want ] || res="BAD-RC($rc)"
  if [ "${pat:0:1}" = "!" ]; then echo "$out" | grep -qE "${pat:1}" && res="$res+UNEXPECTED-MATCH"; else echo "$out" | grep -qE "$pat" || res="$res+MISSING-MATCH"; fi
  echo "$res  $name"; [ "$res" = PASS ] || { fails=$((fails+1)); echo "$out" | grep -E '^(FAIL|note)' | head -5 | sed 's/^/      /'; }; }
T=$(mktemp -d); cd "$T"; git init -q -b main; git config user.email t@example.com; git config user.name t; git config commit.gpgsign false; git config core.hooksPath /dev/null
printf '.env\n.env.*\n!.env.example\n.envrc\n.envrc.local\n*.pem\n*.key\ncredentials.json\nsecrets.yaml\nCLAUDE.local.md\n' > .gitignore
printf '[project]\nname="p"\n' > pyproject.toml; echo l > uv.lock
echo 'defmodule M do end' > mix.exs; echo l > mix.lock
printf '[package]\nname="c"\n' > Cargo.toml; echo l > Cargo.lock
echo '{}' > package.json; echo '{}' > package-lock.json
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'Y'
jobs:
  b:
    steps:
      - run: uv sync --frozen
      - run: npm ci
      - run: npm install -g pnpm
      - run: cargo build --locked
      - run: mix deps.get --check-locked
      # - run: npm install
Y
cat > Containerfile <<'Y'
FROM scratch
COPY mix.exs mix.lock ./
RUN npm ci && uv sync --locked
Y
git add -A; git commit -qm init; base=$(git rev-parse HEAD)
rs(){ git reset -q --hard $base; git clean -qfd; }
t "good" 0 'all checks passed' $K
# --- gitignore
printf '.env\n' > .gitignore; t ".gitignore gaps" 1 'does not ignore: .*CLAUDE.local.md' $K; rs
printf '.env\n.env.*\n.envrc\n.envrc.local\n*.pem\n*.key\ncredentials.json\nsecrets.yaml\nCLAUDE.local.md\n' > .gitignore; t ".env.example ignored (no negation)" 1 'ignores .env.example' $K; rs
rm .gitignore; t "no .gitignore" 1 '.gitignore is missing' $K; rs
printf '.env\n.env.*\n!.env.example\n.envrc\n.envrc.local\n*.pem\n*.key\ncredentials.json\nCLAUDE.local.md\n' > .gitignore
printf '[core]\n\texcludesFile = %s/gi\n' "$T" > "$T/../gc-$$"; echo 'secrets.yaml' > "$T/gi"
t "gap hidden by a global excludes file must still FAIL" 1 'does not ignore: secrets.yaml' env GIT_CONFIG_GLOBAL="$T/../gc-$$" $K; rm -f "$T/../gc-$$" "$T/gi"; rs
# --- lockfiles
git rm -q --cached uv.lock; rm uv.lock; git commit -qam x; t "uv.lock absent" 1 'pyproject.toml has no committed lockfile' $K; rs
git rm -q --cached mix.lock; git commit -qm x; t "mix.lock on disk but untracked" 1 'mix.lock exists but is not committed' $K; rs
git rm -q --cached Cargo.lock; echo Cargo.lock >> .gitignore; git commit -qam x; t "Cargo.lock git-ignored" 1 'Cargo.lock exists but is git-ignored' $K; rs
git rm -q package-lock.json; git commit -qm x; t "package-lock.json absent" 1 'package.json has no committed lockfile' $K; rs
git rm -q uv.lock; echo l > poetry.lock; git add poetry.lock; git commit -qm x; t "poetry.lock accepted for pyproject" 0 '!FAIL' $K; rs
git rm -q package-lock.json; echo l > pnpm-lock.yaml; git add pnpm-lock.yaml; git commit -qm x; t "pnpm lock accepted for package.json" 0 '!FAIL' $K; rs
git rm -q mix.exs mix.lock; git commit -qm x; t "no mix.exs: mix.lock not required" 0 '!mix' $K; rs
# --- frozen installs
sed -i.b 's/uv sync --frozen/uv sync/' .github/workflows/ci.yml; t "uv sync unfrozen" 1 'ci.yml:[0-9]+: uv sync without' $K; rs
sed -i.b 's/uv sync --frozen/uv sync --locked/' .github/workflows/ci.yml; t "uv sync --locked is fine" 0 '!FAIL' $K; rs
sed -i.b 's/npm ci$/npm install/' .github/workflows/ci.yml; t "npm install in CI" 1 'use npm ci' $K; rs
t "npm install -g and a commented npm install are exempt" 0 '!use npm ci' $K
sed -i.b 's/cargo build --locked/cargo build --release/' .github/workflows/ci.yml; t "cargo build unlocked" 1 'cargo build without --locked' $K; rs
sed -i.b 's/mix deps.get --check-locked/mix deps.get/' .github/workflows/ci.yml; t "mix deps.get unlocked" 1 'mix deps.get without --check-locked' $K; rs
sed -i.b 's/RUN npm ci/RUN npm install/' Containerfile; t "npm install in a Containerfile" 1 'Containerfile:[0-9]+: npm install' $K; rs
sed -i.b 's/COPY mix.exs mix.lock/COPY mix.exs mix.lock*/' Containerfile; t "COPY mix.lock* glob" 1 'optional glob' $K; rs
printf 'default:\n  script:\n    - cargo build\n' > .gitlab-ci.yml; git add -A; git commit -qm x; t ".gitlab-ci.yml is scanned" 1 'gitlab-ci.yml:[0-9]+: cargo build' $K; rs
git rm -q Cargo.lock Cargo.toml; sed -i.b 's/cargo build --locked/cargo build/' .github/workflows/ci.yml; git commit -qam x; t "unlocked cargo is ignored when there is no Cargo project" 0 '!cargo build without' $K; rs
printf '    - run: cargo build  # --locked would go here\n' >> .github/workflows/ci.yml; t "a flag mentioned only in a trailing comment still exempts (known limit)" 0 '!FAIL' $K; rs
cd /; rm -rf "$T"; mkdir -p /tmp/nh-$$ && cd /tmp/nh-$$ && t "not a git repo" 1 'not inside a git' $K; cd /; rmdir /tmp/nh-$$
T=$(mktemp -d); cd "$T"; git init -q -b main; git config user.email t@example.com; git config user.name t; git config core.hooksPath /dev/null; printf '.env\n.env.*\n!.env.example\n.envrc\n.envrc.local\n*.pem\n*.key\ncredentials.json\nsecrets.yaml\nCLAUDE.local.md\n' > .gitignore; echo r > README.md; git add -A; git commit -qm i
t "no manifest and no CI: notes only" 0 'no pyproject.toml.*no lockfile to check' $K; t "...and says frozen installs were not checked" 0 'no CI workflow or Containerfile' $K; cd /; rm -rf "$T"
echo "failures: $fails"; exit $fails
