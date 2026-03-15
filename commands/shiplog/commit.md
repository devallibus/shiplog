---
allowed-tools: Bash(git:*), Bash(gh:*), Read
description: Commit staged changes with shiplog ID-first convention and optional context comment
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status`
- Staged and unstaged changes: !`git diff HEAD`
- Recent commits: !`git log --oneline -10`

## Your Task

You are executing shiplog Phase 4: Commit-with-Context.

### Step 1: Extract the Issue Number

Parse the issue number from the current branch name. Branch format: `issue/<number>-<slug>`.

If the branch doesn't follow shiplog convention, ask the user for the issue number.

### Step 2: Stage and Commit

Based on the changes, create a commit with the shiplog ID-first format:

```
<type>(#<issue-number>): <description>
```

If the commit addresses a specific task from the issue, include the task ID:
```
<type>(#<issue-number>/<Tn>): <description>
```

**Commit types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`.

Stage relevant files (prefer specific files over `git add -A`). Create the commit. Do not use `--no-verify`.

End the commit message with:
```

Co-Authored-By: <model family/version> (<tool>) <noreply@anthropic.com>
```

### Step 3: Context Comment (for significant commits)

For significant changes (new functionality, unexpected discoveries, approach changes, tricky fixes), post a context comment on the issue:

```
[shiplog/commit-note] #<issue-number>: <commit-hash-short> <commit-subject>

**What:** <1-2 sentences on what this commit does>
**Why:** <reasoning behind the approach>
**Verification:** <what was tested or checked>

Authored-by: <model-family>/<model-version> (<tool>)
```

Skip the context comment for trivial commits (typos, formatting, small fixes).

### Step 4: Report

Show the user the commit hash, message, and files changed.
