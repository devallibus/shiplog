---
name: discovery
description: "Phase 3: Handle mid-work discoveries — fix inline, stack a prerequisite, or create a new issue."
---

# Discovery Handling (Phase 3)

<!-- routing: tier-2, plan then agent -->
<!-- cross-cutting: references/model-routing.md (Step 0), references/signing.md, references/labels.md -->

0. **Routing check.** Run the phase entry check from `references/model-routing.md`.

1. **Classify the discovery:**

```
Discovery made during work
  +-- Small fix (< 30 min, < 100 lines)?  -> Fix inline, add timeline comment
  +-- Prerequisite for current work?       -> Stack a new branch/PR (3a)
  +-- Independent but important?           -> Create new issue, continue (3b)
  +-- Refactoring opportunity?             -> Create issue tagged "refactor"
```

**3a (stack a prerequisite):** Commit current progress. Create a new issue first (so the ID exists), then create the stacked branch. Label the new issue `shiplog/discovery` and `shiplog/stacked`. Cross-reference on the parent issue and add `shiplog/blocker` to the parent while it is blocked. Sign both artifacts per `references/signing.md`.

**3b (independent discovery):** Create new issue (same template without "blocks parent") and label it `shiplog/discovery`. Add timeline comment. Continue current work. Sign per `references/signing.md`.

---

## Discovery Issue Template

```bash
gh issue create \
  --label "shiplog/discovery" \
  --label "shiplog/stacked" \
  --title "[shiplog/discovery] Brief description" \
  --body-file <temp-file>
```

Issue body:

```markdown
<!-- shiplog:
kind: state
status: open
phase: 3
updated_at: <ISO_TIMESTAMP>
-->

## Discovered During

Issue #<PARENT> - while working on [context]

## Problem

[What we discovered]

## Why This Blocks Parent

[Why this must be resolved first]

## Proposed Fix

[Approach]

---
Authored-by: <family>/<version> (<tool>)
*Discovered during #<PARENT>. Stacked dependency.*
```

## Parent Cross-Reference Comment

```bash
gh issue comment <PARENT_ISSUE> --body "<!-- shiplog:
kind: blocker
issue: <PARENT>
status: blocked
updated_at: <ISO_TIMESTAMP>
-->

[shiplog/discovery] #<PARENT>: Found sub-problem -> created #<NEW_ISSUE>. This is a stacked prerequisite."
```

Then mark the parent as blocked:
```bash
gh issue edit <PARENT_ISSUE> --add-label "shiplog/blocker"
```
