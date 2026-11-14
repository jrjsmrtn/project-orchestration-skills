#!/usr/bin/env bash
# scripts/check-containerfile.sh — the mechanical half of setup-container-security.
#   usage: scripts/check-containerfile.sh [file...]     default: every Containerfile*/Dockerfile* under
#                                                        the repo root (3 levels deep); run from the root
#   exit:  0 every check passed | 1 at least one FAILED | 2 no Containerfile found (nothing was checked)
# Per file (instructions are read as logical lines, backslash continuations joined):
#   FROM        every FROM names a digest (@sha256:<64 hex>); `scratch` and an earlier stage are exempt. A
#               ${VARIABLE} base is expanded from its global ARG default (ARG NAME=value before the first
#               FROM) and that is checked; one with no default fails, because it cannot be verified
#   USER        the final stage ends on a USER that is not root or 0; an exception is declared with a
#               comment line `# root-ok: <reason>` in that stage (reported, not failed)
#   RUN         `curl|wget ... | sh|bash` and `sh -c "$(curl ...)"` fail; a RUN that downloads from a URL
#               must verify it in the same RUN (sha256sum/sha512sum/shasum -c, gpg --verify, cosign verify),
#               or sit under a comment line `# unverified-ok: <reason>`; `apt-get install` needs
#               --no-install-recommends
# Per repository: a .dockerignore or .containerignore (beside the file or at the root) that excludes .git
#   and .env; hadolint named in lefthook.yml, .pre-commit-config.yaml or a CI file; .grype.yaml present and
#   grype named in a CI file; a docker ecosystem in .github/dependabot.yml when that file exists.
# Not checked: that a digest is the multi-arch INDEX rather than a per-arch manifest (needs the registry:
#   skopeo inspect --raw docker://IMAGE@DIGEST must say application/vnd.oci.image.index.v1+json), the
#   scan itself, SBOM contents, HEALTHCHECK, and what an ENTRYPOINT does after start.
set -u
fail=0
ok() { echo "ok    $*"; }
bad() {
  echo "FAIL  $*"
  fail=1
}
info() { echo "info  $*"; }

if [ "$#" -gt 0 ]; then
  files="$*"
else files=$(find . -maxdepth 3 \( -name 'Containerfile*' -o -name 'Dockerfile*' \) -type f \
  -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null | sed 's#^\./##' | sort); fi
[ -n "$files" ] || {
  echo "FAIL  no Containerfile or Dockerfile found — nothing was checked" >&2
  exit 2
}

