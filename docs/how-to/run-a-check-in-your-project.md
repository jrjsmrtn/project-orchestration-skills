<!-- SPDX-FileCopyrightText: 2026 Georges Martin <jrjsmrtn@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# How to run a check in your project

Use this when a skill's Validation section tells you to run a script, or when you want to know whether a
project meets one of the plugin's controls. It takes a few minutes per script.

You need a shell and the project's repository. Some scripts need more, and say so in their header: for
example `check-action-pins.sh` needs an authenticated `gh`, and `check-gitlab-pins.sh` needs mikefarah `yq` v4.

## 1. Find the script

The [script reference](../reference/scripts.md) lists every shipped check with its usage, exit codes and what it
does not cover. Each skill's Validation section names the one that belongs to it.

## 2. Copy it into your project

Copy the script from the skill's `scripts/` directory into your project's `scripts/` directory. Do not retype
it, and do not paste it from a page: the copy is the one that was tested.

```bash
mkdir -p scripts
cp path/to/skills/setup-adrs/scripts/check-adrs.sh scripts/
```

`cp` keeps the executable bit. If you got the file some other way, run `chmod +x scripts/check-adrs.sh`.

## 3. Run it from the repository root

Most scripts read paths relative to the repository root, and their headers say "run from the repository root". Run them from there:

```bash
scripts/check-adrs.sh
```

On a project that is missing things, the output looks like this (from a test project with one decision record
that lacks a date):

```text
FAIL  0001-record-architecture-decisions.md: no 'Date: YYYY-MM-DD' line
ok    ADR numbers are unique
FAIL  ADR-0002 is missing
FAIL  ADR-0003 is missing
WARN  CLAUDE.md states no Category: whether ADR-0004 is required was not checked
FAIL  docs/adr/index.yml is missing
```

In this script each line starts with `ok`, `WARN` or `FAIL`, so you can see which check said what.

## 4. Read the exit code

The exit code is the result. Zero means every check passed. Non-zero means something needs your attention.

| Code | Meaning |
|---|---|
| 0 | Every check passed. |
| 1 | At least one check failed. |
| 2 | The script could not do its job, for scripts that define it. |

Treat 2 as a failure, not a pass. A script that could not run did not check anything. The scripts that use it say
so in their headers, for example "2, not 0, when it cannot run or finds no `uses:`". Not every script has a 2, so
read the usage in the [script reference](../reference/scripts.md) for the one you are running.

A `WARN` does not change the exit code in `check-adrs.sh`, `check-action-pins.sh` or `check-gitlab-pins.sh`, which count only failures. Read it anyway: it flags something the script could not settle.

## 5. Fix, then run it again

Fix what the output names and run the script again until it exits 0. A green result proves only what the script
asserts. Each header lists what it does not check, and those parts are still yours. See
[Why the skills ship checks, not just instructions](../explanation/why-checks-fail-instead-of-instruct.md).

## 6. Make it run without you

A check you run by hand gets forgotten. The skill that ships it says where to wire it. For example,
[`setup-git-hooks`](../../skills/setup-git-hooks/SKILL.md) shows the hygiene check in a pre-push hook, and
[`harden-github-actions`](../../skills/harden-github-actions/SKILL.md) shows the pin check as a CI step. A hook can
be skipped with `--no-verify`, so a CI step is the one that holds.

## If the answer looks wrong

If a script passes something it should fail, or fails something that is fine, that is a defect in the script. Run
it again on a copy of the smallest example you can, and report it as
[CONTRIBUTING](../../CONTRIBUTING.md) says. The fix is a new case in the script's test suite. See
[How a check is built and proved](../explanation/how-a-check-is-built-and-proved.md).

## Related

- [Script reference](../reference/scripts.md): usage and exit codes for every script.
