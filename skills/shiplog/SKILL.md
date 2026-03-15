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

The skill cannot switch models — only the user can. Routing is purely advisory.

| Tier | When to Use | Default Phases |
|------|------------|----------------|
| **tier-1** (reasoning) | Creative synthesis, architecture, narrative | Phase 1, Phase 5 |
| **tier-2** (capable) | Context loading, judgment, structured docs | Phase 2, Phase 3, Phase 6 |
| **tier-3** (fast) | Execution, routine commits, templates | Phase 4, Phase 7 |

### Routing behavior

Configured in `.shiplog/routing.md` (one field). Resolution order: per-issue `## Model Routing` > `.shiplog/routing.md` > built-in default (`confirm`).

| Mode | Behavior |
|------|----------|
| `confirm` (default) | Pause at tier transitions and ask the user before proceeding |
| `warn` | Show a one-line banner at tier transitions, don't stop |
| `off` | Silent. No routing prompts; handoffs still apply when work transfers |

**`/shiplog models`:** Re-runs the setup prompt at any time to change the routing mode.

**First activation:** If `.shiplog/routing.md` is missing, run the setup prompt from `references/model-routing.md` before the first phase entry check.

### Phase entry check (Step 0)

Every phase begins with this check:

1. Read routing mode from per-issue override > `.shiplog/routing.md` > default (`confirm`).
2. If work is transferring to another model/tool, write a handoff comment per `references/model-routing.md`.
3. If mode is `off`, skip to Step 1.
4. Compare the entering phase's tier to the previous phase's tier. If same, skip to Step 1.
5. If mode is `confirm`: emit the routing prompt and wait for user acknowledgment.
6. If mode is `warn`: emit the routing banner and continue immediately.

**Routing mismatch:** If the user continues without switching models, proceed normally. Never block or repeat the prompt.

See `references/model-routing.md` for routing prompt format, handoff template, and tier reference table.

---

## When This Skill Activates

**User-invocable:** `/shiplog`, `/shiplog models`

