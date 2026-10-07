---
name: assess
description: Read-only maturity audit of a repository against the eleven phases of the AI-augmented SDLC. Scores each phase 0-3 from evidence (files, git history, forge), gives a verdict, and lists prioritised gaps and risks tied to the action that closes them. Argument - path to the repository (default - current directory).
---

You are running `assess`. You audit the repository at `$ARGUMENTS` (default: the current directory)
and produce a maturity report. You are self-contained: do not delegate to sub-agents. You are
**read-only**: never write into the audited repository, never run its build, tests or scripts, never
change its labels, issues or pull requests. Only `git` reads, `gh`/`glab` reads and file reads.

The report is only as good as its evidence. Every score cites what you read or ran. A score without
a cited proof is not a score: leave the criterion **unrated** and say why.

## Step 1 — Establish the sources

```bash
cd "$REPO"
git rev-parse --show-toplevel && git branch --show-current
git log -1 --format='%H %cd' --date=short
ORIGIN=$(git remote get-url origin 2>/dev/null)
SLUG=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
```

Record the sources: `git` (always) and `forge` (when `gh` or `glab` answers). Without the forge,
a criterion whose levels 0 to 2 are visible in the repository (a template, a written rule) is
rated from the repository and capped at 2; a criterion whose every level needs the forge (branch
protection, reviews, samples of issues) is **unrated**, never 0. Without a PR sample, the merge
commits on the default branch stand in for it: say "proxy sample" in the report. Note today's date: a proof older than 90 days caps its criterion at 2.

If your shell aborts a command on an unmatched glob (zsh does), run `setopt +o nomatch` first, or
`shopt -s nullglob` in bash. If a command-rewriting proxy sits in front of your shell and an `ls`
prints nothing for files you know exist, use the proxy's raw mode.

Inventory, collected once by the deterministic collector next to this file. It reads the repository
and the forge (when `gh` answers), never executes project code, and prints one Markdown section per
topic (identity, context files, harnessability, tests, CI pipelines, git activity over the last 90
days or the last 100 commits when the window is sparse, forge data, aifier footprint). Every line it
prints is a citable proof; cite it by section and line in the report.

```bash
bash "<directory of this SKILL.md>/probes.sh" "$REPO" > "$OUT/probes.md"
```

Read `$OUT/probes.md` in full before anything else. Without a POSIX shell (native Windows without WSL or
Git Bash), run the same probes yourself with the tools you have, following the script as a
checklist, and say in the report that the collection was manual. Criteria whose evidence the collector does not
reach (reviews on individual PRs, check runs as reported, plans on open issues, grep-only
criteria) use the samples below.

Forge samples (skip when the forge is unavailable; wrap each call in `timeout 60`):

```bash
gh label list --limit 100 --json name -q '.[].name'
gh issue list --state closed --limit 20 --json number,title,body,labels,closedAt > "$OUT/issues.json"
gh pr list --state merged --limit 20 --json number,title,body,files,baseRefName,mergedAt,mergedBy,author,closingIssuesReferences > "$OUT/prs.json"
# protection of EVERY branch that received a sampled PR, plus the default branch; encode "/" as %2F
for b in $(jq -r '.[].baseRefName' "$OUT/prs.json" | sort -u) "$DEFAULT"; do
  gh api "repos/$SLUG/branches/$(printf %s "$b" | sed 's|/|%2F|g')/protection" 2>&1 | head -60
done
gh api "repos/$SLUG/rulesets" 2>/dev/null | head -40
# reviews and comments on the 6 most recent sampled PRs
for n in $(jq -r '.[].number' "$OUT/prs.json" | head -6); do
  gh api "repos/$SLUG/pulls/$n/reviews" --jq '.[] | [.user.login, .state] | @tsv'
  gh api "repos/$SLUG/pulls/$n/comments" --jq 'length'
  gh api "repos/$SLUG/issues/$n/comments" --jq '.[] | .user.login' | sort | uniq -c
done
# CI as actually reported, versus what protection requires
gh pr view $(jq -r '.[0].number' "$OUT/prs.json") --json statusCheckRollup -q '.statusCheckRollup[] | [.name // .context, .conclusion // .state, .completedAt // .startedAt] | @tsv'
# plans live on open or epic issues, not in the closed sample
gh search issues --repo "$SLUG" "Implementation plan" OR "Chosen approach" OR "Approach A" --limit 10 --json number,title,updatedAt
```

