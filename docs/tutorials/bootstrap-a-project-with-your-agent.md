<!-- SPDX-FileCopyrightText: 2026 Georges Martin <jrjsmrtn@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Bootstrap your first project with your agent

In this tutorial you will ask your coding agent to set up a new project with the `bootstrap-project` skill, then
check its work yourself. It takes about fifteen minutes. At the end you will have a small project at tier t0,
and you will know how to tell whether the agent did what it said.

You need Claude Code with this plugin installed (the [README](../../README.md) shows how), `git`, and an empty
folder to work in.

This page is a worked example, not a transcript. An agent's output changes from run to run, so yours will differ
in wording and detail. It is based on one real run, on 2026-11-17, and says where that run surprised its author.

## 1. Make an empty project folder

```bash
mkdir hello && cd hello
git init -b main
```

## 2. Ask for the bootstrap

Start Claude Code in the folder and say what you want, the way you would to a colleague:

> Bootstrap this new project at tier t0. It is a small command-line tool called hello that prints a greeting.
> Public or private is not decided yet.

You name the tier, say what the project is, and say what you have not decided. The tiers are explained in
[Why a project grows through tiers](../explanation/why-projects-graduate-through-tiers.md). t0 is the smallest.

## 3. Watch what it does

The agent should load the `bootstrap-project` skill, look at the folder and its git state, and then write files.
In the run this page is based on it:

- wrote two files, `.gitignore` and `CLAUDE.md`;
- made one commit, `chore: bootstrap project at tier t0`;
- ran the skill's check, `check-bootstrap.sh`, and reported that it passed;
- asked you nothing, and chose nothing you had not decided.

That last point matters. Stack, licence and public-or-private were all left open. `CLAUDE.md` recorded the stack
and licence as "not chosen yet", and recorded the project as Private, which is the skill's default while that is
undecided.

## 4. Do not take "it passed" on trust

The agent told you the check passed. You can run it yourself and read the result. The check should live in the
project, so look first:

```bash
ls scripts/
```

If `check-bootstrap.sh` is there, run it from the project root:

```bash
scripts/check-bootstrap.sh
echo "exit=$?"
```

You should see:

```text
ok    [t0] at least one conventional commit
ok    [t0] CLAUDE.md states 'Current tier: **t0**'
ok    [t0] .gitignore covers .env, *.pem, *.key, credentials.json, CLAUDE.local.md
exit=0
```

Exit code 0 means every check passed. The [how-to guide](../how-to/run-a-check-in-your-project.md) explains the
other codes.

### If the check is not in the project

The skill tells the agent to copy the script into the project. In the run this page is based on, that copy was
blocked by a permission prompt, so the agent ran the script from the plugin's own folder and said so in its
summary. If that happens to you, ask the agent to copy the script into `scripts/` once you approve it. The script
only reads files, so running it from either place gives the same result.

That run left one thing to fix. Because the script was not in the project, the Quick Commands section of the
generated `CLAUDE.md` held a placeholder path, `<project-orchestration-skills>/skills/bootstrap-project/scripts/check-bootstrap.sh`.
That is not a command you can run. Once the script is in `scripts/`, change that line to
`scripts/check-bootstrap.sh`, or ask the agent to.

## 5. Read what it made

Open `CLAUDE.md`. In the run this page is based on it held these sections:

- **Project Context**: category, type, stack, licence, tier and distribution profile.
- **Project Tier**: the line `Current tier: **t0**`, which the check reads, and the triggers for moving up.
- **Status**: a dated line saying the project was bootstrapped and has no code yet.
- **Development Practices**: the commit style, versioning and branching.
- **Quick Commands**, and **AI Collaboration Notes**.

Two lines to look at closely. The Distribution profile says Private, and says going Public is a deliberate step.
The tier triggers list the moments to move up to t1, for example a second contributor joining.

## 6. Break it on purpose

A check that has only ever passed is unproven. Take one line out of `.gitignore`:

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

The check names exactly what you removed. Put it back:

```bash
git checkout .gitignore
scripts/check-bootstrap.sh > /dev/null; echo "exit=$?"
```

```text
exit=0
```

If you want to see how a check fails and is fixed step by step, without an agent, follow
[How a check works, by hand](how-a-check-works-by-hand.md).

## What you did

You asked an agent to set up a project, read what it produced, ran the check yourself, and saw the check fail when
you broke something. The agent's report is a claim. The check's exit code is the evidence.

## Next steps

- When the project outgrows t0, ask your agent to promote it. The skill describes promotion as mechanical, not
  archaeological: the t0 files are already the foundation.
- To run other checks, see [How to run a check in your project](../how-to/run-a-check-in-your-project.md) and the
  [script reference](../reference/scripts.md).
- To understand the choices the agent made, read
  [Why the skills ship checks, not just instructions](../explanation/why-checks-fail-instead-of-instruct.md).
