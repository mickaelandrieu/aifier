---
name: decision-record
description: When and how to write an Architecture Decision Record for {{project}} — the admission test, the NNNN-slug.md naming under the decisions directory, the context/options/decision/consequences template, and supersession instead of editing.
---
<!-- placeholders: {{project}} {{memory.decisions}} -->

An ADR records a decision future contributors must understand to maintain the code correctly: not
only what was built, but why, and what else was considered. Records live in `{{memory.decisions}}`
and are read at the Plan phase before any new approach is proposed.

## When to write one

Write an ADR when the change:

- adopts a new technology, library or external service;
- establishes a cross-cutting pattern every contributor must follow;
- deprecates or replaces an existing pattern;
- restructures a core layer or moves a boundary between layers;
- accepts a deliberate exception to an architecture rule (name it, own it);
- introduces a domain concept with implications across layers;
- supersedes or contradicts a previous ADR.

Do not write one for a feature that follows existing patterns, a bug fix, a refactor that moves
code without changing structure, a performance change inside one layer, or a new entry point built
on the established pattern.

When unsure: if someone in eighteen months will ask "why is the code like this?", write it.

## Naming

- One file per decision: `{{memory.decisions}}/NNNN-slug.md`.
- `NNNN` is the next free four-digit sequence; read the directory to find it, never guess. When
  two records are written in the same session, assign consecutive numbers.
- `slug` is a short kebab-case statement of the decision, not of the problem
  (`0007-queue-backed-ingestion`, not `0007-ingestion-is-slow`).
- Keep an index in `{{memory.decisions}}/README.md` if the project maintains one; add the new
  record to it in the same change.

## Template

```markdown
# NNNN — <Title stating the decision>

Status: proposed | accepted | superseded by NNNN · Date: YYYY-MM-DD

## Context

What situation forced this decision: the pain, the constraint, the opportunity. Specific enough
that a reader understands the problem without the solution.

## Options considered

1. <Option> — what it gives, what it costs, why it was or was not chosen.
2. <Option> — ...
3. <Option> — ...

## Decision

What was decided and how it is implemented: the structure, pattern or rule adopted, concrete
enough for a new contributor to follow.

## Consequences

Positive: what this enables, simplifies or protects.
Negative: what this constrains, complicates or costs.
Neutral: what changes without being better or worse.
```

Two or three genuinely distinct options; a single option with two strawmen is not a decision
record. Name the rejected options honestly, including the one that was "do nothing".

## Lifecycle

- `proposed` while the Plan gate is open; a human sets `accepted`. An agent never accepts its own
  record.
- An accepted record is immutable. To change a decision, write a new record that states
  `supersedes NNNN` in its context, and set the old one to `superseded by MMMM`. Never edit the
  body of an accepted record.
- A record contradicted by the code without a superseding record is a finding for review: either
  the code or the catalogue is wrong, and the review says which.

## Relationship to the rest of the method

- The Plan phase cites applicable records in each proposed approach.
- The review checklist asks whether a change needed a record and did not get one.
- A rule of the form "always do X" with a wrong and right example belongs in the learned-rules
  catalogue, not in an ADR; an ADR explains why X was chosen over Y.
