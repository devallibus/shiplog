# Shell portability

Do not assume Bash. Check which shell runs the commands.

- Post every multiline issue, comment, or PR body with `--body-file`. Write the body to a UTF-8 file first instead of passing it through inline quotes or heredocs.
- Put temp files in the system temp directory or a scratch location, never the repository root, and never commit them. Delete each one after the post succeeds.
- Run commands as separate steps instead of chaining them with `&&` or `||`; Windows PowerShell 5 does not support those operators.
- Use `git commit -F FILE` for multiline commit messages.

In PowerShell:

- Capture output with `$x = gh ...`, not `x=$(...)`.
- Double-quoted strings and `@"..."@` here-strings expand `$name` and treat backticks as escapes. Use a single-quoted `@'...'@` here-string for literal markdown.
- `[IO.File]::WriteAllText` writes UTF-8 without a byte-order mark in every PowerShell version.

```powershell
$path = Join-Path ([IO.Path]::GetTempPath()) 'shiplog-body.md'
$body = @'
## Title

Body with `code` kept literal.
'@
[IO.File]::WriteAllText($path, $body)
gh issue comment N --body-file $path
Remove-Item $path
```
