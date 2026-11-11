# Commit

Inspect the diff and stage only intended files. Use the project's commit convention. When there is no required format, an issue reference such as `fix(#42): preserve source text` makes retrieval easier. Task IDs are optional and useful for partial delivery.

Explain a non-obvious reason in the commit body or link to its existing record. Run relevant project checks and state gaps honestly. Use `git commit -F FILE` for multiline messages. Do not bypass hooks unless the user has authorized it.

Do not post a comment for each significant commit by default. At the next [capture checkpoint](timeline.md), preserve new human discussion and reasoning that is not already recorded. Model signatures are optional unless the project requires them; see [references/signing.md](references/signing.md).
