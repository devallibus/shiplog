---
name: lookup
description: Find past discussion, decisions, and work context in shiplog records.
---

# Lookup

Use the reader first. It prints compact lines and returns full text only when you ask for source entries. Paths are relative to this skill directory. Run it inside the repository, or add `-R OWNER/REPO`.

1. **Find candidates.**
   - Known number: `scripts/shiplog-read.sh show N`.
   - Topic: `scripts/shiplog-read.sh search "TEXT"`. It prints matching issues, PRs, and local commits, one line each. Add `--limit N` to widen it.
   - Open work: use [hunt.md](hunt.md).
2. **Read the summary.** `show N` prints the complete envelope, task counts computed from the checkboxes, open task titles, and one `kind | date | url | summary` line per enveloped comment.
3. **Read original wording only when the question needs it.** For what someone said, why a decision was made, or a rejected idea, run `scripts/shiplog-read.sh source N URL` for one entry, or `source N` for every `kind: source` entry. The output is the original comment text.
4. **Fall back for older records.** When `show` lists no entry that answers the question, read the record with `gh issue view N --comments` or `gh pr view N --comments`. Older issues may keep source text in the body. Do not rewrite old records while reading them.
5. **Report.** Give the answer first. Then list the issues, PRs, commits, and comment URLs it came from. Mark quoted human text separately from agent summaries.

Field meanings: [references/artifact-envelopes.md](references/artifact-envelopes.md). Record format: [references/records.md](references/records.md).
