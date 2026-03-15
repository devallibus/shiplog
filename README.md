# shiplog

**The captain's log for your codebase.** Every decision, discovery, and trade-off — captured in GitHub as you ship.

## Quick Install

```bash
npx skills add devallibus/shiplog --skill shiplog
```

Works with Claude Code, Codex, and Cursor. Only requires [`gh` CLI](https://cli.github.com/).

---

## Your AI assistant forgets everything between sessions

You brainstormed a design with Claude yesterday. Today, a new session starts from scratch. The reasoning behind that auth middleware? Gone. The three alternatives you rejected? Nowhere to be found. Last week's architectural decision? Buried in a chat log you can't search.

**shiplog** makes your git history remember everything. Not just *what* changed — but *why* it changed, what you considered, and what you discovered along the way.

```
Brainstorm → Issue → Branch → Commits → PR
    ↑                           ↑
    |         Discoveries → New Issues / Stacked PRs
    |
    └── Search it all later: issues, PRs, commits, memory
```

## What you get

**Every brainstorm becomes a GitHub Issue.** Design decisions, alternatives considered, and a task list — all searchable forever.

**Every commit carries context.** Not just "add JWT validation" — but *why* JWT over sessions, what you tried first, and what to watch out for.

**Every PR tells the full story.** A timeline of the entire journey: what was planned, what was discovered mid-work, what changed and why.

**Nothing falls through the cracks.** Find a sub-problem while coding? **shiplog** routes it — fix inline, stack a prerequisite PR, or spin off a new issue. Your discovery is never lost.

**Any model can pick up where another left off.** Every artifact is signed with who wrote it (which AI model, which tool). Context handoffs between models are first-class — not copy-paste.

---

## How it works

You say "let's brainstorm auth middleware" and **shiplog** captures the result as a GitHub issue. When you say "work on #42", it creates an isolated branch in a git worktree. As you commit, it logs the reasoning. When you open the PR, it writes a timeline of the whole journey.

Your existing workflow, with a knowledge trail that persists across sessions, models, and tools.

| Step | What happens |
|------|-------------|
| **Brainstorm** | Design discussion becomes a GitHub Issue with tasks |
| **Branch** | Isolated worktree created, timeline started, plan loaded |
| **Discover** | Sub-problems routed: inline fix, stacked PR, or new issue |
| **Commit** | Conventional commits with context comments on significant changes |
| **Ship** | PR with full journey timeline, decisions, and lessons learned |
| **Search** | Find any past decision across issues, PRs, and commits |

### Two modes

**Full Mode** (default) — Knowledge goes directly into issues and PRs. Perfect for personal projects and open source.

**Quiet Mode** — Your team sees clean PRs. The full reasoning lives in a separate `--log` branch, one click away.

```
main
  └── feature/auth-middleware            ← Clean PR (team sees this)
        └── feature/auth-middleware--log  ← Knowledge trail (one click away)
```

---

## Features

### Cross-model review

No PR merges without review from a *different* AI model or a human. A single model authoring, reviewing, and merging its own work is the anti-pattern **shiplog** prevents. Reviews carry signed `Reviewed-by:` lines, support three dispositions (approve, request-changes, comment), and generate self-contained review contracts when spawning a reviewer isn't possible.

### Agent identity signing

Every artifact carries a provenance signature — `Authored-by: claude/opus-4.6 (claude-code)`. The signing system auto-detects the current model from the platform and makes everything searchable:

```bash
gh issue list --search "Authored-by: claude/"   # all Claude artifacts
gh pr list --search "Reviewed-by:"              # all reviews
```

### Model-tier routing

Use your best model for brainstorming, a fast one for implementation. **shiplog** prompts you to switch at phase transitions and writes context handoffs so the receiving model can execute without guessing.

| Tier | Best for | Example models |
|------|----------|----------------|
| tier-1 (reasoning) | Architecture, trade-offs, PR synthesis | Claude Opus, o3 |
| tier-2 (capable) | Context loading, structured docs | Claude Sonnet |
| tier-3 (fast) | Implementation, routine commits | Claude Haiku, GPT-4o-mini |

### Delegation contracts

When a reasoning model hands work to a faster model, the handoff is structured: allowed files, forbidden changes, stop conditions, verification requirements, and decision budget. If a tier-3 model reading the handoff would need to make a judgment call, the handoff is not specific enough.

### Discovery protocol

Find a bug while building a feature? **shiplog** classifies it and routes it:

```
Discovery made during work
  ├── Small fix (< 30 min)?         → Fix inline, add timeline comment
  ├── Prerequisite for current work? → Stack a new branch/PR
  ├── Independent but important?     → Create new issue, continue
  └── Refactoring opportunity?       → Create issue tagged "refactor"
```

Stacked prerequisites get their own issue and branch with cross-references on the parent. Nothing gets lost.

### Implementation issue capture

Implementation trouble that materially affects the work, including failed attempts, hidden dependencies, risky workarounds, scope surprises, and verification gaps, must be recorded durably before the agent moves on.

| Situation | Action |
|-----------|--------|
| Resolved inline | Post a `[shiplog/implementation-issue]` timeline comment |
| Warrants follow-up or long-term retrieval | Open a new linked issue |

Reviewers treat uncaptured implementation issues as a workflow defect, because otherwise that knowledge stays trapped in chat-only memory.

### Task-level delivery

Ship incrementally. Commits reference tasks (`feat(#42/T1): add JWT validation`), partial-delivery PRs use `Addresses #42 (completes T1, T2)`, and the issue stays open for remaining work. No premature closures, no lost track.

### Verification profiles

Configurable testing policies that travel with every task — even when delegated to a faster model:

| Profile | Purpose |
|---------|---------|
| `behavior-spec` | Acceptance scenarios with ask-before-changing rules |
| `red-green` | Fail-first unit tests |
| `structural` | Quality analysis on changed modules |
| `mutation` | Differential mutation testing on changed lines |

Profiles are composable and hierarchical (project > issue > task, tighten-only). Configure in `.shiplog/verification.md`.

### Artifact envelopes

Machine-readable metadata hidden in HTML comments. Agents fetch metadata first, read full bodies only when needed — saving tokens on long threads. Humans see clean markdown; machines get structured data.

### Evidence-linked closure

No issue closes without proof. Merged PRs, commit URLs, or decision artifacts — every closure needs linked evidence. Ambiguous matches are escalated, never silently closed.

### ID-first convention

Every artifact keyed by `#ID` — branches, commits, PRs, tasks, timeline comments. One search finds everything:

```bash
gh issue list --search "#42" --state all    # issues
gh pr list --search "#42" --state all       # PRs
git log --all --oneline --grep="#42"         # commits
git log --all --oneline --grep="#42/T1"     # task-level commits
```

Timeline comments use semantic tags such as `plan`, `session-start`, `session-resume`, `commit-note`, `discovery`, `implementation-issue`, `milestone`, `approach-change`, `blocker`, `review-handoff`, `worklog`, `history`, and `session-end`.

### GitHub labels

**shiplog** bootstraps a compact label vocabulary (`shiplog/plan`, `shiplog/discovery`, `shiplog/blocker`, etc.) so work stays filterable at a glance before anyone opens the issue body.

### Shell portability

Cross-platform from day one. Full Bash and PowerShell support using `gh ... --body-file` patterns for multiline content.

### Worktree-first workflow

One branch, one worktree, one agent. Safe concurrent operation by default — no branch-switching conflicts when multiple sessions are active.

---

## Install

### Recommended: `npx skills` (Claude Code, Codex, Cursor)

```bash
npx skills add devallibus/shiplog --skill shiplog
```

Target a specific agent:

```bash
npx skills add devallibus/shiplog --skill shiplog --agent claude-code
npx skills add devallibus/shiplog --skill shiplog --agent codex
npx skills add devallibus/shiplog --skill shiplog --agent cursor
```

Keep it updated:

```bash
npx skills update
```

### Alternative methods

<details>
<summary>Claude Code plugin from local checkout</summary>

```bash
claude plugins validate .claude-plugin/plugin.json
claude --plugin-dir .
```

</details>

<details>
<summary>Claude Code skill copy</summary>

```bash
# Global (all projects)
cp -r skills/shiplog ~/.claude/skills/shiplog

# Or project-local
cp -r skills/shiplog .claude/skills/shiplog
```

Then invoke with `/shiplog` or let it auto-activate.

</details>

<details>
<summary>Generic manual copy (Codex, Cursor, etc.)</summary>

```bash
cp -r skills/shiplog .agents/skills/shiplog
```

</details>

<details>
<summary>Live development with --add-dir</summary>

```bash
claude --add-dir skills
```

For local iteration without reinstalling after every change.

</details>

### Requirements

- [`gh` CLI](https://cli.github.com/) — authenticated with `gh auth login`
- `git` — in a repo with a GitHub remote
- That's it. Everything else is optional.

## Configuration

| File | Purpose |
|------|---------|
| `.shiplog/routing.md` | Model-tier assignments, routing behavior |
| `.shiplog/verification.md` | Default verification profiles |

Both optional. **shiplog** works without any configuration.

## Companion skills

**shiplog** orchestrates other skills for richer workflows. All optional — without them, it falls back to direct `gh`/`git` commands.

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

## License

MIT
