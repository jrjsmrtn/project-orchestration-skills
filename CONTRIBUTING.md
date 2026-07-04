# Contributing to project-orchestration-skills

Thanks for your interest in improving **project-orchestration-skills** (AI-assisted project orchestration skills)! This project is a
[Claude Code](https://claude.com/claude-code) plugin made of
[Agent Skills](https://agentskills.io/specification) — Markdown `SKILL.md` instruction
files, not compiled code.

## Development Setup

Clone the repository and install the plugin locally to test changes:

```bash
git clone https://github.com/jrjsmrtn/project-orchestration-skills
# then, inside Claude Code:
/plugin install /path/to/project-orchestration-skills
```

Skills live under `skills/<skill-name>/SKILL.md`. Each skill is a self-contained Markdown
file with YAML frontmatter.

## Skill Conventions

- The skill directory and the `name:` frontmatter are kebab-case and must match.
- License is MIT (`license: MIT` in frontmatter, per the Agent Skills spec).
- Each `SKILL.md` `metadata.version` tracks the plugin version in
  `.claude-plugin/plugin.json` — bump them together.
- The `description` first sentence states what the skill does; the following sentences
  state when it should trigger.

## Making Changes

1. Create a feature branch off `main`.
2. Keep changes focused — one skill or concern per pull request.
3. Update `.claude-plugin/plugin.json` and the affected `SKILL.md` `metadata.version`
   together, following [Semantic Versioning](https://semver.org/). During development,
   bump the patch level (`0.1.x`).
4. Add an entry to `CHANGELOG.md` under `[Unreleased]`.
5. Test by installing the plugin locally and exercising the skill in a target project.

## Reporting Bugs and Proposing Features

- **Bugs** — open an issue describing the skill, the agent behavior you observed, and what
  you expected.
- **Features** — open an issue describing the maintainer situation the new skill or change
  addresses.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
