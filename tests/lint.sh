#!/usr/bin/env bash
# Lint gate of this repository: the shape checks that need no build. Each check prints
# "lint: <what> FAIL" with the offending lines and the script exits 1 at the end; it prints
# "lint: OK" when every check passes. Usage: bash tests/lint.sh
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
fail=0
bad() { echo "lint: $1 FAIL"; shift; [ $# -gt 0 ] && printf '  %s\n' "$@"; fail=1; }

# 1. every skill frontmatter has exactly name and description (RULE-002)
for f in skills/*/SKILL.md; do
  keys="$(awk '/^---$/{c++; next} c==1 {print $1}' "$f" | tr '\n' ' ')"
  [ "$keys" = "name: description: " ] || bad "frontmatter of $f" "keys: $keys"
done

# 2. every placeholder in skills/ and templates/ is in the list of templates/README.md
# (RULE-007). The scalar keys are copied from that README's "Placeholders" section; the block
# keys are the ones the renderer derives or iterates. Keep both in sync with the README.
allowed=" project project_summary repo forge engines language default_branch target_branch
label_prefix required_checks ci_file guards protected_paths date memory.rules memory.decisions
memory.handoff name dir from stack guide gates.lint gates.typecheck gates.test gates.build path
area.name area.dir area.summary area.layout area.commands area.patterns "
allowed=" $(printf "%s" "$allowed" | tr "\n" " ") "
blocks=" areas subareas multi_area protected_paths "
unknown=""
for p in $(grep -rhoE '\{\{[#^/]?[a-z_.]+\}\}' skills templates --include='*.md' --include='*.yml' --exclude=README.md | sort -u); do
  key="${p#\{\{}"; key="${key%\}\}}"
  case "$key" in
    [#^/]*) case "$blocks" in *" ${key#?} "*) ;; *) unknown="$unknown $p";; esac ;;
    *) case "$allowed" in *" $key "*) ;; *) unknown="$unknown $p";; esac ;;
  esac
done
[ -z "$unknown" ] || bad "placeholders not in templates/README.md" "$unknown"

# 3. the installer parses and ends with main "$@" (RULE-003)
sh -n install.sh || bad "sh -n install.sh"
[ "$(tail -n 1 install.sh)" = 'main "$@"' ] || bad 'install.sh last line is not main "$@"'

# 4. every bash script parses
for s in skills/*/*.sh scripts/*.sh tests/*.sh tests/fixtures/*.sh; do
  [ -f "$s" ] || continue
  bash -n "$s" || bad "bash -n $s"
done

# 5. no placeholder left in the rendered skills of the golden trees
left="$(grep -rl '{{' tests/expected/render/*/skills 2>/dev/null || true)"
[ -z "$left" ] || bad "placeholders left in rendered goldens" $left

# 6. the manifest of this repository has a ref line
grep -q '^ref:' .aifier/manifest.yml || bad ".aifier/manifest.yml has no ref: line"

# 7. the cycle skills do not paraphrase the gate logic (gate.sh is the one place it is written)
drift="$(grep -nE 'Contract shape|login not ending|## Plan. heading' skills/qualify/SKILL.md skills/plan/SKILL.md skills/build/SKILL.md || true)"
[ -z "$drift" ] || bad "cycle skills paraphrase the gate logic" "$drift"

# 8. no Python under skills/, scripts/, src/ (ADR 0002)
py="$(find skills scripts src -name '*.py' 2>/dev/null || true)"
[ -z "$py" ] || bad "python files" $py

[ "$fail" = 0 ] && echo "lint: OK"
exit "$fail"
