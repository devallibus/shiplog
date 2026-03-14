# Model-Tier Routing Reference

Route AI models to shiplog phases based on cognitive demand. Use your best model for planning and synthesis, a fast model for implementation and commits, and delegation contracts when a stronger model wants a cheaper agent to execute bounded work.

---

## Tier Definitions

| Tier | Cognitive Profile | Use For | Example Models |
|------|-------------------|---------|----------------|
| **tier-1** (reasoning) | Creative synthesis, architectural judgment, narrative construction, trade-off evaluation | Brainstorming, PR timeline synthesis, complex discovery triage | Claude Opus, GPT-5.4 high, o3 |
| **tier-2** (capable) | Context loading, scope judgment, structured documentation | Issue-to-branch, discovery protocol, knowledge retrieval | Claude Sonnet, GPT-5.4 medium |
| **tier-3** (fast) | Execution speed, template filling, routine operations | Commits, simple implementations, timeline checkpoints, delegated bounded work | Claude Haiku, Cursor Composer 1.5, GPT-4o-mini |

## Default Phase-to-Tier Mapping

| Phase | Default Tier | Rationale |
|-------|--------------|-----------|
| 1. Brainstorm-to-Issue | tier-1 | Creative architecture, exploring design alternatives, writing tier-aware task lists |
| 2. Issue-to-Branch | tier-2 | Context loading, plan assessment, approach formulation |
| 3. Discovery Protocol | tier-2 | Scope judgment - categorizing discoveries requires cross-cutting analysis |
| 4. Commit-with-Context | tier-3 | Structured template, low creativity - commit messages are formulaic |
| 5. PR-as-Timeline | tier-1 | Narrative synthesis, journey reflection, extracting lessons learned |
| 6. Knowledge Retrieval | tier-2 | Search synthesis, connecting dots across artifacts |
| 7. Timeline Maintenance | tier-3 | Checkpoint updates, template filling |

---

## Project Configuration

Create `.shiplog/routing.md` in your project root to configure model routing and delegation defaults for your team.

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

## Delegation

- mode: suggest
- allowed_tiers: tier-3
- allowed_phases: 2, 4, 7
- issue_pr_operations: delegator-only
- default_decision_budget: none
- require_return_artifact: true
```

### Fields

**Available Models table:**
- **Model:** The model name as users know it
- **Provider:** The tool/environment where this model runs
- **Tier:** Which tier this model handles

**Routing Behavior** (one of):
- `suggest` (default when configured) - show routing prompt at tier transitions
- `quiet` - log tier in timeline comments only, no prompts to the user
- `off` - no routing behavior at all

**Delegation section:**
- `mode`: `suggest` | `quiet` | `off`
- `allowed_tiers`: Which target tiers may receive delegated work. Default: `tier-3`.
- `allowed_phases`: Which shiplog phases may use delegated execution. Default: `2, 4, 7`.
- `issue_pr_operations`: `delegator-only` (default) or `explicit-contract-only`. `delegator-only` means the delegated agent may not open, close, merge, or retitle issues/PRs. `explicit-contract-only` still requires the contract to grant the action directly.
- `default_decision_budget`: Default contract budget when omitted. Recommended: `none`.
- `require_return_artifact`: Whether every delegated run must produce a structured completion report. Recommended: `true`.

### Delegation defaults

If the delegation section is omitted, shiplog should assume:

- delegation is advisory only
- only `tier-3` execution is recommended for delegation
- only phases 2, 4, and 7 should delegate by default
- issue and PR lifecycle actions stay with the delegator
- delegated runs require a return artifact

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

## Delegation

- mode: suggest
- allowed_tiers: tier-3
- allowed_phases: 2, 4, 7
- issue_pr_operations: delegator-only
- default_decision_budget: none
- require_return_artifact: true
```

When a phase transition requires switching providers, the skill writes a full cross-tool handoff on the issue. When a stronger model delegates execution to a cheaper agent, it writes a delegation handoff with a bounded contract instead of a general summary.

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

To override delegation for a single issue, add:

```markdown
## Delegation

- mode: suggest
- allowed_phases: 2, 4
- issue_pr_operations: delegator-only
- default_decision_budget: none
```

Per-issue delegation may tighten project defaults, but should not widen them silently. For example, an issue may reduce delegation to phase 4 only, but should not grant issue-closing authority if the project default forbids it.

---

## First-Activation Setup Wizard

When model routing is first used and no `.shiplog/routing.md` exists, the skill runs a setup wizard:

### Step 1: Detect platform

| Signal | Platform |
|--------|----------|
| System prompt contains `claude-*` model ID | Claude Code |
| System prompt contains `powered by <model-id>` | Cursor |
| `~/.codex/config.toml` exists with `model` field | Codex |
| None of the above detected | Ask user |

