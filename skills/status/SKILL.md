---
name: status
description: Where the project stands against the AI-augmented SDLC in one screen: last assess verdict and phase levels, next gap, learned rules and their last change, decisions, handoff, drift between the manifest and the files, last gates run. Use for a quick check at session start, before a release, or in CI with a minimum verdict.
---

You are running `status`. It is cheap and read-only: run the script, show its output, add
nothing you did not read.

```bash
bash "<directory of this SKILL.md>/status.sh"
```

What it reads: `aifier.yml`, `.aifier/install.yml`, the latest `.aifier/assess-<date>.md`
(written by `assess`), the learned-rules catalogue and its git history, the decisions directory,
the handoff file, `.aifier/manifest.yml` against the files it lists, the logs under
`.aifier/gates/`.

When there is no assess report, say "run assess" and stop; when a rendered file is missing,
say which, that is drift, and offer `init` to restore it (it skips existing files). When the
catalogue has not changed for months while pull requests landed, say it: either the reviews
find nothing, or the capture step is skipped.

In CI: `bash status.sh --min "Tooled cycle"` exits 3 when the last verdict is below the
minimum, so a team can protect its own setup. Verdicts, in order: Not ready, Ready for Setup,
Tooled cycle, Governed cycle.

Proof: the report is the script's output, quoted verbatim, nothing summarised in its place. Say
`BLOCKED: <reason>` when the script cannot start, and "run assess" when it reports no assess
report: neither is a verdict.

Not covered yet: detecting that a newer aifier exists; the script only prints the install line.
