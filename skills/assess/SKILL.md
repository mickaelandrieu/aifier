---
name: assess
description: Read-only maturity audit of a repository against the eleven phases of the AI-augmented SDLC. Scores each phase 0-3 from evidence (files, git history, forge), gives a verdict, and lists prioritised gaps tied to the command that closes them. Argument - path to the repository (default - current directory).
---

You are running `assess`, the first command of aifier. You audit the repository at `$ARGUMENTS`
(default: the current directory) and produce a maturity report. You are self-contained: do not
delegate to sub-agents. You are **read-only**: never write into the audited repository, never run
its build, tests or scripts, never change its labels or issues. Only `git`, `gh`/`glab` reads, and
file reads are allowed.

The report is only as good as its evidence. Every score cites what you read or ran. A score without
a cited proof is not a score: leave the criterion **unrated** and say why.

## Step 1 — Establish the sources

Run, from the repository root:

```bash
git rev-parse --show-toplevel && git branch --show-current
git log -1 --format='%H %cd' --date=short
git remote get-url origin 2>/dev/null
gh repo view --json nameWithOwner,defaultBranchRef -q '.nameWithOwner + " " + .defaultBranchRef.name' 2>/dev/null
```

Record which sources are available: `git` (always), `forge` (if `gh` or `glab` answers). Without
the forge, every criterion that needs branch protection, issue samples or CI runs is **unrated**,
never 0. Note today's date: a proof older than 90 days caps its criterion at 2.

Collect the inventory once, then reuse it:

```bash
# agent hosts and context
ls AGENTS.md CLAUDE.md GEMINI.md .cursorrules .github/copilot-instructions.md 2>/dev/null
find . -name AGENTS.md -not -path '*/node_modules/*' -not -path './.git/*' | head -30
find . -path '*/skills/*/SKILL.md' -not -path '*/node_modules/*' | head -60
ls -d .claude .opencode .agents .cursor .pi 2>/dev/null
# forge files
ls .github .github/ISSUE_TEMPLATE .github/workflows .gitlab .gitlab/issue_templates 2>/dev/null
ls .gitlab-ci.yml cloudbuild.yaml Jenkinsfile .circleci bitbucket-pipelines.yml 2>/dev/null
ls CONTRIBUTING.md CHANGELOG.md CODEOWNERS .github/CODEOWNERS RELEASE.md SECURITY.md 2>/dev/null
ls docs docs/adr docs/decisions docs/plans docs/runbooks docs/postmortems docs/incidents 2>/dev/null
ls .github/dependabot.yml renovate.json .renovaterc* 2>/dev/null
# gates and harnessability
ls Makefile justfile Taskfile.yml package.json pyproject.toml setup.cfg tox.ini go.mod Cargo.toml pom.xml build.gradle* 2>/dev/null
find . -maxdepth 3 \( -name package.json -o -name pyproject.toml -o -name tsconfig.json -o -name mypy.ini -o -name pyrightconfig.json \) -not -path '*/node_modules/*' | head -30
ls .commitlintrc* commitlint.config.* .pre-commit-config.yaml .husky lefthook.yml 2>/dev/null
ls .env.example .devcontainer 2>/dev/null
```

Forge samples (skip when the forge is unavailable):

```bash
gh api "repos/{owner}/{repo}/branches/$DEFAULT/protection" 2>&1 | head -40
gh label list --limit 100 --json name -q '.[].name'
gh issue list --state closed --limit 20 --json number,title,body,labels,closedAt
gh pr list --state merged --limit 20 --json number,title,body,files,mergedAt,mergedBy,author,closingIssuesReferences
gh run list --limit 10 --json name,conclusion,createdAt 2>/dev/null
```

Git samples (always):

```bash
git log --format='%s' -100
git log -1 --format=%cd --date=short -- AGENTS.md
```

## Step 2 — Score each criterion

Rubric, identical for every criterion:

| Score | Meaning |
|---|---|
| 0 | absent: no trace in the repository or the forge |
| 1 | ad hoc: traces (commits, issues, scattered files) but nothing written or tooled |
| 2 | declared: written and tooled (file, template, config, command) but no proof it applies |
| 3 | governed: declared **and** proven by evidence less than 90 days old (CI run, conforming sample of issues or PRs, active branch protection) |

