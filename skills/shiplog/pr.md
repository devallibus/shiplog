# Open or update a PR

Inspect the branch diff and relevant checks. Capture unsaved discussion through [timeline.md](timeline.md), then push and create or update the PR within the user's authorized scope.

Write for someone who has not read the conversation. Describe the problem, resulting behavior, checks, and limits. Link to the discussion rather than copying its timeline or commit list. Use `Closes #N` only for full delivery; use `Addresses #N` with the completed scope for partial delivery.

```markdown
<!-- shiplog:
kind: history
summary: Brief description of the resulting change.
-->

## Change
The problem and resulting behavior, with a discussion link when useful.

## Verification
Checks run, results, and remaining limits.

Closes #N
```

Use `gh pr create --title TITLE --body-file FILE` or `gh pr edit N --body-file FILE`. Preserve unrelated existing content when editing. Record the PR link and next action in the issue summary. If lifecycle labels are in use, follow [references/labels.md](references/labels.md).

Follow [review.md](review.md) and [references/closure-and-review.md](references/closure-and-review.md) for the project's review and merge requirements. Do not copy review state into several envelopes and body sections. Link evidence when needed. Requested quiet logging is covered by [references/pr-workflow.md](references/pr-workflow.md).
