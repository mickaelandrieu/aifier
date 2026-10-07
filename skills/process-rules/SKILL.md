---
name: process-rules
description: Starter catalogue of process rules for agents working on {{project}} — branching, PR targeting, fixing at the lowest layer, PR health gate, behaviour tests, proof over self-report, git state hygiene, grounded claims and environment preflight. Each rule has a wrong and a right example and a detection.
---
<!-- placeholders: {{project}} {{default_branch}} {{target_branch}} {{label_prefix}} {{gates.test}} {{memory.rules}} -->

These rules apply to every agent in every session. They are process rules: their detection is a
command or a review question, not a linter. Project-specific lessons go to `{{memory.rules}}`;
these are the floor.

## PR-001: branch-from-target-base

Rule: create a work branch from the base the PR will target, fetched fresh, never from whatever is
checked out.
Wrong: `git checkout -b fix/issue-42` while on `{{default_branch}}`, then a PR against
`{{target_branch}}`: the diff carries every commit the two bases do not share.
Right: `git fetch origin {{target_branch}} && git checkout -b fix/issue-42 origin/{{target_branch}}`.
Detection: `git diff --stat {{target_branch}}...HEAD | tail -1` shows only the intended files.

## PR-002: pr-targets-its-base

Rule: a PR targets the branch it was created from; derive the base from the issue (milestone,
release field), not from the current checkout or the forge default.
Wrong: branch cut from `{{target_branch}}`, `gh pr create --base {{default_branch}}`.
Right: `gh pr create --base {{target_branch}}`, same base as the branch point.
Detection: `gh pr view #N --json baseRefName` equals the base the branch was cut from.

## PR-003: fix-at-lowest-layer

Rule: fix a defect in the lowest layer that owns it (domain or utilities, then use cases, then
adapters, then entry points). A guard higher up that compensates for a lower bug is a symptom fix.
Wrong: an adapter skips items whose shape a lower builder produced incorrectly.
Right: the builder produces the correct shape; the adapter keeps no special case.
Detection: the diff adds `skip`, `workaround`, `bypass` or a shape check in a consumer; the PR title
describes a solution rather than a problem.

## PR-004: pr-health-gate

Rule: a PR with merge conflicts or a failing required check never receives a clean verdict or a
ready label, whatever the code quality.
Wrong: acceptance criteria pass, review is clean, `{{label_prefix}}:pr:need-work` is removed while
`mergeable == CONFLICTING`.
Right: either gate fails, drift is at least `MEDIUM`, the label stays.
Detection: `gh pr view #N --json mergeable` and `gh pr checks #N` before any verdict.

## PR-005: tests-verify-behaviour

Rule: a test asserts an observable outcome (domain rule, public contract, rendered result), never
the internal shape of the code. If a refactor with the same behaviour breaks the test, the test is
wrong.
Wrong: `mock.get_metrics.assert_called_once()`; expected value rebuilt with the SUT's arithmetic;
the flag that carries the bug mocked to a constant.
Right: feed a fake with real inputs, assert the rule holds (`len(result.top) == 50`).
Detection: `grep -rEn 'assert_called_once|assert_called_with|call_count ==' tests/`; a hit is a
violation unless the call itself is the contract (event emission, audit).

## PR-006: proof-not-self-report

Rule: never claim a gate passed without the exact command and the tail of its real output in the
deliverable; a gate that cannot run is `BLOCKED: <reason>`, never `PASS`, never a weaker proxy.
Wrong: "Integration tests pass." with no run; a type check presented as the test suite.
Right: a `## Verification Run` section: `$ {{gates.test}} tests/unit -q → 48 passed`,
`Integration: BLOCKED — database unreachable; run in CI`.
Detection: `grep -Ein 'all green|tests? pass|validated|works now' <deliverable>` with no adjacent
captured output.

## PR-007: reground-git-before-mutation

Rule: before any commit, push, checkout or label transition, re-read the branch and the tree; the
working tree is shared and moves between turns. An agent that switches branch restores the previous
state before returning.
Wrong: a review checked out another branch; the agent "fixes" a CI failure against the wrong code
and pushes.
Right: `git branch --show-current && git status --porcelain`, then re-read the files to commit;
`git show origin/{{target_branch}}:path` to read what actually ships.
Detection: `git rev-parse --abbrev-ref HEAD` differs from the branch the session believes it is on.

## PR-008: claims-grounded-and-version-pinned

Rule: an analysis report marks every claim `VERIFIED` (command run, `file:line` cited, ref named)
or `INFERRED`; a question about a tag or release is answered from `git show <ref>:<path>`, and
runtime state (flags, env, rows) is queried or marked "not checked".
Wrong: "the route is `/v2/items/share`" read from `{{default_branch}}` for a bug on tag `v1.7.3`.
Right: "VERIFIED (`git show v1.7.3:src/api/share.py:41`): route is `/v2/sharing/share`. INFERRED:
callers in `src/client/`, runtime not checked."
Detection: confident endpoint or behaviour claims with no `file:line`, no ref, no marker.

## PR-009: verify-mutating-git-from-raw-output

Rule: never trust a success line after `stash`, `add`, `reset`, `checkout`, `clean`, `commit`,
`push` or `rm`; confirm the effect with a raw read, bypassing any output-filtering proxy.
Wrong: `git stash push -u` reports ok; a proxy dropped `-u` and untracked files remain, one
`git clean` from loss.
Right: `git stash push -u && git status --porcelain && git stash list`.
Detection: a mutating git command whose only confirmation is its own success line.

## PR-010: environment-preflight-before-verdict

Rule: before a test verdict, confirm the toolchain, services and scope the gate relies on, and that
the run covered the whole intended scope rather than a cached failure subset.
Wrong: "0 failed" from a runner replaying only its last-failed cache; a green suite with the
database stubbed out of existence.
Right: preflight cited in the `## Verification Run` section: interpreter, lockfile, services
reachable, cache cleared, scope named.
Detection: a verdict with no preflight line; a run count far below the known suite size.
