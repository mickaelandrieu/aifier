# The `assess` scoring grid

`assess` is a read-only maturity audit. It walks an existing repository, phase by phase of the
[AI-augmented SDLC](phases.md), and answers a single question: **what is missing for agents to be
able to work here under human gates, with proof?** It changes nothing; it produces a profile per
phase and a prioritised list of gaps, each tied to the aifier command that closes it.

## Scoring principles

Each criterion receives a score from 0 to 3. The score says whether the practice exists and whether
it is **proven**, not whether it is elegant.

| Score | Level | What the auditor observed |
|---|---|---|
| 0 | absent | No trace in the repository or in the forge |
| 1 | ad hoc | Traces (commits, issues, scattered files) but nothing written or tooled |
| 2 | declared | Written and tooled (file, template, config, command) but no proof that it applies |
| 3 | governed | Declared **and** verified by recent proof: a CI run, a sample of conforming issues or PRs, active branch protection |

Aggregation rules:

- **Phase score** = average of the evaluated criteria, rounded to one decimal.
- A criterion marked **blocking** at 0 caps the phase at 1. A gate without a human stop is not half
  a gate; it is a missing gate.
- A criterion the auditor cannot verify (forge unreachable, `gh` refused, no visible production) is
  marked **not evaluated** and excluded from the average. It is never counted as 0.
- Criteria scored 3 require proof dated less than **90 days** ago (last CI run, last issue, last
  commit on the file). Beyond that, the score drops back to 2: a practice no longer exercised is
  declared, not governed.
- A **dormant** repository (no commit in 90 days) is reported once, in the risks, with the date of
  the last commit. The cap at 2 applies there to the criteria that require a recent practice
  (samples of issues and PRs, CI runs), not to declared artefacts whose presence is enough for the
  targeted level.

Phase levels: **absent** (< 1), **emerging** (1 to 1.9), **tooled** (2 to 2.7), **governed** (≥ 2.8).

Conventions that remove the edge cases:

- percentage thresholds are **inclusive**: "70 %" reads "14 out of 20 pass";
- **branch protection** is judged on the branches that received the PRs of the sample, not only on
  the default branch; if the default branch is protected but the branch that receives most merges is
  not, criteria 3.1, 5.1, 5.4, 5.5 and 7.1 are capped at 2 and the fact becomes a **risk**;
- a review run by an agent that the PR author launched is **not** an independent review;
- a **framework with nothing declared** (empty flag enum, coverage thresholds never run in CI, a
  required check whose name no longer matches anything) is worth 1, not 2;
- a constitution that **copies the rules of a skill** instead of linking to it is duplicated
  context: 0.3 capped at 2;
- the structure of an issue counts whether it comes from the forge template or from a qualification
  agent that rewrote it: the written contract is scored, not its origin.

Each criterion carries an **axis** used for the second reading of the report:

- **H** harnessability: does the codebase let itself be harnessed (typing, boundaries, tooling)?
- **C** context: is what the agents read written, tiered, up to date?
- **W** workflow: do the issues, branches, labels and PRs carry the cycle and its gates?
- **G** verification gates: lint, typecheck, tests, build, review, with proof.

## Sources of proof

`assess` reads only verifiable things:

- the repository tree and its history (`git log`, `git show`), without running the project's code;
- the configuration files of the agent hosts: `AGENTS.md`, `CLAUDE.md`, `.cursorrules`,
  `GEMINI.md`, `.agents/skills/`, `.claude/`, `.opencode/`, `.github/copilot-instructions.md`;
- the forge files: `.github/`, `.gitlab/`, `.gitlab-ci.yml`, `cloudbuild.yaml`,
  `CODEOWNERS`, `CONTRIBUTING.md`, `CHANGELOG.md`, `docs/`;
- the forge itself when it is reachable (`gh` or `glab`): branch protections, labels, a sample of
  the last 20 issues and the last 20 merged PRs, the latest CI runs.

The gate commands are not run by `assess`; that is the role of `gates`. `assess` observes that they
are declared and that a CI has run them.

---

## Phase 0 · Setup

