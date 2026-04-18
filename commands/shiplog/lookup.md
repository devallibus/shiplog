---
allowed-tools: Bash(gh:*), Bash(git:*), Read
description: Search the knowledge graph — issues, PRs, commits, and memory
argument-hint: <search query or issue number>
---

Find anything in the repository knowledge graph. Every **shiplog** artifact is indexed by `#<ID>` — use the issue number as the primary key for exact retrieval.

## Policy

**ID-first retrieval:** when you know the issue or PR number, use `#<N>` directly in search queries. This is the fastest, most precise path.

**Multi-surface search:** a complete lookup checks GitHub issues, GitHub PRs, and git commit history. Memory (if `ork:memory` is available) is searched last.

**Envelope-first reading:** when a result is found, read the `<!-- shiplog: ... -->` envelope comment first before loading the full body. The envelope fields (`readiness`, `tasks_complete`, `max_tier`) give you triage state in one scan.

**Deep dive on request only:** present the initial compact table to the user. Offer to read full bodies only if they ask for more detail or if a decision needs to be re-examined.

## Query / Template

### By issue number (ID-first, fastest)

```bash
gh issue list --state all --search "#<N>" --json number,title,state,labels --limit 5
gh pr list --state all --search "#<N>" --json number,title,state --limit 5
git log --all --oneline --grep="#<N>"
git log --all --oneline --grep="#<N>/T1"
```

### By keyword / topic

```bash
gh issue list --state all --search "<query>" --json number,title,state,labels --limit 10
gh pr list --state all --search "<query>" --json number,title,state --limit 10
git log --all --oneline --grep="<query>" --limit 20
```

### By shiplog tag

```bash
gh issue list --state all --search "[shiplog/plan]" --json number,title,state --limit 10
gh issue list --state all --search "shiplog/ready" --state open --json number,title,labels --limit 20
```

### Read envelope without full body

```bash
gh issue view <N> --json body --jq '.body | split("\n") | .[0:15] | join("\n")'
```

### If `ork:memory` is available

```
/ork:memory search "<query>"
```

### Lookup report format

```
LOOKUP: "<query>"
======================

ISSUES:
#NNN  <title>    <state>  <labels>

PULL REQUESTS:
#NNN  <title>    <state>

COMMITS:
<hash>  <subject>

MEMORY:
<key decisions or patterns found>
```

## Acceptance Checklist

- [ ] Both `gh issue list` and `gh pr list` searched (not just one surface)
- [ ] `git log --grep` run against commit history
- [ ] Results presented as compact table first; full bodies only on follow-up
- [ ] When a specific issue is found, envelope fields (`readiness`, `tasks_complete`) noted in report
- [ ] If `ork:memory` is available, it was queried
