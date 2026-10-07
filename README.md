# aifier

AI-fy the software development lifecycle of an existing project.

aifier is a method and a set of commands that take a classic repository and bring it to the
"Setup" phase of the AI-augmented SDLC: a constitution for agents, explicit verification gates,
an issue-based workflow with human gates, and a catalogue of learned rules that grows with the
project.

It is host-agnostic: the knowledge lives in portable skills (`SKILL.md`), and thin adapters are
generated for Claude Code, opencode and pi.

## Method

The method follows the AI-augmented SDLC: eleven phases, three human gates (intent, architecture,
acceptance) and two capitalisation points (pre-release and runtime). See [method/phases.md](method/phases.md)
and the [assess evaluation grid](method/assess.md).

## Commands

| Command | Phase | Purpose |
|---|---|---|
| `assess` | 0 Setup | Maturity audit of a repository: harnessability, context, workflow, gates |
| `init` | 0 Setup | Generate AGENTS.md, `aifier.yml`, labels, issue/PR templates, skills |
| `gates` | 4 Verify | Detect and declare lint / typecheck / test / build gates, check they run |
| `context` | CDLC | Audit the context fed to agents: rot, hot/warm/cold split, session load |
| `compound` | 6 / 9 | Capture a lesson as a learned rule (pre-release or incident mode) |
| `status` | all | Where the project stands against the eleven phases |

## Layout

```
method/          the method, one page per phase and per concept
skills/          portable skills: process rules, verification evidence, compound, review
packs/           optional stack packs (python-hexagonal, react, playwright, ...)
adapters/        generators for .claude/, .opencode/ and pi
```

## Status

Early design. Distilled from an internal agent framework run on a production GenAI platform; the method itself follows the publicly documented AI-augmented SDLC (https://www.sfeir.com/concepts/sdlc-augmente/).
