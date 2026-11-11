# Parallel work

Use this only when the user has authorized delegation and the runtime can run another agent, session, or tool. Otherwise do the work in order yourself.

## When to fan out

Split work only into independent lanes: each can finish without waiting on another, and none blocks your next step. Keep small or tightly coupled work local. Parallel read-only gathering is fine, but it does not count as independent review.

## One writer per file

Give each set of files exactly one owner; two lanes never edit the same file. Shared files such as the issue body, a changelog, or a lockfile stay with the orchestrator or get one named owner. Give each lane that edits files its own isolated checkout, such as a git worktree.

## Lane contract

Give each lane a self-contained contract:

- **Goal:** one concrete outcome.
- **Owned files:** what it may create, change, or delete.
- **Forbidden changes:** files, interfaces, behavior, and decisions outside its scope, and actions such as pushing or posting.
- **Stop conditions:** when to stop and report instead of widening scope.
- **Checks:** what to run before reporting.
- **Report format:** changed files, commits, check output, and unresolved problems.

The [handoff](model-routing.md#handoff) uses the same fields for a single transfer.

## Accept a report

A report is a claim. Before accepting a lane:

- Compare the reported changes with the actual diff, and confirm the diff stays within the owned files.
- Read the check output yourself, or run the checks again.
- Confirm that the stated limits and open problems match what you see.

Collect every lane explicitly; one lane's success says nothing about another. Record a blocked or timed-out lane as such and continue with the rest. Merging, closing, and posting stay with the orchestrator.

Record only what matters later in the tracking issue: decisions, failed approaches, open problems, and the outcome, following [records.md](records.md). Do not post a comment for each dispatch.

## Clean up

Remove a worktree only when its branch is merged, no open PR depends on it, and no one is still working in it. Then remove the worktree with its build output and delete the merged branch:

```bash
git worktree remove PATH
git branch -d BRANCH
```

Report cleanup only after the commands have run.
