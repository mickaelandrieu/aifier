# Learned rules

Rules captured from reviews and incidents. Every agent reads this file before building or
reviewing. A rule is a repeatable pattern with a detection, not a closed ticket.

## RULE-001: no-origin-references
Severity: critical · Learned from: cleanup of 2026-10-07 · Date: 2026-10-07
Rule: nothing in this repository names a private project, client or internal framework; examples use neutral placeholders.
Wrong: a calibration section naming the production codebase the method was distilled from.
Right: "advanced witness project" with the profile that matters, and the results kept outside the repository.
Detection: review question on every pull request: does the diff name a private project, client or framework? No grep knows the names; the reviewer does.

## RULE-002: skill-frontmatter-minimal
Severity: major · Learned from: portability review of 2026-10-07 · Date: 2026-10-07
Rule: a `SKILL.md` frontmatter has exactly `name` and `description`; engine-specific keys (`skills:` preload, `argument-hint`, `disable-model-invocation`) go in the body as instructions.
Wrong: `skills: [verification-evidence]` in the frontmatter, loaded by one engine and ignored by two.
Right: "Load the `verification-evidence` skill before the first command" in the body.
Detection: `bash tests/lint.sh`, check 1 (the frontmatter keys of every `skills/*/SKILL.md`).

## RULE-003: installer-runs-from-a-function
Severity: major · Learned from: first public `curl | sh` of 2026-10-07 · Date: 2026-10-07
Rule: a script meant for `curl | sh` wraps its body in a function called on the last line, so a truncated download parses to nothing instead of executing half.
Wrong: top-level commands executed as the shell reads the pipe.
Right: `main() { ... }` then `main "$@"` as the last line.
Detection: `bash tests/lint.sh`, check 3 (`sh -n install.sh` and `main "$@"` as its last line).

## RULE-004: tooling-manifest-is-not-an-area
Severity: minor · Learned from: detection on the classic witness project · Date: 2026-10-07
Rule: a root `package.json` without scripts next to sub-projects that have their own manifest is tooling residue, not an area; a repository with no manifest at all is one area of stack `docs`.
Wrong: three areas, one of them the root with every gate `null`.
Right: two areas; or one `root` area when nothing else exists.
Detection: run `skills/init/detect.sh` on the two witness repositories; areas must match the expected list.

## RULE-005: collectors-prove-on-two-repositories
Severity: major · Learned from: the sparse-window fallback of 2026-10-07 · Date: 2026-10-07
Rule: a change to `probes.sh` or `detect.sh` is verified on this repository and on a classic one before it lands; a 90-day window that is empty on a dormant project must fall back to a commit count and say so.
Wrong: zero commits, zero PRs, every git criterion at 0 on a project that simply paused.
Right: "window: last 90 days too sparse, falling back to last 100 commits" in the output.
Detection: the smoke step in CI runs both collectors here; the classic witness run is in the Verification Run of the PR.

## RULE-006: blind-run-before-release
Severity: critical · Learned from: first end-to-end test on the classic witness · Date: 2026-10-07
Rule: a skill ships only after an agent with no other context has run it from its SKILL.md alone and reported every sentence it had to guess at; those guesses become fixes or rules.
Wrong: the author runs the skill with the conversation in mind and finds it clear.
Right: two blind runs found 28 frictions in `assess` and `init` that the author had not seen.
Detection: the pull request's Verification Run quotes the blind agent's friction list, or says "none".

## RULE-007: placeholder-contract-is-explicit
Severity: major · Learned from: blind `init` run · Date: 2026-10-07
Rule: every placeholder has one source key in `aifier.yml`, one documented shape (colon, trailing slash, null handling, scalar versus per-area), and `templates/README.md` lists them all.
Wrong: `{{label_prefix}}:done` with a prefix that already ends in a colon; `{{memory.decisions}}/x` with a value ending in a slash; `{{name}}` with no source.
Right: prefix without colon and skills add it; paths without trailing slash; area table keyed on `stack` and `dir`.
Detection: `bash tests/lint.sh`, check 2 (every placeholder of `skills/` and `templates/` against the list of `templates/README.md`); a blind run reports any doubled separator.

## RULE-008: probe-lines-say-what-they-prove
Severity: major · Learned from: blind `assess` run · Date: 2026-10-07
Rule: a collector line that comes from a keyword scan says so, so it is never cited as proof of an executed step.
Wrong: "CI pipelines: ruff, mypy, bandit" from a comment in the workflow, read as three CI steps.
Right: "CI keyword hits (not steps): ruff, mypy, bandit; steps: pytest".
Detection: review of `probes.sh` output headings; a blind run flags any line it had to re-verify.

