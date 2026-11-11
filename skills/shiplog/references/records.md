# Source records and current summaries

This file defines what to write. [artifact-envelopes.md](artifact-envelopes.md) defines the small retrieval header.

## Capture source text

Use the existing tracking issue. If there is none, create one discussion issue when saving an idea is within the user's requested scope. Do not create an issue for every message. Keep records in the user's chosen project log; do not silently change publication scope.

At a checkpoint, collect uncaptured project messages in order. Preserve human text verbatim, including spelling, spacing, line breaks, questions, and later corrections. Preserve assistant replies needed to understand that text. Clearly separate any added context or summary. Do not record hidden instructions or manufacture unavailable messages.

Use message IDs and the conversation URL when available. Otherwise describe the visible range and compare it with the last captured source entry. Identical text can be two separate messages: do not deduplicate by text alone. Record known coverage gaps. The platform posting date is the capture date, not necessarily the original message date.

Write each message in a fenced text block. Choose a fence longer than any run of that fence character in the source. Do not reflow text or escape its contents. Example:

````markdown
<!-- shiplog:
kind: source
summary: User clarifies that personal recollection includes rejected ideas.
-->

Source: conversation URL and message range, or a description of the available range.
Recorded by: assistant in the current coding session.
Coverage: available messages only; name any known gap.

### Message 1
Speaker: user
Original message ID/time: include only when available

```text
Copy the original message here without changes.
```

### Message 2
Speaker: assistant

```text
Copy the relevant original reply here without changes.
```
````

Save the body to a UTF-8 file ([shell-portability.md](shell-portability.md) covers PowerShell) and post with `gh issue comment N --body-file FILE`. Keep the returned URL. After an uncertain response, inspect the latest entries for that source range before retrying. Do not post the same range twice.

## Corrections and decisions

Append a new source entry when the user corrects an earlier statement. Include `Corrects: URL` outside the quoted text. Keep both versions. Update the current summary to link to the new statement and explain the change when needed. An unresolved conflict stays unresolved.

For an agent decision or discovery, write a short explanation of what changed, why, and the evidence or next step. Use `kind: decision` or `kind: handoff` as appropriate. Routine tool attempts do not need separate comments. An important failed approach should explain what would prevent someone from repeating it.

Source entries are append-only during normal work. Explicit user requests to edit or remove their records take precedence. Do not silently correct, shorten, or replace a quote.

## Current summary

Keep this in the issue body. Omit empty sections; retain a task list when useful.

```markdown
<!-- shiplog:
kind: state
summary: One sentence describing the current work.
-->

## Goal
The intended outcome and key constraints.

## Current decisions
- The decision, whether it is accepted or proposed, and its source link.

## Tasks
- [ ] T1: A concrete task and its completion check.

## Checks and limits
What was checked, the result, and any remaining uncertainty.

## Next action
The next concrete step, or the blocker and what would clear it.

## Source
Links to relevant source entries and the last captured message range.
```

Read the current body immediately before editing it. Change only the current summary and relevant tasks. Preserve human-written sections, original source blocks, unrelated notes, and historical signatures. If there is a concurrent change, reconcile it before writing. Record speaker/source attribution on copied discussion; routine notes need no model signature. See [signing.md](signing.md) if a project requires one.

Task checkboxes are the source for task completion. Do not maintain task-count copies. Optional lifecycle labels own readiness under [labels.md](labels.md). A historical envelope is a fallback for reading old state, not a reason to rewrite the issue.
