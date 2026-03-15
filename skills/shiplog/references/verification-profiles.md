# Verification Profiles

Configurable testing and semantic-stability profiles for shiplog. Verification is not "run tests" — it is semantic-stability pressure that makes behavior drift expensive enough to catch.

---

## Design Principles

- **Shiplog defines policy, not tooling.** Profiles say when verification is required and how evidence is logged. Language/framework skills provide the actual test commands.
- **Behavior drift must be visible.** New features must not silently weaken old tests. Changes to existing scenarios require explicit acknowledgment.
- **Delegated agents inherit verification pressure.** A tier-3 agent cannot bypass verification by taking the path of least resistance — the profile travels with the task contract.
- **Graceful degradation.** Projects without profiles still work. The default profile is `none` (no enforcement, no logging). Profiles add rigor when opted in.

---

## 1. Profile Taxonomy

| Profile | Purpose | Default enforcement |
|---------|---------|---------------------|
| `none` | No verification requirements | silent |
| `behavior-spec` | Acceptance scenarios for new/changed behavior | per-issue opt-in |
| `red-green` | Fail-first unit tests for changed behavior | per-issue opt-in |
| `self-audit` | Implementation quality self-review before commit | per-issue opt-in |
| `structural` | Structural quality analysis on changed modules | per-issue opt-in |
| `mutation` | Differential mutation testing on changed modules | strict-profile opt-in |

Profiles are composable. A project or issue can activate multiple profiles simultaneously (e.g., `behavior-spec` + `red-green`).

### Scope boundary

Profiles govern the **evidence policy** — what must be checked and what must be recorded. They do not:

- Prescribe a specific test framework or runner.
- Replace language-specific testing skills (TDD, pytest, vitest, etc.).
- Block workflow when the required tool is not installed — instead, log the gap as deferred verification.

---

## 2. Configuration and Resolution

### Config location

Verification profiles are configured in `.shiplog/verification.md` at the project root.

### Config format

```markdown
# Verification Profiles

## Default Profile
behavior-spec, red-green

## Profile Settings

### behavior-spec
- scenarios_required: true
- ask_before_changing_existing: true
- fail_first_evidence: true

### red-green
- fail_first_evidence: true

### self-audit
- on_finding: fix-before-proceed

### structural
- threshold: crap <= 8
- on_violation: refactor-before-proceed

### mutation
- mode: differential
- max_workers: 3
- on_survivors: cover-and-kill
```

### Resolution order

```
Per-task contract "Verification" field
  > Per-issue ## Verification Profile section
    > .shiplog/verification.md default
      > Built-in default (none)
        > Silent (no enforcement)
```

Each level can **tighten** the parent but not relax it. A per-issue override can add `mutation` to a project that defaults to `behavior-spec`, but cannot remove `behavior-spec` from an issue where the project requires it.

### Per-issue override

Add a `## Verification Profile` section to the issue body:

```markdown
## Verification Profile
behavior-spec, red-green, structural

### Overrides
- structural.threshold: crap <= 5
- mutation: opt-in (only for auth module)
```

### Per-task override

In the task contract (see `brainstorm.md` issue template), the **Verification** field specifies what the implementer must check. This is the most granular level — it tells the agent exactly what to run and what evidence to produce.

### Surfacing during handoffs

When a verification profile is active, handoff comments (see model-routing.md) SHOULD include the active profile so the receiving agent knows what verification is expected:

```markdown
### Verification
- **Active profile:** behavior-spec, red-green
- **What to run:** [specific commands or checks]
- **Evidence required:** [what to log in the commit context]
```

---

## 3. Behavior-Spec Protocol

The `behavior-spec` profile requires acceptance scenarios for new or changed behavior before implementation begins.

### Scenario lifecycle

```
1. Write scenarios    — describe expected behavior in plain language
2. Confirm failure    — verify the scenario does not pass yet (fail-first)
3. Implement          — make the scenarios pass
4. Record evidence    — log which scenarios were added/changed/passed
```

### Scenario-change rules

| Situation | Required action |
|-----------|----------------|
| New behavior | Write new acceptance scenarios before implementation |
| Changed behavior | Identify affected existing scenarios first |
| Modifying existing scenarios | Ask before changing — document why the old expectation is wrong |
| Removing scenarios | Escalate — removing a scenario weakens the safety net |

