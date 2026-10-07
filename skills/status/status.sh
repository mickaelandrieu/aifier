#!/usr/bin/env bash
# aifier status: where the project stands, in one screen. Read-only.
# usage: status.sh [--min <verdict>]   exits 3 when the last assess verdict is below --min
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
min=""; [ "${1:-}" = "--min" ] && min="${2:-}"
have() { command -v "$1" >/dev/null 2>&1; }
echo "# aifier status · $(basename "$(pwd)") · $(date +%F)"; echo
[ -f aifier.yml ] && echo "- config: aifier.yml ($(grep -c . aifier.yml) lines)" || echo "- config: aifier.yml ABSENT (run init)"
inst=".aifier/install.yml"; [ -f "$inst" ] && echo "- installed: $(grep '^installed_at' $inst | cut -d' ' -f2) from ref $(grep '^ref' $inst | cut -d' ' -f2)" || echo "- installed: no .aifier/install.yml"
# last assess
last=$(ls -1 .aifier/assess-*.md 2>/dev/null | sort | tail -1)
if [ -n "$last" ]; then
  echo "- last assess: $last"
  verdict=$(grep -m1 -oE '^Verdict: \*{0,2}[^*|]+' "$last" | sed 's/Verdict: //; s/\*//g; s/ *$//')
  echo "- verdict: ${verdict:-?}"
  echo; echo "| Phase | Score | Level |"; echo "|---|---|---|"
  grep -E '^\| ?[0-9]+ ' "$last" | awk -F'|' '{printf "|%s|%s|%s|\n", $2, $3, $4}'
  echo
  gap=$(sed -n '/^## \(Prioritised gaps\|Écarts priorisés\)/,/^## /p' "$last" | grep -m1 -E '^1\.')
  echo "- next gap: ${gap:-none listed}"
else
  echo "- last assess: none (run assess)"; verdict=""
fi
# memory
rules=$(grep -m1 '^  rules:' aifier.yml 2>/dev/null | awk '{print $2}'); rules="${rules:-docs/learned-rules.md}"
if [ -f "$rules" ]; then
  n=$(grep -cE '^## RULE-' "$rules"); d=$(git log -1 --format=%cs -- "$rules" 2>/dev/null)
  echo "- learned rules: $n (last change ${d:-uncommitted})"
else echo "- learned rules: $rules ABSENT"; fi
dec=$(grep -m1 '^  decisions:' aifier.yml 2>/dev/null | awk '{print $2}'); dec="${dec:-docs/decisions}"
[ -d "$dec" ] && echo "- decisions: $(ls "$dec" | grep -cE '^[0-9]{4}-' ) records" || echo "- decisions: $dec ABSENT"
hand=$(grep -m1 '^  handoff:' aifier.yml 2>/dev/null | awk '{print $2}'); hand="${hand:-docs/handoff.md}"
[ -f "$hand" ] && echo "- handoff: last change $(git log -1 --format=%cs -- "$hand" 2>/dev/null || echo uncommitted)" || echo "- handoff: $hand ABSENT"
# drift against manifest
if [ -f .aifier/manifest.yml ]; then
  missing=""; while read -r f; do [ -e "$f" ] || missing="$missing $f"; done < <(sed -n '/^rendered:/,/^[a-z]/p' .aifier/manifest.yml | grep -E '^  - ' | sed 's/^  - //; s/ *#.*//')
  [ -n "$missing" ] && echo "- drift: rendered files missing:$missing" || echo "- drift: none (every rendered file present)"
else echo "- drift: no .aifier/manifest.yml"; fi
# gates last run
g=$(ls -1t .aifier/gates/*.log 2>/dev/null | head -1); [ -n "$g" ] && echo "- last gates run: $(date -r "$g" +%F 2>/dev/null) ($(ls .aifier/gates/*.log | wc -l | tr -d ' ') logs)" || echo "- last gates run: none"
echo "- update: re-run the install line to refresh the skills"
if [ -n "$min" ]; then
  order="Not ready|Ready for Setup|Tooled cycle|Governed cycle"
  rank() { echo "$order" | tr '|' '\n' | grep -nix "$1" | cut -d: -f1; }
  have_r=$(rank "${verdict:-Not ready}"); min_r=$(rank "$min")
  if [ -z "$min_r" ]; then echo "unknown --min '$min'"; exit 2; fi
  if [ "${have_r:-1}" -lt "$min_r" ]; then echo; echo "status: BELOW minimum ($min)"; exit 3; fi
  echo; echo "status: at or above minimum ($min)"
fi
exit 0
