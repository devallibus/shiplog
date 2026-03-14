# Phase Templates

All issue, PR, and comment templates used by shiplog phases. The main SKILL.md describes the workflow; this file provides the templates.

For shell portability guidance, see `references/shell-portability.md`.

---

## PHASE 1: Issue Template (Full Mode)

```bash
gh issue create \
  --title "[shiplog/plan] Brief title describing the work" \
  --body "$(cat <<'EOF'
## Context

[1-3 sentences: what problem are we solving and why now]

## Design Summary

[Key decisions from the brainstorm — 3-5 bullet points]

## Approach

[The chosen approach with brief rationale]

## Alternatives Considered

- **Alternative A**: [why not chosen]
- **Alternative B**: [why not chosen]

## Tasks

Each task is self-contained. A tier-3 model should be able to execute any task
using only the information in that task block, without reading the rest of this issue.

- [ ] **Task 1: [Short title]** `[tier-3]`
  - **What:** [1-2 sentences, exactly what to do — no ambiguity]
  - **Files:** `path/to/file.ts` (create|modify|delete)
  - **Accept when:** [concrete, testable acceptance criteria]
  - **Context:** [any non-obvious background the implementer needs]

- [ ] **Task 2: [Short title]** `[tier-1]`
  - **What:** [1-2 sentences]
  - **Files:** `path/to/file.ts`
  - **Accept when:** [criteria]
  - **Why tier-1:** [why this needs reasoning, e.g., "requires evaluating 3 API options"]

Tier tag rules:
- `[tier-3]` tasks MUST be executable without creative judgment.
  Every decision is pre-made in the task description.
- `[tier-1]` tasks require reasoning or trade-off evaluation.
  Include **Why tier-1** explaining what judgment is needed.
- `[tier-2]` tasks need context awareness but not deep creativity.
- The golden rule: if a tier-3 model would need to make a judgment call,
  the task is not specific enough. Rewrite it.

## Open Questions

- [Any unresolved questions]

---
*Captain's log entry created by [shiplog](https://github.com/devallibus/shiplog)*
EOF
)"
```

On PowerShell, prefer the `--body-file` temp-file pattern from `references/shell-portability.md` instead of translating the heredoc inline.

---

## PHASE 2: Timeline Entry (Full Mode)

```bash
gh issue comment <ISSUE_NUMBER> --body "$(cat <<'EOF'
## [shiplog/session-start] <Brief description of the work>

**Branch:** `issue/<N>-<description>`
**Approach:** [1-2 sentences about the plan for this session]

---
*Captain's log — session start*
EOF
)"
```

For cross-platform reliability, prefer `gh issue comment --body-file <temp-file>` when the comment body spans multiple lines.

## PHASE 2: Quiet Mode `--log` Branch + PR

If the `--log` PR doesn't exist yet:
```bash
git checkout -b <branch>--log
git commit --allow-empty -m "shiplog: initialize knowledge log"
git push -u origin <branch>--log
gh pr create --base <branch> \
  --title "[shiplog/worklog] <description>" \
  --body "## Knowledge Log\n\nTracking decisions and discoveries for this work."
# If you deferred a brainstorm from PHASE 1, use that saved content as the initial PR body instead of this placeholder.
# Then switch back to the feature branch
git checkout <branch>
```

On PowerShell, use backtick (`` ` ``) for line continuation instead of `\`, or pass the PR body via `--body-file`.

Post a comment on the `--log` PR:
```bash
gh pr comment <LOG_PR_NUMBER> --body "[shiplog/session-start] Work started. Approach: [1-2 sentences]"
```

---

## PHASE 3a: Discovery Issue Template

```bash
gh issue create \
  --title "[shiplog/discovery] Brief description" \
  --body "$(cat <<'EOF'
## Discovered During

Issue #<PARENT> - while working on [context]

## Problem

[What we discovered]

## Why This Blocks Parent

[Why this must be resolved first]

## Proposed Fix

[Approach]

---
*Discovered during #<PARENT>. Stacked dependency.*
EOF
)"
```

Cross-reference on the parent:
```bash
gh issue comment <PARENT_ISSUE> --body "[shiplog/discovery] #<PARENT>: Found sub-problem -> created #<NEW_ISSUE>. This is a stacked prerequisite."
```

---

## PHASE 4: Commit Context Comment

### Bash

```bash
COMMIT_SHA=$(git log -1 --format='%h')
COMMIT_MSG=$(git log -1 --format='%s')

