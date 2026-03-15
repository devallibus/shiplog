---
allowed-tools: Bash(gh:*), Bash(git:*), Read
description: Scan open issues and PRs, rank by readiness, recommend what to work on next
---

## Context

- Repo: !`gh repo view --json nameWithOwner --jq '.nameWithOwner'`
- Current branch: !`git branch --show-current`
- Open issues with labels: !`gh issue list --state open --json number,title,labels --limit 30`
- Open PRs with review status: !`gh pr list --state open --json number,title,reviewDecision,reviews,isDraft --limit 20`

## Your Task

You are the shiplog hunt command. Present a triage report of all open issues and PRs.

### Step 1: Categorize Issues

Group open issues by their lifecycle label:

| Priority | Label | Meaning |
|----------|-------|---------|
| 1 (act now) | `shiplog/needs-review` | PR exists, needs cross-model review before merge |
| 2 (act now) | `shiplog/ready` | Planned and ready to implement |
| 3 (in flight) | `shiplog/in-progress` | Already being worked on |
| 4 (needs planning) | `shiplog/plan` (no lifecycle label) | Needs further breakdown or review |
| 5 (parked) | No shiplog labels | Uncategorized or external |

### Step 2: Categorize PRs

Group open PRs by review status:

| Priority | Status | Action Needed |
|----------|--------|---------------|
| 1 | No reviews, not draft | Needs review — can we review and merge? |
| 2 | Changes requested | Needs fixes then re-review |
| 3 | Approved | Ready to merge |
| 4 | Draft | Still in progress |

### Step 3: Present the Hunt Report

Display a compact table:

```
HUNT REPORT — <repo> (<date>)
================================

PRs NEEDING ACTION:
#NNN  <title>                           <status>

ISSUES READY TO IMPLEMENT:
#NNN  <title>                           <labels>

ISSUES IN PROGRESS:
#NNN  <title>                           <labels>

ISSUES NEEDING PLANNING:
#NNN  <title>                           <labels>
```

### Step 4: Recommend

End with 1-3 concrete recommendations:
- Which PR to review next (if any need review)
- Which issue to start implementing (highest-readiness first)
- Any housekeeping (stale issues, PRs with no activity)

Keep the report concise. The user wants to know what to do next, not read every issue body.
