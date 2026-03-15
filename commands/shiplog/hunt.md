---
allowed-tools: Bash(gh:*), Bash(git:*), Read
description: Scan open issues and PRs, rank by readiness, recommend what to work on next
---

## Context

- Repo: !`gh repo view --json nameWithOwner --jq '.nameWithOwner'`
- Current branch: !`git branch --show-current`
- Open issues with labels: !`gh issue list --state open --json number,title,labels --limit 30`
- Open PRs with review status: !`gh pr list --state open --json number,title,reviewDecision,reviews,isDraft,body --limit 20`

## Your Task

You are the shiplog hunt command. Present a triage report of all open issues and PRs, filtered by what **you** can actually do.

### Step 0: Detect Agent Identity

Identify yourself using the signing convention from `references/signing.md`:

```
<family>/<version> (<tool>)
```

For example: `claude/opus-4.6 (claude-code)`, `openai/gpt-5.4 (codex)`.

Then derive your tier from `references/model-routing.md`:

| Model Profile | Tier |
|---------------|------|
| Opus, GPT-5, o3 | tier-1 (reasoning) |
| Sonnet, GPT-4.1 | tier-2 (capable) |
| Haiku, GPT-4.1-mini | tier-3 (fast) |

If your model is not listed, default to tier-2.

Record both for use in later steps:
- **Identity:** e.g., `claude/opus-4.6`
- **Tier:** e.g., `tier-1`

### Step 1: Categorize Issues

Group open issues by their lifecycle label:

| Priority | Label | Meaning |
|----------|-------|---------|
| 1 (act now) | `shiplog/needs-review` | PR exists, needs cross-model review before merge |
| 2 (act now) | `shiplog/ready` | Planned and ready to implement |
| 3 (in flight) | `shiplog/in-progress` | Already being worked on |
| 4 (needs planning) | `shiplog/plan` (no lifecycle label) | Needs further breakdown or review |
| 5 (parked) | No shiplog labels | Uncategorized or external |

### Step 2: Categorize PRs

Group open PRs by review status:

| Priority | Status | Action Needed |
|----------|--------|---------------|
| 1 | No reviews, not draft | Needs review — can we review and merge? |
| 2 | Changes requested | Needs fixes then re-review |
| 3 | Approved | Ready to merge |
| 4 | Draft | Still in progress |

### Step 2a: Check PR Code Authorship Against Agent Identity

For each PR from Step 2, determine who **last changed the code** using the provenance fallback chain from `references/signing.md` § Code Provenance:

1. **`Last-code-by:`** in the PR body (authoritative)
2. **`Updated-by:`** in the PR body (approximate — may reflect text edits, not code)
3. **`Authored-by:`** in the PR body (original author — may be stale)
4. If none found, the code author is **unknown**

Extract the `<family>/<version>` from the first available field and compare against your identity from Step 0.

Classify each PR:

| Classification | Condition | What you can do |
|----------------|-----------|-----------------|
| **cross-model** | Last code author is a different model family or version | Gate-satisfying review |
| **same-model** | Last code author matches your identity | Cannot gate-satisfy review (audit trail only) |
| **unknown** | No provenance fields found in PR body | Cannot assume cross-model — treat as blocked |

### Step 3: Present the Hunt Report

Display a compact table with your identity header and reviewability annotations:

```
HUNT REPORT — <repo> (<date>)
Agent: <identity>, <tier>
================================

PRs NEEDING ACTION:
#NNN  <title>               <status>    <reviewability>

ISSUES NEEDING REVIEW:
#NNN  <title>               <labels>

ISSUES READY TO IMPLEMENT:
#NNN  <title>               <labels>

ISSUES IN PROGRESS:
#NNN  <title>               <labels>

ISSUES NEEDING PLANNING:
#NNN  <title>               <labels>
```

Where `<reviewability>` is one of:
- `✓ cross-model (last code: <identity>)` — you can gate-satisfy review
- `⊘ same-model (last code: <identity>)` — review blocked, same model
- `? unknown author` — no provenance, treat as blocked

### Step 4: Recommend

End with 1-3 concrete recommendations **filtered by what you can actually do**.

**Rule: never recommend an action the agent cannot perform.**

#### Identity constraints

| Action | Cross-model PR | Same-model PR | Unknown PR |
|--------|---------------|---------------|------------|
| Gate-satisfying review | Yes | No | No |
| Self-review (audit trail) | — | Only if user confirms | — |
| Fix requested changes | Yes (if you authored the code) | Yes | — |

#### Tier constraints

| Agent Tier | Can work on | Should flag |
|------------|-------------|-------------|
| tier-1 (reasoning) | Any tier work | tier-3 tasks as "could delegate down" |
| tier-2 (capable) | tier-2 and tier-3 work | tier-1 tasks as "needs reasoning model" |
| tier-3 (fast) | tier-3 work only | tier-1/tier-2 as "above my tier" |

Read tier tags from issue task lists (e.g., `[tier-1]`, `[tier-2]`, `[tier-3]`). If no tier tag, treat as tier-2.

#### Recommendation templates

**When cross-model PRs exist:**
> Review PR #N — cross-model, you can gate-satisfy review

**When all PRs are same-model or unknown:**
> All open PRs were last coded by [your identity]. Cross-model review requires a different model (e.g., switch to [suggested alternative]). You can still implement ready issues.

**When issues are above your tier:**
> Issue #N has tier-1 tasks — needs a reasoning model (e.g., Opus). Consider implementing tier-2/tier-3 issues instead.

**When issues could be delegated down:**
> Issue #N has only tier-3 tasks — could delegate to a faster model for efficiency.

Keep the report concise. The user wants to know what to do next, not read every issue body.
