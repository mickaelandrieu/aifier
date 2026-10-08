#!/usr/bin/env bash
# aifier gate: where an issue stands in the cycle, in one line that names the facts it rests on.
# Read-only. This is the one place the gate decision is written: qualify, plan and build act on
# the printed state instead of describing labels, headings and comments themselves.
# usage: gate.sh N [--repo <owner/name>] [--prefix <label prefix>]   fetches the issue with gh
#        gate.sh --from <payload.json> [--repo <owner/name>] [--prefix <label prefix>]   decides from a saved payload, no gh
# payload: {"issue": {"number", "body", "labels": [{"name"}], "comments": [{"author": {"login"}, "body", "createdAt"}]},
#           "prs": [{"number", "body", "closingIssuesReferences": [{"number", "repository": {"name", "owner": {"login"}}}]}]}
#          (what gh returns, see fetch below); a closing reference counts only when its repository
#          is the --repo one (or when the reference carries no repository, or no --repo is known)
# states, in the order they are decided:
#   in-progress          label <prefix>:in-progress, or an open pull request that closes N or names #N as a word
#                        (outside backticks and code fences)
#   done                 label <prefix>:done
#   not-qualified        body without the contract shape (## Problem, ## Impact, ## Acceptance criteria,
#                        <summary>Technical analysis</summary>), or shape without a <prefix> label
#   chosen <letter>      a comment whose first line is `approach: <letter>` (any case; printed upper-cased),
#                        by a human login, posted after the latest comment holding a `## Plan` heading
#   planned              a `## Plan` comment without such a reply
#   needs-input          label <prefix>:needs-input and no plan
#   qualified            label <prefix>:todo and a comment whose first line is `contract: ok` (any case) by a
#                        human login;  proposed: label <prefix>:todo without that comment;
#                        qualified (partial): label <prefix>:partial, a slice landed
# a human login: not ending in [bot] or -bot, and not github-actions or dependabot.
# exit 0 with the state line; exit 1 with "BLOCKED: <reason>" when gh or jq cannot produce the payload.
set -u
have() { command -v "$1" >/dev/null 2>&1; }
blocked() { echo "BLOCKED: $*"; exit 1; }

number=""; repo=""; prefix=""; from=""
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2;;
    --prefix) prefix="${2:-}"; shift 2;;
    --from) from="${2:-}"; shift 2;;
    -h|--help) sed -n '2,25p' "$0"; exit 0;;
    *) n="${1%%\#*}"; n="${n%%\?*}"; n="${n%/}"; number="${n##*/}"; shift;;   # a number or an issue URL, without fragment, query or trailing slash
  esac
done
have jq || blocked "jq is required"
cfg="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/aifier.yml"
cfgtext=""; [ -f "$cfg" ] && cfgtext="$(tr -d '\r' < "$cfg")"   # CRLF files: the values must not carry \r
[ -z "$prefix" ] && [ -n "$cfgtext" ] && prefix="$(printf '%s\n' "$cfgtext" | sed -n 's/^  prefix: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' | head -1)"
[ -z "$prefix" ] && prefix="sdlc"
prefix="${prefix%:}"

if [ -n "$from" ]; then
  [ -f "$from" ] || blocked "payload $from not found"
  payload="$(cat "$from")"
else
  case "$number" in ''|*[!0-9]*) echo "usage: gate.sh N [--repo owner/name] [--prefix p] | gate.sh --from payload.json"; exit 2;; esac
  have gh || blocked "gh unavailable"
  [ -z "$repo" ] && [ -n "$cfgtext" ] && repo="$(printf '%s\n' "$cfgtext" | sed -n 's/^repo: *//p' | head -1)"
  [ -n "$repo" ] && [ "$repo" != unknown ] || blocked "no repository: pass --repo or run inside a repo with aifier.yml"
  r=(--repo "$repo")
  issue="$(gh issue view "$number" ${r[@]+"${r[@]}"} --json number,body,labels,comments 2>&1)" || blocked "gh unavailable ($(echo "$issue" | head -1))"
  prs="$(gh pr list ${r[@]+"${r[@]}"} --state open --limit 200 --json number,body,closingIssuesReferences 2>&1)" || blocked "gh unavailable ($(echo "$prs" | head -1))"
  payload="$(jq -n --argjson issue "$issue" --argjson prs "$prs" '{issue: $issue, prs: $prs}' 2>/dev/null)" || blocked "gh returned something jq cannot read ($(echo "$issue" | head -1 | cut -c1-120))"
