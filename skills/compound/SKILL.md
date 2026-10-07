---
name: compound
description: Capture a lesson as a learned rule in {{project}} — Compound-1 (pre-release, from the work and reviews just done) or Compound-2 (from a production incident), with an admission criterion, de-duplication against the catalogue, and a fixed rule format. Argument - "this session", a PR number, a rule idea, or "incident: <description>".
---
<!-- placeholders: {{project}} {{memory.rules}} {{memory.handoff}} -->

Make the harness mechanically better after this run than before it. A bug seen twice is not a bug,
it is a hole in the system. Run inline in the main session; do not delegate.

## Modes

- **Compound-1** (default, phase 6, pre-release). Lessons from the work and reviews just completed.
  Triggers: end of a session, a review that surfaced a recurring pattern, a bug seen a second time.
- **Compound-2** (phase 9, from production). Lessons from an incident, postmortem, on-call finding
  or observability signal. Trigger: `$ARGUMENTS` starts with `incident:` or names an outage, a
  rollback, a runtime error or an alert.

Both persist to the same catalogue, `{{memory.rules}}`, which every agent loads at Plan, Build and
Review. The flow is identical from step 2 on.

## Step 1 — Gather candidates

Compound-1: from `$ARGUMENTS` (a session, a PR, a stated idea), collect recurring friction, review
findings not already covered by a rule, and every "we hit this before" moment.

Compound-2: read the incident description and anything linked (issue, log excerpt, monitoring
output). Reconstruct the chain: what broke at runtime, why the pre-release gates did not catch it,
and what rule or gate would have. An incident a static rule could have caught is the highest-value
rule to mint; say explicitly which gate it escaped.

## Admission criterion

A candidate qualifies only if it is a **repeatable pattern with a concrete detection**. Reject:

- a one-off event, a closed ticket, a fact git history already records;
- something a linter or type checker already enforces (configure the tool instead);
- a preference without a wrong example that actually occurred;
- a project fact that belongs in the constitution or an area guide, not a rule.

A process rule (how to branch, how to prove, how to review) is admissible with a review question
as its detection. A code rule needs an executable detection: a grep, a lint rule, a query.

## Step 2 — De-duplicate

Read `{{memory.rules}}` in full. For each candidate, check whether an existing rule already covers
it; if so, discard the candidate or strengthen the existing rule's examples or detection instead of
adding a twin. The read is also the only source of the next free `RULE-NNN` id: never guess it, and
assign consecutive ids when several rules land at once.

## Step 3 — Persist

Append each surviving candidate to `{{memory.rules}}` in the catalogue's format:

```
## RULE-NNN: slug
Severity: critical | major | minor · Learned from: #N or PR #N or incident <ref> · Date: YYYY-MM-DD
Rule: one sentence, imperative, stating the pattern to follow.
Wrong: minimal example that actually occurred.
Right: minimal example of the same situation done correctly.
Detection: grep, lint rule, query, or review question.
```

- `critical`: can lose data, ship a security hole, or corrupt the release.
- `major`: breaks a contract, a gate or a review; costs a correction cycle.
- `minor`: consistency and hygiene.

Resolve the path from the repository root (`git rev-parse --show-toplevel`), never relative to the
current directory. Write the rule as a root-cause fix, not a note: if the right fix is a gate, a
guard or a template change, make that change in the same session and let the rule point to it.

## Step 4 — Refresh what the lesson invalidated

- Correct any claim in the constitution, area guides or `{{memory.handoff}}` that the lesson makes
  stale. Replace the wrong sentence; do not append a dated paragraph.
- If the rule changes how a gate or review runs, update that skill or checklist in the same change.

## Step 5 — Report

```
## Compound — <mode> — <date>
Created: RULE-NNN <slug> — <one line>   (or "none")
Strengthened: RULE-MMM — <what changed>  (or "none")
Rejected: <candidate> — <which admission criterion failed>
Refreshed: <file> — <claim corrected>
Escaped gate (Compound-2): <gate> — <why it did not catch this>
```

If nothing survives de-duplication and admission, say so. A clean session yields nothing, and that
is a valid outcome; do not invent a rule to have something to show.
