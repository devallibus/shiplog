# Changelog

## 0.6.0

Simplification of the skill ([#166](https://github.com/devallibus/shiplog/issues/166)). Defaults change; see Migration.

### Changed

- `SKILL.md` is a short core built around three records: the original discussion kept verbatim, one current summary on the tracking issue, and a small retrieval index (envelope).
- Model-tier routing defaults to `off` when unset (was `confirm`).
- PR bodies describe the final change and its verification and link the discussion, instead of a journey timeline.
- Slash commands in `commands/shiplog/` are thin entry points to procedures in `skills/shiplog/`; a skill-only install is complete.
- Cross-model review is an explicit option, checked by a GitHub Action against the PR head commit, instead of a rule stated for every PR. Reviewer identity is declared, not proven.
- Quiet mode is an optional quiet-logging extension.

### Removed

- Mandatory session-start and resume comments.
- Mandatory model signatures on routine notes (speaker attribution on copied discussion stays).
- Stored task counts and other copies of derived state in envelopes; counts are computed from checkboxes.
- Procedure text duplicated between `commands/` and `skills/`.

### Added

- `skills/shiplog/references/records.md`: source-entry and current-summary formats.
- `skills/shiplog/scripts/shiplog-read.sh`: reads envelopes first and full text on request (`index`, `show`, `source`, `search`). Needs only `gh`, `git`, and POSIX tools.
- Tests under `tests/`, run in CI by `.github/workflows/ci.yml`.
- `.gitignore`, `.gitattributes` (LF for `*.md`, `*.sh`, `*.yml`, `*.json`), and this changelog.

### Migration

- Existing issues, PRs, and envelopes stay readable. Nothing is bulk-rewritten; new entries use the new format.
- An explicit `routing:` value in `.shiplog/routing.md` is kept. Set `warn` or `confirm` to restore prompts.
- Existing `Authored-by:` signatures are left in place. Projects that require signatures keep using `skills/shiplog/references/signing.md`.
- Repositories that want enforced cross-model review add `.shiplog/review.md` and the review-gate workflow.

## Earlier versions

See [GitHub Releases](https://github.com/devallibus/shiplog/releases).
