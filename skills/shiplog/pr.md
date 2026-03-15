---
name: pr
description: "Phase 5: Create PR with timeline body, handle review gate, and link to tracking issue."
---

# PR Timeline (Phase 5)

<!-- routing: tier-1, plan -->
<!-- cross-cutting: references/model-routing.md (Step 0), references/signing.md, references/closure-and-review.md, references/labels.md -->

0. **Routing check.** Run the phase entry check from `references/model-routing.md`.

1. **Pre-PR checks.** Follow `references/pr-workflow.md`. External PR skills may still be used for validation help, but shiplog's internal PR workflow is authoritative for title, body, labels, and review gate behavior.

2. **Create PR (Full Mode).** Use the PR timeline template below. Create the PR with `shiplog/history` and `shiplog/issue-driven` already applied. Sign per `references/signing.md`.

3. **Quiet Mode.** Create a clean feature PR (no shiplog content). Add a final summary comment to the `--log` PR using the quiet-mode template below. Sign per `references/signing.md`.

4. **Review gate.** Every PR requires cross-model review before merge. See `references/closure-and-review.md` for the review protocol, sign-off format, and merge authorization rules.

5. **Link and store.** PR body includes `Closes #<issue>` when the PR fully resolves the issue. For partial delivery, use `Addresses #<issue> (completes T1, T2, ...)` - see the partial-delivery template below and `references/closure-and-review.md` Section 1. Store key learning in knowledge graph.

6. **Closure verification (optional).** When evidence-to-issue mapping is non-obvious, optionally delegate a bounded verifier agent per `references/closure-and-review.md`.

---

## PR Timeline Body (Full Mode)

```bash
ISSUE_NUMBER=<N>
BASE_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')

gh pr create --base $BASE_BRANCH \
  --label "shiplog/history" \
  --label "shiplog/issue-driven" \
  --title "<type>(#$ISSUE_NUMBER): Brief description" \
  --body-file <temp-file>
```

PR body:

```markdown
<!-- shiplog:
kind: history
issue: <ISSUE_NUMBER>
branch: issue/<ISSUE_NUMBER>-<slug>
status: resolved
updated_at: <ISO_TIMESTAMP>
review_status: awaiting-review
-->

## Summary

[2-3 sentences: what this PR does and why]

Closes #<ISSUE_NUMBER>

## Review Status

- **Current state:** awaiting review
- **Last reviewed by:** none yet
- **Last reviewed at:** n/a
- **Reviewed commit:** n/a
- **Source artifact:** none yet
- **Needs re-review since:** no

## Journey Timeline

### Initial Plan
[What we set out to do - reference the issue]

### What We Discovered
- [Discovery 1: what surprised us]
- [Discovery 2: what we learned]

### Implementation Issues
- [Issue 1: what happened, how it was resolved - or "None"]

### Key Decisions Made

| Decision | Choice | Why |
|----------|--------|-----|
| [Decision 1] | [Chosen option] | [Reasoning] |

### Changes Made

**Commits:**
[list commits with `git log --oneline $BASE_BRANCH..HEAD`]

## Testing

[If verification profile active]:
**Verification profile:** [profile names]

- [x] [What was tested and how]
- [x] All existing tests pass
- [x] Self-audit: implementation reviewed for redundancy, dead code, and simplification opportunities

**Verification summary:** [scenarios added/changed, tests added/changed, deferred items]

## Stacked PRs / Related

- [#related-pr or #related-issue if any]

## Knowledge for Future Reference

[Anything a future developer should know when revisiting this area.]

---
Authored-by: <family>/<version> (<tool>)
Last-code-by: <family>/<version> (<tool>)
*Captain's log - PR timeline by [shiplog](https://github.com/devallibus/shiplog)*
```

The PR body is large enough that `--body-file` should be the preferred portable path.
After every signed review comment and every post-review code push, refresh this review snapshot in place per `references/closure-and-review.md` and `references/signing.md`.

---

## Quiet Mode: Final Summary Comment

Add to the `--log` PR:

```markdown
<!-- shiplog:
kind: review-handoff
issue: <ISSUE_NUMBER>
pr: <FEATURE_PR_NUMBER>
phase: 5
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/review-handoff] Final Summary

**Feature PR:** #<FEATURE_PR_NUMBER>
**Status:** Ready for review

### Journey Recap
[1-paragraph summary of the complete journey]

### Key Decisions
[Numbered list of most important decisions]

### Lessons Learned
[What we'd do differently next time]

Authored-by: <family>/<version> (<tool>)
```

---

## Partial-Delivery PR Variant

When a PR ships some tasks but the issue has remaining work:

```markdown
<!-- shiplog:
kind: history
issue: <ISSUE_NUMBER>
branch: issue/<ISSUE_NUMBER>-<slug>
status: in-progress
updated_at: <ISO_TIMESTAMP>
review_status: awaiting-review
-->

## Summary

[2-3 sentences: what this PR ships and why it is a partial delivery]

Addresses #<ISSUE_NUMBER> (completes T1, T2, T3)

## Review Status

- **Current state:** awaiting review
- **Last reviewed by:** none yet
- **Last reviewed at:** n/a
- **Reviewed commit:** n/a
- **Source artifact:** none yet
- **Needs re-review since:** no

## Completed Tasks

- [x] **T1:** [title] - [1-sentence summary of what shipped]
- [x] **T2:** [title] - [1-sentence summary]

## Remaining Tasks

- [ ] **T4:** [title] - [why deferred: blocked on X / next phase / needs design]
- [ ] **T5:** [title] - [why deferred]

## Blocked On

- [External dependency with link, or "No external blockers - remaining tasks deferred by choice"]

## Journey Timeline

[Same structure as the standard PR template]

## Knowledge for Future Reference

[Same structure as the standard PR template]

---
Authored-by: <family>/<version> (<tool>)
Last-code-by: <family>/<version> (<tool>)
*Captain's log - partial delivery by [shiplog](https://github.com/devallibus/shiplog)*
```
