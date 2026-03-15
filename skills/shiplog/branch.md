---
name: branch
description: "Phase 2: Create a branch from an issue, set up worktree, and post the initial timeline entry."
---

# Branch Setup (Phase 2)

<!-- routing: tier-2, plan then agent -->
<!-- cross-cutting: references/model-routing.md (Step 0), references/signing.md, references/labels.md, references/shell-portability.md -->

0. **Routing check.** Run the phase entry check from `references/model-routing.md`.

1. **Load context.** `gh issue view <N> --json title,body,labels,comments,milestone` and search knowledge graph. If the issue is missing obvious Shiplog labels, backfill per `references/labels.md`.

2. **Create branch (worktree-first).** One branch, one worktree, one agent.

   Delegate to `superpowers:using-git-worktrees` if available. Otherwise:
   ```bash
   DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
   git fetch origin $DEFAULT_BRANCH
   BRANCH=issue/<ISSUE_NUMBER>-<brief-description>
   git worktree add ../$BRANCH -b $BRANCH origin/$DEFAULT_BRANCH
   cd ../$BRANCH
   ```
   ```powershell
   $defaultBranch = gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
   git fetch origin $defaultBranch
   $branch = 'issue/<ISSUE_NUMBER>-<brief-description>'
   git worktree add ../$branch -b $branch origin/$defaultBranch
   Set-Location ../$branch
   ```
   See `references/shell-portability.md` for shell-specific notes.
   **Fallback (in-place checkout):** Only when the user explicitly requests no worktree.

3. **Post timeline entry.** Full Mode: comment on the issue using the session-start template below. Quiet Mode: create `--log` branch + PR using the quiet-mode template below. Sign per `references/signing.md`.

4. **Load plan** if it exists. Delegate to `superpowers:executing-plans` or `ork:implement`.
   For delegated or tier-3 work, the plan should define a contract: allowed files, forbidden changes, stop conditions, verification, return artifact, and decision budget.

---

## Session-Start Comment (Full Mode)

```bash
gh issue comment <ISSUE_NUMBER> --body-file <temp-file>
```

Comment body:

```markdown
<!-- shiplog:
kind: handoff
issue: <ISSUE_NUMBER>
phase: 2
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/session-start] <Brief description of the work>

**Branch:** `issue/<N>-<description>`
**Approach:** [1-2 sentences about the plan for this session]

---
Authored-by: <family>/<version> (<tool>)
*Captain's log — session start*
```

---

## Quiet Mode: `--log` Branch + PR

If the `--log` PR doesn't exist yet:
```bash
git checkout -b <branch>--log
git commit --allow-empty -m "shiplog: initialize knowledge log"
git push -u origin <branch>--log
gh pr create --base <branch> \
  --label "shiplog/worklog" \
  --label "shiplog/quiet-mode" \
  --label "shiplog/issue-driven" \
  --title "[shiplog/worklog] <description>" \
  --body-file <temp-file>
git checkout <branch>
```

PR body:
```markdown
<!-- shiplog:
kind: state
issue: <ISSUE_NUMBER>
branch: <branch>--log
status: open
updated_at: <ISO_TIMESTAMP>
-->

## Knowledge Log

Tracking decisions and discoveries for this work.
```

If you deferred a brainstorm from plan capture, use that saved content as the initial PR body.

Then post a session-start comment on the `--log` PR:
```bash
gh pr comment <LOG_PR_NUMBER> --body "[shiplog/session-start] Work started. Approach: [1-2 sentences]"
```

On PowerShell, use backtick for line continuation instead of `\`, or pass via `--body-file`.

---

## Delegation Handoff Comment

Use when delegating a bounded task to another agent:

```markdown
<!-- shiplog:
kind: handoff
issue: <ID>
phase: <PHASE>
updated_at: <ISO_TIMESTAMP>
-->

## [#<ID>] delegation handoff: <task title>

**Delegated by:** <family>/<version> (<tool>)
**Target tier:** tier-3
**Why delegation fits:** [why this work is bounded and non-judgmental]

### Goal
[One concrete outcome.]

### Contract
- **Allowed files:** `path/to/file.ts`, `path/to/other.ts`
- **Must not change:** [files, APIs, behavior, or decisions outside scope]
- **Acceptance criteria:** [specific outcomes that define done]
- **Forbidden judgment calls:** [decisions the delegated agent must not make]
- **Stop and ask if:** [conditions that require escalation]
- **Active verification profile:** [profile names or `none`]
- **Verification required:** [tests, checks, or evidence required]
- **Return artifact:** [delegation report, changed-file list, verification note, blockers]
- **Decision budget:** `none` | `narrow`

### Task checklist
1. [Concrete action with file path]

### Gotchas
- [Anything the delegated agent could misunderstand]

Authored-by: <family>/<version> (<tool>)
```

## Delegation Return Artifact

```markdown
<!-- shiplog:
kind: verification
issue: <ID>
updated_at: <ISO_TIMESTAMP>
-->

## [#<ID>] delegation report: <task title>

**Status:** completed | blocked | escalated
**Contract:** [link or quote the delegation handoff heading]

### Changed files
- `path/to/file.ts` - [summary]

### Acceptance criteria
- [x] [criterion met]
- [ ] [criterion not met, with reason]

### Verification status
- **Ran:** [commands/checks]
- **Passed:** [what passed]
- **Deferred:** [what was skipped, with reason]

### Decisions deferred upward
- [question or "None"]

### Blockers
- [blocker or "None"]

Authored-by: <family>/<version> (<tool>)
```

---

## Edge Cases

**Session resume:** Detect the issue from the current branch name or worktree. If the branch has an existing worktree, `cd` into it. Find linked PRs, read comments, add "Session resumed" timeline comment via `shiplog:timeline`.

**Quiet mode — feature branch rebased:** Rebase `--log` branch onto updated feature branch. Use `--force-with-lease`.
