# Closure and review

## Closure evidence

Close only the scope the evidence supports: a commit on the default branch, a merged PR, or a linked decision. Memory, an unmerged branch, or an open PR is not evidence. If the match is unclear, leave the issue open and explain the gap.

When a PR delivers only part of the work, write `Addresses #N (completes T1, T2)` instead of `Closes #N`. Check the delivered tasks; leave the rest open and link any external blocker. An umbrella issue stays open until each child has evidence.

## Review evidence

A review is one attributed native GitHub review or one PR comment:

```text
Reviewed-by: <family>/<version> (<tool>[, qualifier])
Disposition: approve | approve-with-follow-ups | request-changes
Scope: <what was read>
Reviewed commit: <SHA>
Follow-ups: #<issue> | none
```

`approve-with-follow-ups` requires the follow-up issue to exist first. Other disposition text, such as `self-review`, is a note and not an approval. A native review uses its `commit_id` as the reviewed commit. Its state supplies the disposition when the body has no `Disposition:` line. Bot findings are not approvals.

Compute review state from these records and the PR head; do not copy it into the PR body.

## Freshness

A review is current only if its reviewed commit equals the PR head: the full SHA, or a 7+ character prefix that matches no other commit on the PR. A new push makes earlier reviews stale without any record update.

## Modes

`.shiplog/review.md` holds one line: `review: project` or `review: cross-model`. It defaults to `project` when absent.

- **project** (default): follow the repository's own requirements (branch protection, rulesets, required checks, native or Codex reviews). shiplog adds no gate.
- **cross-model**: also require a current approval whose reviewer differs from every declared code author. A current `request-changes` blocks the PR until a newer qualifying approval appears.

"Different" means a different `<family>/<version>` string after lowercasing. The same model in a new session is not different. A human reviewer always counts: a native approval from a person's account, or `Reviewed-by: human/<login>`. The code authors are the PR body's `Last-code-by:` plus every `Authored-by:` and `Co-Authored-By:` trailer on the PR's commits. Every author counts, so one small edit by another model cannot launder the main author's work. If no author is declared, the gate fails. An unsigned bot approval names no model, so it does not count.

**Limits:** Identity is declared, not proven. Agents may share one GitHub account. The gate catches accidental self-approval, not a false `Reviewed-by:` line. The reliable part is freshness: a review cannot cover code it did not name.

## Enabling the Action

Copy `.github/workflows/review-gate.yml` and `.github/scripts/review-gate.sh`, then add `.shiplog/review.md`. On PR, review, and PR-comment events, the gate job runs the script from the default branch (never PR code) and sets the commit status `shiplog/review-gate` on the PR head. In `project` mode the status succeeds with a "no gate" note. The workflow's `test` job runs `tests/review-gate/run.sh` offline; copy that directory too or remove the job.

The status is informational until required. To enforce it, open branch protection or a ruleset for the default branch and add `shiplog/review-gate` as a required status check. Fork PRs get a read-only token on PR events, so the status for a fork PR is set by the next comment event.

## Historical records

Do not rewrite old records. `Last-code-by:` lines remain author declarations. PR-body review snapshots (`Current state:`, `Last reviewed by:`) are history, not current state. Signed comments without `Reviewed commit:` still read as reviews but are never current. Old dispositions such as `self-review (audit trail)` mean what they say; they are not approvals.
