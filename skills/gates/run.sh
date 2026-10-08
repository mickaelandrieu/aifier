#!/usr/bin/env bash
# aifier gates runner: run the gates declared in aifier.yml and capture their output.
#
# usage: run.sh <aifier.yml> [--area <name>|none] [--family lint|typecheck|test|build] [--preflight]
#        [--compare-ci] [--out <dir>]
#
# Prints a `## Verification Run` block: one line per gate with the command, the exit code and
# the path of its captured output, or BLOCKED with the reason. Exit code 1 when a gate failed;
# 2 when the preflight failed, a log could not be written, an area directory is missing,
# --family is not a family or --area matches no gate (nothing else runs); 0 otherwise, with
# `Verdict: no gate run` when nothing was selected. `--area none` runs no gate, for
# `--compare-ci` alone: the preflight runs only with `--preflight` or when at least one gate is
# about to run.
#
# Reads only the subset of aifier.yml that init renders: `gates:` (two-space area, four-space
# family: command, `null` for none; an area declared twice keeps its last block, with a warning),
# `preflight:` (inline list, commas inside quotes kept, or `- item` lines) and `ci:` (`file:`,
# one path or several comma-separated, and `files:` as `- path` lines). It is not a YAML parser:
# a quoted command reaches `sh -c` verbatim, YAML escapes inside it (`\"`, `\n`) are not
# unescaped, so prefer single-quoted YAML strings. Logs are named <area>-<family>.log with `/`
# and spaces in the area replaced by `_`.
#
# CI comparison, per declared gate: `run step matches` when a `run:` line of a CI file is exactly
# the command; `token hit (not a step)` when the command's first word (its first three for npm,
# npx, uv and poetry; leading NAME=value words skipped) appears as a whole word on a `run:` line;
# `no token hit` otherwise. A token hit does not prove that CI runs the gate.
set -u
usage() { sed -n '2,/^set -u/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }
[ $# -ge 1 ] || { usage; exit 2; }
cfg="$1"; shift
[ -f "$cfg" ] || { echo "BLOCKED: $cfg not found"; exit 2; }
area_opt=""; family_opt=""; preflight_opt=0; compare_ci=0; out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --area) area_opt="${2:-}"; shift 2;;
    --family)
      family_opt="${2:-}"
      case "$family_opt" in lint|typecheck|test|build) ;; *) echo "--family must be one of lint|typecheck|test|build, got '$family_opt'"; exit 2;; esac
      shift 2;;
    --preflight) preflight_opt=1; shift;;
    --compare-ci) compare_ci=1; shift;;
    --out) out="${2:-}"; shift 2;;
    *) echo "unknown option: $1"; usage; exit 2;;
  esac
done
root="$(cd "$(dirname "$cfg")" && pwd -P)"
cfg_rel="$(basename "$cfg")"
out="${out:-$root/.aifier/gates}"
mkdir -p "$out" 2>/dev/null || { echo "BLOCKED: cannot write $out"; exit 2; }

