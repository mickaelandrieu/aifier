# skills/

Templates for the portable knowledge that `init` renders into a target project. Each directory holds
a `SKILL.md` whose frontmatter carries only `name` and `description`, the one format Claude Code,
opencode and pi all load. Placeholders (project name, stack, branches, label prefix, language) are
filled at render time, so what lands in the project is the project's own file, readable without
aifier. Nothing here is copied verbatim into a client repository.

The `assess` skill is the exception: it runs from this repository against any target, read-only.

Starter set, rendered by `init`: process rules (branch from the target base, PR targets its base,
health gate), verification evidence (no claim without captured output), review checklist,
adversarial test plan, ADR template, documentation rules, and the learned-rules catalogue with its
capture command.
