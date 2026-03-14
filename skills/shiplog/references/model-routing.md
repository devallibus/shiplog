# Model-Tier Routing Reference

Route AI models to shiplog phases based on cognitive demand. Use your best model for planning and synthesis, a fast model for implementation and commits.

---

## Tier Definitions

| Tier | Cognitive Profile | Use For | Example Models |
|------|------------------|---------|----------------|
| **tier-1** (reasoning) | Creative synthesis, architectural judgment, narrative construction, trade-off evaluation | Brainstorming, PR timeline synthesis, complex discovery triage | Claude Opus, GPT-5.4 high, o3 |
| **tier-2** (capable) | Context loading, scope judgment, structured documentation | Issue-to-branch, discovery protocol, knowledge retrieval | Claude Sonnet, GPT-5.4 medium |
| **tier-3** (fast) | Execution speed, template filling, routine operations | Commits, simple implementations, timeline checkpoints | Claude Haiku, Cursor Composer 1.5, GPT-4o-mini |

## Default Phase-to-Tier Mapping

| Phase | Default Tier | Rationale |
|-------|-------------|-----------|
| 1. Brainstorm-to-Issue | tier-1 | Creative architecture, exploring design alternatives, writing tier-aware task lists |
| 2. Issue-to-Branch | tier-2 | Context loading, plan assessment, approach formulation |
| 3. Discovery Protocol | tier-2 | Scope judgment — categorizing discoveries requires cross-cutting analysis |
| 4. Commit-with-Context | tier-3 | Structured template, low creativity — commit messages are formulaic |
| 5. PR-as-Timeline | tier-1 | Narrative synthesis, journey reflection, extracting lessons learned |
| 6. Knowledge Retrieval | tier-2 | Search synthesis, connecting dots across artifacts |
| 7. Timeline Maintenance | tier-3 | Checkpoint updates, template filling |

---

## Project Configuration

Create `.shiplog/routing.md` in your project root to configure model routing for your team.

### Config format

```markdown
# Model Routing

## Available Models

| Model | Provider | Tier |
|-------|----------|------|
| Claude Opus 4 | Claude Code | tier-1 |
| Claude Sonnet 4 | Claude Code | tier-2 |
| Cursor Composer 1.5 | Cursor | tier-3 |

## Routing Behavior
suggest
```

### Fields

**Available Models table:**
- **Model:** The model name as users know it
- **Provider:** The tool/environment where this model runs (used to detect same-tool vs cross-tool switches)
- **Tier:** Which tier this model handles

**Routing Behavior** (one of):
- `suggest` (default when configured) — show routing prompt at tier transitions
- `quiet` — log tier in timeline comments only, no prompts to the user
- `off` — no routing behavior at all

### Multi-tool example

A team using Claude Code for planning and Cursor for implementation:

```markdown
## Available Models

| Model | Provider | Tier |
|-------|----------|------|
| Claude Opus 4 | Claude Code | tier-1 |
| Claude Sonnet 4 | Claude Code | tier-2 |
| Claude Haiku 4.5 | Claude Code | tier-3 |
| Cursor Composer 1.5 | Cursor | tier-3 |
| GPT-5.4 high | Codex | tier-1 |
```

When a phase transition requires switching providers (e.g., Claude Code → Cursor), the skill writes a **full cross-tool handoff** on the issue. When switching within the same provider (e.g., Opus → Sonnet), the handoff is lighter.

---

## Per-Issue Override

Add a `## Model Routing` section to any GitHub issue body to override project defaults for that issue:

```markdown
## Model Routing

| Phase | Tier | Notes |
|-------|------|-------|
| 1. Brainstorm | tier-1 | Complex architecture |
| 2-4. Implementation | tier-3 | Straightforward CRUD |
| 5. PR | tier-2 | Standard PR |
```

This overrides the project defaults for this specific issue only.

---

## First-Activation Setup Wizard

When model routing is first used and no `.shiplog/routing.md` exists, the skill runs a setup wizard:

### Step 1: Detect platform

| Signal | Platform |
|--------|----------|
| System prompt contains `claude-*` model ID | Claude Code |
| `~/.codex/config.toml` exists with `model` field | Codex |
| Neither detected | Ask user |

### Step 2: Suggest models

**Claude Code detected:**
> I see you're running Claude Code. Available model tiers:
> - tier-1: Claude Opus 4 (`/model opus`)
> - tier-2: Claude Sonnet 4 (`/model sonnet`)
> - tier-3: Claude Haiku 4.5 (`/model haiku`)
>
> Do you use any other tools (Cursor, Codex, etc.)? If so, which models?

