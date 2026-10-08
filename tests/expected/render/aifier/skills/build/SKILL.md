---
name: build
description: Phase 3 Build for aifier - from an issue whose approach a human chose, cut a branch from the target base, load the learned rules and area guides before the first edit, build one slice, run the gates with captured output and open a pull request that ends with a Verification Run. Never merges, never picks the approach. Argument - an issue number or URL.
---
<!-- gate commands are those of `root` -->

Build one slice, under the rules, with proof. Two gates stand behind you (intent, architecture)
and one ahead (acceptance, held by the reviewer and the maintainer). You cross none of them.
Before the first command, read `verification-evidence/SKILL.md` and `process-rules/SKILL.md`
from the skills directory this file lives in.

Vocabulary used below. **Area guide**: the nearest `AGENTS.md` above a directory; the
constitution when there is none. **Approach reply**: the comment `gate.sh` reports as `approach
reply: <letter> by <login> on <date>`; its remaining lines are the amendments. Agents never write
that line. A gate whose value is `null` is **none**: not run, not `BLOCKED`, reported as `none`.
Dates are `YYYY-MM-DD`. Where an issue stands (its shape, its labels, its comments, the open pull
requests) is decided by one script, `gate.sh`, never by this skill: the `gate` skill next to it
documents the states.

## Step 0 — Check the gates behind you

1. Ask the gate where the issue named by `$ARGUMENTS` stands, a number or a URL passed as given
   (`N` below is the number): `bash "<directory of this SKILL.md>/../gate/gate.sh"
   $ARGUMENTS --repo mickaelandrieu/aifier --prefix sdlc`. No argument: ask and stop. A non-zero
   exit has printed `BLOCKED: <reason>`: repeat that line and stop, there is no prose fallback.
   Quote the printed `state:` line in the report.
2. Act on the printed state. `chosen <letter>`: continue, that approach plus the amendments of its
   reply is your specification. `not-qualified` or `needs-input`: stop and say `/qualify N`.
   `proposed`: stop and say "waiting for `contract: ok` on #N". `qualified` or `qualified
   (partial)`: stop and say `/plan N`. `planned`: stop and say "waiting for `approach:` on #N".
   `done`: stop and say "issue closed by the cycle". Never infer the choice from the
   recommendation, from a reaction, or from the person asking you to build: the letter comes
   from the printed line or there is none.
   Then check once that the workflow labels exist: `gh label list --repo mickaelandrieu/aifier --search
   "sdlc:" --limit 100 --json name -q '.[].name'`. When any of
   `sdlc:todo`, `sdlc:in-progress`, `sdlc:done`,
   `sdlc:partial`, `sdlc:needs-input` is missing, print
   `BLOCKED: workflow labels missing` followed by one line per missing label,
   `gh label create "sdlc:<state>" --repo mickaelandrieu/aifier`, and stop.
3. `in-progress`: name every label and pull request the line carries, then fetch the issue
   (item 4) and ask the person once: "continue on the branch of PR #M?" naming the pull request
   whose base matches this slice (the approach reply may name the branch instead). Without a
   yes, stop. On yes: `gh pr checkout M`, then run the clean-tree check and the fetch of Step 2
   and skip only the `checkout -b` and the label command. The approach is still the one the
   line's `approach reply:` names; `none` there is "waiting for `approach:` on #N".
4. Fetch the issue to read the plan and the reply: `gh issue view N --repo mickaelandrieu/aifier --json
   title,body,labels,comments`.

## Step 1 — Load before editing

In this order, before the first edit: `docs/learned-rules.md` in full; the area guide of every
directory the approach touches; the files named in the plan; the decision the plan cites, if
any. Start the PR body now, in a scratch file, with the line "Rules honoured: RULE-NNN, ..."
listing the rules that apply to this slice; the rest of the body is filled at Step 5.

`templates/, skills/*/SKILL.md` are off limits unless the chosen approach's "Touches" line says
"protected: yes" for them. A glob covers files that do not exist yet. A slice that needs a
protected path the plan did not name goes back to the plan: comment on the issue and stop.

## Step 2 — Branch

```bash
git status --porcelain            # must print nothing (untracked files count); otherwise stop and say what is pending
git fetch origin main
git checkout -b <type>/<issue>-<slug> origin/main
gh issue edit N --repo mickaelandrieu/aifier --add-label sdlc:in-progress --remove-label sdlc:todo --remove-label sdlc:partial
```

