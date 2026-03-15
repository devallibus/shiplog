---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write, Skill
description: Create a branch and worktree from a GitHub issue, start a work session
argument-hint: <issue-number>
---

## Context

- Repo: !`gh repo view --json nameWithOwner --jq '.nameWithOwner'`
- Current branch: !`git branch --show-current`
- Default branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Existing worktrees: !`git worktree list`

## Your Task

You are executing shiplog Phase 2: Issue-to-Branch.

**Issue to start:** #$ARGUMENTS

### Step 1: Load the Issue

Fetch the full issue context:
```
gh issue view $ARGUMENTS --json title,body,labels,comments,milestone
```

Read the issue title, tasks, and any existing timeline comments.

### Step 2: Create the Branch

Derive the branch name from the issue: `issue/<number>-<brief-slug>`.

Use a worktree (preferred) or in-place checkout:

**Worktree (preferred):**
```bash
git fetch origin <default-branch>
git worktree add ../<branch-name> -b <branch-name> origin/<default-branch>
cd ../<branch-name>
```

If `superpowers:using-git-worktrees` is available, delegate to it instead.

**Fallback (in-place):** Only if the user requests no worktree.
```bash
git fetch origin <default-branch>
git checkout -b <branch-name> origin/<default-branch>
```

### Step 3: Update Issue Labels

If the issue has `shiplog/plan` or `shiplog/ready` but not `shiplog/in-progress`, transition it:
```
gh issue edit $ARGUMENTS --remove-label "shiplog/ready" --add-label "shiplog/in-progress"
```

### Step 4: Post Session-Start Comment

Post a timeline comment on the issue:
```
[shiplog/session-start] #<number>: Starting work

**Branch:** `<branch-name>`
**Worktree:** `<path>`
**Starting tasks:** <list of tasks from issue body>
**Plan:** <brief summary of approach>

Authored-by: <model-family>/<model-version> (<tool>)
```

### Step 5: Report

Tell the user:
- The branch and worktree path created
- A summary of the tasks from the issue
- Which task to start with
