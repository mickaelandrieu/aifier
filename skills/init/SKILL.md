---
name: init
description: Bring an existing repository to the Setup phase of the AI-augmented SDLC. Detect the stack, confirm a draft aifier.yml with the person, then render the constitution, area guides, issue and PR templates, project memory and the knowledge skills, without overwriting anything silently. Use when asked to set up, bootstrap or "aify" a project for coding agents.
---

You are running `init` at the root of a repository. You render files from the templates next to
this file; you never invent a layout. Everything you write is plain Markdown or YAML, readable
without aifier. Run `assess` first when nothing says it was run: `init` closes gaps, it does not
measure them.

## Step 1 — Detect

```bash
bash "<directory of this SKILL.md>/detect.sh" . > "$OUT/aifier.draft.yml"
```

`$OUT` is a directory outside the repository. Read the draft. Without a POSIX shell, derive the same facts yourself from the manifests, following the script as a checklist, and say so. It is deterministic: forge, default
branch, language guess, engines present, one area per directory holding a manifest, the gate
commands found in each manifest, the CI file, and the `existing:` list of files `init` would
otherwise create. Do not edit the draft by hand; what detection got wrong is a question for the
person, and a fix for `detect.sh`.

## Step 2 — Ask only what detection cannot know

Show the draft and ask, in one message, only the open questions:

- target engines, when none is detected: Claude Code, opencode, pi (several allowed);
- the branch pull requests target, when it differs from the default branch;
- the language of generated documentation, when the README's language is ambiguous;
- the label prefix, default `sdlc:`;
- the gate commands marked `null` that the person knows (a test runner that is not declared is
  a gap for `gates`, not a blocker for `init`);
- protected paths agents must not touch without an approved plan (migrations, infrastructure,
  secrets), default none;
- for each file under `existing:`, the choice **merge** (fold its content into the rendered
  file), **side file** (render as `<name>.aifier.md` next to it) or **skip**.

Wait for the answers. Write the confirmed `aifier.yml` at the repository root.

## Step 3 — Render

Templates live in `templates/` next to this file; placeholders are `{{name}}`, lists repeat
between `{{#list}}` and `{{/list}}`. Render, in this order:

| Template | Target | Rule |
|---|---|---|
| `AGENTS.md` | `AGENTS.md` | the constitution; `{{project_summary}}` is two sentences you write from the README and the manifests, nothing more |
| `AREA_AGENTS.md` | `<area>/AGENTS.md` | one per area; fill layout, commands and patterns from what the repository already documents (README, existing context file, manifests). When an existing context file is long, move its area-specific content here and leave the general part in the constitution; cite nothing you did not read |
| `CLAUDE.md` | `CLAUDE.md` | only when `claude-code` is among the engines and the file does not exist, or the person chose merge |
| `github/ISSUE_TEMPLATE_change.yml` | `.github/ISSUE_TEMPLATE/change.yml` | GitHub only; for GitLab render the same fields as `.gitlab/issue_templates/change.md` |
| `github/PULL_REQUEST_TEMPLATE.md` | `.github/PULL_REQUEST_TEMPLATE.md` | GitLab: `.gitlab/merge_request_templates/default.md` |
| `memory/learned-rules.md` | `{{memory.rules}}` | empty catalogue with the format |
| `memory/decisions-README.md`, `memory/0000-template.md` | `{{memory.decisions}}` | |
| `memory/handoff.md` | `{{memory.handoff}}` | dated today |

Then copy the knowledge skills that agents load, from the skills directory this skill was installed
in, into the project's skills directory when they are not already there: `verification-evidence`,
`review-checklist`, `adversarial-test-plan`, `decision-record`, `compound`, `process-rules`,
`documentation-rules`. Replace their `{{ }}` placeholders with the values of `aifier.yml`. For
Claude Code, make sure `.claude/skills` exists or points to that directory; for opencode and pi
the `.agents/skills` directory is read as is.

Never overwrite a file the person did not mark **merge**. Never delete anything. Never render a
file whose template you did not read.

## Step 4 — Record and report

Write `.aifier/manifest.yml`: the aifier ref, the date, every file rendered, every file skipped
and why, and what this version could not render (`guards: not available`, `labels: not created`).

Report in ten lines: the files rendered, the questions answered, the gaps `init` closed
(constitution, area guides, templates, memory, skills) and the ones it cannot close (branch
protection, CI gates, labels on the forge), each with the command or human action that closes it.
Do not commit; the person reviews the diff and commits on a branch.

## What `init` does not do

- change the forge: no labels, no branch protection, no settings. It prints the `gh` or `glab`
  commands the person can run.
- redistribute a long existing context file on its own authority: it proposes the split in the
  merge choice and does the move only when the person says merge.
- run the gates: that is `gates`.
