# Session handoff

Read at session start, update before stopping. Keep it under forty lines: current branch and
goal, what is done and proven, what is blocked, the next step.

## 2026-10-08 (init on the binary)

- Branch `feat/21-init-binary` (on top of slice 2), issue #21 slice 3 of 3: `init` renders with
  `.aifier/bin/aifier render` and stops with `BLOCKED` without it; `render.py` deleted; no Python
  left under `skills/`. Opened on `main` once #27 lands. Closes #21 when merged.
- Next: a review of the three slices, then the first release tag `v0.1.0` pushed by the agent on the
  maintainer's instruction.

## 2026-10-08 (release)

- Branch `feat/21-release-installer`, issue #21 slice 2 of 3: `release.yml` builds four targets on a
  `v*` tag and publishes them with `SHA256SUMS`; `install.sh` downloads the asset of `AIFIER_REF`
  when it is a tag, verifies the checksum, copies `target/release/aifier` from a local checkout;
  three offline installer tests in `tests/run.sh`. Not merged by the agent.
- Next: the maintainer pushes a `v0.1.0` tag to prove the release end to end; slice 3 (`init`
  calls the binary, `render.py` deleted).

## 2026-10-08 (binary)

- Branch `feat/21-aifier-render`, issue #21 slice 1 of 3: Rust crate, `aifier render`, byte-identical
  to `render.py` (64 files compared), golden trees under `tests/expected/render/`, CI builds the
  crate, ADR 0002. `render.py` stays until slice 3.
- Next: slice 2 (release workflow, `install.sh` download by tag), slice 3 (`init` calls the binary,
  `render.py` deleted, check exception removed).

## 2026-10-08 (later)

- Branch `fix/20-gates-runner-bash`, issue #20: the gates runner is `skills/gates/run.sh` (bash),
  `run.py` deleted, fixture `gates-runner` with two golden files, `scripts/check.sh` fails on any
  `.py` under `skills/` or `scripts/` except `skills/init/render.py` until #21.
- Issue #21 (render.py into the V2 Rust binary) is `needs-input`: two questions for the maintainer.
- Next: a human merges #20; answer #21's questions, then `/plan 21`.

## 2026-10-08 (slice 2)

- Branch `feat/13-cycle-skills-call-gate` (based on `feat/cycle-skills`, which carries slice 1,
  PR #15 not merged yet; the pull request targets `feat/cycle-skills`), issue #13, approach A,
  slice 2 of 2: `qualify`, `plan` and `build` drop their own gate vocabulary and Step 0 and act on
  the line `gate/gate.sh` prints, `BLOCKED` when it cannot run; `init` copies `gate` with the
  cycle skills; `scripts/check.sh` fails when a cycle skill paraphrases the gate logic again.
- Proven: `bash scripts/check.sh` with the new drift check, the test gate (six issue fixtures
  unchanged), `gate.sh 13` on this repository quoted in the pull request. Blocked: the blind runs
  of the three rewritten skills (RULE-006), to be run by a person with `scripts/blind-run.sh`
  before `feat/cycle-skills` merges; their friction lists go on the pull request.
- Next: blind runs, then a human merges #15 and this pull request into `feat/cycle-skills`, then
  `feat/cycle-skills` into `main`; later, `done`/`partial` states for `status` (issue author's
  answer 1).

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
