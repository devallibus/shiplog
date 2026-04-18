---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write, Skill
description: Create a PR with a shiplog journey timeline
---

Push the branch and create a PR whose body is a complete timeline of the work: initial plan, discoveries, key decisions, verification, and provenance signatures. Cross-model review is required before merge — see `commands/shiplog/review.md` for the review sub-skill.

## Policy

**PR body structure (mandatory sections, in order):**
1. Envelope comment (HTML `<!-- shiplog: ... -->`) with `kind: history`, `status: open`, `phase: 5`, `readiness: needs-review`, triage fields
2. Summary (1-3 bullets)
3. `Closes #<N>` (or `Addresses #<N> (completes T1, T2, ...)` for partial delivery)
4. Journey Timeline — Initial Plan, What We Discovered, Key Decisions table, Changes Made (commit list)
5. Verification — checklist of what was tested/checked
6. Reviews placeholder
7. Sig block: `Authored-by:` and `Last-code-by:` (both set to the creating model at creation)

**Provenance signatures (both required):**
```
Authored-by: <family>/<version> (<tool>)
Last-code-by: <family>/<version> (<tool>)
```
`Last-code-by:` is updated whenever new code is pushed to the branch after PR creation. See SKILL.md §8 for code provenance rules.

**Review gate:** do NOT merge until a cross-model `Reviewed-by:` + `Disposition: approve` (or `approve-with-follow-ups`) comment exists on the PR. Self-review does not satisfy the gate. See `commands/shiplog/review.md` for the full review sub-skill, and `references/closure-and-review.md` §3 for the cross-model gate policy.

**Partial delivery:** use `Addresses #<N> (completes T1, T2)` instead of `Closes #<N>` when some tasks remain. Post a `[shiplog/milestone]` comment on the issue after merge.

**Labels to apply at creation:** `shiplog/history`, `shiplog/issue-driven`

**Issue label transition:** move the issue from `shiplog/in-progress` to `shiplog/needs-review` after creating the PR.

## Query / Template

### Push and create the PR

```bash
git push -u origin <branch-name>

gh pr create \
  --title "<type>(#<N>): <summary>" \
  --body-file <temp-file> \
  --label "shiplog/history" \
  --label "shiplog/issue-driven"
```

### PR body template

```markdown
<!-- shiplog:
kind: history
status: open
phase: 5
readiness: needs-review
task_count: <N>
tasks_complete: <N>
updated_at: <ISO_TIMESTAMP>
-->

## Summary

- <bullet 1>
- <bullet 2>

Closes #<N>

## Journey Timeline

### Initial Plan

<1-2 sentences on what the issue called for>

### What We Discovered

<discoveries, blockers encountered, approach changes; omit if none>

### Key Decisions

| Decision | Rationale |
|----------|-----------|
| <decision> | <why> |

### Changes Made

- `<hash>` — <commit subject>
- `<hash>` — <commit subject>

## Verification

- [ ] <verification item 1>
- [ ] <verification item 2>

## Reviews

<!-- Awaiting cross-model review. See commands/shiplog/review.md for the review sub-skill. -->

Current state: awaiting review
Last reviewed by: —
Last reviewed at: —
Reviewed commit: —
Source artifact: —
Needs re-review since: —

---
Authored-by: <family>/<version> (<tool>)
Last-code-by: <family>/<version> (<tool>)
*Captain's log — PR timeline by **shiplog***
```

### Transition issue label

```bash
gh issue edit <N> --remove-label "shiplog/in-progress" --add-label "shiplog/needs-review"
```

## Acceptance Checklist

- [ ] PR envelope has `kind: history`, `readiness: needs-review`, correct triage fields
- [ ] PR body contains `Closes #<N>` (or `Addresses #<N>`) line
- [ ] Journey Timeline section present with commit list
- [ ] Both `Authored-by:` and `Last-code-by:` sig blocks present
- [ ] Review placeholder section present pointing to `review.md`
- [ ] Issue label transitioned from `shiplog/in-progress` to `shiplog/needs-review`
