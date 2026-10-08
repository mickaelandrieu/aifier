# The eleven phases of the AI-augmented SDLC

Reference: https://www.sfeir.com/concepts/sdlc-augmente/ (and the related concepts: context-engineering,
harness-engineering, cdlc, issue-based-development, context-flywheel). This page fixes the vocabulary
used by every aifier command. It invents nothing: it numbers.

| No. | Phase | Time | What happens there | Nature |
|---|---|---|---|---|
| 0 | Setup | Upstream | Frame the cycle: agent constitution, declared gates, workflow, knowledge bases | — |
| 1 | Define | Upstream | An idea becomes a contract: problem, impact, observable acceptance criteria | **Human gate** (intent) |
| 2 | Plan | Upstream | Two or three distinct architecture approaches, decided by a human before any code | **Human gate** (architecture) |
| 3 | Build | Core | Build one slice at a time, under the learned rules | — |
| 4 | Verify | Core | Run lint, typecheck, tests, build, with captured proof | — |
| 5 | Review | Core | Consolidate several parallel reviews into one verdict | — |
| 6 | Compound-1 | Compounding | Static lessons before delivery, fed back into the next Plan | **Compounding** |
| 7 | Ship | Downstream | Release checklist, rollback written in advance, progressive deployment 5 → 100 % | **Human gate** (acceptance) |
| 8 | Ops | Downstream | Observe the system in production, 7 to 14 days | — |
| 9 | Compound-2 | Compounding | Runtime lessons from production, fed back into the next Plan | **Compounding** |
| 10 | Deprecation | Downstream | Remove code through an announced withdrawal, behind a flag | — |

## The three human gates

A gate is a point where an agent **must stop** and where a human decides. Two defects to watch for
when tooling a project: the **missing gate** (an agent that decides the intent, the architecture or
the merge on its own) and the **superfluous approval** (a human signature between two gates, where
the agents should carry the responsibility).

| Gate | Phase | Held by | Question settled |
|---|---|---|---|
| Intent | 1 Define | PO, author of the issue | Does the contract reflect the real need? |
| Architecture | 2 Plan | lead, architect | Which approach do we build? |
| Acceptance | 7 Ship | reviewer, maintainer | Do we merge and ship? |

## The two compounding steps

Both feed the same catalogue of learned rules, reloaded by every agent and consulted at the Plan of
the next cycle. "A bug seen twice is not a bug, it is a hole in the system."

- **Compound-1** (phase 6): lessons drawn from the work and the reviews that were just done.
- **Compound-2** (phase 9): lessons drawn from an incident, a postmortem, an observability signal.

## The cross-cutting axes

Three concepts run through the phases and serve as the reading grid for `assess` and `context`:

- **Harness engineering**: guides (feedforward: AGENTS.md, conventions, templates) and sensors
  (feedback: tests, linters, typechecking, automated review); the **harnessability** of a codebase
  depends on its typing, its module boundaries and its structure.
- **Context engineering and CDLC**: context is a software dependency, in tiers (hot always loaded,
  warm on demand, cold consulted when needed), with a Generate → Evaluate → Distribute → Observe
  cycle. A stale spec is more harmful than no spec at all.
- **Issue-based development**: a gap is reported, the agent analyses the system, a human decides the
  plan, review precedes delivery, the lesson is recorded.

## Published figures

To be taken as orders of magnitude, not as thresholds: about 80 % of human effort on specification
and review; about 30 % fewer correction iterations after ten cycles; team tipping point around the
tenth iteration.
