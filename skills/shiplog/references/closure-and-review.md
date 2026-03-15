# Closure and Review

Evidence-linked issue closure and multi-model review protocol for shiplog. No issue closes without evidence. No PR merges without cross-model review.

---

## 1. Evidence-Linked Closure

### Core rule

Do not close an issue without linked evidence and a verification note.

### Evidence requirements

| Evidence type | When to use |
|---------------|-------------|
| Commit URL on default branch | The fix is a code change that has been merged |
| Merged PR URL | The fix is better represented by the full PR |
| Discussion or decision artifact | No code change — the issue was resolved by a decision, policy change, or external action |

**Preference order:** Commit on default branch > merged PR > discussion artifact. Use the most specific link available.

### Closure comment format

Every closure must include a comment (or be closed via PR body `Closes #N` with the PR containing the evidence). When closing manually:

```markdown
## [shiplog/history] #<ID>: Closure

**Evidence:** [URL to commit, PR, or decision artifact]
**Merged to default branch:** yes | no | n/a
**Verification:** [1-3 sentences — why this evidence satisfies the issue]
**Disposition:** fully resolved | superseded by #<N> | won't fix (reason)
```

### What counts as evidence

- A commit SHA on the default branch that addresses the issue.
- A merged PR whose diff addresses the issue.
- A comment, ADR, or external decision that makes the issue moot.
- For umbrella issues: links to the child PRs/issues that collectively satisfy the parent.

### What does NOT count

- Memory or assumption that the work was done.
- A branch that exists but was never merged.
- A PR that is still open or was closed without merging.
- Partial resolution without acknowledging the remaining gap.

### Escalation on ambiguity

If the match between the issue and the evidence is ambiguous:

1. **Do not close the issue.** Leave it open.
2. Post a comment explaining the ambiguity.
3. Tag the issue for human review or escalate to a higher-tier model.
4. If a verifier agent is available, delegate the ambiguity check using the bounded handoff contract from `references/model-routing.md`.

### Optional verifier-agent workflow

Use this workflow when closure evidence is specific enough to audit but repetitive enough to delegate.
The supervising model remains responsible for the closure decision.

**Supervisor responsibilities:**
- choose the candidate evidence links to inspect
- assemble a bounded verifier contract using the handoff template from `references/model-routing.md`
- keep closure judgment for ambiguous issues, umbrella issues, and any case where the verifier reports mismatch or low confidence

**Verifier may:**
- read the issue body and linked discussion
- inspect candidate commits and merged PRs
- inspect current file state on the default branch
- produce a signed verification note with evidence, confidence, and a recommended action

**Verifier may not:**
- reinterpret vague issue intent
- decide that a partial fix is "good enough"
- close umbrella issues or mixed-status roadmap issues on its own
- close any issue directly
- resolve ambiguous evidence by inference

**Required verifier output:**
- candidate fix artifact links
- whether the fix is merged to the default branch
- which parts of the issue are satisfied by the diff or current file state
- any unresolved mismatch or ambiguity
- confidence: `high` | `medium` | `low`
- recommended action: `close` | `keep open` | `escalate`

**Decision rule:**
- Only close when the supervising model agrees with the verifier's evidence review and the verifier returns `close` with high confidence and no unresolved mismatch.
- If the verifier returns `keep open` or `escalate`, do not close the issue.
- When a verifier note materially informed the closure decision, post it as an issue comment before closing so the audit trail stays durable.

### Umbrella issues

Umbrella issues (tracking multiple sub-issues or a roadmap) require:

- All child issues closed with their own evidence.
- A summary comment on the umbrella linking each child's resolution.
- If any child is unresolved, the umbrella stays open.

### Partial delivery

When a PR ships some tasks from an issue but other tasks remain (blocked, deferred, or planned for a later phase):

1. **Do not use `Closes #N`.** Use `Addresses #N (completes T1, T2, ...)` in the PR body. This links the PR to the issue without triggering auto-close.
2. **The issue stays open.** Completed tasks are checked off in the issue body; remaining tasks stay unchecked.
3. **Post a milestone comment** on the issue after merge, listing what shipped and what remains. Use the `[shiplog/milestone]` tag.
4. **Post a blocker comment** if remaining tasks are blocked on an external dependency. Reference the upstream issue (e.g., `openai/codex#11180`). Use the `[shiplog/blocker]` tag.
5. **Final closure** happens when the last remaining task ships (via a follow-up PR with `Closes #N`) or when all remaining tasks are explicitly cancelled with a rationale.

**What counts as evidence for partial delivery:** The merged PR is evidence for the tasks it completes. It is NOT evidence for the tasks that remain. The issue stays open because the remaining gap is acknowledged, not ignored.

**External blockers:** When tasks are blocked on upstream work outside this repository, the blocker comment should include a link to the upstream issue or tracking artifact. This makes the dependency searchable and auditable.

