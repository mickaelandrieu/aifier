# aifier assess probes
- root: ROOT
- date: DATE

## Identity

- remote: https://example.com/acme/dormant.git
- default branch: unknown (no origin/HEAD)
- commits total: 5
- last commit: 2025-01-05
- shallow clone: no
- tracked files: 1
- languages (by extension, top 8):
  - toml: 1

## C. Context

- AGENTS.md: absent
- CLAUDE.md: absent
- .cursorrules: absent
- .github/copilot-instructions.md: absent
- .agents/skills: absent
- .claude/skills: absent
- .claude/agents: absent
- .claude/commands: absent
- .opencode/agents: absent
- .opencode/commands: absent
- .opencode/skills: absent
- .pi: absent
- sub-project AGENTS.md/CLAUDE.md: 
- docs dirs: 
- adr dirs: 
- CHANGELOG: absent
- README: absent
- CONTRIBUTING: absent
- session load (constitution + @includes): 0 lines
- paths cited in constitution/docs: 0, dead: 0
- constitution last change: n/a; docs last change: n/a; code last change: 2025-01-05
- docs commits since 2026-08-01: 0 / all commits: 0

## H. Harnessability

- type-check config:  
- lint/format config:  
- pre-commit: absent; git hooks dir: default
- module boundary tooling: 
- top-level layout: 
- lockfiles: 
- runtime pins:   
- containers: 
- Makefile targets: none
- package.json scripts: none
- generators/templates: 

## Tests

- test files: 0
- test dirs: 
- e2e tooling: 
- coverage config: 

## CI pipelines

- none found
- dependabot/renovate: 
- secret scanning config: 
- .env tracked by git: 
- .env.example: absent
- dead code tooling: 
- feature flags lib: 
- structured logging / tracing: 

## Secrets (narrow regex scan, candidates: read before citing)

- gitleaks: 
- secret-looking assignments in tracked files (regex: key, then : or =, then 8+ value characters; max 15):
- tracked .env files: 

## Git activity

- window: since 2026-08-01 too sparse (0 in window, fewer than 5), sample is the last 100 commits: 5 in sample (ending 2025-01-05)
- non-merge commits: 5; merge commits: 0
- conventional commit subjects: 5 / 5
- commits referencing an issue (#N): 0 / 5
- code commits also touching tests: 0 / 0
- commit size (lines changed, non-merge, sorted sample):
  - count 5, median 2, p90 3
- merge authors (who merges): 
- direct commits on default branch (non-merge, first-parent): 5
- postmortem/incident files: 
- migrations: 
- tags: 0, latest: none

## GitHub (gh)

- gh unavailable or not authenticated: D2, D3, D5, R1, R4, L1 are NOT OBSERVABLE
- issue templates (local): 
- PR template (local): 

## Aifier footprint

- aifier.yml: absent
- rules catalogue: 
- process skills: 
- checkpoints dir: 