Do not run `gh run list`: it hangs on repositories whose CI is not GitHub Actions. Check runs from
any CI provider appear in `statusCheckRollup`. `$OUT` is a directory **outside** the audited
repository.

Git samples the collector does not cover:

```bash
git log -1 --format=%cd --date=short -- <rule catalogue path>
```

Scoring the samples by hand is slow and irreproducible. Write a short throwaway script (any
language, in `$OUT`) that computes, from `issues.json` and `prs.json`: share of issues with a
problem / expected / acceptance structure; share with an acceptance-criteria section; share of PRs
touching a test path (`test`, `tests`, `spec`, `__tests__`, `*.test.*`, `*_test.*`); median changed
files; share with `closingIssuesReferences` **or** a `Closes|Fixes|Resolves #N` body match; merger
versus author; base branches. Quote the numbers in the report.

Grep hints for criteria whose evidence has no standard location (search `docs/`, deployment and
infrastructure directories, application config):

| Criterion | Grep for |
|---|---|
| 7.3 rollback | `rollback`, `roll back`, `revert`, `down migration`, `forward-only` |
| 7.4 progressive delivery | `canary`, `traffic`, `percent`, `feature.?flag`, `unleash`, `launchdarkly`, `flagsmith`, `growthbook` |
| 8.1 observability | `structlog`, `json.?log`, `opentelemetry`, `otel`, `prometheus`, `datadog`, `sentry`, `langfuse`, `dashboard`, `alert` |
| 8.2 runbooks | `runbook`, `on-call`, `oncall`, `troubleshoot`, `recover` |
| 8.3 observation | `observ`, `bake`, `soak`, `monitor.*days` |
| 9.1 postmortems | `postmortem`, `post-mortem`, `incident`, `blameless`, `RCA` |
| 10.1 deprecation | `deprecat`, `Sunset`, `/v[0-9]+/`, `BREAKING` |
| 8.4 swallowed errors | lint config: ruff `S110`, `S112`, `BLE001`; eslint `no-empty`; detection greps in the rule catalogue |

## Step 2 — Score each criterion

Rubric, identical for every criterion:

| Score | Meaning |
|---|---|
| 0 | absent: no trace in the repository or the forge |
| 1 | ad hoc: traces (commits, issues, scattered files) but nothing written or tooled; or tooled but demonstrably never executed |
| 2 | declared: written and tooled (file, template, config, command) but no proof it applies |
| 3 | governed: declared **and** proven by evidence less than 90 days old (CI run, conforming sample of issues or PRs, active branch protection on the branches that actually receive merges) |

Conventions that remove judgement calls:

- Percent thresholds are **inclusive**: "70 %" means 14 of 20 passes.
- **Branch protection** is rated on the branches that received the sampled PRs, not only the
  default branch. If the default branch is protected but the branch receiving most merges is not,
  the protection criteria (3.1, 5.1, 5.4, 5.5, 7.1) are capped at 2 and the fact is a **risk**.
- A review run by an agent that the PR author launched is **not** an independent review.
- A **framework with nothing declared** (a flag enum with zero flags, coverage thresholds never
  run in CI, a required check whose name no longer matches any reported check) is 1, not 2.
- A constitution that **restates a skill's rules** instead of pointing to the skill is duplicated
  context: cap 0.3 at 2.
- Structure in issues counts whether it comes from the forge template or from a qualification agent
  that rewrote the issue: what is rated is the written contract, not its origin.
- Phase level: absent (< 1), emerging (1 to 1.9), tooled (2 to 2.7), governed (≥ 2.8).

Aggregation: phase score = mean of rated criteria, one decimal. A **blocking** criterion at 0 caps
its phase at 1. Unrated and informative criteria are excluded from the mean. Each criterion has an
axis: **H** harnessability, **C** context, **W** workflow, **G** verification gates.

### Phase 0 · Setup

