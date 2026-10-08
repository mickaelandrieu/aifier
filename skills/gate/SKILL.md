---
name: gate
description: Where an issue stands in the cycle of {{project}}, in one line - not-qualified, needs-input, proposed, qualified, qualified (partial), planned, chosen, in-progress, done - decided by one script from the issue body, its labels, its comments and the open pull requests. The one place the gate decision is written; qualify, plan and build act on its output. Argument - an issue number or URL.
---
<!-- placeholders: {{project}} {{repo}} {{label_prefix}} -->

You are running `gate`. It is cheap and read-only: run the script, show its line, add nothing
you did not read.

```bash
bash "<directory of this SKILL.md>/gate.sh" N --repo {{repo}} --prefix {{label_prefix}}
```

`N` is the issue number or its URL, passed as given: the script takes the number from the URL
(without its fragment, query or trailing slash). No argument: ask for one and stop. The script
needs `gh`, `jq` and a repository (`--repo`, or `repo:` in `aifier.yml`) and checks them itself;
when it exits non-zero it has printed `BLOCKED: <reason>`: repeat that line and stop. When the
script cannot be started at all, print `BLOCKED: gate.sh could not run (<reason>)` and stop.
Never decide the state from the issue yourself.

What it prints, one line: `state: <state> (shape: ok|missing, labels: <the {{label_prefix}}:*
labels>, contract reply: ok by <login> on <date>|none, plan comment: <which|none>, approach
reply: <letter> by <login> on <date>|none, open PR: #M|none)`. The parenthesis names the facts
the state rests on, so the line can be quoted as proof.

A **human login** is one not ending in `[bot]` or `-bot` and not `github-actions` or
`dependabot`. The states, and what each one means for the next step:

| State | Facts | Next |
|---|---|---|
| `in-progress` | label `{{label_prefix}}:in-progress`, or an open pull request of `{{repo}}` that closes the issue or names `#N` as a word outside backticks and code fences | `build` continues on that branch only if the person confirms |
| `done` | label `{{label_prefix}}:done` | nothing: the issue was closed by the cycle |
| `not-qualified` | body without the contract shape (`## Problem`, `## Impact`, `## Acceptance criteria`, a `<details>` whose summary is `Technical analysis`), or shape without any `{{label_prefix}}:*` label | `/qualify N` |
| `chosen <letter>` | a comment whose first line is `approach: <letter>` (any case, printed upper-cased), by a human login, posted after the latest plan comment (a comment holding a `## Plan` line) | `/build N` |
| `planned` | a plan comment and no such reply | wait for the human `approach:` reply |
| `needs-input` | label `{{label_prefix}}:needs-input` and no plan | the author answers the open questions |
| `qualified` | label `{{label_prefix}}:todo` and a comment whose first line is `contract: ok` (any case) by a human login: the intent gate is crossed | `/plan N` |
| `proposed` | label `{{label_prefix}}:todo` without that comment: the contract is posted, the author has not confirmed it | wait for the human `contract: ok` reply |
| `qualified (partial)` | label `{{label_prefix}}:partial` and not `{{label_prefix}}:todo` (a previous slice landed) | `/build N` for the next slice |

The states are decided in the order of the table: in-progress wins over everything; `done` wins
over everything but in-progress; then a body without shape or without any `{{label_prefix}}:*`
label is not-qualified whatever its comments; then a reply wins over a plan, a plan over
`needs-input`, `needs-input` over `todo`, `todo` (qualified or proposed, by the `contract: ok`
reply) over `partial`. The intent gate and the architecture gate are both human signals read
from comments: `contract: ok` and `approach: <letter>`; agents never write either.

Offline, for tests and fixtures: `gate.sh --from <payload.json> [--repo owner/name]` decides from
a saved payload of the shape documented at the top of the script, without `gh`; `--repo` then
only filters the closing references of the pull requests.