---

## 2. Closure Scope

This policy applies to:

- Backlog hygiene and issue triage.
- Recovery or history-reconciliation flows that close stale issues.
- Any automated or semi-automated closure by shiplog workflows.
- Manual closure during PR merges (via `Closes #N` in the PR body).

This policy does NOT normalize:

- Silent closure of ambiguous issues.
- Closing issues "for housekeeping" without evidence.
- Closing issues because the branch exists (merge status matters, not branch existence).

---

## 3. Multi-Model Review Protocol

### Core rule

Every PR merge requires a positive review from a model different from the author. Same-model self-review does not count as independent review.

### Why this matters

The review loop is part of the safety model. If shiplog captures the workflow but omits signed review, it is missing one of the core mechanisms that makes the process trustworthy. A single model authoring, reviewing, and merging its own work is the anti-pattern this protocol prevents.

### Review artifacts

A review produces one of three artifacts:

| Artifact | Meaning |
|----------|---------|
| **Approve** | No issues found; merge is authorized |
| **Request changes** | Issues found; author must address before re-review |
| **Comment** | Observations that do not block merge |

For AI-operated shiplog reviews, these outcomes are recorded as signed comment artifacts. The `Disposition:` line is the authoritative outcome; formal GitHub review states and badges are advisory at best.

### Sign-off format

Every review comment must include a structured sign-off block:

```
Reviewed-by: <family>/<version> (<tool>)
Disposition: approve | request-changes
Scope: <what was reviewed — e.g., "full diff", "SKILL.md + artifact-envelopes.md">
```

**Example:**
```
Reviewed-by: claude/sonnet-4 (claude-code)
Disposition: approve
Scope: full diff — references/artifact-envelopes.md structure, SKILL.md pointer
```

This remains the canonical review sign-off block. Authorship and edit provenance are tracked separately via `Authored-by:` and `Updated-by:` artifacts; the review disposition still lives here.

### What constitutes "different model"

- Different model family (e.g., Opus vs Sonnet, GPT-5 vs Claude).
- Different model version within the same family counts IF explicitly documented (e.g., Opus 4.6 reviewing Opus 4.5 work).
- Same model, same version, different session does NOT count as independent.
- Human review always counts as independent.

### Review target selection

When asked to review PRs, whether one PR or many (e.g., "review PRs", "check for PRs to review", "review PR #56"), the reviewing agent should:

1. List open PRs on the repository.
2. For each PR, inspect the newest signed shiplog author-side artifact you can verify for that work (for example the PR body `Authored-by:` or `Updated-by:` line, or a newer linked commit-note / handoff / amendment artifact) and any existing `Reviewed-by:` sign-offs.
3. **Skip PRs where the newest verifiable author-side artifact or most recent review sign-off was authored by the same model and version.** Reviewing your own work adds no independent assurance — it is the anti-pattern this protocol exists to prevent.
4. **Review PRs where the latest activity is from a different model.** These are candidates for cross-model review.
5. If all open PRs were last touched by the current model, inform the user:
   > "All open PRs were last touched by [model]. Cross-model review requires a different model. Would you like me to review anyway as an audit trail (non-gate-satisfying)?"
6. Only proceed with self-authored PR review if the user explicitly confirms after the reminder. Mark such reviews as `self-review` per Section 4 audit trail rules.

**Where to find review artifacts:** Shiplog review sign-offs are posted as issue/PR comments, not formal GitHub review events (see §4 GitHub API constraint). When checking for existing reviews, search the PR body plus issue/PR comments for `Reviewed-by:` and `Disposition:` lines. Do not rely on the formal reviews API endpoint alone — it will miss most AI-operated reviews.

**What counts as "last touched":** The most recent signed shiplog artifact you can verify on either side: (a) the newest author-side `Authored-by:` or `Updated-by:` artifact associated with the work, or a newer amendment artifact, or (b) the most recent review `Reviewed-by:` sign-off. Do not treat raw Git commit metadata as model provenance; shiplog provenance lives in signed artifacts, not the commit object. If the branch moved after the last visible signed author artifact and the responsible model is unclear, treat authorship as unknown and do not claim a gate-satisfying same-model review.

---

## 4. Review Execution Ladder

Ordered from most to least desirable:

### GitHub API constraint

All AI agents authenticate as the repository owner's GitHub account. Formal same-account review events are not a reliable mechanism in this workflow: GitHub blocks self-`APPROVE`, and shiplog should not depend on formal `REQUEST_CHANGES` or other review states as merge-authoritative signals either.

**Workaround:**
- Use signed review comments as the canonical review artifact.
- Post a comment review artifact for every outcome, including approve, request-changes, and non-blocking feedback.
- Include the full signed disposition block (`Reviewed-by:`, `Disposition: approve | request-changes`, `Scope:`) in the comment body.
- The cross-model provenance in the `Reviewed-by:` line is the authoritative review signal for shiplog, not the GitHub review badge.
- Merge authorization follows the shiplog sign-off (see Section 5), not GitHub `reviewDecision`, review badges, or formal review states.

