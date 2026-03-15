# Commit Workflow

Convention-enforced commit workflow for shiplog. This replaces delegation to external commit skills (`ork:commit`, `commit-commands:commit`) to guarantee shiplog naming, signing, and traceability conventions are met.

External commit skills remain usable as a convenience, but this reference is the authoritative workflow when shiplog is active.

---

## Step 1: Pre-commit safety

### Bash

```bash
BRANCH=$(git branch --show-current)

# Must be on an issue branch, not the default branch
if [[ "$BRANCH" == "main" || "$BRANCH" == "master" || "$BRANCH" == "dev" ]]; then
  echo "STOP: Cannot commit directly to $BRANCH. Use issue/<id>-<slug> branch."
  exit 1
fi
```

### PowerShell

```powershell
$branch = git branch --show-current

# Must be on an issue branch, not the default branch
if ($branch -in @('main', 'master', 'dev')) {
  Write-Host "STOP: Cannot commit directly to $branch. Use issue/<id>-<slug> branch."
  exit 1
}
```

## Step 2: Determine issue and task context

Extract the issue number from the branch name:

### Bash

```bash
ISSUE=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1)
```

### PowerShell

```powershell
$issue = ([regex]::Match($branch, '\d+')).Value
```

If the commit addresses a specific task from the issue body, note the task ID (`T1`, `T2`, etc.).

## Step 3: Stage and review changes

These Git commands are shell-neutral; the same sequence works in Bash and PowerShell.

```bash
git status
git diff --staged    # What will be committed
git diff             # Unstaged changes — stage if needed
git add <files>      # Stage specific files
```

Prefer staging specific files over `git add .` to avoid accidentally including sensitive files.

## Step 4: Commit with shiplog format

**Issue-level commit** (most common):

### Bash

```bash
git commit -m "<type>(#$ISSUE): <brief description>"
```

### PowerShell

```powershell
git commit -m "<type>(#$issue): <brief description>"
```

**Task-level commit** (when addressing a specific task):

### Bash

```bash
git commit -m "<type>(#$ISSUE/T<n>): <brief description>"
```

### PowerShell

```powershell
git commit -m "<type>(#$issue/T<n>): <brief description>"
```

### Commit types

| Type | Use for |
|------|---------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code improvement, no behavior change |
| `docs` | Documentation only |
| `test` | Tests only |
| `chore` | Build, deps, CI, tooling |

### Rules

- Subject line under 72 characters.
- One logical change per commit.
- Always reference the issue: `(#<id>)` or `(#<id>/<Tn>)`.
- Task-level refs (`/<Tn>`) enable retrieval with `git log --grep="#42/T1"`.
- If the commit body is needed, add it after a blank line.

## Step 5: Verify

This verification step is shell-neutral.

```bash
git log -1 --stat
```

## When to add a timeline comment

After committing, decide whether to post a commit-context comment on the issue (Full Mode) or `--log` PR (Quiet Mode). See the commit context template in `phase-templates.md`.

**Add a context comment when:**
- Significant new functionality lands
- An unexpected discovery occurred during implementation
- The approach changed from the original plan
- A tricky bug was fixed and the reasoning matters
- A verification profile is active

**Skip the context comment for:**
- Trivial commits (typos, formatting, single-line fixes)
- Routine progress that doesn't carry decision context

---

## Attribution

This workflow internalizes conventions from:
- [OrchestKit](https://github.com/yonatangross/orchestkit) `ork:commit` (MIT License)
- [Superpowers](https://github.com/obra/superpowers) `commit-commands:commit` (MIT License)

See `LICENSES/` for full license texts.
