# AI-Assisted Project Orchestration Skills

Claude Code plugin providing 8 skills for AI-assisted project orchestration.

## Project Structure

```
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, description, keywords)
skills/
  <skill-name>/
    SKILL.md           # Skill definition (frontmatter + markdown body)
```

## Skill File Format

Each `SKILL.md` follows the [Agent Skills specification](https://agentskills.io/specification) with YAML frontmatter:

```yaml
---
name: <skill-name>
description: <one-line description>. <when-to-use sentences>.
license: MIT
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.x"
---
```

- `name` must match the directory name
- `description` is the trigger: first sentence describes what it does, subsequent sentences describe when to use it
- `license` is the spec-defined license field (replaces prior SPDX comment headers)
- `metadata.version` tracks with the parent plugin's `version` in `plugin.json`
- Body follows a consistent structure: title, When to Use, Required Inputs, Workflow (phased steps), Outputs (checklist), Validation, Related Skills

## Skills Overview

| Skill | Phase |
|-------|-------|
| analyze-project | Inception (SPARK methodology) |
| bootstrap-project | Inception (scaffolding + initial roadmap) |
| setup-adrs | Inception (architecture decisions) |
| setup-architecture-as-code | Architecture (C4/Structurizr) |
| setup-pre-commit | Quality (two-stage hooks) |
| validate-quality-config | Quality (config consistency) |
| plan-sprint | Sprint workflow (planning, minimal or structured) |
| wrapup-sprint | Sprint workflow (retrospective, minimal or expanded) |

## Development Conventions

- Version: 0.1.x during development (semantic versioning)
- License: MIT, declared via `license: MIT` in every SKILL.md frontmatter (per Agent Skills spec)
- Skill names are kebab-case
- Skills reference each other via `Related Skills` sections
- Skills are designed to run in the target project's working directory, not in this plugin repo
- The plugin is extracted from the [AI-Assisted Project Orchestration](https://github.com/jrjsmrtn/ai-assisted-project-orchestration) pattern language project

## Installation

Installation requires a marketplace — install via [jrjsmrtn-skills](https://github.com/jrjsmrtn/jrjsmrtn-skills).

## Remotes

- origin: private git server
- github: https://github.com/jrjsmrtn/project-orchestration-skills
