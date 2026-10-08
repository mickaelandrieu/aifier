---
name: review-checklist
description: Structured code review for {{project}} — read everything first, then check architecture, correctness, security, tests and consistency, apply the PR health gate, report with a drift level, and ask whether each finding should become a learned rule.
---
<!-- placeholders: {{project}} {{target_branch}} {{label_prefix}} {{gates.test}} {{memory.rules}} -->

Apply this checklist to every change under review. Every section of the report is mandatory: write
"N/A — reason" when a section does not apply, never leave it blank. Load `{{memory.rules}}` before
starting; a finding already covered by a rule is cited by its id.

## Phases

1. **Read.** Read every changed file in full, plus callers, consumers, tests and configuration that
   reference the changed symbols. For a change that crosses a boundary (API and client, producer
   and consumer), read both sides. Do not analyse before you have read everything.
2. **Health gate.** Check the PR state before judging the code (see below).
3. **Analyse.** Apply the checks in order. Address every item explicitly.
4. **Report.** Use the template. Finish with the learned-rule question.

## PR health gate

A PR with merge conflicts or at least one failing required check is never clean, whatever the
quality of its code. Verify both before any clean verdict:

- `gh pr view <PR> --json mergeable` is not `CONFLICTING`;
- `gh pr checks <PR>` reports no check with conclusion `FAILURE`.

If either fails: drift is at least `MEDIUM`, the verdict is `REQUEST CHANGES`, and the PR keeps
`{{label_prefix}}:pr:need-work`. Also confirm the PR targets `{{target_branch}}` and that
`git diff --stat {{target_branch}}...HEAD` contains only the intended change.

## Architecture

- Does each change sit at the lowest responsible layer, or does a guard at a high layer compensate
  for a defect in a lower one? Trace the data from producer to consumer.
- Are dependencies injected through the existing chain, never instantiated deep in a call stack?
- Does the business logic live where the project puts it, or did it leak into an adapter or
  an entry point?
- Are errors explicit, typed and propagated, never swallowed?
- Is the PR title problem-framed ("X is wrong when Y") rather than solution-framed
  ("preserve X in Z")?

## Correctness

- Walk every branch of the changed logic with a concrete input, including empty, missing, maximum
  and concurrent cases.
- Check state transitions: can the change leave data in a state the rest of the system does not
  expect?
- Check time, ordering and idempotence wherever the change retries, schedules or reconciles.
- Check that the change matches the issue's acceptance criteria, not a reinterpretation of them.

## Security

- Is every new entry point authenticated, and does it check that the caller may act on this
  resource, not only that the caller exists?
- Is user input validated at the boundary and parameterised before reaching a query, a shell or a
  file path? Are uploads validated by content, not by extension?
- Do errors, logs or responses leak secrets, stack traces or internal structure?
- Did a route's access widen to make a test pass?

## Tests: behaviour, not implementation

Coverage is necessary, not sufficient. For each new or modified test:

- Refactor test: if the internals were rewritten with the same public outcome, would the test
  still pass? If not, it is implementation-coupled.
- Does the name state a domain rule (`returns_top_50_by_cost`), not a call (`calls_repo_once`)?
- Are assertions on observable outcomes (returned value, response, rendered output) rather than on
  collaborator calls? A call assertion is legitimate only when the call is the contract (event
  publication, audit emission).
- Does the fixture rebuild the expected value with the SUT's own arithmetic (`x == x`)?
- Is the system under test mocked, or the very flag that carries the bug?
- For a bug fix: is there a regression test that fails without the fix?
- Are error paths and edge cases exercised, not only the happy path?

These are `REQUEST CHANGES` findings, not nits.

## Consistency

- Contract between sides: paths, methods, status codes, field names and error shapes match;
  authorisation enforced on the server and handled on the client.
- Naming, structure and idioms match the surrounding code.
- Documentation changed in the same PR when behaviour, configuration or commands changed.

## Report template

```
## Code Review — <title> (#N)

### Verdict: REQUEST CHANGES | APPROVE WITH COMMENTS | APPROVE
### Drift: NONE | LOW | MEDIUM | HIGH

Health gate: mergeable=<value> · failing checks=<none|list> · base=<branch>

### Architecture
### Correctness
### Security
### Tests
### Consistency
(each: findings with file:line, or "N/A — reason")

### Required actions before merge   (numbered, or "None.")
### Recommended follow-ups
### Commands to run                 ($ {{gates.test}} → exit code, last line; name the scope in words)
### Learned-rule candidates
- <finding> → repeatable pattern with a detection? yes: propose RULE / no: why not
```

## Verdict and drift

- `REQUEST CHANGES`: health gate failed, architecture violation, missing regression test on a fix,
  broken contract, silent error swallowing, implementation-coupled test.
- `APPROVE WITH COMMENTS`: no blocking finding, non-trivial observations to address soon.
- `APPROVE`: nothing to add; you read the code and the tests.
- Drift is the distance from the issue's contract and the project's rules: `NONE` on target; `LOW`
  cosmetic; `MEDIUM` a rule broken or a gate failing; `HIGH` the contract is not delivered or data,
  security or the release is endangered.

Last question, every time: **should any of these findings become a learned rule?** A pattern seen
twice is a hole in the system. Hand candidates to `/compound`.
