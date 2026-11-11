# shiplog

**shiplog** keeps a project's discussion, decisions, and work context in GitHub issues and PRs, so you can recall what you said and the next agent session can pick up the work. It is a skill (plain markdown instructions) for Claude Code, Codex, and Cursor, for people who plan and build with coding agents and want that history to outlive the chat window.

## Install

```bash
npx skills add devallibus/shiplog --skill shiplog
```

The skill directory is self-contained: a skill-only install has every procedure it needs. Add `--agent claude-code`, `--agent codex`, or `--agent cursor` to target one agent; run `npx skills update` to refresh.

As a Claude Code plugin, which also adds the slash commands `/shiplog:plan`, `start`, `commit`, `pr`, `lookup`, `hunt`, `resume`, `review`, and `models`:

```bash
/plugin marketplace add devallibus/shiplog
/plugin install shiplog@shiplog
```

From a local checkout: `claude --plugin-dir .`. The slash commands are short entry points to the same procedures in [`skills/shiplog/`](skills/shiplog/SKILL.md); plain requests ("save this idea", "resume #42") work without them.

## What you get: three records

**1. The original discussion, verbatim.** Your messages are copied in order, unedited, with who said them and who recorded them. Rejected ideas and doubts stay in. Corrections are added as new entries; earlier wording is never rewritten. A source entry, posted as an issue comment:

````markdown
<!-- shiplog:
kind: source
summary: User wants their own words kept, not only a summary.
-->
Source: Codex session, messages 2-3. Recorded by: assistant.
Coverage: available messages only.

### Message 2
Speaker: user

```text
but i wouldn't want to lose the things i said as a human, you know
```
````

**2. One current summary** in the tracking issue body: goal, current decisions (each linked to its source entry), tasks, checks, and next action. It is edited when facts change, not appended to.

```markdown
<!-- shiplog:
kind: state
summary: Simplify the skill while keeping the user's original words.
-->
## Goal
A small core that preserves human discussion and compact retrieval.
## Current decisions
- Routing stays as an option, off by default ([source](#issuecomment-...)).
## Tasks
- [x] T1: Capture discussion verbatim
- [ ] T2: Make resume read the summary first
## Next action
Implement T2.
```

**3. A small retrieval index.** New records start with the short `<!-- shiplog: -->` envelope shown above. The helper [`skills/shiplog/scripts/shiplog-read.sh`](skills/shiplog/scripts/shiplog-read.sh) returns those compact fields first, and full text only when the question needs it:

```bash
shiplog-read.sh index           # envelopes of open issues and PRs
shiplog-read.sh show 42         # current summary of #42
shiplog-read.sh source 42       # verbatim source entries on #42
shiplog-read.sh search "auth"   # search the original text
```

Task counts are computed from the checkboxes; no copies of derived state are stored. Byte and API-call measurements for the helper are in [`tests/reader/MEASUREMENTS.md`](tests/reader/MEASUREMENTS.md).

## A day with it

1. "Save this idea": the discussion becomes an issue with a source entry. No branch needed.
2. "Work on #42": the agent reads the summary, checks the real branch and diff, and starts a branch.
3. At checkpoints and before a handoff, new discussion and decisions are captured and the summary updated.
4. Commits follow your convention; `fix(#42): ...` helps lookup. No comment per commit.
5. The PR describes the final change, its checks and limits, and links the discussion.
6. Next week, "what did I say about auth?" or "resume #42" reads the index, then the source text.

No mandatory session announcements, and no mandatory model signatures on routine notes.

## Options (all off by default)

| Option | What it does | Turn it on |
|---|---|---|
| Model-tier routing | Suggests a model tier at phase changes: `off`, `warn` (banner), or `confirm` (ask first). Advisory only. | `/shiplog:models` or `.shiplog/routing.md` |
| Cross-model review | A GitHub Action checks that a review declared by a different model covers the PR's head commit. | [`.shiplog/review.md`](.shiplog/review.md) and [`review-gate.yml`](.github/workflows/review-gate.yml); see [review.md](skills/shiplog/review.md) |
| Verification profiles | Project or issue test policies such as `red-green` or `behavior-spec`. | `.shiplog/verification.md`; see [profiles](skills/shiplog/references/verification-profiles.md) |
| Lifecycle labels | `shiplog/ready`, `shiplog/in-progress`, `shiplog/needs-review`. | See [labels.md](skills/shiplog/references/labels.md) |
| Quiet logging | Keeps the work log on a separate branch, off the PR. | Ask for it; see [quiet-logging.md](skills/shiplog/references/quiet-logging.md) |

Without the review option, **shiplog** follows the review your repository already uses: native GitHub reviews, Codex review, or a human.

## What it does not do

- It cannot capture messages the runtime does not show the agent. Known gaps are recorded, not reconstructed.
- Model identity on a review is declared, not proven. The check confirms a review covers the head commit; it cannot confirm which model wrote it.
- It is instructions an agent follows, not a daemon or service. Nothing runs unless an agent is working.
- It does not protect branches. Use GitHub required checks for that.

## Requirements

- [`gh`](https://cli.github.com/), authenticated with `gh auth login`
- `git`, in a repository with a GitHub remote
- POSIX shell tools for the helper (Git Bash works on Windows)

## Upgrading from 0.5 and earlier

- Old issues, PRs, and envelopes stay readable. Nothing is bulk-rewritten; only new entries use the new format.
- Routing defaults to `off` when unset (it was `confirm`). An explicit setting in `.shiplog/routing.md` is kept.
- Model signatures (`Authored-by:`) are optional; existing ones are left alone. See [signing.md](skills/shiplog/references/signing.md) if your project requires them.
- Session-start and resume comments, PR journey timelines, and stored task counts are no longer written.
- Cross-model review is an opt-in, CI-checked option instead of an unenforced rule on every PR.
- Quiet mode is now the optional quiet-logging extension.

Details: [CHANGELOG.md](CHANGELOG.md).

## Contributing and licence

See [CONTRIBUTING.md](CONTRIBUTING.md) for the versioning rule, tests, and repository layout. MIT; see [LICENSE](LICENSE).
