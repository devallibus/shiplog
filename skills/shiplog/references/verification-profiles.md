# Verification profiles

A project can name the checks a kind of task requires. The profile travels with the task, so whoever does the work, including a delegated agent, knows what to run and what evidence to report. Use this file only when `.shiplog/verification.md` exists or an issue names a profile. Without one, run the project's normal checks and report what was not run.

Profiles state policy, not tooling. The project's own scripts and language tools supply the commands.

## Configuration

```markdown
# Verification Profiles

## Default Profile
tests

## Profiles

### tests
- run: npm test
- evidence: the command and its result

### behavior
- run: npm test
- new or changed behavior needs a test that failed before the change
- ask before changing an existing test's expected result
```

Profile names and rules belong to the project. Write each rule so a reader can check whether it was followed. Older configurations that use names such as `behavior-spec` or `red-green` keep working; apply each listed setting as written.

## Resolution

Resolve the active profiles in this order: the checks named in the task, then a `## Verification Profile` section in the issue body, then the default in `.shiplog/verification.md`. A narrower level can add checks. It cannot remove checks the project requires.

```markdown
## Verification Profile
tests, behavior
```

## Use a profile

- Before work, put the active profile and its commands in the task or handoff.
- During work, do not weaken, skip, or delete an existing check to make it pass. If an existing expectation is wrong, stop and explain why before changing it.
- After work, report the profile, the commands run, their results, and anything skipped with the reason. Put this where checks are already recorded, such as the commit body, the PR verification section, or the current summary. Do not post an extra comment for it.
- When a check cannot run, for example because a tool is missing or the change is docs-only, say so. The work can continue, and the report names the unverified gap.

A delegated agent inherits the active profile and reports the same evidence. The orchestrator checks that evidence against the diff and test output before accepting the work.
