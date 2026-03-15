---
allowed-tools: Bash(cat:*), Bash(test:*), Bash(mkdir:*), Read, Write
description: Configure model-tier routing for shiplog phase transitions
---

## Context

- Routing config exists: !`test -f .shiplog/routing.md && echo "yes" || echo "no"`
- Current config: !`cat .shiplog/routing.md 2>/dev/null || echo "(no config file)"`

## Your Task

You are running the shiplog model-routing setup.

### If Config Exists

Show the current routing mode and ask if the user wants to change it.

### If No Config Exists (or user wants to change)

Present the setup prompt:

> How should I handle model-tier suggestions at phase transitions?
>
> - **confirm** (default) -- I'll pause and ask before proceeding, so you can switch models if you want.
> - **warn** -- I'll show a banner but keep going.
> - **off** -- No routing prompts. Use this if you run the same model for everything.
>
> **Tier reference:**
> | Tier | Use For | Example Phases |
> |------|---------|----------------|
> | tier-1 (reasoning) | Creative synthesis, architecture | Brainstorm, PR timeline |
> | tier-2 (capable) | Context loading, structured docs | Issue-to-branch, retrieval |
> | tier-3 (fast) | Execution, routine operations | Commits, timeline updates |

### Save the Choice

Create `.shiplog/routing.md`:

```markdown
# Model Routing

routing: <chosen-mode>
```

Create the `.shiplog/` directory if it doesn't exist.

### Report

Confirm the saved routing mode and explain when it will take effect (at the next phase transition).
