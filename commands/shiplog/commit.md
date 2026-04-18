---
allowed-tools: Bash(git:*), Bash(gh:*), Read
description: Commit staged changes with shiplog ID-first convention and optional context comment
---

Stage and commit work with the shiplog ID-first format. For significant commits, post a `[shiplog/commit-note]` comment on the issue so the reasoning is durable on the timeline.

## Policy

**Commit message format:**
```
<type>(#<issue-id>): <description>
```

When the commit addresses a specific task:
```
<type>(#<issue-id>/<Tn>): <description>
```

**Types:** `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `style`, `perf`.

**Provenance signature in commit body:** every commit message body must include:
```
Authored-by: <family>/<version> (<tool>)
```

This is required for forensic retrieval — `git log --grep="Authored-by:"` surfaces all AI-authored commits.

**When to post a `[shiplog/commit-note]` comment:** post for any commit that involves new functionality, an unexpected discovery, an approach change, a tricky fix, or a decision the next reader would need context for. Skip for trivial commits (typos, formatting, small lint fixes).

**Staging:** prefer specific files (`git add <file>`) over `git add -A` or `git add .`. Never use `--no-verify` unless the user explicitly requests it.

## Query / Template

### Commit message template

Write to a temp file and use `git commit -F`:

```
<type>(#<issue-id>/<Tn>): <description>

<optional body: 1-2 sentences of context if the subject line isn't enough>

Authored-by: <family>/<version> (<tool>)
```

Commands:
```bash
git add <specific-files>
git commit -F <temp-file>
```

### Commit-note comment template

Post on the tracking issue when the commit is significant:

```markdown
[shiplog/commit-note] #<issue-id>: <commit-hash-short> <commit-subject>

**What:** <1-2 sentences on what this commit does>
**Why:** <reasoning behind the approach>
**Verification:** <what was tested or checked>

Authored-by: <family>/<version> (<tool>)
```

Post with:
```bash
gh issue comment <N> --body-file <temp-file>
```

### Retrieve commits by issue

```bash
git log --grep="#<issue-id>" --oneline
git log --grep="#<issue-id>/T1" --oneline
```

## Acceptance Checklist

- [ ] Commit message subject follows `<type>(#<id>): <msg>` or `<type>(#<id>/<Tn>): <msg>`
- [ ] Commit message body contains `Authored-by: <family>/<version> (<tool>)`
- [ ] Specific files staged, not `git add .` or `git add -A`
- [ ] `--no-verify` not used (unless user explicitly requested)
- [ ] For significant commits: `[shiplog/commit-note]` comment posted on the issue with `Authored-by:` sig
- [ ] Commit hash shown to user after committing
