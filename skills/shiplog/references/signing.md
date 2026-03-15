# Agent Identity Signing

Every shiplog artifact (comments, PR bodies, review sign-offs) must carry a provenance signature in the canonical format.

---

## Canonical Grammar

```
<role>: <family>/<version> (<tool>[, <qualifier>])
```

| Field | Values | Examples |
|-------|--------|---------|
| `role` | `Authored-by`, `Updated-by`, or `Reviewed-by` | — |
| `family` | Provider name, lowercase | `claude`, `openai`, `google` |
| `version` | Model identifier | `opus-4.6`, `sonnet-4`, `gpt-5.4` |
| `tool` | Runtime environment, lowercase | `claude-code`, `codex`, `cursor` |
| `qualifier` | Optional tool-specific metadata | `effort: high`, `effort: medium` |

**Searching:** `Authored-by:` → original authorship. `Updated-by:` → later material editors. `Reviewed-by:` → review artifacts. `claude/` → all Claude artifacts. `(codex` → all Codex artifacts.

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
- A **material edit** changes meaning, facts, scope, requirements, acceptance criteria, verification results, review disposition, or a handoff contract. Typos, formatting cleanups, and link-only fixes are cosmetic and do not need `Updated-by:`.

---

## Edit-in-Place vs Amendment

- **Edit in place** when the artifact is meant to stay the single canonical current body: issue bodies, PR bodies, and latest-wins status/history artifacts. Refresh envelope `updated_at` and add `updated_by` plus `edit_kind` fields when an envelope exists.
- **Post an amendment artifact** when the original text matters for auditability: handoffs, verification comments, commit-note comments, review sign-offs, and other major signed timeline entries. Use a new signed artifact that references the prior artifact and add envelope `amends` or `supersedes` markers.

Use `supersedes` when the new artifact replaces the old one as canonical. Use `amends` when the new artifact corrects or clarifies but both should remain visible.

If the platform does not expose reliable edit history, prefer an amendment artifact.

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
