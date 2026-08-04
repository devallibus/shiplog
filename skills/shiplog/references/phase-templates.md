# Phase Templates

This file is retained as a compatibility pointer after the phase-template split.

Template content now lives with the phase-specific sub-skills:
- `../brainstorm.md` for issue creation and task contracts
- `../branch.md` for session-start and delegation handoffs
- `../commit.md` for commit-context comments
- `../pr.md` for PR body templates and partial-delivery variants
- `../timeline.md` for timeline, implementation-issue, milestone, blocker, and closure artifacts
- `../discovery.md` for discovery issues and blocker cross-reference comments
- `../lookup.md` for retrieval and triage-scan output formats
- `orchestrator-protocol.md` for fan-out dispatch, collection summaries, and worktree cleanup
- `closure-and-review.md` for review sign-off format, dispositions (approve, approve-with-follow-ups, request-changes, comment), and follow-up capture rules

See `../SKILL.md` and the phase files above for the current canonical workflow.

## Signature block convention

Every artifact template in the files above ends with a pre-filled signature block so the emitting LLM can copy it verbatim and fill in only the `<family>/<version>` fields:

```
Authored-by: <family>/<version> (<tool>)
```

For PR bodies and code-push artifacts:

```
Authored-by: <family>/<version> (<tool>)
Last-code-by: <family>/<version> (<tool>)
```

For review sign-off comments, use the four-field block defined in `closure-and-review.md` ("Sign-off format"), which owns it. This file intentionally does not duplicate it.

For in-place edits to existing artifacts (append after the original `Authored-by:` line):

```
Updated-by: <family>/<version> (<tool>)
Edit-kind: correction | amendment | rewrite
Edit-note: [1 sentence describing what changed and why]
```

The full signing rules and amendment artifact template live in `../SKILL.md` → "Agent Identity Signing".
