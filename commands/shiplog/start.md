---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write, Skill
description: Create a branch and worktree from a GitHub issue, start a work session
argument-hint: <issue-number>
---

Go from an open issue to a live branch in one step. Load the issue, create the branch, swap the lifecycle label, and post the session-start comment — all in order.

## Policy

**Branch naming:** `issue/<id>-<brief-slug>` where `<id>` is the issue number and `<slug>` is 2-5 words from the title, hyphen-separated, lowercase. Example: `issue/42-auth-middleware`.

**Branch base:** always from the default branch tip (`origin/<default>`). Never branch from another feature branch unless this is an explicitly stacked PR.

**Label swap:** when starting work, transition the issue lifecycle label from `shiplog/ready` (or `shiplog/plan`) to `shiplog/in-progress`. These labels are mutually exclusive — remove the old one before adding the new one.

**Envelope update:** edit the issue body to set `readiness: in-progress`. This is a triage field update; it does not require `Updated-by:` provenance.

**Session-start comment:** every work session must open with a `[shiplog/session-start]` comment on the issue. This is the durable record that a branch exists and work has begun.

**Worktree (preferred):** use a git worktree so the main checkout stays clean. If `superpowers:using-git-worktrees` is available, delegate worktree creation to it. For in-place checkout, use the fallback commands below.

## Query / Template

### Fetch the issue

```bash
gh issue view <N> --json title,body,labels,comments,milestone
```

### Create the branch

**Worktree (preferred):**
```bash
git fetch origin <default-branch>
git worktree add ../<branch-name> -b <branch-name> origin/<default-branch>
```

**In-place fallback:**
```bash
git fetch origin <default-branch>
git checkout -b <branch-name> origin/<default-branch>
```

### Swap lifecycle label

```bash
gh issue edit <N> --remove-label "shiplog/ready" --add-label "shiplog/in-progress"
# Also remove shiplog/plan if present:
gh issue edit <N> --remove-label "shiplog/plan"
```

### Update envelope readiness in issue body

Edit the issue body in place: change `readiness: ready` to `readiness: in-progress`. This is triage state; no `Updated-by:` needed.

### Session-start comment template

```markdown
[shiplog/session-start] #<N>: Starting work

**Branch:** `<branch-name>`
**Worktree:** `<path>` (or `in-place checkout`)
**Starting tasks:** <list of unchecked tasks from issue body>
**Plan:** <1-2 sentence summary of approach>

Authored-by: <family>/<version> (<tool>)
```

Post with:
```bash
gh issue comment <N> --body-file <temp-file>
```

## Acceptance Checklist

- [ ] Branch name follows `issue/<id>-<slug>` convention
- [ ] Branch was created from `origin/<default-branch>` tip, not from another feature branch
- [ ] Issue label transitioned from `shiplog/ready` (or `shiplog/plan`) to `shiplog/in-progress`
- [ ] Issue body `readiness:` field updated to `in-progress`
- [ ] Session-start comment posted on the issue with `Authored-by:` sig
- [ ] Unchecked task list from the issue is visible in the session-start comment
