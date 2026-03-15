# Model-Tier Routing Reference

Route AI models to shiplog phases based on cognitive demand. The skill cannot switch models — only the user can. Routing is purely advisory: it tells or asks the user at phase transitions, based on the configured behavior.

---

## Routing Behavior

Configure how the skill communicates tier transitions. Set in `.shiplog/routing.md`.

| Mode | Behavior | Default? |
|------|----------|----------|
| `confirm` | Pause at tier transitions and ask the user before proceeding | Yes |
| `warn` | Show a one-line banner at tier transitions, don't stop | No |
| `off` | Silent. No routing prompts or banners; actual handoffs still apply when work transfers | No |

### Config file format

Create `.shiplog/routing.md` in your project root:

```markdown
# Model Routing

routing: confirm
```

That's it. One field. If the file doesn't exist, the skill runs the setup prompt on first activation (see [Setup Prompt](#setup-prompt)).

### `/shiplog models`

Re-runs the setup prompt at any time. Updates `.shiplog/routing.md` with the new choice.

### Setup prompt

When no `.shiplog/routing.md` exists, or when the user runs `/shiplog models`:

> How should I handle model-tier suggestions at phase transitions?
> - **confirm** (default) — I'll pause and ask before proceeding, so you can switch models if you want.
> - **warn** — I'll show a banner but keep going.
> - **off** — No routing prompts. Use this if you run the same model for everything.

---

## Tier Definitions

| Tier | Cognitive Profile | Use For |
|------|-------------------|---------|
| **tier-1** (reasoning) | Creative synthesis, architectural judgment, narrative construction | Brainstorming, PR timeline synthesis, complex discovery triage |
| **tier-2** (capable) | Context loading, scope judgment, structured documentation | Issue-to-branch, discovery protocol, knowledge retrieval |
| **tier-3** (fast) | Execution speed, template filling, routine operations | Commits, simple implementations, timeline checkpoints |

## Default Phase-to-Tier Mapping

| Phase | Default Tier | Recommended Mode | Rationale |
|-------|--------------|-----------------|-----------|
| 1. Brainstorm-to-Issue | tier-1 | plan | Analysis and design — no code changes expected |
| 2. Issue-to-Branch | tier-2 | plan then agent | Load context in plan mode, then switch to agent to create branch |
| 3. Discovery Protocol | tier-2 | plan then agent | Classify the discovery before acting on it |
| 4. Commit-with-Context | tier-3 | agent | Pure execution — staging, committing, posting |
| 5. PR-as-Timeline | tier-1 | plan | Narrative synthesis — composing the PR body, not touching code |
| 6. Knowledge Retrieval | tier-2 | plan | Read-only search and synthesis |
| 7. Timeline Maintenance | tier-3 | agent | Posting comments and updates |
| Review execution | — | plan | Reviewing a diff should not modify code |

---

## Routing Prompt Format

At phase transitions, when the entering phase's tier differs from the previous phase's tier:

### `confirm` mode

```
---
[shiplog routing] Entering <Phase Name> — recommends tier-X (<profile>).
This is advisory — switch models if you want, or continue as-is.
Continue? (y / or switch models first)
---
```

Wait for user acknowledgment before proceeding.

### `warn` mode

```
---
[shiplog routing] Entering <Phase Name> — recommends tier-X (<profile>).
---
```

Show the banner and continue immediately.

### `off` mode

No routing prompt or banner. Proceed directly unless work is actually transferring to another model or tool, in which case write the handoff artifact and continue.

### When to prompt

Only prompt when the tier changes between consecutive phases. Same-tier transitions (e.g., Phase 2 tier-2 → Phase 3 tier-2) produce no prompt regardless of mode.

---

## Per-Issue Override

Add a `## Model Routing` section to any GitHub issue body to override the project routing mode for that issue:

```markdown
## Model Routing

routing: off
```

This silences routing prompts for that specific issue only. Useful for simple tasks where tier switching adds no value.

---

## Mode Routing

In addition to tier routing (which model), shiplog recommends an **execution mode** (plan vs. agent) for each phase. Plan mode prevents premature execution during analysis phases; agent mode is for phases that create or modify artifacts.

### Mode definitions

| Mode | Purpose | What the agent may do |
|------|---------|----------------------|
| **plan** | Analysis, design, classification, synthesis | Read files, search, compose text. No file writes, no shell commands that modify state. |
| **agent** | Execution, creation, modification | Full tool access — write files, run commands, post artifacts. |
| **plan then agent** | Two-step phases | Start in plan mode for context loading or classification, then switch to agent mode for execution within the same phase. |

### Mode switching capability by tool

Not all tools support agent-initiated mode switching. Where unavailable, mode routing is advisory — the skill prompts the user to switch, just like tier routing.

| Tool | Agent can self-switch? | Activation | Fallback |
|------|----------------------|------------|----------|
| **Claude Code** | Yes | The agent can invoke `exit_plan_mode` to enter plan-mode workflow. Auto Plan Mode can be configured via `--append-system-prompt`. | N/A — self-switch available |
| **Codex CLI** | Not yet | Pending [openai/codex#11180](https://github.com/openai/codex/issues/11180). No documented user-initiated mode switch yet. | Advisory prompt — ask the user to switch |
| **Cursor** | No | User switches with `Shift+Tab`. Plan Mode, Ask Mode, and Agent Mode are user-controlled. | Advisory prompt — ask the user to switch |

### Mode routing behavior

Mode advisories follow the same `confirm` / `warn` / `off` routing config as tier advisories — they share the same setting in `.shiplog/routing.md`. Mode transitions are checked alongside tier transitions in the phase entry check.

A mode advisory is emitted when the entering phase's recommended mode differs from the previous phase's mode.

### Mode routing prompt format

#### `confirm` mode

```
---
[shiplog routing] Entering <Phase Name> — recommends tier-X (<profile>), plan mode.
Switch to plan mode before proceeding.
  Claude Code: agent will enter plan mode automatically.
  Codex: switch to plan mode if your tool supports it (no documented mechanism yet).
  Cursor: press Shift+Tab to select Plan Mode.
Continue? (y / or switch first)
---
```

#### `warn` mode

```
---
[shiplog routing] Entering <Phase Name> — recommends tier-X (<profile>), plan mode.
---
```

#### `off` mode

No mode advisory prompt. For tools with self-switch capability (Claude Code), the agent still enters plan mode silently when the phase recommends it.

### Tool-conditional self-switching

When the recommended mode is `plan` and the tool supports agent-initiated mode switching:

1. **Claude Code:** The agent should enter plan mode at the start of the phase. This prevents accidental file modifications during analysis phases. The agent exits plan mode when the phase transitions to agent work or when the next phase begins.
2. **Codex / Cursor:** The skill emits an advisory prompt per the routing config. If the user does not switch, proceed normally — never block.

When the recommended mode is `plan then agent`, the plan-mode portion covers context loading and classification. The agent switches to (or the user is prompted for) agent mode when the phase reaches its execution step.

---

## Context Handoff Protocol

When work transfers between models or tools — whether prompted by routing or not — a self-contained handoff ensures the receiving model has everything it needs. This protocol is useful independently of routing configuration.

### When to write a handoff

- Transitioning from a higher tier to a lower tier (the outgoing model writes it)
- Switching tools (e.g., Claude Code → Cursor)
- Delegating bounded work to another agent
- Any time the next model won't have the current conversation context

### Handoff template

```markdown
## [#<ID>] handoff: Phase N → Phase M

**Tier transition:** tier-X → tier-Y
**Current model:** <family>/<version> (<tool>)

### What was decided
- [Decision 1 — concrete, not conceptual]
- [Decision 2]

### What to do next
1. [Concrete action with file path]
2. [Concrete action with file path]

### Contract
- **Allowed files:** `path/to/file.ts`, `path/to/other.ts`
- **Must not change:** [files, APIs, behavior, or decisions out of scope]
- **Stop and ask if:** [condition requiring widening scope or judgment]
- **Verification required:** [tests, checks, or evidence required before claiming done]
- **Return artifact:** [diff summary, verification note, changed file list, blocker report]
- **Decision budget:** `none` | `narrow` | `full`

### Files to touch
- `path/to/file.ts` (create) — [what goes in it]
- `path/to/other.ts` (modify line N) — [what to change]

### Gotchas
- [Anything a cheaper model would get wrong without this warning]
```

### The golden rule

> If a tier-3 model reading this handoff would need to make a judgment call, the handoff is not specific enough. Rewrite it until every decision is pre-made.

For delegated execution, `Decision budget: none` should be the default.

### Using the handoff as a verifier contract

When closure or review work is delegated to another model, use this same handoff template as the bounded verifier contract. The supervising model keeps the closure or merge decision; the delegated verifier only inspects the named evidence, current file state, or PR diff and returns the required verification artifact.
