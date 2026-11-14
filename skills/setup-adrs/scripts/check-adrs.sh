#!/usr/bin/env bash
# scripts/check-adrs.sh — the mechanical half of setup-adrs' Validation.
#   usage: scripts/check-adrs.sh [adr-dir]        (default docs/adr; run from the repository root)
#   exit:  0 every check passed | 1 at least one FAILED
# Per ADR file: NNNN-kebab-title.md; first line "# N. Title" with N equal to the file number (the adr-tools
# form Structurizr's !adrs needs); a real, not-future "Date: YYYY-MM-DD"; a "## Status" with a recognised
# value; "## Context", "## Decision" and "## Consequences"; no template placeholder left in the text.
# Per directory: no README.md or other non-ADR markdown; numbers unique, 0001-0003 present (gaps warn);
# ADR-0003 mentions alternatives; an Operations ADR-0004 only when CLAUDE.md's Category is Infrastructure
# or Hybrid (a Development project's ADR-0004 may be any decision); index.yml present and accurate for
# the foundational ADRs (file exists, id, title and status agree with the ADR).
# Not checked: that ADR-0002 fits the project's stack, or that ADR-0003's reasoning is sound.
set -u
DIR="${1:-docs/adr}"
fail=0
ok() { echo "ok    $*"; }
bad() {
  echo "FAIL  $*"
  fail=1
}
warn() { echo "WARN  $*"; }
# first_file PATH...: print the first argument that exists (a glob that matched nothing stays literal)
first_file() {
  local f
  for f in "$@"; do
    if [ -e "$f" ]; then
      printf '%s\n' "$f"
      return 0
    fi
  done
  return 0
}

[ -d "$DIR" ] || {
  bad "$DIR is not a directory"
  exit 1
}

