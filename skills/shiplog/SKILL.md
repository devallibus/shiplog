---
name: shiplog
description: Git-as-knowledge-graph workflow for traceability. Use when planning work, brainstorming designs, creating/managing issues and PRs, tracking architectural decisions, or resuming prior sessions. Slash command /shiplog.
---

# Shiplog

The captain's log for your codebase. Every decision, discovery, and change logged as you ship code.

Use GitHub as a complete knowledge graph where every brainstorm, commit, review, and decision is traceable. This skill orchestrates existing skills and references; it defines when and how to invoke them and what documentation protocol to follow.

## Core Principle

**Nothing gets lost.** Every brainstorm becomes an issue. Every issue drives a branch. Every branch produces a PR. Every PR is a timeline of the entire journey. Git becomes the uber-memory.

---

## Golden-Path Walkthrough

A complete issue-to-merge example using a concrete fake issue `#999`. Follow this sequence and every artifact produced will pass the acceptance checklists in `commands/shiplog/*.md`.

### Step 1 — Plan Capture (`/shiplog plan`)

A brainstorm produces: "Add rate-limit headers to the API so clients can back off intelligently." Load `commands/shiplog/plan.md` and create the issue:

```bash
gh issue create \
  --title "[shiplog/plan] Add rate-limit headers to API" \
  --label "shiplog/plan" \
  --body-file .tmp-plan.md
```

Issue body (excerpt):
```
<!-- shiplog:
kind: state
status: open
phase: 1
readiness: ready
task_count: 2
tasks_complete: 0
max_tier: tier-2
updated_at: 2026-04-18T10:00:00Z
-->
## Tasks
- [ ] **T1: Add X-RateLimit-* headers to response middleware** `[tier-2]`
  - **What:** Inject X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset on every API response.
  - **Verification:** curl the endpoint; confirm all three headers are present.
- [ ] **T2: Document header semantics in API reference** `[tier-2]`
  - **What:** Add a "Rate Limiting" section to docs/api-reference.md.
  - **Verification:** Section exists and matches header values in integration test.

Authored-by: claude/sonnet-4.6 (claude-code)
```

Apply lifecycle label: `gh issue edit 999 --add-label "shiplog/ready"`

### Step 2 — Branch Setup (`/shiplog start`)

