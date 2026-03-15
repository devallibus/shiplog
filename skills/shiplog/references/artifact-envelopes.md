# Artifact Envelopes

Machine-readable metadata for low-token retrieval of shiplog artifacts. Human-facing prose stays readable; hidden envelopes let agents filter before reading deeply.

---

## Design Principles

- **Human layer unchanged.** Semantic tags (`[shiplog/plan]`, `[shiplog/discovery]`) and prose remain the primary interface for people scanning the repo.
- **Machine layer is hidden.** Envelopes live in HTML comments so they never clutter rendered markdown.
- **Selective retrieval.** Agents fetch envelope metadata first, then read the full body only when needed — reducing token cost on long threads.
- **Complementary to naming conventions.** The ID-first naming convention (see SKILL.md) handles discovery; envelopes handle selective retrieval once the artifact is found.

---

## 1. Envelope Format and Field Schema

### Container

Envelopes use HTML comments with a `shiplog:` prefix for unambiguous parsing:

```html
<!-- shiplog:
kind: state
issue: 42
branch: issue/42-auth-middleware
status: in-progress
phase: 2
updated_at: 2026-03-14T12:00:00Z
-->
```

Place the envelope at the **top** of the artifact body (issue body, PR body, or comment), before any visible content.

### Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `kind` | yes | string | Artifact kind from the canonical vocabulary (see §2) |
| `issue` | yes* | integer | Linked issue number. *Required unless the artifact is issue-independent. |
| `pr` | no | integer | Linked PR number, when the artifact lives on or references a PR |
| `branch` | no | string | Associated branch name |
| `status` | no | string | Current status: `open`, `in-progress`, `blocked`, `resolved`, `closed` |
| `phase` | no | integer | Shiplog phase number (1-7) when the artifact was created |
| `profile` | no | string | Active verification profile name, if any |
| `updated_at` | yes | ISO 8601 | When the envelope was last written or refreshed |
| `updated_by` | no | string | Latest material editor of this artifact when it was edited in place |
| `edit_kind` | no | string | Edit classification: `correction`, `amendment`, `rewrite`, or `cosmetic` |
| `amends` | no | string | Reference to the earlier artifact this one corrects or clarifies without replacing |
| `supersedes` | no | string | Reference to the artifact this one replaces (see §3) |
| `superseded_by` | no | string | Back-pointer added to the older artifact when superseded |
| `readiness` | no | string | Triage signal: `ready`, `blocked`, `needs-design`, `in-progress`, or `done` |
| `task_count` | no | integer | Total number of tasks in the issue body |
| `tasks_complete` | no | integer | Number of checked tasks |
| `max_tier` | no | string | Highest tier among remaining tasks: `tier-1`, `tier-2`, or `tier-3` |

### Triage fields

Use triage fields on issue-body `state` envelopes so agents can rank work without reading the whole issue body.

| Value | Meaning |
|-------|---------|
| `ready` | Tasks are scoped and implementation can begin |
| `blocked` | A blocker prevents progress |
| `needs-design` | Open tier-1 decisions remain |
| `in-progress` | Work has started |
| `done` | All tasks are complete |

### Normalization rules

- **Issue/PR numbers:** bare integers, no `#` prefix — e.g., `issue: 42` not `issue: #42`.
- **Branch names:** full branch name — e.g., `branch: issue/42-auth-middleware`.
- **Timestamps:** ISO 8601 with timezone — e.g., `2026-03-14T12:00:00Z`.
- **`updated_by`:** normalized like the signature body without the role prefix — e.g., `openai/gpt-5.4 (codex, effort: high)`.
- **`edit_kind`:** use `correction` for factual or signature fixes, `amendment` for clarifications that preserve the original event, `rewrite` for substantial in-place rewrites, and `cosmetic` only when recording a non-semantic cleanup intentionally.
- **Amendment/supersession references:** use the same `<artifact-location>#<kind>` format for `amends`, `supersedes`, and `superseded_by`.
- **Supersession references:** `<artifact-location>#<kind>` - e.g., `issue/42#state` or `pr/55#verification`. See Section 3 for resolution.
- **Triage integers:** use bare integers, not quoted strings.
- **`readiness`:** use only `ready`, `blocked`, `needs-design`, `in-progress`, or `done`.
- **`max_tier`:** use `tier-1`, `tier-2`, or `tier-3`; omit it when all tasks are complete.
- **Line endings:** normalize `\r\n` to `\n` before parsing envelopes on Windows.
- **Unknown fields:** agents MUST ignore fields they do not recognize. This preserves forward compatibility as the schema evolves.

