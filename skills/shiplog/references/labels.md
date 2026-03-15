# GitHub Labels

Use this file when Shiplog needs to bootstrap, apply, or repair repository labels.

## Canonical label set

| Label | Use when | Color | Description |
|------|----------|-------|-------------|
| `shiplog/plan` | The issue is the planning artifact created from a brainstorm | `0B7285` | Brainstorm captured as a planning issue |
| `shiplog/discovery` | The issue was created from an in-flight discovery | `1D6F42` | Work discovered during another issue or PR |
| `shiplog/blocker` | The tracked work is currently blocked | `C92A2A` | Progress is blocked and needs unblocking |
| `shiplog/worklog` | The PR is a Quiet Mode `--log` knowledge PR | `7C6F64` | Knowledge-log PR for Quiet Mode work |
| `shiplog/history` | The PR is the final timeline/history artifact for the work | `495057` | Final history-bearing Shiplog PR |
| `shiplog/verification` | The issue or PR mainly audits evidence, review readiness, or closure status | `5F3DC4` | Verification, closure audit, or review evidence |
| `shiplog/stacked` | The issue or PR is a stacked prerequisite or child of another work item | `E67700` | Stacked dependency or prerequisite |
| `shiplog/issue-driven` | The PR is explicitly tied to a tracking issue | `1971C2` | PR is linked to a Shiplog issue |
| `shiplog/quiet-mode` | The PR is part of Quiet Mode logging rather than the clean feature PR | `6741D9` | Quiet Mode log artifact |
| `shiplog/ready` | The issue is fully scoped and ready to implement | `2DA44E` | Ready to implement |
| `shiplog/in-progress` | Work has started and a branch exists | `FBCA04` | Implementation in progress |
| `shiplog/needs-review` | A PR exists and awaits review | `D93F0B` | Awaiting review |

**Lifecycle label rules:** `shiplog/ready`, `shiplog/in-progress`, and `shiplog/needs-review` are mutually exclusive.

## Bootstrap

Run this once before the first labeled `gh issue create` or `gh pr create` in a repository, then rerun it whenever the label descriptions need to be refreshed.

```bash
gh label create "shiplog/plan" --color 0B7285 --description "Brainstorm captured as a planning issue" --force
gh label create "shiplog/discovery" --color 1D6F42 --description "Work discovered during another issue or PR" --force
gh label create "shiplog/blocker" --color C92A2A --description "Progress is blocked and needs unblocking" --force
gh label create "shiplog/worklog" --color 7C6F64 --description "Knowledge-log PR for Quiet Mode work" --force
gh label create "shiplog/history" --color 495057 --description "Final history-bearing Shiplog PR" --force
gh label create "shiplog/verification" --color 5F3DC4 --description "Verification, closure audit, or review evidence" --force
gh label create "shiplog/stacked" --color E67700 --description "Stacked dependency or prerequisite" --force
gh label create "shiplog/issue-driven" --color 1971C2 --description "PR is linked to a Shiplog issue" --force
gh label create "shiplog/quiet-mode" --color 6741D9 --description "Quiet Mode log artifact" --force
gh label create "shiplog/ready" --color 2DA44E --description "Ready to implement" --force
gh label create "shiplog/in-progress" --color FBCA04 --description "Implementation in progress" --force
gh label create "shiplog/needs-review" --color D93F0B --description "Awaiting review" --force
```

## Auto-label mapping

Use high-confidence mapping only.

| Signal | Labels |
|--------|--------|
| Issue title starts with `[shiplog/plan]` | `shiplog/plan` |
| Issue title starts with `[shiplog/discovery]` | `shiplog/discovery` |
| Discovery issue explicitly blocks a parent or is created as a prerequisite | `shiplog/discovery`, `shiplog/stacked` |
| PR title starts with `[shiplog/worklog]` or the branch ends with `--log` | `shiplog/worklog`, `shiplog/quiet-mode` |
| Full-mode PR body follows the timeline template and includes `Closes #<N>` | `shiplog/history`, `shiplog/issue-driven` |
| PR branch matches `issue/<N>-...` or the PR body includes `Closes #<N>` | `shiplog/issue-driven` |
| Issue or PR exists mainly to audit closure, review, or verification evidence | `shiplog/verification` |
| Timeline state says blocked and work cannot proceed | add `shiplog/blocker` |
| Timeline state says unblocked, resumed, or prerequisite resolved | remove `shiplog/blocker` |
| Issue envelope `readiness: ready` and no lifecycle label is present | add `shiplog/ready` |
| Branch created for issue | replace lifecycle label with `shiplog/in-progress` |
| PR created for issue | replace lifecycle label with `shiplog/needs-review` |
| PR merged and issue closed | remove all lifecycle labels |

## Backfill and repair

Inspect labels before changing them:

```bash
gh issue view <ISSUE_NUMBER> --json labels
gh pr view <PR_NUMBER> --json labels
```

Add or repair labels without touching user labels outside the `shiplog/` namespace:

```bash
gh issue edit <ISSUE_NUMBER> --add-label "shiplog/plan"
gh issue edit <ISSUE_NUMBER> --add-label "shiplog/discovery" --add-label "shiplog/stacked"
gh issue edit <ISSUE_NUMBER> --add-label "shiplog/blocker"
gh issue edit <ISSUE_NUMBER> --remove-label "shiplog/blocker"
gh pr edit <PR_NUMBER> --add-label "shiplog/worklog" --add-label "shiplog/quiet-mode"
gh pr edit <PR_NUMBER> --add-label "shiplog/history" --add-label "shiplog/issue-driven"
gh pr edit <PR_NUMBER> --add-label "shiplog/verification"
gh pr edit <PR_NUMBER> --remove-label "shiplog/blocker"
gh issue edit <ISSUE_NUMBER> --remove-label "shiplog/in-progress" --remove-label "shiplog/needs-review" --add-label "shiplog/ready"
gh issue edit <ISSUE_NUMBER> --remove-label "shiplog/ready" --remove-label "shiplog/needs-review" --add-label "shiplog/in-progress"
gh issue edit <ISSUE_NUMBER> --remove-label "shiplog/ready" --remove-label "shiplog/in-progress" --add-label "shiplog/needs-review"
gh issue edit <ISSUE_NUMBER> --remove-label "shiplog/ready" --remove-label "shiplog/in-progress" --remove-label "shiplog/needs-review"
```
