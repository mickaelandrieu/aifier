# Learned rules

Rules captured from reviews and incidents. Every agent reads this file before building or
reviewing. A rule is a repeatable pattern with a detection, not a closed ticket.

## RULE-001: no-origin-references
Severity: critical · Learned from: cleanup of 2026-10-07 · Date: 2026-10-07
Rule: nothing in this repository names a private project, client or internal framework; examples use neutral placeholders.
Wrong: a calibration section naming the production codebase the method was distilled from.
Right: "advanced witness project" with the profile that matters, and the results kept outside the repository.
Detection: `scripts/check.sh` greps the tree; add new forbidden names there when they appear.

## RULE-002: skill-frontmatter-minimal
Severity: major · Learned from: portability review of 2026-10-07 · Date: 2026-10-07
Rule: a `SKILL.md` frontmatter has exactly `name` and `description`; engine-specific keys (`skills:` preload, `argument-hint`, `disable-model-invocation`) go in the body as instructions.
Wrong: `skills: [verification-evidence]` in the frontmatter, loaded by one engine and ignored by two.
Right: "Load the `verification-evidence` skill before the first command" in the body.
Detection: `scripts/check.sh` lists the keys of every frontmatter.

## RULE-003: installer-runs-from-a-function
Severity: major · Learned from: first public `curl | sh` of 2026-10-07 · Date: 2026-10-07
Rule: a script meant for `curl | sh` wraps its body in a function called on the last line, so a truncated download parses to nothing instead of executing half.
Wrong: top-level commands executed as the shell reads the pipe.
Right: `main() { ... }` then `main "$@"` as the last line.
Detection: `grep -c '^main "\$@"$' install.sh` must be 1.

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
