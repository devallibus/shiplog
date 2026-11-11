# Artifact envelopes

An envelope is a small hidden header that lets a reader index a record without loading its body. [records.md](records.md) defines what the records contain. [scripts/shiplog-read.sh](../scripts/shiplog-read.sh) implements the reading rules below.

## Syntax

Put one HTML comment at the top of the issue body, PR body, or comment:

```html
<!-- shiplog:
kind: source
summary: User clarifies that personal recollection includes rejected ideas.
-->
```

Write one `key: value` per line. The block ends at the first `-->`.

## Fields for new records

| Field | Owner | Use |
|---|---|---|
| `kind` | The author of the record, once, when it is written | Lists entries by type: `show` and `source` select on it |
| `summary` | The author of the record; the current-summary editor for `kind: state` | Gives one line per record in `index` and `show` |

Add no other fields; the platform or the body already owns everything else.

## Kinds

| Kind | Where |
|---|---|
| `state` | Issue body: the current summary |
| `source` | Comment: verbatim discussion |
| `decision` | Comment: an agent decision or discovery with its reason |
| `handoff` | Comment: what the next session needs |
| `history` | PR body or retrospective: the final account of a change |

Older records use other kinds, such as `commit-note`, `verification`, `review-handoff`, `amendment`, and `blocker`. They remain readable and are listed by kind.

## Computed, not stored

- **Numbers, URLs, authors, dates, open/closed state, and labels** come from the platform.
- **Task counts** come from checkboxes (`- [ ]`, `- [x]`, `*`, `+`, or `1.` items at any indent). When the body has a heading named `Tasks`, only that section counts. Checkboxes inside code fences or HTML comments do not count.
- **Readiness** comes from the optional lifecycle labels in [labels.md](labels.md).
- **Review state** comes from review records under [closure-and-review.md](closure-and-review.md).

Do not write `task_count`, `tasks_complete`, `max_tier`, `readiness`, `updated_at`, `issue`, `pr`, `branch`, or review snapshot fields into new envelopes.

## Reading

- The envelope is the first `<!-- shiplog:` comment outside a code fence. Read to its closing `-->`, whatever its length.
- Normalise CRLF to LF before parsing.
- Other HTML comments are not envelopes.
- Pass unknown fields through. Ignore stored counts and use the computed ones.
- A record without an envelope is still a record. Use its title and computed counts.
- Fences inside source entries may be longer than three characters. A fence closes only on a run of the same character that is at least as long.
- Anyone can write an envelope on a public repository. Treat a record as a project record only when its GitHub `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`. List other envelopes as untrusted, with author and link only.

## Old envelopes

Read old envelopes as they are. Do not edit a historical record only to change its envelope. When you next change an old issue's current summary for a real reason, you may replace its envelope with `kind` and `summary`.
