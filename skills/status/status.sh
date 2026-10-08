#!/usr/bin/env bash
# aifier status: where the project stands, in one screen. Read-only.
# usage: status.sh [--min <verdict>]   exits 3 when the last assess verdict is below --min,
#        2 when --min or the verdict read from the assess file is not a known verdict.
# Verdicts, in order, English or French: Not ready / Pas prêt, Ready for Setup / Prêt pour le
# Setup, Tooled cycle / Cycle outillé, Governed cycle / Cycle gouverné.
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
min=""; [ "${1:-}" = "--min" ] && min="${2:-}"
have() { command -v "$1" >/dev/null 2>&1; }
cr() { tr -d '\r'; }
echo "# aifier status · $(basename "$(pwd)") · $(date +%F)"; echo
[ -f aifier.yml ] && echo "- config: aifier.yml ($(grep -c . aifier.yml) lines)" || echo "- config: aifier.yml ABSENT (run init)"
inst=".aifier/install.yml"; [ -f "$inst" ] && echo "- installed: $(grep '^installed_at' "$inst" | cut -d' ' -f2 | cr) from ref $(grep '^ref' "$inst" | cut -d' ' -f2 | cr)" || echo "- installed: no .aifier/install.yml"
# last assess
last=$(ls -1 .aifier/assess-*.md 2>/dev/null | sort | tail -1)
if [ -n "$last" ]; then
  echo "- last assess: $last"
  verdict=$(grep -m1 -oE '^Verdict: \*{0,2}[^*|]+' "$last" | cr | sed 's/Verdict: //; s/\*//g; s/ *$//')
  echo "- verdict: ${verdict:-?}"
  echo; echo "| Phase | Score | Level |"; echo "|---|---|---|"
  grep -E '^\| ?[0-9]+ ' "$last" | cr | awk -F'|' '{printf "|%s|%s|%s|\n", $2, $3, $4}'
  echo
  gap=$(sed -E -n '/^## (Prioritised gaps|Écarts priorisés)/,/^## /p' "$last" | cr | grep -m1 -E '^1\.')
  echo "- next gap: ${gap:-none listed}"
else
  echo "- last assess: none (run assess)"; verdict=""
fi
# memory
rules=$(grep -m1 '^  rules:' aifier.yml 2>/dev/null | cr | awk '{print $2}'); rules="${rules:-docs/learned-rules.md}"
if [ -f "$rules" ]; then
  n=$(grep -cE '^## RULE-' "$rules"); d=$(git log -1 --format=%cs -- "$rules" 2>/dev/null)
  echo "- learned rules: $n (last change ${d:-uncommitted})"
else echo "- learned rules: $rules ABSENT"; fi
dec=$(grep -m1 '^  decisions:' aifier.yml 2>/dev/null | cr | awk '{print $2}'); dec="${dec:-docs/decisions}"
[ -d "$dec" ] && echo "- decisions: $(ls "$dec" | grep -cE '^[0-9]{4}-' ) records" || echo "- decisions: $dec ABSENT"
hand=$(grep -m1 '^  handoff:' aifier.yml 2>/dev/null | cr | awk '{print $2}'); hand="${hand:-docs/handoff.md}"
if [ -f "$hand" ]; then d=$(git log -1 --format=%cs -- "$hand" 2>/dev/null); echo "- handoff: last change ${d:-uncommitted}"; else echo "- handoff: $hand ABSENT"; fi
# drift against manifest
if [ -f .aifier/manifest.yml ]; then
  missing=""; while read -r f; do [ -e "$f" ] || missing="$missing $f"; done < <(sed -n '/^rendered:/,/^[a-z]/p' .aifier/manifest.yml | cr | grep -E '^  - ' | sed 's/^  - //; s/ *#.*//')
  [ -n "$missing" ] && echo "- drift: rendered files missing:$missing" || echo "- drift: none (every rendered file present)"
else echo "- drift: no .aifier/manifest.yml"; fi
# gates last run
g=$(ls -1t .aifier/gates/*.log 2>/dev/null | head -1); [ -n "$g" ] && echo "- last gates run: $(date -r "$g" +%F 2>/dev/null) ($(ls .aifier/gates/*.log | wc -l | tr -d ' ') logs)" || echo "- last gates run: none"
echo "- update: re-run the install line to refresh the skills"
if [ -n "$min" ]; then
  # rank <verdict>: 1..4, empty when unknown; both spellings share a rank
  rank() {
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
      "not ready"|"pas prêt") echo 1;; "ready for setup"|"prêt pour le setup") echo 2;;
      "tooled cycle"|"cycle outillé") echo 3;; "governed cycle"|"cycle gouverné") echo 4;;
    esac
  }
  min_r=$(rank "$min")
  if [ -z "$min_r" ]; then echo "unknown --min '$min'"; exit 2; fi
  if [ -z "$verdict" ]; then echo; echo "status: BELOW minimum ($min): no assess verdict"; exit 3; fi
  have_r=$(rank "$verdict")
  if [ -z "$have_r" ]; then echo; echo "unknown verdict '$verdict'"; exit 2; fi
  if [ "$have_r" -lt "$min_r" ]; then echo; echo "status: BELOW minimum ($min)"; exit 3; fi
  echo; echo "status: at or above minimum ($min)"
fi
exit 0
