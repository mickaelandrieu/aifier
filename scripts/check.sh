#!/usr/bin/env bash
# aifier gates: syntax of every shell script, neutrality of the content, frontmatter and
# placeholders of every skill. Exit 1 on the first failure.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0
for f in install.sh scripts/*.sh skills/*/*.sh tests/*.sh tests/fixtures/*.sh; do
  case "$f" in *.sh) ;; *) continue;; esac
  if head -1 "$f" | grep -q bash; then bash -n "$f" || fail=1; else sh -n "$f" || fail=1; fi
done
hits="$(grep -rniE 'raise|sfeir' --exclude-dir=.git --exclude-dir=.claude --exclude-dir=target . | grep -v 'sfeir.com/concepts' || true)"
[ -n "$hits" ] && { echo "origin references found:"; echo "$hits"; fail=1; }
for f in skills/*/SKILL.md; do
  keys="$(awk '/^---$/{c++; next} c==1 {print $1}' "$f" | tr -d ':' | sort | tr '\n' ' ')"
  [ "$keys" = "description name " ] || { echo "$f: frontmatter must be exactly name and description, got: $keys"; fail=1; }
done
# the gate decision is written once, in skills/gate/gate.sh: the cycle skills must not paraphrase it
drift="$(grep -nE 'Contract shape|## Plan. heading|login not ending' skills/qualify/SKILL.md skills/plan/SKILL.md skills/build/SKILL.md || true)"
[ -n "$drift" ] && { echo "gate logic paraphrased in a cycle skill (it lives in skills/gate/gate.sh):"; echo "$drift"; fail=1; }
# using aifier must not need python3; skills/init/render.py is the one exception until #21 moves it to the V2 binary
py="$(find skills scripts -name '*.py' | grep -vx 'skills/init/render.py' | sort)"
[ -n "$py" ] && { echo "python under skills/ or scripts/ (using aifier must not need python3):"; echo "$py"; fail=1; }
allowed='protected_paths|project|project_summary|default_branch|target_branch|label_prefix|language|repo|forge|engines|stack|dir|name|path|date|guards|required_checks|ci_file|area\.(name|dir|summary|layout|commands|patterns)|gates\.(lint|typecheck|test|build)|memory\.(rules|decisions|handoff)'
bad="$(grep -rhoE '\{\{[a-z_.]+\}\}' skills templates | sort -u | grep -vE "^\{\{($allowed)\}\}$" || true)"
[ -n "$bad" ] && { echo "unknown placeholders: $bad"; fail=1; }
[ "$fail" = 0 ] && echo "aifier check: OK"
exit $fail
