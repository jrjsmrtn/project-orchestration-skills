<!-- SPDX-FileCopyrightText: 2026 Georges Martin <jrjsmrtn@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# How a check works, by hand

In this tutorial you will make a tiny project, run one of the plugin's checks against it, watch it fail, fix
what it names, and watch it pass. It takes about ten minutes. At the end you will have seen the loop every
check in this plugin follows.

You need a shell, `git`, and a copy of this repository to take the script from. Nothing else is installed.

The check is `check-bootstrap.sh` from `bootstrap-project`. Normally your agent runs the skill and the check for
you: see [Bootstrap your first project with your agent](bootstrap-a-project-with-your-agent.md). Here you make the
files by hand, because the point is to watch the check work, not to set a project up.

## 1. Make a project and copy the check in

```bash
mkdir hello && cd hello
git init -b main
mkdir scripts
cp path/to/skills/bootstrap-project/scripts/check-bootstrap.sh scripts/
```

Replace `path/to` with where your copy of this repository is. If `git` later asks who you are, set
`user.name` and `user.email` first.

## 2. Run it with nothing set up

```bash
scripts/check-bootstrap.sh
echo "exit=$?"
```

You should see:

```text
FAIL  tier unknown: pass t0|t1|t2, or state 'Current tier: **tN**' in CLAUDE.md
exit=2
```

The check does not know which tier to test, so it stopped. The exit code is 2, not 1: it could not do its job,
which is different from doing it and finding a problem. A check that could not run did not pass.

## 3. Tell it the tier, and see what is missing

Tell it to check tier t0, the smallest one:

```bash
scripts/check-bootstrap.sh t0
echo "exit=$?"
```

```text
FAIL  [t0] no commits yet
FAIL  [t0] CLAUDE.md is missing
FAIL  [t0] .gitignore is missing
exit=1
```

Now it ran, and it found three things. Exit code 1 means at least one check failed.

## 4. Fix two of them

Create the two files it named:

```bash
printf '# hello\n\n## Project Tier\n\nCurrent tier: **t0**\n' > CLAUDE.md
printf '.env\n.env.local\n*.pem\n*.key\ncredentials.json\nCLAUDE.local.md\n' > .gitignore
```

Run the check again. This time you do not need to say `t0`, because `CLAUDE.md` now states it:

```bash
scripts/check-bootstrap.sh
```

```text
FAIL  [t0] no commits yet
ok    [t0] CLAUDE.md states 'Current tier: **t0**'
ok    [t0] .gitignore covers .env, *.pem, *.key, credentials.json, CLAUDE.local.md
```

Two checks are now `ok`. One is left.

## 5. Fix the last one

The check wants at least one commit whose subject follows the conventional form, `type: subject`:

```bash
git add .
git commit -m "chore: start the project"
scripts/check-bootstrap.sh
echo "exit=$?"
```

```text
ok    [t0] at least one conventional commit
ok    [t0] CLAUDE.md states 'Current tier: **t0**'
ok    [t0] .gitignore covers .env, *.pem, *.key, credentials.json, CLAUDE.local.md
exit=0
```

Exit code 0: every check passed. You have a project that meets tier t0.

## 6. Break it on purpose

A check that has only ever passed is unproven. Take a line out of `.gitignore` and see whether the check notices:

```bash
sed -i.bak '/^\.env$/d' .gitignore && rm .gitignore.bak
scripts/check-bootstrap.sh
echo "exit=$?"
```

```text
ok    [t0] at least one conventional commit
ok    [t0] CLAUDE.md states 'Current tier: **t0**'
FAIL  [t0] .gitignore does not ignore: .env
exit=1
```

It names the exact thing you removed. Put it back and confirm it passes again:

```bash
git checkout .gitignore
scripts/check-bootstrap.sh > /dev/null; echo "exit=$?"
```

```text
exit=0
```

## 7. Look one tier up

Ask for tier t1, the next one:

```bash
scripts/check-bootstrap.sh t1
```

```text
ok    [t0] at least one conventional commit
FAIL  [t0] CLAUDE.md does not state 'Current tier: **t1**' under ## Project Tier
ok    [t0] .gitignore covers .env, *.pem, *.key, credentials.json, CLAUDE.local.md
FAIL  [t1] CHANGELOG.md is missing or has no '## [Unreleased]' section
ok    [t1] branch main exists
FAIL  [t1] branch develop does not exist
FAIL  [t1] docs/adr/0001-*.md is missing
FAIL  [t1] docs/adr/0002-*.md is missing
FAIL  [t1] docs/adr/0003-*.md is missing
FAIL  [t1] README.md is missing
FAIL  [t1] no hook manager config (lefthook.yml or .pre-commit-config.yaml)
```

That list is what moving from t0 to t1 adds: a changelog, a `develop` branch, three decision records, a README
and a hook configuration. You do not need to fix it now.

## What you did

You ran a check, read its exit code, fixed what it named until it passed, and broke it on purpose to see it fail.
Every script in the [script reference](../reference/scripts.md) works the same way.

## Next steps

- To run a different check on a real project, follow
  [How to run a check in your project](../how-to/run-a-check-in-your-project.md).
- To see what each tier contains and why they exist, read
  [Why a project grows through tiers](../explanation/why-projects-graduate-through-tiers.md).
- To set a real project up, use the [`bootstrap-project`](../../skills/bootstrap-project/SKILL.md) skill, which
  writes these files and more for you.
