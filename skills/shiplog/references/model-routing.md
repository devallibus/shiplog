# Model routing

Routing is an optional advisory. It names the kind of model a step suits so the user can decide whether to switch. Only the user or the runtime switches models.

## Setting

Resolve the mode in this order: a `## Model Routing` section in the issue body, then `.shiplog/routing.md`, then `off`.

```markdown
# Model Routing

routing: off
```

- `off`: no routing prompts or banners.
- `warn`: when the suggested tier changes between steps, show one line and continue.
- `confirm`: when the suggested tier changes, ask once whether to continue or switch first, and wait for the answer.

Do not create the file or ask for a setting on first use. Change the setting only when the user asks, through [models.md](../models.md). Preserve explicit settings, per-issue overrides, and model assignments that already exist. A per-issue override applies only to that issue:

```markdown
## Model Routing

routing: warn
```

shiplog never switches plan mode or any other execution mode, in any routing mode. A `warn` or `confirm` banner may suggest planning first for open-ended design work; `off` shows nothing. If the user continues without switching, proceed; never block or repeat the prompt.

## Tiers

Tiers describe capability:

- **reasoning:** open design questions, ambiguous trade-offs, synthesis across many sources.
- **capable:** loading context, scoping, retrieval, reviewing a bounded diff.
- **fast:** routine execution against a clear contract, such as a commit or a filled template.

Suggest the lowest tier that can do the step well. The user may assign models to tiers in `.shiplog/routing.md`. Name a model in a prompt only when the user assigned it; otherwise name the tier.

```markdown
# Model Routing

routing: warn

## Tiers
reasoning: <model the user chose>
capable: <model the user chose>
fast: <model the user chose>
```

A `warn` banner is one line:

```text
[shiplog routing] Next step suits the reasoning tier.
```

In `confirm` mode, add: `Continue, or switch first?`

## Handoff

Write a handoff only when work actually transfers to another model, tool, or session, whatever the routing mode. Post it on the tracking issue or give it to the delegated worker. Follow [records.md](records.md) for the envelope.

```markdown
<!-- shiplog:
kind: handoff
summary: One sentence naming the transferred work.
-->

## Handoff

**Goal:** the outcome and how to tell it is done.
**Limits:** files allowed, what must not change, and when to stop and ask.
**Done so far:** completed work and decisions, with links.
**Next action:** the first concrete step.
**Checks:** what to run and what evidence to return.
```

Write it so the receiver can act without the conversation. Name any judgment call the handoff leaves open as an open question. For several parallel lanes, see [orchestrator-protocol.md](orchestrator-protocol.md).
