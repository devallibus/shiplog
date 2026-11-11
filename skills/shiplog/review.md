# Review a PR, or check whether it is reviewed

Rules and limits: [references/closure-and-review.md](references/closure-and-review.md).

## Check review state

1. Read the project's requirements: branch protection or rulesets, required checks, and `.shiplog/review.md` (`review: project` when absent).
2. Get the head commit: `gh pr view N --json headRefOid,commits,body`.
3. Collect evidence: native reviews (`gh api repos/O/R/pulls/N/reviews`) and comments with `Reviewed-by:` lines (`gh pr view N --json comments`).
4. A review is current only if its reviewed commit equals the head SHA (full SHA or a unique 7+ character prefix). A native review's commit is its `commit_id`. Anything else is stale, including old comments with no `Reviewed commit:` line.
5. Report what exists: reviewer, disposition, reviewed commit, and whether it is current. Never report an approval that does not exist. Bot findings, "no findings", and a model name are not approvals. Only an explicit approval from an owner, member, or collaborator account counts.

In `cross-model` mode, the `shiplog/review-gate` status reports the same check.

## Review

1. Read the project's requirements and the diff at the current head (`gh pr diff N`).
2. If an approval will leave follow-ups, open the follow-up issue first.
3. Post one comment (`gh pr comment N --body-file FILE`):

```markdown
<Findings, or "No blocking findings." Tag non-blocking items [follow-up].>

Reviewed-by: <family>/<version> (<tool>)
Disposition: approve | approve-with-follow-ups | request-changes
Scope: <what you read, e.g. full diff>
Reviewed commit: <full head SHA>
Follow-ups: #<issue> | none
```

Use your own identity. Never write `human/...` for a model. In `cross-model` mode, check the PR's `Last-code-by:` line and the commits' `Authored-by:` and `Co-Authored-By:` trailers. If your identity matches any of them, your approval does not satisfy the gate. Say so in the comment.

Do not update the PR body. Review state comes from the comments and the head SHA.
