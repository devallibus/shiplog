# PR Creation Workflow

Convention-enforced PR creation workflow for shiplog. This replaces delegation to external PR skills (`ork:create-pr`, `superpowers:finishing-a-development-branch`) to guarantee shiplog's PR timeline template, envelope metadata, label application, provenance signing, and review gate are met.

External PR skills remain usable for their validation features (security scanning, test coverage), but this reference is the authoritative workflow for PR creation when shiplog is active.

---

## Step 1: Pre-flight checks

### Bash

```bash
BRANCH=$(git branch --show-current)
ISSUE=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1)
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')

# Verify not on default branch
if [[ "$BRANCH" == "$DEFAULT_BRANCH" ]]; then
  echo "STOP: Cannot create PR from $BRANCH."
  exit 1
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  echo "Uncommitted changes detected. Commit or stash first."
  exit 1
fi

# Push branch if needed
git fetch origin
if ! git rev-parse --verify "origin/$BRANCH" &>/dev/null; then
  git push -u origin "$BRANCH"
fi
```

### PowerShell

```powershell
$branch = git branch --show-current
$issue = ([regex]::Match($branch, '\d+')).Value
$defaultBranch = gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# Verify not on default branch
if ($branch -eq $defaultBranch) {
  Write-Host "STOP: Cannot create PR from $branch."
  exit 1
}

# Check for uncommitted changes
if (git status --porcelain) {
  Write-Host "Uncommitted changes detected. Commit or stash first."
  exit 1
}

# Push branch if needed
git fetch origin
git show-ref --verify --quiet "refs/remotes/origin/$branch"
if ($LASTEXITCODE -ne 0) {
  git push -u origin $branch
}
```

## Step 2: Gather context

### Bash

```bash
# Commits in this branch
git log --oneline "$DEFAULT_BRANCH..HEAD"

# File change summary
git diff "$DEFAULT_BRANCH...HEAD" --stat

# Issue context (if available)
gh issue view "$ISSUE" --json title,body,labels 2>/dev/null
```

### PowerShell

```powershell
# Commits in this branch
git log --oneline "$defaultBranch..HEAD"

# File change summary
git diff "$defaultBranch...HEAD" --stat

# Issue context (if available)
gh issue view $issue --json title,body,labels 2>$null
```

## Step 3: Determine delivery type

Check whether this PR fully resolves the issue or is a partial delivery.

**Full delivery:** All tasks in the issue are complete. Use `Closes #<id>`.

**Partial delivery:** Some tasks are complete but others are blocked or deferred. Use `Addresses #<id> (completes T1, T2, ...)` — this does not trigger GitHub auto-close.

## Step 4: Create the PR

Use the shiplog PR timeline template from `phase-templates.md`. The PR body must include:

1. Envelope metadata (`<!-- shiplog: ... -->`)
2. Summary
3. `Closes #N` or `Addresses #N (completes ...)`
4. Journey Timeline (discoveries, decisions)
5. Changes (commit list)
6. Testing / Verification
7. Knowledge for Future Reference
8. Provenance signature (`Authored-by:`)

### Labels

Apply shiplog labels at creation time:

### Bash

```bash
gh pr create --base "$DEFAULT_BRANCH" \
  --label "shiplog/history" \
  --label "shiplog/issue-driven" \
  --title "<type>(#$ISSUE): <brief description>" \
  --body-file "$TEMP_FILE"
```

### PowerShell

```powershell
gh pr create --base $defaultBranch `
  --label "shiplog/history" `
  --label "shiplog/issue-driven" `
  --title "<type>(#$issue): <brief description>" `
  --body-file $tempFile
```

For stacked PRs, also add `--label "shiplog/stacked"`.
For partial delivery PRs, use `status: in-progress` in the envelope instead of `status: resolved`.

### Base branch

Always use the repo's default branch (`$DEFAULT_BRANCH`), not a hardcoded value. Quiet Mode PRs use the feature branch as base for the `--log` PR.

## Step 5: Review gate

Every PR requires cross-model review before merge. After creating the PR:

1. Note the review requirement in the PR body or a comment.
2. See `closure-and-review.md` for the full review protocol.
3. The review must come from a different model than the one that authored the PR.
4. Sign the review artifact per the agent identity signing rules.

Do not merge without a review sign-off unless the user explicitly overrides.

## Step 6: Post-merge (after review and merge)

1. If the PR fully resolves the issue: GitHub auto-closes it via `Closes #N`.
2. If partial delivery: post a `[shiplog/milestone]` comment on the issue listing what shipped.
3. If any tasks are blocked on external dependencies: post a `[shiplog/blocker]` comment.
4. Store key learnings in the knowledge graph (`ork:remember` if available).

---

## Quiet Mode variant

For Quiet Mode, the feature PR is clean (no shiplog content). The `--log` PR carries all the timeline documentation.

1. Create the feature PR with the team's standard template.
2. Add a final `[shiplog/review-handoff]` comment to the `--log` PR (see `phase-templates.md`).
3. Keep the `--log` PR labels current: `shiplog/worklog`, `shiplog/quiet-mode`, `shiplog/issue-driven`.

---

## Finishing a branch (integration options)

When implementation is complete and all tests pass, present these options:

1. **Push and create PR** — the standard shiplog path (this workflow).
2. **Keep the branch** — for further work before PR.

Shiplog does not support direct local merges without a PR, because every merge must go through the review gate. If the user requests a local merge, note the review requirement and offer to create a PR instead.

---

## Attribution

This workflow internalizes conventions from:
- [OrchestKit](https://github.com/yonatangross/orchestkit) `ork:create-pr` (MIT License)
- [Superpowers](https://github.com/obra/superpowers) `superpowers:finishing-a-development-branch` (MIT License)

See `LICENSES/` for full license texts.