- **0.1 Agent constitution** (blocking, C). Root `AGENTS.md` or equivalent. 1 if generated boilerplate or more than 300 lines of prose; 2 if a short map pointing to area guides; 3 if every referenced file exists and the file changed in the last 90 days.
- **0.2 Area guides** (C). One guide per sub-project in a multi-stack repo. 3 when guides state checkable rules, not descriptions.
- **0.3 Knowledge packaged as skills** (C). `SKILL.md` directories with `name` and `description`. 3 when loaded by identifiable agents or commands and the constitution points to them rather than restating them.
- **0.4 Agent engines detected** (informative, not scored). Engine directories found; tracked or ignored; generic or project-specific content; stale working copies.
- **0.5 Code harnessability** (H). Strict typing configured (`tsconfig` `"strict": true`, `mypy`/`pyright` section, typed language), linter and formatter configured, module boundaries (workspaces, packages). 3 when typing runs in CI (check run visible).
- **0.6 Environment bootstrap** (H). `Makefile`, `justfile`, `scripts/`, `.env.example`, devcontainer, README install section. 3 when the CI invokes the same script or target, including inside a container image.
- **0.7 Delegation scope** (W). A written statement of what agents do not do: merge, decide intent, pick architecture, touch safety-critical zones. 3 when agent instructions explicitly stop at the gates.

### Phase 1 · Define (human gate: intent)

- **1.1 Issue templates** (blocking, W). Forge issue templates. 2 with fields for problem, expected behaviour, acceptance criteria; 3 when 70 % or more of the 20 sampled issues carry that structure, from the template or from a qualification rewrite.
- **1.2 Two audiences** (W). Business-readable top (problem, impact, observable criteria), technical analysis folded below. 3 when the sample respects it.
- **1.3 Observable acceptance criteria** (W). "When X, then Y", checkable without reading code. 3 when present in 70 % or more of sampled closed issues.
- **1.4 Tooled qualification** (W). A command or skill that rewrites a raw issue into the contract, and a workflow state (label) for "qualified". 3 when the state appears on recent issues.
- **1.5 Human stop on intent** (W). The qualified issue waits for human validation before plan or build. 3 when a label materialises the wait and automation does not pick up issues that have not passed it.

### Phase 2 · Plan (human gate: architecture)

Evidence lives on open or epic issues and in issue comments, not in the closed sample: use the
`gh search issues` call above and read the matching comments.

- **2.1 Architecture decisions recorded** (C). ADRs in `docs/adr/` or `docs/decisions/`. 3 with a template and one ADR in the last 90 days.
- **2.2 Alternative approaches** (W). A command or skill producing two or three approaches that differ in strategy, with trade-offs and a recommendation. 3 when a plan posted in the last 90 days shows them.
- **2.3 Stop at the gate** (blocking, W). The planner never builds; a human chooses (comment, label, "chosen approach" field). 3 when a human arbitration is visible on a recent issue.
- **2.4 Learned rules consulted at plan time** (C). The planner loads the rule catalogue. 3 when a recent plan cites a rule.
- **2.5 Grounded claims** (C). Plan claims tagged verified (`file:line`) or inferred. 3 when applied in a recent plan.

### Phase 3 · Build

- **3.1 Branching and protected base** (W). Written branch convention; protection on every branch that received sampled PRs. 3 when direct pushes and force pushes are blocked there and administrators are not exempt.
- **3.2 Conventional commits** (W). Ratio over the last 100 commits: 0 below 30 %, 1 below 70 %, 2 at 70 % or more, 3 at 90 % or more or enforced by a hook or CI.
- **3.3 Written code conventions** (C). Style guides per language, linter and formatter config, `CODEOWNERS`. 3 when loaded by build agents.
- **3.4 Rule catalogue loaded at build** (C). 3 when loaded and the catalogue changed in the last 90 days.
- **3.5 Tests are part of the change** (G). Share of the 20 last merged PRs touching test paths: 0 below 20 %, 1 below 50 %, 2 at 50 % or more, 3 at 70 % or more with the rule written.
- **3.6 One slice per PR** (W). Median changed files over the sample and linked issues (API references **or** body keyword). 2 when median under 20 files with a linked issue on most PRs; 3 when the link is present on 90 % or more.

### Phase 4 · Verify