Aggregation: phase score = mean of rated criteria, one decimal. A **blocking** criterion at 0 caps
its phase at 1. Unrated criteria are excluded from the mean. Phase level: absent (< 1), emerging
(1 to 1.9), tooled (2 to 2.9), governed (3). Each criterion has an axis: **H** harnessability,
**C** context, **W** workflow, **G** verification gates.

Walk the criteria below. For each: what to look for, where. Score from the rubric, cite the proof.

### Phase 0 · Setup

- **0.1 Agent constitution** (blocking, C). Root `AGENTS.md` or equivalent. 1 if generated boilerplate or more than 300 lines of prose; 2 if a short map pointing to area guides; 3 if every referenced file exists and the file changed in the last 90 days.
- **0.2 Area guides** (C). One guide per sub-project in a multi-stack repo. 3 when guides state checkable rules, not descriptions.
- **0.3 Knowledge packaged as skills** (C). `SKILL.md` directories with `name` and `description`. 3 when loaded by identifiable agents or commands and not duplicated in the constitution.
- **0.4 Agent hosts detected** (informative, not scored). List the host directories found and whether they look hand-copied or generated.
- **0.5 Code harnessability** (H). Strict typing configured (`tsconfig` `"strict": true`, `mypy`/`pyright` section, Go/Rust by nature), linter and formatter configured, module boundaries (workspaces, packages). 3 when typing runs in CI.
- **0.6 Environment bootstrap** (H). `Makefile`, `justfile`, `scripts/`, `.env.example`, devcontainer, README install section. 3 when the CI uses the same command.
- **0.7 Delegation scope** (W). A written statement of what agents do not do: merge, decide intent, pick architecture, touch safety-critical zones. 3 when agent instructions explicitly stop at the gates.

### Phase 1 · Define (human gate: intent)

- **1.1 Issue templates** (blocking, W). `.github/ISSUE_TEMPLATE/*.yml` or `.gitlab/issue_templates/`. 2 with fields for problem, expected behaviour, acceptance criteria; 3 when more than 70 % of the 20 sampled issues follow the structure.
- **1.2 Two audiences** (W). Business-readable top (problem, impact, observable criteria), technical analysis folded below. 3 when the sample respects it.
- **1.3 Observable acceptance criteria** (W). "When X, then Y", checkable without reading code. 3 when present in more than 70 % of sampled closed issues.
- **1.4 Tooled qualification** (W). A command or skill that rewrites a raw issue into the contract, and a workflow state (label) for "qualified". 3 when the state appears on recent issues.
- **1.5 Human stop on intent** (W). The qualified issue waits for human validation before plan or build. 3 when a label materialises the wait.

### Phase 2 · Plan (human gate: architecture)

- **2.1 Architecture decisions recorded** (C). ADRs in `docs/adr/` or `docs/decisions/`. 3 with a template and one ADR in the last 90 days.
- **2.2 Alternative approaches** (W). A command or skill producing two or three approaches that differ in strategy, with trade-offs and a recommendation. 3 when recent issues or plans show the arbitration.
- **2.3 Stop at the gate** (blocking, W). The planner never builds; a human chooses (comment, label, "chosen approach" field). 3 when the human arbitration is visible on recent issues.
- **2.4 Learned rules consulted at plan time** (C). The planner loads the rule catalogue. 3 when a recent plan cites a rule.
- **2.5 Grounded claims** (C). Plan claims tagged verified (`file:line`) or inferred. 3 when applied in a recent plan.

### Phase 3 · Build

- **3.1 Branching and protected base** (W). Written branch convention; default branch protection via the forge API. 3 when direct pushes are blocked.
- **3.2 Conventional commits** (W). `commitlint`, hook, or ratio over the last 100 commits: 0 below 30 %, 1 up to 70 %, 2 above 70 %, 3 above 90 % or enforced by hook or CI.
- **3.3 Written code conventions** (C). Style guides per language, linter and formatter config, `CODEOWNERS`. 3 when loaded by build agents.
- **3.4 Rule catalogue loaded at build** (C). 3 when loaded and the catalogue changed in the last 90 days.
- **3.5 Tests are part of the change** (G). Share of the 20 last merged PRs touching test files: 0 below 20 %, 1 up to 50 %, 2 above 50 %, 3 above 70 % with the rule written.
- **3.6 One slice per PR** (W). Median changed files over the 20 last merged PRs and linked issues. 2 when median under 20 files with a linked issue; 3 when `Closes #N` or equivalent is systematic.

