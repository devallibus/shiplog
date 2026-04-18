---
name: branch
description: "Phase 2: Create a branch from an issue, set up worktree, and post the initial timeline entry."
---

# Branch Setup (Phase 2)

<!-- routing: tier-2, plan then agent -->
<!-- cross-cutting: references/model-routing.md (Step 0), SKILL.md §8 (Agent Identity Signing), references/labels.md, references/shell-portability.md, references/orchestrator-protocol.md -->

0. **Routing check.** Run the phase entry check from `references/model-routing.md`.

1. **Load context.** `gh issue view <N> --json title,body,labels,comments,milestone` and search knowledge graph. If the issue is missing obvious Shiplog labels, backfill per `references/labels.md`.

2. **Create branch (worktree-first).** One branch, one worktree, one agent for the primary line of work.

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
   If a delegated lane later uses a forked workspace, tmux session, or other runtime-specific isolation backend, keep this feature branch/worktree as the canonical shiplog record for the work.
   **Fallback (in-place checkout):** Only when the user explicitly requests no worktree.

3. **Post timeline entry.** Comment on the issue using the session-start template below. Record the workspace path when known. Sign per the signing spec — see SKILL.md §8 (Agent Identity Signing).

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
**Workspace:** `[absolute-or-relative-worktree-path if known]`
**Approach:** [1-2 sentences about the plan for this session]

---
Authored-by: <family>/<version> (<tool>)
*Captain's log — session start*
```

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

For N-way orchestration, pair these per-lane contracts with the fan-out dispatch and collection artifacts from `references/orchestrator-protocol.md`.

---

## Worktree Lifecycle

Track the primary feature worktree from session start through cleanup.

- Record the workspace path in the session-start artifact when known.
- Use `references/orchestrator-protocol.md` for fan-out dispatch when cleanup runs as its own lane.
- After merge, remove only worktrees whose branches are merged and no longer back an open PR.

Portable cleanup sequence:

```bash
git fetch origin
git branch --merged origin/$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
git worktree list
git worktree remove <path-to-worktree>
git branch -d <branch-name>
```

```powershell
git fetch origin
$defaultBranch = gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
git branch --merged origin/$defaultBranch
git worktree list
git worktree remove <path-to-worktree>
git branch -d <branch-name>
```

---

## Edge Cases

**Session resume:** Detect the issue from the current branch name or worktree. If the branch has an existing worktree, `cd` into it. Find linked PRs, read comments, add "Session resumed" timeline comment via `shiplog:timeline`.

**Post-merge cleanup:** If the branch is merged and no open PR still depends on it, run the cleanup protocol above or dispatch a dedicated cleanup lane per `references/orchestrator-protocol.md`.