# One record per line, tab-separated, in file order (gates after the whole file is read, so a
# duplicated area keeps its last block):
#   gate <area> <family> <command or empty>  |  preflight <command>  |  ci <key> <value>  |  warn <text>
records="$(awk '
  function unquote(s) { sub(/^["\047]/, "", s); sub(/["\047]$/, "", s); return s }
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  # items(s, out): splits s on the commas outside quotes into out[1..n]; returns n
  function items(s, out,    n, i, c, q, cur) {
    n = 0; q = ""; cur = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (q == "") {
        if (c == "\"" || c == "\047") q = c
        else if (c == ",") { out[++n] = cur; cur = ""; continue }
      } else if (c == q) q = ""
      cur = cur c
    }
    out[++n] = cur
    return n
  }
  /^[ \t]*$/ || /^[ \t]*#/ { next }
  {
    line = $0; sub(/\r$/, "", line)
    body = line; sub(/^[ \t]+/, "", body)
    indent = length(line) - length(body)
    if (indent == 0) {
      section = body; sub(/:.*/, "", section); area = ""
      if (section == "preflight" && body ~ /\]$/) {
        inner = body; sub(/^[^:]*:[ \t]*\[/, "", inner); sub(/\][ \t]*$/, "", inner)
        n = items(inner, it)
        for (i = 1; i <= n; i++) { v = unquote(trim(it[i])); if (v != "") print "preflight\t" v }
      }
      next
    }
    if (section == "gates") {
      if (indent == 2) {
        area = body; sub(/:[ \t]*$/, "", area); area = trim(area)
        if (area in seen) {
          print "warn\tarea " area " declared twice, keeping the last block"
          nd = 0; for (k in gate) { split(k, p, SUBSEP); if (p[1] == area) del[++nd] = k }
          for (j = 1; j <= nd; j++) delete gate[del[j]]
        }
        seen[area] = 1
      } else if (indent == 4 && area != "") {
        key = body; sub(/:.*/, "", key); key = trim(key)
        val = body; sub(/^[^:]*:/, "", val); val = trim(val)
        if (val == "null" || val == "~" || val == "") val = ""; else val = unquote(val)
        k = area SUBSEP key; order[++no] = k; gate[k] = val
      }
    } else if (section == "preflight" && body ~ /^- /) {
      v = body; sub(/^- [ \t]*/, "", v); print "preflight\t" unquote(trim(v))
    } else if (section == "ci") {
      if (body ~ /^- /) { v = body; sub(/^- [ \t]*/, "", v); print "ci\tfiles\t" unquote(trim(v)) }
      else {
        key = body; sub(/:.*/, "", key); key = trim(key)
        val = body; sub(/^[^:]*:/, "", val); val = unquote(trim(val))
        print "ci\t" key "\t" val
      }
    }
  }
  END {
    for (i = 1; i <= no; i++) {
      k = order[i]; if (!(k in gate) || (k in printed)) continue
      printed[k] = 1; split(k, p, SUBSEP); print "gate\t" p[1] "\t" p[2] "\t" gate[k]
    }
  }' "$cfg")"

if [ -n "$area_opt" ] && [ "$area_opt" != none ]; then
  printf '%s\n' "$records" | awk -F'\t' -v a="$area_opt" '$1=="gate" && $2==a {f=1} END {exit !f}' \
    || { echo "no gate matched --area $area_opt"; exit 2; }
fi
selected() {  # <area> <family>: true when the options keep this gate
  [ "$area_opt" != none ] || return 1
  [ -z "$area_opt" ] || [ "$1" = "$area_opt" ] || return 1
  [ -z "$family_opt" ] || [ "$2" = "$family_opt" ] || return 1
  return 0
}
will_run=0
while IFS=$'\t' read -r kind area fam cmd; do
  if [ "$kind" = gate ] && [ -n "$cmd" ] && selected "$area" "$fam"; then will_run=$((will_run + 1)); fi
done <<EOF
$records
EOF

rel() { case "$1" in "$root"/*) printf '%s' "${1#"$root"/}";; *) printf '%s' "$1";; esac; }
# run <command> <cwd> <log>: captures the command, sets $code and $tail (last three lines);
# $code is `blocked` when the log cannot be written
run() {
  if ! printf '$ %s   (cwd %s)\n' "$1" "$2" > "$3" 2>/dev/null; then code=blocked; tail=""; return 0; fi
  (cd "$2" && sh -c "$1") >> "$3" 2>&1; code=$?
  tail="$(tail -n 3 "$3" | sed 's/^/  /')"
}
blocked_log() { printf 'BLOCKED: cannot write %s\n' "$(rel "$1")"; exit 2; }

printf '## Verification Run\n\n'
printf 'Date: %s · Config: %s\n\n' "$(date +%Y-%m-%dT%H-%M)" "$cfg_rel"
warnings="$(printf '%s\n' "$records" | awk -F'\t' '$1=="warn"{print "warning: " $2}')"
[ -z "$warnings" ] || printf '%s\n\n' "$warnings"

preflights="$(printf '%s\n' "$records" | awk -F'\t' '$1=="preflight"{print $2}')"
if [ -n "$preflights" ] && { [ "$preflight_opt" = 1 ] || [ "$will_run" -gt 0 ]; }; then
  i=0
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    run "$cmd" "$root" "$out/preflight-$i.log"
    [ "$code" = blocked ] && blocked_log "$out/preflight-$i.log"
    if [ "$code" != 0 ]; then printf 'BLOCKED: preflight `%s` exited %s\n%s\n' "$cmd" "$code" "$tail"; exit 2; fi
    printf -- '- preflight ok: `%s`\n' "$cmd"
    i=$((i + 1))
  done <<EOF
$preflights
EOF
  printf '\n'
fi

if [ "$compare_ci" = 1 ]; then
  cifiles="$(printf '%s\n' "$records" | awk -F'\t' '
    $1=="ci" && $2=="file" { n = split($3, a, /, */); for (i = 1; i <= n; i++) if (a[i] != "" && a[i] != "null") print a[i] }
    $1=="ci" && $2=="files" { print $3 }')"
  text=""; missing=""; listed=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    listed="${listed:+$listed, }$f"
    if [ -f "$root/$f" ]; then text="$text$(cat "$root/$f")"$'\n'; else missing="$missing$f"$'\n'; fi
  done <<EOF
