# Plan or save an idea

Read [references/records.md](references/records.md). Reuse a relevant issue when one exists. Preserve the source discussion before replacing it with a design summary.

Capture the goal, constraints, open decisions, and proposed approach. Distinguish user choices from agent proposals. Mark any claim not checked against the repository or a primary source as `[unverified]` and treat it as a hypothesis. If the request covers several independent subsystems, say so and split it into separate issues. An exploratory discussion needs no task list or branch. When implementation is requested, add only the tasks needed for the real product path. Each task needs a concrete action and completion check; add file limits or dependencies when they matter.

Create the issue with `gh issue create --title TITLE --body-file FILE`. Post the source batch as a comment and add its URL to the current summary. Check existing labels before using them; labels are optional under [references/labels.md](references/labels.md).

Do not add model tiers when routing is off. Do not require a separate design approval if the user has already authorized the work. Continue through [branch.md](branch.md) when implementation is requested.
