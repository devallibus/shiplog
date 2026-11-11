# Signatures

Model signatures are optional. Add them only when the project requires them. `review: cross-model` does: its gate fails unless commits declare their authors with `Authored-by:` or `Co-Authored-By:` trailers. Review evidence always carries one; [closure-and-review.md](closure-and-review.md) owns that format. Speaker and source attribution on copied discussion is a separate rule in [records.md](records.md).

Put each signature on its own line at the end of the artifact:

```text
<role>: <family>/<version> (<tool>[, qualifier])
```

`family` is the lowercase provider, `version` the model identifier, and `tool` the runtime. The optional qualifier is a short note such as `orchestrator` or `sub-agent: reviewer`.

Roles:

- `Authored-by`: wrote the artifact.
- `Updated-by`: later changed its meaning, facts, scope, or results. Append it below the existing lines, newest last. Cosmetic fixes need none.
- `Reviewed-by`: wrote a review. Use it for nothing else.
- `Last-code-by`: most recent code author on a PR branch. This is a historical field; read it where present and add it only if the project still uses it.

A signature declares identity; it does not prove it. It is not, by itself, evidence of independence or approval.

Never rewrite, remove, or normalize historical signatures, including old model names and formats.
