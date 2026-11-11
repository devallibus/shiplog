# Start tracked work

Read the issue summary, relevant sources, and current repository state. Check the linked PR before creating another branch. Follow the project's branch convention. Otherwise use the runtime's default naming convention and include the issue number when useful.

Reuse the correct existing checkout. For parallel work or a dirty main checkout, prefer an isolated worktree. Determine the actual default branch with `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`, then fetch it before creating a new feature branch. Use a different base only for a known dependency or an explicit user request.

Example with values chosen from the repository:

```bash
git fetch origin DEFAULT_BRANCH
git worktree add WORKTREE_PATH -b BRANCH origin/DEFAULT_BRANCH
```

Record the branch and next action in the current summary when that changes useful state. If the project uses lifecycle labels, follow [references/labels.md](references/labels.md). Do not remove its planning label. No routine session-start comment is required.

Capture new user messages through [timeline.md](timeline.md). Read routing guidance only when routing is enabled. Actual delegation uses [references/orchestrator-protocol.md](references/orchestrator-protocol.md) when authorized and useful.