### Best: Spawn a review agent

If the current tool supports spawning a bounded agent:

1. Prepare a review contract (see below).
2. Spawn the reviewer with read-only access to the PR diff.
3. The reviewer produces a signed review artifact.
4. The author addresses findings or proceeds to merge on approval.

### Fallback: Generate a review contract

If spawning is unavailable, generate a self-contained review contract for the user to hand to another model/tool:

```markdown
## Review Contract

**PR:** #<N> — <title>
**Author:** <model name> (<tool>)
**Branch:** <branch> → <base>
**Diff command:** `gh pr diff <N>`

### What to review
- [Specific files or sections to focus on]
- [Key decisions to validate]

### Review checklist
- [ ] Changes match the issue requirements
- [ ] No unintended side effects or regressions
- [ ] Cross-references between files are consistent
- [ ] Templates and examples are correct

### Output required
Sign-off comment with:
- Reviewed-by line
- Disposition (approve / request-changes)
- Scope of review
- Any findings
```

### When independent review is unavailable: audit trail only

When cross-model review is genuinely unavailable (single-tool environment, urgency), the author records a self-review audit artifact. **This does not satisfy the gate and the PR remains unmerged.**

1. The author signs a self-review clearly marked as non-satisfying.
2. The sign-off explicitly states that independent review is still required.
3. The PR stays open — merge is blocked until an independent reviewer approves.

```
Reviewed-by: claude/opus-4.6 (claude-code)
Disposition: self-review (does NOT satisfy gate — independent review required)
Scope: full diff
Note: Self-review recorded as audit trail. This PR must not merge until an independent cross-model review is completed.
```

**Self-review is an audit artifact, not a gate-satisfying event.** It exists so the review intent is visible in the timeline, but it confers no merge authorization. There are no exceptions to the independent review requirement.

### Review completion: default publication

A PR review is not complete until the signed review artifact is posted on the PR as a GitHub comment. Local analysis that exists only in the agent's chat session does not satisfy the review protocol — the canonical artifact must be durable and visible on the PR timeline.

**Default behavior:** After completing the review analysis and summarizing findings to the user, post the signed review artifact on the PR. Then link the posted comment in the user-facing response.

**Explicit exceptions (require user opt-in):**
- The user explicitly requested a dry run or local-only review.
- The user explicitly asked not to post to GitHub.

Unless one of these exceptions applies, publication is the assumed completion step. The agent should not wait for a follow-up prompt to post.

**When GitHub posting is blocked:** If the agent cannot reach GitHub (network failure, API error, permission issue):

1. Report the blocker to the user immediately.
2. Provide the exact signed review artifact text in the chat response so the user can post it manually or the agent can retry later.
3. Do not mark the review as complete — note that publication is pending.
4. On next opportunity, retry posting the artifact or confirm the user has posted it.

The signed artifact text is the deliverable. GitHub publication is the delivery mechanism. When the mechanism fails, preserve the deliverable intact and make the failure visible.

---

## 5. Merge Authorization

### Merge conditions

A PR may be merged when:

1. At least one cross-model review with `Disposition: approve` exists.
2. All `request-changes` reviews have been addressed (new review cycle or author response).
3. The PR body includes `Closes #<N>` linking to the tracking issue.
4. The issue closure will have linked evidence (the merged PR itself serves as evidence).

### Risk-based review requirements

| Change type | Minimum review |
|-------------|----------------|
| Documentation only | 1 cross-model approve |
| Code changes | 1 cross-model approve |
| Gate/policy changes | 1 cross-model approve + explicit acknowledgment of policy impact |
| Security-sensitive | 1 cross-model approve + human confirmation recommended |

### After merge

1. Verify the linked issue(s) are closed (GitHub auto-close via `Closes #N`, or manual closure with evidence).
2. If manual closure is needed, use the closure comment format from §1.
3. Post a verification note if the auto-close does not carry sufficient evidence context.

---

## Integration with Shiplog Phases

### Phase 5 (PR-as-Timeline)

Before creating a PR, check:
- Is the author identity known? (Include in PR body or sign-off.)
- Who will review? (Note in the PR body if pre-arranged.)

After creating a PR:
- If cross-model review is available, request it immediately.
- If not, generate the review contract and inform the user.

### Phase 4 (Commit-with-Context)

Commit context comments do not require cross-model review. The review gate applies at the PR level, not the commit level.

### Issue closure

When a PR merges and auto-closes issues via `Closes #N`:
- The merged PR is the evidence.
- If the PR body contains a clear evidence table or summary, no additional closure comment is needed.
- If the relationship between the PR and the issue is non-obvious, add a closure comment per §1.
