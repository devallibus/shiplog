---
allowed-tools: Bash(gh:*), Bash(git:*), Read
description: Scan open issues and PRs, rank by readiness, recommend what to work on next
---

Triage the repository. Identify what is ready to work on, what needs review, and what you can gate-satisfy given your identity. Signed **shiplog** reviews live in PR/issue **comments**, not in formal GitHub review events — see `skills/shiplog/references/closure-and-review.md` §3 for the authoritative rule.

## Policy

A **signed shiplog review** is a PR or issue comment whose body contains both:
- `Reviewed-by: <family>/<version> (<tool>)` — provenance line
- `Disposition: approve | approve-with-follow-ups | request-changes` — outcome line

Formal GitHub `reviews` / `reviewDecision` fields are **advisory only**. GitHub blocks AI agents from self-`APPROVE`, and most AI-operated reviews are posted as comments, not formal review events. Do **not** rely on `reviewDecision` or `reviews` alone to determine whether a PR has been reviewed.

The cross-model gate rule: a review is gate-satisfying only when the reviewer's `<family>/<version>` differs from the `Last-code-by:` (or fallback chain) on the PR branch. See `skills/shiplog/references/closure-and-review.md` §3 ("What constitutes 'different model'") for the full definition.

## Query / Template

### Step 0 — Detect agent identity

Identify yourself from the system prompt:
```
<family>/<version> (<tool>)
```
Examples: `claude/opus-4.6 (claude-code)`, `openai/gpt-5.4 (codex)`.

Derive your tier:

| Model profile | Tier |
|---------------|------|
| Opus, GPT-5, o3 | tier-1 (reasoning) |
| Sonnet, GPT-4.1 | tier-2 (capable) |
| Haiku, GPT-4.1-mini | tier-3 (fast) |

If unlisted, default to tier-2. Record both for later steps.

### Step 1 — Fetch open issues

```bash
gh issue list --state open --json number,title,labels --limit 30
```

### Step 2 — Fetch open PRs with comments

Fetch the PR list including body, reviews, and commits:
```bash
gh pr list --state open --json number,title,isDraft,reviewDecision,reviews,body,url,headRefName --limit 20
```

Then for **each open PR**, fetch comments to detect signed reviews:
```bash
gh pr view <N> --json comments,commits
```

Signed-review detection — scan each comment body for both patterns:
```
Reviewed-by:
Disposition: approve
```
or
```
Disposition: approve-with-follow-ups
```

A comment containing both a `Reviewed-by:` line and a `Disposition: approve` or `Disposition: approve-with-follow-ups` line is a **valid signed approval**. A comment with `Disposition: request-changes` is a blocking review.

Use the PR body `review_status` snapshot first (fields: `Current state:`, `Last reviewed by:`, `Reviewed commit:`). If the snapshot is missing, stale, or contradicted by newer commits, fall back to scanning comments directly.

### Step 3 — Determine last code author per PR

For each PR, walk this fallback chain and stop at the first available signal:

1. `Last-code-by:` in the PR body (authoritative)
2. `Updated-by:` in the PR body (approximate)
3. `Authored-by:` in the PR body (may be stale)
4. Latest commit author on the PR branch

Extract `<family>/<version>` and compare against your identity from Step 0.

### Step 4 — Classify PRs

Apply signed-comment review results and last-code-author identity together:

| Review status (from comments) | Last code author | Classification |
|-------------------------------|-----------------|----------------|
| Signed approval exists | Different model | `approved + cross-model` — ready to merge |
| Signed approval exists | Same model | `approved + same-model` — cannot gate-satisfy |
| No signed approval, not draft | Different model | `awaiting-review + cross-model` — you can provide first review |
| `needs-rereview` snapshot | Different model | `needs-rereview + cross-model` — prior review stale |
| `changes-requested` comment | Any | `changes-requested` — author must address first |
| Draft | Any | `draft` — still in progress |

### Step 5 — Triage report

```
HUNT REPORT - <repo> (<date>)
Agent: <identity>, <tier>
================================

PRs NEEDING ACTION:
#NNN  <title>               <review-status>    <reviewability>

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
- `approved + cross-model (last code: <identity>)` — reviewed, mergeable
- `awaiting-review + cross-model (last code: <identity>)` — you can provide gate-satisfying review
- `needs-rereview + cross-model (last code: <identity>)` — prior review stale, you can re-review
- `changes-requested + cross-model (last code: <identity>)` — needs fixes first
- `same-model (last code: <identity>)` — cannot gate-satisfy; different reviewer needed
- `unknown author` — no provenance signal; treat as blocked

Issue priority order:
1. `shiplog/needs-review` — PR exists, awaiting cross-model sign-off
2. `shiplog/ready` — planned, ready to implement
3. `shiplog/in-progress` — already in flight
4. `shiplog/plan` (no lifecycle) — needs breakdown
5. No shiplog labels — uncategorized

### Step 6 — Recommendations

End with 1–3 concrete actions **filtered to what you can actually do**.

Identity constraints:

| Action | Cross-model PR | Same-model PR |
|--------|---------------|---------------|
| Gate-satisfying review | Yes | No |
| Merge after approval | Yes | No |
| Self-review (audit trail) | — | Only on explicit user confirmation |

Tier constraints:

| Tier | Can work on | Should flag |
|------|-------------|-------------|
| tier-1 | Any | tier-3 tasks as "could delegate down" |
| tier-2 | tier-2, tier-3 | tier-1 tasks as "needs reasoning model" |
| tier-3 | tier-3 only | tier-1/2 as "above my tier" |

**Recommendation templates:**

> Review PR #N — signed comment inspection shows awaiting review; you can provide the first gate-satisfying review.

> PR #N already has a signed `Disposition: approve` comment from a different model. Top merge candidate if branch is mergeable.

> No open PR allows a gate-satisfying review (all same-model or unknown). Recommend implementing ready issues instead.

## Acceptance Checklist

- [ ] For every open PR, `gh pr view <N> --json comments` was fetched and scanned for `Reviewed-by:` + `Disposition:` lines before classifying review status
- [ ] No PR with a valid signed `Disposition: approve` comment appears in the "needs review" bucket
- [ ] No PR with `Disposition: request-changes` is classified as approved
- [ ] Each PR's last-code author was resolved via the fallback chain (not assumed from `Authored-by:` alone)
- [ ] Cross-model gate check used the resolved last-code-author identity, not `reviewDecision`
- [ ] Recommendations are filtered to actions the current agent can actually perform given identity and tier
