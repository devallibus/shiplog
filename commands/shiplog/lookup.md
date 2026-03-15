---
allowed-tools: Bash(gh:*), Bash(git:*), Read
description: Search the knowledge graph — issues, PRs, commits, and memory
argument-hint: <search query>
---

## Context

- Repo: !`gh repo view --json nameWithOwner --jq '.nameWithOwner'`
- Current branch: !`git branch --show-current`

## Your Task

You are executing shiplog Phase 6: Knowledge Retrieval.

**Search query:** $ARGUMENTS

### Step 1: Search GitHub Issues and PRs

```
gh issue list --state all --search "$ARGUMENTS" --json number,title,state,labels --limit 10
gh pr list --state all --search "$ARGUMENTS" --json number,title,state --limit 10
```

### Step 2: Search Git History

```
git log --all --oneline --grep="$ARGUMENTS" --limit 20
```

### Step 3: Search Knowledge Graph (if available)

If `ork:memory` is available, search it:
```
/ork:memory search "$ARGUMENTS"
```

### Step 4: Compile Results

Present a summary organized by source:

```
LOOKUP: "$ARGUMENTS"
======================

ISSUES:
#NNN  <title>                    <state>  <labels>

PULL REQUESTS:
#NNN  <title>                    <state>

COMMITS:
<hash>  <subject>

MEMORY:
<key decisions or patterns found>
```

### Step 5: Deep Dive (if needed)

If results are found, offer to read the most relevant issue or PR body for full context. Prefer reading envelope metadata first (look for `<!-- shiplog:` HTML comments) before loading full bodies.

Keep the initial report concise. Let the user ask for details on specific items.
