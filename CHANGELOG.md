# Changelog

All notable changes to aifier are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); one tag of the repository is one
release carrying the `aifier` binary ([ADR 0002](docs/decisions/0002-aifier-binary.md)).

## v0.1.0 - 2026-10-08

First release.

### Added

- `install.sh`: `curl | sh` installer that picks the latest release, puts the skills in
  `.agents/skills/`, the binary in `.aifier/bin/`, records `.aifier/install.yml` and links
  `.claude/skills`; `AIFIER_REF`, `AIFIER_DIR`, `AIFIER_SRC`, `AIFIER_BIN` documented and tested
  alone and combined, offline, in `tests/run.sh`.
- Sixteen skills under `skills/`: `assess`, `init`, `gates`, `context`, `status`, `gate`,
  `qualify`, `plan`, `build`, `compound`, and the knowledge skills `verification-evidence`,
  `review-checklist`, `adversarial-test-plan`, `decision-record`, `process-rules`,
  `documentation-rules`.
- Bash collectors next to their skill (`detect.sh`, `probes.sh`, `run.sh`, `gate.sh`,
  `status.sh`), with golden tests on the fixtures under `tests/`; `BLOCKED` over a false verdict,
  NUL-separated path iteration, portable `sed` and `awk`.
- The `aifier render` binary (Rust, `src/`), released per tag for four targets (Linux musl and
  macOS, x86_64 and aarch64) with `SHA256SUMS`; `init` renders with it and stops with `BLOCKED`
  without it; loud errors on a configuration key of the wrong shape.
- The method pages under `method/`: phases, gates and the assess grid, in English.
- The cycle run end to end on this repository: it was set up with `/init`, its issues go through
  `/qualify`, `/plan` and `/build`, its rules are captured in `docs/learned-rules.md`.
- `tests/lint.sh`: frontmatter, placeholders, installer shape, shell syntax, rendered goldens,
  manifest and skill-drift checks, run first in CI.

### Not in this release

- Per-engine guards (hooks); `aifier update` and `aifier remove`; native Windows (WSL and Git
  Bash work); stack packs; GitLab for the cycle skills (`qualify`, `plan`, `build`, `gate` need
  `gh`); detection of a newer aifier by `status`.
