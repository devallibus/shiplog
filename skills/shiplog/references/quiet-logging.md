# Quiet logging

Quiet logging keeps the team-facing PR limited to the change and puts the shiplog record somewhere else. Use it only when the user asks for it or the project has already set it up. It is never the default.

## Choose the log location

If the location is not already decided, ask once where the record should live:

- an existing tracking issue, without shiplog labels or planning prose;
- a log branch named after the feature branch with a `--log` suffix, with a draft PR that holds the record; or
- an external tracker the team already uses, cited by its own ID.

Do not create issues the user did not ask for. Without a GitHub issue, cite the external ID or the branch name wherever a commit or PR would cite `#N`.

## What changes

Write source entries, decisions, handoffs, and the current summary at the log location, in the formats from [records.md](records.md). Keep the feature PR to the problem, resulting behavior, checks, and closing reference. Link the log from the feature PR only if the user wants it visible. A log branch carries no product code.

Review evidence stays on the feature PR, because that PR is what merges. Lookup and resume read the log location as well as the feature PR.

Switching an existing project to quiet logging does not move or rewrite earlier records.
