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

| Phase | Default Tier | Rationale |
|-------|--------------|-----------|
| 1. Brainstorm-to-Issue | tier-1 | Creative architecture, exploring design alternatives |
| 2. Issue-to-Branch | tier-2 | Context loading, plan assessment, approach formulation |
| 3. Discovery Protocol | tier-2 | Scope judgment — categorizing discoveries requires cross-cutting analysis |
| 4. Commit-with-Context | tier-3 | Structured template, low creativity |
| 5. PR-as-Timeline | tier-1 | Narrative synthesis, journey reflection, extracting lessons |
| 6. Knowledge Retrieval | tier-2 | Search synthesis, connecting dots across artifacts |
| 7. Timeline Maintenance | tier-3 | Checkpoint updates, template filling |

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
