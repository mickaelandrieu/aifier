# templates/

Files `init` renders into a target project, with `{{ }}` placeholders filled from `aifier.yml`.
Blocks between `{{#list}}` and `{{/list}}` repeat per item.

| Template | Rendered as | Role |
|---|---|---|
| `AGENTS.md` | `AGENTS.md` | the constitution: a map, rules everywhere, delegation scope, gates |
| `AREA_AGENTS.md` | `<area>/AGENTS.md` | one guide per area, filled from the existing context or by `/context` |
| `CLAUDE.md` | `CLAUDE.md` | one-line include so Claude Code reads the constitution |
| `aifier.yml` | `aifier.yml` | the cycle configuration |
| `github/ISSUE_TEMPLATE_change.yml` | `.github/ISSUE_TEMPLATE/change.yml` | two-audience issue |
| `github/PULL_REQUEST_TEMPLATE.md` | `.github/PULL_REQUEST_TEMPLATE.md` | PR with a Verification Run section |
| `memory/learned-rules.md` | `docs/learned-rules.md` | empty catalogue with the rule format |
| `memory/decisions-README.md`, `memory/0000-template.md` | `docs/decisions/` | decision journal |
| `memory/handoff.md` | `docs/handoff.md` | session handoff |

An existing `AGENTS.md` or `CLAUDE.md` is never overwritten: `init` shows the difference and
offers merge, side file or skip. On merge, `init` redistributes the existing content between the
constitution and the area guides; `/context` later audits what is stale or duplicated.
