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
bash "<directory of this SKILL.md>/../init/detect.sh" . > "$OUT/draft.yml"
```

`$OUT` is a directory outside the repository.

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
bash "<directory of this SKILL.md>/run.sh" aifier.yml --compare-ci --area none
```

`--area none` is the sentinel for "compare only": the runner matches no area, so it runs no gate
and prints the comparison alone. Every declared gate that CI does not run is a finding; every CI step that is not a declared
gate is a question. Propose the CI change (a job per missing family, and the check names to
require in branch protection), do not apply it without a yes.

## Step 4 — Run once, capture

```bash
bash "<directory of this SKILL.md>/run.sh" aifier.yml --preflight
```

The runner executes the preflight, stops with `BLOCKED` when it fails, then every declared
gate in its area, and prints a `## Verification Run` block with the exit code and the log path
of each. Paste that block in your report, verbatim. A gate that fails is a result, not a reason
to edit `aifier.yml`: say what failed and leave it to the person.

The runner needs `bash` and the usual Unix tools; when `run.sh` cannot start, say
`BLOCKED: run.sh could not run (<reason>)`, do not write the block by hand.

## Step 5 — Make it stick

- Add the block format to the PR template's Verification section if it is not there.
- The constitution's Gates section keeps the raw commands per area (the template renders them
  from `aifier.yml`); add once, above them, the runner line
  `bash <skills dir>/gates/run.sh aifier.yml --preflight`, so every agent uses it.
- Add `.aifier/gates/` to `.gitignore`: logs are evidence for the session, not for the repository.

## Report

```
## Gates — <date>
Declared: <area>: lint <cmd|none>, typecheck <…>, test <…>, build <…>   (one line per area)
Gaps: <family without a tool, per area | none>
CI: <declared gates CI does not run | CI steps that are not gates | in sync>
Preflight: <items>
Run: <the ## Verification Run block of Step 4, verbatim> | BLOCKED (<reason>)
Needs the person: <CI change, missing tool | nothing>
```
