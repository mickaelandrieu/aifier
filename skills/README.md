# skills/

Portable knowledge, one directory per skill, each with a `SKILL.md` whose frontmatter carries only
`name` and `description`. This is the single unit that Claude Code, opencode and pi all load, so it
is the only place where method knowledge lives. Adapters in `adapters/` reference these files; they
never copy them.

Planned starter set: process rules (branching, PR target, health gate), verification evidence (no
claim without captured output), review checklist, adversarial test plan, ADR template, documentation
rules, and the learned-rules catalogue with its capture command.
