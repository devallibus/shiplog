---
allowed-tools: Bash(gh:*), Bash(git:*), Read
description: Resume a shiplog work session on the current branch
---

## Context

- Current branch: !`git branch --show-current`
- Existing worktrees: !`git worktree list`
- Recent commits on this branch: !`git log --oneline -10`
- Uncommitted changes: !`git status --short`

## Your Task

You are resuming a shiplog work session (Phase 2 continuation + Phase 7 timeline update).

### Step 1: Detect the Issue

Parse the issue number from the current branch name (`issue/<number>-<slug>`).

If the branch doesn't match the shiplog convention, check if there's a worktree with a shiplog branch and offer to switch to it.

### Step 2: Load Issue Context

```
gh issue view <number> --json title,body,labels,comments
```

Read the issue body for:
- Task list and completion status
- Recent timeline comments (session starts, milestones, blockers)
- Any open blockers

Also check for linked PRs:
```
gh pr list --state open --head "issue/<number>-*" --json number,title,url
```

### Step 3: Post Session-Resume Comment

Post a timeline comment on the issue:

```
[shiplog/session-resume] #<number>: Resuming work

**Branch:** `<branch-name>`
**Last commit:** `<hash> <subject>`
**Uncommitted changes:** <yes/no + summary>
**Tasks remaining:** <list of unchecked tasks>
**Picking up from:** <brief summary of where we left off>

Authored-by: <model-family>/<model-version> (<tool>)
```

### Step 4: Report

Show the user:
- Issue title and number
- Tasks completed vs remaining
- Any blockers from previous sessions
- Recommended next task to work on
- Any open PRs for this issue

Keep it brief -- the user wants to get back to work quickly.
