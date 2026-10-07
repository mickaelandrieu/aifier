# adapters/

Generators that turn one manifest (`aifier.yml` plus the skills) into the host-specific layout:
`.claude/` for Claude Code, `.opencode/` for opencode, prompt templates for pi. Generated files carry
a header saying they are generated and must not be edited by hand; the source of truth stays in
`skills/` and `aifier.yml`.

Hooks and per-user settings are host-specific and out of scope for the first version.
