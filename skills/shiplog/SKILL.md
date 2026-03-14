---
name: shiplog
description: Git-as-knowledge-graph workflow. Use when starting planned work, brainstorming, creating issues/PRs, tracking decisions, or when complete traceability is needed. Auto-activates for branch creation, issue creation, PR creation, brainstorming, or session resume. Slash command /shiplog.
---

# Shiplog

The captain's log for your codebase. Every decision, discovery, and change logged as you ship code.

Use GitHub as a complete knowledge graph where every brainstorm, commit, review, and decision is traceable. This skill ORCHESTRATES existing skills — it defines WHEN and HOW to invoke them and what documentation protocol to follow.

## Core Principle

**Nothing gets lost.** Every brainstorm becomes an issue. Every issue drives a branch. Every branch produces a PR. Every PR is a timeline of the entire journey. Git becomes the uber-memory.

---

## Mode Selection

On first activation per project, determine which mode to use:

### Mode A: Full Mode (default)

For personal projects, OSS, teams that embrace documentation. Knowledge goes directly into issues and PRs.

### Mode B: Quiet Mode

For work environments where issues/PRs must stay clean. Knowledge lives in a **stacked knowledge branch** (`--log`) with its own PR targeting the feature branch.

```
main
  └── feature/auth-middleware            ← Clean PR to main
        └── feature/auth-middleware--log  ← Knowledge PR targets feature branch
```

Ask the user which mode on first activation. Remember the choice via `ork:remember` or note in project CLAUDE.md.

---

## When This Skill Activates

**User-invocable:** `/shiplog`

**Auto-activate when ANY of these occur:**
- User says "let's plan", "let's brainstorm", "let's build", "let's fix"
- Creating a new branch or issue
- Creating a PR
- Mid-work discovery requiring a new issue or stacked PR
- User asks "where did we decide X?" or "what's the status of Y?"
- Resuming work on an existing issue or PR

---

## ID-First Naming Convention

All artifacts use `#ID` as the primary key for fast, token-efficient retrieval:

| Artifact | Convention | Example |
|----------|-----------|---------|
| Branch | `issue/<id>-<slug>` | `issue/42-auth-middleware` |
| Commit | `<type>(#<id>): <msg>` | `feat(#42): add JWT validation` |
| PR title | `<type>(#<id>): <msg>` | `feat(#42): add auth middleware` |
| PR body | `Closes #<id>` | `Closes #42` |
| Timeline comment | `[#<id>] <type>: ...` | `[#42] discovery: race condition` |
| Stacked branch | `issue/<new-id>-<slug>` | `issue/43-fix-race-condition` |
| Stacked PR title | `<type>(#<new-id>): ... [stack: #<parent>]` | `fix(#43): race cond [stack: #42]` |
| Memory entry | `#<id>: <decision>` | `#42: chose JWT over sessions` |

**Quiet Mode overrides:**

| Artifact | Convention | Example |
|----------|-----------|---------|
| Feature branch | per team convention | `feature/auth-middleware` |
| Knowledge branch | `<branch>--log` | `feature/auth-middleware--log` |
| Knowledge PR title | `[shiplog] <desc>` | `[shiplog] auth middleware decisions` |
| Knowledge PR base | the feature branch | base: `feature/auth-middleware` |

**Retrieval:**
- `gh issue list --search "#42"` — everything linked to issue 42
- `git log --grep="#42"` — all commits for issue 42
- `gh pr list --search "#42"` — PRs closing issue 42
- `gh pr list --search "[shiplog]"` — all knowledge PRs (quiet mode)

---

## Decision Tree

```
User request arrives
  |
  +-- "Let's brainstorm/plan/design X"     -> PHASE 1
  +-- "Work on issue #N"                    -> PHASE 2
  +-- "I found a sub-problem"              -> PHASE 3
  +-- "Let's commit" / "Ready for PR"      -> PHASE 4 or 5
  +-- "Where did we decide X?"             -> PHASE 6
  +-- Currently mid-work on a branch       -> PHASE 7
```