### Step 2: Suggest models

**Claude Code detected:**
> I see you're running Claude Code. Available model tiers:
> - tier-1: Claude Opus 4 (`/model opus`)
> - tier-2: Claude Sonnet 4 (`/model sonnet`)
> - tier-3: Claude Haiku 4.5 (`/model haiku`)
>
> Do you use any other tools (Cursor, Codex, etc.)? If so, which models?

**Cursor detected:**
> I see you're running Cursor with [model-id from system prompt]. Which tier should this model be?
>
> Do you use any other tools (Claude Code, Codex, etc.)? If so, which models?

**Codex detected:**
> Reading `~/.codex/config.toml`... Current model: [model]. Available models from `~/.codex/models_cache.json`: [list].
> Which tier should each model be?

**No platform detected:**
> Which AI tools and models do you use? I'll set up routing for your workflow.

### Step 3: Confirm delegation policy

Ask:

- Do you delegate bounded implementation work to cheaper agents today?
- Which phases may delegate by default?
- Should delegated agents ever perform issue or PR lifecycle actions directly, or should those stay with the delegator?

### Step 4: Generate config

Create `.shiplog/routing.md` with the user's confirmed model inventory, tier assignments, and delegation defaults.

---

## Routing Prompt Format

At phase transitions, when the entering phase's tier differs from the previous phase's tier:

### Same-tool switch

```
---
[shiplog routing] Entering Phase N (name) - recommends tier-X (profile).
Use /model <alias> to switch.
---
```

### Cross-tool switch

```
---
[shiplog routing] Entering Phase N (name) - recommends tier-X (profile).
Configured model: <model name> in <provider>.
Switch to <provider>. The handoff is on issue #<N>.
---
```

Only prompt when the tier changes between consecutive phases. Phase 2 (tier-2) -> Phase 3 (tier-2) means no prompt.

---

## Context Handoff Protocol

When transitioning from a higher tier to a lower tier, the outgoing model MUST write a handoff comment on the issue (Full Mode) or `--log` PR (Quiet Mode). The receiving model should get a contract, not a goal. If a cheaper model must infer scope from tone, the handoff is underspecified.

### Phase-transition handoff template

```markdown
## [#<ID>] handoff: Phase N -> Phase M

**Tier transition:** tier-1 (reasoning) -> tier-3 (fast)
**Recommended model:** [from config]

### What was decided
- [Decision 1 - concrete, not conceptual]
- [Decision 2]

### What to do next
1. [Concrete action with file path]
2. [Concrete action with file path]
3. [Concrete action with file path]

### Contract
- **Allowed files:** `path/to/file.ts`, `path/to/other.ts`
- **Must not change:** [files, APIs, behavior, or decisions that remain out of scope]
- **Stop and ask if:** [condition that would require widening scope or making a judgment call]
- **Active verification profile:** [profile names or `none`]
- **Verification required:** [tests, checks, or evidence that must exist before reporting done]
- **Return artifact:** [diff summary, verification note, changed file list, blocker report]
- **Decision budget:** `none` | `narrow` | `full`

### Files to touch
- `path/to/file.ts` (create) - [what goes in it]
- `path/to/other.ts` (modify line N) - [what to change]

### Gotchas
- [Anything a cheaper model would get wrong without this warning]
- [Non-obvious conventions, env var names, type conflicts, etc.]
```

### Same-tool vs cross-tool

| Switch type | Handoff depth | Conversation context? |
|-------------|---------------|-----------------------|
| Same-tool (for example, Opus -> Sonnet in Claude Code) | Light - summary only | Yes, prior context available |
| Cross-tool (for example, Claude Code -> Cursor) | Full - 100% self-contained | No, new tool starts cold |

The skill detects which case applies by checking the **Provider** column in the model inventory. Same provider means same-tool. Different provider means cross-tool.

### The golden rule

> If a tier-3 model reading this handoff would need to make a judgment call, the handoff is not specific enough. Rewrite it until every decision is pre-made.

For delegated execution, `Decision budget: none` should be the default. If the work really needs local judgment, narrow the allowed decision surface explicitly instead of implying it.

---

## Delegation Mode

Delegation mode is separate from a normal phase switch. Use it when one model or agent spawns another agent to execute a bounded task, even if both agents remain in the same phase.

### Core rule

Delegated execution is an extension of the handoff protocol:

1. A tier-1 or tier-2 model writes the contract.
2. The delegated agent executes only within that contract.
3. The delegated agent returns a structured artifact linked to the issue or `--log` PR.
4. The delegator decides whether follow-up work, issue updates, commits, or PR lifecycle actions should happen.

### When delegation is allowed

Delegation is recommended only when all of the following are true:

- the task is already decomposed and scoped
- the files or directories to touch are known
- acceptance criteria are concrete
- the delegated agent does not need to choose among product or architecture options
- verification and return-artifact requirements are explicit

