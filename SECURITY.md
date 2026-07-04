# Security Policy

## Reporting a Vulnerability

If you discover a security issue in this project, please report it **privately**:

- Email: jrjsmrtn@gmail.com
- Or open a private [GitHub Security Advisory](https://github.com/jrjsmrtn/project-orchestration-skills/security/advisories/new)

Please do **not** open a public issue for security reports. You can expect an initial
response within 7 days. Once an issue is confirmed, a fix will be prepared and a
coordinated disclosure arranged.

## Supported Versions

This project follows [Semantic Versioning](https://semver.org/). Security fixes are
applied to the latest released version.

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Scope

This project is distributed as [Agent Skills](https://agentskills.io/specification) /
plugin metadata for AI coding agents. It ships **no executable runtime and declares no
package dependencies**. The primary security considerations are the integrity of the
distributed content and the safety of any commands the skills instruct an agent to run.
