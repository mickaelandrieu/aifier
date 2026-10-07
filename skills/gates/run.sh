#!/usr/bin/env bash
# aifier gates runner: run the gates declared in aifier.yml and capture their output.
#
# usage: run.sh <aifier.yml> [--area <name>] [--family lint|typecheck|test|build] [--preflight]
#        [--compare-ci] [--out <dir>]
#
# Prints a `## Verification Run` block: one line per gate with the command, the exit code and
# the path of its captured output, or BLOCKED with the reason. Exit code 1 when a gate failed,
# 2 when the preflight failed (nothing else runs), 0 otherwise.
#
# Reads only the subset of aifier.yml that init renders: `gates:` (two-space area, four-space
# family: command, `null` for none), `preflight:` (inline list or `- item` lines) and `ci:`
# (`file:`). Anything else in the file is ignored; it is not a YAML parser.
set -u
usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; }
[ $# -ge 1 ] || { usage; exit 2; }
cfg="$1"; shift
[ -f "$cfg" ] || { echo "BLOCKED: $cfg not found"; exit 2; }
area_opt=""; family_opt=""; preflight_opt=0; compare_ci=0; out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --area) area_opt="$2"; shift 2;;
    --family) family_opt="$2"; shift 2;;
    --preflight) preflight_opt=1; shift;;
    --compare-ci) compare_ci=1; shift;;
    --out) out="$2"; shift 2;;
    *) echo "unknown option: $1"; usage; exit 2;;
  esac
done
root="$(cd "$(dirname "$cfg")" && pwd -P)"
cfg_rel="$(basename "$cfg")"
out="${out:-$root/.aifier/gates}"
mkdir -p "$out"

# One record per line, tab-separated, in file order:
#   gate <area> <family> <command or empty>  |  preflight <command>  |  ci <key> <value>
records="$(awk '
  function unquote(s) { sub(/^["\x27]/, "", s); sub(/["\x27]$/, "", s); return s }
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  /^[ \t]*$/ || /^[ \t]*#/ { next }
  {
    line = $0; sub(/\r$/, "", line)
    body = line; sub(/^[ \t]+/, "", body)
    indent = length(line) - length(body)
    if (indent == 0) {
      section = body; sub(/:.*/, "", section); area = ""
      if (section == "preflight" && body ~ /\]$/) {
        inner = body; sub(/^[^:]*:[ \t]*\[/, "", inner); sub(/\][ \t]*$/, "", inner)
        n = split(inner, items, ",")
        for (i = 1; i <= n; i++) { it = unquote(trim(items[i])); if (it != "") print "preflight\t" it }
      }
      next
    }
    if (section == "gates") {
      if (indent == 2) { area = body; sub(/:[ \t]*$/, "", area) }
      else if (indent == 4 && area != "") {
        key = body; sub(/:.*/, "", key); key = trim(key)
        val = body; sub(/^[^:]*:/, "", val); val = trim(val)
        if (val == "null" || val == "~" || val == "") val = ""; else val = unquote(val)
        print "gate\t" area "\t" key "\t" val
      }
    } else if (section == "preflight" && body ~ /^- /) {
      it = body; sub(/^- [ \t]*/, "", it); print "preflight\t" unquote(trim(it))
    } else if (section == "ci") {
      key = body; sub(/:.*/, "", key); key = trim(key)
      val = body; sub(/^[^:]*:/, "", val); val = unquote(trim(val))
      print "ci\t" key "\t" val
    }
  }' "$cfg")"

# run <command> <cwd> <log>: captures the command, sets $code and $tail (last three lines)
run() {
  printf '$ %s   (cwd %s)\n' "$1" "$2" > "$3"
  (cd "$2" && sh -c "$1") >> "$3" 2>&1; code=$?
  tail="$(tail -n 3 "$3" | sed 's/^/  /')"
}
rel() { case "$1" in "$root"/*) printf '%s' "${1#"$root"/}";; *) printf '%s' "$1";; esac; }

printf '## Verification Run\n\n'
printf 'Date: %s · Config: %s\n\n' "$(date +%Y-%m-%dT%H-%M)" "$cfg_rel"

preflights="$(printf '%s\n' "$records" | awk -F'\t' '$1=="preflight"{print $2}')"
if [ "$preflight_opt" = 1 ] || [ -n "$preflights" ]; then
  i=0
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    run "$cmd" "$root" "$out/preflight-$i.log"
    if [ "$code" != 0 ]; then printf 'BLOCKED: preflight `%s` exited %s\n%s\n' "$cmd" "$code" "$tail"; exit 2; fi
    printf -- '- preflight ok: `%s`\n' "$cmd"
    i=$((i + 1))
  done <<EOF
$preflights
EOF
  [ -n "$preflights" ] && printf '\n'
fi

if [ "$compare_ci" = 1 ]; then
  ci="$(printf '%s\n' "$records" | awk -F'\t' '$1=="ci" && $2=="file"{print $3; exit}')"
  if [ -n "$ci" ] && [ -f "$root/$ci" ]; then text="$(cat "$root/$ci")"; else text=""; fi
  printf 'CI comparison (%s):\n' "${ci:-no CI file declared}"
  while IFS=$'\t' read -r kind area fam cmd; do
    [ "$kind" = gate ] && [ -n "$cmd" ] || continue
    set -- $cmd
    case "$1" in npm|npx|uv|poetry) token="$1 ${2:-} ${3:-}"; token="${token% }"; token="${token% }";; *) token="$1";; esac
    if printf '%s' "$text" | grep -qF -- "$token"; then printf -- '- %s/%s: found in CI\n' "$area" "$fam"
    else printf -- '- %s/%s: NOT in CI (`%s`)\n' "$area" "$fam" "$token"; fi
  done <<EOF
$records
EOF
  printf '\n'
fi

failed=0
while IFS=$'\t' read -r kind area fam cmd; do
  [ "$kind" = gate ] || continue
  [ -z "$area_opt" ] || [ "$area" = "$area_opt" ] || continue
  [ -z "$family_opt" ] || [ "$fam" = "$family_opt" ] || continue
  if [ -z "$cmd" ]; then printf -- '- %s/%s: not declared (gap)\n' "$area" "$fam"; continue; fi
  if [ "$area" = root ]; then cwd="$root"; else cwd="$root/$area"; fi
  log="$out/$area-$fam.log"
  run "$cmd" "$cwd" "$log"
  if [ "$code" = 0 ]; then status=OK; else status=FAIL; failed=$((failed + 1)); fi
  printf -- '- %s/%s: %s (exit %s) `%s` → %s\n%s\n' "$area" "$fam" "$status" "$code" "$cmd" "$(rel "$log")" "$tail"
done <<EOF
$records
EOF

if [ "$failed" = 0 ]; then printf '\nVerdict: OK\n'; exit 0; fi
if [ "$failed" = 1 ]; then printf '\nVerdict: FAIL (1 gate)\n'; else printf '\nVerdict: FAIL (%s gates)\n' "$failed"; fi
exit 1
