# Brainstorm Workflow

<!-- Based on superpowers:brainstorming (MIT, see LICENSES/superpowers-MIT.txt) -->
<!-- Internalized for shiplog convention enforcement -->

Turn ideas into fully formed designs through collaborative dialogue, then capture them as **shiplog** issues with structured task contracts.

## Hard Gate

Do NOT write code, scaffold, or take any implementation action until a design is presented and the user approves it. Every project goes through this process regardless of perceived simplicity.

## Process

```
User says "let's brainstorm / plan / design"
  |
  v
1. Explore project context (files, docs, recent commits)
  |
  v
2. Ask clarifying questions — one at a time, multiple choice preferred
  |
  v
3. Propose 2-3 approaches with trade-offs and a recommendation
  |
  v
4. Present design in sections, get approval after each section
  |
  v
5. Capture as shiplog issue (see Issue Capture below)
  |
  v
6. Transition to shiplog Phase 2 (branch setup) if user wants to start work
```

Steps 1-4 follow the same collaborative dialogue process as `superpowers:brainstorming` or `ork:brainstorming`. Either may be used for the exploration phase. The difference is in steps 5-6: output MUST be captured as a **shiplog** issue, not as a spec file.

## Design Principles

- **One question at a time.** Do not overwhelm with multiple questions.
- **Multiple choice preferred.** Easier to answer than open-ended.
- **YAGNI ruthlessly.** Remove unnecessary features.
- **Explore alternatives.** Always propose 2-3 approaches before settling.
- **Incremental validation.** Present design sections, get approval before moving on.
- **Design for isolation.** Break the system into units with one clear purpose, well-defined interfaces, and independent testability.

## Working in Existing Codebases

Explore the current structure before proposing changes. Follow existing patterns. Where existing code has problems that affect the work, include targeted improvements as part of the design. Do not propose unrelated refactoring.

## Scope Check

Before asking detailed questions, assess scope. If the request describes multiple independent subsystems, flag this immediately. Help the user decompose into sub-projects, each getting its own issue through the brainstorm workflow. Build the first sub-project through the normal flow.

## Claim Verification

Before writing the final issue body, classify factual claims:

- **Internal claims** about the repository's code, tests, or committed docs — verify from the repo itself.
- **External claims** about third-party tools, APIs, platform capabilities — verify against primary sources before stating as fact.
- **Unverified claims** — mark explicitly as `[unverified]` and treat as hypotheses.

## Issue Capture

Once the design is approved, create a **shiplog** issue using the template in `../brainstorm.md`. The issue body MUST include:

1. **Envelope metadata** — `<!-- shiplog: kind: state ... -->` block
2. **Context, Design Summary, Approach, Alternatives** — from the brainstorm
3. **Sources and Verification Status** — for external claims
4. **Task contracts** — structured `T1`, `T2`, ... with tier annotations, file lists, acceptance criteria, and decision budgets per `../brainstorm.md`
5. **Provenance signature** — `Authored-by:` per `signing.md`
6. **Label** — `shiplog/plan` applied at creation time

Bootstrap **shiplog** labels first if this is the first labeled create in the repo (see `labels.md`). Use the portable `--body-file` pattern from `shell-portability.md` for the issue body.

## Transition

After issue creation:
- Store key decisions in the knowledge graph if `ork:remember` is available.
- Offer to proceed to Phase 2 (branch setup via `shiplog:branch`).
- Do NOT invoke `superpowers:writing-plans` or any implementation skill.

## Visual Companion

If `superpowers:brainstorming` is available and offers a visual companion (browser-based mockups), it may be used during the exploration phase (steps 1-4). The visual companion is a tool for understanding, not an output format — the final output is always a **shiplog** issue.

## When to Use External Skills

| Scenario | Use |
|----------|-----|
| Standard brainstorm | This workflow (steps 1-6) |
| Need parallel agent exploration | Delegate steps 1-4 to `ork:brainstorming`, then return here for steps 5-6 |
| Need visual mockups | Use `superpowers:brainstorming` visual companion during steps 1-4, then return here for steps 5-6 |
| Quick inline discussion | Skip delegation, brainstorm inline, still capture via steps 5-6 |
