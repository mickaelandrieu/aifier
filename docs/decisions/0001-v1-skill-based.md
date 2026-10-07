# 0001 — V1 is skill-based; the standalone binary is V2

Status: accepted · Date: 2026-10-07

## Context

The generator was first specified as a Rust binary installed by `curl | sh`, with per-engine
guards. That is weeks of work and blocks every other deliverable. The method, the `assess`
grid and the templates do not depend on how files get rendered.

## Options considered

1. Build the binary first, ship nothing until it renders.
2. Ship `init` as a skill run by the engine, with a deterministic detection script and the
   templates; the binary comes later and reuses the templates unchanged.
3. Ship shell-only tooling and never build a binary.

## Decision

Option 2. The engine is present anyway to use the result; it already reads repositories, asks
questions and writes files. The binary is V2 and brings guards, offline rendering, `update`
and `remove`, and native Windows.

## Consequences

- V1 requires a POSIX shell (macOS, Linux, WSL, Git Bash); documented in the README.
- Templates are the contract between V1 and V2: a change to a template is a change to both.
- Detection must stay deterministic so the binary can port it line by line.
