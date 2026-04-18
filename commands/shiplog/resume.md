---
allowed-tools: Bash(gh:*), Bash(git:*), Read
description: Resume a shiplog work session on the current branch
---

Re-orient to the current branch and issue. Load the task list, identify where work stopped, post a session-resume comment, and recommend the next action.

## Policy

**Branch detection:** parse the issue number from the current branch name using the `issue/<id>-<slug>` convention. If the current branch does not match, check `git worktree list` for a shiplog branch and offer to switch.

**Session-resume comment:** every resumed session must post a `[shiplog/session-resume]` comment on the issue. This is distinct from `[shiplog/session-start]` — it marks a continuation, not a first start. The comment must include the last commit, uncommitted changes summary, remaining tasks, and where work was left off.

**Triage field sync:** if the issue body `tasks_complete` is out of date relative to the checked checkboxes in the task list, update it in place (no `Updated-by:` needed for triage fields).

**Open blockers:** if any previous `[shiplog/blocker]` comments exist without a corresponding resolution, surface them in the report before recommending the next task.

## Query / Template

### Detect issue from branch

```bash
git branch --show-current
# Parse: issue/<N>-<slug>  →  N is the issue number
```

### Load issue context

```bash
gh issue view <N> --json title,body,labels,comments
```

Scan comments for: `[shiplog/session-start]`, `[shiplog/session-resume]`, `[shiplog/blocker]`, `[shiplog/commit-note]`.

### Check for linked PRs

```bash
gh pr list --state open --head "issue/<N>-*" --json number,title,url
```

### Session-resume comment template

```markdown
[shiplog/session-resume] #<N>: Resuming work

**Branch:** `<branch-name>`
**Last commit:** `<hash> <subject>`
**Uncommitted changes:** <yes/no — summary if yes>
**Tasks remaining:** <list of unchecked tasks>
**Picking up from:** <1-2 sentences on where work stopped>

Authored-by: <family>/<version> (<tool>)
```

Post with:
```bash
gh issue comment <N> --body-file <temp-file>
```

### Retrieve prior session commits

```bash
git log --oneline --grep="#<N>"
```

## Acceptance Checklist

- [ ] Issue number parsed from current branch name
- [ ] Issue body and comments loaded; task completion status current
- [ ] Open blockers from prior sessions surfaced before recommending next task
- [ ] Session-resume comment posted with last-commit, uncommitted-changes status, remaining tasks, and `Authored-by:` sig
- [ ] If tasks_complete is stale, issue body updated in place
- [ ] Next recommended task is the first unchecked task that matches agent tier
