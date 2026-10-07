---
name: adversarial-test-plan
description: Adversarial QA for a completed {{project}} feature — attack categories, numbered test plan format, strict verdicts, defect severity levels, and the PLAN versus EXECUTE mode boundary.
---
<!-- placeholders: {{project}} -->

Try to break the feature before a user does. Every attack category is mandatory; skipping one means
the feature is untested in that dimension.

## Modes

The caller states the mode. Default to `PLAN`.

- **PLAN** — produce the numbered test plan below and stop. Do not execute. The plan is reviewed by
  a human, then handed back.
- **EXECUTE** — run an approved plan, test by test, and produce the report. Never execute a plan
  that was not returned to you after review.

Approval is a mode boundary, not an inline wait: an agent cannot pause mid-run, so the two modes
are two separate invocations.

## Attack categories

| Category | What you attack | Examples |
|---|---|---|
| Happy path | The basic contract | Create, read, update, delete with valid data |
| Input abuse | Every field with hostile input | Empty, whitespace only, 10 000 characters, script tags, SQL fragments, null bytes, combining characters, emoji only, right-to-left text |
| Boundaries | Limits and edges | 0, 1, max, max+1 items; min, max, max+1 length; first, last, only element |
| State corruption | Reaching invalid states | Double submit, edit while creating, delete while editing, navigate away or reload mid-operation |
| Concurrency | Two actors on one resource | Same action from two sessions, overlapping retries, out-of-order responses, stale write after a newer one |
| Persistence | Does it really save? | Create, edit, delete, reorder, then reload and verify from scratch |
| Validation bypass | Submitting what the UI forbids | Remove `disabled` and `required` in the DOM, call the API with malformed payloads |
| Authorisation | Acting as the wrong caller | Another user's resource id, a lower role, an expired or missing token, a revoked key |
| Error recovery | When the backend misbehaves | Network loss, 500, timeout, malformed response |
| Interaction chaos | Unexpected user behaviour | Rapid clicks, Enter in the wrong field, tab order, browser back and forward |
| Security surface | Injection and leakage | Stored script, prompt injection in model-facing fields, hidden characters, secrets in responses |

## Plan format

```
## Adversarial Test Plan — <feature> (#N)

T-01 · <category> · <title>
  Pre-conditions: <state that must exist>
  Steps: 1. ... 2. ... (click by click, character by character)
  Expected: <precise: "error X appears below field Y, submit becomes disabled">
  Verify by: screenshot | DOM state | network request | API response | database row
T-02 · ...
```

Precise expectations only. "It works" is not an expectation.

## Execution protocol

Before every interaction: capture the current state, identify the exact element, confirm
pre-conditions. After every action: capture evidence (screenshot or raw output), re-read the state,
check console errors, check the network call if the action triggers one.

During execution, always:

- fill a field, click away and back: does the value persist?
- repeat a successful operation immediately;
- open a modal and press Escape: does state stay clean?
- after any save, reload and verify from scratch; never trust client state;
- after a delete, verify the item is gone, not hidden;
- type into fields that should be read-only;
- strip DOM guards and submit anyway.

## Verdicts per test

| Verdict | Criteria |
|---|---|
| PASS | Matches the expectation exactly, proven by captured evidence, after you actively tried to break it |
| FAIL | Any deviation, however small |
| CONDITIONAL PASS | Works, but something could not be verified; document what and why. A risk flag, not a pass |
| BLOCKED | Could not execute; document the blocker. A risk, not a pass |

## Defect severity

| Severity | Definition | Example |
|---|---|---|
| S0 CRITICAL | Data loss, security breach, crash | Delete without confirmation; stored script executes; app crash |
| S1 BUG | Feature broken or wrong | Save does nothing; validation missing; data not persisted |
| S2 DEFECT | Incorrect, not catastrophic | Wrong message; wrong count; order lost |
| S3 UX | Usable but confusing | No loading state; no success feedback; ambiguous label |
| S4 SMELL | Works today, breaks tomorrow | Hard-coded value; missing edge case; fragile layout |

## Defect format

```
### [S1] D-03 — <title>
Test: T-07
Steps: 1. ... 2. ...
Expected: ...
Actual: ...
Evidence: <screenshot or raw output>
Impact: <who, how>
Suggested fix: <direction, not implementation>
```

## Final report

```
## QA Adversarial Report — <feature> (#N)
Environment: <url, date, branch or commit>
Verdict: REJECTED | APPROVED WITH RESERVATIONS | APPROVED
Tests: X · PASS X · FAIL X · CONDITIONAL X · BLOCKED X
Defects: S0 X · S1 X · S2 X · S3 X · S4 X
### Results      (table: id, test, verdict, defects, notes)
### Defects      (ordered by severity)
### Untested risks   (unknowns, never passes)
### Recommendations  (what to test next, what smells wrong)
```

`REJECTED` on any S0 or S1. `APPROVED WITH RESERVATIONS` with only S2 and below, conditions
listed. `APPROVED` only when you genuinely could not break it.
