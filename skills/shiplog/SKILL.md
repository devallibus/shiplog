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

On first activation per project, determine which mode to use:

### Mode A: Full Mode (default)

For personal projects, OSS, teams that embrace documentation. Knowledge goes directly into issues and PRs.

### Mode B: Quiet Mode

For work environments where issues/PRs must stay clean. Knowledge lives in a **stacked knowledge branch** (`--log`) with its own PR targeting the feature branch.

```
<default-branch>
  └── feature/auth-middleware            ← Clean PR to <default-branch>
        └── feature/auth-middleware--log  ← Knowledge PR targets feature branch
```

Ask the user which mode on first activation. Remember the choice via `ork:remember` or note in project CLAUDE.md.

---

## Model-Tier Routing

Assign AI model tiers to phases based on cognitive demand. Advisory only — never blocks workflow.

| Tier | When to Use | Default Phases |
|------|------------|----------------|
| **tier-1** (reasoning) | Creative synthesis, architecture, narrative | Phase 1, Phase 5 |
| **tier-2** (capable) | Context loading, judgment, structured docs | Phase 2, Phase 3, Phase 6 |
| **tier-3** (fast) | Execution, routine commits, templates | Phase 4, Phase 7 |

**Resolution order:** Per-issue `## Model Routing` > `.shiplog/routing.md` > built-in defaults > silent.

**Routing prompt:** At phase transitions when the tier changes, suggest the model switch. For cross-tool switches, include the handoff location.

**Context handoff:** When transitioning tiers, write a self-contained handoff comment. The golden rule: if a tier-3 model reading the handoff would need to make a judgment call, the handoff is not specific enough.

See `references/model-routing.md` for full configuration format, setup wizard, handoff template, and examples.

---

## When This Skill Activates

**User-invocable:** `/shiplog`

**Auto-activate when ANY of these occur:**
- User says "let's plan", "let's brainstorm", or "let's design"
- User explicitly requests traceability or knowledge-graph tracking
- Creating a new issue or PR with intent to document decisions
- Mid-work discovery requiring a new issue or stacked PR
- User asks "where did we decide X?" or "what's the status of Y?"
- Resuming work on an existing issue or PR

**Do NOT auto-activate for:**
- Generic coding requests ("let's build", "let's fix", "add a feature")
- Simple bug fixes or refactors that don't need traceability
- Work where a more specific skill (TDD, debugging, etc.) is the better fit

---

## ID-First Naming Convention

All artifacts use `#ID` as the primary key for fast, token-efficient retrieval.

**Semantic tag vocabulary** for user-facing headings: `plan`, `session-start`, `commit-note`, `discovery`, `blocker`, `review-handoff`, `worklog`, `history`. Format: `[shiplog/<kind>] <human title>`.

| Artifact | Convention | Example |
|----------|-----------|---------|
| Branch | `issue/<id>-<slug>` | `issue/42-auth-middleware` |
| Commit | `<type>(#<id>): <msg>` | `feat(#42): add JWT validation` |
| PR title | `<type>(#<id>): <msg>` | `feat(#42): add auth middleware` |
| PR body | `Closes #<id>` | `Closes #42` |
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

**Retrieval:**
- `gh issue list --search "#42"` — everything linked to issue 42
- `git log --grep="#42"` — all commits for issue 42
- `gh pr list --search "#42"` — PRs closing issue 42
- `gh pr list --search "[shiplog/"` — all knowledge PRs (quiet mode)

---

## Decision Tree

```
User request arrives
  |
  +--> [Routing check: resolve tier for target phase]
  |
  +-- "Let's brainstorm/plan/design X"     -> PHASE 1 [tier-1]
  +-- "Work on issue #N"                    -> PHASE 2 [tier-2]
  +-- "I found a sub-problem"              -> PHASE 3 [tier-2]
  +-- "Let's commit" / "Ready for PR"      -> PHASE 4 [tier-3] or 5 [tier-1]
  +-- "Where did we decide X?"             -> PHASE 6 [tier-2]
  +-- Currently mid-work on a branch       -> PHASE 7 [tier-3]
```

