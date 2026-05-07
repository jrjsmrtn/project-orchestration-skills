<!-- SPDX-FileCopyrightText: 2025 Georges Martin <jrjsmrtn@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# AI-Assisted Project Orchestration Skills

A Claude Code plugin providing skills for AI-assisted project orchestration, following best practices for software development lifecycle, architecture documentation, and quality automation.

## Installation

### Claude Code

Install via the [jrjsmrtn-skills](https://github.com/jrjsmrtn/jrjsmrtn-skills) marketplace:

```
/plugin install github:jrjsmrtn/jrjsmrtn-skills
```

### Mistral Vibe

[Mistral Vibe](https://mistral.ai/products/vibe) scans `~/.vibe/skills/` as a flat directory. Bridge this plugin's nested layout via clone + symlink:

```bash
mkdir -p ~/.vibe/claude-skills ~/.vibe/skills
git clone https://github.com/jrjsmrtn/project-orchestration-skills.git ~/.vibe/claude-skills/project-orchestration-skills
cd ~/.vibe/skills
for skill_dir in ~/.vibe/claude-skills/project-orchestration-skills/skills/*/; do
  skill=$(basename "$skill_dir")
  ln -s "../claude-skills/project-orchestration-skills/skills/${skill}" "${skill}"
done
```

Update later: `git -C ~/.vibe/claude-skills/project-orchestration-skills pull`.

## Included Skills

### Project Inception

| Skill | Description |
|-------|-------------|
| **analyze-project** | SPARK methodology analysis for new project inception |
| **bootstrap-project** | Bootstrap a new project with foundational artifacts |
| **setup-adrs** | Create foundational Architecture Decision Records |

### Architecture & Documentation

| Skill | Description |
|-------|-------------|
| **setup-architecture-as-code** | Establish C4 modeling with Structurizr DSL |

### Quality Automation

| Skill | Description |
|-------|-------------|
| **setup-pre-commit** | Configure two-stage pre-commit hooks |
| **validate-quality-config** | Validate consistency across quality configs |

### Sprint Workflow

| Skill | Description |
|-------|-------------|
| **plan-sprint** | Create sprint plans with backlog and goals |
| **wrapup-sprint** | Complete sprints with retrospective and release |

## Usage

After installation, invoke skills using slash commands:

```
/analyze-project
/bootstrap-project
/setup-adrs
/setup-architecture-as-code
/setup-pre-commit
/validate-quality-config
/plan-sprint
/wrapup-sprint
```

Or reference them naturally in conversation - Claude will activate the appropriate skill based on context.

## Related Project

This plugin is extracted from the [AI-Assisted Project Orchestration](https://github.com/jrjsmrtn/ai-assisted-project-orchestration) pattern language project, which documents patterns for effective AI-human collaboration in software project management.

## License

MIT
