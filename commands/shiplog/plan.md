---
allowed-tools: Bash(gh:*), Bash(git:*), Read, Write, Glob, Agent, Skill
description: Brainstorm a feature and capture it as a GitHub Issue
argument-hint: <feature description>
---

Capture a brainstorm as a durable planning issue. The issue becomes the single source of truth for the feature: envelope metadata, task contracts, open questions, and provenance signature — all in one body.

## Policy

Convert a brainstorm to a planning issue when:
- The scope is too large for a single commit (more than one logical change)
- The work requires tracking decisions over time
- Multiple tasks with dependencies exist
- Cross-model review will be required before shipping

**Issue envelope requirements (mandatory):**
- `kind: state` — planning issues carry state kind
- `status: open`
- `phase: 1`
- `readiness: ready` — if tasks are scoped and no blockers exist; `readiness: blocked` if a known blocker exists at creation
- `task_count` — count of `- [ ]` task lines
- `tasks_complete: 0` — always 0 at creation
- `max_tier` — highest `[tier-N]` tag among unchecked tasks

**Triage field derivation** (from `references/artifact-envelopes.md` §1): `task_count`, `tasks_complete`, and `max_tier` are derived from the task list, not hand-written. Only `readiness` is hand-set. Count `- [ ]` and `- [x]` lines; `max_tier` is the highest `[tier-N]` among unchecked tasks.

**Brainstorm external skills** (`superpowers:brainstorming`, `ork:brainstorming`) may be used for the exploration phase. Output capture MUST use this sub-skill's template — do not let external skills write the issue body directly.

**Label at creation:** Apply `shiplog/plan` when posting the issue.

## Query / Template

### Bootstrap labels (first run in a repo only)

```bash
gh label create "shiplog/plan" --color "0B7285" --description "Brainstorm captured as a planning issue" --force
gh label create "shiplog/ready" --color "2DA44E" --description "Ready to implement" --force
gh label create "shiplog/in-progress" --color "FBCA04" --description "Implementation in progress" --force
gh label create "shiplog/needs-review" --color "D93F0B" --description "Awaiting review" --force
gh label create "shiplog/history" --color "5319E7" --description "PR with a shiplog journey timeline" --force
gh label create "shiplog/issue-driven" --color "D4C5F9" --description "Branch/PR driven by an issue" --force
gh label create "shiplog/blocker" --color "B60205" --description "Something blocking progress" --force
```

### Create the issue

```bash
gh issue create \
  --title "[shiplog/plan] <feature title>" \
  --label "shiplog/plan" \
  --body-file <temp-file>
```

### Planning issue body template

```markdown
<!-- shiplog:
kind: state
status: open
phase: 1
readiness: ready
task_count: <N>
tasks_complete: 0
max_tier: tier-<N>
updated_at: <ISO_TIMESTAMP>
-->

## Context

<1–3 paragraphs: what problem this solves, why now, key constraints>

## Design Summary

<Key design decisions in bullet form>

## Approach

<How the work will be done — phases, key steps>

## Alternatives Considered

- **<Alternative A>:** rejected because <reason>

## Tasks

- [ ] **T1: <Title>** `[tier-<N>]`
  - **What:** <what this task does>
  - **Files:** <files affected>
  - **Allowed to change:** <explicit scope>
  - **Must not change:** <explicit constraints>
  - **Forbidden judgment calls:** <what the implementor must NOT decide>
  - **Verification:** <how to confirm this task is done>

- [ ] **T2: <Title>** `[tier-<N>]`
  - (same fields)

## Open Questions

- <question 1> — unresolved, must be answered before T<N>

Authored-by: <family>/<version> (<tool>)
```

### After creation — mark issue ready

If the issue was created with `readiness: ready` and tasks are fully scoped, apply the lifecycle label:

```bash
gh issue edit <N> --add-label "shiplog/ready"
```

## Acceptance Checklist

- [ ] Issue envelope has all five triage fields (`kind`, `readiness`, `task_count`, `tasks_complete`, `max_tier`)
- [ ] `max_tier` matches the highest `[tier-N]` tag in the unchecked task list
- [ ] Every task has at minimum: What, Verification fields
- [ ] `shiplog/plan` label applied at creation
- [ ] Issue body ends with `Authored-by: <family>/<version> (<tool>)`
- [ ] No unverified external claims are embedded as task requirements without `[unverified]` annotation
