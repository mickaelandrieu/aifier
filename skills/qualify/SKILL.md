---
name: qualify
description: Phase 1 Define for {{project}} - rewrite a raw issue into the two-audience contract (problem, impact, observable acceptance criteria, folded technical analysis), ground the technical part in the repository, set the workflow label and stop at the intent gate. Never plans, never builds. Argument - an issue number or URL.
---
<!-- placeholders: {{project}} {{repo}} {{forge}} {{label_prefix}} {{memory.rules}} {{memory.decisions}} -->

An idea becomes a contract. The contract is judged by the person who owns the need, not by you:
your job ends when the issue is readable by two audiences and the human gate on intent is
visibly open. Run inline in the main session.

Vocabulary used below. **Area guide**: the nearest `AGENTS.md` above a directory; the
constitution at the root when there is none. **Catalogue**: `{{memory.rules}}`. Dates are
`YYYY-MM-DD`. Where an issue stands (its shape, its labels, its comments, the open pull requests)
is decided by one script, `gate.sh`, never by this skill: the `gate` skill next to it documents
the states.

## Step 0 — Read, do not write yet

1. Ask the gate where the issue named by `$ARGUMENTS` stands, a number or a URL passed as given
   (`N` below is the number): `bash "<skills directory this file lives in>/gate/gate.sh"
   $ARGUMENTS --repo {{repo}} --prefix {{label_prefix}}`. No argument: ask for one and stop. A
   non-zero exit has printed `BLOCKED: <reason>`: repeat that line and stop, there is no prose
   fallback. Quote the printed `state:` line in the report.
2. Act on the printed state. `not-qualified` with `shape: missing`: continue, this is the issue to
   qualify. `not-qualified` with `shape: ok`: do not rewrite; set the label (Step 2) and say the
   body was already in shape. `qualified`, `qualified (partial)`, `needs-input`, `planned`,
   `chosen <letter>`: say "already qualified" with the state and stop. `in-progress`: say which
   label or pull request the line names and stop; qualification happens before work, not during
   it.
3. Fetch the issue: `gh issue view N --repo {{repo}} --json title,body,labels,comments,author`
   (GitLab: `glab issue view N`).
4. Read what grounds the technical part: the constitution, the area guide of each directory the
   issue mentions, the catalogue, the titles of the files in `{{memory.decisions}}`, and the files
   the issue names. Cite nothing you did not open.

## Step 1 — Write the contract

Rewrite the body in this shape, in the language the issue is written in:

```
## Problem
<what is wrong or missing, plain language, no code, one paragraph>

## Impact
<who is affected, what it costs them; "unknown" is acceptable, a guess is not>

## Acceptance criteria
- [ ] When <observable situation>, then <observable result>
- [ ] ...

<details><summary>Technical analysis</summary>

Affected areas: <dir> (guide: <path> | no guide), <dir> (...)
Suspected cause: <file:line>; for something missing, <what is absent and where it would live>; or "not located"
Constraints: <catalogue rules by RULE id, constitution rules by number, decisions by ADR id>
Non-binding approach: <one or two sentences, or "left to plan">
Open questions: <what the author must answer, or "none">

</details>

<details><summary>Original request</summary>
<the body as it was, verbatim>
</details>
```

Rules of the rewrite:

- Acceptance criteria are behaviours, checkable without reading code: "when the form is sent with
  an empty email, then the field shows an error and nothing is saved". A criterion that names a
  function, a table or a class is technical and belongs in the folded part.
- Never invent a criterion the author did not state or clearly imply. When the request is too thin
  to yield at least one observable criterion, write the criteria you could infer, list what is
  missing under **Open questions**, and treat the issue as blocked on its author (Step 2).
- Impact may restate a consequence the Problem already implies; it may not add one the author
  never hinted at.
- Mark every technical claim `VERIFIED (file:line)`, `VERIFIED (command)` when a command output
  proves it (`git ls-tree`, `gh pr list`), or `INFERRED`. A route, a flag, a schema you did not
  open is `INFERRED`.
- Keep the original request folded, verbatim. The author must be able to check nothing was lost.
- Do not solve the problem. "Non-binding approach" is one or two sentences; alternatives, trade-offs
  and the choice belong to `plan`.

## Step 2 — Set the state and stop

Write the body to a file, print its path and the commands below, and ask once: "post it?". Run
on yes; on no, leave the file for the person to paste. `--remove-label` on a label the issue does
not carry is harmless.

- Contract complete: `gh issue edit N --repo {{repo}} --body-file <file> --add-label
  {{label_prefix}}:todo --remove-label {{label_prefix}}:needs-input`, then one comment:
  "Qualified. Please confirm the problem and the acceptance criteria reflect the need, or edit them.
  Next step after your confirmation: `/plan N`."
- Open questions remain: same edit, but the label is `{{label_prefix}}:needs-input` and the comment
  lists the questions. The issue is not qualified until the author answers.

Never run `plan` or `build` from here, never create a branch, never close the issue.

## Report

In the chat, not on the issue:

```
## Qualify — #N — <date>
State: todo | needs-input | already qualified
Criteria: <count> observable, <count> open questions
Grounding: <files opened>; claims VERIFIED <count>, INFERRED <count>
Stopped at: intent gate (human confirms the contract)
```

## What `qualify` does not do

- choose an approach or estimate effort: that is `plan`, after the human confirmed the contract;
- touch code, branches or pull requests;
- close an issue or merge duplicates on its own; it may say "looks like #M" in the comment.
