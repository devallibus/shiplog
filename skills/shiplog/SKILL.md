---
name: shiplog
description: Git-as-knowledge-graph workflow for traceability. Use when planning work, brainstorming designs, creating/managing issues and PRs, tracking architectural decisions, or resuming prior sessions. Slash command /shiplog.
---

# Shiplog

The captain's log for your codebase. Every decision, discovery, and change logged as you ship code.

Use GitHub as a complete knowledge graph where every brainstorm, commit, review, and decision is traceable. This skill orchestrates existing skills and references; it defines when and how to invoke them and what documentation protocol to follow.

## Core Principle

**Nothing gets lost.** Every brainstorm becomes an issue. Every issue drives a branch. Every branch produces a PR. Every PR is a timeline of the entire journey. Git becomes the uber-memory.

---

## Mode Selection

On first activation per project, ask the user which mode to use:

- **Full Mode** (default): Knowledge goes directly into issues and PRs. For personal projects, OSS, and teams that embrace documentation.
- **Quiet Mode**: Knowledge lives in a stacked knowledge branch (`<branch>--log`) with its own PR targeting the feature branch. For work environments where issues and PRs must stay clean.

Remember the choice via `ork:remember` or note it in project instructions.

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
- User references an issue or PR by number

**Do NOT auto-activate for:**
- Generic coding requests that do not need traceability
- Simple bug fixes or refactors that do not need durable workflow history
- Work where a more specific skill is the better fit

---

## Decision Tree

Match the user's intent and load the corresponding sub-skill:

```
User request arrives
  +--> [If .shiplog/routing.md missing: run setup from references/model-routing.md]
  +--> ["/shiplog models": re-run setup prompt, update config]
  |
  +-- "Let's brainstorm/plan/design X" -> shiplog:brainstorm
  +-- "Work on issue #N"               -> shiplog:branch
  +-- "I found a sub-problem"          -> shiplog:discovery
  +-- "Let's commit"                   -> shiplog:commit
  +-- "Ready for PR"                   -> shiplog:pr
  +-- "Where did we decide X?"         -> shiplog:lookup
  +-- Currently mid-work on a branch    -> shiplog:timeline
```

---

## ID-First Naming Convention

All artifacts use `#ID` as the primary key for fast, token-efficient retrieval.

**Semantic tag vocabulary** for user-facing headings: `plan`, `session-start`, `commit-note`, `discovery`, `blocker`, `implementation-issue`, `review-handoff`, `worklog`, `history`, and `amendment`. Format: `[shiplog/<kind>] <human title>`.

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

## Triage Field Maintenance

Issue envelope triage fields (`readiness`, `task_count`, `tasks_complete`, `max_tier`) and lifecycle labels must be kept current so triage scans produce accurate results.

| Event | Envelope update | Label update |
|-------|----------------|--------------|
| Issue created (Phase 1) | Set all four triage fields at creation | Apply `shiplog/ready` if tasks are scoped and no blockers |
| Branch created (Phase 2) | Set `readiness: in-progress` | Replace lifecycle label with `shiplog/in-progress` |
| Task checked off (Phase 4) | Increment `tasks_complete`, recompute `max_tier` from remaining tasks | - |
| All tasks complete | Set `readiness: done`, clear `max_tier` | - |
| Blocker found (Phase 3) | Set `readiness: blocked` | Add `shiplog/blocker` |
| Blocker cleared | Restore previous `readiness` (`in-progress` or `ready`) | Remove `shiplog/blocker` |
| PR created (Phase 5) | Set `readiness: done` if all tasks shipped | Replace lifecycle label with `shiplog/needs-review` |
| PR merged and issue closed | - | Remove all lifecycle labels |

Edit the issue body in place when these fields change. Triage metadata is derived state, so refreshing it does not require `Updated-by:` provenance.

---

## Mandatory Issue Capture

Implementation trouble that materially affects the work must be durably recorded before the agent proceeds to the next material step or ends the turn.

### What counts as a relevant implementation issue

- Failed attempts
- Hidden dependencies
- Risky workarounds
- Scope surprises
- Verification gaps
- Environment or tooling friction

### What does not require capture

- Normal iteration where the final approach is obvious from the diff
- Minor typos or lint fixes resolved in the same commit
- Expected complexity that matches the task description

### Capture rule

| Situation | Artifact | Where |
|-----------|----------|-------|
| Issue is local and resolved inline | Timeline comment (`[shiplog/implementation-issue]`) | Issue (Full Mode) or `--log` PR (Quiet Mode) |
| Issue warrants follow-up, scope split, or long-term retrieval | New linked issue | GitHub issue with cross-reference on parent |

The timeline comment is the minimum: one paragraph explaining what happened, why it matters, and how it was resolved or deferred.

---

## Agent Identity Signing

Every shiplog artifact must carry a provenance signature: `<role>: <family>/<version> (<tool>[, <qualifier>])`

Roles: `Authored-by`, `Updated-by`, `Reviewed-by`. See `references/signing.md` for full rules, edit provenance, and model detection.

---

## Integration Map

This skill orchestrates. For activities that directly produce shiplog artifacts, convention-enforced workflows are internalized in `references/`.

| Activity | Primary | External (optional) | Shiplog Adds |
|----------|---------|---------------------|--------------|
| Committing | `references/commit-workflow.md` | `ork:commit`, `commit-commands:commit` | ID-first format, task refs, context comments |
| Creating PRs | `references/pr-workflow.md` | `ork:create-pr` | Timeline body, envelopes, labels, review gate |
| Finishing branches | `references/pr-workflow.md` | `superpowers:finishing-a-development-branch` | Review gate enforcement |
| Brainstorming | `superpowers:brainstorming` or `ork:brainstorming` | - | Issue creation from output |
| Planning | `superpowers:writing-plans` | - | Issue task list mirroring |
| Plan execution | `superpowers:executing-plans` | - | Timeline comments at checkpoints |
| Worktree creation | `superpowers:using-git-worktrees` | - | Branch-issue linking |
| Stacked PRs | `ork:stacked-prs` | - | Discovery-driven stacking protocol |
| Storing decisions | `ork:remember` | - | Structured `#ID: decision` entries |

**Internalized workflows:** Commit and PR workflows are internalized in `references/` so shiplog conventions win over third-party defaults.

**Graceful degradation:** Internalized workflow -> external skill -> direct `gh`/`git` commands.

---

## Edge Cases

- **No issue exists:** Let the user work. At first commit or PR, offer to create a tracking issue.
- **Mid-work activation:** Check branch name for `issue/N-*`. If found, add catch-up timeline comment via `shiplog:timeline`. If not, offer retroactive issue creation.
- **Small tasks (< 30 min):** Lightweight protocol - issue optional, branch still created, PR sections can be brief.
- **Hotfix / emergency:** Fix first. Create issue and PR after, backfilling the timeline.

---

## Requirements

| Dependency | Purpose | Install |
|-----------|---------|---------|
| `gh` CLI | GitHub issue/PR/comment operations | `brew install gh` / `winget install GitHub.cli` |
| `git` | Branch, commit, diff, log | Pre-installed |
| GitHub remote | Must be in a git repo with GitHub remote | - |

All recommended skills are optional. Internalized workflows live in `references/`; external skills remain optional enhancements.