---

## User-Facing Language

The phase numbers are internal workflow labels. Do not surface them to the user.

Preferred labels: `Plan Capture` (1), `Branch Setup` (2), `Discovery Handling` (3), `Commit Context` (4), `PR Timeline` (5), `History Lookup` (6), `Timeline Updates` (7).

Use descriptive status language: `capturing the plan`, `creating the branch`, `implementing the change`, `documenting the commit`, `opening the PR`.

---

## Shell Portability

Keep the workflow cross-platform. See `references/shell-portability.md` for full guidance and Bash/PowerShell patterns.

Key rules:
- Prefer `gh ... --body-file <temp-file>` for multiline content.
- Break chained shell commands into separate steps when the shell operator differs.
- Keep Bash examples as the primary path; add PowerShell notes where syntax diverges.

---

## PHASE 1: Brainstorm-to-Issue

**Routing:** tier-1 (reasoning).

1. **Run the brainstorm.** Delegate to `superpowers:brainstorming` or `ork:brainstorming`, or brainstorm inline for quick discussions.

2. **Capture as GitHub Issue (Full Mode).** Use the issue template from `references/phase-templates.md`. The issue body should include: Context, Design Summary, Approach, Alternatives Considered, Tasks (with tier tags), and Open Questions.

3. **Quiet Mode: defer capture.** Do not create the `--log` PR yet — the feature branch does not exist until PHASE 2. Save the brainstorm content locally and use it as the opening entry when the `--log` PR is created in PHASE 2.

4. **Store in knowledge graph.** If `ork:remember` is available, store the key decision.

5. **Transition.** Proceed to PHASE 2 if the user wants to start work. Write a context handoff if the next phase uses a different tier.

---

## PHASE 2: Issue-to-Branch

**Routing:** tier-2 (capable).

1. **Load context.** `gh issue view <N> --json title,body,labels,comments,milestone` and search knowledge graph.

2. **Create branch (worktree-first).** The skill cannot detect concurrent agents, so shared-checkout branch switching is unsafe by default. One branch, one worktree, one agent.

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

3. **Post timeline entry.** Full Mode: comment on the issue. Quiet Mode: create `--log` branch + PR targeting the feature branch. See `references/phase-templates.md` for templates.

4. **Load plan** if it exists. Delegate to `superpowers:executing-plans` or `ork:implement`.

---

## PHASE 3: Discovery Protocol

**Routing:** tier-2 (capable).

```
Discovery made during work
  +-- Small fix (< 30 min, < 100 lines)?  -> Fix inline, add timeline comment
  +-- Prerequisite for current work?       -> Stack a new branch/PR (Phase 3a)
  +-- Independent but important?           -> Create new issue, continue (Phase 3b)
  +-- Refactoring opportunity?             -> Create issue tagged "refactor"
```

**Phase 3a (stack a prerequisite):** Commit current progress. Create a new issue first (so the ID exists), then create the stacked branch. Cross-reference on the parent issue. See `references/phase-templates.md` for the discovery issue template.

**Phase 3b (independent discovery):** Create new issue (same template without "blocks parent"). Add timeline comment. Continue current work.

---

## PHASE 4: Commit-with-Context

**Routing:** tier-3 (fast).

1. **Delegate the commit.** Use `ork:commit` > `commit-commands:commit` > manual `git commit`. Format: `<type>(#<issue-id>): <description>`.

2. **Add context comment** for significant commits. Document the reasoning on the issue (Full Mode) or `--log` PR (Quiet Mode). See `references/phase-templates.md` for the commit context template.

**When to add context comments:** After significant functionality, unexpected discoveries, approach changes, or tricky bug fixes. NOT after trivial commits.

---

