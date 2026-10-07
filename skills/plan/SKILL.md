---
name: plan
description: Phase 2 Plan for {{project}} - from a qualified issue, produce two or three approaches that diverge in strategy, each with scope, trade-offs, risks and the rules it must honour, recommend one, post them on the issue and stop at the architecture gate until a human names the approach. Never builds. Argument - an issue number or URL.
---
<!-- placeholders: {{project}} {{repo}} {{label_prefix}} {{memory.rules}} {{memory.decisions}} {{protected_paths}} {{gates.test}} -->

The planner never builds. A human picks the approach; you make that choice informed and cheap.
Run inline in the main session.

Vocabulary used below. **Contract shape**: the body has the `## Problem`, `## Impact` and
`## Acceptance criteria` headings and a `<details>` block whose summary is `Technical analysis`.
**Area guide**: the nearest `AGENTS.md` above a directory; the constitution when there is none.
**Human reply**: a comment whose first line starts with `approach:` and whose author is not a
bot account (login not ending in `[bot]`); agents never write that line. Dates are `YYYY-MM-DD`.

## Step 0 — Check the gate behind you

1. Fetch the issue named by `$ARGUMENTS`, a number or a URL: `gh issue view N --repo {{repo}}
   --json title,body,labels,comments`. No argument: ask and stop.
2. Qualified means contract shape **and** label `{{label_prefix}}:todo`. Shape without the label,
   or no shape: say "not qualified, run `/qualify N`" and stop. With `{{label_prefix}}:needs-input`
   and no `## Plan` comment: the author has questions to answer; stop.
3. A comment with a `## Plan` heading exists:
   - with a later human reply: say "already planned, approach <X> chosen; run `/build N`" and stop;
   - without one: say "already planned, waiting for `approach:` on #N" and stop. Re-plan only when
     the person asks for it explicitly; the new comment then starts with "Supersedes the plan of
     <date>".

## Step 1 — Load what constrains the plan

Read, in this order, and keep the ids: `{{memory.rules}}` in full, noting the rules that touch the
affected areas; the titles of the files in `{{memory.decisions}}` and the body of any decision the
technical analysis or an area guide cites; the area guide of each affected directory; the files
named in the technical analysis. If work on the issue already exists in the tree or on a branch,
say so in the first line of the plan: the approaches are written from the contract, not from
that draft.

`{{protected_paths}}` are paths no approach may touch without saying so, because `build` refuses
them otherwise. A glob covers files that do not exist yet: creating `skills/x/SKILL.md` under a
protected `skills/*/SKILL.md` is touching it.

## Step 2 — Write the approaches

Two or three approaches that **diverge in strategy**, not in detail. Two variants of the same
change (same files, different naming) are one approach. Divergence looks like: fix in the layer
that owns the rule versus guard in the caller; extend the existing model versus add a new one;
migrate data versus translate at read time; one slice versus a flagged rollout in two.

For each:

```
### Approach <letter> — <name>
What changes: <three to six lines, the user-visible result and the mechanism>
Touches: <dir>: <files or modules>; protected: <yes, which | no>
Slices: <one PR | N PRs, each named, each independently shippable>
Honours: RULE-NNN, RULE-MMM, ADR NNNN
Trade-offs: + <gain> / − <cost>
Risk: <what breaks if the assumption is wrong, and how it would be noticed>
Proof: per criterion: "{{gates.test}} <scope>", "new test: <what it asserts>", or "manual: <steps>" when no gate can exercise it
Effort: S | M | L  (relative to the other approaches, no hours)
```

Then, in this order: one paragraph "Decision of record: <none | what and why>" when an approach
needs a new dependency, a schema change or a contract change (the ADR is written in the build PR,
see the `decision-record` skill); then:

```
### Recommendation
<one approach, two or three sentences of reasons tied to the trade-offs above>
### To decide
Reply with `approach: <letter>`, amendments in the same comment. `build` starts from that comment.
```

Rules of the plan:

- An approach that cannot show how each acceptance criterion will be proven is incomplete; say
  which criterion has no proof rather than hide it. "manual:" is a proof only when no gate can run
  the behaviour, and it says so.
- If the qualified contract turns out to be unbuildable as written (contradictory criteria, a
  constraint the author did not know), do not plan around it: post the finding, set
  `{{label_prefix}}:needs-input`, and stop. The contract goes back through its own gate.
- Cite `file:line` for every claim about the committed code, `git status` or the branch for
  claims about uncommitted work, `INFERRED` otherwise.

## Step 3 — Post and stop

Write the plan under a `## Plan` heading to a file, print its path and the two commands, and ask
once: "post it?". On yes: `gh issue comment N --repo {{repo}} --body-file <file>` then
`gh issue edit N --repo {{repo}} --add-label {{label_prefix}}:needs-input`. On no, leave the file.
Never cut a branch, never edit code, never pick the approach yourself even when one is obviously
better: the recommendation is where your opinion goes.

## Report

In the chat, not on the issue:

```
## Plan — #N — <date>
Approaches: <count>, recommended: <letter>
Constraints loaded: <count> rules apply (of <total>), <count> decisions, <count> area guides
Unproven criteria: <list or none>
Posted: yes | no (file kept at <path>)
Stopped at: architecture gate (human replies `approach: <letter>`)
```