### Minimal envelope

For lightweight artifacts (simple timeline comments), only `kind` and `updated_at` are required:

```html
<!-- shiplog:
kind: commit-note
updated_at: 2026-03-14T14:30:00Z
-->
```

---

## 2. Canonical Artifact Kinds

### Kind taxonomy

| Kind | Description | Uniqueness | Appears on |
|------|-------------|------------|------------|
| `state` | Current status snapshot of the issue or PR | latest-wins | issues, PRs |
| `handoff` | Context transfer between tiers or tools | accumulating | issues, PRs |
| `verification` | Evidence of testing, review, or quality check | accumulating | issues, PRs |
| `commit-note` | Reasoning behind a specific commit | accumulating | issues |
| `review-handoff` | Review request or review completion artifact | accumulating | PRs |
| `amendment` | Correction or clarification for an existing signed artifact | accumulating | issues, PRs |
| `blocker` | Something preventing progress | latest-wins | issues |
| `history` | Retrospective summary for knowledge retrieval | latest-wins | issues, PRs |

### Uniqueness rules

- **latest-wins:** Only the most recent artifact of this kind is current. Older instances are historical. Agents should prefer the newest.
- **accumulating:** Multiple artifacts of this kind coexist. Each captures a distinct event. Agents may need to read several.

### Per-kind guidance

**`state`** — Write or refresh when the issue/PR status materially changes (e.g., blocked → in-progress, approach changed). Include `status` field. Previous `state` envelopes become historical.

**`handoff`** — Write at tier transitions or tool switches. Include `phase` field. Each handoff is a distinct event in the timeline.

**`verification`** — Write after running tests, completing a review, or producing evidence. Include `profile` field when a verification profile is active.

**`commit-note`** — Write for significant commits. The human-facing `[shiplog/commit-note]` heading carries the reasoning; the envelope adds machine-parseable metadata.

**`review-handoff`** — Write when requesting or completing a PR review. Distinct from `handoff` (tier/tool switch) — this is specifically about code review.

**`amendment`** — Write when a later model materially corrects, clarifies, or annotates an existing signed artifact without silently erasing the prior text. Include `amends` for additive corrections; include `supersedes` if the amendment becomes the new canonical replacement.

**`blocker`** — Write when something blocks progress. Supersedes the previous blocker if the blocking condition changes. Include `status: blocked`.

**`history`** — Write when summarizing a completed journey (e.g., PR body timeline, session-end recap). Useful for future retrieval queries.

### Relationship to semantic tags

Envelope `kind` is the machine key. The `[shiplog/<tag>]` heading is the human key. They serve different audiences:

| Envelope kind | Human-facing tags that may carry this kind |
|---------------|-------------------------------------------|
| `state` | `session-start`, `session-resume`, `milestone` |
| `handoff` | `session-start`, `review-handoff` |
| `verification` | `commit-note`, `review-handoff` |
| `commit-note` | `commit-note` |
| `review-handoff` | `review-handoff` |
| `amendment` | `amendment` |
| `blocker` | `blocker` |
| `history` | `history`, `worklog` |

One comment may carry a human tag and a different envelope kind when the machine purpose differs from the human-facing label. The envelope is authoritative for retrieval; the tag is authoritative for human scanning.

---

## 3. Supersession Model

### Current-state retrieval

For **latest-wins** kinds (`state`, `blocker`, `history`), the most recent artifact of that kind on an issue or PR is the current one. Agents should:

1. Fetch all envelopes of the target kind.
2. Sort by `updated_at` descending.
3. Use the first result as current.

### Explicit supersession markers

When a newer artifact intentionally replaces an older one, the author SHOULD add:

- `supersedes: issue/42#state` on the new artifact.
- `superseded_by: issue/42#state@2026-03-14T15:00:00Z` on the old artifact (best-effort — editing old comments may not always be practical).

The `@timestamp` suffix disambiguates when multiple artifacts of the same kind exist.

### Amendments versus supersession

