#!/usr/bin/env bash
# usage: extract-script.sh SKILL.md NAME   — print the fenced bash block whose second line is "# scripts/NAME ".
# The shipped script is the one embedded in the SKILL.md, so the tests run that text, not a copy.
awk -v n="# scripts/$2 " '
  /^```bash/ {buf=""; inb=1; first=1; next}
  inb && /^```/ {if (hit) {printf "%s", buf; exit} inb=0; hit=0; next}
  inb {buf=buf $0 "\n"; if (index($0, n)==1) hit=1}
' "$1"
