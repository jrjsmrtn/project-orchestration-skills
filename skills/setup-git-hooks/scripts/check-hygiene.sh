#!/usr/bin/env bash
# scripts/check-hygiene.sh — the mechanical half of setup-git-hooks' Step 3 (.gitignore) and its
# "Lockfile and frozen installs" rule.
#   usage: scripts/check-hygiene.sh            run from the repository root
#   exit:  0 every check passed | 1 at least one FAILED
# .gitignore: judged by the tracked file alone in a scratch repository (your global excludes file is not
#   the project's). It must ignore .env .env.local .envrc .envrc.local *.pem *.key credentials.json
#   secrets.yaml CLAUDE.local.md, and must NOT ignore .env.example.
# Lockfiles: for each manifest found (pyproject.toml, mix.exs, Cargo.toml, package.json) a lockfile must
#   be COMMITTED — present in the index, not just on disk, and not git-ignored.
# Frozen installs, in CI files (.github/workflows, .gitlab-ci.yml) and Containerfile*/Dockerfile*, for an
#   ecosystem that has a lockfile: `uv sync` needs --frozen or --locked; `npm install` must be `npm ci`
#   (npm install -g is exempt); `cargo build` needs --locked; `mix deps.get` needs --check-locked. A
#   `COPY` of a lockfile through an optional glob (`mix.lock*`) is a failure: it masks a missing lockfile.
# Not checked: shell scripts the CI calls, other ecosystems (Go, for one), and lines continued across
#   backslashes (the command and its flag are judged on one physical line).
set -u
fail=0
ok() { echo "ok    $*"; }
bad() {
  echo "FAIL  $*"
  fail=1
}
note() { echo "note  $*"; }

git rev-parse --git-dir >/dev/null 2>&1 || {
  echo "FAIL  not inside a git repository"
  exit 1
}
tracked() { git ls-files --error-unmatch -- "$@" >/dev/null 2>&1; }

# ------------------------------------------------------------------ .gitignore
if [ ! -f .gitignore ]; then
  bad ".gitignore is missing"
else
  tmp=$(mktemp -d) && git -C "$tmp" init -q && cp .gitignore "$tmp/.gitignore"
  miss=""
  for p in .env .env.local .envrc .envrc.local server.pem server.key credentials.json secrets.yaml CLAUDE.local.md; do
    git -C "$tmp" -c core.excludesFile=/dev/null check-ignore -q --no-index "$p" 2>/dev/null || miss="$miss $p"
  done
  if git -C "$tmp" -c core.excludesFile=/dev/null check-ignore -q --no-index .env.example 2>/dev/null; then
    bad ".gitignore ignores .env.example, which is meant to be committed (add '!.env.example' after '.env.*')"
  fi
  rm -rf "$tmp"
  if [ -z "$miss" ]; then ok ".gitignore covers the secret-bearing files of Step 3"; else bad ".gitignore does not ignore:$miss"; fi
fi

# ------------------------------------------------------------------ lockfiles
eco=""
lock_check() { # $1 ecosystem key  $2 manifest  $3.. acceptable lockfiles
  local key=$1 manifest=$2
  shift 2
  [ -f "$manifest" ] || return 0
  local found="" l
  for l in "$@"; do
    if tracked "$l"; then
      found=$l
      break
    fi
  done
  if [ -n "$found" ]; then
    ok "$manifest has a committed lockfile ($found)"
    eco="$eco $key"
    return 0
  fi
  for l in "$@"; do
    if [ -f "$l" ]; then
      if git check-ignore -q "$l" 2>/dev/null; then
        bad "$manifest: $l exists but is git-ignored — commit it"
      else bad "$manifest: $l exists but is not committed (git add it)"; fi
      eco="$eco $key"
      return 0
    fi
  done
  bad "$manifest has no committed lockfile (one of: $*)"
  eco="$eco $key"
}
lock_check uv pyproject.toml uv.lock poetry.lock pdm.lock pylock.toml
lock_check mix mix.exs mix.lock
lock_check cargo Cargo.toml Cargo.lock
lock_check npm package.json package-lock.json pnpm-lock.yaml yarn.lock
[ -n "$eco" ] || note "no pyproject.toml, mix.exs, Cargo.toml or package.json: no lockfile to check"

# ------------------------------------------------------------------ frozen installs
files=$({
  ls .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml 2>/dev/null
  ls Containerfile* Dockerfile* 2>/dev/null
  find . -maxdepth 3 \( -name 'Containerfile*' -o -name 'Dockerfile*' \) -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null | sed 's#^\./##'
} | sort -u)
has() { case " $eco " in *" $1 "*) return 0 ;; *) return 1 ;; esac }
# (grep -e below: an exemption pattern such as --locked must not be read as an option)
scan() { # $1 ecosystem  $2 message  $3 grep -E pattern for the offending line  $4 grep -E pattern that EXEMPTS a line
  has "$1" || return 0
  local f hits
  for f in $files; do
    [ -f "$f" ] || continue
    hits=$(grep -nE "$3" "$f" | grep -vE '^[0-9]+:[[:space:]]*#' | { if [ -n "${4:-}" ]; then grep -vE -e "$4"; else cat; fi; })
    [ -z "$hits" ] || { while IFS= read -r h; do bad "$f:${h%%:*}: $2 — $(printf '%s' "${h#*:}" | sed -E 's/^[[:space:]]+//')"; done <<<"$hits"; }
  done
}
scan uv "uv sync without --frozen or --locked" 'uv sync' '(--frozen|--locked)'
scan npm "npm install in CI/container, use npm ci" 'npm (install|i)([[:space:]]|$)' '(npm (install|i) .*(-g|--global)|npm ci)'
scan cargo "cargo build without --locked" 'cargo build' '--locked'
scan mix "mix deps.get without --check-locked" 'mix deps\.get' '--check-locked'
if has mix || has npm || has cargo || has uv; then
  for f in $files; do
    case "$f" in */Containerfile* | */Dockerfile* | Containerfile* | Dockerfile*) ;; *) continue ;; esac
    hits=$(grep -nE '^[[:space:]]*COPY[[:space:]].*(mix\.lock|package-lock\.json|Cargo\.lock|uv\.lock|yarn\.lock)\*' "$f" | grep -vE '^[0-9]+:[[:space:]]*#')
    [ -z "$hits" ] || { while IFS= read -r h; do bad "$f:${h%%:*}: COPY of a lockfile through an optional glob masks a missing lockfile — $(printf '%s' "${h#*:}" | sed -E 's/^[[:space:]]+//')"; done <<<"$hits"; }
  done
fi
[ -n "$files" ] || note "no CI workflow or Containerfile found: frozen installs not checked"

[ "$fail" -eq 0 ] && ok "all checks passed"
exit "$fail"