**The ask-before-changing rule** applies when an existing scenario needs modification. The agent must flag the change to the user (or higher-tier model) and document the reason. This prevents silent behavior redefinition.

### Fail-first evidence

When `fail_first_evidence: true`:

1. Run the new or changed scenario before implementation.
2. Confirm it fails for the expected reason.
3. Record the failure output as evidence (in the commit context or issue timeline).
4. Implement until the scenario passes.

Fail-first confirmation is part of the verification evidence, not a debugging step. It proves the scenario is testing the right thing.

### When scenarios are not practical

Some changes (documentation-only, config changes, template updates) may not have testable behavior. In this case:

- Log `Verification: behavior-spec — not applicable (docs-only change)` in the commit context.
- The profile does not block — it just requires the exemption to be explicit.

---

## 4. Evidence in Artifacts

When a verification profile is active, shiplog artifacts MUST record what verification was performed.

### Commit-context evidence

Add to the Phase 4 commit context comment:

```markdown
**Verification:**
- **Profile:** behavior-spec, red-green
- **Scenarios:** [added N, changed M, existing passed K]
- **Tests:** [added N, changed M, all passing]
- **Deferred:** [anything intentionally skipped, with reason]
```

When no profile is active, the existing `**Verification:** [What was checked, what was deferred, or "Not run"]` field from the commit context template is sufficient.

### PR-timeline evidence

Add to the Phase 5 PR timeline Testing section:

```markdown
## Testing

**Verification profile:** behavior-spec, red-green

- [x] Acceptance scenarios added for [new behavior]
- [x] Fail-first confirmed before implementation
- [x] All new tests passing
- [x] All existing tests passing (no scenarios modified)
- [ ] Structural analysis: deferred (no structural profile active)

**Verification summary:**
- Scenarios added: N
- Tests added: N
- Tests modified: M (reason: [why])
- Existing scenarios changed: 0
```

### What to capture

| Evidence type | When to log | Where |
|---------------|-------------|-------|
| Active profile | Every commit context, every PR | Commit comment, PR body |
| Scenarios added/changed | When behavior-spec is active | Commit comment |
| Fail-first output | When fail_first_evidence is true | Commit comment or issue timeline |
| Test results summary | Every commit with test changes | Commit comment |
| Existing scenarios modified | Always — this is a change signal | Commit comment + issue timeline |
| Deferred verification | When something was intentionally skipped | Commit comment, PR body |
| Self-audit findings | When self-audit is active | Commit comment |
| Structural analysis results | When structural profile is active | PR body |
| Mutation results | When mutation profile is active | PR body |

### Recording modifications to existing tests

When existing tests or scenarios are modified, the evidence must explain why:

```markdown
**Existing scenarios changed:** 1
- `test_auth_token_expiry`: updated expected TTL from 3600 to 7200 — requirement changed per #42
```

This makes behavior drift traceable. If a reviewer sees modified scenarios without explanation, that is a review finding.

---

## 5. Self-Audit Protocol

The `self-audit` profile requires the agent to review its own diff for implementation quality issues before committing. This catches redundancy, dead code, and missed simplifications before they reach the cross-model review gate.

### Scope

Only files changed in the current branch compared to the base branch — the same scoping as `structural`.

### Review checklist

The agent reviews its diff against these questions:

1. **Simpler approach?** Is there a better or simpler way to achieve the same result?
2. **Redundant code?** Does any redundant code remain — copy-pasted blocks, near-duplicate logic?
3. **Duplicate logic?** Was logic introduced that could reuse an existing function or utility in the codebase?
4. **Dead code?** Is there dead or unused code left behind — unreachable branches, unused imports, orphaned helpers?

If findings exist, the agent acts according to the `on_finding` setting. If no issues are found, the agent briefly confirms the implementation is clean and proceeds.

### Configuration

```markdown
### self-audit
- on_finding: fix-before-proceed | warn | log
```

| `on_finding` | Behavior |
|--------------|----------|
| `fix-before-proceed` | Agent must fix issues before committing (default) |
| `warn` | Log findings in the commit context, continue |
| `log` | Record silently in verification evidence |

