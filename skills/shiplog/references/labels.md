# Labels

Labels are optional. Use them only when the project already uses shiplog labels or the user asks for them. Check existing labels before applying one, and touch only labels in the `shiplog/` namespace.

When labels are in use, lifecycle labels own readiness. Do not keep a copy of readiness in an envelope, summary, or other field.

- `shiplog/plan`: the issue holds a captured plan or idea. Keep it while work proceeds.
- `shiplog/ready`: scoped and ready to implement.
- `shiplog/in-progress`: a branch exists and work has started.
- `shiplog/needs-review`: a PR awaits review.
- `shiplog/blocker`: progress is blocked. Remove it when the work is unblocked.

`shiplog/ready`, `shiplog/in-progress`, and `shiplog/needs-review` are mutually exclusive. Adding one removes the other two. Remove all three when the issue closes.

Other `shiplog/*` labels from earlier versions, such as `shiplog/discovery`, `shiplog/history`, `shiplog/stacked`, `shiplog/issue-driven`, and `shiplog/verification`, remain readable. Leave them on old records; new records do not need them.

## Bootstrap

Run once in a repository that opts in. `--force` updates labels that already exist.

```bash
gh label create "shiplog/plan" --color 0B7285 --description "Captured plan or idea" --force
gh label create "shiplog/ready" --color 2DA44E --description "Ready to implement" --force
gh label create "shiplog/in-progress" --color FBCA04 --description "Implementation in progress" --force
gh label create "shiplog/needs-review" --color D93F0B --description "Awaiting review" --force
gh label create "shiplog/blocker" --color C92A2A --description "Progress is blocked" --force
```

Change lifecycle state in one edit:

```bash
gh issue edit N --remove-label "shiplog/ready" --remove-label "shiplog/needs-review" --add-label "shiplog/in-progress"
```
