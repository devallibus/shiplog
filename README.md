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
| [Cross-Model Review](#cross-model-review) | No PR merges without independent review from a different AI model |
| [Evidence-Linked Closure](#evidence-linked-closure) | No issue closes without linked proof (commit, PR, or decision artifact) |
| [Model-Tier Routing](#model-tier-routing) | Route reasoning models to planning, fast models to implementation |
| [Delegation Contracts](#delegation-contracts) | Structured handoffs with allowed files, stop conditions, decision budgets |
| [Verification Profiles](#verification-profiles) | Configurable testing policies: behavior-spec, red-green, structural, mutation |
| [Artifact Envelopes](#artifact-envelopes) | Machine-readable metadata for low-token agent retrieval |
| [Agent Identity Signing](#agent-identity-signing) | Provenance tracking on every artifact — who wrote it, which model, which tool |
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

Every PR requires a positive review from a model *different* from the author before it can merge. A single model authoring, reviewing, and merging its own work is the anti-pattern this protocol prevents.

- **Review artifacts** carry a signed `Reviewed-by:` line with model family, version, and tool
- **Three dispositions:** approve (merge authorized), request-changes (must address), comment (non-blocking)
- **Smart target selection:** the reviewer automatically skips PRs it authored and reviews only cross-model candidates
- **Self-review as audit trail:** when no other model is available, a self-review is recorded but does *not* satisfy the gate — the PR stays open until an independent reviewer approves
- **Risk-based tiers:** documentation needs 1 cross-model approve; security-sensitive changes recommend human confirmation

When spawning a reviewer isn't possible, shiplog generates a self-contained **review contract** you can hand to any other model or tool.

## Evidence-Linked Closure

No issue closes without linked evidence:

| Evidence Type | When To Use |
|---------------|-------------|
| Commit URL on default branch | The fix is a code change that has been merged |
| Merged PR URL | The fix is better represented by the full PR |
| Discussion or decision artifact | Resolved by a decision, policy change, or external action |

Closing an issue requires a structured closure comment with evidence link, verification statement, and disposition. Umbrella issues require all children closed first. Ambiguous matches are escalated — never silently closed.

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

Seven canonical kinds: `state`, `handoff`, `verification`, `commit-note`, `review-handoff`, `blocker`, `history`. Each follows either a **latest-wins** rule (only the newest is current) or an **accumulating** rule (multiple coexist). Supersession markers link newer artifacts to the ones they replace, preserving the full timeline while making current state instantly retrievable.

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
| Memory | `#<id>: <decision>` | `#42: chose JWT over sessions` |

Retrieve everything about issue 42:
```bash
gh issue list --search "#42" --state all    # issues
gh pr list --search "#42" --state all       # PRs
git log --all --oneline --grep="#42"         # commits
```

## Shell Portability

shiplog is cross-platform from day one. All templates and commands work on both Bash (macOS/Linux) and PowerShell (Windows). Multiline GitHub content uses the `gh ... --body-file <temp-file>` pattern for reliable cross-shell operation. See `references/shell-portability.md` for the full pattern library.

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
| `superpowers:brainstorming` | [Superpowers](https://github.com/obra/superpowers) | Design-first brainstorming |
| `superpowers:using-git-worktrees` | Superpowers | Isolated workspaces |
| `superpowers:writing-plans` | Superpowers | Structured plan documents |
| `superpowers:executing-plans` | Superpowers | Plan execution with checkpoints |

## Configuration Files

| File | Purpose |
|------|---------|
| `.shiplog/routing.md` | Model-tier assignments, routing behavior, multi-tool inventory |
| `.shiplog/verification.md` | Default verification profiles and per-profile settings |

Both are optional. shiplog works without any configuration — defaults are sensible.

## License

MIT