The frame in which the agents work. Everything else rests on it.

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 0.1 | **Agent constitution** (blocking) | C | A root file read by the hosts (`AGENTS.md`, otherwise `CLAUDE.md` or equivalent) | 0 none · 1 a generated file not maintained, or > 300 lines of prose · 2 a short file that acts as a map and links to guides per area · 3 the same, and every referenced file exists and was modified less than 90 days ago |
| 0.2 | **Guides per area** | C | A guide in each sub-project (`back/AGENTS.md`, `front/AGENTS.md`, `e2e/AGENTS.md`...) | 0 none · 1 a single guide for a multi-stack monorepo · 2 one guide per area · 3 each guide states verifiable rules, not a description |
| 0.3 | **Knowledge packaged as skills** | C | `SKILL.md` folders (`.agents/skills/`, `.claude/skills/`) with `name` and `description` | 0 none · 1 scattered prompts · 2 named and described skills · 3 the skills are loaded by identifiable agents or commands, no duplicated content between skills and constitution |
| 0.4 | **Agent engines detected** (informative, not scored) | C | Engine folders present, tracked or ignored by git, generic or project-specific content, stale working copies | Reported as is: portability is a tooling choice, not a maturity level of the cycle |
| 0.5 | **Code harnessability** | H | Typing enabled (`tsconfig` `strict`, `mypy`/`pyright` configured, equivalents), formatter and linter configured, module boundaries (packages, workspaces) | 0 nothing · 1 linter only · 2 typing and linter configured · 3 strict typing run in CI and explicit boundaries |
| 0.6 | **Environment bootstrap** | H | `Makefile`, `justfile`, `scripts/`, `.env.example`, `devcontainer.json`, install section of the README | 0 nothing · 1 a narrative README · 2 a documented bootstrap command · 3 the CI invokes the same script or the same target, including in a container image |
| 0.7 | **Delegation scope** | W | A text that says what the agents do not do (merge, intent, architecture, critical areas) | 0 nothing · 2 written in the constitution or `CONTRIBUTING.md` · 3 the agent instructions explicitly stop at the gates |
| 0.8 | **No secret in the repository** (blocking) | H | Files tracked by git without any API key, password, token or session secret; `.env*` ignored; secret scanner configured | 0 a real secret tracked by git · 1 demo values hard-coded in the configuration (compose, CI) without a scanner · 2 nothing tracked, `.env.example` alone carries the names · 3 the same, and a scanner blocks in CI or in a hook |

## Phase 1 · Define — human gate of intent

An idea becomes a contract readable by someone who will never open the code.

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 1.1 | **Issue templates** (blocking) | W | `.github/ISSUE_TEMPLATE/*.yml` or `.gitlab/issue_templates/` | 0 none · 1 a free-form template · 2 fields for problem, expected behaviour, acceptance criteria · 3 the last 20 issues follow the structure at 70 % or more |
| 1.2 | **Two audiences** | W | An upper part in business language (problem, impact, observable criteria) and a folded technical part | 0 everything mixed · 2 the separation is in the template · 3 a sample of issues respects it |
| 1.3 | **Observable acceptance criteria** | W | Phrased "when X, then Y", verifiable without reading the code | 0 absent · 1 present but technical · 2 present and behavioural in the template · 3 present in 70 % or more of the recently closed issues |
| 1.4 | **Tooled qualification** | W | A command or a skill that rewrites a raw issue into the contract, and a "qualified" state (label); aifier renders `qualify` | 0 nothing · 2 the command exists · 3 the state is set on recent issues |
| 1.5 | **Human stop on intent** | W | The qualified issue waits for a human validation before plan or build: after `qualify` the issue stays in the state `proposed` until its author replies `contract: ok` (a comment, like `approach: <letter>` for the architecture gate); aifier renders `qualify` | 0 the agent goes on · 2 the stop is written in the instructions · 3 the `contract: ok` replies are visible on recent issues |

## Phase 2 · Plan — human gate of architecture

Several approaches, a human chooses, before any code.

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 2.1 | **Architecture decisions recorded** | C | `docs/adr/`, `docs/decisions/`, ADR format or equivalent | 0 none · 1 a narrative architecture page · 2 dated ADRs · 3 at least one ADR less than 90 days old and an ADR template |
| 2.2 | **Alternative approaches** | W | A command or a skill that produces two or three distinct approaches with trade-offs and a recommendation; aifier renders `plan` | 0 nothing · 1 plans in `docs/plans/` without alternatives · 2 the command exists and requires approaches that diverge in strategy · 3 recent issues or plans show the decision |
| 2.3 | **Stop at the gate** (blocking) | W | The planner never builds; a human chooses (comment, label, "chosen approach" field); `build` requires that choice; aifier renders `plan`, which stops until a human replies `approach: <letter>` | 0 the agent chooses and builds · 2 the stop is written in the instructions · 3 the trace of the human decision is visible on recent issues |
| 2.4 | **Learned rules consulted at plan time** | C | The planner loads the catalogue of learned rules | 0 no catalogue · 2 the catalogue is referenced by the planner · 3 a recent plan cites a rule |
| 2.5 | **Grounding in the code** | C | The plan's claims are tagged verified (`file:line`) or inferred | 0 nothing · 2 the convention is written · 3 applied in a recent plan |

