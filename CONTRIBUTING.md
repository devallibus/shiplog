# Contributing to shiplog

Thanks for contributing. This file covers what a contributor or agent needs before opening a PR.

## Repository layout: one tree, one definition per rule

- Every procedure lives under [`skills/shiplog/`](skills/shiplog/SKILL.md). `SKILL.md` is the core; the files beside it and under `references/` hold the detail. A skill-only install must work from this directory alone.
- `commands/shiplog/*.md` are thin plugin entry points. Each one points to a procedure in `skills/shiplog/`; none restates its rules.
- Each rule is defined in exactly one file. Other files link to it instead of copying it. When you change a rule, change it where it is defined and fix links, not copies.

## Tests

```bash
bash tests/docs/run.sh          # the skill and command docs
bash tests/reader/run.sh        # skills/shiplog/scripts/shiplog-read.sh
bash tests/review-gate/run.sh   # the cross-model review check
```

All three run in CI through [`.github/workflows/ci.yml`](.github/workflows/ci.yml). They run offline and need `bash`, `git`, and POSIX tools; the review-gate suite also needs `node`. On Windows use Git Bash. Shell scripts must keep LF line endings (enforced by `.gitattributes`). The CI and release workflows can also be started manually from the Actions tab.

## Versioning

**shiplog** follows [semver](https://semver.org/). The version lives in `.claude-plugin/plugin.json`. Claude Code's plugin manager and `npx skills` use it to decide whether to refresh installed copies, so without a bump downstream installs never see your change.

### Bump rule

If your PR touches any path under `commands/`, `skills/`, or `.claude-plugin/`, it **must** bump `version` in `.claude-plugin/plugin.json`. [`version-bump-check.yml`](.github/workflows/version-bump-check.yml) enforces this on every PR to the default branch by comparing the base and head versions. PRs that touch only other paths (README, CONTRIBUTING, CHANGELOG, `.github/`, `tests/`, `LICENSE`) do not need a bump.

### Choosing the bump

While on `0.x.y`:

| Change | Bump |
|--------|------|
| New, removed, or renamed command or skill file; new envelope kind, label, or option; changed default behaviour | MINOR (`0.X.0`) |
| Wording changes, doc-only updates, cleanups that keep the documented behaviour | PATCH (`0.x.Y`) |

In `0.x` there is no MAJOR; breaking changes are MINOR (semver §4). After `1.0.0`, breaking changes become MAJOR.

Add a `## X.Y.Z` section to [CHANGELOG.md](CHANGELOG.md) for each version bump; `tests/docs/run.sh` fails when the version in `plugin.json` has none.

### Releases

When a push to the default branch changes the version in `plugin.json`, [`release.yml`](.github/workflows/release.yml) creates tag `vX.Y.Z` at that commit and a GitHub Release with notes generated from the PRs merged since the previous tag. It fails instead of overwriting if the tag already exists.

If the workflow is missing or fails, cut the release manually:

```bash
gh release create vX.Y.Z --notes-file <release-notes-file> --target <default-branch>
```

## Workflow

**shiplog** uses its own workflow; see [`skills/shiplog/SKILL.md`](skills/shiplog/SKILL.md).

- Branch from the default branch as `issue/<id>-<slug>`.
- Commit subjects use `<type>(#<id>): <msg>`, or `<type>(#<id>/<Tn>): <msg>` for a task.
- The PR body describes the final change and its verification and links the discussion; see [`skills/shiplog/pr.md`](skills/shiplog/pr.md). Use `Closes #N` only for full delivery.
- This repository opts into the cross-model review check through [`.shiplog/review.md`](.shiplog/review.md): a PR needs a review, declared as coming from a model other than the author's, that covers its head commit. See [`skills/shiplog/review.md`](skills/shiplog/review.md). Declare each commit's author with an `Authored-by:` or `Co-Authored-By:` trailer, or a model's approval cannot pass the check; a maintainer's human approval needs no trailers. The reviewer's identity is declared, not proven.

## Asking for help

Open an issue describing what you are trying to do.
