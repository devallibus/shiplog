---
name: timeline
description: "Phase 7: Add timeline comments for session starts, milestones, discoveries, blockers, and approach changes."
---

# Timeline Updates (Phase 7)

<!-- routing: tier-3, agent -->
<!-- cross-cutting: references/model-routing.md (Step 0), references/signing.md, references/labels.md -->

0. **Routing check.** Run the phase entry check from `references/model-routing.md`.

1. **Add timeline comments** when: starting a new session, changing approach, finding something unexpected, completing a milestone, or getting blocked. Sign per `references/signing.md`.

2. **Use the standard format** below. Comment types: `session-start`, `session-resume`, `milestone`, `discovery`, `implementation-issue`, `approach-change`, `blocker`, `session-end`.

3. **Keep state labels honest.** Add `shiplog/blocker` when work cannot proceed. Remove it when the blocker clears.

Delegate automatic checkbox updates to `ork:issue-progress-tracking` if available.

---

## Timeline Comment Format

Target: issue (Full Mode) or `--log` PR (Quiet Mode).

```markdown
<!-- shiplog:
kind: <ENVELOPE_KIND>
issue: <ID>
phase: 7
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/<tag>] #<ID>: <brief summary>

**Status:** [In progress / Blocked / Approach changed / Milestone reached]

**Progress since last update:**
- [What was done]

**Current state:**
- [Where things stand]

**Next steps:**
- [What comes next]

[If blocked]: **Blocker:** [Description and what help is needed]

[If approach changed]: **Why:** [What changed and reasoning]

Authored-by: <family>/<version> (<tool>)
```

### Tag-to-Kind Mapping

| Tag | Envelope Kind |
|-----|--------------|
| `session-start` | `handoff` |
| `session-resume` | `state` |
| `milestone` | `state` |
| `discovery` | `blocker` |
| `implementation-issue` | `state` |
| `approach-change` | `state` |
| `blocker` | `blocker` |
| `session-end` | `history` |

---

## Implementation-Issue Timeline Comment

Use this when a relevant implementation issue surfaces during execution and is resolved inline.

```markdown
<!-- shiplog:
kind: state
issue: <ID>
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/implementation-issue] #<ID>: <brief summary>

**Category:** failed attempt | hidden dependency | risky workaround | scope surprise | verification gap | tooling friction
**Severity:** blocking | material | informational

**What happened:**
[1-3 sentences]

**Resolution:**
[How it was handled]

**Impact on the work:**
[How this affected scope, timeline, approach, or confidence]

Authored-by: <family>/<version> (<tool>)
```

---

## Issue Closure Comment

When closing an issue manually (not via PR auto-close):

```markdown
<!-- shiplog:
kind: history
issue: <ID>
status: closed
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/history] #<ID>: Closure

**Evidence:** [URL to commit, PR, or decision artifact]
**Merged to default branch:** yes | no | n/a
**Verification:** [1-3 sentences - why this evidence satisfies the issue]
**Disposition:** fully resolved | superseded by #<N> | won't fix (reason)

Authored-by: <family>/<version> (<tool>)
```

See `references/closure-and-review.md` for the full closure and review protocol.

---

## Closure Verifier Handoff

Use when a stronger model wants a bounded verifier agent to audit closure evidence:

```markdown
## [#<ID>] closure verifier handoff: <issue title>

**Delegated by:** <family>/<version> (<tool>)
**Target tier:** tier-3
**Why delegation fits:** [why this closure audit is bounded and evidence-driven]

### Goal
Verify whether the listed evidence justifies closing issue #<ID>. Do not close the issue yourself.

### Allowed sources
- issue body and linked discussion
- listed commits and merged PRs
- current file state on the default branch

### Contract
- **Candidate evidence:** [commit URLs, PR URLs, or artifact links to inspect]
- **Must not decide:** vague intent, partial-fix sufficiency, umbrella mixed status, or the closure action itself
- **Stop and ask if:** [conditions that require escalation]
- **Verification required:** confirm merge status, compare diff to issue claim, record any mismatch
- **Return artifact:** closure verification note
- **Decision budget:** `none`

Authored-by: <family>/<version> (<tool>)
```

## Closure Verification Note

```markdown
<!-- shiplog:
kind: verification
issue: <ID>
updated_at: <ISO_TIMESTAMP>
-->

## [shiplog/verification] #<ID>: Closure audit

**Candidate evidence:** [links inspected]
**Merged to default branch:** yes | no | unclear
**Satisfied scope:** [which issue claims are satisfied]
**Unresolved mismatch:** [gap, ambiguity, or `None`]
**Confidence:** high | medium | low
**Recommended action:** close | keep open | escalate

Authored-by: <family>/<version> (<tool>)
```
