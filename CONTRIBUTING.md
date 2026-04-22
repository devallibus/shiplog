# Contributing to shiplog

Thanks for contributing. This file documents the project conventions a contributor or AI agent needs to know before opening a PR.

## Versioning

**shiplog** follows [semver](https://semver.org/). The version field that matters lives in `.claude-plugin/plugin.json`. It is the cache key used by Claude Code's plugin manager and by `npx skills add` to decide whether to refresh installed copies — so without a bump, downstream installs never see your change.

### Bump rule

If your PR touches any path under:

- `commands/`
- `skills/`
- `.claude-plugin/`

then your PR **must** include a `version` bump in `.claude-plugin/plugin.json`. CI enforces this (see `.github/workflows/version-bump-check.yml`).

PRs that only touch other paths (README, CONTRIBUTING, `.github/`, `LICENSE`, etc.) do not need a bump.

### Choosing the bump

While we are on `0.x.y`:

| Change | Bump |
|--------|------|
| New slash command, new skill file, new envelope kind, new label, new disposition, removed or renamed slash command, removed skill | MINOR (`0.X.0`) |
| Wording changes inside an existing skill or command, doc-only updates, internal cleanups that preserve the documented surface | PATCH (`0.x.Y`) |

In `0.x` there is no MAJOR — every breaking change is a MINOR per semver §4. Once we declare `1.0.0`, breaking changes become MAJOR and the rule above shifts accordingly.

### Releases

Each version bump on `master` triggers a Git tag and a GitHub Release automatically (see `.github/workflows/release.yml`). The release notes are auto-generated from PRs merged since the previous tag.

If the release workflow is missing or fails, cut the release manually:

```bash
gh release create vX.Y.Z --notes-file <release-notes-file> --target master
```

## Workflow

**shiplog** dogfoods its own workflow. See [`skills/shiplog/SKILL.md`](skills/shiplog/SKILL.md) for the full conventions: ID-first branches, signed artifacts, cross-model review, and evidence-linked closure.

Key contributor expectations:

- Branch from `master` as `issue/<id>-<slug>`.
- Commit subjects use `<type>(#<id>): <msg>` or `<type>(#<id>/<Tn>): <msg>` for task-scoped commits.
- PR body follows the template in [`skills/shiplog/pr.md`](skills/shiplog/pr.md): envelope, summary, journey timeline, changes, verification, knowledge for future reference.
- Sign every shiplog artifact (PR body, signed comments, review comments) with `<role>: <family>/<version> (<tool>)`.
- Cross-model review is required before merge. See [`skills/shiplog/references/closure-and-review.md`](skills/shiplog/references/closure-and-review.md) §3.

## Asking for help

Open an issue with the `shiplog/plan` label and describe what you are trying to do. The maintainer (or the next agent that runs `/shiplog:hunt`) will pick it up.
