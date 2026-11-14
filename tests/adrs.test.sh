#!/usr/bin/env bash
# usage: tests-adrs.sh "RUNNER SCRIPT"      e.g.  tests-adrs.sh "/bin/bash /path/check-adrs.sh"
K=$1; fails=0
t(){ name=$1; want=$2; pat=$3; shift 3; out=$("$@" 2>&1); rc=$?; res=PASS; [ $rc -eq $want ] || res="BAD-RC($rc)"
  if [ "${pat:0:1}" = "!" ]; then echo "$out" | grep -qE "${pat:1}" && res="$res+UNEXPECTED-MATCH"; else echo "$out" | grep -qE "$pat" || res="$res+MISSING-MATCH"; fi
  echo "$res  $name"; [ "$res" = PASS ] || { fails=$((fails+1)); echo "$out" | grep -E '^(FAIL|WARN|        )' | head -5 | sed 's/^/      /'; }; }
# scratch: a fresh temporary directory, entered. Refuses to continue anywhere else: an empty $T makes `cd ""`
# succeed in bash 3.2, and these suites run `git reset --hard` and `git clean -fd`.
scratch() {
  T=$(mktemp -d) || exit 1
  [ -d "$T" ] || exit 1
  cd "$T" || exit 1
}
scratch; git init -q -b main; mkdir -p docs/adr
adr(){ # n title status date
  printf '# %s. %s\n\nDate: %s\n\n## Status\n\n%s\n\n## Context\n\nWe need X.\n\n## Decision\n\nWe will do Y.\n\n**Alternatives Considered**: Z was rejected.\n\n## Consequences\n\nFine.\n' "$1" "$2" "$4" "$3" > "docs/adr/$(printf %04d "$1")-$5.md"; }
adr 1 "Record Architecture Decisions" Accepted 2026-01-02 record-architecture-decisions
adr 2 "Adopt Development Best Practices" Accepted 2026-01-02 adopt-development-best-practices
adr 3 "Use Go and Cobra" Accepted 2026-01-03 use-go-and-cobra
adr 4 "Operations Best Practices" Accepted 2026-01-04 operations-best-practices
cat > docs/adr/index.yml <<'Y'
# Architecture Decision Records
foundational:
  - id: 1
    file: 0001-record-architecture-decisions.md
    title: Record Architecture Decisions
    purpose: HOW TO DECIDE
    status: Accepted
  - id: 2
    file: 0002-adopt-development-best-practices.md
    title: Adopt Development Best Practices
    status: Accepted
  - id: 3
    file: 0003-use-go-and-cobra.md
    title: "Use Go and Cobra"
    status: Accepted
  - id: 4
    file: 0004-operations-best-practices.md
    title: Operations Best Practices
    status: Accepted