$cifiles
EOF
  printf 'CI comparison (%s):\n' "${listed:-no CI file declared}"
  printf '%s' "$missing" | while IFS= read -r f; do [ -n "$f" ] && printf -- '- CI file not found: %s\n' "$f"; done
  runs="$(printf '%s\n' "$text" | grep -E '^[[:space:]]*-?[[:space:]]*run:' | sed -E 's/^[[:space:]]*-?[[:space:]]*run:[[:space:]]*//; s/[[:space:]]+$//')"
  while IFS=$'\t' read -r kind area fam cmd; do
    [ "$kind" = gate ] && [ -n "$cmd" ] || continue
    set -f; set -- $cmd; set +f
    while [ $# -gt 0 ]; do case "$1" in [A-Za-z_]*=*) shift;; *) break;; esac; done
    [ $# -gt 0 ] || continue
    case "$1" in npm|npx|uv|poetry) token="$1 ${2:-} ${3:-}"; token="${token% }"; token="${token% }";; *) token="$1";; esac
    if printf '%s\n' "$runs" | grep -qxF -- "$cmd"; then printf -- '- %s/%s: run step matches `%s`\n' "$area" "$fam" "$cmd"
    elif printf '%s\n' "$runs" | grep -qwF -- "$token"; then printf -- '- %s/%s: token hit (not a step): `%s`\n' "$area" "$fam" "$token"
    else printf -- '- %s/%s: no token hit: `%s`\n' "$area" "$fam" "$token"; fi
  done <<EOF
$records
EOF
  printf '\n'
fi

failed=0; ran=0
while IFS=$'\t' read -r kind area fam cmd; do
  [ "$kind" = gate ] || continue
  selected "$area" "$fam" || continue
  if [ -z "$cmd" ]; then printf -- '- %s/%s: not declared (gap)\n' "$area" "$fam"; continue; fi
  if [ "$area" = root ]; then cwd="$root"; else cwd="$root/$area"; fi
  [ -d "$cwd" ] || { printf 'BLOCKED: area dir %s missing\n' "$(rel "$cwd")"; exit 2; }
  log="$out/$(printf '%s' "$area" | tr '/ ' '__')-$fam.log"
  run "$cmd" "$cwd" "$log"
  [ "$code" = blocked ] && blocked_log "$log"
  ran=$((ran + 1))
  if [ "$code" = 0 ]; then status=OK; else status=FAIL; failed=$((failed + 1)); fi
  printf -- '- %s/%s: %s (exit %s) `%s` → %s\n%s\n' "$area" "$fam" "$status" "$code" "$cmd" "$(rel "$log")" "$tail"
done <<EOF
$records
EOF

if [ "$ran" = 0 ]; then printf 'Verdict: no gate run\n'; exit 0; fi
if [ "$failed" = 0 ]; then printf '\nVerdict: OK\n'; exit 0; fi
if [ "$failed" = 1 ]; then printf '\nVerdict: FAIL (1 gate)\n'; else printf '\nVerdict: FAIL (%s gates)\n' "$failed"; fi
exit 1
