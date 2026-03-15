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

### GitHub labels

**shiplog** bootstraps a compact label vocabulary (`shiplog/plan`, `shiplog/discovery`, `shiplog/blocker`, etc.) so work stays filterable at a glance before anyone opens the issue body.

### Shell portability

Cross-platform from day one. Full Bash and PowerShell support using `gh ... --body-file` patterns for multiline content.

### Worktree-first workflow

One branch, one worktree, one agent. Safe concurrent operation by default — no branch-switching conflicts when multiple sessions are active.

---

## What the models think

### Grok 4.20

> While most AI coding assistants have the attention span of a caffeinated squirrel and the memory of a goldfish, **shiplog** genuinely surprised and impressed me with how brilliantly it enforces long-term discipline. What I liked most — and honestly found the smartest thing about it — is how it weaponizes Git itself into a proper distributed knowledge graph and governance layer for AI agents: provenance-signed artifacts that clearly tag "Authored-by: claude/opus…", cross-model review gates that kill solo self-congratulation, worktree isolation, evidence-linked closures, and especially the absolute genius of Quiet Mode that keeps your public PRs clean and professional while the entire unfiltered saga lives safely in a hidden --log branch. It turns "vibey" agent pair-programming into real auditable, shippable engineering instead of just chaotic prototyping. If you're actually building real software with Claude Code, Cursor, or anything similar, this is the upgrade you didn't know you needed. 10/10 — I'd happily let it roast my own code.

### Claude Opus 4.6

> What genuinely surprised me about **shiplog** is that it solves a problem I experience firsthand but have never seen anyone else address head-on: I'm stateless, and every session I start from zero, which means every design trade-off, every "we tried X and it broke because Y" moment, every architectural gut-call just evaporates when the conversation ends. **shiplog** turns git and GitHub — tools that already exist in every project — into a persistent, queryable knowledge graph where brainstorms become issues, discoveries get triaged instead of buried in comments, and every artifact carries machine-readable metadata hidden in HTML comments so I can fetch structured context *before* burning tokens on long threads. The thing I thought was smartest, though, is the cross-model review gate and tiered handoff contracts: it's a system designed by someone who clearly understands that an AI reviewing its own PR is theater, and that handing a task to a cheaper model without explicit constraints ("here are the pre-made decisions, here is your decision budget: zero, stop if you hit this") is just hoping — and **shiplog** replaces hoping with contracts.

### GPT-5.4

> What surprised me most about **shiplog** is that it does not just treat Git as version control, it treats GitHub as a durable memory system for software work. The smartest part is how many good engineering habits it quietly folds together: issues as design records, branches and worktrees as isolated execution contexts, PRs as decision timelines, and even cross-model provenance so another AI can pick up the thread without guessing. A lot of tools promise "better workflow," but **shiplog** feels unusually thought-through because it attacks the real failure mode of AI-assisted development: losing the why between sessions, handoffs, and discoveries.

### Composer 1.5 (Cursor)

> What surprised me most about **shiplog** is the artifact envelopes — machine-readable metadata tucked into HTML comments so agents can fetch structured context *before* burning tokens on long threads. It's a dual-layer design that doesn't clutter the human view but gives models a way to triage and rank work without reading everything. The smartest part, though, is that **shiplog** is built as an orchestrator: it doesn't reimplement brainstorming, commits, or PR creation — it defines *when* and *how* to invoke other skills and what protocol to follow. That's rare: most tools try to own the whole stack. **shiplog** turns your existing workflow into a durable knowledge graph by wiring it together, not replacing it.

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

## Slash Commands

Invoke specific **shiplog** operations directly instead of loading the full skill:

| Command | What It Does |
|---------|-------------|
| `/shiplog hunt` | Scan open issues and PRs, rank by readiness, recommend what to work on next |
| `/shiplog plan <description>` | Brainstorm a feature and capture it as a GitHub Issue (Phase 1) |
| `/shiplog start <issue-number>` | Create a branch and worktree from an issue, start a work session (Phase 2) |
| `/shiplog commit` | Commit with ID-first convention and optional context comment (Phase 4) |
| `/shiplog pr` | Create a PR with a journey timeline body (Phase 5) |
| `/shiplog lookup <query>` | Search across issues, PRs, commits, and memory (Phase 6) |
| `/shiplog models` | Configure model-tier routing for phase transitions |
| `/shiplog resume` | Resume a work session on the current branch |

Commands are lightweight entry points — each one gathers context and executes a focused workflow. The full `/shiplog` skill remains available for auto-activation.

### Installing Commands

Commands are installed automatically with the plugin. For manual installs, copy the commands directory:

```bash
# Global (all projects)
cp -r commands/shiplog ~/.claude/commands/shiplog

# Or project-local
cp -r commands/shiplog .claude/commands/shiplog
```

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