**`/shiplog models`:** Re-runs the routing setup prompt. See [Model-Tier Routing](#model-tier-routing).

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

**Task IDs:** Tasks in issue bodies carry local IDs (`T1`, `T2`, ...) scoped to the issue. Task IDs appear in commit messages as `#<id>/<Tn>` and in timeline comments as `#<id>/<Tn>`. They are not globally unique — the issue number provides the namespace.

**Retrieval:**
- `gh issue list --search "#42"` — everything linked to issue 42
- `git log --grep="#42"` — all commits for issue 42
- `git log --grep="#42/T1"` — commits for task T1 of issue 42
- `gh pr list --search "#42"` — PRs closing issue 42
- `gh pr list --search "[shiplog/"` — all knowledge PRs (quiet mode)

---

## Decision Tree

```
User request arrives
  |
  +--> [If .shiplog/routing.md missing: run setup prompt]
  +--> ["/shiplog models": re-run setup prompt, update config]
  |
  +--> [Step 0: phase entry check — compare tier, apply routing mode]
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

<!-- routing: tier-1 -->

0. **Routing check (Step 0).** Run the [phase entry check](#phase-entry-check-step-0). On first activation, if `.shiplog/routing.md` is missing, run the setup prompt first.

1. **Run the brainstorm.** Delegate to `superpowers:brainstorming` or `ork:brainstorming`, or brainstorm inline for quick discussions.

2. **Capture as GitHub Issue (Full Mode).** Use the issue template from `references/phase-templates.md`. The issue body should include: Context, Design Summary, Approach, Alternatives Considered, Tasks (with tier tags and contract fields), and Open Questions. Sign the issue body per [Agent identity signing](#agent-identity-signing).
   Before writing the final issue body, classify factual claims:
   - **Internal claims** about this repository's code, tests, configuration, or committed docs can be verified from the repo itself. The codebase is the source of truth.
   - **External claims** about third-party tools, URLs, APIs, platform capabilities, pricing, distribution channels, or ecosystem behavior must be verified against primary sources before they are stated as facts.
   - If an external claim cannot be verified yet, keep it explicitly marked as `[unverified]` and treat it as a hypothesis, not settled input. Do not turn an unverified claim into a task requirement, acceptance criterion, or architectural decision without a verification step.
   - Brainstorming can stay exploratory, but the final issue body must distinguish verified facts from open questions and hypotheses.

3. **Quiet Mode: defer capture.** Do not create the `--log` PR yet — the feature branch does not exist until PHASE 2. Save the brainstorm content locally and use it as the opening entry when the `--log` PR is created in PHASE 2.

4. **Store in knowledge graph.** If `ork:remember` is available, store the key decision.

5. **Transition.** Proceed to PHASE 2 if the user wants to start work.

---

## PHASE 2: Issue-to-Branch

<!-- routing: tier-2 -->

0. **Routing check (Step 0).** Run the [phase entry check](#phase-entry-check-step-0).

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

3. **Post timeline entry.** Full Mode: comment on the issue. Quiet Mode: create `--log` branch + PR targeting the feature branch. See `references/phase-templates.md` for templates. Sign the posted artifact per [Agent identity signing](#agent-identity-signing).

4. **Load plan** if it exists. Delegate to `superpowers:executing-plans` or `ork:implement`.
   For delegated or tier-3 work, the plan should define a contract: allowed files, forbidden changes, stop conditions, verification, return artifact, and decision budget.

---

## PHASE 3: Discovery Protocol

<!-- routing: tier-2 -->

0. **Routing check (Step 0).** Run the [phase entry check](#phase-entry-check-step-0).

1. **Classify the discovery.** Use the routing-aware decision tree below to decide whether to fix inline, stack a prerequisite, or create a new issue.

```
Discovery made during work
  +-- Small fix (< 30 min, < 100 lines)?  -> Fix inline, add timeline comment
  +-- Prerequisite for current work?       -> Stack a new branch/PR (Phase 3a)
  +-- Independent but important?           -> Create new issue, continue (Phase 3b)
  +-- Refactoring opportunity?             -> Create issue tagged "refactor"
```

**Phase 3a (stack a prerequisite):** Commit current progress. Create a new issue first (so the ID exists), then create the stacked branch. Cross-reference on the parent issue. See `references/phase-templates.md` for the discovery issue template. Sign both the discovery issue and the parent cross-reference comment per [Agent identity signing](#agent-identity-signing).

**Phase 3b (independent discovery):** Create new issue (same template without "blocks parent"). Add timeline comment. Continue current work. Sign each posted artifact per [Agent identity signing](#agent-identity-signing).

---

## PHASE 4: Commit-with-Context

<!-- routing: tier-3 -->

0. **Routing check (Step 0).** Run the [phase entry check](#phase-entry-check-step-0).

1. **Delegate the commit.** Use `ork:commit` > `commit-commands:commit` > manual `git commit`. Format: `<type>(#<issue-id>): <description>`. When a commit addresses a specific task, include the task ID: `<type>(#<issue-id>/<Tn>): <description>`.

2. **Add context comment** for significant commits. Document the reasoning and verification on the issue (Full Mode) or `--log` PR (Quiet Mode). See `references/phase-templates.md` for the commit context template. Sign the comment per [Agent identity signing](#agent-identity-signing).

**When to add context comments:** After significant functionality, unexpected discoveries, approach changes, or tricky bug fixes. NOT after trivial commits.

**Verification profiles:** When a verification profile is active, include verification evidence in commit context and PR timeline. See `references/verification-profiles.md` for profile configuration, behavior-spec protocol, and evidence requirements.

---

## PHASE 5: PR-as-Timeline

<!-- routing: tier-1 -->

0. **Routing check (Step 0).** Run the [phase entry check](#phase-entry-check-step-0).

1. **Pre-PR checks.** Delegate to `ork:create-pr` or `superpowers:finishing-a-development-branch`.

2. **Create PR (Full Mode).** Use the PR timeline template from `references/phase-templates.md`. Body includes: Summary, `Closes #<N>`, Journey Timeline, Key Decisions, Changes, Testing, and Knowledge for Future Reference. Sign the PR body per [Agent identity signing](#agent-identity-signing).

3. **Quiet Mode.** Create a clean feature PR (no shiplog content). Add a final summary comment to the `--log` PR. Sign the summary comment per [Agent identity signing](#agent-identity-signing).

4. **Review gate.** Every PR requires cross-model review before merge. See `references/closure-and-review.md` for the review protocol, sign-off format, and merge authorization rules. Sign every review artifact per [Agent identity signing](#agent-identity-signing).

5. **Link and store.** PR body includes `Closes #<issue>` when the PR fully resolves the issue. For partial delivery — when some tasks are complete but others are blocked or deferred — use `Addresses #<issue> (completes T1, T2, ...)` and list remaining tasks in the PR body. The issue stays open. Post a `[shiplog/milestone]` comment on the issue after merge listing what shipped, and a `[shiplog/blocker]` comment for any externally-blocked tasks. See `references/closure-and-review.md` §1 for the partial-delivery rules. Store key learning in knowledge graph.

6. **Closure verification (optional).** When an issue will be closed manually or the mapping between the evidence and the issue is non-obvious, optionally delegate a bounded verifier agent per `references/closure-and-review.md`. The verifier audits the evidence and returns a verification note, but the higher-tier actor still decides whether to close, keep open, or escalate.

---

## PHASE 6: Knowledge Retrieval

<!-- routing: tier-2 -->

0. **Routing check (Step 0).** Run the [phase entry check](#phase-entry-check-step-0).
1. **Search git history.** Issues, PRs, commits via `gh` and `git log --grep`.
2. **Prefer structured envelopes.** When artifacts carry machine-readable envelopes, fetch envelope metadata before reading full threads. See `references/artifact-envelopes.md` for the envelope format, artifact kinds, supersession model, and `gh` query patterns.
3. **Search knowledge graph.** `/ork:memory search "keyword"` if available.
4. **Compile summary.** See `references/phase-templates.md` for the retrieval summary format.

---

## PHASE 7: Timeline Maintenance

<!-- routing: tier-3 -->

0. **Routing check (Step 0).** Run the [phase entry check](#phase-entry-check-step-0).

1. **Add timeline comments** when: starting a new session, changing approach, finding something unexpected, completing a milestone, or getting blocked. Sign each timeline comment per [Agent identity signing](#agent-identity-signing).

2. **Use the standard format.** See `references/phase-templates.md` for the comment format. Comment types: `session-start`, `session-resume`, `milestone`, `discovery`, `approach-change`, `blocker`, `session-end`.

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
| Model routing | Built-in | Phase entry check (Step 0), routing prompts, handoffs |

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

### Agent identity signing

Every shiplog artifact (comments, PR bodies, review sign-offs) must carry a provenance signature in the canonical format. All templates in `references/phase-templates.md` include the signature line.

**Canonical grammar:**

```
<role>: <family>/<version> (<tool>[, <qualifier>])
```

| Field | Values | Examples |
|-------|--------|---------|
| `role` | `Authored-by`, `Updated-by`, or `Reviewed-by` | — |
| `family` | Provider name, lowercase | `claude`, `openai`, `google` |
| `version` | Model identifier | `opus-4.6`, `sonnet-4`, `gpt-5.4` |
| `tool` | Runtime environment, lowercase | `claude-code`, `codex`, `cursor` |
| `qualifier` | Optional tool-specific metadata | `effort: high`, `effort: medium` |

**Searching:** `Authored-by:` → original authorship. `Updated-by:` → later material editors. `Reviewed-by:` → review artifacts. `claude/` → all Claude artifacts. `(codex` → all Codex artifacts (matches both `(codex)` and `(codex, effort: high)`).

**Model detection per tool:**

| Tool | Source | Example signature |
|------|--------|-------------------|
| Claude Code | System prompt model name | `claude/opus-4.6 (claude-code)` |
| Codex | `~/.codex/config.toml` `model` + `model_reasoning_effort` | `openai/gpt-5.4 (codex, effort: high)` |
| Cursor | System prompt model identifier | `claude/opus-4.6 (cursor)` |
| Other | Best available model identifier | `<family>/<version> (<tool>)` |

**Correction rule:** If a shiplog artifact carries an incorrect or incomplete signature, correct it in place when the platform allows editing. Otherwise post an immediate follow-up correction.

**Edit provenance rule:**
- `Authored-by:` records the original author of an artifact body.
- `Updated-by:` records a later model or human who materially edits that same artifact body. Preserve the original `Authored-by:` line and append a new `Updated-by:` line for each material edit, newest last.
- `Reviewed-by:` is review-only. Do not use it for authorship or edit attribution.
- A **material edit** changes meaning, facts, scope, requirements, acceptance criteria, verification results, review disposition, or a handoff contract. Typos, formatting cleanups, and link-only fixes are cosmetic and do not need `Updated-by:`.
- **Edit in place** when the artifact is meant to stay the single canonical current body: issue bodies, PR bodies, and latest-wins status/history artifacts. When such an artifact is materially edited, refresh its envelope `updated_at` and add `updated_by` plus `edit_kind` fields when an envelope exists.
- **Post an amendment artifact** instead of silently rewriting when the artifact is an accumulated event whose original text matters for auditability: handoffs, verification comments, commit-note comments, review sign-offs, and other major signed timeline entries. Use a new signed artifact that references the prior artifact and add envelope `amends` or `supersedes` markers as appropriate.
- Use `supersedes` when the new artifact replaces the old one as the canonical current version. Use `amends` when the new artifact corrects or clarifies the earlier artifact but both should remain visible in history.
- If the platform does not expose reliable edit history or does not allow editing, prefer an amendment artifact even for corrections that would otherwise be safe in place.

Model identity detection is also used by model-tier routing to verify the current model matches the recommended tier. See [Model-Tier Routing](#model-tier-routing).
