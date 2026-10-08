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
- the label prefix, default `sdlc`;
- the gate commands marked `null` that the person knows (a test runner that is not declared is
  a gap for `gates`, not a blocker for `init`);
- protected paths agents must not touch without an approved plan (migrations, infrastructure,
  secrets), default none;
- for each file under `existing:`, the choice **merge** (fold its content into the rendered
  file), **side file** (render as `<name>.aifier.md` next to it) or **skip**.

Wait for the answers. Write the confirmed `aifier.yml` at the repository root.

## Step 3 — Render

Templates live in `templates/` next to this file. The rendering is deterministic: run the
renderer, the `aifier` binary the installer put under `.aifier/bin/`, then fill only what it
leaves for you.

First, copy the knowledge skills that agents load, from the skills directory this skill was
installed in, into the project's skills directory when they are not already there (the installer
puts both in the same directory, `.agents/skills` by default, so this is often a no-op): the cycle
skills `gate`, `qualify`, `plan`, `build` (the three call `gate/gate.sh` by its path next to them,
so `gate` travels with them), and the knowledge skills `verification-evidence`,
`review-checklist`, `adversarial-test-plan`, `decision-record`, `compound`, `process-rules`,
`documentation-rules`. That directory is the `--skills` argument below: the renderer substitutes
their `{{ }}` placeholders in place with the values of `aifier.yml` (for the per-area gates it
uses the area that owns the most gates, the backend in a backend-plus-frontend repository, and
says so in the skill's first line; it strips the `<!-- placeholders: … -->` comment once
substituted; `{{label_prefix}}` carries no colon, the skills add it). For Claude Code, make sure
`.claude/skills` exists or points to that directory; for opencode and pi the `.agents/skills`
directory is read as is.

```bash
.aifier/bin/aifier render aifier.yml "<directory of this SKILL.md>/templates" . --skills "<project skills dir>"
```

When `.aifier/bin/aifier` is missing, stop with `BLOCKED: aifier binary missing; run
curl -fsSL https://raw.githubusercontent.com/mickaelandrieu/aifier/main/install.sh | sh (it
picks the latest release; AIFIER_REF=<tag> pins one), or build it with cargo build --release and
copy target/release/aifier to .aifier/bin/`. There is no by-hand rendering: one renderer, one
result (ADR 0002).

It writes every target below, skips a file that already exists (so the merge, side-file and skip
choices of Step 2 are honoured by renaming or removing before, never by `--force` on a file the
person did not mark merge), drops the lines whose gate is `null`, renders the skills of
`--skills` in place, and prints what it wrote. Then open each
written file and fill the placeholders it left: `{{project_summary}}` (two sentences from the
README and the manifests) and, in each area guide, `{{area.summary}}`, `{{area.layout}}`,
`{{area.commands}}`, `{{area.patterns}}` from what the repository already documents. When the
person chose **merge** for an existing context file, that content is the source for these
fields: move the area-specific part into the guide, the general part into the constitution,
drop what contradicts the constitution's rules and list it in the manifest. Cite nothing you did
not read. The target table, for the record:

| Template | Target | Rule |
|---|---|---|
| `aifier.yml` | `aifier.yml` | the confirmed configuration; a gate the person left unknown stays bare `null`, a known one is a quoted string |
| `AGENTS.md` | `AGENTS.md` | the constitution; `{{project_summary}}` is two sentences you write from the README and the manifests, nothing more |
| `AREA_AGENTS.md` | `<area>/AGENTS.md` | one per area; fill layout, commands and patterns from what the repository already documents (README, existing context file, manifests). when the person chose **merge** for an existing context file, move its area-specific content here and the general part into the constitution, drop what contradicts the constitution's rules and list it in the manifest; cite nothing you did not read |
| `CLAUDE.md` | `CLAUDE.md` | only when `claude-code` is among the engines and the file does not exist, or the person chose merge |
| `github/ISSUE_TEMPLATE_change.yml` | `.github/ISSUE_TEMPLATE/change.yml` | two-audience issue |
| `github/PULL_REQUEST_TEMPLATE.md` | `.github/PULL_REQUEST_TEMPLATE.md` | PR with a Verification Run section |
| `memory/learned-rules.md` | `{{memory.rules}}` | empty catalogue with the format |
| `memory/decisions-README.md`, `memory/0000-template.md` | `{{memory.decisions}}/` | |
| `memory/handoff.md` | `{{memory.handoff}}` | dated today |

GitLab: the forge templates are rendered under `.github/` only and the cycle skills need `gh`;
both are GitHub-only in this release, say so in the report when `forge` is not `github`.

Never overwrite a file the person did not mark **merge**. Never delete anything. Never render a
file whose template you did not read.

## Step 4 — Record and report

Write `.aifier/manifest.yml` with these keys: `ref` (from `.aifier/install.yml`), `date`,
`rendered` (list of paths), `skipped` (list of `path: reason`), `not_rendered` (list of
`item: reason`, at least `guards: not available yet` and `labels: not created, command printed`
or `labels: created on <date>`), `answers` (the confirmed questions).

Show the forge commands below, filled from `aifier.yml`, and ask the person once: "run them
now?". Run exactly the ones the person approves, and record the answer in the manifest. Never run
them unasked.

```bash
# workflow labels (idempotent)
for l in todo in-progress done partial needs-input; do gh label create "{{label_prefix}}:$l" --repo {{repo}} --color 0E8A16 --force; done
for l in ok need-work rejected; do gh label create "{{label_prefix}}:pr:$l" --repo {{repo}} --color 1D76DB --force; done
# branch protection: one review, the required checks, no force push, admins included
gh api -X PUT "repos/{{repo}}/branches/{{target_branch}}/protection" --input - <<'JSON'
{"required_status_checks":{"strict":true,"contexts":[{{required_checks}}]},
 "enforce_admins":true,
 "required_pull_request_reviews":{"required_approving_review_count":1,"dismiss_stale_reviews":true},
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
JSON
```

Say that protection on a branch people push to directly will reject those pushes from then on:
it is the gate, not a bug.

Report, in the chat; do not commit, the person reviews the diff and commits on a branch:

```
## Init — <date>
Rendered: <the files, as the renderer printed them>
Skipped: <path: reason | none>
Answered: <the questions of Step 2 and their answers>
Closed: <constitution, area guides, templates, memory, skills, as applicable>
Not closed: <branch protection, CI gates, labels on the forge: each with the command or the human action>
Stopped at: done | BLOCKED (<reason>)
```

## What `init` does not do

- change the forge without a yes: labels and branch protection are shown first, run only on
  approval.
- redistribute a long existing context file on its own authority: it does the move only when
  the person says merge; `/context` is the skill that proposes the split and audits it later.
- run the gates: that is `gates`.
