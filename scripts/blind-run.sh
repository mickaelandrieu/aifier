#!/usr/bin/env bash
# Prepare a blind run of a skill: a throwaway clone of a target repository with the skills of
# this checkout installed, and the prompt to give to an agent that has no other context.
# usage: scripts/blind-run.sh <repo path or URL> <skill> [out dir]
# The out dir is reused only when it holds a previous run (its prompt.md): then repo/ and
# prompt.md are replaced and nothing else is touched. Any other existing directory is refused.
set -eu
repo="${1:?repo}"; skill="${2:?skill}"; out="${3:-${TMPDIR:-/tmp}/aifier-blind-$skill}"
src="$(cd "$(dirname "$0")/.." && pwd)"
work="$out/repo"
if [ -e "$out" ]; then
  [ -f "$out/prompt.md" ] || { echo "BLOCKED: $out exists and is not a previous blind run (no prompt.md); pass another out dir"; exit 1; }
  rm -rf "$work" "$out/prompt.md"
fi
mkdir -p "$out"
git clone -q "$repo" "$work"
( cd "$work" && AIFIER_SRC="$src" sh "$src/install.sh" >/dev/null )
cat > "$out/prompt.md" <<PROMPT
You are a coding agent working in the repository at $work. Skills are installed under .agents/skills/.
Your only instruction: run the \`$skill\` skill. Open .agents/skills/$skill/SKILL.md and follow it exactly as written, as if you had no other knowledge. Use $out/out as the \$OUT directory (create it). Do not read any file outside the repository and that skill directory. Do not commit.
When done, return: (1) what you produced, verbatim; (2) every sentence of the SKILL.md that was unclear, contradictory, or where you had to guess, quoted; (3) the number of tool calls per step.
PROMPT
echo "blind run ready: repo=$work"; echo "prompt: $out/prompt.md"; echo "give the prompt to a fresh agent, then paste its friction list in the pull request's Verification Run"