---

## PHASE 1: Brainstorm-to-Issue

**Trigger:** User wants to plan, brainstorm, or design something.

### Step 1: Run the brainstorm

Delegate to the appropriate brainstorming skill:
- `superpowers:brainstorming` — if available and task involves creative/design work
- `ork:brainstorming` — if available and task benefits from parallel agent research
- Inline brainstorm — for quick discussions that don't need a full spec

### Step 2: Capture as GitHub Issue (Full Mode)

```bash
gh issue create \
  --title "[PLAN] Brief title describing the work" \
  --body "$(cat <<'EOF'
## Context

[1-3 sentences: what problem are we solving and why now]

## Design Summary

[Key decisions from the brainstorm — 3-5 bullet points]

## Approach

[The chosen approach with brief rationale]

## Alternatives Considered

- **Alternative A**: [why not chosen]
- **Alternative B**: [why not chosen]

## Tasks

- [ ] Task 1: [specific deliverable]
- [ ] Task 2: [specific deliverable]
- [ ] Task 3: [specific deliverable]

## Open Questions

- [Any unresolved questions]

---
*Captain's log entry created by [shiplog](https://github.com/devallibus/shiplog)*
EOF
)"
```

### Step 2 (Quiet Mode): Defer capture until the feature branch exists

Do not create the `--log` PR yet. Quiet Mode needs the feature branch to exist first, and that branch is only created in PHASE 2.

Instead:
- Save the brainstorm content locally using the same template as above.
- If your team still requires an issue, create a minimal clean issue and keep the detailed reasoning out of it.
- In PHASE 2, after `<branch>` exists, create `<branch>--log`, open the PR against `<branch>`, and use the saved brainstorm content as the opening knowledge log entry.

### Step 3: Store in knowledge graph

If `ork:remember` is available:
```
/ork:remember --category decision #<issue-id>: Planned [feature]: [1-sentence summary]. Key decision: [most important choice].
```

### Step 4: Transition

If the user wants to start work immediately, proceed to PHASE 2.

---

## PHASE 2: Issue-to-Branch

**Trigger:** User wants to work on a specific issue.

### Step 1: Load context

```bash
gh issue view <ISSUE_NUMBER> --json title,body,labels,comments,milestone
```

Also search knowledge graph if available: `/ork:memory search "#<issue-id>"`

### Step 2: Create branch

Delegate to `superpowers:using-git-worktrees` if isolation is needed, otherwise:

```bash
git checkout main && git pull origin main
git checkout -b issue/<ISSUE_NUMBER>-<brief-description>
```

### Step 3: Post timeline entry (Full Mode)

```bash
gh issue comment <ISSUE_NUMBER> --body "$(cat <<'EOF'
## [shiplog] Work Started

**Branch:** `issue/<N>-<description>`
**Approach:** [1-2 sentences about the plan for this session]

---
*Captain's log — session start*
EOF
)"
```

### Step 3 (Quiet Mode): Create `--log` branch + PR

If the `--log` PR doesn't exist yet:
```bash
git checkout -b <branch>--log
git commit --allow-empty -m "shiplog: initialize knowledge log"
git push -u origin <branch>--log
gh pr create --base <branch> \
  --title "[shiplog] <description>" \
  --body "## Knowledge Log\n\nTracking decisions and discoveries for this work."
# If you deferred a brainstorm from PHASE 1, use that saved content as the initial PR body instead of this placeholder.
# Then switch back to the feature branch
git checkout <branch>
```

Post a comment on the `--log` PR:
```bash
gh pr comment <LOG_PR_NUMBER> --body "[shiplog] Work started. Approach: [1-2 sentences]"
```

### Step 4: Load plan if it exists

Delegate to `superpowers:executing-plans` or `ork:implement` as appropriate.

