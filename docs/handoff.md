# Session handoff

Read at session start, update before stopping. Keep it under forty lines: current branch and
goal, what is done and proven, what is blocked, the next step.

## 2026-10-08 (later)

- Branch `feat/13-gate-collector` (based on `feat/cycle-skills`, PR #12 not merged yet), issue #13,
  approach A, slice 1 of 2: `skills/gate/gate.sh` prints the state of an issue in one line, its
  `SKILL.md`, six payload fixtures under `tests/fixtures/issues/`, the loop in `tests/run.sh`.
- Proven: the six fixtures diff against `tests/expected/issue-*.txt`; the live run on #13 and #11
  of this repository is quoted in the pull request. Blocked: nothing.
- Next: slice 2, "cycle skills call the collector": `qualify`, `plan` and `build` replace their
  vocabulary and Step 0 with the script, `init` copies `gate`, the drift check in `scripts/check.sh`,
  blind runs of the three skills.

## 2026-10-08

- Branch `feat/cycle-skills`, issue #11: the cycle skills `qualify` (1 Define), `plan` (2 Plan),
  `build` (3 Build), each stopping at its gate; `init` copies them, README and the grid cite them.
- Three blind dry runs on issue #11 (no forge write); frictions in the pull request.
- Next: a human merges; then run the real cycle on the classic witness from inside the engine.

## 2026-10-07

- V1 shipped on `main`: installer, `/assess`, `/init`, seven knowledge skills, templates.
- aifier uses aifier: constitution, `aifier.yml`, GitHub templates, memory and CI rendered by
  `/init` on this repository; five learned rules captured from the day.
- Witnesses: a classic project (installer, detection and probes verified there, an `init`
  rendering open as a pull request, not merged) and an advanced one (results outside the repo).
- Next: make `/init` print the forge commands it does not run (last V1 checkbox of issue #1);
  then run the full cycle on the classic witness from inside the engine, not simulated.
