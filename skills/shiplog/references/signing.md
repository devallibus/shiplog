# Agent Identity Signing

Every shiplog artifact (comments, PR bodies, review sign-offs) must carry a provenance signature in the canonical format.

---

## Canonical Grammar

```
<role>: <family>/<version> (<tool>[, <qualifier>])
```

| Field | Values | Examples |
|-------|--------|---------|
| `role` | `Authored-by`, `Updated-by`, `Reviewed-by`, or `Last-code-by` | — |
| `family` | Provider name, lowercase | `claude`, `openai`, `google` |
| `version` | Model identifier | `opus-4.6`, `sonnet-4`, `gpt-5.4` |
| `tool` | Runtime environment, lowercase | `claude-code`, `codex`, `cursor` |
| `qualifier` | Optional tool-specific metadata | `effort: high`, `effort: medium` |

**Searching:** `Authored-by:` → original authorship. `Updated-by:` → later material editors. `Reviewed-by:` → review artifacts. `Last-code-by:` → most recent code author on a PR branch. `claude/` → all Claude artifacts. `(codex` → all Codex artifacts.

---

## Model Detection Per Tool

| Tool | Source | Example signature |
|------|--------|-------------------|
| Claude Code | System prompt model name | `claude/opus-4.6 (claude-code)` |
| Codex | `~/.codex/config.toml` `model` + `model_reasoning_effort` | `openai/gpt-5.4 (codex, effort: high)` |
| Cursor | System prompt model identifier | `claude/opus-4.6 (cursor)` |
| Other | Best available model identifier | `<family>/<version> (<tool>)` |

---

## Correction Rule

If a shiplog artifact carries an incorrect or incomplete signature, correct it in place when the platform allows editing. Otherwise post an immediate follow-up correction.

---

## Edit Provenance Rules

- `Authored-by:` records the original author of an artifact body.
- `Updated-by:` records a later model or human who materially edits that same artifact body. Preserve the original `Authored-by:` line and append a new `Updated-by:` line for each material edit, newest last.
- `Reviewed-by:` is review-only. Do not use it for authorship or edit attribution.
- Updating a PR body's review snapshot after publishing a signed review comment or after pushing code that makes a prior review stale counts as a material edit.
- A **material edit** changes meaning, facts, scope, requirements, acceptance criteria, verification results, review disposition, or a handoff contract. Typos, formatting cleanups, and link-only fixes are cosmetic and do not need `Updated-by:`.

---

## Code Provenance

`Last-code-by:` tracks which model most recently pushed code to a PR branch. It is distinct from artifact provenance fields:

| Field | Tracks | Updated when |
|-------|--------|-------------|
| `Authored-by:` | Original artifact text author | Artifact is created |
| `Updated-by:` | Later artifact text editor | Artifact body is materially edited |
| `Reviewed-by:` | Review author | Review sign-off is posted |
| `Last-code-by:` | Most recent code author | Code is pushed to the PR branch |

### When to set `Last-code-by:`

- **On PR creation:** Set in the PR body sign-off block. The model creating the PR is the initial code author.
- **After pushing code:** When a model pushes commits to an existing PR branch, update the PR body's `Last-code-by:` field via `gh pr edit`. This is an in-place edit; append an `Updated-by:` footer per the edit provenance rules.
- **After review-driven code changes:** When a reviewer pushes fixes to the branch (not just commenting), they become the `Last-code-by:` author.

### When NOT to update `Last-code-by:`

- Reviewing without pushing code (use `Reviewed-by:` instead)
- Editing the PR body text without pushing commits (use `Updated-by:` instead)
- Rebasing or force-pushing without new code changes (the code author has not changed)

### Why this field exists

The multi-model review gate (closure-and-review.md §3) must know who last changed the code to determine whether a reviewing agent's review is cross-model (gate-satisfying) or same-model (non-gate-satisfying). `Authored-by:` tracks artifact text, not code. Without `Last-code-by:`, consumers must fall back to git commit forensics, which is slower and contradicts shiplog's principle that provenance lives in signed artifacts.

### Fallback chain for review gating

When determining code authorship for review-gate decisions, use this priority:

1. `Last-code-by:` in the PR body (authoritative)
2. `Updated-by:` in the PR body (approximate — may reflect text edits, not code)
3. `Authored-by:` in the PR body (original author — may be stale)
4. Git commit author on the PR branch (last resort — requires API call)

---

## Edit-in-Place vs Amendment

- **Edit in place** when the artifact is meant to stay the single canonical current body: issue bodies, PR bodies, and latest-wins status/history artifacts. Refresh envelope `updated_at` and add `updated_by` plus `edit_kind` fields when an envelope exists.
- **Post an amendment artifact** when the original text matters for auditability: handoffs, verification comments, commit-note comments, review sign-offs, and other major signed timeline entries. Use a new signed artifact that references the prior artifact and add envelope `amends` or `supersedes` markers.

Use `supersedes` when the new artifact replaces the old one as canonical. Use `amends` when the new artifact corrects or clarifies but both should remain visible.

If the platform does not expose reliable edit history, prefer an amendment artifact.

### PR body review snapshot maintenance

When a PR body carries the current review snapshot:

- Post the signed `Reviewed-by:` comment first. That comment is the review evidence.
- Then refresh the PR body snapshot in place so retrieval flows can read current review state without replaying the comment thread.
- If new code lands after the latest signed review, update the snapshot to `needs-rereview` and record the commit that made the prior review stale.
- Use the standard `Updated-by:` footer and envelope `updated_by` / `edit_kind` fields for these edits. Do not create a separate provenance role for review snapshots.

### In-Place Edit Footer

Preserve the original `Authored-by:` line and append:

```markdown
Updated-by: <family>/<version> (<tool>)
Edit-kind: correction | amendment | rewrite
Edit-note: [1 sentence describing what changed and why]
```

If the artifact carries an envelope, refresh the metadata too:

```html
<!-- shiplog:
updated_at: <ISO_TIMESTAMP>
updated_by: <family>/<version> (<tool>)
edit_kind: correction | amendment | rewrite
-->
```

### Amendment Artifact

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

---

Model identity detection is also used by model-tier routing to verify the current model matches the recommended tier. See `references/model-routing.md`.
