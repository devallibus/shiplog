---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write, Skill
description: Create a PR with a shiplog journey timeline
---

## Context

- Current branch: !`git branch --show-current`
- Default branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Commit history on this branch: !`git log --oneline origin/HEAD..HEAD 2>/dev/null || git log --oneline -20`
- Unpushed commits: !`git log --oneline @{upstream}..HEAD 2>/dev/null || echo "(no upstream set)"`

## Your Task

You are executing shiplog Phase 5: PR-as-Timeline.

### Step 1: Extract Issue Number and Context

Parse the issue number from the branch name (`issue/<number>-<slug>`).

Fetch the issue:
```
gh issue view <number> --json title,body,labels,comments
```

Read the issue body for tasks, decisions, and context.

### Step 2: Push the Branch

If there are unpushed commits or no upstream:
```
git push -u origin <branch-name>
```

### Step 3: Build the PR Body

Create the PR using the shiplog timeline template. The PR body must include:

1. **Summary** — 1-3 bullet points
2. **`Closes #<number>`** (or `Addresses #<number> (completes T1, T2, ...)` for partial delivery)
3. **Journey Timeline** — Initial Plan, What We Discovered, Key Decisions Made (table), Changes Made (commits list)
4. **Testing** — Checklist of what was verified
5. **Knowledge for Future Reference** — Lessons learned

Apply labels: `shiplog/history`, `shiplog/issue-driven`.

### Step 4: Create the PR

Use `gh pr create` with `--body-file` for the multiline body:
```
gh pr create --title "<type>(#<number>): <summary>" --body-file <temp-file> --label "shiplog/history" --label "shiplog/issue-driven"
```

### Step 5: Sign the Artifact

End the PR body with:
```
---
Authored-by: <model-family>/<model-version> (<tool>)
*Captain's log -- PR timeline by [shiplog](https://github.com/devallibus/shiplog)*
```

### Step 6: Update Issue Label

Transition the issue to needs-review:
```
gh issue edit <number> --remove-label "shiplog/in-progress" --add-label "shiplog/needs-review"
```

### Step 7: Report

Show the user the PR URL and remind them that cross-model review is required before merge.