Y
printf '# P\n\n- **Category**: Hybrid\n' > CLAUDE.md
snap=$(mktemp -d); cp -R docs CLAUDE.md "$snap"/; rs(){ rm -rf docs CLAUDE.md; cp -R "$snap"/docs "$snap"/CLAUDE.md .; }
t "good" 0 'all checks passed' $K
t "bad file name" 1 'not an ADR file name' bash -c "cd $T; cp docs/adr/0001-record-architecture-decisions.md docs/adr/ADR-5.md; $K"; rs
echo "# readme" > docs/adr/README.md; t "README.md inside docs/adr" 1 'README.md: not an ADR file name' $K; rs
cp docs/adr/0002-adopt-development-best-practices.md docs/adr/0002-other.md; t "duplicate number" 1 'duplicate ADR numbers: 2' $K; rs
rm docs/adr/0002-*.md; t "ADR-0002 missing" 1 'ADR-0002 is missing' $K; rs
rm docs/adr/0003-*.md; t "ADR-0003 missing" 1 'ADR-0003 is missing' $K; rs
cp docs/adr/0004-operations-best-practices.md docs/adr/0006-x.md; sed -i.b 's/^# 4\./# 6./' docs/adr/0006-x.md; t "gap in numbering is a warning, not a failure" 0 'WARN  gaps in the numbering: 0005' $K; rs
sed -i.b 's/^# 3\. /# 7. /' docs/adr/0003-use-go-and-cobra.md; t "heading number differs from file" 1 "expected '# 3. Title'" $K; rs
sed -i.b 's/^# 3\. /## 3. /' docs/adr/0003-use-go-and-cobra.md; t "not an adr-tools heading" 1 "expected '# 3" $K; rs
sed -i.b 's/^Date: .*/Date: 2026-02-30/' docs/adr/0001-record-architecture-decisions.md; t "impossible date" 1 "'2026-02-30' is not a real" $K; rs
sed -i.b 's/^Date: .*/Date: 2099-01-01/' docs/adr/0001-record-architecture-decisions.md; t "future date" 1 'in the future' $K; rs
sed -i.b 's/^Date: .*/Date: [YYYY-MM-DD]/' docs/adr/0001-record-architecture-decisions.md; t "template date" 1 "not a real YYYY-MM-DD" $K; rs
sed -i.b '/^Date:/d' docs/adr/0001-record-architecture-decisions.md; t "no date line" 1 "no 'Date" $K; rs
sed -i.b 's/^Date: .*/Date: 2024-02-29/' docs/adr/0001-record-architecture-decisions.md; t "leap-day 2024-02-29 is real" 0 '!is not a real' $K; rs
sed -i.b 's/^Date: .*/Date: 2026-02-29/' docs/adr/0001-record-architecture-decisions.md; t "2026-02-29 is not" 1 'is not a real' $K; rs
sed -i.b 's/^Accepted$/Maybe/' docs/adr/0002-adopt-development-best-practices.md; t "unknown status" 1 "got 'Maybe'" $K; rs
sed -i.b 's/^## Consequences/## Fallout/' docs/adr/0002-adopt-development-best-practices.md; t "no Consequences section" 1 "no '## Consequences'" $K; rs
sed -i.b 's/We need X\./We need [Project name] to work./' docs/adr/0002-adopt-development-best-practices.md; t "template placeholder left" 1 'template placeholder left' $K; rs
sed -i.b 's/Alternatives Considered/Notes/; s/Z was rejected/nothing/' docs/adr/0003-use-go-and-cobra.md; t "ADR-0003 without alternatives" 1 'ADR-0003 does not mention alternatives' $K; rs
rm docs/adr/0004-*.md; sed -i.b '/id: 4/,$d' docs/adr/index.yml; t "Hybrid needs ADR-0004" 1 'ADR-0004 \(operations\) does not exist' $K; rs
printf '# P\n\n- **Category**: Development\n' > CLAUDE.md; t "Development with an operations ADR-0004" 1 'Development but ADR-0004 is an operations' $K
sed -i.b 's/^# 4\. .*/# 4. Extract the tool from dotfiles/' docs/adr/0004-operations-best-practices.md; sed -i.b 's/title: Operations Best Practices/title: Extract the tool from dotfiles/' docs/adr/index.yml; t "Development with a non-operations ADR-0004 is fine" 0 '!Development but' $K; rs
rm CLAUDE.md; t "no CLAUDE.md: warning only" 0 'WARN  CLAUDE.md states no Category' $K; rs
sed -i.b 's/^Accepted$/Accepted./' docs/adr/0002-adopt-development-best-practices.md; t "status with a trailing period matches the index" 0 '!FAIL' $K; rs
sed -i.b 's/^Accepted$/**Accepted** on 2026-01-02, as recommended./' docs/adr/0002-adopt-development-best-practices.md; t "bold status with a date" 0 '!FAIL' $K; rs
printf '<!--\nSPDX-FileCopyrightText: 2026 Example\nSPDX-License-Identifier: Apache-2.0\n-->\n\n' | cat - docs/adr/0001-record-architecture-decisions.md > /tmp/adr1-$$ && mv /tmp/adr1-$$ docs/adr/0001-record-architecture-decisions.md; t "SPDX comment before the heading" 0 '!FAIL' $K; rs
printf '<!-- one line comment -->\n' | cat - docs/adr/0001-record-architecture-decisions.md > /tmp/adr1-$$ && mv /tmp/adr1-$$ docs/adr/0001-record-architecture-decisions.md; t "one-line comment before the heading" 0 '!FAIL' $K; rs
sed -i.b 's/^## Status/## Status\n\nAccepted/; ' docs/adr/0002-adopt-development-best-practices.md; rs
rm docs/adr/index.yml; t "no index.yml" 1 'index.yml is missing' $K; rs
sed -i.b 's/file: 0003-use-go-and-cobra.md/file: 0003-gone.md/' docs/adr/index.yml; t "index names a missing file" 1 "names '0003-gone.md'" $K; rs
sed -i.b 's/- id: 3/- id: 9/' docs/adr/index.yml; t "index id disagrees with the file" 1 'listed with id 9' $K; rs
sed -i.b 's/title: Operations Best Practices/title: Ops/' docs/adr/index.yml; t "index title disagrees" 1 "title 'Ops' differs" $K; rs
python3 - <<'PY'
s=open("docs/adr/index.yml").read(); open("docs/adr/index.yml","w").write(s.replace("status: Accepted","status: Proposed",1))
PY
t "index status disagrees" 1 "status 'Proposed' differs" $K; rs
python3 - <<'PY'
import re
s=open("docs/adr/index.yml").read(); s=re.sub(r"  - id: 2\n.*?  - id: 3","  - id: 3",s,flags=re.S); open("docs/adr/index.yml","w").write(s)
PY
t "index omits a foundational ADR" 1 'does not list ADR-0002' $K; rs
printf '# idx\n' > docs/adr/index.yml; t "index with no entries" 1 "no '- id:' entries" $K; rs
cp docs/adr/0004-operations-best-practices.md docs/adr/0005-extra.md; sed -i.b 's/^# 4\./# 5./' docs/adr/0005-extra.md; t "unlisted non-foundational ADR is only a warning" 0 'WARN  index.yml does not list ADR-0005' $K; rs
cd /; rm -rf "$T" "$snap"; mkdir -p /tmp/na-$$; cd /tmp/na-$$ || exit 1; t "no docs/adr" 1 'is not a directory' $K; mkdir -p docs/adr; t "empty docs/adr" 1 'no ADR files' $K; cd /; rm -rf /tmp/na-$$
echo "failures: $fails"; exit $fails