### Phase 4 · Verify

- **4.1 Gates declared** (blocking, G). Lint, typecheck, test, build commands discoverable in `package.json` scripts, `pyproject.toml`, `Makefile`, `justfile`. 2 when all four families exist in every sub-project; 3 when grouped under one documented command.
- **4.2 Gates run in CI** (G). CI config runs the same commands. 3 when they are required checks in branch protection.
- **4.3 Local / CI parity** (G). CI calls the commands the docs give locally; an environment preflight exists. 3 when the preflight is written and required before any verdict.
- **4.4 Coverage measured** (G). Coverage report in CI, threshold or trend. 3 when the threshold blocks.
- **4.5 Proof discipline** (G). Agent instructions require captured command output and a `BLOCKED` verdict when a check cannot run; the PR template has a validation section. 3 when recent PRs contain command output.
- **4.6 Behavioural tests** (G). A written rule against implementation-coupled tests (mocks asserting calls, fixtures recomputing the result). 3 when it is in the review checklist.

### Phase 5 · Review

- **5.1 Review required before merge** (blocking, W). Branch protection requires at least one approval; `CODEOWNERS`. 3 with owners per area.
- **5.2 Written review checklist** (C). Architecture, quality, security, coverage, test quality; a report template. 3 when loaded by review agents.
- **5.3 Automated review** (G). A command or skill posting findings on PRs, several angles in parallel. 3 when consolidated findings are visible on recent PRs.
- **5.4 PR health gate** (G). No approval possible with conflicts or failing checks. 3 when enforced by protection or automated review.
- **5.5 Authors do not approve themselves** (W). Readiness is never set by whoever produced the PR, human or agent. 3 when the "ok" state is set by an independent review.
- **5.6 Reviews propose rules** (W). The review process asks whether a finding should become a learned rule. 3 when a recent rule came from a review.

### Phase 6 · Compound-1 (capitalisation before release)

- **6.1 Learned-rules catalogue** (blocking, C). One canonical file of numbered rules with severity, rule, wrong example, right example, detection. 1 for scattered notes; 3 when each rule has an executable detection.
- **6.2 Capture command** (W). A command that extracts lessons, de-duplicates against the catalogue and persists. 3 when the catalogue received a rule in the last 90 days (`git log` on the file).
- **6.3 Reinjection** (C). The catalogue is loaded by plan, build and review agents. 2 for one of them, 3 for all three.
- **6.4 Rule quality** (C). Each rule is a repeatable pattern, not a closed ticket or a lint rule. 2 when the admission criterion is written; 3 when a sample conforms.
- **6.5 A clean session yields nothing** (W). Written: absence of a lesson is a valid outcome. 2 when written.

### Phase 7 · Ship (human gate: acceptance)

- **7.1 Only a human merges** (blocking, W). No `merge` in agent instructions, branch protection, no auto-merge. 3 when protection is active and no bot appears among recent merge authors.
- **7.2 Release checklist** (W). `RELEASE.md`, `CONTRIBUTING.md` section, release template. 3 when followed in recent tags or notes.
- **7.3 Rollback written cold** (W). Documented rollback per change type (code, schema, config), written before deployment. 3 when tested or referenced in risky PRs.
- **7.4 Progressive delivery** (H). Feature flags, canary, traffic percentage in deployment config. 3 when used on a recent delivery.
- **7.5 Changelog** (C). `CHANGELOG.md` or generated release notes, current as of the last tag. 3 when generated from commits or PRs.

### Phase 8 · Ops

Often outside the repository: rate what is visible, leave the rest unrated.

- **8.1 Observability configured** (H). Structured logs, metrics, traces in application config; dashboards referenced. 3 with documented dashboards and alerts.
- **8.2 Runbooks** (C). `docs/runbooks/`, `docs/troubleshooting/`, on-call procedures. 3 when updated in the last 90 days.
- **8.3 Observation period** (W). Written: a delivery is observed 7 to 14 days before flag removal or closure. 3 with a trace on a recent delivery.
- **8.4 Errors never swallowed** (G). Written rule against silent exceptions; detection by lint or learned rule. 3 with executable detection.