- **4.1 Gates declared** (blocking, G). Lint, typecheck, test and build-or-package commands discoverable in manifests, `Makefile`, `justfile`. A backend without a build step counts the three families it has. 2 when every sub-project declares its families; 3 when each sub-project exposes one documented command that runs them all, or the root does.
- **4.2 Gates run in CI** (G). CI config runs the same commands and a recent check run succeeded. 3 when the required status checks in branch protection match the names actually reported in `statusCheckRollup`.
- **4.3 Local / CI parity** (G). CI calls the commands the docs give locally; an environment preflight exists. 3 when the preflight is written and required before any verdict.
- **4.4 Coverage measured** (G). 1 when thresholds exist but no CI step runs coverage; 2 when CI measures it; 3 when a threshold blocks.
- **4.5 Proof discipline** (G). Agent instructions require captured command output and a `BLOCKED` verdict when a check cannot run; the PR template has a validation section. 3 when 70 % or more of sampled PRs contain command output.
- **4.6 Behavioural tests** (G). A written rule against implementation-coupled tests. 3 when it is in the review checklist with a blocking consequence.

### Phase 5 · Review

- **5.1 Review required before merge** (blocking, W). Protection on the merge-receiving branches requires at least one approval; `CODEOWNERS`. 3 when sampled PRs show approving reviews by someone other than the author.
- **5.2 Written review checklist** (C). Architecture, quality, security, coverage, test quality; a report template. 3 when loaded by review agents.
- **5.3 Automated review** (G). A command or skill posting findings on PRs, several angles. 3 when findings are visible on sampled PRs (inline comments or a summary comment).
- **5.4 PR health gate** (G). No approval possible with conflicts or failing checks. 3 when enforced by protection on the merge-receiving branches or by automated review with visible effect.
- **5.5 Authors do not approve themselves** (W). Readiness is never set by whoever produced the PR, human or agent run by the author. 3 when the sample shows readiness set by an independent party.
- **5.6 Reviews propose rules** (W). The review process asks whether a finding should become a learned rule. 3 when a rule added in the last 90 days traces to a review (commit or PR that introduced it).

### Phase 6 · Compound-1 (capitalisation before release)

- **6.1 Learned-rules catalogue** (blocking, C). One canonical file of numbered rules with severity, rule, wrong example, right example, detection. 1 for scattered notes; 3 when each code-level rule has an executable detection (process rules may have a prose detection).
- **6.2 Capture command** (W). Extracts lessons, de-duplicates against the catalogue, persists. 3 when the catalogue received a rule in the last 90 days.
- **6.3 Reinjection** (C). Catalogue loaded by plan, build and review agents. 2 for one of them, 3 for all three.
- **6.4 Rule quality** (C). Each rule is a repeatable pattern, not a closed ticket or a lint rule. 2 when the admission criterion is written; 3 when a sample of rules conforms.
- **6.5 A clean session yields nothing** (informative, not scored). Report whether it is written that the absence of a lesson is a valid outcome.

### Phase 7 · Ship (human gate: acceptance)

- **7.1 Only a human merges** (blocking, W). No `merge` in agent instructions, protection on merge-receiving branches, no auto-merge. 3 when no bot appears among sampled merge authors and protection holds on those branches.
- **7.2 Release checklist** (W). Release process documented, release automation. 3 when followed in recent tags or notes.
- **7.3 Rollback written cold** (W). Documented rollback per change type (code, schema, config). 3 when tested or referenced in risky PRs.
- **7.4 Progressive delivery** (H). Feature flags, canary, traffic percentage. 1 when a flag framework exists with no declared flag; 3 when used on a recent delivery.
- **7.5 Changelog** (C). Current as of the last tag. 3 when generated from commits or PRs.

### Phase 8 · Ops

Often outside the repository: rate what is visible, leave the rest unrated.

- **8.1 Observability configured** (H). Structured logs, metrics, traces in application config; dashboards and alerts referenced. 3 with documented dashboards and alert policies.
- **8.2 Runbooks** (C). Troubleshooting or runbook pages, recovery procedures. 3 when updated in the last 90 days.
- **8.3 Observation period** (W). Written: a delivery is observed 7 to 14 days before flag removal or closure. 3 with a trace on a recent delivery.
- **8.4 Errors never swallowed** (G). Written rule against silent exceptions; detection by lint or learned rule. 3 with executable detection running in a hook or CI.

### Phase 9 · Compound-2 (capitalisation from production)

