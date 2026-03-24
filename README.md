# AI-Assisted Project Orchestration Skills

A Claude Code plugin providing skills for AI-assisted project orchestration, following best practices for software development lifecycle, architecture documentation, and quality automation.

## Installation

### Direct Installation

```
/plugin install github:jrjsmrtn/project-orchestration-skills
```

### Via Project Settings

Add to your project's `.claude/settings.json`:

```json
{
  "plugins": [
    "github:jrjsmrtn/project-orchestration-skills"
  ]
}
```

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
