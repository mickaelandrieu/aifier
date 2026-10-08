---
name: verification-evidence
description: The proof discipline for agents working on docs-only — never claim a gate passed without its captured output, end every deliverable with a Verification Run section, report BLOCKED with the reason when a check cannot run, and never mark work ready on a self-report.
---
<!-- gate commands are those of `root` -->

Every claim of success is backed by the captured real output of the command that proves it. Nobody
reading your deliverable should have to trust your word.

## The rule

- Never write "tests pass", "all green", "validated", "works now", "looks good" or "confirmed"
  unless the exact command that establishes it, and the tail of its real output, is in the
  deliverable.
- A check that cannot run in the current environment is `BLOCKED: <reason>`. Never `PASS`, never
  silent, never "pre-existing" or "unrelated".
- Never substitute a weaker proxy for the real check while implying the real one ran: a type check
  instead of running the test, listing the specs instead of executing them, inspecting bytes
  instead of opening the artifact, a green unit suite instead of exercising the live path.
- A collection error, a non-zero exit with nothing executed, or "collected N items" with no run is
  `BLOCKED`, not a pass.

## Environment preflight

Run the preflight before trusting any gate result, and cite it:

1. Confirm the toolchain the gate expects (interpreter, package manager, lockfile) is the one
   installed and resolvable from the project root.
2. Confirm the services a gate needs (database, broker, browser) are reachable, or declare the gate
   `BLOCKED` before running it.
3. Confirm the gate ran on the full intended scope: no stale failure cache, no `--last-failed`
   shortcut, no filtered subset presented as the whole suite.
4. Confirm the branch and working tree are the ones you believe (`git branch --show-current`,
   `git status --porcelain`) before attributing a result to a change.

A result produced without preflight is unverified, whatever its colour.

## Mandatory deliverable section

Every developer, reviewer, QA and validator deliverable ends with:

```
## Verification Run
$ <exact command 1>            → <verdict + output tail>
$ <exact command 2>            → <verdict + output tail>
<check that could not run>     → BLOCKED: <reason> (who must run it, where)
```

Example:

```
## Verification Run
Integration tests: BLOCKED — database unreachable (DB_HOST unset). Must run in CI before merge.
```

Browser or artifact validation:

```
## Verification Run
Drove the real flow (not a mock): <what you did, step by step>
Network: POST /api/orders → 201 with the expected body (screenshot attached)
Console: no errors after the critical action
```

## Verdicts

- `OK` — every applicable gate ran on the intended scope and its output is attached.
- `FAIL` — at least one gate ran and failed; attach the failing output, not a summary.
- `BLOCKED` — at least one gate could not run; name the gate, the reason, and who can run it.

A deliverable with any `BLOCKED` line is not "ready"; it is "ready pending <gate> in CI".

## For orchestrators

- A sub-agent success claim without a `## Verification Run` section is unverified. Do not forward
  it, do not act on it, do not relabel on it.
- Cross-check against ground truth before proceeding: re-run the gate yourself or open the artifact
  the sub-agent says it produced.
- Never apply a terminal success label (`sdlc:done`, `sdlc:pr:ok`) on a
  self-report. The label is set by whoever verified the evidence, never by the author of the work
  or an agent the author launched.

## The "break it" pass

Before declaring a user-facing change done, exercise the real deliverable, not the happy path:

- Open the actual artifact (rendered document, running UI) and inspect it. Byte, schema and type
  checks are necessary, not sufficient.
- Feed boundary and hostile input: 0, negative, empty, oversized, wrong type, unauthorised role.
- Exercise at least one error path and one undo or rollback path.
- Reproduce the user's real conditions. Synthetic actions can mask a bug: programmatic clicks that
  generate traffic hide an idle timeout a real user would hit.
