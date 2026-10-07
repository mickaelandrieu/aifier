---
name: gate
description: Where an issue stands in the cycle of {{project}}, in one line - not-qualified, needs-input, qualified, qualified (partial), planned, chosen, in-progress - decided by one script from the issue body, its labels, its comments and the open pull requests. The one place the gate decision is written; qualify, plan and build act on its output. Argument - an issue number or URL.
---
<!-- placeholders: {{project}} {{repo}} {{label_prefix}} -->

You are running `gate`. It is cheap and read-only: run the script, show its line, add nothing
you did not read.

```bash
bash "<directory of this SKILL.md>/gate.sh" N --repo {{repo}} --prefix {{label_prefix}}
```

`N` is the issue number or its URL, passed as given: the script takes the number from the URL. No
argument: ask for one and stop. The script needs `gh` and `jq` and checks them itself; when it exits
non-zero it has printed `BLOCKED: <reason>`: repeat that line and stop. When the script cannot be
started at all, print `BLOCKED: gate.sh could not run (<reason>)` and stop. Never decide the state
from the issue yourself.

What it prints, one line: `state: <state> (shape: ok|missing, labels: <the {{label_prefix}}:*
labels>, plan comment: <which|none>, approach reply: <letter> by <login> on <date>|none, open PR:
#M|none)`. The parenthesis names the facts the state rests on, so the line can be quoted as proof.

The states, and what each one means for the next step:

| State | Facts | Next |
|---|---|---|
| `in-progress` | label `{{label_prefix}}:in-progress`, or an open pull request that closes the issue or names `#N` as a word | `build` continues on that branch only if the person confirms |
| `not-qualified` | body without the contract shape (`## Problem`, `## Impact`, `## Acceptance criteria`, a `<details>` whose summary is `Technical analysis`), or shape without any `{{label_prefix}}:*` label | `/qualify N` |
| `chosen <letter>` | a comment whose first line is `approach: <letter>`, by a login not ending in `[bot]`, posted after the latest plan comment (a comment holding a `## Plan` line) | `/build N` |
| `planned` | a plan comment and no such reply | wait for the human `approach:` reply |
| `needs-input` | label `{{label_prefix}}:needs-input` and no plan | the author answers the open questions |
| `qualified` | label `{{label_prefix}}:todo`; `qualified (partial)` when the label is `{{label_prefix}}:partial` and not `{{label_prefix}}:todo` (a previous slice landed) | `/plan N`, or `/build N` for the next slice of a partial issue |

The states are decided in the order of the table: in-progress wins over everything; then a body
without shape or without any `{{label_prefix}}:*` label is not-qualified whatever its comments;
then a reply wins over a plan, a plan over `needs-input`, `needs-input` over `todo`, `todo` over
`partial`. `{{label_prefix}}:done` is not a state the script decides yet: an issue carrying only
that label and no plan prints `not-qualified`, with the label visible in the parenthesis.

Offline, for tests and fixtures: `gate.sh --from <payload.json>` decides from a saved payload of
the shape documented at the top of the script, without `gh`.
