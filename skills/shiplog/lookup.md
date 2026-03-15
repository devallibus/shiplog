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

---

## Retrieval Summary Format

```markdown
## Shiplog Query: "keyword"

### Issues
- #N: [title] — [status]

### PRs
- #N: [title] — [status], key decision: [from PR body]

### Commits
- abc1234: [message]

### Timeline
[Chronological narrative of how this evolved]
```