- Use `amends` when the new artifact corrects or clarifies an earlier one but the original event should still be read as part of the timeline.
- Use `supersedes` when the new artifact should be treated as the current canonical replacement for the old one.
- For in-place edits to an existing artifact, keep the same artifact location, refresh `updated_at`, and record `updated_by` plus `edit_kind` on that artifact instead of inventing a self-reference.

### When markers are absent

If no explicit `supersedes` marker exists, agents fall back to timestamp ordering. This is the expected common case — explicit markers are for clarity, not enforcement.

### Conflict resolution

If two artifacts of a latest-wins kind have the same `updated_at`:

1. Prefer the one with an explicit `supersedes` marker.
2. If neither has a marker, prefer the one posted later (by comment creation order).
3. If still ambiguous, read both and use the one with more complete information.

### Historical artifacts

Superseded artifacts are historical, not deleted. They remain in the thread for timeline reconstruction. Agents performing history queries (Phase 6) should include superseded artifacts; agents performing current-state queries should skip them.

---

## 4. Retrieval Guidance

### Agent query strategy

When loading context for an issue or PR, agents should follow this priority:

```
1. Discover — find the issue/PR by naming convention or search
   gh issue list --search "#42"
   gh pr list --search "#42"

2. Envelope scan — fetch shiplog-typed artifacts first
   Look for <!-- shiplog: ... --> blocks in:
   - Issue/PR body (always check first — state envelopes often live here)
   - Comments (scan for envelope prefix)

3. Prefer structured — for current state, use latest-wins envelopes
   - Latest `state` envelope → current status
   - Latest `blocker` envelope → current blockers
   - Latest `history` envelope → journey summary

4. Fall back — read unstructured prose only when envelopes are insufficient
   - Discussion comments without envelopes
   - Older timeline entries for historical context
```

### `gh` query patterns

**Find all shiplog artifacts on an issue:**
```bash
gh issue view 42 --json body,comments --jq '
  [.body, .comments[].body]
  | map(select(test("<!-- shiplog:")))
'
```

**Find all state envelopes (apply §3 resolution to select current):**
```bash
gh issue view 42 --json body,comments --jq '
  [.body, .comments[].body]
  | map(select(test("kind: state")))
'
```
> The result is a candidate set, not a final answer. Agents must apply the
> supersession rules from §3: sort by `updated_at` descending, prefer entries
> with explicit `supersedes` markers, and use the first result as current.
> Do not assume comment order equals logical currency.

**Find all verification artifacts on a PR:**
```bash
gh pr view 55 --json body,comments --jq '
  [.body, .comments[].body]
  | map(select(test("kind: verification")))
'
```

### Integration with Phase 6

Phase 6 (Knowledge Retrieval) should prefer envelope-based retrieval when available:

1. Search for the issue/PR using existing naming conventions.
2. Check for envelopes before reading full comment threads.
3. Use `state` and `history` envelopes to build the summary.
4. Fall back to full-thread reading only when structured artifacts are insufficient.

This reduces token cost on issues with long discussion threads.

### Integration with delegation and verification

- **Delegated agents** should check for the latest `handoff` envelope on their assigned issue to load their task contract.
- **Verifier agents** should check for `verification` envelopes to find prior evidence before producing their own.
- **Recovery flows** should check for `blocker` and `state` envelopes to understand where work was interrupted.

---

## Examples

### Issue body with envelope

```markdown
<!-- shiplog:
kind: state
issue: 42
branch: issue/42-auth-middleware
status: in-progress
phase: 2
updated_at: 2026-03-14T12:00:00Z
-->

## [shiplog/plan] Add JWT-based auth middleware

[Human-readable issue body follows...]
```

### Comment with envelope

```markdown
<!-- shiplog:
kind: handoff
issue: 42
phase: 4
updated_at: 2026-03-14T14:00:00Z
-->

## [shiplog/session-start] #42: Implementation handoff

**Tier transition:** tier-1 → tier-3
[Human-readable handoff content follows...]
```

### PR body with envelope

```markdown
<!-- shiplog:
kind: history
issue: 42
pr: 55
branch: issue/42-auth-middleware
status: resolved
updated_at: 2026-03-14T18:00:00Z
-->

## Summary

This PR adds JWT-based auth middleware.

Closes #42
[Rest of PR timeline template...]
```