# logical instructions: "start-line<TAB>preceding-comment-or-dash<TAB>text"
logical() {
  awk '
    function flush() { if (buf != "") { print start "\t" (w == "" ? "-" : w) "\t" buf; buf = "" } }
    cont { sub(/^[[:space:]]+/, "", $0); if ($0 ~ /^#/) next
           if ($0 ~ /\\[[:space:]]*$/) { sub(/\\[[:space:]]*$/, "", $0); buf = buf " " $0; next }
           buf = buf " " $0; cont = 0; flush(); prev = ""; next }
    /^[[:space:]]*#/ { prev = $0; next }
    /^[[:space:]]*$/ { prev = ""; next }
    { start = NR; w = prev; prev = ""; line = $0; sub(/^[[:space:]]+/, "", line)
      if (line ~ /\\[[:space:]]*$/) { sub(/\\[[:space:]]*$/, "", line); buf = line; cont = 1; next }
      buf = line; flush() }
    END { flush() }' "$1"
}

for f in $files; do
  [ -f "$f" ] || {
    bad "$f: no such file"
    continue
  }
  stages=" "
  gargs=""
  last_from=0
  user=""
  rootok=""
  nfrom=0
  n_fail_before=$fail
  while IFS=$'\t' read -r n w text; do
    instr=$(printf '%s' "$text" | awk '{print toupper($1)}')
    case "$instr" in
      ARG)
        # global ARGs (before the first FROM) are what a FROM line can expand: remember NAME=default
        if [ "$nfrom" -eq 0 ]; then
          a=$(printf '%s' "$text" | sed -E 's/^[Aa][Rr][Gg][[:space:]]+//; s/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/\1\t\2/')
          gargs="$gargs$a"$'\n'
        fi
        ;;
      FROM)
        nfrom=$((nfrom + 1))
        last_from=$n
        user=""
        rootok=""
        img=""
        alias=""
        prev_tok=""
        for tok in $text; do
          case "$tok" in FROM | from | From) continue ;; --*) continue ;; esac
          if [ -z "$img" ]; then img=$tok; elif [ "$prev_tok" = AS ] || [ "$prev_tok" = as ]; then alias=$tok; fi
          prev_tok=$tok
        done
        # expand ${NAME} / $NAME from the global ARG defaults, repeatedly: a default may name another ARG
        for _pass in 1 2 3 4 5; do
          while IFS=$'\t' read -r an av; do
            [ -n "$an" ] || continue
            av=${av#\"}
            av=${av%\"}
            av=${av#\'}
            av=${av%\'}
            case "$an" in *[!A-Za-z0-9_]*) continue ;; esac
            [ -n "$av" ] || continue # `ARG NAME` (or `ARG NAME=`): no default to expand
            img=${img//\$\{$an\}/$av}
            img=${img//\$$an/$av}
          done <<<"$gargs"
        done
        case "$img" in
          scratch) ;;
          *@sha256:[0-9a-f]*) printf '%s' "$img" | grep -qE '@sha256:[0-9a-f]{64}$' || bad "$f:$n: FROM $img — digest is not 64 hex characters" ;;
          *'$'*) bad "$f:$n: FROM $img — a variable with no default in a global ARG cannot be verified; give it a pinned default or write the digest" ;;
          *) case "$stages" in *" $img "*) ;; *) bad "$f:$n: FROM $img is not pinned by digest (name:tag@sha256:...)" ;; esac ;;
        esac
        [ -z "$alias" ] || stages="$stages$alias "
        ;;
      USER)
        user=$(printf '%s' "$text" | awk '{print $2}')
        ;;
      RUN)
        if printf '%s' "$text" | grep -qE '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(sh|bash|zsh|ash)([[:space:]]|;|&|$)|(sh|bash)[[:space:]]+-c[[:space:]]+["'"'"']?\$\([[:space:]]*(curl|wget)'; then
          bad "$f:$n: pipes a download into a shell (curl | sh)"
        fi
        if printf '%s' "$text" | grep -qE '(curl|wget)[^|;&]*https?://'; then
          if ! printf '%s' "$text" | grep -qE '(sha256sum|sha512sum|sha1sum|shasum|md5sum)[[:space:]]+(-c|--check)|(sha256sum|sha512sum|shasum)[^|;&]*-c([[:space:]]|$)|gpg[[:space:]]+--verify|gpgv|cosign[[:space:]]+verify'; then
            case "$w" in *unverified-ok:*) info "$f:$n: unverified download waived (${w#*unverified-ok:})" ;;
            *) bad "$f:$n: downloads from a URL with no checksum or signature check in the same RUN" ;; esac
          fi
        fi
        if printf '%s' "$text" | grep -qE 'apt(-get)?[[:space:]]+install' && ! printf '%s' "$text" | grep -q -e '--no-install-recommends'; then
          bad "$f:$n: apt-get install without --no-install-recommends"
        fi
        ;;
    esac
  done < <(logical "$f")
  # a root-ok comment may sit anywhere in the final stage, including above USER
  if [ "$nfrom" -eq 0 ]; then
    bad "$f: has no FROM instruction"
  else
    final=$(awk -v s="$last_from" 'NR >= s' "$f")
    printf '%s\n' "$final" | grep -qE '^[[:space:]]*#[[:space:]]*root-ok:' && rootok=$(printf '%s\n' "$final" | sed -nE 's/^[[:space:]]*#[[:space:]]*root-ok:(.*)/\1/p' | head -1)
    case "$user" in
      "" | root | 0 | root:* | 0:*)
        if [ -n "$rootok" ]; then
          info "$f: final stage runs as root, declared acceptable:$rootok"
        else bad "$f: the final stage has no USER, or ends as root (declare an exception with '# root-ok: <reason>' and an ADR)"; fi
        ;;
    esac
  fi
  [ "$fail" -eq "$n_fail_before" ] && ok "$f: base pinned, non-root, no unverified fetch"
done

# ---- repository level
ign=0
for d in . $(for f in $files; do dirname "$f"; done | sort -u); do
  for i in "$d/.dockerignore" "$d/.containerignore"; do
    [ -f "$i" ] || continue
    if grep -qE '^/?\.git/?$' "$i" && grep -qE '^/?\.env(\*|\.\*)?$|^/?\.env\*$' "$i"; then ign=1; fi
  done
done
if [ "$ign" -eq 1 ]; then ok ".dockerignore/.containerignore excludes .git and .env"; else bad "no .dockerignore or .containerignore that excludes both .git and .env"; fi

ci=$({ ls .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml 2>/dev/null; })
hooks=$({ ls lefthook.yml lefthook.yaml .lefthook.yml .pre-commit-config.yaml 2>/dev/null; })
# shellcheck disable=SC2086   # $hooks and $ci are newline lists of plain paths, or empty
if [ -n "$hooks$ci" ] && grep -qs hadolint $hooks $ci; then ok "hadolint is wired (hook or CI)"; else bad "hadolint appears in no lefthook/pre-commit config or CI file"; fi
if [ -f .grype.yaml ] || [ -f .grype.yml ]; then ok ".grype.yaml present"; else bad ".grype.yaml is missing"; fi
# shellcheck disable=SC2086   # $ci is a newline list of plain paths
if [ -n "$ci" ] && grep -qs grype $ci; then ok "grype runs in CI"; else bad "grype appears in no CI file"; fi
if [ -f .github/dependabot.yml ] || [ -f .github/dependabot.yaml ]; then
  if grep -qsE 'package-ecosystem:[[:space:]]*"?docker"?' .github/dependabot.y*ml; then ok "dependabot has a docker ecosystem"; else bad ".github/dependabot.yml has no docker ecosystem for digest bumps"; fi
fi

exit "$fail"