### Phase 9 · Compound-2 (capitalisation from production)

- **9.1 Postmortems** (C). Blameless template, incident directory. 3 with a postmortem in the last 90 days.
- **9.2 From incident to rule** (W). The capture command has an incident mode asking why pre-release gates missed it. 3 when a catalogue rule cites an incident.
- **9.3 Back to Plan** (C). Production rules visible to the planner. 2 when it is the same catalogue as Compound-1; 3 with a plan citing an incident rule.

### Phase 10 · Deprecation

- **10.1 Deprecation policy** (C). API versioning, deprecation headers or warnings, announced delay. 3 when applied on a recent removal.
- **10.2 Flag and dead-code removal** (W). Cleanup issues or label, removal date in flag definitions. 3 with removals visible in recent history.
- **10.3 Dependency hygiene** (H). `dependabot.yml`, `renovate.json`, dependency audit in CI. 3 with update PRs merged recently.

## Step 3 — Verdict, axes, gaps

Axis means: average the rated criteria per axis (H, C, W, G).

Verdict, from phases, not from the overall mean:

| Verdict | Condition |
|---|---|
| **Not ready** | a blocking criterion at 0 in phase 0, 1 or 4 |
| **Ready for Setup** | no blocking criterion at 0; phases 0, 1 and 4 at least emerging |
| **Tooled cycle** | phases 0 to 6 at least tooled (≥ 2) and criterion 7.1 ≥ 2 |
| **Governed cycle** | phases 0 to 7 tooled, at least four of them governed (= 3), and phase 9 ≥ 2 |

Gaps: every criterion scored below 2. Order them: blocking criteria at 0 or 1 first, in phase order;
then phases 0 to 2; then phases 4 and 5; then the rest in phase order. For each gap give the missing
proof, a realistic target (usually 2), and what closes it: `init` (constitution, labels, templates,
skills, rule catalogue), `gates` (gate detection, CI parity, preflight, proof discipline),
`context` (stale or duplicated context), `compound` (rule capture), or a human action when no aifier
command applies (branch protection, observability, release process).

## Step 4 — Report

Write the report in the language of the repository's README (default English), to standard output
and, if the caller gave an output path, to that file **outside** the audited repository. Format:

```
# assess · <repo> · <date>

Verdict: <level>                 Sources: git + forge | git only
Default branch: <name>           Last commit: <date>

| Phase | Score | Level | Blocking |
|---|---|---|---|
| 0 Setup | 2.4 | tooled | ok |
| 1 Define | 1.0 | emerging | 1.1 at 1 |
| ... | | | |

Axes: C <n> · W <n> · G <n> · H <n>
Hosts detected: <0.4 findings>

## Prioritised gaps
1. [1.1 blocking] Issue templates missing — proof: .github/ISSUE_TEMPLATE/ absent — target 2 — `init`
2. ...

## Detail by criterion
### Phase 0 · Setup
- 0.1 (C) 2 — AGENTS.md, 89 lines, maps to back/front/e2e guides; last change 2026-07-02 (> 90 days) so capped at 2
- 0.2 (C) 3 — back/AGENTS.md, front/AGENTS.md, e2e/AGENTS.md; rules are imperative and checkable
- 0.4 (C) informative — .claude/ only, hand-written
- ...
- 3.1 (W) unrated — forge unavailable (gh: not authenticated)
```

Rules for the report:

- Every rated line cites a path, a command with its relevant output, or a sample count.
- Never invent a file or a number. If you did not read it, you did not see it.
- Unrated is a verdict in itself: say what source would rate it.
- Keep opinions out of the detail; put them, briefly, in the gaps.

## Important rules

- Read-only. No write, no label change, no comment, no build, no test run in the audited repository.
- No sub-agents. Do the reading yourself.
- The 90-day rule caps at 2; it never lowers a score to 1 or 0.
- A blocking criterion at 0 caps the phase at 1 even if every other criterion is 3.
- Do not score what you cannot see: the forge unavailable means unrated, not absent.
