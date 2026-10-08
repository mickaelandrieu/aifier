# aifier assess probes
- root: ROOT
- date: DATE

## Identity

- remote: https://example.com/acme/two-stacks.git
- default branch: unknown (no origin/HEAD)
- commits total: 12
- last commit: 2026-09-26
- shallow clone: no
- tracked files: 28
- languages (by extension, top 8):
  - py: 7
  - ts: 6
  - json: 5
  - md: 4
  - yml: 3
  - toml: 2
  - example: 1

## C. Context

- AGENTS.md: absent
- CLAUDE.md: present (20 lines)
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
- docs dirs: docs 
- docs files: 2 markdown, top-level: architecture.md decisions 
- adr dirs: ./docs/decisions 
- CHANGELOG: absent
- README: present (3 lines)
- CONTRIBUTING: absent
- session load (constitution + @includes): 20 lines
- paths cited in constitution/docs: 0, dead: 0
- constitution last change: 2026-09-01; docs last change: 2026-09-15; code last change: 2026-09-26
- docs commits since 2026-08-01: 2 / all commits: 12

## H. Harnessability

- type-check config:  api/pyproject.toml 
  - tsconfig strict:     "strict": true,
  - mypy: strict = true
- lint/format config:  api/pyproject.toml 
- pre-commit: absent; git hooks dir: default
- module boundary tooling: 
- top-level layout: api/ docs/ web/ 
- lockfiles: 
- runtime pins:   requires-python = ">=3.12"
- containers: 
- Makefile targets: none
- package.json scripts: 
- generators/templates: 

## Tests

- test files: 1
- test dirs: ./api/tests 
- e2e tooling: 
- coverage config: 

## CI pipelines

- .github/workflows/ci.yml (keyword hits, not steps; read the file before citing):
  - ruff
  - pytest
- dependabot/renovate: .github/dependabot.yml 
- secret scanning config: 
- .env tracked by git: 
- .env.example: present (2 lines)
- dead code tooling: 
- feature flags lib: 
- structured logging / tracing: 

## Secrets (narrow regex scan, candidates: read before citing)

- gitleaks: 
- secret-looking assignments in tracked files (regex: key, then : or =, then 8+ value characters; max 15):
- tracked .env files: 

## Git activity

- window: since 2026-08-01: 12 in window, 12 in sample
- non-merge commits: 12; merge commits: 0
- conventional commit subjects: 12 / 12
- commits referencing an issue (#N): 1 / 12
- code commits also touching tests: 2 / 10
- commit size (lines changed, non-merge, sorted sample):
  - count 12, median 6, p90 26
- merge authors (who merges): 
- direct commits on default branch (non-merge, first-parent): 12
- postmortem/incident files: 
- migrations: 
- tags: 0, latest: none

## GitHub (gh)

- gh unavailable or not authenticated: D2, D3, D5, R1, R4, L1 are NOT OBSERVABLE
- issue templates (local): bug.yml 
- PR template (local): 

## Aifier footprint

- aifier.yml: absent
- rules catalogue: 
- process skills: 
- checkpoints dir: 