fi

echo "$payload" | jq -r --arg pre "$prefix" --arg repo "$repo" '
  def heading($h): test("(^|\n)" + $h + "[ \t]*(\r?\n|$)");
  def human: (. // "") | (endswith("[bot]") or endswith("-bot") or . == "github-actions" or . == "dependabot") | not;
  def nocode: gsub("```[^`]*```"; " ") | gsub("`[^`\n]*`"; " ");
  .issue as $i
  | ($i.number) as $n
  | ($i.body // "") as $body
  | ([$i.labels[]?.name | select(startswith($pre + ":"))]) as $labels
  | ($i.comments // []) as $c
  | (($body | heading("## Problem")) and ($body | heading("## Impact")) and ($body | heading("## Acceptance criteria"))
     and ($body | test("<summary>Technical analysis</summary>"))) as $shape
  | ([range(0; $c | length) | select(($c[.].body // "") | heading("## Plan"))] | last) as $plan
  | (if $plan == null then null
     else ([range($plan + 1; $c | length)
            | select(($c[.].author.login | human) and (($c[.].body // "") | test("^approach: *[A-Za-z]"; "i")))]
           | first) end) as $reply
  | (if $reply == null then null else (($c[$reply].body // "") | capture("^approach: *(?<l>[A-Za-z])"; "i") | .l | ascii_upcase) end) as $letter
  | ([range(0; $c | length) | select(($c[.].author.login | human) and (($c[.].body // "") | test("^contract: *ok"; "i")))] | first) as $ok
  | (if ($repo | length) > 0 then ($repo | split("/")) else [] end) as $rp
  | ([.prs[]? | select((([.closingIssuesReferences[]?
                          | select(.repository == null or ($rp | length) < 2
                                   or (.repository.name == $rp[1] and .repository.owner.login == $rp[0]))
                          | .number] | index($n)) != null)
                        or (((.body // "") | nocode) | test("(^|[^0-9A-Za-z_/])#" + ($n | tostring) + "([^0-9]|$)")))
      | .number]) as $prs
  | ($labels | index($pre + ":in-progress") != null) as $wip
  | (if $wip or ($prs | length) > 0 then "in-progress"
     elif ($labels | index($pre + ":done")) != null then "done"
     elif ($shape | not) or ($labels | length) == 0 then "not-qualified"
     elif $letter != null then "chosen " + $letter
     elif $plan != null then "planned"
     elif ($labels | index($pre + ":needs-input")) != null then "needs-input"
     elif ($labels | index($pre + ":todo")) != null then (if $ok != null then "qualified" else "proposed" end)
     elif ($labels | index($pre + ":partial")) != null then "qualified (partial)"
     else "not-qualified" end) as $state
  | "state: \($state) (shape: \(if $shape then "ok" else "missing" end), labels: \(if ($labels | length) > 0 then ($labels | join(" ")) else "none" end), contract reply: \(if $ok != null then "ok by \($c[$ok].author.login) on \(($c[$ok].createdAt // "")[0:10])" else "none" end), plan comment: \(if $plan != null then "comment \($plan + 1) of \($c | length)" else "none" end), approach reply: \(if $reply != null then "\($letter) by \($c[$reply].author.login) on \(($c[$reply].createdAt // "")[0:10])" else "none" end), open PR: \(if ($prs | length) > 0 then ($prs | map("#" + tostring) | join(" ")) else "none" end))"
' 2>/dev/null || blocked "payload is not the expected shape ($(echo "$payload" | head -1 | cut -c1-120))"
