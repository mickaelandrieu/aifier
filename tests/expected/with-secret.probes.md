# aifier assess probes
- root: ROOT
- date: DATE

## Identity

- remote: https://example.com/acme/with-secret.git
- default branch: 
- commits total: 4
- last commit: 2026-09-22
- tracked files: 6
- languages (by extension, top 8):
  - md: 3
  - yml: 2
  - env: 1

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
- docs dirs: docs 
- docs files: 2 markdown, top-level: faq.md guide.md 
- adr dirs: 
- CHANGELOG: absent
- README: present (3 lines)
- CONTRIBUTING: absent
- session load (constitution + @includes): 0 lines
- paths cited in constitution/docs: 0, dead: 0
- constitution last change: ; docs last change: 2026-09-18; code last change: 2026-09-22
- docs commits in last 2026-08-01: 2 / all commits: 4

## H. Harnessability

- type-check config:  
- lint/format config:  
- pre-commit: absent; git hooks dir: default
- module boundary tooling: 
- top-level layout: docs/ 
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
- .env tracked by git: .env 
- .env.example: absent
- dead code tooling: 
- feature flags lib: 
- structured logging / tracing: 

## Secrets (candidates, read before citing)

- gitleaks: 
- tracked files with secret-looking assignments (max 15):
  - .env:1:PASSWORD=hunter2hunter2
  - config.yml:2:api_key: sk_live_ABCDEF1234567890abcdef
- tracked .env files: .env 

## Git activity

- window: last 2026-08-01 too sparse, falling back to last 100 commits (ending 2026-09-22)
- non-merge commits: 4; merge commits: 0
- conventional commit subjects: 4 / 4
- commits referencing an issue (#N): 0 / 4
- code commits also touching tests: 0 / 0
- commit size (lines changed, non-merge, sorted sample):
  - count 4, median 3, p90 4
- merge authors (who merges): 
- direct commits on default branch (non-merge, first-parent): 4
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