valid_date() { # YYYY-MM-DD, a real calendar date
  case "$1" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) return 1 ;; esac
  local y=${1:0:4} m=$((10#${1:5:2})) d=$((10#${1:8:2})) max
  [ "$m" -ge 1 ] && [ "$m" -le 12 ] && [ "$d" -ge 1 ] || return 1
  local dim=(0 31 28 31 30 31 30 31 31 30 31 30 31)
  max=${dim[$m]}
  if [ "$m" -eq 2 ] && { [ $((y % 400)) -eq 0 ] || { [ $((y % 4)) -eq 0 ] && [ $((y % 100)) -ne 0 ]; }; }; then max=29; fi
  [ "$d" -le "$max" ]
}
today=$(date +%Y-%m-%d)
PLACEHOLDERS='\[(YYYY-MM-DD|Project name|project name|Project Name|Technology Stack|technology stack|technology-stack-name|specific technical domain|other key technologies|pros|cons|Option [ABC]|Requirement [0-9]+|Reason [0-9]+ with evidence|Trade-off [0-9]+|Benefit [0-9]+|Risk and mitigation|Author-filled[^]]*)\]'

numbers=""
tab=$(mktemp)
trap 'rm -f "$tab"' EXIT                                                       # num<TAB>title<TAB>status<TAB>file (no bash-4 associative arrays: macOS ships 3.2)
lookup() { awk -F'\t' -v n="$1" -v c="$2" '$1 == n {print $c; exit}' "$tab"; } # $1 number, $2 column 2=title 3=status 4=file
for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  if ! printf '%s' "$base" | grep -qE '^[0-9]{4}-[a-z0-9][a-z0-9-]*\.md$'; then
    bad "$base: not an ADR file name (NNNN-kebab-title.md) — the adrtools importer fails on non-ADR markdown in $DIR"
    continue
  fi
  n=${base:0:4}
  num=$((10#$n))
  numbers="${numbers:+$numbers$'\n'}$num"
  title=""
  status=""
  # first line of content: skip blank lines and a leading HTML comment (an SPDX/REUSE header)
  line1=$(awk 'c { if (index($0, "-->")) c = 0; next }
               /^[[:space:]]*<!--/ { if (!index($0, "-->")) c = 1; next }
               /[^[:space:]]/ { print; exit }' "$f")
  if printf '%s' "$line1" | grep -qE "^# $num\. .+"; then
    title=$(printf '%s' "$line1" | sed -E "s/^# $num\. //")
  else bad "$base: first line is '$line1', expected '# $num. Title'"; fi
  d=$(sed -nE 's/^Date: *([^ ]*).*/\1/p' "$f" | head -1)
  if [ -z "$d" ]; then
    bad "$base: no 'Date: YYYY-MM-DD' line"
  elif ! valid_date "$d"; then
    bad "$base: '$d' is not a real YYYY-MM-DD date"
  elif [[ "$d" > "$today" ]]; then bad "$base: date $d is in the future (today is $today)"; fi
  st=$(awk '/^## Status/{f=1;next} f&&NF{print;exit}' "$f")
  word=$(printf '%s' "$st" | sed -E 's/^[*_` ]+//' | grep -oE '^[A-Za-z]+') # "**Accepted** on 2026-09-11." -> Accepted
  if printf '%s' "$word" | grep -qE '^(Proposed|Accepted|Rejected|Deprecated|Superseded|Amended)$'; then
    status=$word
  else bad "$base: '## Status' is missing or not Proposed/Accepted/Rejected/Deprecated/Superseded/Amended (got '${st:-nothing}')"; fi
  printf '%s\t%s\t%s\t%s\n' "$num" "$title" "$status" "$base" >>"$tab"
  for sec in Context Decision Consequences; do grep -qE "^## $sec" "$f" || bad "$base: no '## $sec' section"; done
  if hit=$(grep -nE "$PLACEHOLDERS" "$f"); then
    bad "$base: template placeholder left in the text:"
    echo "$hit" | head -3 | sed 's/^/        /'
  fi
done

[ -n "$numbers" ] || {
  bad "no ADR files in $DIR"
  exit 1
}
sorted=$(printf '%s\n' "$numbers" | sort -n)
dups=$(printf '%s\n' "$sorted" | uniq -d | tr '\n' ' ')
if [ -z "$dups" ]; then ok "ADR numbers are unique"; else bad "duplicate ADR numbers: $dups"; fi
for want in 1 2 3; do printf '%s\n' "$sorted" | grep -qx "$want" || bad "ADR-$(printf %04d $want) is missing"; done
max=$(printf '%s\n' "$sorted" | tail -1)
gaps=""
for ((i = 1; i <= max; i++)); do printf '%s\n' "$sorted" | grep -qx "$i" || gaps="$gaps $(printf %04d $i)"; done
[ -z "$gaps" ] || warn "gaps in the numbering:$gaps"

f3=$(first_file "$DIR"/0003-*.md)
if [ -n "$f3" ]; then
  if grep -qiE 'alternative|options? considered|considered options' "$f3"; then
    ok "ADR-0003 mentions the alternatives considered"
  else bad "ADR-0003 does not mention alternatives or options considered"; fi
fi

cat=""
[ -f CLAUDE.md ] && cat=$(sed -nE 's/.*\*\*Category\*\*: *([A-Za-z]+).*/\1/p' CLAUDE.md | head -1)
f4=$(first_file "$DIR"/0004-*.md)
case "$cat" in
  Infrastructure | Hybrid) if [ -n "$f4" ]; then ok "ADR-0004 exists (Category: $cat)"; else bad "Category is $cat but ADR-0004 (operations) does not exist"; fi ;;
  Development) if [ -n "$f4" ] && grep -qiE '^# 4\. .*operations' "$f4"; then bad "Category is Development but ADR-0004 is an operations ADR"; fi ;;
  *) warn "CLAUDE.md states no Category: whether ADR-0004 is required was not checked" ;;
esac

idx="$DIR/index.yml"
if [ ! -f "$idx" ]; then
  bad "$idx is missing"
else
  recs=$(awk '
    /^[[:space:]]*#/ {next}
    /^[[:space:]]*- id:/ { if (have) print id "\t" file "\t" title "\t" status
      have=1; id=$0; sub(/^[[:space:]]*- id:[[:space:]]*/,"",id); sub(/[[:space:]]+$/,"",id); file="-"; title="-"; status="-"; next }
    have && /^[[:space:]]+file:/   { v=$0; sub(/^[[:space:]]+file:[[:space:]]*/,"",v);   sub(/[[:space:]]+$/,"",v); file=v; next }
    have && /^[[:space:]]+title:/  { v=$0; sub(/^[[:space:]]+title:[[:space:]]*/,"",v);  sub(/[[:space:]]+$/,"",v); gsub(/^["\047]|["\047]$/,"",v); title=v; next }
    have && /^[[:space:]]+status:/ { v=$0; sub(/^[[:space:]]+status:[[:space:]]*/,"",v); sub(/[[:space:]]+$/,"",v); status=v; next }
    END { if (have) print id "\t" file "\t" title "\t" status }' "$idx")
  listed=" "
  while IFS=$'\t' read -r id file title status; do
    [ -n "$id" ] || continue
    listed="$listed$id "
    if [ ! -f "$DIR/$file" ]; then
      bad "index.yml: entry $id names '$file', which does not exist"
      continue
    fi
    fn=$((10#${file:0:4}))
    [ "$id" = "$fn" ] || bad "index.yml: '$file' is listed with id $id, but its number is $fn"
    at=$(lookup "$fn" 2)
    as=$(lookup "$fn" 3)
    [ "$title" = "$at" ] || bad "index.yml: '$file' title '$title' differs from the ADR's '$at'"
    [ "$(printf '%s' "$status" | sed -E 's/^[*_` ]+//; s/[^A-Za-z].*$//')" = "$as" ] || bad "index.yml: '$file' status '$status' differs from the ADR's '$as'"
  done <<<"$recs"
  [ -n "$recs" ] || bad "index.yml has no '- id:' entries"
  for want in 1 2 3; do
    case "$listed" in *" $want "*) ;; *) bad "index.yml does not list ADR-$(printf %04d $want)" ;; esac
  done
  for n in $sorted; do case "$listed" in *" $n "*) ;; *) [ "$n" -gt 3 ] && warn "index.yml does not list ADR-$(printf %04d "$n") ($(lookup "$n" 4))" ;; esac done
fi

[ "$fail" -eq 0 ] && ok "all checks passed"
exit "$fail"