## Phase 3 · Build

One slice at a time, under written conventions.

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 3.1 | **Branches and protected base** | W | Written branch convention, protection of the branches that receive the PRs of the sample (`gh api repos/:owner/:repo/branches/<branch>/protection`) | 0 direct commits on the base · 1 oral convention · 2 written convention · 3 protection active on those branches: no direct push, no force push, administrators not exempted |
| 3.2 | **Conventional commits** | W | `commitlint`, hook, or ratio over the last 100 commits | 0 < 30 % · 1 < 70 % · 2 ≥ 70 % · 3 ≥ 90 % or enforced by hook or CI |
| 3.3 | **Written code conventions** | C | Style guides per language, linter and formatter configuration, `CODEOWNERS` | 0 nothing · 1 linter only · 2 written guide and config · 3 guide loaded by the build agents |
| 3.4 | **Catalogue of learned rules loaded at build time** | C | Build agents or skills that load the catalogue; aifier renders `build` | 0 no catalogue · 2 loaded · 3 loaded, and the catalogue has changed less than 90 days ago |
| 3.5 | **Tests are part of the change** | G | Ratio of the last 20 merged PRs that touch test files | 0 < 20 % · 1 < 50 % · 2 ≥ 50 % · 3 ≥ 70 % and the rule is written |
| 3.6 | **One slice per PR** | W | Median size of the last 20 merged PRs (files changed), issues linked by API reference **or** keyword in the body (the forge does not resolve `Closes #N` outside the default branch); aifier renders `build` | 0 catch-all PRs without an issue · 1 linked but large PRs · 2 median under 20 files and a linked issue · 3 the same with `Closes #N` or equivalent systematically |

## Phase 4 · Verify

The gates exist, run, and leave proof.

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 4.1 | **Declared gates** (blocking) | G | Discoverable lint, typecheck, test, build commands (`package.json` scripts, `pyproject.toml`, `Makefile`, `justfile`) | 0 none · 1 some · 2 the four families present in each sub-project · 3 the four grouped under a single documented command |
| 4.2 | **Gates run in CI** | G | `.github/workflows/`, `.gitlab-ci.yml`, `cloudbuild.yaml` that run the same commands | 0 no CI · 1 partial CI · 2 the four families in CI · 3 checks required before merge, whose names match the checks actually reported on a recent PR |
| 4.3 | **Local / CI parity** | G | The CI calls the same commands as the local doc; an environment preflight exists | 0 different commands · 2 same commands · 3 preflight written and enforced before any verdict |
| 4.4 | **Measured coverage** | G | Coverage report in CI, threshold or trend | 0 none · 1 thresholds configured but no CI step measures · 2 measured in CI · 3 blocking threshold |
| 4.5 | **Proof discipline** | G | The agent instructions require the captured output of the commands and a `BLOCKED` verdict when a check cannot run; the PR template has a validation section | 0 nothing · 1 a free-form "tests" section · 2 the rule is written and the template requires it · 3 recent PRs contain the output of the commands |
| 4.6 | **Behaviour tests** | G | Written rule against tests coupled to the implementation (mocks that verify calls, fixtures that recompute the result) | 0 nothing · 2 written rule · 3 included in the review checklist |

## Phase 5 · Review

Several eyes, one verdict, and the review feeds the rules.

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 5.1 | **Review required before merge** (blocking) | W | Branch protection: at least one approval required, `CODEOWNERS` | 0 free merge · 1 convention · 2 active protection · 3 code owners designated per area |
| 5.2 | **Written review checklist** | C | Sections for architecture, quality, security, coverage, test quality; report template | 0 nothing · 1 informal list · 2 complete checklist · 3 loaded by the review agents |
| 5.3 | **Automated review** | G | Review command or skill that posts findings on the PR; several angles in parallel (code, architecture, security, QA) | 0 nothing · 1 a lint bot · 2 an agent review on demand · 3 several angles consolidated, findings visible on recent PRs |
| 5.4 | **PR health gate** | G | No approval possible with conflicts or failing checks | 0 nothing · 2 written rule · 3 enforced by branch protection or automated review |
| 5.5 | **The author does not approve their own work** | W | The PR is never marked ready by whoever produced it, human or agent launched by the author | 0 self-approval · 2 written · 3 the sample shows the "ok" state set by an independent third party |
| 5.6 | **The review proposes rules** | W | The review process includes "should this finding become a learned rule?" | 0 nothing · 2 written · 3 a recent rule comes from a review |