- **9.1 Postmortems** (C). Blameless template, incident directory. 3 with a postmortem in the last 90 days.
- **9.2 From incident to rule** (W). The capture command has an incident mode asking why pre-release gates missed it. 3 when a catalogue rule cites an incident.
- **9.3 Back to Plan** (C). 2 when production rules share the Compound-1 catalogue loaded by the planner; 3 with a plan citing an incident rule.

### Phase 10 · Deprecation

- **10.1 Deprecation policy** (C). API versioning, deprecation markers, announced delay. 3 when applied on a recent removal.
- **10.2 Flag and dead-code removal** (W). Cleanup issues or label, removal date in flag definitions. 3 with removals visible in recent history.
- **10.3 Dependency hygiene** (H). Automated update tool, or vulnerability audit blocking in CI. 2 for one of them; 3 for both, or one plus update PRs merged in the last 90 days.

## Step 3 — Verdict, axes, gaps, risks

Axis means: average the rated criteria per axis (H, C, W, G).

Verdict, from phases, not from the overall mean:

| Verdict | Condition |
|---|---|
| **Not ready** | a blocking criterion at 0 in phase 0, 1 or 4 |
| **Ready for Setup** | no blocking criterion at 0; phases 0, 1 and 4 at least emerging |
| **Tooled cycle** | phases 0 to 6 at least tooled (≥ 2) and criterion 7.1 ≥ 2 |
| **Governed cycle** | phases 0 to 7 tooled, at least four of them governed (≥ 2.8), and phase 9 ≥ 2 |

**Gaps**: every criterion scored below 2. Order: blocking criteria first, in phase order; then
phases 0 to 2; then phases 4 and 5; then the rest. For each gap: the missing proof, a realistic
target (usually 2), and what closes it: `init` (constitution, labels, templates, skills, catalogue),
`gates` (gate detection, CI parity, preflight, proof discipline), `context` (stale or duplicated
context), `compound` (rule capture), or a human action when no command applies (branch protection,
observability, release process).

**Risks**: findings that do not lower a score below 2 but undermine several criteria at once. Always
report: a merge-receiving branch without protection; required checks whose names match nothing
reported; force pushes allowed or administrators exempt; readiness labels set by the author's own
agent; coverage configured but never run. Risks go in their own section, before the detail.

## Step 4 — Report

Write the report in the language of the repository's README (default English). Samples may be in
another language: make your regexes cover both. Write to standard output and, if the caller gave an
output path, to that file **outside** the audited repository. Format:

```
# assess · <repo> · <date>

Verdict: <level>                 Sources: git + forge | git only
Default branch: <name>           Merge-receiving branches in sample: <names>
Last commit: <date>              90-day window starts: <date>

Verdict reasoning: <one line citing the phases and criteria that decided it>

| Phase | Score | Level | Blocking |
|---|---|---|---|
| 0 Setup | 2.4 | tooled | 0.1 at 2 |
| ... | | | |

Axes: C <n> · W <n> · G <n> · H <n>
Engines detected: <0.4 findings>

## Prioritised gaps
1. [1.1 blocking] Issue templates missing — proof: .github/ISSUE_TEMPLATE/ absent — target 2 — `init`

## Risks
- <finding> — proof — criteria affected — action

## Detail by criterion
### Phase 0 · Setup
- 0.1 (C) 2 — AGENTS.md, 120 lines, a map to three area guides; last change <date>, older than 90 days, so capped at 2
- 0.4 (C) informative — one engine directory, project-specific content, tracked in git
- 3.1 (W) unrated — forge unavailable

## Unrated
- <criterion> — <source that would rate it>
```

Rules for the report:

- Every rated line cites a path, a command with its relevant output, or a sample count.
- Never invent a file or a number. If you did not read it, you did not see it.
- Unrated is a verdict in itself: say what source would rate it.
- Keep opinions out of the detail; put them, briefly, in gaps and risks.

## Important rules

- Read-only. No write, no label change, no comment, no build, no test run in the audited repository.
- No sub-agents. Do the reading yourself.
- The 90-day rule caps at 2; it never lowers a score to 1 or 0.
- A blocking criterion at 0 caps the phase at 1 even if every other criterion is 3.
- Do not score what you cannot see: the forge unavailable means unrated, not absent.