Shiplog should recommend delegation primarily for `[tier-3]` issue tasks and routine implementation or documentation work in phases 2, 4, and 7.

### When delegation is not allowed

Do not delegate when the task requires:

- brainstorming or trade-off evaluation
- discovery triage that may widen scope
- issue creation or issue closure judgment
- PR synthesis, merge authorization, or review disposition
- choosing among multiple valid approaches without a pre-made decision

By default, delegated agents do not open, close, merge, or retitle issues or PRs. If a team intentionally allows this, the contract must say so explicitly and all existing closure and review rules still apply.

### Delegation handoff template

```markdown
## [#<ID>] delegation handoff: <task title>

**Delegated by:** <family>/<version> (<tool>)
**Target tier:** tier-3
**Why delegation fits:** [why this work is bounded and non-judgmental]

### Goal
[One concrete outcome. This is the only goal.]

### Contract
- **Allowed files:** `path/to/file.ts`, `path/to/other.ts`
- **Must not change:** [files, APIs, behavior, or decisions outside scope]
- **Acceptance criteria:** [specific outcomes that define done]
- **Forbidden judgment calls:** [decisions the delegated agent must not make]
- **Stop and ask if:** [conditions that require escalation]
- **Active verification profile:** [profile names or `none`]
- **Verification required:** [tests, checks, or evidence required]
- **Return artifact:** [delegation report, changed-file list, verification note, blockers]
- **Decision budget:** `none` | `narrow`

### Task checklist
1. [Concrete action with file path]
2. [Concrete action with file path]
3. [Concrete action with file path]

### Gotchas
- [Anything the delegated agent could misunderstand]
```

### Return artifact requirements

Every delegated run should report, at minimum:

- changed files
- whether acceptance criteria were met
- verification status
- blockers encountered
- decisions deferred back upward

If the delegated agent completes code changes but cannot satisfy the full contract, the return artifact must say so explicitly. Silence is not completion.

### Delegation report template

```markdown
## [#<ID>] delegation report: <task title>

**Status:** completed | blocked | escalated
**Contract:** [link or quote the delegation handoff heading]

### Changed files
- `path/to/file.ts` - [summary]

### Acceptance criteria
- [x] [criterion met]
- [ ] [criterion not met, with reason]

### Verification status
- **Ran:** [commands/checks]
- **Passed:** [what passed]
- **Deferred:** [what was skipped, with reason]

### Decisions deferred upward
- [question or "None"]

### Blockers
- [blocker or "None"]
```

### The golden rule for delegation

> If the delegated agent would need to interpret intent, choose an approach, or widen scope, the task was not delegated correctly.

Rewrite the contract until the cheap agent can succeed by executing, not by deciding.

---

## Environment Detection

How the skill detects the current model at runtime:

| Platform | Detection method |
|----------|------------------|
| Claude Code | System prompt contains model ID (for example, `claude-opus-4-6`) |
| Codex | Read `~/.codex/config.toml` -> `model` field |
| Cursor | System prompt contains model identifier (for example, `powered by claude-4.6-opus-high-thinking`). Fall back to asking the user if not present |
| Unknown | Ask user in routing prompt |

---

## Example Workflow

**Scenario:** Team builds auth middleware. Opus for planning, Sonnet for development, Composer for delegated commits.

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

## Delegation

- mode: suggest
- allowed_tiers: tier-3
- allowed_phases: 2, 4, 7
- issue_pr_operations: delegator-only
- default_decision_budget: none
- require_return_artifact: true
```

**2. Phase 1 - Brainstorm (Opus):**
User says "let's plan auth middleware". Skill detects Phase 1 (tier-1). Current model is Opus, so no switch is needed. Opus brainstorms, creates issue #42 with tier-aware task list, and marks the routine implementation blocks as delegable.

**3. Phase 2 - Branch setup (Sonnet):**
Routing prompt: `[shiplog routing] Entering Phase 2 - recommends tier-2. Use /model sonnet.`
User switches. Sonnet reads issue #42, creates the branch, writes a delegation handoff for the bounded file edits, and keeps discovery or API-design decisions for itself.

**4. Phase 4 - Delegated implementation (Composer 1.5):**
Sonnet spawns or briefs Composer with the delegation handoff. Composer edits only the listed files, follows the explicit acceptance criteria, and returns a delegation report with changed files, blockers, and verification status.

**5. Phase 5 - PR synthesis (Opus):**
Routing prompt: `[shiplog routing] Entering Phase 5 - recommends tier-1. Switch to Claude Code and use /model opus.`
User switches back. Opus reads the issue timeline, delegation handoff, and delegation report, then synthesizes the PR with the higher-tier reasoning still attached to the work artifact.