## Phase 6 · Compound-1 — compounding before delivery

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 6.1 | **Catalogue of learned rules** (blocking) | C | A canonical file of numbered rules: severity, rule, wrong example, right example, detection method | 0 nothing · 1 scattered notes (`docs/solutions/`, wiki) · 2 the catalogue in the full format · 3 every code rule has an executable detection (process rules may stay in prose) |
| 6.2 | **Capture command** | W | A command that extracts the lessons, de-duplicates against the catalogue and persists | 0 nothing · 2 the command exists · 3 the catalogue received a rule less than 90 days ago |
| 6.3 | **Feedback into the cycle** | C | The catalogue is loaded by the plan, build and review agents | 0 not loaded · 2 loaded by at least one · 3 loaded by all three |
| 6.4 | **Quality of the rules** | C | Each rule is a repeatable pattern, not a closed ticket nor a lint rule | 0 not applicable · 2 written admission criterion · 3 conforming sample |
| 6.5 | **A clean session produces nothing** (informative, not scored) | W | It is written that the absence of a lesson is a valid result | Reported as is |

## Phase 7 · Ship — human gate of acceptance

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 7.1 | **Only a human merges** (blocking) | W | Agent instructions without `merge`; branch protection; no auto-merge | 0 an agent merges · 2 written · 3 active protection and no bot among the recent merge authors |
| 7.2 | **Release checklist** | W | `RELEASE.md`, section of `CONTRIBUTING.md`, release template | 0 nothing · 1 tribal · 2 written · 3 followed in the latest releases (tags, notes) |
| 7.3 | **Rollback written in advance** | W | Rollback procedure documented before deployment, per type of change (code, schema, config) | 0 nothing · 2 written · 3 tested or referenced in the risky PRs |
| 7.4 | **Progressive deployment** | H | Feature flags, canary, traffic percentage in the deployment config | 0 all or nothing · 1 a flag framework with no flag declared · 2 mechanism declared and used · 3 used on a recent delivery |
| 7.5 | **Changelog** | C | `CHANGELOG.md` or generated release notes, up to date with the last tag | 0 nothing · 1 stale · 2 up to date · 3 generated from the commits or PRs |

## Phase 8 · Ops

Often outside the repository. `assess` scores what is visible and marks the rest not evaluated.

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 8.1 | **Observability configured** | H | Structured logs, metrics, traces in the application config; dashboards referenced | 0 `print` · 1 logs only · 2 structured logs and metrics · 3 dashboards and alerts documented |
| 8.2 | **Runbooks** | C | `docs/runbooks/`, `docs/troubleshooting/`, on-call procedures | 0 nothing · 1 one page · 2 per incident type · 3 updated less than 90 days ago |
| 8.3 | **Observation period** | W | It is written that a delivery is observed 7 to 14 days before the flag is removed or the issue closed | 0 nothing · 2 written · 3 trace on a recent delivery |
| 8.4 | **Errors never swallowed** | G | Written rule against silent exceptions; detection by lint or learned rule | 0 nothing · 2 written rule · 3 executable detection |

## Phase 9 · Compound-2 — compounding from production

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 9.1 | **Postmortems** | C | Postmortem template, incident folder, blameless | 0 nothing · 1 incident tickets · 2 template and folder · 3 a postmortem less than 90 days old |
| 9.2 | **From the incident to the rule** | W | The capture command accepts an incident mode and asks why the pre-release gates did not catch the problem | 0 nothing · 2 the mode exists · 3 a rule of the catalogue cites an incident |
| 9.3 | **Back to the Plan** | C | The rules that come from production are visible to the planner | 0 nothing · 2 same catalogue as Compound-1 · 3 proof of a plan that cites an incident rule |

## Phase 10 · Deprecation

| # | Criterion | Axis | Expected proof | 0 → 3 |
|---|---|---|---|---|
| 10.1 | **Deprecation policy** | C | API versioning, deprecation headers or warnings, announced delay | 0 hard removal · 1 case by case · 2 written policy · 3 applied on a recent removal |
| 10.2 | **Removal of flags and dead code** | W | Cleanup issues or label, removal date in the flag definitions | 0 eternal flags · 2 written tracking · 3 removals visible in the recent history |
| 10.3 | **Dependency hygiene** | H | `dependabot.yml`, `renovate.json`, dependency audit in CI | 0 nothing · 1 manual audit · 2 tool configured · 3 update PRs merged recently |

