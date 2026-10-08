#!/usr/bin/env sh
# aifier installer: puts the aifier skills into the current repository so your coding agent can
# run /assess and /init, and the aifier binary that /init renders with. Usage, from the root of
# a git repository:
#   curl -fsSL https://raw.githubusercontent.com/mickaelandrieu/aifier/main/install.sh | sh
# Options (environment): AIFIER_REF=<tag or branch>  AIFIER_DIR=.agents/skills
#   AIFIER_SRC=<local checkout>  AIFIER_BIN=<a built binary, with AIFIER_SRC>
# AIFIER_REF defaults to the latest release tag (main when there is none, or when AIFIER_SRC is
# set: a local checkout has no tag to query). With a tag (v1.2.3) the binary of that release is
# downloaded and its checksum verified; with a branch, or from a local checkout without a build,
# the skills are installed and init says which command builds the binary. AIFIER_RELEASE_URL=<base
# url> overrides where the release assets are fetched from (tests use a file:// directory); it
# needs a tag ref. The checksum comes from the same release as the asset: it guards against a
# corrupted or wrong-target download, not against a compromised host. Requires a POSIX shell, git,
# curl and tar: macOS, Linux, WSL or Git Bash. A native Windows installer comes with a later release.
set -eu
main() {
REF="${AIFIER_REF:-}"
DEST="${AIFIER_DIR:-.agents/skills}"
BIN_DIR=".aifier/bin"
REPO_URL="https://github.com/mickaelandrieu/aifier"
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "aifier: run this from inside a git repository" >&2; exit 1
fi
# relative paths given by the caller are resolved from where the caller stands, before the cd
src=""
if [ -n "${AIFIER_SRC:-}" ]; then
  src="$(cd "$AIFIER_SRC" 2>/dev/null && pwd -P)" || { echo "aifier: AIFIER_SRC=$AIFIER_SRC is not a directory" >&2; exit 1; }
fi
built="${AIFIER_BIN:-}"
case "$built" in ""|/*) ;; *) built="$PWD/$built";; esac
cd "$(git rev-parse --show-toplevel)"
for tool in curl tar; do command -v "$tool" >/dev/null 2>&1 || { echo "aifier: $tool is required" >&2; exit 1; }; done
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
if [ -z "$REF" ]; then
  if [ -n "$src" ]; then
    REF=main
  else
    REF="$(latest_tag || true)"
    [ -n "$REF" ] || { echo "aifier: no release yet, installing the skills from main; the binary needs a tag"; REF=main; }
  fi
fi
case "$REF" in v[0-9]*) is_tag=1;; *) is_tag=0;; esac
if [ -n "$src" ]; then
  echo "aifier: using local source $src"
else
  echo "aifier: downloading $REPO_URL@$REF"
  if [ "$is_tag" = 1 ]; then archive="$REPO_URL/archive/refs/tags/$REF.tar.gz"
  else archive="$REPO_URL/archive/refs/heads/$REF.tar.gz"; fi
  curl -fsSL "$archive" | tar -xz -C "$tmp" || {
    echo "aifier: download failed; the repository may be private, try AIFIER_SRC=<local checkout>" >&2; exit 1; }
  src="$(find "$tmp" -maxdepth 1 -mindepth 1 -type d | head -1)"
fi
mkdir -p "$DEST"
if [ "$(cd "$DEST" && pwd -P)" = "$(cd "$src/skills" && pwd -P)" ]; then
  echo "aifier: installing into its own skills directory, nothing to copy"
else
  # skills are the portable unit: every engine (Claude Code, opencode, pi) reads SKILL.md
  for d in "$src"/skills/*/; do
    name="$(basename "$d")"
    rm -rf "$DEST/$name"; cp -R "$d" "$DEST/$name"
  done
  # templates travel with init so the skill is self-contained once installed
  rm -rf "$DEST/init/templates"; cp -R "$src/templates" "$DEST/init/templates"
fi

# the binary: one per platform, released with the repository tag (ADR 0002)
binary="none"
target="$(platform_target || true)"
if [ -n "${AIFIER_RELEASE_URL:-}" ] && [ -n "$target" ] && [ "$is_tag" = 1 ]; then
  fetch_binary "$AIFIER_RELEASE_URL" "$target"
elif [ -n "${AIFIER_SRC:-}" ]; then
  [ -z "${AIFIER_RELEASE_URL:-}" ] || echo "aifier: AIFIER_RELEASE_URL needs AIFIER_REF=<tag>, using the local build instead"
  [ -n "$built" ] || built="$src/target/release/aifier"
  if [ -x "$built" ]; then
    mkdir -p "$BIN_DIR"; cp "$built" "$BIN_DIR/aifier"; binary="$BIN_DIR/aifier (copied from $built)"
  else
    echo "aifier: no binary at $built; build it with 'cargo build --release' in $src and run this again, init needs it"
  fi
elif [ -z "$target" ]; then
  echo "aifier: no binary for $(uname -s)/$(uname -m); build from source with 'cargo build --release', init needs it"
elif [ "$is_tag" = 1 ]; then
  fetch_binary "$REPO_URL/releases/download/$REF" "$target"
else
  echo "aifier: branches carry no binary; use AIFIER_REF=<tag> (see $REPO_URL/releases) for init's renderer"
fi
if [ "$binary" = none ] && [ -x "$BIN_DIR/aifier" ]; then
  binary="$BIN_DIR/aifier (kept from a previous install)"
fi

mkdir -p .aifier
{
  echo "ref: $REF"; echo "installed_at: $(date +%F)"; echo "skills_dir: $DEST"; echo "binary: $binary"
  echo "skills:"; for d in "$DEST"/*/; do echo "  - $(basename "$d")"; done
} > .aifier/install.yml
# Claude Code reads .claude/skills; a symlink keeps one source of truth
if [ "$DEST" != ".claude/skills" ] && [ ! -e .claude/skills ]; then
  mkdir -p .claude
  case "$DEST" in /*) ln -s "$DEST" .claude/skills;; *) ln -s "../$DEST" .claude/skills;; esac
  echo "aifier: linked .claude/skills -> $DEST"
fi
echo "aifier: installed $(find "$DEST" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ') skills into $DEST; binary: $binary"
echo "aifier: next, in your coding agent run /assess then /init"
}
# latest_tag: the tag of the latest GitHub release, empty when there is none or the query fails.
latest_tag() {
  curl -fsSL --max-time 10 "https://api.github.com/repos/mickaelandrieu/aifier/releases/latest" 2>/dev/null \
    | tr -d '\n' | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p'
}
# fetch_binary <base url> <target>: downloads the asset of $REF, verifies it against SHA256SUMS,
# extracts it into $BIN_DIR. Exits 1 on a missing asset or a mismatch: a wrong binary is worse than none.
fetch_binary() {
  asset="aifier-$REF-$2.tar.gz"
  curl -fsSL "$1/$asset" -o "$tmp/$asset" && curl -fsSL "$1/SHA256SUMS" -o "$tmp/SHA256SUMS" || {
    echo "aifier: cannot download $asset from $1" >&2; exit 1; }
  expected="$(grep " $asset\$" "$tmp/SHA256SUMS" | cut -d' ' -f1)"
  actual="$(sha256_of "$tmp/$asset")"
  [ -n "$expected" ] && [ "$expected" = "$actual" ] || { echo "aifier: checksum mismatch for $asset" >&2; exit 1; }
  mkdir -p "$BIN_DIR"; tar -xz -C "$BIN_DIR" -f "$tmp/$asset"; chmod +x "$BIN_DIR/aifier"
  binary="$BIN_DIR/aifier ($REF, $2, sha256 verified)"
}
# The Rust target of this machine, empty when no release asset exists for it.
platform_target() {
  os="$(uname -s)"; arch="$(uname -m)"
  case "$arch" in x86_64|amd64) arch=x86_64;; arm64|aarch64) arch=aarch64;; *) return 1;; esac
  case "$os" in
    Linux) echo "$arch-unknown-linux-musl";;
    Darwin) echo "$arch-apple-darwin";;
    *) return 1;;
  esac
}
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  else echo "aifier: sha256sum or shasum is required to verify the binary" >&2; exit 1; fi
}
main "$@"
