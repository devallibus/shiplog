# Shell Portability

Keep the workflow cross-platform. Do not assume Bash unless you know the agent is running in Bash.

- Prefer shell-neutral patterns for multiline GitHub content. When the issue, comment, or PR body is more than a short sentence, prefer `gh ... --body-file <temp-file>` over inline heredocs or nested quoting.
- Keep the existing Bash examples for macOS/Linux, but add a PowerShell-safe variant when interpolation or quoting rules differ.
- If the same content will be reused across shells, write the markdown to a temp file first and pass it to `gh`.
- For branch setup, break chained shell commands into separate steps if the shell operator differs across platforms.

## Portable pattern for multiline `gh` bodies

```bash
body_file="$(mktemp)"
cat > "$body_file" <<'EOF'
## Title

Body content
EOF
gh issue comment <ISSUE_NUMBER> --body-file "$body_file"
rm "$body_file"
```

```powershell
$bodyPath = Join-Path $PWD '.tmp-gh-body.md'
$body = @"
## Title

Body content
"@
Set-Content -Path $bodyPath -Value $body -NoNewline
gh issue comment <ISSUE_NUMBER> --body-file $bodyPath
Remove-Item $bodyPath -Force
```

Use the same pattern for `gh issue create`, `gh pr create`, and `gh pr comment`.

## PowerShell notes

- On PowerShell, break chained commands (`&&`) into separate steps.
- Use different variable capture syntax: `$VAR = gh ...` instead of `VAR=$(...)`.
- Use backtick (`` ` ``) for line continuation instead of `\`.
- In an expandable string or here-string, `` `$var `` escapes interpolation and posts the literal text `$var`.
- Use `` ``$var`` `` when you want markdown backticks around the interpolated value.
- If in doubt, avoid markdown code spans and post values as plain text.

## Worktree branch setup

```bash
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
git fetch origin $DEFAULT_BRANCH
BRANCH=issue/<ISSUE_NUMBER>-<brief-description>
git worktree add ../$BRANCH -b $BRANCH origin/$DEFAULT_BRANCH
cd ../$BRANCH
```

```powershell
$defaultBranch = gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
git fetch origin $defaultBranch
$branch = 'issue/<ISSUE_NUMBER>-<brief-description>'
git worktree add ../$branch -b $branch origin/$defaultBranch
Set-Location ../$branch
```
