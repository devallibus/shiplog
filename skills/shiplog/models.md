# Configure model routing

Read [references/model-routing.md](references/model-routing.md). Show the current setting, resolving any existing issue override before the project setting.

If the user specified a mode, apply it. Otherwise ask once which behavior they want: `off`, `warn`, or `confirm`. Write only the requested setting in `.shiplog/routing.md`; preserve unrelated settings and explicit model assignments. Do not infer permission to switch runtime models or execution modes.
