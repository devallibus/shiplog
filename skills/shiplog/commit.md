---
name: commit
description: "Phase 4: Commit with conventional format and post context comments for significant changes."
---

# Commit Context (Phase 4)

<!-- routing: tier-3, agent -->
<!-- cross-cutting: references/model-routing.md (Step 0), references/signing.md, references/verification-profiles.md -->

0. **Routing check.** Run the phase entry check from `references/model-routing.md`.

1. **Create the commit.** Follow `references/commit-workflow.md`. External commit skills may still be used for convenience, but the conventions in the internal workflow take precedence. Format: `<type>(#<issue-id>): <description>`. When a commit addresses a specific task, include the task ID: `<type>(#<issue-id>/<Tn>): <description>`.

2. **Add context comment** for significant commits. Document the reasoning and verification on the issue (Full Mode) or `--log` PR (Quiet Mode). Sign per `references/signing.md`.

**When to add context comments:** After significant functionality, unexpected discoveries, approach changes, or tricky bug fixes. Not after trivial commits.

**Verification profiles:** When a verification profile is active, include verification evidence in commit context. See `references/verification-profiles.md`.

---

## Commit Context Comment

### Bash

```bash
COMMIT_SHA=$(git log -1 --format='%h')
COMMIT_MSG=$(git log -1 --format='%s')

gh issue comment <ISSUE_NUMBER> --body-file <temp-file>
gh pr comment <LOG_PR_NUMBER> --body-file <temp-file>
```

Comment body:

```markdown
<!-- shiplog:
kind: commit-note
issue: <ISSUE>
phase: 4
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/commit-note] #<ISSUE>: `<COMMIT_SHA>`

**What:** <COMMIT_MSG>

**Why:** [1-2 sentences explaining the reasoning]
**Verification:** [What was checked, what was deferred, or "Not run"]
[If verification profile active]:
- **Profile:** [active profile names]
- **Scenarios:** [added N, changed M, existing passed K]
- **Tests:** [added N, changed M, all passing]
- **Deferred:** [anything intentionally skipped, with reason]
[If self-audit profile active]:
- **Self-audit:** clean | N findings fixed | not applicable (reason)

**Discovered:** [Anything unexpected, or "Nothing unexpected"]

**Next:** [What comes next]

Authored-by: <family>/<version> (<tool>)
```