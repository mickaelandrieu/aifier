#!/usr/bin/env bash
# aifier assess probes: deterministic evidence collection. Read-only. Output: markdown on stdout.
set -u
ROOT="${1:-.}"
cd "$ROOT" || { echo "cannot cd to $ROOT"; exit 1; }
ROOT="$(pwd)"
SINCE="${AIFIER_SINCE:-90.days}"
have() { command -v "$1" >/dev/null 2>&1; }
exists() { [ -e "$1" ] && echo "present ($(wc -l < "$1" 2>/dev/null | tr -d ' ') lines)" || echo "absent"; }
section() { printf '\n## %s\n\n' "$1"; }
line() { printf -- '- %s\n' "$*"; }
src_files() { git ls-files 2>/dev/null | grep -Ev '(^|/)(node_modules|dist|build|\.venv|vendor)/' ; }

echo "# aifier assess probes"
line "root: $ROOT"
line "date: $(date +%F)"

section "Identity"
line "remote: $(git remote get-url origin 2>/dev/null || echo none)"
line "default branch: $(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#origin/##' || echo unknown)"
line "commits total: $(git rev-list --count HEAD 2>/dev/null || echo 0)"
line "last commit: $(git log -1 --format=%cs 2>/dev/null || echo none)"
line "tracked files: $(src_files | wc -l | tr -d ' ')"
line "languages (by extension, top 8):"
src_files | sed -n 's/.*\.\([A-Za-z0-9]*\)$/\1/p' | sort | uniq -c | sort -rn | head -8 | awk '{printf "  - %s: %s\n", $2, $1}'

section "C. Context"
for f in AGENTS.md CLAUDE.md .cursorrules .github/copilot-instructions.md; do line "$f: $(exists "$f")"; done
for d in .agents/skills .claude/skills .claude/agents .claude/commands .opencode/agents .opencode/commands .opencode/skills .pi; do
  [ -d "$d" ] && line "$d: $(find "$d" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ') entries" || line "$d: absent"
done
line "sub-project AGENTS.md/CLAUDE.md: $(src_files | grep -E '/(AGENTS|CLAUDE)\.md$' | tr '\n' ' ')"
line "docs dirs: $(ls -d docs doc documentation 2>/dev/null | tr '\n' ' ')"
[ -d docs ] && line "docs files: $(find docs -type f -name '*.md' | wc -l | tr -d ' ') markdown, top-level: $(ls docs | tr '\n' ' ')"
line "adr dirs: $(find . -type d \( -iname 'adr' -o -iname 'adrs' -o -iname 'decisions' \) -not -path '*/node_modules/*' 2>/dev/null | tr '\n' ' ')"
line "CHANGELOG: $(exists CHANGELOG.md)"
line "README: $(exists README.md)"
line "CONTRIBUTING: $(exists CONTRIBUTING.md)"
# C5 session load: constitution + @included files
load=0
for f in AGENTS.md CLAUDE.md; do
  [ -f "$f" ] || continue
  load=$((load + $(wc -l < "$f")))
  for inc in $(grep -oE '^@[^ ]+' "$f" | sed 's/^@//'); do [ -f "$inc" ] && load=$((load + $(wc -l < "$inc"))); done
done
line "session load (constitution + @includes): $load lines"
# C4 dead paths cited in constitution/docs
dead=0; total=0
for f in AGENTS.md CLAUDE.md $( [ -d docs ] && find docs -name '*.md' | head -50 ); do
  [ -f "$f" ] || continue
  for p in $(grep -oE '`[A-Za-z0-9_./-]+\.[a-z]{1,5}`' "$f" | tr -d '`' | grep '/' | sort -u); do
    total=$((total+1)); [ -e "$p" ] || dead=$((dead+1))
  done
done
line "paths cited in constitution/docs: $total, dead: $dead"
line "constitution last change: $(git log -1 --format=%cs -- AGENTS.md CLAUDE.md 2>/dev/null || echo n/a); docs last change: $(git log -1 --format=%cs -- docs 2>/dev/null || echo n/a); code last change: $(git log -1 --format=%cs 2>/dev/null)"
line "docs commits in last $SINCE: $(git log --since="$SINCE" --format=%h -- docs AGENTS.md CLAUDE.md 2>/dev/null | wc -l | tr -d ' ') / all commits: $(git log --since="$SINCE" --format=%h 2>/dev/null | wc -l | tr -d ' ')"

