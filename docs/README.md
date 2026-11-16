<!-- SPDX-FileCopyrightText: 2026 Georges Martin <jrjsmrtn@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Documentation

This documentation follows the [Diátaxis](https://diataxis.fr/) framework, which separates four
kinds of writing because they serve different needs: tutorials (learning by doing), how-to guides
(solving a problem), reference (looking something up) and explanation (understanding why).

A directory appears here when it has something in it.

## Explanation

Background on why the plugin works the way it does. Read these to understand, not to follow steps.

- [Why the skills ship checks, not just instructions](explanation/why-checks-fail-instead-of-instruct.md)
  — why a control is a script that fails rather than a sentence that instructs, and where prose
  is still the right tool.
- [How a check is built and proved](explanation/how-a-check-is-built-and-proved.md)
  — why a script is not trusted because it exists, and how the plugin tests its own checks.
- [How the skills fit together](explanation/how-the-skills-fit-together.md)
  — how the skills are grouped by moment in a project's life, and how this plugin and
  `project-maintenance-skills` divide the work.
- [Why a project grows through tiers](explanation/why-projects-graduate-through-tiers.md)
  — why `bootstrap-project` sets a project up at t0, t1 or t2, and why exposure is a separate
  setting from maturity.
- [Why the hardening skills are tied to one forge](explanation/why-hardening-is-forge-specific.md)
  — why `harden-github-actions` and `harden-gitlab-ci` are siblings and not one skill, and what
  neither covers.

## Elsewhere

- The [README](../README.md) lists the skills and how to install them.
- Each skill's `SKILL.md` in [`skills/`](../skills/) is its working instructions.