**Default:** `fix-before-proceed` — issues are resolved inline before the commit happens.

### Execution order

When composed with other profiles, `self-audit` runs **first** — fix quality issues before verifying behavior. A clean implementation produces more meaningful test results.

```
self-audit → behavior-spec → red-green → structural → mutation
```

### When not applicable

Documentation-only, config-only, or template-only changes may not benefit from self-audit. In this case:

- Log `Self-audit: not applicable (docs-only change)` in the commit context.
- The profile does not block — it just requires the exemption to be explicit.

### Self-audit evidence

In the commit context:

```markdown
- **Self-audit:** clean | N findings fixed | not applicable (reason)
```

When `on_finding` is `warn` or `log`, include the findings:

```markdown
- **Self-audit:** 2 findings (warn)
  - Unused import `parseConfig` in `src/auth.ts`
  - Near-duplicate validation logic in `handleLogin` / `handleRegister`
```

---

## 6. Structural and Mutation Gates

### Structural analysis

The `structural` profile runs quality analysis on changed modules.

**Changed module identification:** A module is "changed" if any file in its directory tree was modified in the current branch compared to the base branch.

**Threshold configuration:**

```markdown
### structural
- threshold: crap <= 8
- analyzer: [tool-agnostic — the language skill provides the command]
- on_violation: refactor-before-proceed | warn | log
```

| `on_violation` | Behavior |
|----------------|----------|
| `refactor-before-proceed` | Agent must reduce complexity before continuing |
| `warn` | Log the violation in the commit context, continue |
| `log` | Record silently in verification evidence |

**Default:** `warn` — violations are visible but do not block progress.

### Mutation testing

The `mutation` profile runs differential mutation testing on changed modules.

**Differential scope:** Only mutate lines that were added or modified in the current branch. This keeps mutation cost proportional to the change size.

**Configuration:**

```markdown
### mutation
- mode: differential | full
- max_workers: 3
- batch_size: 1 module at a time
- on_survivors: cover-and-kill | warn | log
```

| Field | Description |
|-------|-------------|
| `mode` | `differential` mutates only changed lines; `full` mutates the entire changed module |
| `max_workers` | Maximum parallel mutation processes |
| `batch_size` | How many modules to mutate at once (default: 1 — sequential) |
| `on_survivors` | What to do when mutations survive |

| `on_survivors` | Behavior |
|----------------|----------|
| `cover-and-kill` | Agent must write tests to kill surviving mutants before continuing |
| `warn` | Log survivors in commit context, continue |
| `log` | Record silently in verification evidence |

**Default:** `warn`.

### Mutation opt-in rules

- Mutation is **never** the default profile. It must be explicitly activated per-project or per-issue.
- `mode: differential` is the recommended starting point — full-module mutation is expensive.
- Mutation results appear in the PR body, not individual commit comments (too noisy per-commit).

### Batching guidance

When multiple modules are changed:

1. Process one module at a time (default `batch_size: 1`).
2. Run structural analysis first, mutation second.
3. If structural violations exist, resolve them before running mutation (cleaner code mutates more meaningfully).
4. Log per-module results in the PR verification summary.

```markdown
**Mutation summary:**
| Module | Mutants | Killed | Survived | Coverage |
|--------|---------|--------|----------|----------|
| auth/  | 24      | 22     | 2        | 91.7%    |
| api/   | 18      | 18     | 0        | 100%     |
```

---

## Integration Points

### With contract fields (task templates)

Task contracts should reference the active profile in the **Verification** field:

```markdown
- **Verification:** Run behavior-spec scenarios + red-green tests for changed auth module. Profile: `behavior-spec, red-green`. Evidence: scenario count, fail-first log, test results.
```

### With delegation (model-routing.md)

Delegated agents inherit the active verification profile. The handoff contract must state:
- Which profile is active
- What the agent must run
- What evidence to produce in the return artifact

A delegated agent MUST NOT silently weaken existing tests or scenarios. If a test change is needed, the agent should stop and escalate per the behavior-spec scenario-change rules.

### With artifact envelopes (artifact-envelopes.md)

Verification evidence artifacts should carry an envelope with `kind: verification` and `profile: <name>` so retrieval can quickly find what was verified.
