---
name: lookup
description: "Phase 6: Search git history, issues, PRs, and knowledge graph for past decisions and context."
---

# History Lookup (Phase 6)

<!-- routing: tier-2, plan -->
<!-- cross-cutting: references/model-routing.md (Step 0), references/artifact-envelopes.md -->

0. **Routing check.** Run the phase entry check from `references/model-routing.md`.

1. **Search git history.** Issues, PRs, commits via `gh` and `git log --grep`.

2. **Prefer structured envelopes.** When artifacts carry machine-readable envelopes, fetch envelope metadata before reading full threads. See `references/artifact-envelopes.md` for the envelope format, artifact kinds, supersession model, and `gh` query patterns.

3. **Search knowledge graph.** `/ork:memory search "keyword"` if available.

4. **Compile summary** using the format below.

5. **Run a triage scan** when the user asks which issues or PRs are ready next:
   - Fetch open issues with bodies in one call.
   - Parse envelope triage fields (`readiness`, `task_count`, `tasks_complete`, `max_tier`).
   - Cross-reference open PRs to detect "implemented but not merged".
   - Only read full issue bodies for items the user selects.

---

## Retrieval Summary Format

```markdown
## Shiplog Query: "keyword"

### Issues
- #N: [title] - [status]

### PRs
- #N: [title] - [status], key decision: [from PR body]

### Commits
- abc1234: [message]

### Timeline
[Chronological narrative of how this evolved]
```

## Triage Scan Output

```markdown
## Shiplog Triage Scan

| # | Title | Readiness | Tasks | Max Tier | PR | Labels |
|---|-------|-----------|-------|----------|----|--------|
| 42 | Auth middleware | ready | 0/3 | tier-2 | - | `plan` |
| 43 | Fix race condition | in-progress | 1/2 | tier-3 | #55 | `discovery` |
| 44 | Refactor logging | done | 3/3 | - | #56 (open) | `plan`, `needs-review` |

**Legend:** Readiness comes from the issue envelope. Tasks = `tasks_complete`/`task_count`.
```
