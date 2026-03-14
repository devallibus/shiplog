# Phase Templates

All issue, PR, and comment templates used by shiplog phases. The main SKILL.md describes the workflow; this file provides the templates.

For shell portability guidance, see `references/shell-portability.md`.

---

## PHASE 1: Issue Template (Full Mode)

```bash
gh issue create \
  --title "[shiplog/plan] Brief title describing the work" \
  --body "$(cat <<'EOF'
<!-- shiplog:
kind: state
status: open
phase: 1
updated_at: <ISO_TIMESTAMP>
-->

## Context

[1-3 sentences: what problem are we solving and why now]

## Design Summary

[Key decisions from the brainstorm — 3-5 bullet points]

## Approach

[The chosen approach with brief rationale]

## Alternatives Considered

- **Alternative A**: [why not chosen]
- **Alternative B**: [why not chosen]

## Sources and Verification Status

Use this section when the issue includes external factual claims. If the issue is only
about this repository's own code or docs, cite repo paths inline where useful and omit
this section if it adds no value.

- `[verified]` Claim: [external factual statement that affects the issue]
  - **Source:** [primary source URL or official repository link]
  - **Checked:** [what the source confirms]
- `[unverified]` Claim or hypothesis: [idea worth preserving, but not yet confirmed]
  - **Why unverified:** [missing source, conflicting reports, or pending experiment]
  - **Next step:** [what must be checked before this can become a requirement]

## Tasks

Each task is self-contained. A tier-3 model should be able to execute any task
using only the information in that task block, without reading the rest of this issue.
When exact behavior matters, write a contract instead of relying on emphasis or tone.
These fields also serve as the default delegation contract when a stronger model
hands a `[tier-3]` task to a cheaper agent.
Do not encode an `[unverified]` external claim as a fixed requirement unless the task
includes the verification work needed to resolve it.

- [ ] **Task 1: [Short title]** `[tier-3]`
  - **What:** [1-2 sentences, exactly what to do - no ambiguity]
  - **Files:** `path/to/file.ts` (create|modify|delete)
  - **Allowed to change:** [`path/to/file.ts`; specific symbols or sections if needed]
  - **Must not change:** [files, APIs, behavior, or decisions that are out of scope]
  - **Forbidden judgment calls:** [choices the implementer must not make locally]
  - **Stop and ask if:** [condition that would require widening scope or making a product/architecture choice]
  - **Verification:** [command, check, or evidence required before claiming completion]
  - **Return artifact:** [diff, comment, checklist update, verification note, or exact file list]
  - **Decision budget:** `none`
  - **Accept when:** [concrete, testable acceptance criteria]
  - **Context:** [any non-obvious background the implementer needs]

- [ ] **Task 2: [Short title]** `[tier-1]`
  - **What:** [1-2 sentences]
  - **Files:** `path/to/file.ts`
  - **Decision budget:** [what judgment this task is allowed to exercise]
  - **Accept when:** [criteria]
  - **Why tier-1:** [why this needs reasoning, e.g., "requires evaluating 3 API options"]

Tier tag rules:
- `[tier-3]` tasks MUST be executable without creative judgment.
  Every decision is pre-made in the task description and contract fields.
- `[tier-1]` tasks require reasoning or trade-off evaluation.
  Include **Why tier-1** explaining what judgment is needed.
- `[tier-2]` tasks need context awareness but not deep creativity.
- If a task has safety-critical or review-critical steps, put them in
  **Verification** or **Stop and ask if**, not in emphatic prose.
- If completion needs to be checked later, define the **Return artifact**
  explicitly so another human or agent can verify it.
- The golden rule: if a tier-3 model would need to make a judgment call,
  the task is not specific enough. Rewrite it.

## Open Questions

- [Any unresolved questions]

---
Authored-by: <family>/<version> (<tool>)
*Captain's log entry created by [shiplog](https://github.com/devallibus/shiplog)*
EOF
)"
```