---

## Reading by axis

The report also gives the average of the criteria per axis. It serves to name the dominant work
area:

| Weak axis | Reading | aifier command |
|---|---|---|
| C context | The agents do not know where they are: constitution absent, stale or monolithic | `init` then `context` |
| W workflow | The gates have no support: no states, no templates, free merge | `init` (labels, templates, workflow), then `qualify`, `plan` and `build` to run the cycle on the issues |
| G verification gates | Nothing proves that it works | `gates` |
| H harnessability | The code itself resists: no typing, no boundaries, no observability | outside aifier; recommendations in the report |

## Overall verdict

The profile matters more than a single score. `assess` nevertheless draws a verdict on four levels,
based on the phases and not on the average:

| Verdict | Condition |
|---|---|
| **Not ready** | A blocking criterion at 0 in phases 0, 1 or 4 (0.8 at 0 is enough) |
| **Ready for Setup** | No blocking criterion at 0; phases 0, 1, 4 at least emerging |
| **Tooled cycle** | Phases 0 to 6 at least tooled (≥ 2) and criterion 7.1 ≥ 2 |
| **Governed cycle** | Phases 0 to 7 tooled, of which at least four governed (≥ 2.8), and phase 9 ≥ 2 |

Phases 8 and 10, and the rest of phase 7, do not condition the "tooled" verdict: their substance
often lives outside the repository, in the deployment pipeline. They appear in the profile and in
the gaps.

## Prioritised gaps

Every criterion scored under 2 becomes a gap. The order of priority:

1. **blocking** criteria at 0 or 1, in phase order;
2. criteria of phases 0 to 2 (upstream conditions everything);
3. criteria of phases 4 and 5 (without proof, the rest is trust);
4. the rest, in phase order.

Each gap is rendered with: the missing proof, the realistic target score (often 2, not 3), and the
aifier command or the human action that closes it. For the workflow criteria, that command is the
cycle skill that provides the practice: `qualify` for 1.4 and 1.5, `plan` for 2.2 and 2.3, `build`
for 3.4 and 3.6, `compound` for 6.2 and 9.2.

## Risks

Some observations bring no criterion under 2 and yet undermine several criteria at once. They have
their own section, before the detail: a branch receiving the merges without protection, required
checks whose name matches no reported check, force push allowed or administrators exempted, a
readiness label set by the author's agent, coverage configured but never run. A risk cites its
proof, the criteria affected and the action.

## Report format

```
# assess · <repository> · <date>

Verdict: <level>              Sources: git, forge (gh) | git only
Branches receiving the merges: <names>     90-day window since: <date>
Reason for the verdict: <one line citing the decisive phases and criteria>

| Phase | Score | Level | Blocking |
|---|---|---|---|
| 0 Setup | 2.4 | tooled | ok |
| 1 Define | 1.0 | emerging | 1.1 at 1 |
| ...

Axes: C 2.1 · W 1.4 · G 2.6 · H 2.0

## Prioritised gaps
1. [1.1 blocking] Issue templates absent — proof: .github/ISSUE_TEMPLATE/ empty — target 2 — `init`
2. ...

## Risks
- <observation> — proof — criteria affected — action

## Detail per criterion
<criterion, score, observed proof (path, or command and output), not evaluated if applicable>
```

The detail cites the proof for every score, in the spirit of the proof discipline that the grid
itself evaluates. A criterion without a cited proof has no score.

## Calibration

The grid is checked on two reference repositories before it is held to be right. The results stay
outside the aifier repository; only the expectations appear here.

| Reference | Profile | Expected verdict | If the verdict differs |
|---|---|---|---|
| Advanced project | constitution as a map, guides per area, living skills and rule catalogue, gates in CI with proof, label-based workflow, multi-angle reviews | **Tooled cycle**, close to governed; phases 8, 9 and 10 lagging | the grid or the probes are too severe |
| Classic project | test CI and linter present, one monolithic context file, no issue template, no catalogue, merge without required review | **Ready for Setup** at best, with 1.1 and 6.1 as blocking gaps | the grid scores presence and not practice |

A difference between expected and obtained is a finding about the grid, to be fixed in the grid,
never by adjusting a score by hand.

## What the grid does not measure

- the quality of the code or of the architecture as such: only their **harnessability**;
- velocity, cost per feature or rework rate: those are outcome metrics of the cycle, to be
  instrumented elsewhere;
- the relevance of the context in depth (rot, load per session, tiers): that is the role of
  `context`, of which `assess` takes only a sample in phase 0.