## PHASE 5: PR-as-Timeline

**Routing:** tier-1 (reasoning).

1. **Pre-PR checks.** Delegate to `ork:create-pr` or `superpowers:finishing-a-development-branch`.

2. **Create PR (Full Mode).** Use the PR timeline template from `references/phase-templates.md`. Body includes: Summary, `Closes #<N>`, Journey Timeline, Key Decisions, Changes, Testing, and Knowledge for Future Reference.

3. **Quiet Mode.** Create a clean feature PR (no shiplog content). Add a final summary comment to the `--log` PR.

4. **Link and store.** PR body includes `Closes #<issue>`. Store key learning in knowledge graph.

---

## PHASE 6: Knowledge Retrieval

**Routing:** tier-2 (capable).

1. **Search git history.** Issues, PRs, commits via `gh` and `git log --grep`.
2. **Search knowledge graph.** `/ork:memory search "keyword"` if available.
3. **Compile summary.** See `references/phase-templates.md` for the retrieval summary format.

---

## PHASE 7: Timeline Maintenance

**Routing:** tier-3 (fast).

Add timeline comments when: starting a new session, changing approach, finding something unexpected, completing a milestone, or getting blocked.

See `references/phase-templates.md` for the comment format. Comment types: `session-start`, `session-resume`, `milestone`, `discovery`, `approach-change`, `blocker`, `session-end`.

Delegate automatic checkbox updates to `ork:issue-progress-tracking` if available.

---

## Integration Map

This skill ORCHESTRATES. It never reimplements.

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
| Model routing | Built-in (no delegation) | Tier-based switch prompts + handoff |

**Graceful degradation:** Try preferred skill → alternative skill → direct `gh`/`git` commands. Minimum viable installation: `gh` CLI + `git` + this skill.

**Conflict avoidance:** This skill sets the WORKFLOW context. Delegated skills set IMPLEMENTATION details. This skill's templates take precedence for knowledge-graph fields.

---

## Edge Cases

**No issue exists:** Let the user work. At first commit or PR, offer to create a tracking issue and backfill.

**Mid-work activation:** Check for existing linked issue (from branch name `issue/N-*`). If found, add a catch-up timeline comment. If not, offer retroactive issue creation.

**Small tasks (< 30 min):** Lightweight protocol — issue optional, branch still created, PR timeline sections can be brief.

**Hotfix / emergency:** Fix first. Create issue and PR after, backfilling the timeline.

**Session resume:** Detect the issue from the current branch name or worktree. If the branch has an existing worktree, `cd` into it. Find linked PRs, read comments, add "Session resumed" timeline comment. Continue with Phase 7.

**Quiet mode — feature PR merges:** Close the `--log` PR. Knowledge is preserved in closed PR history.

**Quiet mode — feature branch rebased:** Rebase `--log` branch onto updated feature branch. Use `--force-with-lease`.

**Model routing mismatch:** If the user continues without switching models, proceed normally. Never block or repeat the prompt.

---

## Requirements

| Dependency | Purpose | Install |
|-----------|---------|---------|
| `gh` CLI | GitHub issue/PR/comment operations | `brew install gh` / `winget install GitHub.cli` |
| `git` | Branch, commit, diff, log | Pre-installed |
| GitHub remote | Must be in a git repo with GitHub remote | — |

All recommended skills are optional. The current optional integrations are listed below. Without them, shiplog falls back to direct `gh`/`git` commands.

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

### Codex agent identity

When signing artifacts from Codex, read model identity from `~/.codex/config.toml` (`model`, `model_reasoning_effort`). Corroborate with `~/.codex/models_cache.json`. Sign as `OpenAI Codex (<model>, reasoning effort: <effort>)`. Fall back to `OpenAI Codex, based on GPT-5` if unavailable.

Model identity detection is also used by model-tier routing to verify the current model matches the recommended tier. See [Model-Tier Routing](#model-tier-routing).