On PowerShell, prefer the `--body-file` temp-file pattern from `references/shell-portability.md` instead of translating the heredoc inline.

---

## PHASE 2: Timeline Entry (Full Mode)

```bash
gh issue comment <ISSUE_NUMBER> --body "$(cat <<'EOF'
<!-- shiplog:
kind: handoff
issue: <ISSUE_NUMBER>
phase: 2
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/session-start] <Brief description of the work>

**Branch:** `issue/<N>-<description>`
**Approach:** [1-2 sentences about the plan for this session]

---
Authored-by: <family>/<version> (<tool>)
*Captain's log — session start*
EOF
)"
```

For cross-platform reliability, prefer `gh issue comment --body-file <temp-file>` when the comment body spans multiple lines.

## Delegation Handoff Comment

Use this when a model or agent delegates a bounded task to another agent. This is distinct from a phase-transition handoff.

```markdown
<!-- shiplog:
kind: handoff
issue: <ID>
phase: <PHASE>
updated_at: <ISO_TIMESTAMP>
-->

## [#<ID>] delegation handoff: <task title>

**Delegated by:** <family>/<version> (<tool>)
**Target tier:** tier-3
**Why delegation fits:** [why this work is bounded and non-judgmental]

### Goal
[One concrete outcome. This is the only goal.]

### Contract
- **Allowed files:** `path/to/file.ts`, `path/to/other.ts`
- **Must not change:** [files, APIs, behavior, or decisions outside scope]
- **Acceptance criteria:** [specific outcomes that define done]
- **Forbidden judgment calls:** [decisions the delegated agent must not make]
- **Stop and ask if:** [conditions that require escalation]
- **Active verification profile:** [profile names or `none`]
- **Verification required:** [tests, checks, or evidence required]
- **Return artifact:** [delegation report, changed-file list, verification note, blockers]
- **Decision budget:** `none` | `narrow`

### Task checklist
1. [Concrete action with file path]
2. [Concrete action with file path]
3. [Concrete action with file path]

### Gotchas
- [Anything the delegated agent could misunderstand]

Authored-by: <family>/<version> (<tool>)
```

## Delegation Return Artifact

The delegated agent should report completion with a structured artifact instead of an informal summary.

```markdown
<!-- shiplog:
kind: verification
issue: <ID>
updated_at: <ISO_TIMESTAMP>
-->

## [#<ID>] delegation report: <task title>

**Status:** completed | blocked | escalated
**Contract:** [link or quote the delegation handoff heading]

### Changed files
- `path/to/file.ts` - [summary]

### Acceptance criteria
- [x] [criterion met]
- [ ] [criterion not met, with reason]

### Verification status
- **Ran:** [commands/checks]
- **Passed:** [what passed]
- **Deferred:** [what was skipped, with reason]

### Decisions deferred upward
- [question or "None"]

### Blockers
- [blocker or "None"]

Authored-by: <family>/<version> (<tool>)
```

## PHASE 2: Quiet Mode `--log` Branch + PR

If the `--log` PR doesn't exist yet:
```bash
git checkout -b <branch>--log
git commit --allow-empty -m "shiplog: initialize knowledge log"
git push -u origin <branch>--log
gh pr create --base <branch> \
  --title "[shiplog/worklog] <description>" \
  --body "<!-- shiplog:\nkind: state\nissue: <ISSUE_NUMBER>\nbranch: <branch>--log\nstatus: open\nupdated_at: <ISO_TIMESTAMP>\n-->\n\n## Knowledge Log\n\nTracking decisions and discoveries for this work."
# If you deferred a brainstorm from PHASE 1, use that saved content as the initial PR body instead of this placeholder.
# Then switch back to the feature branch
git checkout <branch>
```

