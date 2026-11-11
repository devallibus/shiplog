---
name: shiplog
description: Preserve project discussion, decisions, and work context in GitHub. Use when the user requests durable tracking, recalls past discussion, or continues tracked work across sessions.
---

# Shiplog

Keep the original discussion available for human recollection. Give the next agent a small, current account of the work. Use GitHub issues, PRs, and links; no separate memory service is required.

## When to use it

Use **shiplog** for requested project logging, planning with durable records, history lookup, and work on an existing tracked issue or PR. An idea can remain a discussion without a branch or delivery commitment. Ordinary small edits do not require a new issue. Follow the user's existing authorization and chosen location for published records.

## Three records

**Original discussion:** Preserve available human project messages verbatim and in order. Include enough assistant dialogue to understand references and answers. Keep rejected ideas, doubts, and preferences even when they do not affect implementation. Identify the original speaker separately from the account or agent that records the text. Never present an agent inference as a human decision.

Save discussion in batches at useful checkpoints and before a handoff or context reduction when the runtime exposes that event. Use source message IDs or a recorded message range to avoid duplicate capture. A link alone does not preserve the text. Do not invent unavailable history or promise complete capture when there are gaps. Add later corrections as linked entries; leave earlier wording intact.

**Current summary:** Keep one editable summary on the tracking issue: goal, constraints, current decisions, open questions, checks, and next action. Link important decisions to their source entries. Update this summary when facts change. Preserve source sections already present in older issue bodies. A PR describes the final change and links back to the discussion.

**Retrieval index:** Keep a small envelope on new records. Extract its fields before returning tool output to the model. Read selected original records when the question needs them. Use platform IDs, dates, and links instead of copying them into metadata. Compute task counts from the task section. Search original text when a summary does not answer a recollection question.

Read [references/records.md](references/records.md) when capturing or updating records. Read [references/artifact-envelopes.md](references/artifact-envelopes.md) when retrieving them. These files own their formats.

## Work with the record

Before starting or resuming, read the current summary and inspect the actual branch, changes, and linked PR. Resolve differences before claiming the summary is current. Follow project branch and commit conventions. Link commits and PRs to the issue where useful. A routine start, resume, or commit does not require another comment.

Record new decisions, useful failed approaches, blockers, checks, and remaining work at the next checkpoint. Record human discussion regardless of its coding value. Verify the real product path with the checks the project requires. Report checks that were not run. Close only the scope supported by evidence; partial delivery leaves remaining tasks open.

## Commands and natural-language requests

All procedures live inside this skill directory, so a skill-only install is complete. Resolve links relative to this file. Plugin slash commands are optional entry points to the same procedures.

| Request | Read |
|---|---|
| Plan or save an idea | [brainstorm.md](brainstorm.md) |
| Start tracked work | [branch.md](branch.md) |
| Capture discussion or a handoff | [timeline.md](timeline.md) |
| Handle a discovery | [discovery.md](discovery.md) |
| Commit | [commit.md](commit.md) |
| Open a PR | [pr.md](pr.md) |
| Find past discussion | [lookup.md](lookup.md) |
| Find next work | [hunt.md](hunt.md) |
| Resume | [resume.md](resume.md) |
| Review | [review.md](review.md) |
| Configure routing | [models.md](models.md) |

## Optional policy

Routing is off when unset. Preserve explicit settings; load [references/model-routing.md](references/model-routing.md) only for enabled routing or a requested change. Off means no routing prompts or mode changes.

Follow project review requirements using [references/closure-and-review.md](references/closure-and-review.md). Native GitHub reviews, configured Codex review, and attributed comments can provide evidence. Cross-model review is an explicit option. Model identity alone proves neither independence nor approval. Required checks and user authorization still govern merge.

Load [verification profiles](references/verification-profiles.md) only when configured and [quiet logging](references/pr-workflow.md) only when requested. Do not rewrite historical records during adoption. Read older formats as needed. Optional features must not add setup steps to the default workflow.
