# skills/

The portable skills the installer puts into a target project. Each directory holds a `SKILL.md`
whose frontmatter carries only `name` and `description`, the one format Claude Code, opencode and
pi all load, and, for the collectors, a bash script next to it.

Every skill is installed as is; those with a `<!-- placeholders: … -->` comment are rendered in
place by `/init` (project name, repository, branches, label prefix, gates, memory paths filled from
`aifier.yml`, so what lands in the project is the project's own file, readable without aifier);
`assess`, `init`, `gates`, `context`, `status`, `gate` carry no placeholders.

| Skill | Role |
|---|---|
| `assess` | Read-only maturity audit of any repository against the eleven phases; writes one report, `.aifier/assess-<date>.md`, that `status` reads. |
| `init` | Brings a repository to the Setup phase: detects the stack (`detect.sh`), confirms `aifier.yml`, renders constitution, templates, memory and the skills below with the `aifier` binary. |
| `gates` | Declares the lint, typecheck, test and build commands per area, the preflight, compares with CI, runs them with captured output (`run.sh`). |
| `context` | Audits what agents read: stale claims, dead paths, duplication, load per session, tiering and the split proposal for a long context file. |
| `status` | One-screen position against the method from the last assess, the memory files and the manifest (`status.sh`, `--min` for CI). |
| `gate` | Where an issue stands in the cycle, one line from one script (`gate.sh`): not-qualified, needs-input, proposed, qualified, planned, chosen, in-progress, done; the one place the gate decision is written. |
| `qualify` | Phase 1 Define: rewrites a raw issue into the two-audience contract, sets `<prefix>:todo`, stops at the intent gate (`contract: ok`). |
| `plan` | Phase 2 Plan: two or three approaches that diverge in strategy, posted on the issue, `<prefix>:needs-input`, stops until a human replies `approach: <letter>`. |
| `build` | Phase 3 Build: from the chosen approach, branch from the target base, rules and guides loaded first, one slice, gates with captured output, a PR ending with a Verification Run; never merges. |
| `compound` | Captures a lesson as a learned rule, pre-release (Compound-1) or from an incident (Compound-2), with admission criterion and de-duplication. |
| `verification-evidence` | The proof discipline: no gate claimed without captured output, environment preflight, `## Verification Run` section, `BLOCKED` verdict, no ready label on self-report. |
| `review-checklist` | Structured review (architecture, correctness, security, behaviour tests, consistency) with the PR health gate, a drift level and the learned-rule question. |
| `adversarial-test-plan` | Adversarial QA: attack categories, numbered plan, strict verdicts and severities, PLAN versus EXECUTE modes. |
| `decision-record` | When to write an ADR, `NNNN-slug.md` naming under the decisions directory, the template, supersession. |
| `process-rules` | Starter catalogue of process rules PR-001 to PR-010: branching, PR base, lowest layer, health gate, proof, git hygiene, grounded claims, preflight. |
| `documentation-rules` | Diátaxis decision guide and checklists, docs in the same PR as the code, every claim verified against source, no dead path. |
