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
4. If a verifier agent is available, delegate the ambiguity check per `references/model-routing.md` delegation protocol.

### Umbrella issues

Umbrella issues (tracking multiple sub-issues or a roadmap) require:

- All child issues closed with their own evidence.
- A summary comment on the umbrella linking each child's resolution.
- If any child is unresolved, the umbrella stays open.

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

### Sign-off format

Every review comment must include a structured sign-off block:

```
Reviewed-by: <model name> (<tool/environment>)
Disposition: approve | request-changes
Scope: <what was reviewed — e.g., "full diff", "SKILL.md + artifact-envelopes.md">
```

**Example:**
```
Reviewed-by: Claude Sonnet 4 (Claude Code)
Disposition: approve
Scope: full diff — references/artifact-envelopes.md structure, SKILL.md pointer
```

This is the temporary format. When #33 (authored-artifact signatures) lands, it will formalize provenance more completely. Until then, this format provides enough structure for auditability.

### What constitutes "different model"

- Different model family (e.g., Opus vs Sonnet, GPT-5 vs Claude).
- Different model version within the same family counts IF explicitly documented (e.g., Opus 4.6 reviewing Opus 4.5 work).
- Same model, same version, different session does NOT count as independent.
- Human review always counts as independent.

---

## 4. Review Execution Ladder

Ordered from most to least desirable:

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

### Minimum: Self-review with transparency

When cross-model review is genuinely unavailable (single-tool environment, urgency):

1. The reviewing model signs its own review.
2. The sign-off explicitly states that independent review was not available.
3. Shiplog marks whether independent review is still required.

```
Reviewed-by: Claude Opus 4.6 (Claude Code)
Disposition: approve (self-review — independent review unavailable)
Scope: full diff
Note: This PR was self-reviewed. Independent cross-model review is recommended before this work is treated as trusted.
```

**Self-review does not satisfy the gate.** It is a documented exception, not a workaround.

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
