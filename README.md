# shiplog

The captain's log for your codebase. Every decision, discovery, and change logged as you ship code.

**shiplog** turns GitHub into a complete knowledge graph for your project. Every brainstorm becomes an issue. Every issue drives a branch. Every branch produces a PR with a full timeline of the journey — what you planned, what you discovered, what you decided, and why.

Neither you nor your AI coding assistant ever loses context again.

## How It Works

```
Brainstorm → GitHub Issue → Branch → Commits with Context → PR with Timeline
     ↑                                      ↑
     |              Discoveries → Stacked PRs / New Issues
     |
     └── Knowledge Retrieval (search issues, PRs, commits, memory)
```

### Two Modes

**Full Mode** (default) — Knowledge goes directly into issues and PRs. Great for personal projects and OSS.

**Quiet Mode** — For work environments where issues/PRs must stay clean. Knowledge lives in a stacked `--log` branch with its own PR targeting the feature branch. Your team sees clean PRs; the full reasoning is one click away.

```
main
  └── feature/auth-middleware            ← Clean PR (your team sees this)
        └── feature/auth-middleware--log  ← Knowledge PR (full timeline here)
```

### Model Routing

Assign AI model tiers to phases - use your best model for brainstorming and PR synthesis, a fast model for implementation and commits. Shiplog prompts you to switch at phase transitions and ensures the stronger model leaves a contract clear enough for a cheaper model to execute.

### Delegation Contracts

When a tier-1 or tier-2 model wants a cheaper agent to execute bounded work, shiplog treats that as a first-class delegation handoff:

- delegation is best for `[tier-3]` tasks and routine implementation
- the delegator defines allowed files, acceptance criteria, forbidden judgment calls, verification, and return artifact
- the delegated agent reports back with a structured completion artifact instead of improvising or widening scope
- issue and PR lifecycle actions stay with the delegator by default

Configure per-project in `.shiplog/routing.md` or per-issue in the issue body. See `references/model-routing.md` for the full spec.

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

Verified locally on March 14, 2026: installing from `devallibus/shiplog` created project-local installs for Claude Code, Codex, and Cursor. The installer placed Claude Code under `.claude/skills/shiplog` and Codex/Cursor under `.agents/skills/shiplog`.

### 2. Claude Code plugin from a local checkout

This repo includes a Claude plugin manifest in `.claude-plugin/plugin.json`.
To validate and load it from a checkout:

```bash
claude plugins validate .claude-plugin/plugin.json
claude --plugin-dir .
```

This is the best path for local plugin development and pre-submission testing.

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

### Submission channels

- Claude Code marketplace submission is manual and login-gated. Validate
  `.claude-plugin/plugin.json` first, then submit through the Claude plugin
  submission flow.
- Vercel's `skills` CLI can install directly from this repository today; no
  separate catalog submission was required for the local install paths verified
  above.
- Codex is documented to support repo-based skill installation, so a separate
  curated-catalog submission is not required for basic distribution. Treat any
  future catalog submission as optional packaging work, not a prerequisite for
  installability.

### Requirements
- `gh` CLI ([install](https://cli.github.com/)) — authenticated with `gh auth login`
- `git` — you're in a git repo with a GitHub remote
- That's it. Everything else is optional.

## Recommended Companion Skills

shiplog orchestrates other skills to provide a richer experience. All are optional — without them, shiplog falls back to direct `gh`/`git` commands.

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

## The 7 Phases

| Phase | Trigger | What Happens | Default Tier |
|-------|---------|-------------|-------------|
| 1. Brainstorm-to-Issue | "Let's plan X" | Brainstorm captured as GitHub Issue | tier-1 (reasoning) |
| 2. Issue-to-Branch | "Work on #42" | Branch created, timeline started | tier-2 (capable) |
| 3. Discovery Protocol | Sub-problem found | New issue/stacked PR or inline fix | tier-2 (capable) |
| 4. Commit-with-Context | Ready to commit | Commit + reasoning comment | tier-3 (fast) |
| 5. PR-as-Timeline | Work complete | PR with full journey timeline | tier-1 (reasoning) |
| 6. Knowledge Retrieval | "Where did we decide X?" | Search across all artifacts | tier-2 (capable) |
| 7. Timeline Maintenance | Mid-work | Session/milestone/blocker comments | tier-3 (fast) |

## License

MIT
