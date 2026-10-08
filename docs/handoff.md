# Session handoff

Read at session start, update before stopping. Keep it under forty lines: current branch and
goal, what is done and proven, what is blocked, the next step.

## 2026-10-08 (review of main applied)

- Branch `main`. Merged: #31 (method pages in English, criteria 0.7/0.8 ordered, cycle skills as
  gap closers), #32 (release smokes the built artefact, installer env combinations tested, latest
  tag by default), #33 (loud config-shape errors in the renderer, single-area constitution,
  template cleanups), #34 (collectors: `BLOCKED` over false verdicts, NUL-safe paths, portable
  sed, the `proposed` and `done` gate states), and the pull request of branch `fix/skills-docs`
  (self-description of the repository, one assess report path, `tests/lint.sh` back as the lint
  gate, seven learned rules from the review, the changelog, the four gates of `aifier.yml`).
- Proven: `bash tests/lint.sh`, `cargo build --release`, `bash tests/run.sh` (`tests: OK`), the
  installer from a local checkout, `bash skills/gates/run.sh aifier.yml --preflight --compare-ci`
  on this repository; the blocks are quoted in the pull request.
- Not done: per-engine guards, `aifier update` and `remove`, native Windows, stack packs, the
  cycle skills on GitLab; the blind runs of the skills edited here (RULE-006) are the reviewer's.
- Released: `v0.1.0` on 2026-10-08, four binaries published with `SHA256SUMS`; the README install
  line verified on a clean repository (latest tag picked, sha256 verified, 16 skills, binary 0.1.0).
- Next: blind runs of the edited skills on a target repository installed from the release (RULE-006);
  then `aifier update` and `remove`, guards, Windows.
  the four targets and the installer picks it by default).