---

## PHASE 3: Discovery Protocol

**Trigger:** While working, you discover something that is a separate concern.

### Decision tree

```
Discovery made during work
  |
  +-- Small fix (< 30 min, < 100 lines)?
  |     -> Fix inline, add timeline comment
  |
  +-- Prerequisite for current work?
  |     -> Stack a new branch/PR (Phase 3a)
  |
  +-- Independent but important?
  |     -> Create new issue, continue current work (Phase 3b)
  |
  +-- Refactoring opportunity?
        -> Create issue tagged "refactor", note in timeline
```

### Phase 3a: Stack a prerequisite

1. Commit current progress on current branch.
2. Create a new issue for the discovered work first, so the new issue ID exists before any branch or PR naming depends on it:

```bash
gh issue create \
  --title "[DISCOVERY] Brief description" \
  --body "$(cat <<'EOF'
## Discovered During

Issue #<PARENT> - while working on [context]

## Problem

[What we discovered]

## Why This Blocks Parent

[Why this must be resolved first]

## Proposed Fix

[Approach]

---
*Discovered during #<PARENT>. Stacked dependency.*
EOF
)"
```

3. Capture the created issue number as `<NEW_ISSUE>`, then delegate to `ork:stacked-prs` if available, otherwise manually:

```bash
git checkout -b issue/<NEW_ISSUE>-<description>
```

4. Cross-reference on the parent:

```bash
gh issue comment <PARENT_ISSUE> --body "[#<PARENT>] discovery: Found sub-problem -> created #<NEW_ISSUE>. This is a stacked prerequisite."
```

### Phase 3b: Log independent discovery

1. Create new issue (same template without "blocks parent").
2. Add timeline comment on current issue/PR (or `--log` PR in Quiet Mode).
3. Continue current work.

---

## PHASE 4: Commit-with-Context

**Trigger:** Ready to commit changes.

### Step 1: Delegate the commit

Use `ork:commit` > `commit-commands:commit` > manual `git commit` (in order of preference).

Commit message format: `<type>(#<issue-id>): <description>`

### Step 2: Add context comment (for significant commits)

After each meaningful commit, document the reasoning. Target: the issue (Full Mode) or `--log` PR (Quiet Mode).

```bash
COMMIT_SHA=$(git log -1 --format='%h')
COMMIT_MSG=$(git log -1 --format='%s')

# Full Mode: comment on issue
gh issue comment <ISSUE_NUMBER> --body "$(cat <<EOF
## [#<ISSUE>] commit: \`$COMMIT_SHA\`

**What:** $COMMIT_MSG

**Why:** [1-2 sentences explaining the reasoning]

**Discovered:** [Anything unexpected, or "Nothing unexpected"]

**Next:** [What comes next]
EOF
)"

# Quiet Mode: comment on --log PR
gh pr comment <LOG_PR_NUMBER> --body "[same content]"
```

**When to add context comments:**
- After implementing significant functionality
- After discovering something unexpected
- After changing approach mid-work
- After resolving a tricky bug
- **NOT** after trivial commits (formatting, typos, import ordering)

---

## PHASE 5: PR-as-Timeline

**Trigger:** Work is complete and ready for PR.

### Step 1: Pre-PR checks

Delegate to `ork:create-pr` (validation) or `superpowers:finishing-a-development-branch`.

### Step 2: Create PR with timeline body (Full Mode)

