# 0002 — The aifier binary: one crate in this repository, released with the repository tag, no fallback

Status: accepted · Date: 2026-10-08 · Issue: #21

## Context

Using aifier must not need Python (#20, #21): the gates runner is bash since #20, and the one
piece left in Python was the renderer `init` calls. ADR 0001 reserves rendering, `update`,
`remove` and the guards to a standalone binary, and makes the templates the contract between
the skills and that binary. The maintainer answered two questions on #21: no by-hand rendering
fallback once the binary exists, and the binary is versioned with the repository.

## Options considered

1. A Rust crate at the root of this repository, one subcommand at a time, starting with
   `render`, released by CI on the repository tag for Linux and macOS, downloaded once by
   `install.sh`.
2. The whole V2 binary in one go (detection, questions, rendering, update, remove).
3. No binary: the installer renders with `sed` and `awk`.

## Decision

Option 1. `Cargo.toml` and `src/` live next to the method and the skills; the binary is named
`aifier`; `aifier render <aifier.yml> <templates> <target> [--force] [--skills <dir>]` reproduces
the former Python renderer byte for byte, which the golden trees under `tests/expected/render/`
enforce (`bash tests/run.sh`). One tag of this repository is one release carrying the binary for
`x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl`, `x86_64-apple-darwin` and
`aarch64-apple-darwin`; WSL uses the Linux build. `install.sh` downloads the asset of the tag it
installs into `.aifier/bin/` and verifies its checksum. When the binary is missing, `init` stops
with `BLOCKED` and the install line: there is one renderer.

The daily collectors (`gate.sh`, `probes.sh`, `detect.sh`, `status.sh`, `run.sh`) stay bash: the
binary runs at setup, never in the daily life of a project (arbitration of 2026-10-07).

## Consequences

- Developing aifier needs a Rust toolchain; using it does not need Python nor Rust.
- CI formats, lints (`clippy -D warnings`), tests and builds the crate before the golden tests.
- `serde_yaml` is pinned and unmaintained; only the subset `init` renders is read, and the
  parser can be swapped without touching the templates contract.
- `update` and `remove` come as later subcommands under the same release policy.
