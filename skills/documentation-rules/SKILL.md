---
name: documentation-rules
description: Documentation rules for {{project}} — classify every page with the Diátaxis decision guide (tutorial, how-to, reference, explanation), change docs in the same PR as the code, verify every claim against source, and leave no dead path or command.
---
<!-- placeholders: {{project}} {{memory.decisions}} -->

Documentation is part of the change. When a PR adds or alters a command, a configuration key, an
endpoint, an environment variable or a behaviour a reader relies on, the page that describes it
changes in the same PR, and the review checks it.

## Decision guide

Every page is exactly one of four types. Choose before writing a word.

| The content... | Type | Answers |
|---|---|---|
| Takes a newcomer end to end to a meaningful working result | Tutorial | "Can I get started?" |
| Gives steps for a goal a practitioner already has | How-to guide | "How do I...?" |
| Describes what exists: options, fields, commands, behaviour | Reference | "What is...? What are all the...?" |
| Explains why, when, and the trade-offs | Explanation | "Why this way? When X over Y?" |

A page that spans two types is split into two pages. A hybrid serves neither reader.

Architecture decisions are explanations and live in `{{memory.decisions}}`; an explanation page
that touches a decision links to its record rather than restating it.

## Per-type checklist

Tutorial:
- prerequisites stated at the top; every step yields a visible, checkable result;
- no decision left to the reader without guidance; the end state is described;
- no reference material inline; link to it;
- read once from start to finish as the newcomer would.

How-to guide:
- title names the goal, in the imperative; prerequisites listed first;
- numbered steps, one action each; every command complete and pasteable;
- no "why" (link to an explanation); success criteria stated;
- errors and edge cases at the bottom, not between steps.

Reference:
- every field, option and parameter present, with type, allowed values and default;
- each entry verified against code or schema, not against an example file;
- deprecated entries marked, not removed; examples for the non-obvious;
- no recommendation; that belongs in a how-to or an explanation.

Explanation:
- answers why or when, never how; concepts defined before use;
- trade-offs stated honestly; no step-by-step;
- links to the how-to and reference pages, and to the decision record if one exists.

## Verification protocol

Every factual claim traces to a source read in this session:

- a command: run it or read its definition (`Makefile`, `package.json` scripts, `pyproject.toml`,
  the CLI source); document its prerequisites;
- a configuration key or environment variable: read the code that consumes it for the exact name,
  type, default and effect when absent; never copy the default from an example file;
- an endpoint: read the route definition for method, path, request and response schemas, and the
  authentication it requires;
- a file path: confirm it exists in the repository at the branch the docs describe;
- a behaviour: read the code path, not the previous docs.

A claim that cannot be verified from source (third-party behaviour, infrastructure outside the
repository) carries an inline marker: `<!-- TO VERIFY: what, where -->`. Never publish an
unverified claim silently.

Before finishing, run a dead-path check over the changed pages: every relative link resolves,
every referenced file exists, every command names a target that exists.

## Structure and style

- One page, one job, one audience, one goal.
- Titles: imperative for how-to guides ("Configure object storage"), noun phrase for reference
  ("Environment variables"), gerund for tutorials ("Getting started with the API").
- Code blocks are complete and runnable; mark what the reader must substitute.
- Short sentences, active voice, present tense. No marketing adjectives.
- One idea per paragraph. An introduction longer than two paragraphs is a separate explanation
  page; link to it.
- Place pages in the project's existing docs tree; do not create a parallel one.

## Review questions

- Did the code change alter anything a page describes? Is that page in the diff?
- Is each changed page a single Diátaxis type?
- Does every claim in the diff cite a source you read?
- Any `TO VERIFY` markers left? Who resolves them, and when?
