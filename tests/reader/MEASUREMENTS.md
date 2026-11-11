# Retrieval measurement (issue #166, T3)

Measured on 2026-11-11T18:04:24Z against `devallibus/shiplog` (18 open issues, 2 open PRs), with gh 2.86.0 in Git Bash on Windows. `GH_REPO=devallibus/shiplog` was set.

- **Requests** are HTTP requests counted from `GH_DEBUG=api` stderr lines that start with `* Request to https`.
- **Bytes** are the command's stdout, measured with `wc -c`. That is the text the model would receive.

No token counts were measured. Each command ran once and exited 0.

## Results

| Command | Requests | Bytes |
|---|---:|---:|
| Old hunt step 1: `gh issue list --state open --json number,title,labels --limit 30` | 1 | 5302 |
| Old hunt step 2: `gh pr list --state open --json number,title,isDraft,reviewDecision,reviews,body,url,headRefName,comments,commits --limit 20` | 1 | 10939 |
| Old lookup triage (issues with bodies): `gh issue list --state open --json number,title,labels,body --limit 30` | 1 | 127527 |
| Old envelope shortcut: `gh issue view 166 --json body --jq '.body \| split("\n") \| .[0:15] \| join("\n")'` | 1 | 410 |
| Old envelope scan: `gh issue view 166 --json body,comments --jq '[.body, .comments[].body] \| map(select(test("<!-- shiplog:")))'` | 2 | 17391 |
| Full record: `gh issue view 166 --json body,comments` | 2 | 17991 |
| Old lookup search: `gh issue list --state all --search envelope --json number,title,state,labels --limit 10`, then `gh pr list --state all --search envelope --json number,title,state --limit 10`, then `git log --all --oneline --grep=envelope -n 20` | 4 | 5974 |
| New: `scripts/shiplog-read.sh index` | 1 | 2734 |
| New: `scripts/shiplog-read.sh show 166` | 2 | 1467 |
| New: `scripts/shiplog-read.sh source 166` (both source comments) | 1 | 5273 |
| New: `scripts/shiplog-read.sh source 166 <comment URL>` (one comment) | 1 | 955 |
| New: `scripts/shiplog-read.sh search envelope` | 4 | 2213 |

The reader receives larger payloads from gh than it prints. It parses these bytes locally and does not return them to the model:

| Reader input | Requests | Bytes |
|---|---:|---:|
| `index`: `gh api "repos/{owner}/{repo}/issues?state=open&per_page=50" --jq ".[].body"` | 1 | 123549 |
| `show 166`: issue body plus comment bodies via `gh api` | 2 | 17092 |

## Notes

- The old first-15-lines shortcut is smaller than `show 166` because it prints only the start of the body. Issue 166's envelope has 10 lines, so this run does not show truncation. The test fixture `long-envelope.md` covers that case. The shortcut also omits task counts, authors, and the list of comment entries.
- Issue 166's old envelope stores `task_count: 7` and `tasks_complete: 0`. `index` and `show` compute `0/7` from the Tasks section, so the values agree on this issue.
- Old hunt step 2 returns full PR comment threads. With only 2 open PRs, this run understates its size in a repository with more PRs.
- The reproduction was a one-off loop around the commands above. Set `GH_REPO` and `GH_DEBUG=api`, then count stdout with `wc -c`.
