# aifier — guidance for AI agents

aifier is a method and a set of portable skills that bring an existing repository to the Setup
phase of the AI-augmented SDLC. This repository holds the method (`method/`), the skills
(`skills/`), the files `init` renders (`templates/`) and the installer. It contains no
application code: the deliverable is Markdown, YAML and three shell scripts.

aifier uses aifier: this file, `aifier.yml`, the templates under `.github/` and the memory under
`docs/` were rendered by `/init` on this repository.

Memory: [learned rules](docs/learned-rules.md) (read before changing a skill or a template),
[decisions](docs/decisions/) (ADRs), [session handoff](docs/handoff.md) (read at session start,
update before stopping). Configuration of the cycle: [aifier.yml](aifier.yml).

## Rules that apply everywhere

1. Everything published here must be reusable by anyone: no reference to any private project,
   client or internal framework, only sources freely available on the internet. The check script
   fails on such references.
2. A skill's frontmatter carries only `name` and `description`: it is the one format every
   engine loads. Placeholders come from the list in `scripts/check.sh`.
3. Scripts are POSIX `sh` for the installer and `bash` for collectors, syntax-checked by the
   gate, and written so that a partial download never executes.
4. No claim without proof. Every deliverable ends with a `## Verification Run` section quoting
   `bash scripts/check.sh` and the smoke commands with their captured output, or `BLOCKED`.
5. Method pages are in French, skills, templates and scripts in English.
6. Branch from `main`, one slice per pull request, conventional commit subjects, the pull
   request references its issue.

## What agents do not do

- change the method's vocabulary (phases, gates, capitalisations): it comes from published
  concepts, see `method/phases.md`;
- rewrite a template or a skill body without an issue that says why and a human who agreed;
- merge, approve their own pull request, or set it as ready; a human merges.

## Gates

```bash
bash scripts/check.sh
AIFIER_SRC=. AIFIER_DIR=skills sh install.sh
bash skills/init/detect.sh . >/dev/null && bash skills/assess/probes.sh . >/dev/null
```

Run the two collectors against a second, classic repository before changing them: a change that
only works on this repository is not a change.