Load `commands/shiplog/start.md`. Create the branch from the default branch tip (substitute your repo's default branch, e.g. `main` or `master`):

```bash
git fetch origin <default-branch>
git checkout -b issue/999-rate-limit-headers origin/<default-branch>
```

Swap label and update envelope:
```bash
gh issue edit 999 --remove-label "shiplog/ready" --add-label "shiplog/in-progress"
# Edit issue body: readiness: ready → readiness: in-progress
```

Post session-start comment:
```
[shiplog/session-start] #999: Starting work

**Branch:** `issue/999-rate-limit-headers`
**Starting tasks:** T1, T2
**Plan:** Add headers in middleware (T1) then document (T2).

Authored-by: claude/sonnet-4.6 (claude-code)
```

### Step 3 — Commit Context (`/shiplog commit`)

After implementing T1, load `commands/shiplog/commit.md` and commit:

```bash
git add src/middleware/rate_limit.ts
git commit -F .tmp-commit-msg.md
# Commit message: feat(#999/T1): add X-RateLimit-* headers to response middleware
#
# Injects the three standard headers into every API response via middleware.
#
# Authored-by: claude/sonnet-4.6 (claude-code)
```

Post commit-note on the issue:
```
[shiplog/commit-note] #999: a1b2c3d feat(#999/T1): add X-RateLimit-* headers

**What:** Middleware now injects X-RateLimit-Limit, -Remaining, and -Reset.
**Why:** Clients need these to implement back-off without polling.
**Verification:** curl localhost:3000/api/health — all three headers present.

Authored-by: claude/sonnet-4.6 (claude-code)
```

Repeat for T2 commit (`docs(#999/T2): document rate-limit headers in API reference`).

### Step 4 — PR Timeline (`/shiplog pr`)

Load `commands/shiplog/pr.md`. Push and create the PR:

```bash
git push -u origin issue/999-rate-limit-headers
gh pr create \
  --title "feat(#999): add rate-limit headers to API" \
  --label "shiplog/history" \
  --label "shiplog/issue-driven" \
  --body-file .tmp-pr-body.md
```

PR body includes: envelope (`kind: history`), summary, `Closes #999`, Journey Timeline with both commits, Verification checklist, Reviews placeholder, and sig block:
```
Authored-by: claude/sonnet-4.6 (claude-code)
Last-code-by: claude/sonnet-4.6 (claude-code)
*Captain's log — PR timeline by **shiplog***
```

Transition issue label:
```bash
gh issue edit 999 --remove-label "shiplog/in-progress" --add-label "shiplog/needs-review"
```

### Step 5 — Cross-Model Review (`/shiplog review`)

A different model (e.g., `openai/gpt-5.4 (codex)`) loads `commands/shiplog/review.md`, reads the diff, and posts the signed review comment on the PR:

```
[shiplog/review-handoff] #999: Review of PR #<PR>

Middleware approach is correct. Headers match RFC 6585 semantics.

Reviewed-by: openai/gpt-5.4 (codex, effort: high)
Disposition: approve
Scope: full diff
Follow-ups: none
```

The reviewer then updates the PR body review snapshot in place:
```
Current state: approved
Last reviewed by: openai/gpt-5.4 (codex, effort: high)
Last reviewed at: 2026-04-18T15:00:00Z
Reviewed commit: a1b2c3d
Source artifact: <URL to review comment>
Needs re-review since: —
```

### Step 6 — Merge

Cross-model gate is satisfied (`Last-code-by: claude/sonnet-4.6` ≠ `Reviewed-by: openai/gpt-5.4`). Merge the PR. Remove all lifecycle labels from issue #999. GitHub closes #999 automatically via `Closes #999`.

---

## When This Skill Activates

**User-invocable:** `/shiplog`, `/shiplog models`, `/shiplog <phase>`

**`/shiplog models`:** Re-runs the routing setup prompt. See `references/model-routing.md`.

**Auto-activate when ANY of these occur:**
- User says "let's plan", "let's brainstorm", or "let's design"
- User explicitly requests traceability or knowledge-graph tracking
- Creating a new issue or PR with intent to document decisions
- Mid-work discovery requiring a new issue or stacked PR
- User asks "where did we decide X?" or "what's the status of Y?"
- Resuming work on an existing issue or PR
- Applying review feedback, fixing review findings, or addressing request-changes dispositions
- User references an issue or PR by number
- Issue or PR body footer contains `Managed by **shiplog**` (recognition trigger — do not add this footer proactively)

**Do NOT auto-activate for:**
- Generic coding requests that do not need traceability
- Simple bug fixes or refactors that do not need durable workflow history
- Work where a more specific skill is the better fit

---

## Verb Grid

Each `/shiplog <phase>` slash command maps to one sub-skill file. Load the file for that phase — it owns policy, templates, and acceptance checklist.

| Command | What it does | Sub-skill |
|---------|-------------|-----------|
| `/shiplog plan` | Capture a brainstorm as a GitHub planning issue with envelope + task contracts | `commands/shiplog/plan.md` |
| `/shiplog start` | Create a branch from an issue, swap lifecycle labels, post session-start comment | `commands/shiplog/start.md` |
| `/shiplog hunt` | Triage open issues and PRs; rank by readiness; detect gate-satisfying reviews | `commands/shiplog/hunt.md` |
| `/shiplog commit` | Stage and commit with ID-first format; post commit-note comment for significant commits | `commands/shiplog/commit.md` |
| `/shiplog pr` | Push branch, create PR with journey timeline body, transition issue label | `commands/shiplog/pr.md` |
| `/shiplog review` | Perform cross-model review; post signed comment; update PR body review snapshot | `commands/shiplog/review.md` |
| `/shiplog lookup` | Search issues, PRs, and git log by `#ID` or keyword; return compact table first | `commands/shiplog/lookup.md` |
| `/shiplog resume` | Re-orient to current branch; detect issue number; post session-resume comment | `commands/shiplog/resume.md` |

**`/shiplog models`:** Re-runs the model-routing setup prompt. See `references/model-routing.md`.

---

## Canonical Kind → Tag → Label Map

`kind:` in envelope YAML is the source of truth. Title tags (`[shiplog/<tag>]`) and GitHub labels (`shiplog/<label>`) are derived views on `kind:`. When a new artifact kind is defined, it is added here once and all three surfaces are updated together.

| `kind:` (envelope) | Title tag `[shiplog/<tag>]` | GitHub label `shiplog/<label>` | Description |
|--------------------|-----------------------------|-------------------------------|-------------|
| `state` | `plan`, `session-start`, `session-resume`, `milestone`, `discovery`, `implementation-issue` | `plan` (planning issues) | Current status snapshot of an issue or PR |
| `handoff` | `session-start`, `review-handoff` | — | Context transfer between tiers, tools, or sessions |
| `verification` | `commit-note`, `review-handoff`, `verification` | `verification` | Evidence of testing, review, or quality check |
| `commit-note` | `commit-note` | — | Reasoning behind a specific commit |
| `review-handoff` | `review-handoff` | — | Review request or review completion artifact |
| `amendment` | `amendment` | — | Correction or clarification for an existing signed artifact |
| `blocker` | `blocker` | `blocker` | Something preventing progress |
| `history` | `history` | `history` | Retrospective summary for knowledge retrieval |

**Lifecycle labels** (`shiplog/ready`, `shiplog/in-progress`, `shiplog/needs-review`) are not tied to an artifact `kind:`. They track issue/PR workflow state and are mutually exclusive. Apply them per the Triage Field Maintenance table below.

**Aspect labels** (`shiplog/discovery`, `shiplog/stacked`, `shiplog/issue-driven`) classify the relationship between artifacts, not their content kind. They may coexist with lifecycle labels.

For the full label set, color codes, and bootstrap CLI snippets, see `references/labels.md` (which cross-references this table as its canonical kind source).

---

## ID-First Naming Convention

All artifacts use `#ID` as the primary key for fast, token-efficient retrieval.

**Semantic tag vocabulary** for user-facing headings: `plan`, `session-start`, `session-resume`, `commit-note`, `discovery`, `blocker`, `implementation-issue`, `handoff`, `review-handoff`, `history`, `amendment`, `milestone`, and `verification`. Format: `[shiplog/<tag>] <human title>`. See the Canonical Kind → Tag → Label Map section for the authoritative mapping.

| Artifact | Convention | Example |
|----------|-----------|---------|
| Branch | `issue/<id>-<slug>` | `issue/42-auth-middleware` |
| Commit | `<type>(#<id>): <msg>` | `feat(#42): add JWT validation` |
| Commit (task) | `<type>(#<id>/<Tn>): <msg>` | `feat(#42/T2): add middleware chain` |
| PR title | `<type>(#<id>): <msg>` | `feat(#42): add auth middleware` |
| PR body (closes) | `Closes #<id>` | `Closes #42` |
| PR body (partial) | `Addresses #<id> (completes ...)` | `Addresses #42 (completes T1, T2)` |
| Task in issue | `- [ ] **T<n>: Title** [tier-N]` | `- [ ] **T1: Add JWT** [tier-3]` |
| Timeline comment | `[shiplog/<kind>] #<id>: ...` | `[shiplog/discovery] #42: race condition` |
| Stacked branch | `issue/<new-id>-<slug>` | `issue/43-fix-race-condition` |
| Stacked PR title | `<type>(#<new-id>): ... [stack: #<parent>]` | `fix(#43): race cond [stack: #42]` |
| Memory entry | `#<id>: <decision>` | `#42: chose JWT over sessions` |

**Task IDs:** Tasks carry local IDs (`T1`, `T2`, ...) scoped to the issue. Commits use `#<id>/<Tn>`.

**Retrieval:** `gh issue list --search "#42"` | `git log --grep="#42"` | `git log --grep="#42/T1"` | `gh pr list --search "#42"`

### Envelope Schema and Triage Fields

Issue and PR envelopes use `<!-- shiplog: ... -->` HTML comment blocks. The full field schema and triage field derivation rule live in `references/artifact-envelopes.md` §1. Summary of triage fields:

| Field | Derived from | Hand-written? |
|-------|-------------|---------------|
| `task_count` | Count of `- [ ]` + `- [x]` lines | No — derived |
| `tasks_complete` | Count of `- [x]` lines | No — derived |
| `max_tier` | Highest `[tier-N]` among unchecked tasks | No — derived |
| `readiness` | Workflow intent | Yes |

**Triage field maintenance:** keep envelope triage fields current on each lifecycle event. See the Triage Field Maintenance table below. Derivation rule is in `references/artifact-envelopes.md` §1.

### Triage Field Maintenance

Issue envelope triage fields (`readiness`, `task_count`, `tasks_complete`, `max_tier`) and lifecycle labels must be kept current so triage scans produce accurate results.

| Event | Envelope update | Label update |
|-------|----------------|--------------|
| Issue created (Phase 1) | Set all four triage fields at creation (`task_count`, `tasks_complete`, `max_tier` from derivation rule; `readiness` by intent) | Apply `shiplog/ready` if tasks are scoped and no blockers |
| Branch created (Phase 2) | Set `readiness: in-progress` | Replace lifecycle label with `shiplog/in-progress` |
| Task checked off (Phase 4) | Recompute `tasks_complete` and `max_tier` from body (derivation rule) | - |
| All tasks complete | Set `readiness: done`; `max_tier` will be empty per derivation rule | - |
| Blocker found (Phase 3) | Set `readiness: blocked` | Add `shiplog/blocker` |
| Blocker cleared | Restore previous `readiness` (`in-progress` or `ready`) | Remove `shiplog/blocker` |
| PR created (Phase 5) | Set `readiness: done` if all tasks shipped | Replace lifecycle label with `shiplog/needs-review` |
| PR merged and issue closed | - | Remove all lifecycle labels |

**Derived fields:** `task_count`, `tasks_complete`, and `max_tier` are computed from the issue body task list (counted `- [ ]` / `- [x]` lines and highest `[tier-N]` among unchecked tasks). See the derivation rule in `references/artifact-envelopes.md` §1 "Triage field derivation". Only `readiness` is hand-written.

Edit the issue body in place when these fields change. Triage metadata is derived state, so refreshing it does not require `Updated-by:` provenance.

---

## Agent Identity Signing

Every shiplog artifact (comments, PR bodies, review sign-offs) must carry a provenance signature in the canonical format:

```
<role>: <family>/<version> (<tool>[, <qualifier>])
```

### Signature field reference

| Field | Values | Examples |
|-------|--------|---------|
| `role` | `Authored-by`, `Updated-by`, `Reviewed-by`, or `Last-code-by` | — |
| `family` | Provider name, lowercase | `claude`, `openai`, `google` |
| `version` | Model identifier | `opus-4.6`, `sonnet-4.6`, `gpt-5.4` |
| `tool` | Runtime environment, lowercase | `claude-code`, `codex`, `cursor` |
| `qualifier` | Optional metadata string; may be compound when needed | `effort: high`, `orchestrator`, `sub-agent: reviewer`, `effort: high; orchestrator` |

**Searching:** `Authored-by:` → original authorship. `Updated-by:` → later material editors. `Reviewed-by:` → review artifacts. `Last-code-by:` → most recent code author on a PR branch. `claude/` → all Claude artifacts. `(codex` → all Codex artifacts.

### Model detection per tool

| Tool | Source | Example signature |
|------|--------|-------------------|
| Claude Code | System prompt model name | `claude/opus-4.6 (claude-code)` |
| Codex | `~/.codex/config.toml` `model` + `model_reasoning_effort` | `openai/gpt-5.4 (codex, effort: high)` |
| Cursor | System prompt model identifier | `claude/opus-4.6 (cursor)` |
| Other | Best available model identifier | `<family>/<version> (<tool>)` |

### Orchestration role qualifiers

When an artifact is emitted as part of a multi-lane flow, qualifiers carry orchestration role information:

- `orchestrator` — the current actor dispatched or collected delegated lanes
- `sub-agent: reviewer` — delegated reviewer lane
- `sub-agent: verifier` — delegated closure verifier lane
- `sub-agent: implementation` — delegated implementation lane

Examples:
- `Authored-by: openai/gpt-5.4 (codex, effort: high; orchestrator)`
- `Reviewed-by: claude/opus-4.6 (claude-code, sub-agent: reviewer)`
- `Authored-by: openai/gpt-5.4 (codex, sub-agent: verifier)`

### Correction rule

If a shiplog artifact carries an incorrect or incomplete signature, correct it in place when the platform allows editing. Otherwise post an immediate follow-up correction.

### Edit provenance rules

- `Authored-by:` records the original author of an artifact body.
- `Updated-by:` records a later model or human who materially edits that same artifact body. Preserve the original `Authored-by:` line and append a new `Updated-by:` line for each material edit, newest last.
- `Reviewed-by:` is review-only. Do not use it for authorship or edit attribution.
- Updating a PR body's review snapshot after publishing a signed review comment or after pushing code that makes a prior review stale counts as a material edit.
- A **material edit** changes meaning, facts, scope, requirements, acceptance criteria, verification results, review disposition, or a handoff contract. Typos, formatting cleanups, and link-only fixes are cosmetic and do not need `Updated-by:`.

### Code provenance: `Last-code-by:`

`Last-code-by:` tracks which model most recently pushed code to a PR branch. It is distinct from artifact provenance fields.

| Field | Tracks | Updated when |
|-------|--------|-------------|
| `Authored-by:` | Original artifact text author | Artifact is created |
| `Updated-by:` | Later artifact text editor | Artifact body is materially edited |
| `Reviewed-by:` | Review author | Review sign-off is posted |
| `Last-code-by:` | Most recent code author | Code is pushed to the PR branch |

**When to set `Last-code-by:`:**
- On PR creation: set in the PR body sign-off block (the creating model is the initial code author).
- After pushing code to an existing PR branch: update via `gh pr edit`.
- After review-driven code changes: the reviewer who pushes fixes becomes `Last-code-by:`.

**When NOT to update `Last-code-by:`:** reviewing without pushing code; editing the PR body text without commits; rebasing or force-pushing without new code changes.

**Why this field exists:** The multi-model review gate must know who last changed the code to determine whether a review is cross-model (gate-satisfying) or same-model (non-gate-satisfying). Without `Last-code-by:`, consumers fall back to git commit forensics.

**Fallback chain for review gating:**
1. `Last-code-by:` in the PR body (authoritative)
2. `Updated-by:` in the PR body (approximate)
3. `Authored-by:` in the PR body (original author — may be stale)
4. Git commit author on the PR branch (last resort)

### Edit-in-place vs amendment

- **Edit in place** when the artifact is meant to stay the single canonical current body: issue bodies, PR bodies, and latest-wins status/history artifacts. Refresh envelope `updated_at` and add `updated_by` plus `edit_kind` fields when an envelope exists.
- **Post an amendment artifact** when the original text matters for auditability: handoffs, verification comments, commit-note comments, review sign-offs, and other major signed timeline entries.

Use `supersedes` when the new artifact replaces the old one as canonical. Use `amends` when the new artifact corrects or clarifies but both should remain visible.

**In-place edit footer — append after original `Authored-by:`:**

```markdown
Updated-by: <family>/<version> (<tool>)
Edit-kind: correction | amendment | rewrite
Edit-note: [1 sentence describing what changed and why]
```

**Amendment artifact template:**

```markdown
<!-- shiplog:
kind: amendment
issue: <ISSUE_NUMBER>
pr: <PR_NUMBER>
updated_at: <ISO_TIMESTAMP>
amends: <artifact-reference>
-->

## [shiplog/amendment] #<ISSUE_NUMBER>: <brief description>

**Target:** [URL to the artifact being corrected or clarified]
**Edit kind:** correction | amendment | rewrite
**Why new artifact:** [why this should not be a silent in-place edit]
**What changed:**
- [change 1]
- [change 2]

**Current canonical artifact:** [URL to the current body, or `this comment`]

Authored-by: <family>/<version> (<tool>)
```

If the amendment fully replaces the old artifact, swap `amends:` for `supersedes:` and update the old artifact with `superseded_by:` when practical.

### PR body review snapshot maintenance

When a PR body carries the current review snapshot:
- Post the signed `Reviewed-by:` comment first. That comment is the review evidence.
- Then refresh the PR body snapshot in place so retrieval flows can read current review state without replaying the comment thread.
- If new code lands after the latest signed review, update the snapshot to `needs-rereview` and record the commit that made the prior review stale.
- Use the standard `Updated-by:` footer and envelope `updated_by` / `edit_kind` fields for these edits.

Model identity detection is also used by model-tier routing to verify the current model matches the recommended tier. See `references/model-routing.md`.

---

## GitHub Labels

**shiplog** manages a compact repo-level label vocabulary so issues and PRs stay filterable even when a reader never opens the body. See `references/labels.md` for the canonical label set, descriptions, and CLI snippets.

Label rules:
- On the first write operation in a repo, bootstrap or refresh labels with `gh label create --force ...`.
- Apply labels at creation time with `gh issue create --label` or `gh pr create --label`.
- `shiplog/blocker` is stateful. Add it when work becomes blocked and remove it when the blocker is cleared.
- `shiplog/ready`, `shiplog/in-progress`, and `shiplog/needs-review` are mutually exclusive lifecycle labels.

---

## Mandatory Issue Capture

Implementation trouble that materially affects the work must be durably recorded before the agent proceeds to the next material step or ends the turn.

### What counts as a relevant implementation issue

- Failed attempts
- Hidden dependencies
- Risky workarounds
- Scope surprises
- Verification gaps
- Environment or tooling friction

### What does not require capture

- Normal iteration where the final approach is obvious from the diff
- Minor typos or lint fixes resolved in the same commit
- Expected complexity that matches the task description

### Capture rule

| Situation | Artifact | Where |
|-----------|----------|-------|
| Issue is local and resolved inline | Timeline comment (`[shiplog/implementation-issue]`) | Issue |
| Issue warrants follow-up, scope split, or long-term retrieval | New linked issue | GitHub issue with cross-reference on parent |

The timeline comment is the minimum: one paragraph explaining what happened, why it matters, and how it was resolved or deferred.

---

## Edge Cases

- **No issue exists:** Let the user work. At first commit or PR, offer to create a tracking issue.
- **Mid-work activation:** Check branch name for `issue/N-*`. If found, add catch-up timeline comment via `shiplog:timeline`. If not, offer retroactive issue creation.
- **Small tasks (< 30 min):** Lightweight protocol - issue optional, branch still created, PR sections can be brief.
- **Hotfix / emergency:** Fix first. Create issue and PR after, backfilling the timeline.
- **Post-merge cleanup:** Remove a worktree only when its branch is merged, no open PR still depends on it, and it is not the active workspace. See `references/orchestrator-protocol.md`.

---

## Requirements

| Dependency | Purpose | Install |
|-----------|---------|---------|
| `gh` CLI | GitHub issue/PR/comment operations | `brew install gh` / `winget install GitHub.cli` |
| `git` | Branch, commit, diff, log | Pre-installed |
| GitHub remote | Must be in a git repo with GitHub remote | — |

All recommended skills are optional. The current optional integrations are listed below. Without them, shiplog falls back to direct `gh`/`git` commands.

### User-Facing Language

The phase numbers are internal workflow labels. Do not surface them to the user.

Preferred labels: `Plan Capture`, `Branch Setup`, `Discovery Handling`, `Commit Context`, `PR Timeline`, `History Lookup`, `Timeline Updates`.

**Brand formatting:** Always bold the word **shiplog** in user-facing text (messages, comments, PR bodies, issue bodies). Write it lowercase and bold: **shiplog**. This does not apply to code identifiers, branch names, CLI output, or other machine-readable contexts where markdown is not rendered.

### Shell Portability

Keep the workflow cross-platform. See `references/shell-portability.md` for full guidance and Bash/PowerShell patterns.

Key rules:
- Prefer `gh ... --body-file <temp-file>` for multiline content.
- Break chained shell commands into separate steps when the shell operator differs.
- Keep Bash examples as the primary path; add PowerShell notes where syntax diverges.

### Integration Map

This skill ORCHESTRATES. Sub-skills under `commands/shiplog/` each own their phase's policy, runnable queries, and acceptance checklist in a single file — no cross-file navigation required during execution. References in `references/` are deep-dive anchors for cross-cutting policy only.

#### Sub-skill map

| Phase | Sub-skill | Owns |
|-------|-----------|------|
| Plan Capture | `commands/shiplog/plan.md` | Brainstorm-to-issue policy, gh issue create template, envelope requirements |
| Branch Setup | `commands/shiplog/start.md` | Branch naming, label swap, session-start comment template |
| Triage / Hunt | `commands/shiplog/hunt.md` | PR+issue triage, signed-review detection (comment-based), reviewability classification |
| Commit Context | `commands/shiplog/commit.md` | Commit format, Authored-by sig, commit-note template |
| PR Timeline | `commands/shiplog/pr.md` | PR body structure, sig blocks, review gate pointer |
| Review | `commands/shiplog/review.md` | Review sign-off template, cross-model check, PR snapshot update |
| Lookup | `commands/shiplog/lookup.md` | ID-first retrieval queries, multi-surface search |
| Session Resume | `commands/shiplog/resume.md` | Branch detection, session-resume comment template |

#### Cross-cutting reference anchors

| Policy | Reference | What stays there |
|--------|-----------|-----------------|
| Cross-model gate rule | `references/closure-and-review.md` §3 | What constitutes different model; provenance fallback chain; where reviews live |
| Merge conditions | `references/closure-and-review.md` §5 | Gate satisfaction conditions; risk-based requirements |
| Closure evidence | `references/closure-and-review.md` §1–2 | Evidence requirements; closure comment format |
| Envelope schema | `references/artifact-envelopes.md` §1 | Triage field derivation rule; field definitions |
| Signing spec | `SKILL.md §8` | Authored-by / Updated-by / Reviewed-by / Last-code-by rules |

#### External skill delegation

| Activity | Primary | External (optional) | Shiplog Adds |
|----------|---------|---------------------|--------------|
| Committing | `commands/shiplog/commit.md` | `ork:commit`, `commit-commands:commit` | ID-first format, task refs, Authored-by sig |
| Creating PRs | `commands/shiplog/pr.md` | `ork:create-pr` (validation agents) | Timeline body, envelopes, labels, review gate pointer |
| Finishing branches | `commands/shiplog/pr.md` | `superpowers:finishing-a-development-branch` | Review gate enforcement |
| Brainstorming | `references/brainstorm-workflow.md` | `superpowers:brainstorming`, `ork:brainstorming` | Design-to-issue capture with task contracts |
| Planning | `commands/shiplog/plan.md` | `superpowers:writing-plans` | Issue task list, envelope, sig |
| Plan execution | `superpowers:executing-plans` | — | Timeline comments at checkpoints |
| Worktree creation | `superpowers:using-git-worktrees` | — | Branch-issue linking |
| Stacked PRs | `ork:stacked-prs` | — | Discovery-driven stacking protocol |
| Issue tracking | `ork:issue-progress-tracking` | — | Auto-checkbox updates from commits |
| Fixing issues | `ork:fix-issue` | — | Timeline documentation of RCA |
| Storing decisions | `ork:remember` | — | Structured `#ID: decision` entries |
| Model routing | Built-in | — | Phase entry check (Step 0), routing prompts, handoffs |
| Fan-out dispatch | `references/orchestrator-protocol.md` | runtime sub-agent/session tools | Dispatch artifact, per-lane contracts, collection summary |
| Review execution | `commands/shiplog/review.md` + `references/closure-and-review.md` §3 | runtime reviewer/verifier tools | Signed comment, cross-model gate check, PR snapshot update |
| Worktree hygiene | `references/orchestrator-protocol.md` | shell commands or external cleanup helpers | Workspace tracking and post-merge cleanup protocol |

**Graceful degradation:** Co-located sub-skill → references deep-dive → external skill → direct `gh`/`git` commands. Minimum viable installation: `gh` CLI + `git` + this skill.

**Conflict avoidance:** This skill sets the WORKFLOW context. External skills provide IMPLEMENTATION helpers. Shiplog's internalized conventions always take precedence for artifact format, signing, labels, and review gates.

#### Runtime-Aware Orchestration

Shiplog records orchestration honestly instead of assuming one agent backend fits every runtime.

- **Local parallel tool fan-out:** one orchestrator runs multiple independent helper calls in parallel. Good for sidecar reads; not a separate reviewer identity.
- **Bounded sub-agent:** the orchestrator spawns a child lane with a scoped contract and collects a return artifact.
- **External session delegation:** a separate tmux session, terminal agent, or other durable worker runs the lane outside the current orchestrator.
- **Contract-only fallback:** shiplog emits the handoff or review contract when the current runtime cannot execute the lane itself.

Isolation backend is tracked separately from the orchestration primitive. A git worktree, forked workspace, or tmux session may all isolate delegated work, but only the primary feature branch/worktree is shiplog's canonical branch record.

See `references/orchestrator-protocol.md` for the capability mapping, fan-out templates, and cleanup protocol.

#### Optional External Skills

These skills enhance shiplog but are not required. Shiplog's conventions take precedence when both are active.

| Skill | Plugin | What It Adds |
|-------|--------|-------------|
| `ork:commit` | OrchestKit | Pre-commit validation (lint, type-check) |
| `ork:create-pr` | OrchestKit | Parallel validation agents (security, tests, quality) |
| `ork:stacked-prs` | OrchestKit | Stacked PR mechanics and management |
| `ork:issue-progress-tracking` | OrchestKit | Auto-checkbox updates from commits |
| `ork:remember` / `ork:memory` | OrchestKit | Knowledge graph storage and retrieval |
| `ork:brainstorming` | OrchestKit | Parallel agent exploration (steps 1-4) |
| `superpowers:brainstorming` | Superpowers | Visual companion, design dialogue (steps 1-4) |
| `superpowers:using-git-worktrees` | Superpowers | Isolated workspace creation |
| `superpowers:writing-plans` | Superpowers | Structured plan documents |
| `superpowers:executing-plans` | Superpowers | Plan execution with checkpoints |

---

## References

One line per deep-dive file. Open only when the co-located sub-skill or inline section is insufficient.

| File | Open when |
|------|-----------|
| `references/artifact-envelopes.md` | Writing or parsing `<!-- shiplog: ... -->` blocks; need triage field derivation rule or full field schema |
| `references/closure-and-review.md` | Deciding whether a PR is mergeable; need cross-model gate rule, merge conditions, or closure evidence requirements |
| `references/labels.md` | Bootstrapping a new repo or repairing labels; need color codes or full label bootstrap CLI |
| `references/signing.md` | The inline Agent Identity Signing section is insufficient; need edge-case signing rules or full model detection details |
| `references/model-routing.md` | Running `/shiplog models` or checking agent tier assignments |
| `references/brainstorm-workflow.md` | Processing brainstorm output before filing an issue; need capture and design-to-issue conventions |
| `references/orchestrator-protocol.md` | Coordinating multi-lane work; need fan-out dispatch templates, reviewer lane contracts, or worktree cleanup |
| `references/shell-portability.md` | Shell syntax for a command is unclear; need Bash/PowerShell cross-platform patterns |
| `references/commit-workflow.md` | The co-located `commands/shiplog/commit.md` is insufficient for cross-cutting commit policy |
| `references/pr-workflow.md` | The co-located `commands/shiplog/pr.md` is insufficient for cross-cutting PR policy |
| `references/verification-profiles.md` | A task requires a named verification profile |
| `references/phase-templates.md` | A template is not covered by any co-located sub-skill file |