## RULE-009: ci-smokes-what-it-ships
Severity: major · Learned from: review of main (#issue-less) · Date: 2026-10-08
Rule: CI runs the smoke on the exact artefact path it packages; a test that finds a binary on its own proves another build than the one released.
Wrong: `release.yml` built `target/<triple>/release/aifier` and `tests/run.sh` picked `target/release/aifier`, a host build of an earlier step, so the packaged binary was never run.
Right: `AIFIER_BIN=target/${{ matrix.target }}/release/aifier bash tests/run.sh` in `release.yml`; `check.yml` exports `AIFIER_BIN` to the build it just made.
Detection: every `tests/run.sh` call in the workflows under `.github/workflows/` passes `AIFIER_BIN`.

## RULE-010: config-shape-errors-are-loud
Severity: major · Learned from: review of main (#issue-less) · Date: 2026-10-08
Rule: a configuration key with the wrong YAML type is an error before the first write, naming the key and the type found; a renderer never coerces a mapping to a string or a scalar to a list silently.
Wrong: `areas: [root]` (a sequence) rendered an empty area table and a constitution without gates, and `init` reported success.
Right: `aifier render` stops with `areas must be a mapping of <dir>: { guide, stack }` (or `memory.rules must be a path`) and writes nothing.
Detection: a unit test per documented key of `aifier.yml` feeding the wrong shape and asserting the error names the key.

## RULE-011: installer-env-combinations-are-tested
Severity: major · Learned from: review of main (#issue-less) · Date: 2026-10-08
Rule: every `AIFIER_*` variable the installer reads is exercised in `tests/run.sh` alone and in the combinations the README documents, offline.
Wrong: `AIFIER_RELEASE_URL` with `AIFIER_REF=main` (a branch names no asset) was untested and tried to download `aifier-main-<target>.tar.gz`.
Right: the `release-url-branch` case: a release URL with a branch ref falls back to the local build and the install record says `copied from`.
Detection: `grep -o 'AIFIER_[A-Z_]*' install.sh | sort -u`: each name appears in `tests/run.sh`.

## RULE-012: collectors-iterate-paths-nul-separated
Severity: major · Learned from: review of main (#issue-less) · Date: 2026-10-08
Rule: a collector that loops over paths uses `-print0` and `read -r -d ''` (or `ls-files -z`), never word-splitting of a `find` or `ls` output.
Wrong: `for f in $(find . -name AGENTS.md)` split `docs/area guides/AGENTS.md` into two paths and counted a guide that does not exist.
Right: `git ls-files -z | grep -zvE '…'` in `probes.sh`, consumed with `read -r -d ''`; the `with-secret` fixture holds an area and a file whose names carry a space.
Detection: a fixture with a space in a path under `tests/fixtures/`, diffed by `tests/run.sh`.

## RULE-013: generated-fields-are-read-back-by-their-consumer
Severity: major · Learned from: review of main (#issue-less) · Date: 2026-10-08
Rule: what one script writes into `aifier.yml` or a report is read back by the script that consumes it, in a test, CRLF variant included.
Wrong: `detect.sh` wrote `prefix: "sdlc"` quoted and `gate.sh` read the prefix with its quotes, so no label matched on a repository whose configuration came from detection.
Right: the `crlf-prefix` case: `gate.sh` reads the prefix `detect.sh` wrote, quotes and CR stripped, and the golden shows the labels matched.
Detection: for each field `detect.sh` writes, a `tests/run.sh` case where `run.sh` or `gate.sh` reads it, one of them from a CRLF file.

## RULE-014: blocked-not-fail-when-the-precondition-failed
Severity: critical · Learned from: review of main (#issue-less) · Date: 2026-10-08
Rule: a verdict line never says OK or FAIL for a command that did not run; a failed preflight, a bad option or a missing tool is `BLOCKED: <reason>` with its own exit code.
Wrong: `--area nope` printed `lint: FAIL (exit 1)` for every family because the runner ran nothing and reported the empty run as a failure.
Right: `no gate matched --area nope`, exit 2, no gate line at all; a failed preflight prints `BLOCKED: preflight `false` exited 1` and stops before the first gate.
Detection: review question on every runner change ("what does the block say when the command did not run?") plus the `gates-runner-badopts` and `gates-runner-badpre` goldens.

## RULE-015: portable-sed-and-awk
Severity: major · Learned from: review of main (#issue-less) · Date: 2026-10-08
Rule: collectors use `sed -E` with ERE for alternation, never `\|` in a BRE, and octal escapes (`\015`) rather than hex in awk, so BSD and GNU tools print the same output.
Wrong: `sed 's/foo\|bar//'` matched nothing on macOS, so `status.sh` compared `--min` against a verdict line still ending in CR.
Right: `sed -E 's/foo|bar//'` and `awk '{ sub(/\015$/, "") }'`, same output on both platforms, proven by the status case of `tests/run.sh`.
Detection: `grep -n '\\|' skills/*/*.sh` is empty, and the status case in `tests/run.sh` passes on macOS and Linux.
