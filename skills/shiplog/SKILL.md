---
name: shiplog
description: Git-as-knowledge-graph workflow for traceability. Use when planning work, brainstorming designs, creating/managing issues and PRs, tracking architectural decisions, or resuming prior sessions. Slash command /shiplog.
---

# Shiplog

The captain's log for your codebase. Every decision, discovery, and change logged as you ship code.

Use GitHub as a complete knowledge graph where every brainstorm, commit, review, and decision is traceable. This skill ORCHESTRATES existing skills — it defines WHEN and HOW to invoke them and what documentation protocol to follow.

## Core Principle

**Nothing gets lost.** Every brainstorm becomes an issue. Every issue drives a branch. Every branch produces a PR. Every PR is a timeline of the entire journey. Git becomes the uber-memory.

---

## Mode Selection

On first activation per project, ask the user which mode to use:

- **Full Mode** (default): Knowledge goes directly into issues and PRs. For personal projects, OSS, teams that embrace documentation.
- **Quiet Mode**: Knowledge lives in a stacked knowledge branch (`<branch>--log`) with its own PR targeting the feature branch. For work environments where issues/PRs must stay clean.

Remember the choice via `ork:remember` or note in project CLAUDE.md.

---

## When This Skill Activates

**User-invocable:** `/shiplog`, `/shiplog models`, `/shiplog <phase>`

**`/shiplog models`:** Re-runs the routing setup prompt. See `references/model-routing.md`.

**Auto-activate when ANY of these occur:**
- User says "let's plan", "let's brainstorm", or "let's design"
- User explicitly requests traceability or knowledge-graph tracking
- Creating a new issue or PR with intent to document decisions
- Mid-work discovery requiring a new issue or stacked PR
- User asks "where did we decide X?" or "what's the status of Y?"
- Resuming work on an existing issue or PR
- Applying review feedback, fixing review findings, or addressing request-changes dispositions
- User references an issue or PR by number (e.g., "fix #42", "address the findings on PR #44")

**Do NOT auto-activate for:**
- Generic coding requests ("let's build", "let's fix", "add a feature")
- Simple bug fixes or refactors that don't need traceability
- Work where a more specific skill (TDD, debugging, etc.) is the better fit

---

## Decision Tree

Match the user's intent and load the corresponding sub-skill:

```
User request arrives
  +--> [If .shiplog/routing.md missing: run setup from references/model-routing.md]
  +--> ["/shiplog models": re-run setup prompt, update config]
  |
  +-- "Let's brainstorm/plan/design X"     -> shiplog:brainstorm
  +-- "Work on issue #N"                    -> shiplog:branch
  +-- "I found a sub-problem"              -> shiplog:discovery
  +-- "Let's commit"                       -> shiplog:commit
  +-- "Ready for PR"                       -> shiplog:pr
  +-- "Where did we decide X?"             -> shiplog:lookup
  +-- Currently mid-work on a branch       -> shiplog:timeline
```

---

## ID-First Naming Convention

All artifacts use `#ID` as the primary key for fast, token-efficient retrieval.

**Semantic tag vocabulary** for user-facing headings: `plan`, `session-start`, `commit-note`, `discovery`, `blocker`, `review-handoff`, `worklog`, `history`, `amendment`. Format: `[shiplog/<kind>] <human title>`.

| Artifact | Convention | Example |
|----------|-----------|---------|
| Branch | `issue/<id>-<slug>` | `issue/42-auth-middleware` |
| Commit | `<type>(#<id>): <msg>` | `feat(#42): add JWT validation` |
| Commit (task) | `<type>(#<id>/<Tn>): <msg>` | `feat(#42/T2): add middleware chain` |
| PR title | `<type>(#<id>): <msg>` | `feat(#42): add auth middleware` |
| PR body (closes) | `Closes #<id>` | `Closes #42` |
| PR body (partial) | `Addresses #<id> (completes ...)` | `Addresses #42 (completes T1, T2)` |
| Task in issue | `- [ ] **T<n>: Title** [tier-N]` | `- [ ] **T1: Add JWT** [tier-3]` |
| Timeline comment | `[shiplog/<kind>] #<id>: ...` | `[shiplog/discovery] #42: race condition` |
| Stacked branch | `issue/<new-id>-<slug>` | `issue/43-fix-race-condition` |
| Stacked PR title | `<type>(#<new-id>): ... [stack: #<parent>]` | `fix(#43): race cond [stack: #42]` |
| Memory entry | `#<id>: <decision>` | `#42: chose JWT over sessions` |

**Quiet Mode overrides:**

| Artifact | Convention | Example |
|----------|-----------|---------|
| Feature branch | per team convention | `feature/auth-middleware` |
| Knowledge branch | `<branch>--log` | `feature/auth-middleware--log` |
| Knowledge PR title | `[shiplog/worklog] <desc>` | `[shiplog/worklog] auth middleware decisions` |
| Knowledge PR base | the feature branch | base: `feature/auth-middleware` |

**Task IDs:** Tasks carry local IDs (`T1`, `T2`, ...) scoped to the issue. Commits use `#<id>/<Tn>`.

**Retrieval:** `gh issue list --search "#42"` | `git log --grep="#42"` | `git log --grep="#42/T1"` | `gh pr list --search "#42"`

---

## User-Facing Language

The phase numbers are internal workflow labels. Do not surface them to the user.

Preferred labels: `Plan Capture`, `Branch Setup`, `Discovery Handling`, `Commit Context`, `PR Timeline`, `History Lookup`, `Timeline Updates`.

---

## Agent Identity Signing

Every shiplog artifact must carry a provenance signature: `<role>: <family>/<version> (<tool>[, <qualifier>])`

Roles: `Authored-by`, `Updated-by`, `Reviewed-by`. See `references/signing.md` for full rules, edit provenance, and model detection.

---

## Integration Map

This skill ORCHESTRATES. It never reimplements.

| Activity | Delegate To |
|----------|-------------|
| Brainstorming | `superpowers:brainstorming` or `ork:brainstorming` |
| Planning | `superpowers:writing-plans` |
| Plan execution | `superpowers:executing-plans` |
| Committing | `ork:commit` or `commit-commands:commit` |
| Creating PRs | `ork:create-pr` |
| Finishing branches | `superpowers:finishing-a-development-branch` |
| Worktree creation | `superpowers:using-git-worktrees` |
| Stacked PRs | `ork:stacked-prs` |
| Storing decisions | `ork:remember` |

**Graceful degradation:** Try preferred skill → alternative → direct `gh`/`git` commands.

---

## Edge Cases

- **No issue exists:** Let the user work. At first commit or PR, offer to create a tracking issue.
- **Mid-work activation:** Check branch name for `issue/N-*`. If found, add catch-up timeline comment via `shiplog:timeline`. If not, offer retroactive issue creation.
- **Small tasks (< 30 min):** Lightweight protocol — issue optional, branch still created, PR sections can be brief.
- **Hotfix / emergency:** Fix first. Create issue and PR after, backfilling the timeline.

---

## Requirements

| Dependency | Purpose | Install |
|-----------|---------|---------|
| `gh` CLI | GitHub issue/PR/comment operations | `brew install gh` / `winget install GitHub.cli` |
| `git` | Branch, commit, diff, log | Pre-installed |
| GitHub remote | Must be in a git repo with GitHub remote | — |

All recommended skills are optional. Without them, shiplog falls back to direct `gh`/`git` commands.
