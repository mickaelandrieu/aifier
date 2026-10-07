# aifier

**Make your existing codebase a place where AI agents can work safely.**

aifier audits a repository, tells you exactly what is missing for coding agents to operate under
human control, then installs it: a constitution for agents, verification gates with proof, an
issue-based workflow with human gates, and a catalogue of learned rules that grows with every cycle.

It is a method first and a toolkit second. Everything it installs is plain Markdown and YAML,
versioned in your repo, and portable across Claude Code, opencode and pi.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status: early design](https://img.shields.io/badge/status-early%20design-orange.svg)](#status)

---

## Who it is for

- **Tech leads and architects** who want to let agents touch a real, aging codebase without
  giving up control of intent, architecture and release.
- **Teams already using Claude Code, Cursor, opencode or Copilot** who feel the agent "doesn't know
  the project": wrong conventions, repeated mistakes, confident claims that nothing proves.
- **Platform and DevEx engineers** asked to "roll out AI" across many repositories with one
  consistent, auditable setup.
- **Consultants and coaches** who need a repeatable way to assess a client's readiness and bring
  a project to a known state.

If you have one agent working on a weekend side project, you do not need aifier. If you have a
team, a backlog, a CI and something in production, you do.

## The problem it solves

Agents are good at writing code and bad at knowing where they are. Dropped into an existing
repository they:

- ignore conventions nobody wrote down, and reinvent what already exists;
- make the same mistake in every session, because nothing remembers the last review;
- say "tests pass" without the output to prove it;
- decide intent, architecture and merge on their own, because nothing told them to stop.

The usual answer is a longer prompt. It does not scale. What scales is a **harness**: written
context at the right altitude, mechanical gates that produce evidence, a workflow that stops at the
decisions humans must own, and a loop that turns every lesson into a rule.

## What you get

aifier brings a repository to the **Setup** phase of the
[AI-augmented SDLC](https://www.sfeir.com/concepts/sdlc-augmente/): eleven phases, three human
gates (intent, architecture, acceptance), two capitalisation points (before release, from
production).

| Command | Phase | What it does |
|---|---|---|
| `assess` | 0 Setup | Read-only maturity audit, phase by phase: a score, a verdict, prioritised gaps, each tied to the command that closes it. See the [evaluation grid](method/assess.md). |
| `init` | 0 Setup | Generates `AGENTS.md`, `aifier.yml`, workflow labels, two-audience issue templates and a PR template with a validation section; installs the portable skills and the starter rule catalogue; proposes stack packs. |
| `gates` | 4 Verify | Detects lint, typecheck, test and build commands, declares them, checks they actually run, and installs an environment preflight so a "tests pass" verdict can be trusted. |
| `context` | CDLC | Audits what agents read: stale files, duplicated knowledge, hot / warm / cold tiering, load per session. |
| `compound` | 6 and 9 | Captures a lesson as a learned rule, with a wrong example, a right example and an executable detection. Two modes: pre-release and incident. |
| `status` | all | Where the project stands against the eleven phases, and what the next gap is. |

Installed in your project, nothing more:

```
AGENTS.md                      the constitution: a short map, rules that apply everywhere
aifier.yml                     repo, branches, label prefix, gates, language
.agents/skills/                portable knowledge: process, proof, review, compound
.github/ISSUE_TEMPLATE/        issues readable by a PO on top, technical analysis folded below
.github/PULL_REQUEST_TEMPLATE.md
.claude/ .opencode/ ...        generated adapters, never edited by hand
```

## How it works

1. **Assess.** Run `assess` on the repository. In a few minutes you get a profile over the eleven
   phases and a ranked list of gaps. It reads files, git history and the forge; it changes nothing.
2. **Init.** Run `init`. It writes the constitution, the workflow and the templates, tuned to what
   `assess` found, and installs the skills your agents will load.
3. **Gates.** Run `gates`. From now on every agent deliverable ends with the captured output of
   lint, typecheck, tests and build, or an explicit `BLOCKED` with the reason.
4. **Work the cycle.** Issues are qualified into contracts (human gate), planned as two or three
   distinct approaches (human gate), built one slice at a time, verified with proof, reviewed from
   several angles, and merged by a human (human gate).
5. **Compound.** When a review finds a pattern, or production surfaces an incident, `compound`
   turns it into a rule. Every agent loads the rules on its next run. The tenth cycle is
   mechanically better than the first.

The three human gates are not optional. aifier's agents stop at them by construction: nothing in the
toolkit decides intent, picks an architecture or merges a pull request.

## What you gain

- **Control without babysitting.** Humans hold three decisions. Everything between them is
  delegated, with evidence attached.
- **No claim without proof.** "Tests pass" comes with the command and its output, or it is
  `BLOCKED`. Reviews cannot approve a PR with conflicts or failing checks.
- **Mistakes that do not come back.** A bug seen twice is a hole in the system. The rule catalogue
  closes it for every agent, in every session, from the next run.
- **One setup, many hosts.** The knowledge lives in portable `SKILL.md` files. Switch from Claude
  Code to opencode, or run both, without rewriting your context.
- **A measurable starting point.** `assess` gives you a score you can re-run after each change.
  Teams following this method report fewer correction iterations after about ten cycles
  ([source](https://www.sfeir.com/concepts/sdlc-augmente/)); the grid lets you check that on
  your own repository rather than take it on faith.

## Grounding

aifier does not invent its vocabulary. It implements publicly documented concepts:

- [AI-augmented SDLC](https://www.sfeir.com/concepts/sdlc-augmente/): the eleven phases, three
  gates and two capitalisations.
- [Harness engineering](https://www.sfeir.com/concepts/harness-engineering/): guides before the
  action, sensors after it, and the harnessability of a codebase.
- [Context engineering](https://www.sfeir.com/concepts/context-engineering/) and the
  [CDLC](https://www.sfeir.com/concepts/cdlc/): context as a versioned dependency, in tiers.
- [Issue-based development](https://www.sfeir.com/concepts/issue-based-development/): report a
  gap, let the agent analyse the system, arbitrate the plan, review, capitalise.
- [Context flywheel](https://www.sfeir.com/concepts/context-flywheel/): why the loop compounds.

The method pages live in [`method/`](method/), starting with the
[eleven phases](method/phases.md) and the [assess grid](method/assess.md).

## Layout

```
method/          the method, one page per phase and per concept
skills/          portable skills: process rules, verification evidence, compound, review
packs/           optional stack packs (python-hexagonal, react, playwright, ...)
adapters/        generators for .claude/, .opencode/ and pi
```

## Status

Early design, documentation first. The method and the `assess` grid are written; the commands are
being extracted from an agent framework that has run for months on a production GenAI platform,
with a label-driven workflow, a proof discipline and a catalogue of twenty-plus learned rules.

Star the repository to follow the release of `assess`, and open an issue if you want to try the
grid on your own codebase before the tooling lands.

## License

[MIT](LICENSE).
