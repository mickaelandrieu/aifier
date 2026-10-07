#!/usr/bin/env sh
# aifier installer: puts the aifier skills into the current repository so your coding agent can
# run /assess and /init. Usage, from the root of a git repository:
#   curl -fsSL https://raw.githubusercontent.com/mickaelandrieu/aifier/main/install.sh | sh
# Options (environment): AIFIER_REF=main  AIFIER_DIR=.agents/skills  AIFIER_SRC=<local checkout>
# Requires a POSIX shell, git, curl and tar: macOS, Linux, WSL or Git Bash. A native Windows
# installer comes with the V2 binary.
set -eu
main() {
REF="${AIFIER_REF:-main}"
DEST="${AIFIER_DIR:-.agents/skills}"
REPO_URL="https://github.com/mickaelandrieu/aifier"
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "aifier: run this from inside a git repository" >&2; exit 1
fi
cd "$(git rev-parse --show-toplevel)"
for tool in curl tar; do command -v "$tool" >/dev/null 2>&1 || { echo "aifier: $tool is required" >&2; exit 1; }; done
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
if [ -n "${AIFIER_SRC:-}" ]; then
  src="$AIFIER_SRC"; echo "aifier: using local source $src"
else
  echo "aifier: downloading $REPO_URL@$REF"
  curl -fsSL "$REPO_URL/archive/refs/heads/$REF.tar.gz" | tar -xz -C "$tmp" || {
    echo "aifier: download failed; the repository may be private, try AIFIER_SRC=<local checkout>" >&2; exit 1; }
  src="$(find "$tmp" -maxdepth 1 -mindepth 1 -type d | head -1)"
fi
mkdir -p "$DEST"
# skills are the portable unit: every engine (Claude Code, opencode, pi) reads SKILL.md
for d in "$src"/skills/*/; do
  name="$(basename "$d")"
  rm -rf "$DEST/$name"; cp -R "$d" "$DEST/$name"
done
# templates travel with init so the skill is self-contained once installed
rm -rf "$DEST/init/templates"; cp -R "$src/templates" "$DEST/init/templates"
mkdir -p .aifier
{
  echo "ref: $REF"; echo "installed_at: $(date +%F)"; echo "skills_dir: $DEST"
  echo "skills:"; for d in "$DEST"/*/; do echo "  - $(basename "$d")"; done
} > .aifier/install.yml
# Claude Code reads .claude/skills; a symlink keeps one source of truth
if [ "$DEST" != ".claude/skills" ] && [ ! -e .claude/skills ]; then
  mkdir -p .claude && ln -s "../$DEST" .claude/skills && echo "aifier: linked .claude/skills -> $DEST"
fi
echo "aifier: installed $(ls "$DEST" | wc -l | tr -d ' ') skills into $DEST"
echo "aifier: next, in your coding agent run /assess then /init"
}
main "$@"