`<type>`: `fix` when the issue is labelled `bug` or describes a defect, `feat` for an
`enhancement` or new behaviour, `refactor` or `chore` when the chosen approach says so. One
branch per slice; the slice is the first one the plan names (the issue title when the plan has a
single unnamed slice). `--remove-label` on an absent label is harmless.

## Step 3 — Build the slice

- Follow the chosen approach. Where it is silent, follow the area guide; where both are silent,
  follow the existing code around you. A deviation from the approach that you believe necessary
  is a comment on the issue and a stop, not a silent improvement.
- Write the test that proves each acceptance criterion first when the plan's "Proof" line says
  "new test"; make it assert the behaviour, not the implementation (process rule PR-005).
- Fix at the lowest layer that owns the defect (PR-003). No `skip`, `workaround` or special case in
  a consumer to cover a producer's bug.
- Keep the slice one slice: no drive-by refactors, no formatting of files the slice does not
  change. Those are their own issues.
- Documentation changes in the same PR when the slice changes behaviour the docs describe.
- Update `docs/handoff.md` as part of the slice: branch, slice, what is proven, what is blocked,
  next slice. It is committed with the slice, so the tree is clean for the next run.
- Commit when the gates of Step 4 are green, one commit per slice unless the plan says otherwise:
  `git add -A && git commit -m "<type>(<scope>): <subject> (#N)"`, the subject in the
  imperative, the scope the area or skill touched, nothing else in the message. Confirm with
  `git status --porcelain` (empty) and `git log --oneline -1` (process rule PR-009). The PR title
  of Step 5 reuses that subject.

## Step 4 — Verify, with proof

Run the environment preflight, then every gate declared for the areas the slice touches (the
values in `aifier.yml` win over the four below when they differ), from the repository root, and
capture the tail of each real output:

```
$ cargo fmt --check && cargo clippy --all-targets -- -D warnings
$ AIFIER_SRC=. AIFIER_DIR=skills sh install.sh && bash skills/init/detect.sh . >/dev/null && bash skills/assess/probes.sh . >/dev/null && bash tests/run.sh
```

A gate that cannot run is `BLOCKED: <reason>`, never skipped silently, never replaced by a weaker
proxy. A failing gate is fixed or the PR says so; a red gate never becomes "pre-existing". When
the plan's proof for a criterion is "manual: <steps>", run the steps and quote what you saw.

## Step 5 — Open the pull request

Conventional subject, `Closes #N` in the body (or `Part of #N` when slices remain), target
`main`. Fill the project's pull request template as it is; whatever its sections, the
body carries the "Rules honoured" line, a `## Verification Run` section with the captured output
of Step 4, and an "Out of scope" part naming the next slices and the deviations you refused to
make. If the plan's "Decision of record" is not none, the ADR is in this PR, written with the
`decision-record` skill.

```bash
git push -u origin HEAD
gh pr create --base main --title "<type>(<scope>): <subject>" --body-file <file>
gh issue edit N --repo mickaelandrieu/aifier --add-label sdlc:partial --remove-label sdlc:in-progress   # only when slices remain
```

When the slice closes the issue, leave `sdlc:in-progress`: the reviewer moves it to
`sdlc:done` after the merge. Never approve, merge, or mark the pull request ready on
your own authority; never remove `sdlc:pr:need-work`. The reviewer and the maintainer
hold the acceptance gate.

## Step 6 — Hand off

If the build surfaced a lesson (a rule you had to discover, a gate that lied), say so in the
report: it is `compound`'s input, run it when the person asks.

## Report

```
## Build — #N — <date>
Gate: <the printed state: line, verbatim>
Approach: <letter> (chosen by <login> on <date>)
Branch: <name> → PR #M
Slice: <name>, <count> of <total>
Rules honoured: RULE-NNN, ...
Verification Run: lint <ok|BLOCKED>, typecheck <ok|BLOCKED|none>, test <ok|BLOCKED>, build <ok|BLOCKED|none>
Deviations refused: <list or none>
Stopped at: acceptance gate (review and merge are human) | Step 0 (<state>, nothing written) | BLOCKED (<reason>)
```

On a stop at Step 0 or on `BLOCKED`, fill `Gate` and `Stopped at`; leave the other lines out.
