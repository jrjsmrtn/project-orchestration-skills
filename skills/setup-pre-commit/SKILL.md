---
name: setup-pre-commit
description: DEPRECATED — renamed to setup-git-hooks in 0.1.29. This skill should be used only to redirect; invoke setup-git-hooks instead for configuring two-stage git hooks (pre-commit + pre-push) with either pre-commit or lefthook.
metadata:
  author: "Georges Martin <jrjsmrtn@gmail.com>"
  version: "0.1.42"
license: MIT
---

# Setup Pre-commit Hooks (deprecated)

**This skill was renamed to `setup-git-hooks` in 0.1.29. Invoke that instead.**

Do not follow any procedure from this file. It retains no content — it exists solely so that an
invocation of the old name yields a pointer rather than silence.

## Why it was renamed

The old name was wrong on two axes at once:

- **It named one of the two stages.** The skill's thesis is the two-stage split — fast checks on
  commit, thorough checks on push. The pre-push stage is roughly a third of the content and carries
  the checks that catch the expensive defects.
- **It named one of the two supported hook managers.** The skill documents both `pre-commit` and
  `lefthook`; its "Install Hook Framework" step mentions `lefthook` more often than `pre-commit`, and
  roughly half the skill (`.editorconfig`, secret-detection architecture, `.gitignore` hardening,
  multi-remote protection) involves no hook manager at all.

The practical effect was that maintainers on Elixir, Go or Rust projects read "pre-commit", correctly
inferred "that is the Python hook framework", and never reached the content that had nothing to do
with it.

See workspace ADR-0013.

## Migration

Replace any invocation of `setup-pre-commit` with `setup-git-hooks`. There is no behavioural change —
same workflow, same steps, same outputs.

## Removal

This stub will be removed at **0.2.0**. It exists only for the deprecation window, because the skill,
plugin and marketplace manifests provide no rename, alias or redirect mechanism — content-level
deprecation is the only graceful path the format offers.
