# adapters/

Generators that turn one manifest (`aifier.yml` plus the rendered skills) into each host's layout.
Generated files carry a header saying they are generated and must not be edited by hand; the source
of truth stays in `skills/` and `aifier.yml`.

| Host | Skills | Commands and agents | Hooks |
|---|---|---|---|
| Claude Code | `.claude/skills/` or `.agents/skills/` | `.claude/agents/*.md` | shell commands in `settings.json`: `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart` |
| opencode | `.agents/skills/` | `.opencode/commands/*.md`, `.opencode/agents/*.md` | TypeScript plugins in `.opencode/plugins/`: `tool.execute.before`, `tool.execute.after`, `session.idle` ([docs](https://opencode.ai/docs/plugins/)) |
| pi | agentskills format | prompt templates | TypeScript extensions in `.pi/extensions/`: `tool_call`, `turn_start`, `session_start` ([docs](https://cdn.jsdelivr.net/npm/@earendil-works/pi-coding-agent@0.81.1/docs/extensions.md)) |

Base hooks are defined once, abstractly (remind the verification run before a stop, refuse a merge
command, load the constitution at session start), and rendered per host. Per-user settings are not
generated.
