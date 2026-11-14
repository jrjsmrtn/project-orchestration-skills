#!/usr/bin/env bash
# Every row of the plan's "## De-risk" table must end in a verdict: viable, reshaped or rejected.
#   usage: scripts/check-derisk.sh docs/sprints/sprint-NNNN-plan.md
# Exit: 0 section present, >=1 row, every row has a verdict | 1 otherwise | 2 no such file
set -u
f="${1:-}"
[ -f "$f" ] || {
  echo "FAIL: no such plan '$f'" >&2
  exit 2
}
grep -q '^## De-risk' "$f" || {
  echo "FAIL: $f has no '## De-risk' section" >&2
  exit 1
}
rows=$(awk '/^## De-risk/{s=1;next} /^## /{s=0} s && /^\|/ && !/^\|[-: |]+\|$/' "$f" | tail -n +2) # drop the header row
[ -n "$rows" ] || {
  echo "FAIL: '## De-risk' has no rows — state one, or 'none: <reason>' as a row" >&2
  exit 1
}
bad=$(printf '%s\n' "$rows" | grep -viE '\|[[:space:]]*(viable|reshaped|rejected)[[:space:]]*\|?[[:space:]]*$' || true)
if [ -n "$bad" ]; then
  echo "FAIL: De-risk rows without a verdict (viable | reshaped | rejected):" >&2
  printf '%s\n' "$bad" >&2
  exit 1
fi
echo "De-risk: $(printf '%s\n' "$rows" | grep -c .) row(s), each with a verdict"
