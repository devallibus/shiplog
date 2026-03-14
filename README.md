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

## Install

### Claude Code

Copy the `skills/shiplog/` directory to your Claude Code skills:

```bash
# Global (all projects)
cp -r skills/shiplog ~/.claude/skills/shiplog

# Or project-local
cp -r skills/shiplog .claude/skills/shiplog
```

Then invoke with `/shiplog` or let it auto-activate when you create branches, issues, or PRs.

### Codex

Copy the `skills/shiplog/` directory to your Codex skills directory.

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

| Phase | Trigger | What Happens |
|-------|---------|-------------|
| 1. Brainstorm-to-Issue | "Let's plan X" | Brainstorm captured as GitHub Issue |
| 2. Issue-to-Branch | "Work on #42" | Branch created, timeline started |
| 3. Discovery Protocol | Sub-problem found | New issue/stacked PR or inline fix |
| 4. Commit-with-Context | Ready to commit | Commit + reasoning comment |
| 5. PR-as-Timeline | Work complete | PR with full journey timeline |
| 6. Knowledge Retrieval | "Where did we decide X?" | Search across all artifacts |
| 7. Timeline Maintenance | Mid-work | Session/milestone/blocker comments |

## License

MIT
