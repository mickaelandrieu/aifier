---
name: context
description: Audit what coding agents read in this repository and propose the fix. Finds stale claims, dead paths, duplicated knowledge between the constitution, area guides, skills and docs, measures the load per session, tiers the content (always loaded, on demand, reference), and when a context file is too long proposes how to split it. Use when agents seem not to know the project, after a long CLAUDE.md or AGENTS.md was inherited, or before and after init.
---

You are running `context`. You audit the context fed to agents and write a proposal; you change
nothing in the repository. Load the `documentation-rules` skill first if it is installed.

## Step 1 — Inventory what is loaded

```bash
ls AGENTS.md CLAUDE.md GEMINI.md .cursorrules .github/copilot-instructions.md 2>/dev/null
find . -name AGENTS.md -not -path '*/node_modules/*' -not -path './.git/*'
find .agents/skills .claude/skills .opencode/skills -name SKILL.md 2>/dev/null
grep -oE '^@[^ ]+' AGENTS.md CLAUDE.md 2>/dev/null
```

For every file loaded at session start (constitution and its `@` includes) count the lines: that
is the **load per session**. Above 150 lines the constitution is no longer a map. For every file
loaded on demand (area guides, skills) count the lines and note what loads it.

## Step 2 — Check every claim

In each context file, for each claim that can be checked, check it:

| Claim | Check |
|---|---|
| a path in backticks | `test -e <path>` |
| a command | it exists in the manifest scripts, the Makefile or the tool's config |
| a file structure ("routes live in `src/x/`") | `ls` the directory |
| a tool or version | the manifest or lockfile |
| a rule ("always use X") | grep the code for two counter-examples; if the code disagrees, the rule is stale or aspirational, say which |

List every failed check as **stale** with the file, the line and what the repository says
instead. A context file whose last commit predates the last change of the code it describes is
flagged for review even when every check passes.

## Step 3 — Find duplication and misplacement

- The same rule stated in two places: constitution and a skill, constitution and an area guide,
  README and constitution. The constitution points, it does not restate.
- Area-specific content in the constitution (a framework's idioms, a directory's layout): it
  belongs to that area's guide.
- Procedure and knowledge mixed in one file: procedure (how to run, how to commit) in the
  constitution or the guide, knowledge (patterns, checklists) in skills loaded on demand.
- Knowledge the agent needs every session that is only in a skill or in `docs/`: promote it.

## Step 4 — Tier and propose

Assign every piece of content a tier: **always** (constitution, under 150 lines: map, rules
everywhere, delegation scope, gates), **on demand** (area guides, skills), **reference** (docs,
decisions, learned rules). Write the proposal to `$OUT/context-proposal.md` (outside the
repository) with:

1. the load per session before and after;
2. the stale claims, each with the fix;
3. the duplications, each with the one place that keeps the content;
4. when a context file exceeds 150 lines, the split: for each section, its target file and tier,
   verbatim section titles so the person can check nothing is lost;
5. what to delete, with the reason.

The person reads the proposal and decides. `init` applies a split when the person chooses merge;
otherwise the person edits by hand.

Proof: the report quotes every file read with its line count (`wc -l`), and every stale claim
with the check that failed. Say `BLOCKED: <reason>` when `$OUT` cannot be written or when none
of the files of Step 1 exists: there is nothing to audit, not a clean result.

## Report

```
## Context — <date>
Load per session: <lines> before → <lines> after   (files: <name> <lines>, …)
Stale claims: <count> (<file:line>: <what the repository says instead>, …)
Duplications: <count> (<content>: kept in <file>, …)
Split: <file> (<lines>) → <targets> | none needed
First fix: <one line>
Proposal: $OUT/context-proposal.md | BLOCKED (<reason>)
```
