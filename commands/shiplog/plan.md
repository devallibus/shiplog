---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write, Glob, Agent, Skill
description: Brainstorm a feature and capture it as a GitHub Issue
argument-hint: <feature description>
---

## Context

- Repo: !`gh repo view --json nameWithOwner --jq '.nameWithOwner'`
- Default branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Existing labels: !`gh label list --json name --jq '.[].name' --limit 50`

## Your Task

You are executing shiplog Phase 1: Brainstorm-to-Issue.

**Feature to plan:** $ARGUMENTS

### Step 1: Brainstorm

Run a focused brainstorm on the feature. Consider:
- What problem does this solve and why now?
- What are the key design decisions?
- What alternatives exist?
- What are the risks and open questions?

If `superpowers:brainstorming` or `ork:brainstorming` is available, delegate to it. Otherwise brainstorm inline.

### Step 2: Bootstrap Labels

If the repo does not already have shiplog labels (`shiplog/plan`, `shiplog/ready`, etc.), bootstrap them:
```
gh label create "shiplog/plan" --color "0B7285" --description "Brainstorm captured as a planning issue" --force
gh label create "shiplog/ready" --color "2DA44E" --description "Ready to implement" --force
gh label create "shiplog/in-progress" --color "FBCA04" --description "Implementation in progress" --force
gh label create "shiplog/needs-review" --color "D93F0B" --description "Awaiting review" --force
gh label create "shiplog/discovery" --color "1D6F42" --description "Work discovered during another issue or PR" --force
gh label create "shiplog/history" --color "5319E7" --description "PR with a shiplog journey timeline" --force
gh label create "shiplog/issue-driven" --color "D4C5F9" --description "Branch/PR driven by an issue" --force
```

### Step 3: Create the Issue

Create a GitHub issue using the shiplog Phase 1 template. The issue body must include:
- An envelope comment (HTML comment with `kind: state`, `status: open`, `phase: 1`)
- Context, Design Summary, Approach, Alternatives Considered
- Tasks with tier tags (`[tier-1]`, `[tier-2]`, `[tier-3]`) and contract fields
- Open Questions (if any)

Apply the `shiplog/plan` label at creation time.

Classify all factual claims as internal (verifiable from the repo) or external (needs primary source). Mark unverified external claims as `[unverified]`.

### Step 4: Sign the Artifact

End the issue body with:
```
Authored-by: <model-family>/<model-version> (<tool>)
```

Detect your model identity from the system prompt.

### Step 5: Report

Show the user the created issue number and URL. Ask if they want to start working on it (which would trigger Phase 2).
