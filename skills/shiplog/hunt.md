---
name: hunt
description: Scan open issues and PRs and recommend what to work on next.
---

# Hunt

Paths are relative to this skill directory. Run inside the repository, or add `-R OWNER/REPO`.

1. **List open work.** Run `scripts/shiplog-read.sh index`. It makes one bounded call for open issues and one for open PRs and prints one line per record:

   `number  type  kind  tasks  labels  title  summary`

   `type` is `issue`, `pr`, or `draft-pr`. `tasks` is `done/total`, computed from checkboxes; `-` means none. Use `--limit N` when the repository has more open records than the default 30.
2. **Rank.** Use only the index lines:
   1. Open PRs that are not drafts. They are closest to done. Decide their review state with [review.md](review.md) and [references/closure-and-review.md](references/closure-and-review.md); do not decide it from the index.
   2. Issues labelled `shiplog/ready`.
   3. Issues labelled `shiplog/in-progress`, with the fewest open tasks first.
   4. Issues with other or no shiplog labels. They may need planning first.

   Lifecycle labels are optional; see [references/labels.md](references/labels.md). Without them, rank by open PRs, then partly done issues, then the rest.
3. **Check the top candidates only.** Run `scripts/shiplog-read.sh show N` for the two or three best items. Confirm the next action, blockers, and open tasks there. Do not open every record.
4. **Report.** List the ranked items as `#N title (tasks, labels)`. Then give one to three concrete recommendations, each with its reason and the next command to run.
