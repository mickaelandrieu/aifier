---
name: plan
description: Phase 2 Plan for {{project}} - from a qualified issue, produce two or three approaches that diverge in strategy, each with scope, trade-offs, risks and the rules it must honour, recommend one, post them on the issue and stop at the architecture gate until a human names the approach. Never builds. Argument - an issue number or URL.
---
<!-- placeholders: {{project}} {{repo}} {{label_prefix}} {{memory.rules}} {{memory.decisions}} {{protected_paths}} {{gates.test}} -->

The planner never builds. A human picks the approach; you make that choice informed and cheap.
Run inline in the main session.

Vocabulary used below. **Area guide**: the nearest `AGENTS.md` above a directory; the
constitution when there is none. Dates are `YYYY-MM-DD`. Where an issue stands (its shape, its
labels, its comments, the open pull requests) is decided by one script, `gate.sh`, never by this
skill: the `gate` skill next to it documents the states. Agents never write an `approach:` reply.

## Step 0 — Check the gate behind you

1. Ask the gate where the issue named by `$ARGUMENTS` stands, a number or a URL passed as given
   (`N` below is the number): `bash "<directory of this SKILL.md>/../gate/gate.sh"
   $ARGUMENTS --repo {{repo}} --prefix {{label_prefix}}`. No argument: ask and stop. A non-zero
   exit has printed `BLOCKED: <reason>`: repeat that line and stop, there is no prose fallback.
   Quote the printed `state:` line in the report.
2. Act on the printed state. `qualified` or `qualified (partial)`: continue. `not-qualified`: say
   "not qualified, run `/qualify N`" and stop. `proposed`: say "waiting for `contract: ok` on
   #N" and stop; the intent gate is the author's, not yours. `needs-input`: the author has
   questions to answer; stop. `in-progress`: name every label and pull request the line carries
   and stop; planning happens before work, not during it. `done`: say "issue closed by the
   cycle" and stop.
3. `chosen <letter>`: say "already planned, approach <letter> chosen; run `/build N`" and stop.
   `planned`: say "already planned, waiting for `approach:` on #N" and stop. Re-plan only when
   the person asks for it explicitly; the new comment's first line is still `## Plan` and its second line is "Supersedes the plan
   of <date>".
4. Check once that the workflow labels exist: `gh label list --repo {{repo}} --search
   "{{label_prefix}}:" --limit 100 --json name -q '.[].name'`. When any of
   `{{label_prefix}}:todo`, `{{label_prefix}}:in-progress`, `{{label_prefix}}:done`,
   `{{label_prefix}}:partial`, `{{label_prefix}}:needs-input` is missing, print
   `BLOCKED: workflow labels missing` followed by one line per missing label,
   `gh label create "{{label_prefix}}:<state>" --repo {{repo}}`, and stop.
5. Fetch the issue: `gh issue view N --repo {{repo}} --json title,body,labels,comments`.

## Step 1 — Load what constrains the plan

Read, in this order, and keep the ids: `{{memory.rules}}` in full, noting the rules that touch the
affected areas; the titles of the files in `{{memory.decisions}}` and the body of any decision the
technical analysis or an area guide cites; the area guide of each affected directory; the files
named in the technical analysis. If work on the issue already exists in the tree or on a branch,
say so in the first paragraph under the `## Plan` line: the approaches are written from the
contract, not from that draft.

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

Write the plan to a file whose first line is `## Plan` (the line `gate.sh` looks for), print its
path and the two commands, and ask
once: "post it?". On yes: `gh issue comment N --repo {{repo}} --body-file <file>` then
`gh issue edit N --repo {{repo}} --add-label {{label_prefix}}:needs-input`. On no, leave the file.
Never cut a branch, never edit code, never pick the approach yourself even when one is obviously
better: the recommendation is where your opinion goes.

## Report

In the chat, not on the issue:

```
## Plan — #N — <date>
Gate: <the printed state: line, verbatim>
Approaches: <count>, recommended: <letter>
Constraints loaded: <count> rules apply (of <total>), <count> decisions, <count> area guides
Unproven criteria: <list or none>
Posted: yes | no (file kept at <path>)
Stopped at: architecture gate (human replies `approach: <letter>`) | Step 0 (<state>, nothing written) | BLOCKED (<reason>)
```

On a stop at Step 0 or on `BLOCKED`, fill `Gate` and `Stopped at`; leave the other lines out.