```bash
ISSUE_NUMBER=<N>
BASE_BRANCH=main

gh pr create --base $BASE_BRANCH \
  --title "<type>(#$ISSUE_NUMBER): Brief description" \
  --body "$(cat <<'EOF'
## Summary

[2-3 sentences: what this PR does and why]

Closes #<ISSUE_NUMBER>

## Journey Timeline

### Initial Plan
[What we set out to do — reference the issue]

### What We Discovered
- [Discovery 1: what surprised us]
- [Discovery 2: what we learned]

### Key Decisions Made

| Decision | Choice | Why |
|----------|--------|-----|
| [Decision 1] | [Chosen option] | [Reasoning] |
| [Decision 2] | [Chosen option] | [Reasoning] |

### Changes Made

**Commits:**
[list commits with `git log --oneline main..HEAD`]

## Testing

- [x] [What was tested and how]
- [x] All existing tests pass

## Stacked PRs / Related

- [#related-pr or #related-issue if any]

## Knowledge for Future Reference

[Anything a future developer should know when revisiting this area. Patterns established, gotchas found, decisions that might need revisiting.]

---
*Captain's log — PR timeline by [shiplog](https://github.com/devallibus/shiplog)*
EOF
)"
```

### Step 2 (Quiet Mode): Clean feature PR

Create the feature PR with a standard body (no shiplog content). The `--log` PR already has the full timeline.

Add a final summary comment to the `--log` PR:
```bash
gh pr comment <LOG_PR_NUMBER> --body "$(cat <<'EOF'
## [shiplog] Final Summary

**Feature PR:** #<FEATURE_PR_NUMBER>
**Status:** Ready for review

### Journey Recap
[1-paragraph summary of the complete journey]

### Key Decisions
[Numbered list of most important decisions]

### Lessons Learned
[What we'd do differently next time]
EOF
)"
```

### Step 3: Link and store

- PR body includes `Closes #<issue>` for auto-linking (Full Mode)
- Store in knowledge graph: `/ork:remember --category decision #<issue>: Completed [feature]. PR #<pr>. Key learning: [lesson].`

---

## PHASE 6: Knowledge Retrieval

**Trigger:** User asks about past decisions, status, or history.

### Step 1: Search git history

```bash
# Search issues
gh issue list --search "keyword" --state all --json number,title,state --limit 10

# Search PRs
gh pr list --search "keyword" --state all --json number,title,state --limit 10

# Search commits
git log --all --oneline --grep="keyword" -20

# Quiet mode: search knowledge PRs
gh pr list --search "[shiplog] keyword" --state all --json number,title,state
```

### Step 2: Search knowledge graph

If `ork:memory` is available: `/ork:memory search "keyword"`

### Step 3: Compile summary

```markdown
## Shiplog Query: "keyword"

### Issues
- #N: [title] — [status]

### PRs
- #N: [title] — [status], key decision: [from PR body]

### Commits
- abc1234: [message]

### Timeline
[Chronological narrative of how this evolved]
```

---

## PHASE 7: Timeline Maintenance

**Trigger:** Mid-work on a branch, need to maintain the timeline.

### When to add timeline comments

1. **Starting a new session** on the same issue/branch
2. **Changing approach** from what was originally planned
3. **Finding something unexpected** that affects the plan
4. **Completing a milestone** (a task checkbox in the issue)
5. **Getting blocked** and needing to pause

### Comment format

Target: issue (Full Mode) or `--log` PR (Quiet Mode).

```markdown
## [#<ID>] <type>: <brief summary>

**Status:** [In progress / Blocked / Approach changed / Milestone reached]

**Progress since last update:**
- [What was done]

**Current state:**
- [Where things stand]

**Next steps:**
- [What comes next]

[If blocked]: **Blocker:** [Description and what help is needed]

[If approach changed]: **Why:** [What changed and reasoning]
```

Comment types: `session-start`, `session-resume`, `milestone`, `discovery`, `approach-change`, `blocker`, `session-end`

Delegate automatic checkbox updates to `ork:issue-progress-tracking` if available.

---

## Integration Map

This skill ORCHESTRATES. It never reimplements. Delegation map:

| Activity | Delegate To | Shiplog Adds |
|----------|-------------|--------------|
| Brainstorming | `superpowers:brainstorming` or `ork:brainstorming` | Issue creation from output |
| Planning | `superpowers:writing-plans` | Issue task list mirroring |
| Plan execution | `superpowers:executing-plans` | Timeline comments at checkpoints |
| Committing | `ork:commit` or `commit-commands:commit` | Commit context comments |
| Creating PRs | `ork:create-pr` | Timeline PR body template |
| Finishing branches | `superpowers:finishing-a-development-branch` | Knowledge graph storage after |
| Worktree creation | `superpowers:using-git-worktrees` | Branch-issue linking |
| Stacked PRs | `ork:stacked-prs` | Discovery-driven stacking protocol |
| Issue tracking | `ork:issue-progress-tracking` | Richer timeline comments |
| Storing decisions | `ork:remember` | Structured `#ID: decision` entries |
| Fixing issues | `ork:fix-issue` | Timeline documentation of RCA |

### Graceful Degradation

```
For each operation:
  1. Try preferred skill (e.g., ork:commit)
  2. Try alternative skill (e.g., commit-commands:commit)
  3. Fall back to direct gh/git commands
```

**Minimum viable installation:** `gh` CLI + `git` + this skill. The core loop (issue -> branch -> commits with context -> PR with timeline) works with just `gh` commands.

### Conflict Avoidance

- This skill sets the WORKFLOW context. Delegated skills set IMPLEMENTATION details.
- This skill's templates take precedence for knowledge-graph fields.
- Delegated skills' validation, agents, and process steps are used as-is.

---

## Edge Cases

**No issue exists:** Let the user work. At first commit or PR, offer: "No tracking issue for this work. Want me to create one to maintain the knowledge graph? I can backfill from what we've done."

**Mid-work activation:** Check for existing linked issue (from branch name `issue/N-*`). If found, add a catch-up timeline comment. If not, offer retroactive issue creation.

**Small tasks (< 30 min):** Lightweight protocol — issue optional, branch still created, PR timeline sections can be brief. "Knowledge for Future Reference" should still be filled if anything was learned.

**Hotfix / emergency:** Fix first. Create issue and PR after, backfilling the timeline. PR body notes: "Hotfix — issue created retroactively."

**Session resume:** Check `--from-pr <number>` for PR context. Search `ork:memory`. Read issue/PR comments. Add "Session resumed" timeline comment. Continue with Phase 7.

**Quiet mode — feature PR merges:** Close the `--log` PR. Knowledge is preserved in the closed PR's history.

**Quiet mode — feature branch rebased:** Rebase `--log` branch onto updated feature branch. Use `--force-with-lease` for the push.

---

## Requirements

### System

| Dependency | Purpose | Install |
|-----------|---------|---------|
| `gh` CLI | GitHub issue/PR/comment operations | `brew install gh` / `winget install GitHub.cli` |
| `git` | Branch, commit, diff, log | Pre-installed |
| GitHub remote | Must be in a git repo with GitHub remote | — |

### Recommended Skills

| Skill | Plugin | What It Adds |
|-------|--------|-------------|
| `ork:commit` | OrchestKit | Conventional commits with validation |
| `ork:create-pr` | OrchestKit | PR creation with parallel validation agents |
| `ork:stacked-prs` | OrchestKit | Stacked PR mechanics and management |
| `ork:issue-progress-tracking` | OrchestKit | Auto-checkbox updates from commits |
| `ork:remember` / `ork:memory` | OrchestKit | Knowledge graph storage and retrieval |
| `ork:brainstorming` | OrchestKit | Parallel agent brainstorming |
| `superpowers:brainstorming` | Superpowers | Design-first brainstorming workflow |
| `superpowers:using-git-worktrees` | Superpowers | Isolated workspace creation |
| `superpowers:finishing-a-development-branch` | Superpowers | Post-implementation options |
| `superpowers:writing-plans` | Superpowers | Structured plan documents |
| `superpowers:executing-plans` | Superpowers | Plan execution with checkpoints |

All skills are optional. Without them, shiplog falls back to direct `gh`/`git` commands.
