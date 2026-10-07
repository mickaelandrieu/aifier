# {{project}} — guidance for AI agents

{{project_summary}}

This file is a map; the rules of each area live in its guide.

| Area | Directory | Read first |
|---|---|---|
{{#areas}}| {{stack}} | `{{dir}}/` | [{{dir}}/AGENTS.md]({{dir}}/AGENTS.md) |
{{/areas}}

Memory: [learned rules]({{memory.rules}}) (read before building or reviewing),
[decisions]({{memory.decisions}}) (ADRs), [session handoff]({{memory.handoff}}) (read at session
start, update before stopping). Configuration of the cycle: [aifier.yml](aifier.yml).

## Rules that apply everywhere

1. Match the surrounding code: naming, structure, idioms. Leave it better, stay in scope.
2. Tests are part of the change. A fix or a feature lands with the tests that prove it.
3. No claim without proof. Every deliverable ends with a `## Verification Run` section quoting
   the gate commands and their captured output, or `BLOCKED` with the reason. Never write "tests
   pass" from memory.
4. Never skip the gates. Hook-bypass flags are not available to agents.
5. Secrets come from the environment only. Never put keys or passwords in code, docs or logs.
6. Branch from `{{target_branch}}`, one slice per pull request, conventional commit subjects
   (`type(scope): description`), the pull request references its issue.

## What agents do not do

- decide the intent of an issue: an issue is built only once a human has validated its problem,
  impact and acceptance criteria;
- choose an architecture on their own: a change that touches more than one area or introduces
  a dependency, a data model or a migration is planned as two or three approaches, and a human picks;
- merge, approve their own pull request, or set it as ready; a human merges;
{{#protected_paths}}- touch `{{path}}` without an approved plan;
{{/protected_paths}}

## Gates

Lines whose gate is `null` in `aifier.yml` are omitted; say which family is missing.

{{#areas}}From `{{dir}}/`:

```bash
{{gates.lint}}
{{gates.typecheck}}
{{gates.test}}
{{gates.build}}
```

{{/areas}}