# Full Mode: comment on issue
gh issue comment <ISSUE_NUMBER> --body "$(cat <<EOF
## [shiplog/commit-note] #<ISSUE>: \`$COMMIT_SHA\`

**What:** $COMMIT_MSG

**Why:** [1-2 sentences explaining the reasoning]

**Discovered:** [Anything unexpected, or "Nothing unexpected"]

**Next:** [What comes next]
EOF
)"

# Quiet Mode: comment on --log PR
gh pr comment <LOG_PR_NUMBER> --body "[same content]"
```

### PowerShell

```powershell
$commitSha = git log -1 --format='%h'
$commitMsg = git log -1 --format='%s'
$body = @"
## [shiplog/commit-note] #<ISSUE>: ``$commitSha``

**What:** $commitMsg

**Why:** [1-2 sentences explaining the reasoning]

**Discovered:** [Anything unexpected, or "Nothing unexpected"]

**Next:** [What comes next]
"@
gh issue comment <ISSUE_NUMBER> --body $body
```

---

## PHASE 5: PR Timeline Body (Full Mode)

```bash
ISSUE_NUMBER=<N>
BASE_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')

gh pr create --base $BASE_BRANCH \
  --title "<type>(#$ISSUE_NUMBER): Brief description" \
  --body "$(cat <<'EOF'
## Summary

[2-3 sentences: what this PR does and why]

Closes #<ISSUE_NUMBER>

## Journey Timeline

### Initial Plan
[What we set out to do — reference the issue]

### What We Discovered
- [Discovery 1: what surprised us]
- [Discovery 2: what we learned]

### Key Decisions Made

| Decision | Choice | Why |
|----------|--------|-----|
| [Decision 1] | [Chosen option] | [Reasoning] |
| [Decision 2] | [Chosen option] | [Reasoning] |

### Changes Made

**Commits:**
[list commits with `git log --oneline $BASE_BRANCH..HEAD`]

## Testing

- [x] [What was tested and how]
- [x] All existing tests pass

## Stacked PRs / Related

- [#related-pr or #related-issue if any]

## Knowledge for Future Reference

[Anything a future developer should know when revisiting this area. Patterns established, gotchas found, decisions that might need revisiting.]

---
*Captain's log — PR timeline by [shiplog](https://github.com/devallibus/shiplog)*
EOF
)"
```

The PR body is large enough that `--body-file` should be treated as the preferred portable path on both macOS/Linux and PowerShell.

## PHASE 5: Quiet Mode Final Summary

Add a final summary comment to the `--log` PR:
```bash
gh pr comment <LOG_PR_NUMBER> --body "$(cat <<'EOF'
## [shiplog/review-handoff] Final Summary

**Feature PR:** #<FEATURE_PR_NUMBER>
**Status:** Ready for review

### Journey Recap
[1-paragraph summary of the complete journey]

### Key Decisions
[Numbered list of most important decisions]

### Lessons Learned
[What we'd do differently next time]
EOF
)"
```

---

## PHASE 6: Retrieval Summary Format

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

---

## PHASE 7: Timeline Comment Format

Target: issue (Full Mode) or `--log` PR (Quiet Mode).

```markdown
## [shiplog/<kind>] #<ID>: <brief summary>

**Status:** [In progress / Blocked / Approach changed / Milestone reached]

**Progress since last update:**
- [What was done]

**Current state:**
- [Where things stand]

**Next steps:**
- [What comes next]

[If blocked]: **Blocker:** [Description and what help is needed]

[If approach changed]: **Why:** [What changed and reasoning]
```

Comment types: `session-start`, `session-resume`, `milestone`, `discovery`, `approach-change`, `blocker`, `session-end`