On PowerShell, use backtick (`` ` ``) for line continuation instead of `\`, or pass the PR body via `--body-file`.

Post a comment on the `--log` PR:
```bash
gh pr comment <LOG_PR_NUMBER> --body "<!-- shiplog:
kind: handoff
issue: <ISSUE_NUMBER>
phase: 2
updated_at: <ISO_TIMESTAMP>
-->

[shiplog/session-start] Work started. Approach: [1-2 sentences]"
```

---

## PHASE 3a: Discovery Issue Template

```bash
gh issue create \
  --title "[shiplog/discovery] Brief description" \
  --body "$(cat <<'EOF'
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
EOF
)"
```

Cross-reference on the parent:
```bash
gh issue comment <PARENT_ISSUE> --body "<!-- shiplog:
kind: blocker
issue: <PARENT>
status: blocked
updated_at: <ISO_TIMESTAMP>
-->

[shiplog/discovery] #<PARENT>: Found sub-problem -> created #<NEW_ISSUE>. This is a stacked prerequisite."
```

---

## PHASE 4: Commit Context Comment

### Bash

```bash
COMMIT_SHA=$(git log -1 --format='%h')
COMMIT_MSG=$(git log -1 --format='%s')

# Full Mode: comment on issue
gh issue comment <ISSUE_NUMBER> --body "$(cat <<EOF
<!-- shiplog:
kind: commit-note
issue: <ISSUE>
phase: 4
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/commit-note] #<ISSUE>: \`$COMMIT_SHA\`

**What:** $COMMIT_MSG

**Why:** [1-2 sentences explaining the reasoning]
**Verification:** [What was checked, what was deferred, or "Not run"]
[If verification profile active]:
- **Profile:** [active profile names]
- **Scenarios:** [added N, changed M, existing passed K]
- **Tests:** [added N, changed M, all passing]
- **Deferred:** [anything intentionally skipped, with reason]

**Discovered:** [Anything unexpected, or "Nothing unexpected"]

**Next:** [What comes next]

Authored-by: <family>/<version> (<tool>)
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
<!-- shiplog:
kind: commit-note
issue: <ISSUE>
phase: 4
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/commit-note] #<ISSUE>: ``$commitSha``

**What:** $commitMsg

**Why:** [1-2 sentences explaining the reasoning]
**Verification:** [What was checked, what was deferred, or "Not run"]
[If verification profile active]:
- **Profile:** [active profile names]
- **Scenarios:** [added N, changed M, existing passed K]
- **Tests:** [added N, changed M, all passing]
- **Deferred:** [anything intentionally skipped, with reason]

**Discovered:** [Anything unexpected, or "Nothing unexpected"]

**Next:** [What comes next]

Authored-by: <family>/<version> (<tool>)
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
<!-- shiplog:
kind: history
issue: <ISSUE_NUMBER>
branch: issue/<ISSUE_NUMBER>-<slug>
status: resolved
updated_at: <ISO_TIMESTAMP>
-->

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

[If verification profile active]:
**Verification profile:** [profile names]

- [x] [What was tested and how]
- [x] All existing tests pass
- [x] [Verification-profile-specific checks, e.g., "Fail-first confirmed", "No existing scenarios modified"]

**Verification summary:** [scenarios added/changed, tests added/changed, deferred items]

## Stacked PRs / Related

- [#related-pr or #related-issue if any]

## Knowledge for Future Reference

[Anything a future developer should know when revisiting this area. Patterns established, gotchas found, decisions that might need revisiting.]

---
Authored-by: <family>/<version> (<tool>)
*Captain's log — PR timeline by [shiplog](https://github.com/devallibus/shiplog)*
EOF
)"
```

The PR body is large enough that `--body-file` should be treated as the preferred portable path on both macOS/Linux and PowerShell.

## PHASE 5: Quiet Mode Final Summary

Add a final summary comment to the `--log` PR:
```bash
gh pr comment <LOG_PR_NUMBER> --body "$(cat <<'EOF'
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
<!-- shiplog:
kind: <ENVELOPE_KIND>
issue: <ID>
phase: 7
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/<tag>] #<ID>: <brief summary>

**Status:** [In progress / Blocked / Approach changed / Milestone reached]

**Progress since last update:**
- [What was done]