section "H. Harnessability"
line "type-check config: $(ls mypy.ini pyrightconfig.json tsconfig.json 2>/dev/null | tr '\n' ' ') $(grep -lE '\[tool\.(mypy|pyright)\]' pyproject.toml */pyproject.toml 2>/dev/null | tr '\n' ' ')"
grep -hE '"strict"\s*:\s*true' tsconfig.json */tsconfig.json 2>/dev/null | head -1 | sed 's/^/  - tsconfig strict: /'
grep -hE '^(strict|disallow_untyped_defs)\s*=\s*[Tt]rue' mypy.ini pyproject.toml */pyproject.toml 2>/dev/null | head -2 | sed 's/^/  - mypy: /'
line "lint/format config: $(ls .ruff.toml ruff.toml .flake8 .eslintrc* eslint.config.* biome.json .prettierrc* .editorconfig 2>/dev/null | tr '\n' ' ') $(grep -lE '\[tool\.(ruff|black|isort|flake8)\]' pyproject.toml */pyproject.toml 2>/dev/null | tr '\n' ' ')"
line "pre-commit: $(exists .pre-commit-config.yaml); git hooks dir: $(git config core.hooksPath 2>/dev/null || echo default)"
line "module boundary tooling: $(grep -lE 'import-linter|importlinter|dependency-cruiser|eslint-plugin-boundaries|tach' pyproject.toml package.json .importlinter setup.cfg 2>/dev/null | tr '\n' ' ')"
line "top-level layout: $(ls -d */ 2>/dev/null | tr '\n' ' ')"
line "lockfiles: $(ls uv.lock poetry.lock Pipfile.lock package-lock.json pnpm-lock.yaml yarn.lock Cargo.lock go.sum 2>/dev/null | tr '\n' ' ')"
line "runtime pins: $(ls .python-version .nvmrc .node-version .tool-versions 2>/dev/null | tr '\n' ' ') $(grep -hoE '"engines"' package.json 2>/dev/null) $(grep -hoE 'requires-python\s*=\s*"[^"]+"' pyproject.toml */pyproject.toml 2>/dev/null | head -1)"
line "containers: $(ls Dockerfile */Dockerfile docker-compose.y*ml compose.y*ml 2>/dev/null | tr '\n' ' ')"
line "Makefile targets: $( [ -f Makefile ] && grep -oE '^[a-zA-Z_-]+:' Makefile | tr -d ':' | tr '\n' ' ' || echo none)"
line "package.json scripts: $( [ -f package.json ] && have jq && jq -r '.scripts // {} | keys | join(" ")' package.json || echo none)"
line "generators/templates: $(find . -maxdepth 3 -type d \( -iname 'templates' -o -iname 'scaffold*' -o -iname 'generators' -o -iname 'examples' \) -not -path '*/node_modules/*' -not -path './.git/*' 2>/dev/null | tr '\n' ' ')"

section "Tests"
line "test files: $(src_files | grep -E '(^|/)(test_[^/]+\.py|[^/]+_test\.py|[^/]+\.(test|spec)\.[jt]sx?)$' | wc -l | tr -d ' ')"
line "test dirs: $(find . -type d \( -name tests -o -name test -o -name __tests__ -o -name e2e \) -not -path '*/node_modules/*' -not -path './.git/*' 2>/dev/null | tr '\n' ' ')"
line "e2e tooling: $(grep -lE 'playwright|cypress|puppeteer' package.json */package.json pyproject.toml 2>/dev/null | tr '\n' ' ')"
line "coverage config: $(grep -lE 'coverage|--cov|c8|istanbul' pyproject.toml setup.cfg .coveragerc package.json vitest.config.* jest.config.* 2>/dev/null | tr '\n' ' ')"

section "CI pipelines"
ci=$(ls .github/workflows/*.y*ml .gitlab-ci.yml cloudbuild*.y*ml .circleci/config.yml Jenkinsfile bitbucket-pipelines.yml 2>/dev/null)
[ -z "$ci" ] && line "none found"
for f in $ci; do
  line "$f:"
  for k in ruff flake8 eslint biome prettier mypy pyright tsc pytest vitest jest playwright cypress coverage codecov trivy gitleaks trufflehog semgrep bandit snyk dependabot build docker deploy; do
    grep -qiE "\b$k\b" "$f" && printf '  - %s\n' "$k"
  done
done
line "dependabot/renovate: $(ls .github/dependabot.yml renovate.json .renovaterc* 2>/dev/null | tr '\n' ' ')"
line "secret scanning config: $(ls .gitleaks.toml .secrets.baseline .trufflehog* 2>/dev/null | tr '\n' ' ')"
line ".env tracked by git: $(git ls-files | grep -E '(^|/)\.env(\.local|\.prod.*)?$' | tr '\n' ' ')"
line ".env.example: $(exists .env.example)"
line "dead code tooling: $(grep -lE 'vulture|knip|ts-prune|deadcode' pyproject.toml package.json 2>/dev/null | tr '\n' ' ')"
line "feature flags lib: $(grep -lE 'unleash|launchdarkly|flipt|flagsmith|growthbook' pyproject.toml package.json 2>/dev/null | tr '\n' ' ')"
line "structured logging / tracing: $(grep -lE 'structlog|opentelemetry|langfuse|sentry|datadog' pyproject.toml package.json 2>/dev/null | tr '\n' ' ')"

section "Git activity"
WIN="--since=$SINCE"
n=$(git log $WIN --no-merges --format=%h | wc -l | tr -d ' ')
if [ "$n" -lt 20 ]; then WIN="-n 100"; n=$(git log $WIN --no-merges --format=%h | wc -l | tr -d ' '); line "window: last $SINCE too sparse, falling back to last 100 commits (ending $(git log -1 --format=%cs))"; else line "window: last $SINCE"; fi
line "non-merge commits: $n; merge commits: $(git log $WIN --merges --format=%h | wc -l | tr -d ' ')"
conv=$(git log $WIN --no-merges --format=%s | grep -cE '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf)(\([^)]*\))?!?:' )
line "conventional commit subjects: $conv / $n"
line "commits referencing an issue (#N): $(git log $WIN --no-merges --format='%s %b' | grep -cE '#[0-9]+') / $n"
code=0; both=0
for h in $(git log $WIN --no-merges --format=%h | head -300); do
  files=$(git show --format= --name-only "$h")
  echo "$files" | grep -qE '\.(py|ts|tsx|js|jsx|go|rs|java|kt|rb|php)$' || continue
  code=$((code+1))
  echo "$files" | grep -qE '(^|/)(tests?|__tests__|e2e)/|test_[^/]+\.py|_test\.py|\.(test|spec)\.' && both=$((both+1))
done
line "code commits also touching tests: $both / $code"
line "commit size (lines changed, non-merge, sorted sample):"
git log $WIN --no-merges --shortstat --format= | awk '/changed/ {a=0; d=0; for(i=1;i<=NF;i++){ if($(i+1) ~ /insertion/) a=$i; if($(i+1) ~ /deletion/) d=$i }; print a+d}' | sort -n | awk '{v[NR]=$1} END { if (NR==0) {print "  - no data"; exit} printf "  - count %d, median %d, p90 %d\n", NR, v[int((NR+1)/2)], v[int(NR*0.9)+ (NR*0.9==int(NR*0.9)?0:1)] }'
line "merge authors (who merges): $(git log $WIN --merges --format=%an | sort | uniq -c | sort -rn | head -5 | awk '{$1=$1; print}' | tr '\n' ';')"
line "direct commits on default branch (non-merge, first-parent): $(git log $WIN --first-parent --no-merges --format=%h "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo HEAD)" 2>/dev/null | wc -l | tr -d ' ')"
line "postmortem/incident files: $(src_files | grep -iE 'postmortem|post-mortem|incident' | head -5 | tr '\n' ' ')"
line "migrations: $(find . -type d \( -iname 'migrations' -o -iname 'migration' -o -iname 'alembic' -o -path '*/database/scripts' \) -not -path '*/node_modules/*' -not -path './.git/*' 2>/dev/null | head -3 | tr '\n' ' ')"
line "tags: $(git tag | wc -l | tr -d ' '), latest: $(git describe --tags --abbrev=0 2>/dev/null || echo none)"

section "GitHub (gh)"
if have gh && gh auth status >/dev/null 2>&1 && gh repo view --json nameWithOwner >/dev/null 2>&1; then
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  def=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
  line "repo: $repo, default branch: $def"
  line "issue templates: $(ls .github/ISSUE_TEMPLATE/ 2>/dev/null | tr '\n' ' ') $( [ -f .github/ISSUE_TEMPLATE.md ] && echo ISSUE_TEMPLATE.md )"
  line "PR template: $(ls .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md PULL_REQUEST_TEMPLATE.md 2>/dev/null | tr '\n' ' ')"
  prot=$(gh api "repos/$repo/branches/$def/protection" 2>/dev/null)
  if [ -n "$prot" ]; then
    line "branch protection on $def: enabled"
    echo "$prot" | jq -r '"  - required reviews: \(.required_pull_request_reviews.required_approving_review_count // 0), dismiss stale: \(.required_pull_request_reviews.dismiss_stale_reviews // false)\n  - required checks: \((.required_status_checks.contexts // []) | join(", "))\n  - enforce admins: \(.enforce_admins.enabled // false)"' 2>/dev/null
  else
    rules=$(gh api "repos/$repo/rules/branches/$def" 2>/dev/null | jq -r '[.[].type] | join(", ")' 2>/dev/null)
    line "branch protection on $def: ${rules:+rulesets: $rules}${rules:-none}"
  fi
  line "reviews on the last 6 merged PRs (number base author mergedBy reviews):"
  gh pr list --state merged --limit 6 --json number,author,mergedBy,reviews,baseRefName -q '.[] | "  - #\(.number) \(.baseRefName) \(.author.login) -> \(.mergedBy.login // "?") [\([.reviews[] | "\(.author.login):\(.state)"] | join(","))]"' 2>/dev/null
  last=$(gh pr list --state merged --limit 1 --json number -q '.[0].number' 2>/dev/null)
  line "checks reported on PR #${last:-?}: $(gh pr view "$last" --json statusCheckRollup -q '[.statusCheckRollup[] | "\(.name // .context)=\(.conclusion // .state)"] | join(", ")' 2>/dev/null)"
  rs=$(gh api "repos/$repo/rulesets" 2>/dev/null)
  case "$rs" in *'"message"'*) line "rulesets: not observable ($(echo "$rs" | jq -r .status 2>/dev/null))";; *) line "rulesets: $(echo "$rs" | jq -r '[.[] | "\(.name) (\(.enforcement))"] | join(", ")' 2>/dev/null)";; esac
  line "labels: $(gh label list --limit 100 --json name -q '[.[].name] | join(", ")' 2>/dev/null)"
  line "open issues: $(gh issue list --state open --limit 1 --json number -q 'length' 2>/dev/null), open PRs: $(gh pr list --state open --limit 1 --json number -q 'length' 2>/dev/null)"
  line "last 20 closed issues: with acceptance criteria wording / with a template-like structure / total:"
  gh issue list --state closed --limit 20 --json body,title 2>/dev/null | jq -r '[.[] | .body // ""] | "  - \(map(select(test("(?i)acceptance|crit[eè]re|given|when|then|expected"))) | length) / \(map(select(test("(?i)^#+ |\\*\\*(problem|impact|context)"))) | length) / \(length)"' 2>/dev/null
  prs=$(gh pr list --state merged --limit 100 --json number,title,body,additions,deletions,changedFiles,mergedBy,reviews,mergedAt 2>/dev/null)
  since=$(date -v-90d +%F 2>/dev/null || date -d '-90 days' +%F)
  recent=$(echo "$prs" | jq --arg since "$since" '[.[] | select(.mergedAt >= $since)] | length')
  if [ "${recent:-0}" -ge 10 ]; then line "PRs merged in last $SINCE:"; else line "PRs merged (last 100, window too sparse):"; since="0000-00-00"; fi
  echo "$prs" | jq -r --arg since "$since" '
    [.[] | select(.mergedAt >= $since)] |
    "  - count: \(length)\n  - referencing an issue (#N): \(map(select((.title + (.body // "")) | test("#[0-9]+"))) | length)\n  - with at least one review: \(map(select((.reviews | length) > 0)) | length)\n  - median changed files: \(if length>0 then (map(.changedFiles) | sort | .[length/2|floor]) else 0 end), median lines: \(if length>0 then (map(.additions+.deletions) | sort | .[length/2|floor]) else 0 end)\n  - merged by: \(map(.mergedBy.login // "unknown") | group_by(.) | map("\(.[0]) \(length)") | join(", "))\n  - merged by a bot: \(map(select((.mergedBy.login // "") | test("\\[bot\\]|bot$"))) | length)"' 2>/dev/null
else
  line "gh unavailable or not authenticated: D2, D3, D5, R1, R4, L1 are NOT OBSERVABLE"
  line "issue templates (local): $(ls .github/ISSUE_TEMPLATE/ 2>/dev/null | tr '\n' ' ')"
  line "PR template (local): $(ls .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md 2>/dev/null | tr '\n' ' ')"
fi

section "Aifier footprint"
line "aifier.yml: $(exists aifier.yml)"
line "rules catalogue: $(src_files | grep -iE 'learned-rules|rules/README|RULE-[0-9]+' | head -3 | tr '\n' ' ')"
line "process skills: $(for s in verification-evidence compound review-checklist workflow-label assess; do find .agents/skills .claude/skills .opencode/skills -maxdepth 1 -name "$s" -o -maxdepth 1 -name "aifier-$s" 2>/dev/null; done | tr '\n' ' ')"
line "checkpoints dir: $(ls -d .aifier/checkpoints 2>/dev/null | tr '\n' ' ')"
