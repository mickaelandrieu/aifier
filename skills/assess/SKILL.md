---
name: assess
description: Read-only maturity audit of a repository against the AI-augmented SDLC grid (eleven phases, harnessability and context axes). Run the deterministic probes, score every criterion from captured evidence, and write a prioritised report. Use when asked to assess, audit, or measure how ready a project is for AI agents, before and after `init`.
---

# aifier assess

Measure where a repository stands against the AI-augmented SDLC and say what to fix first.
This command never modifies the target repository except to write its report.

## Inputs

- `$ARGUMENTS`: optional path to the repository to assess. Default: the current working
  directory's git root (`git rev-parse --show-toplevel`).
- `grid.md` next to this file: the evaluation grid. It is the only source of criteria, scales,
  weights and report format. Read it in full before scoring.
- `probes.sh` next to this file: the deterministic evidence collector.

## Step 1 — Collect evidence

Run the probes once and keep the full output; every score below must cite a line from it.

```bash
bash "<dir of this skill>/probes.sh" "<repo path>" > /tmp/aifier-probes.md
```

Then read `/tmp/aifier-probes.md`. If the `GitHub (gh)` section says gh is unavailable, mark
D2, D3, D5, R1, R4 and L1 as `non observable` and compute phase scores on the remaining criteria.

The probes cover what can be detected mechanically. For criteria that need reading (C1 quality of
the constitution, D1 template content, R2 checklist, K4 detection methods, X2 deprecation
procedure), open the file the probes located and judge from its content. Do not open more than
twenty files; the audit is a measurement, not an exploration.

## Step 2 — Score every criterion

For each criterion of the grid, in order (H, C, then phases 0 to 10):

1. Quote the evidence: the probe line or file excerpt that supports the score.
2. Assign the level 0 to 3 using the grid's `0` and `3` anchors. Interpolate 1 and 2 as
   `ad hoc` and `formalised`, as defined in the grid's scale.
3. Apply the two inversions the grid imposes: a human gate that an automation bypasses (D4, P3,
   R4, L1) scores lower, not higher; a control that is declared but not executed scores at most 2.
4. If the evidence is missing because the probe cannot see it (Ops tooling outside the
   repository, a GitHub API refusal), write `non observable` instead of 0 and say where to look.

Never score from assumption. A criterion with no evidence line and no opened file is `0` with the
note `no evidence found`, which is different from `non observable`.

## Step 3 — Compute

- Phase score = arithmetic mean of its scored criteria, one decimal. `non observable` criteria are
  excluded from the mean and listed under the phase.
- Global score = weighted mean of phase and axis scores with the grid's weights.
- Global level from the grid's table: Classique, Assisté, Augmenté, Compound.

Show the computation for the global score in one line so a reader can check it.

## Step 4 — Prioritise gaps

Order the gaps exactly as the grid prescribes:

1. missing or bypassed human gates (D4, P3, R4, L1) scored 0 or 1;
2. criteria in weight-3 phases (Define, Plan, Verify, Compound-1) scored 0 or 1;
3. everything else by phase weight descending, then by score ascending.

For each gap give one line: criterion id, what was found, the evidence, and whether `init` or
`gates` can close it (`init` installs configuration, templates, skills and rules; `gates`
declares and verifies lint, typecheck, tests and build). Keep the list to the fifteen most
valuable gaps; the full detail table carries the rest.

## Step 5 — Write the report

Write the report with the grid's `Format du rapport`, in the language of the target
repository's README (French if the README is in French, otherwise English), to:

```
<repo>/docs/aifier/assess-<YYYY-MM-DD>.md
```

Create the directory if needed. If a report already exists for the same day, overwrite it. Never
commit; leave that to the person.

End with a five-line summary in the conversation: global level and score, the two strongest
phases, the two weakest, the first gap to close, and the report path.

## Calibration checks

The grid carries expected scores for two reference repositories. When assessing one of them,
compare the result with the expectation and state the delta. A result outside the expected range
is a finding about the grid or the probes, to report as such, not a reason to adjust scores by
hand.
