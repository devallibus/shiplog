# Closure and review

## Closure evidence

Close only the scope the evidence supports: a commit on the default branch, a merged PR, or a linked decision. Memory, an unmerged branch, or an open PR is not evidence. If the match is unclear, leave the issue open and explain the gap.

When a PR delivers only part of the work, write `Addresses #N (completes T1, T2)` instead of `Closes #N`. Check the delivered tasks; leave the rest open and link any external blocker. An umbrella issue stays open until each child has evidence.

## Review evidence

A review is one attributed native GitHub review or PR comment from an owner, member, or collaborator account; evidence from other accounts is ignored. A comment carries the evidence block defined in [review.md](../review.md#review); the gate reads its `Reviewed-by:`, `Disposition:`, and `Reviewed commit:` lines.

`approve-with-follow-ups` needs the follow-up issue first. Other disposition text, such as `self-review`, is a note and not an approval. A native review uses its `commit_id` as the reviewed commit. Its state supplies the disposition when the body has no `Disposition:` line. Bot findings are not approvals.

Compute review state from these records and the head; never copy it into the PR body.

## Freshness

A review is current only if its reviewed commit equals the PR head: the full SHA, or a 7+ character prefix that matches no other commit on the PR. A new push makes earlier reviews stale without any record update.

## Modes

`.shiplog/review.md` holds one line: `review: project` (default when absent) or `review: cross-model`.

- **project** (default): follow the repository's own requirements (branch protection, rulesets, required checks, native or Codex reviews). shiplog adds no gate.
- **cross-model**: also require a current approval whose reviewer differs from every declared code author. A current `request-changes` blocks the PR until a newer qualifying approval appears.

"Different" means a different `<family>/<version>` string after lowercasing. The same model in a new session is not different. A human reviewer always counts: a native approval from a person's account, or `Reviewed-by: human/<login>`. The code authors are the PR body's `Last-code-by:` plus every `Authored-by:` and `Co-Authored-By:` trailer on the PR's commits. Every author counts, so one small edit by another model cannot launder the main author's work. Without a declared author, a model's approval cannot be compared and fails; a human approval still counts. An unsigned bot approval names no model, so it does not count.

**Limits:** Identity is declared, not proven. Agents may share one account, and admins can edit comments. The gate catches accidental self-approval, not a false `Reviewed-by:` line from a collaborator. The reliable part is freshness: a review cannot cover code it did not name.

## Enabling the Action

From github.com/devallibus/shiplog, copy `.github/workflows/review-gate.yml` and `.github/scripts/review-gate.sh`, then add `.shiplog/review.md`. On PR, review, and comment events, the gate job runs the script from the default branch (never PR code) and sets the commit status `shiplog/review-gate` on the PR head. `project` mode reports success with a "no gate" note. The workflow's `test` job runs `tests/review-gate/run.sh` offline; copy that directory too or remove the job.

To enforce the status, open branch protection or a ruleset for the default branch and add `shiplog/review-gate` as a required status check. Fork PRs get a read-only token on PR events, so a fork PR's status is set by the next comment event.

## Historical records

Do not rewrite old records. `Last-code-by:` lines remain author declarations. PR-body review snapshots (`Current state:`, `Last reviewed by:`) are history, not current state. Signed comments without `Reviewed commit:` still read as reviews but are never current. Old `self-review (audit trail)` dispositions are not approvals.