**Codex detected:**
> Reading `~/.codex/config.toml`... Current model: [model]. Available models from `~/.codex/models_cache.json`: [list].
> Which tier should each model be?

**No platform detected:**
> Which AI tools and models do you use? I'll set up routing for your workflow.

### Step 3: Generate config

Create `.shiplog/routing.md` with the user's confirmed model inventory and tier assignments.

---

## Routing Prompt Format

At phase transitions, when the entering phase's tier differs from the previous phase's tier:

### Same-tool switch

```
---
[shiplog routing] Entering Phase N (name) — recommends tier-X (profile).
Use /model <alias> to switch.
---
```

### Cross-tool switch

```
---
[shiplog routing] Entering Phase N (name) — recommends tier-X (profile).
Configured model: <model name> in <provider>.
Switch to <provider>. The handoff is on issue #<N>.
---
```

**Only prompt when the tier changes** between consecutive phases. Phase 2 (tier-2) → Phase 3 (tier-2) = no prompt.

---

## Context Handoff Protocol

When transitioning from a higher tier to a lower tier, the outgoing model MUST write a handoff comment on the issue (Full Mode) or `--log` PR (Quiet Mode).

### Handoff template

```markdown
## [#<ID>] handoff: Phase N → Phase M

**Tier transition:** tier-1 (reasoning) → tier-3 (fast)
**Recommended model:** [from config]

### What was decided
- [Decision 1 — concrete, not conceptual]
- [Decision 2]

### What to do next
1. [Concrete action with file path]
2. [Concrete action with file path]
3. [Concrete action with file path]

### Files to touch
- `path/to/file.ts` (create) — [what goes in it]
- `path/to/other.ts` (modify line N) — [what to change]

### Gotchas
- [Anything a cheaper model would get wrong without this warning]
- [Non-obvious conventions, env var names, type conflicts, etc.]
```

### Same-tool vs cross-tool

| Switch type | Handoff depth | Conversation context? |
|-------------|---------------|----------------------|
| Same-tool (e.g., Opus → Sonnet in Claude Code) | Light — summary only | Yes, prior context available |
| Cross-tool (e.g., Claude Code → Cursor) | Full — 100% self-contained | No, new tool starts cold |

The skill detects which case applies by checking the **Provider** column in the model inventory. Same provider = same-tool. Different provider = cross-tool.

### The golden rule

> If a tier-3 model reading this handoff would need to make a judgment call, the handoff is not specific enough. Rewrite it until every decision is pre-made.

---

## Environment Detection

How the skill detects the current model at runtime:

| Platform | Detection method |
|----------|-----------------|
| Claude Code | System prompt contains model ID (e.g., `claude-opus-4-6`) |
| Codex | Read `~/.codex/config.toml` → `model` field |
| Cursor | Cannot detect programmatically — include model name in routing prompt so user can self-check |
| Unknown | Ask user in routing prompt |

---

## Example Workflow

**Scenario:** Team builds auth middleware. Opus for planning, Sonnet for development, Composer for commits.

**1. Setup (once):**
`.shiplog/routing.md`:
```markdown
## Available Models

| Model | Provider | Tier |
|-------|----------|------|
| Claude Opus 4 | Claude Code | tier-1 |
| Claude Sonnet 4 | Claude Code | tier-2 |
| Cursor Composer 1.5 | Cursor | tier-3 |

## Routing Behavior
suggest
```

**2. Phase 1 — Brainstorm (Opus):**
User says "let's plan auth middleware". Skill detects Phase 1 (tier-1). Current model is Opus → no switch needed. Opus brainstorms, creates issue #42 with tier-aware task list. Before transitioning, Opus writes a handoff comment.

**3. Phase 2 — Branch setup (Sonnet):**
Routing prompt: `[shiplog routing] Entering Phase 2 — recommends tier-2. Use /model sonnet.`
User switches. Sonnet reads issue #42, creates branch, starts work.

**4. Phase 4 — Commits (Composer 1.5):**
Routing prompt: `[shiplog routing] Entering Phase 4 — recommends tier-3. Configured: Cursor Composer 1.5. Switch to Cursor. The handoff is on issue #42.`
User opens Cursor. Composer reads the handoff, follows self-contained task descriptions, commits.

**5. Phase 5 — PR synthesis (Opus):**
Routing prompt: `[shiplog routing] Entering Phase 5 — recommends tier-1. Switch to Claude Code, use /model opus.`
User switches back. Opus reads the full timeline from issue #42 comments, synthesizes the PR.
