# docs-only — guidance for AI agents

{{project_summary}}

This file is a map; the rules of each area live in its guide.

One area, the repository root.

Memory: [learned rules](docs/learned-rules.md) (read before building or reviewing),
[decisions](docs/decisions) (ADRs), [session handoff](docs/handoff.md) (read at session
start, update before stopping). Configuration of the cycle: [aifier.yml](aifier.yml).

## Rules that apply everywhere

1. Match the surrounding code: naming, structure, idioms. Leave it better, stay in scope.
2. Tests are part of the change. A fix or a feature lands with the tests that prove it.
3. No claim without proof: see the `verification-evidence` skill.
4. Never skip the gates. Never pass `--no-verify` or any flag that skips a hook or a check.
5. Secrets come from the environment only. Never put keys or passwords in code, docs or logs.
6. Branch from `main`, one slice per pull request: see `process-rules` PR-001 and PR-002.

## What agents do not do

- decide the intent of an issue: an issue is built only once a human has validated its problem,
  impact and acceptance criteria;
- choose an architecture on their own: a change that touches more than one area or introduces
  a dependency, a data model or a migration is planned as two or three approaches, and a human picks;
- merge, approve their own pull request, or set it as ready; a human merges;

## Gates

From the root:

```bash
```