**Current state:**
- [Where things stand]

**Next steps:**
- [What comes next]

[If blocked]: **Blocker:** [Description and what help is needed]

[If approach changed]: **Why:** [What changed and reasoning]

Authored-by: <family>/<version> (<tool>)
```

Tag-to-kind mapping:
- `session-start` -> `handoff`
- `session-resume` -> `state`
- `milestone` -> `state`
- `discovery` -> `blocker`
- `approach-change` -> `state`
- `blocker` -> `blocker`
- `session-end` -> `history`

---

## Issue Closure Comment

When closing an issue manually (not via PR auto-close), use this format:

```markdown
<!-- shiplog:
kind: history
issue: <ID>
status: closed
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/history] #<ID>: Closure

**Evidence:** [URL to commit, PR, or decision artifact]
**Merged to default branch:** yes | no | n/a
**Verification:** [1-3 sentences — why this evidence satisfies the issue]
**Disposition:** fully resolved | superseded by #<N> | won't fix (reason)

Authored-by: <family>/<version> (<tool>)
```

See `references/closure-and-review.md` for the full closure and review protocol.

---

## Closure Verifier Handoff

Use this when a stronger model wants a bounded verifier agent to audit closure
evidence before an issue is manually closed.

```markdown
## [#<ID>] closure verifier handoff: <issue title>

**Delegated by:** <family>/<version> (<tool>)
**Target tier:** tier-3
**Why delegation fits:** [why this closure audit is bounded and evidence-driven]

### Goal
Verify whether the listed evidence justifies closing issue #<ID>. Do not close the issue yourself.

### Allowed sources
- issue body and linked discussion
- listed commits and merged PRs
- current file state on the default branch

### Contract
- **Candidate evidence:** [commit URLs, PR URLs, or artifact links to inspect]
- **Must not decide:** vague intent, partial-fix sufficiency, umbrella mixed status, or the closure action itself
- **Stop and ask if:** [conditions that require escalation to the supervising model]
- **Verification required:** confirm merge status, compare the diff or file state to the issue claim, and record any unresolved mismatch
- **Return artifact:** closure verification note
- **Decision budget:** `none`

Authored-by: <family>/<version> (<tool>)
```

## Closure Verification Note

Post the verifier output as a signed issue comment when it materially informs a
closure decision.

```markdown
<!-- shiplog:
kind: verification
issue: <ID>
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/verification] #<ID>: Closure audit

**Candidate evidence:** [links inspected]
**Merged to default branch:** yes | no | unclear
**Satisfied scope:** [which issue claims are satisfied]
**Unresolved mismatch:** [gap, ambiguity, or `None`]
**Confidence:** high | medium | low
**Recommended action:** close | keep open | escalate

Authored-by: <family>/<version> (<tool>)
```

---
## Review Sign-Off Comment

When reviewing a PR, include this sign-off block:

```
<!-- shiplog:
kind: verification
issue: <ISSUE_NUMBER>
pr: <PR_NUMBER>
updated_at: <ISO_TIMESTAMP>
-->

Reviewed-by: <family>/<version> (<tool>)
Disposition: approve | request-changes
Scope: <what was reviewed>
```

See `references/closure-and-review.md` §3-5 for the full multi-model review protocol.

---

## Edit Provenance

When a later model materially edits an existing signed artifact, choose one of these patterns.

### In-place edit footer

Use this when the artifact should remain the single canonical current body
(issue body, PR body, or a latest-wins state/history artifact). Preserve the
original `Authored-by:` line and append:

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

### Amendment artifact

Use this when silently rewriting the existing artifact would hide an important
event in the timeline: handoffs, verification comments, commit notes, review
sign-offs, or other major signed comments.

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

**Current canonical artifact:** [URL to the body/comment that should now be treated as current, or `this comment`]

Authored-by: <family>/<version> (<tool>)
```

If the amendment fully replaces the old artifact as current, swap `amends:` for
`supersedes:` and update the old artifact with `superseded_by:` when practical.
