# shiplog

The captain's log for your codebase. Every decision, discovery, and change logged as you ship code.

**shiplog** turns GitHub into a complete knowledge graph for your project. Every brainstorm becomes an issue. Every issue drives a branch. Every branch produces a PR with a full timeline of the journey — what you planned, what you discovered, what you decided, and why.

Neither you nor your AI coding assistant ever loses context again.

```
Brainstorm → GitHub Issue → Branch → Commits with Context → PR with Timeline
     ↑                                      ↑
     |              Discoveries → Stacked PRs / New Issues
     |
     └── Knowledge Retrieval (search issues, PRs, commits, memory)
```

## Why shiplog

AI coding assistants lose context between sessions. Decisions vanish into chat history. Code gets merged without anyone knowing *why* it was written that way.

shiplog fixes this by making your git history the single source of truth — not just for *what* changed, but for the reasoning, discoveries, and trade-offs behind every change. It works with Claude Code, Codex, and Cursor.

## Feature Overview

| Feature | What It Does |
|---------|-------------|
| [Two Modes](#two-modes) | Full mode for OSS, quiet mode for clean team PRs |
| [7-Phase Workflow](#the-7-phases) | Brainstorm → Issue → Branch → Commit → PR → Retrieval → Maintenance |
| [Cross-Model Review](#cross-model-review) | No PR merges without independent review from a different model or a human |
| [Evidence-Linked Closure](#evidence-linked-closure) | No issue closes without linked proof (commit, PR, or decision artifact) |
| [Model-Tier Routing](#model-tier-routing) | Route reasoning models to planning, fast models to implementation |
| [Delegation Contracts](#delegation-contracts) | Structured handoffs with allowed files, stop conditions, decision budgets |
| [Verification Profiles](#verification-profiles) | Configurable testing policies: behavior-spec, red-green, structural, mutation |
| [Artifact Envelopes](#artifact-envelopes) | Machine-readable metadata for low-token agent retrieval |
| [Agent Identity Signing](#agent-identity-signing) | Provenance tracking on every artifact — who wrote it, which model, which tool |
| [GitHub Labels](#github-labels) | Shiplog bootstraps and applies a compact label vocabulary to issues and PRs |
| [Discovery Protocol](#discovery-protocol) | Mid-work findings get tracked as stacked PRs or new issues, never lost |
| [ID-First Convention](#id-first-convention) | Every artifact keyed by `#ID` — one search finds everything |
| [Shell Portability](#shell-portability) | Full Bash and PowerShell support, cross-platform from day one |
| [Worktree-First Workflow](#worktree-first-workflow) | One branch, one worktree, one agent — safe concurrent operation |

## Two Modes

**Full Mode** (default) — Knowledge goes directly into issues and PRs. Great for personal projects and OSS.

**Quiet Mode** — For work environments where issues/PRs must stay clean. Knowledge lives in a stacked `--log` branch with its own PR targeting the feature branch. Your team sees clean PRs; the full reasoning is one click away.

```
main
  └── feature/auth-middleware            ← Clean PR (your team sees this)
        └── feature/auth-middleware--log  ← Knowledge PR (full timeline here)
```

## The 7 Phases

| Phase | Trigger | What Happens | Default Tier |
|-------|---------|-------------|-------------|
| 1. Brainstorm-to-Issue | "Let's plan X" | Brainstorm captured as GitHub Issue with tier-aware task list | tier-1 (reasoning) |
| 2. Issue-to-Branch | "Work on #42" | Worktree created, timeline started, plan loaded | tier-2 (capable) |
| 3. Discovery Protocol | Sub-problem found | Stacked PR, new issue, or inline fix — nothing lost | tier-2 (capable) |
| 4. Commit-with-Context | Ready to commit | Commit + reasoning comment with verification evidence | tier-3 (fast) |
| 5. PR-as-Timeline | Work complete | PR with full journey timeline, decisions table, lessons learned | tier-1 (reasoning) |
| 6. Knowledge Retrieval | "Where did we decide X?" | Search across issues, PRs, commits, and memory | tier-2 (capable) |
| 7. Timeline Maintenance | Mid-work | Session, milestone, blocker, and approach-change comments | tier-3 (fast) |

## Cross-Model Review

Every PR requires a positive review from an independent reviewer — a different AI model or a human — before it can merge. A single model authoring, reviewing, and merging its own work is the anti-pattern this protocol prevents.

- **Review artifacts** carry a signed `Reviewed-by:` line with model family, version, and tool
- **Three dispositions:** approve (merge authorized), request-changes (must address), comment (non-blocking)
- **Smart target selection:** the reviewer automatically skips PRs it authored and reviews only cross-model candidates
- **Self-review as audit trail:** when no other model is available, a self-review is recorded but does *not* satisfy the gate — the PR stays open until an independent reviewer approves
- **Risk-based tiers:** documentation needs 1 cross-model approve; security-sensitive changes recommend human confirmation

When spawning a reviewer isn't possible, shiplog generates a self-contained **review contract** you can hand to any other model or tool.

**Merge conditions:**
1. At least one cross-model (or human) review with `Disposition: approve`
2. All `request-changes` reviews addressed
3. PR body includes `Closes #<N>` linking to the tracking issue
4. Issue closure has linked evidence (the merged PR itself)

## Evidence-Linked Closure

No issue closes without linked evidence:

| Evidence Type | When To Use |
|---------------|-------------|
| Commit URL on default branch | The fix is a code change that has been merged |
| Merged PR URL | The fix is better represented by the full PR |
| Discussion or decision artifact | Resolved by a decision, policy change, or external action |

When a PR with `Closes #N` merges, the PR itself serves as evidence — no separate closure comment is needed if the PR body carries a clear summary. For manual closure, a structured comment with evidence link, verification statement, and disposition is required. Umbrella issues require all children closed first. Ambiguous matches are escalated — never silently closed.

## Model-Tier Routing

Assign AI model tiers to phases — use your best model for brainstorming and PR synthesis, a fast model for implementation and commits. Shiplog prompts you to switch at phase transitions and writes context handoffs so the receiving model can execute without guessing.

| Tier | Profile | Example Models |
|------|---------|----------------|
| tier-1 (reasoning) | Creative synthesis, architecture, trade-off evaluation | Claude Opus, GPT-5.4 high, o3 |
| tier-2 (capable) | Context loading, scope judgment, structured docs | Claude Sonnet, GPT-5.4 medium |
| tier-3 (fast) | Execution speed, template filling, routine ops | Claude Haiku, Cursor Composer, GPT-4o-mini |

Configure per-project in `.shiplog/routing.md` or per-issue in the issue body. A first-activation setup wizard detects your platform and suggests model assignments.

## Delegation Contracts

When a reasoning model hands work to a faster model, shiplog treats it as a first-class delegation with a structured contract:

```markdown
### Contract
- **Allowed files:** `src/auth.ts`, `src/middleware.ts`
- **Must not change:** public API surface, existing test expectations
- **Stop and ask if:** scope needs to widen or a judgment call is required
- **Verification required:** all tests pass, no new lint warnings
- **Return artifact:** changed file list + verification note
- **Decision budget:** none
```

The golden rule: if a tier-3 model reading the handoff would need to make a judgment call, the handoff is not specific enough.

Same-tool switches (e.g., Opus → Sonnet in Claude Code) get light handoffs since conversation context carries over. Cross-tool switches (e.g., Claude Code → Cursor) get fully self-contained handoffs since the new tool starts cold.

## Verification Profiles

Configurable testing and semantic-stability policies that travel with issues and task contracts. Shiplog defines the *policy* — language/framework skills provide the actual test commands.

| Profile | Purpose |
|---------|---------|
| `none` | No verification requirements (default) |
| `behavior-spec` | Acceptance scenarios for new/changed behavior, with ask-before-changing rules |
| `red-green` | Fail-first unit tests for changed behavior |
| `structural` | Quality analysis (e.g., CRAP score thresholds) on changed modules |
| `mutation` | Differential mutation testing on changed lines only |

Profiles are composable, hierarchical (project → issue → task, tighten-only), and produce verification evidence that appears in commit context comments and PR timelines. The `behavior-spec` profile enforces fail-first confirmation and requires explicit acknowledgment before modifying existing scenarios — preventing silent behavior redefinition.

Configure in `.shiplog/verification.md`.

## Artifact Envelopes

Machine-readable metadata in HTML comments for low-token agent retrieval. Human-facing prose stays readable; hidden envelopes let agents filter before reading deeply.

```html
<!-- shiplog:
kind: state
issue: 42
branch: issue/42-auth-middleware
status: in-progress
phase: 2
updated_at: 2026-03-14T12:00:00Z
-->
```

**Why invisible?** Agents fetch envelope metadata first, then read the full body only when needed — reducing token cost on long threads. Humans see clean markdown; machines get structured data.

**How to inspect:** Envelopes are hidden in rendered GitHub views. To see them:
```bash
# Raw body includes the HTML comment
gh issue view 42 --json body --jq '.body'

# Find all shiplog envelopes on an issue
gh issue view 42 --json body,comments --jq '
  [.body, .comments[].body]
  | map(select(test("<!-- shiplog:")))
'
```
Or click **Edit** on any issue or comment in GitHub to see the envelope in the raw source.

**7 envelope kinds:**

| Kind | Purpose | Uniqueness |
|------|---------|------------|
| `state` | Current status snapshot | latest-wins |
| `handoff` | Context transfer between tiers/tools | accumulating |
| `verification` | Testing or review evidence | accumulating |
| `commit-note` | Reasoning behind a commit | accumulating |
| `review-handoff` | Review request or completion | accumulating |
| `blocker` | Something preventing progress | latest-wins |
| `history` | Retrospective summary | latest-wins |

For **latest-wins** kinds, the most recent envelope is current — older ones are historical. For **accumulating** kinds, multiple envelopes coexist, each capturing a distinct event. Supersession markers link newer artifacts to the ones they replace, preserving the full timeline while making current state instantly retrievable.

## Agent Identity Signing

Every shiplog artifact carries a provenance signature:

```
Authored-by: claude/opus-4.6 (cursor)
```

The grammar: `<role>: <family>/<version> (<tool>[, <qualifier>])`. Roles are `Authored-by` and `Reviewed-by`. The signing system auto-detects the current model from the platform (Claude Code system prompt, Codex config, Cursor system prompt) and makes provenance searchable:

```bash
# Find all artifacts authored by Claude
gh issue list --search "Authored-by: claude/"

# Find all Codex artifacts
gh pr list --search "(codex"

# Find all reviews
gh pr list --search "Reviewed-by:"
```

## Discovery Protocol

When you find a sub-problem mid-work, shiplog categorizes it and routes it:

| Discovery | Action |
|-----------|--------|
| Small fix (< 30 min, < 100 lines) | Fix inline, add timeline comment |
| Prerequisite for current work | Stack a new branch/PR, cross-reference on parent issue |
| Independent but important | Create new issue, continue current work |
| Refactoring opportunity | Create issue tagged "refactor" |

Stacked prerequisites get their own issue (so the ID exists for linking), their own branch, and a cross-reference on the parent. Nothing falls through the cracks.

## ID-First Convention

All artifacts use `#ID` as the primary key for fast retrieval:

| Artifact | Convention | Example |
|----------|-----------|---------|
| Branch | `issue/<id>-<slug>` | `issue/42-auth-middleware` |
| Commit | `<type>(#<id>): <msg>` | `feat(#42): add JWT validation` |
| PR title | `<type>(#<id>): <msg>` | `feat(#42): add auth middleware` |
| PR body | `Closes #<id>` | `Closes #42` |
| Timeline comment | `[shiplog/<kind>] #<id>: ...` | `[shiplog/discovery] #42: race condition` |
| Stacked PR title | `<type>(#<new-id>): ... [stack: #<parent>]` | `fix(#43): race cond [stack: #42]` |
| Memory | `#<id>: <decision>` | `#42: chose JWT over sessions` |

Timeline comments use semantic tags: `plan`, `session-start`, `session-resume`, `commit-note`, `discovery`, `milestone`, `approach-change`, `blocker`, `review-handoff`, `worklog`, `history`, `session-end`.

Retrieve everything about issue 42:
```bash
gh issue list --search "#42" --state all    # issues
gh pr list --search "#42" --state all       # PRs
git log --all --oneline --grep="#42"         # commits
```

## GitHub Labels

shiplog also manages a compact repository label vocabulary so work stays filterable at a glance, even before anyone opens the issue or PR body.

The skill bootstraps labels on first write, applies them at creation time, and backfills them when the mapping is obvious from shiplog conventions like `[shiplog/plan]`, `[shiplog/discovery]`, `Closes #<N>`, or Quiet Mode `--log` branches.

The built-in label set is:
- `shiplog/plan`
- `shiplog/discovery`
- `shiplog/blocker`
- `shiplog/worklog`
- `shiplog/history`
- `shiplog/verification`
- `shiplog/stacked`
- `shiplog/issue-driven`
- `shiplog/quiet-mode`

`shiplog/blocker` is stateful: add it when progress is blocked, remove it when the blocker clears.
## Shell Portability

shiplog is cross-platform from day one. All templates and commands work on both Bash (macOS/Linux) and PowerShell (Windows). The key pattern: use `gh ... --body-file <temp-file>` for multiline content instead of inline heredocs.

```bash
# Bash
body_file="$(mktemp)"
cat > "$body_file" <<'EOF'
## Timeline comment content
EOF
gh issue comment 42 --body-file "$body_file"
rm "$body_file"
```

```powershell
# PowerShell
$bodyPath = Join-Path $PWD '.tmp-gh-body.md'
Set-Content -Path $bodyPath -Value @"
## Timeline comment content
"@ -NoNewline
gh issue comment 42 --body-file $bodyPath
Remove-Item $bodyPath -Force
```

See `references/shell-portability.md` for worktree setup, variable capture syntax, and escaping differences.

## Worktree-First Workflow

Branches are created in git worktrees by default — one branch, one worktree, one agent. This prevents branch-switching conflicts when multiple agents or sessions are active. In-place checkout is only used when the user explicitly requests it.

## Install

### 1. Cross-platform with `npx skills add`

The fastest verified install path is the Vercel Labs CLI:

```bash
npx skills add devallibus/shiplog --skill shiplog
```

Target a specific agent explicitly when you want tighter control:

```bash
npx skills add devallibus/shiplog --skill shiplog --agent claude-code
npx skills add devallibus/shiplog --skill shiplog --agent codex
npx skills add devallibus/shiplog --skill shiplog --agent cursor
```

Update later with:

```bash
npx skills update
```

### 2. Claude Code plugin from a local checkout

This repo includes a Claude plugin manifest in `.claude-plugin/plugin.json`.
To validate and load it from a checkout:

```bash
claude plugins validate .claude-plugin/plugin.json
claude --plugin-dir .
```

### 3. Claude Code skill copy

If you want the raw skill without the plugin wrapper, copy `skills/shiplog/`
into Claude Code's skill directory:

```bash
# Global (all projects)
cp -r skills/shiplog ~/.claude/skills/shiplog

# Or project-local
cp -r skills/shiplog .claude/skills/shiplog
```

Then invoke with `/shiplog` or let it auto-activate when you create branches,
issues, or PRs.

### 4. Cursor and generic manual copy

If you are not using the `npx skills` flow, you can still install shiplog by
copying the skill folder into the generic agentskills.io layout used by Codex,
Cursor, and similar tools:

```bash
cp -r skills/shiplog .agents/skills/shiplog
```

### Live development with `--add-dir`

For local iteration without reinstalling after every change:

```bash
claude --add-dir skills
```

### Requirements

- `gh` CLI ([install](https://cli.github.com/)) — authenticated with `gh auth login`
- `git` — you're in a git repo with a GitHub remote
- That's it. Everything else is optional.

## Companion Skills

shiplog orchestrates other skills for a richer experience. All are optional — without them, shiplog falls back to direct `gh`/`git` commands.

| Skill | Plugin | What It Adds |
|-------|--------|-------------|
| `ork:commit` | [OrchestKit](https://github.com/yonatangross/orchestkit) | Conventional commits with validation |
| `ork:create-pr` | OrchestKit | PR creation with parallel validation agents |
| `ork:stacked-prs` | OrchestKit | Stacked PR mechanics |
| `ork:issue-progress-tracking` | OrchestKit | Auto-checkbox updates from commits |
| `ork:remember` / `ork:memory` | OrchestKit | Knowledge graph storage |
| `ork:brainstorming` | OrchestKit | Parallel agent brainstorming |
| `superpowers:brainstorming` | [Superpowers](https://github.com/obra/superpowers) | Design-first brainstorming |
| `superpowers:using-git-worktrees` | Superpowers | Isolated workspaces |
| `superpowers:finishing-a-development-branch` | Superpowers | Post-implementation options |
| `superpowers:writing-plans` | Superpowers | Structured plan documents |
| `superpowers:executing-plans` | Superpowers | Plan execution with checkpoints |

## Configuration Files

| File | Purpose |
|------|---------|
| `.shiplog/routing.md` | Model-tier assignments, routing behavior, multi-tool inventory |
| `.shiplog/verification.md` | Default verification profiles and per-profile settings |

Both are optional. shiplog works without any configuration — defaults are sensible.

## Feature Deep Dive

### Artifact Envelopes

Every shiplog artifact — issue bodies, PR bodies, timeline comments — carries a machine-readable metadata envelope embedded as an HTML comment. Envelopes are invisible in rendered GitHub views by design: they exist for agent retrieval, not human reading.

```html
<!-- shiplog:
kind: state
issue: 42
branch: issue/42-auth-middleware
status: in-progress
phase: 2
updated_at: 2026-03-14T12:00:00Z
-->
```

**Why invisible?** Agents fetch envelope metadata first, then read the full body only when needed — reducing token cost on long threads. Humans see clean markdown; machines get structured data.

**How to inspect them:**
```bash
# Raw body includes the HTML comment
gh issue view 42 --json body --jq '.body'

# Find all shiplog envelopes on an issue
gh issue view 42 --json body,comments --jq '
  [.body, .comments[].body]
  | map(select(test("<!-- shiplog:")))
'
```

On GitHub, click **Edit** on any issue or comment to see the envelope in the raw markdown source.

**7 envelope kinds:**

| Kind | Purpose | Uniqueness |
|------|---------|------------|
| `state` | Current status snapshot | latest-wins |
| `handoff` | Context transfer between tiers/tools | accumulating |
| `verification` | Testing or review evidence | accumulating |
| `commit-note` | Reasoning behind a commit | accumulating |
| `review-handoff` | Review request or completion | accumulating |
| `blocker` | Something preventing progress | latest-wins |
| `history` | Retrospective summary | latest-wins |

**Supersession model:** For latest-wins kinds, the most recent envelope of that kind is current — older ones are historical. For accumulating kinds, multiple envelopes coexist, each capturing a distinct event. Agents sort by `updated_at` to find what's current.

See `references/artifact-envelopes.md` for the full field schema, retrieval patterns, and conflict resolution rules.

### Agent Identity Signing

Every shiplog artifact carries a provenance signature identifying which AI model authored or reviewed it.

```
Authored-by: claude/opus-4.6 (claude-code)
Reviewed-by: openai/gpt-5.4 (codex, effort: high)
```

**Canonical grammar:**

```
<role>: <family>/<version> (<tool>[, <qualifier>])
```

- **role** — `Authored-by` or `Reviewed-by`
- **family** — provider name (`claude`, `openai`, `google`)
- **version** — model identifier (`opus-4.6`, `sonnet-4`, `gpt-5.4`)
- **tool** — runtime environment (`claude-code`, `codex`, `cursor`)
- **qualifier** — optional tool metadata (`effort: high`)

Signatures make it possible to search for all work by a specific model, trace who authored what, and enforce cross-model review requirements.

### Cross-Model Review

Every PR requires a positive review from a model different from the author before merge. Same-model self-review does not count as independent review.

**Review sign-off format:**

```
Reviewed-by: claude/sonnet-4 (claude-code)
Disposition: approve
Scope: full diff — README.md, SKILL.md
```

**Why cross-model?** A single model authoring, reviewing, and merging its own work is the anti-pattern this protocol prevents. The review loop is part of the safety model — signed review comments are the canonical review artifact, not GitHub review badges.

**Merge conditions:**
1. At least one cross-model review with `Disposition: approve`
2. All `request-changes` reviews addressed
3. PR body includes `Closes #<N>` linking to the tracking issue
4. Issue closure has linked evidence (the merged PR itself)

See `references/closure-and-review.md` for the full review execution ladder and evidence-linked closure protocol.

### Verification Profiles

Configurable testing and semantic-stability policies that travel with the task. Verification is not "run tests" — it is semantic-stability pressure that makes behavior drift expensive enough to catch.

| Profile | Purpose |
|---------|---------|
| `none` | No enforcement (default) |
| `behavior-spec` | Acceptance scenarios for new/changed behavior |
| `red-green` | Fail-first unit tests |
| `structural` | Quality analysis on changed modules |
| `mutation` | Differential mutation testing |

Profiles are composable and configured in `.shiplog/verification.md`. A per-issue override can tighten the project default but not relax it. Delegated agents inherit the active profile — a tier-3 agent cannot bypass verification.

See `references/verification-profiles.md` for the full behavior-spec protocol, evidence requirements, and configuration format.

### Discovery Protocol

When you find a sub-problem while working on an issue, shiplog routes it based on scope:

```
Discovery made during work
  ├── Small fix (< 30 min)?         → Fix inline, add timeline comment
  ├── Prerequisite for current work? → Stack a new branch/PR (Phase 3a)
  ├── Independent but important?     → Create new issue, continue (Phase 3b)
  └── Refactoring opportunity?       → Create issue tagged "refactor"
```

**Stacked PRs** for prerequisites create a new issue first (so the `#ID` exists), then branch from the current work. Cross-references on the parent issue keep the relationship visible.

### Shell Portability

Shiplog works on both Bash and PowerShell. The key pattern: use `gh ... --body-file <temp-file>` for multiline content instead of inline heredocs.

```bash
# Bash
body_file="$(mktemp)"
cat > "$body_file" <<'EOF'
## Timeline comment content
EOF
gh issue comment 42 --body-file "$body_file"
rm "$body_file"
```

```powershell
# PowerShell
$bodyPath = Join-Path $PWD '.tmp-gh-body.md'
Set-Content -Path $bodyPath -Value @"
## Timeline comment content
"@ -NoNewline
gh issue comment 42 --body-file $bodyPath
Remove-Item $bodyPath -Force
```

See `references/shell-portability.md` for worktree setup, variable capture syntax, and escaping differences.

## License

MIT
