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
- PR-body review snapshots (`Current state:`, `Last reviewed by:`); review state is computed from review records and the head commit.
- Files: `skills/shiplog/references/brainstorm-workflow.md`, `skills/shiplog/references/commit-workflow.md`, `skills/shiplog/references/phase-templates.md`, `skills/shiplog/references/pr-workflow.md`.

### Added

- `/shiplog:capture` (`commands/shiplog/capture.md`): save uncaptured discussion and handoff state to the tracking issue.
- `skills/shiplog/scripts/shiplog-read.sh`: reads envelopes first and full text on request. Subcommands `index`, `show`, `source`, `search`; `-R OWNER/REPO` reads another repository. Needs `bash`, `gh`, `git`, and POSIX tools.
- `shiplog/review-gate` commit status (`.github/workflows/review-gate.yml`, `.github/scripts/review-gate.sh`): in `review: cross-model` mode it passes only when a collaborator's review names the PR head commit and declares a reviewer other than every code author. It enforces only when added as a required status check. The decision logic runs on Node.js on the runner.
- Skill files: `skills/shiplog/hunt.md`, `skills/shiplog/models.md`, `skills/shiplog/resume.md`, `skills/shiplog/review.md`, `skills/shiplog/references/records.md` (source-entry and current-summary formats), `skills/shiplog/references/quiet-logging.md`.
- Tests, run in CI by `.github/workflows/ci.yml`: `tests/docs/run.sh` (docs lint), `tests/reader/run.sh` (helper; measurements in `tests/reader/MEASUREMENTS.md`), `tests/review-gate/run.sh` (gate; needs `node`), with their fixtures and cases.
- `.gitignore`, `.gitattributes` (LF for `*.md`, `*.sh`, `*.yml`, `*.json`), `.shiplog/review.md` for this repository, and this changelog.

### Security

- The helper treats a record as a project record only when its GitHub `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`. Envelopes from other accounts are listed as untrusted and their fields are not shown. Each record is framed by a line count, so text inside a body cannot forge another record or its envelope.
- The review gate ignores review evidence from accounts that are not owners, members, or collaborators.

### Migration

- Existing issues, PRs, and envelopes stay readable. Nothing is bulk-rewritten; new entries use the new format.
- An explicit `routing:` value in `.shiplog/routing.md` is kept. Set `warn` or `confirm` to restore prompts.
- Existing `Authored-by:` signatures are left in place. Projects that require signatures keep using `skills/shiplog/references/signing.md`.
- Repositories that want enforced cross-model review add `.shiplog/review.md` and the review-gate workflow.

## Earlier versions

See [GitHub Releases](https://github.com/devallibus/shiplog/releases).
