---
name: gates
description: Detect, declare and prove the verification gates of a repository (lint, typecheck, test, build) per area, compare them with CI, generate an environment preflight, and run them with captured output so that "tests pass" is a fact. Use when setting up a project, when a Verification Run is needed, or when agents claim results nothing proves.
---

You are running `gates`. The outcome is an `aifier.yml` whose `gates:` block is true, a
preflight agents must pass before any verdict, and a `## Verification Run` block with captured
output. Load the `verification-evidence` skill first if it is installed.

## Step 1 — What is declared, what is missing

Read `aifier.yml`. If it does not exist, run the detection of `init` first:

```bash
bash "<skills dir>/init/detect.sh" . > "$OUT/draft.yml"
```

For every area, list the four families (lint, typecheck, test, build) with the command or
`null`. For each `null`, look for a command detection missed: scripts in the manifest, a
`Makefile` or `justfile` target, a tool configured but not wired (a `tsconfig.json` without a
typecheck script, a `pytest` section without a test script). A family that truly has no tool is
named as a gap: "frontend: no test runner".

## Step 2 — Declare, with the person

Show the table and ask the person to confirm or correct each command, and to answer:

- the **preflight**: what must be true before a gate result can be trusted (dependencies
  synced, services up, generated code present, database migrated). Each item becomes a
  command that exits non-zero when the condition is false, listed under `preflight:` in
  `aifier.yml`;
- the **single command** that runs everything, if one exists (`make check`, `npm run verify`);
  when none exists, propose one in the manifest or the Makefile of each area and add it to
  the area guide. Write the confirmed `gates:`, `preflight:` and `ci.required_checks:` into
  `aifier.yml`.

## Step 3 — Compare with CI

```bash
python3 -I "<directory of this SKILL.md>/run.py" aifier.yml --compare-ci --area none
```

Every declared gate that CI does not run is a finding; every CI step that is not a declared
gate is a question. Propose the CI change (a job per missing family, and the check names to
require in branch protection), do not apply it without a yes.

## Step 4 — Run once, capture

```bash
python3 -I "<directory of this SKILL.md>/run.py" aifier.yml --preflight
```

The runner executes the preflight, stops with `BLOCKED` when it fails, then every declared
gate in its area, and prints a `## Verification Run` block with the exit code and the log path
of each. Paste that block in your report, verbatim. A gate that fails is a result, not a reason
to edit `aifier.yml`: say what failed and leave it to the person.

Without `python3`, run each command yourself in its area directory, redirect the output to a
file under `.aifier/gates/`, and write the same block by hand.

## Step 5 — Make it stick

- Add the block format to the PR template's Verification section if it is not there.
- Add to the constitution's Gates section the runner command, so every agent uses it.
- Add `.aifier/gates/` to `.gitignore`: logs are evidence for the session, not for the repository.

Report in eight lines: declared gates per area, gaps, CI differences, preflight items, the
verdict of the run, and what needs the person (CI change, missing tool).
