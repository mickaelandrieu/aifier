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

aifier is a **generator**. It runs when you install it and when you update it, and never
afterwards. It inspects your repository, asks what it cannot infer, and renders files for the
engine you use: Claude Code, opencode or pi. Those files work on their own. Nothing in the daily
life of the project calls aifier.

```sh
curl -fsSL https://raw.githubusercontent.com/mickaelandrieu/aifier/main/install.sh | sh
aifier init      # detect, ask, render
aifier update    # refresh generated files, leave yours alone
aifier remove    # remove exactly what was installed
```

What `init` renders into your project:

| Rendered | Role |
|---|---|
| `AGENTS.md` | the constitution: a short map, rules that apply everywhere, pointers to area guides |
| `aifier.yml` | repo, branches, label prefix, gates, language, chosen guards |
| Skills | run by your engine as slash commands: `/assess`, `/gates`, `/context`, `/compound`, `/status`, plus knowledge skills (proof discipline, review checklist, adversarial test plan, ADR and documentation rules) |
| Guards | standalone hooks for your engine that constrain what the model reads and writes: protected paths, forbidden git operations, secrets, a required verification section before the agent stops |
| Memory | the learned-rules catalogue, the decision journal (ADRs) and the session handoff file, all plain Markdown in git |
| Workflow | two-audience issue templates, a PR template with a validation section, workflow labels |

The skills, once in your project:

| Skill | Phase | What it does |
|---|---|---|
| `/assess` | 0 Setup | Read-only maturity audit, phase by phase: a score, a verdict, prioritised gaps and risks. Re-run it any time to see where the project stands. See the [evaluation grid](method/assess.md). |
| `/gates` | 4 Verify | Detects lint, typecheck, test and build commands, declares them, checks they run, installs an environment preflight so a "tests pass" verdict can be trusted. |
| `/context` | CDLC | Audits what agents read: stale files, duplicated knowledge, hot / warm / cold tiering, load per session. |
| `/compound` | 6 and 9 | Captures a lesson as a learned rule, with a wrong example, a right example and an executable detection. Two modes: pre-release and incident. |
| `/status` | all | Where the project stands against the eleven phases, and the next gap. |

## How it works

1. **Install and init.** One `curl | sh`, then `aifier init`. aifier detects your stack,
   architecture decisions, CI and engines, shows the manifest it inferred, asks the rest, and
   renders. Existing files are never overwritten silently.
2. **Assess.** Run `/assess` in your engine. You get a profile over the eleven phases, prioritised
   gaps and risks. It reads files, git history and the forge; it changes nothing.
3. **Gates.** Run `/gates`. From now on every agent deliverable ends with the captured output of
   lint, typecheck, tests and build, or an explicit `BLOCKED` with the reason.
4. **Work the cycle.** Issues are qualified into contracts (human gate), planned as two or three
   distinct approaches (human gate), built one slice at a time under the guards, verified with
   proof, reviewed from several angles, and merged by a human (human gate).
5. **Compound.** When a review finds a pattern, or production surfaces an incident, `/compound`
   turns it into a rule. Every agent loads the rules on its next run. The tenth cycle is
   mechanically better than the first.

The three human gates are not optional. The generated skills stop at them by construction, and the
guards refuse the operations that would skip them: nothing decides intent, picks an architecture or
merges a pull request on its own.

## What you gain

- **Control without babysitting.** Humans hold three decisions. Everything between them is
  delegated, with evidence attached.
- **No claim without proof.** "Tests pass" comes with the command and its output, or it is
  `BLOCKED`. Reviews cannot approve a PR with conflicts or failing checks.
- **Mistakes that do not come back.** A bug seen twice is a hole in the system. The rule catalogue
  closes it for every agent, in every session, from the next run.
- **One setup, any engine.** The knowledge lives in portable `SKILL.md` files and the guards are
  rendered for Claude Code, opencode or pi. Switch engine, or run two, without rewriting your
  context.
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
skills/          templates of the portable skills rendered into your project
packs/           optional stack packs (python-hexagonal, react, playwright, ...)
adapters/        per-engine rendering: layouts, hooks, memory for Claude Code, opencode and pi
```

## Status

Early design, documentation first. The method, the `assess` grid and the `/assess` skill are
written and the skill has been run end to end on a production codebase. Its evidence collector,
`skills/assess/probes.sh`, runs on its own against any repository (`git`, plus `gh` and `jq` for
the forge section). The generator is
specified in [issue #1](https://github.com/mickaelandrieu/aifier/issues/1); the other skills in
issues #3 to #6. All of it is distilled from an agent framework that has run for months on a
production GenAI platform, with a label-driven workflow, a proof discipline and a catalogue of
twenty-plus learned rules.

Star the repository to follow the first release, and open an issue if you want to run the grid
on your own codebase before the generator lands.

## License

[MIT](LICENSE).

