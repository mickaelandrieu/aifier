#!/usr/bin/env bash
# Builds the synthetic repositories the collector tests run on. Every commit is dated through
# GIT_AUTHOR_DATE / GIT_COMMITTER_DATE so the collectors print the same thing on every machine.
# Usage: bash tests/fixtures/make.sh [target-dir]   (default: $TMPDIR/aifier-fixtures)
set -eu
TARGET="${1:-${TMPDIR:-/tmp}/aifier-fixtures}"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

new_repo() {
  rm -rf "$TARGET/$1"; mkdir -p "$TARGET/$1"
  git init -q -b main "$TARGET/$1"
  git -C "$TARGET/$1" config user.name "Fixture Author"
  git -C "$TARGET/$1" config user.email "fixture@example.com"
  git -C "$TARGET/$1" config commit.gpgsign false
  git -C "$TARGET/$1" remote add origin "https://example.com/acme/$1.git"
}
# commit <repo> <date> <subject>: stages everything and commits at the given instant
commit() {
  git -C "$TARGET/$1" add -A
  GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$TARGET/$1" commit -q -m "$3"
}
# put <repo> <path>: writes stdin to the file, creating directories
put() { mkdir -p "$(dirname "$TARGET/$1/$2")"; cat > "$TARGET/$1/$2"; }

# --- two-stacks: a python api and a typescript web client, root package.json is tooling residue
r=two-stacks; new_repo $r
put $r package.json <<'F'
{
  "name": "two-stacks-tooling",
  "private": true,
  "dependencies": {
    "husky": "9.1.7"
  }
}
F
put $r .env.example <<'F'
API_URL=http://localhost:8000
API_KEY=replace-me
F
put $r README.md <<'F'
# two-stacks

A sample repository with a python api under `api/` and a typescript client under `web/`.
F
put $r CLAUDE.md <<'F'
# two-stacks — guidance for agents

Two areas: `api/` (python, fastapi) and `web/` (typescript).

## Rules

1. Run the gates of the area you touched before opening a pull request.
2. Keep commits small and conventional.
3. Tests land with the change.

## Gates

- api: `ruff check . && mypy . && pytest`
- web: `npm run lint && npm run typecheck && npm run build`

## Layout

- `api/app/`: application code
- `api/tests/`: pytest suite
- `web/src/`: client code
F
put $r .github/workflows/ci.yml <<'F'
name: ci
on: [push, pull_request]
jobs:
  api:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install -e "api[dev]"
      - run: ruff check api
      - run: pytest api
F
put $r .github/dependabot.yml <<'F'
version: 2
updates:
  - package-ecosystem: pip
    directory: /api
    schedule:
      interval: weekly
F
put $r .github/ISSUE_TEMPLATE/bug.yml <<'F'
name: Bug report
description: Something does not work as expected
body:
  - type: textarea
    attributes:
      label: Expected behaviour
F
commit $r "2026-09-01T10:00:00+00:00" "chore: scaffold repository"

put $r api/pyproject.toml <<'F'
[project]
name = "two-stacks-api"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["fastapi"]

[project.optional-dependencies]
dev = ["pytest", "ruff", "mypy"]

[tool.ruff]
line-length = 100

[tool.mypy]
strict = true
F
put $r api/config/settings.toml <<'F'
[server]
port = 8000
F
put $r api/app/__init__.py <<'F'
"""two-stacks api."""
F
put $r api/app/main.py <<'F'
from fastapi import FastAPI

app = FastAPI()
F
commit $r "2026-09-02T10:00:00+00:00" "feat(api): add application skeleton"

put $r web/package.json <<'F'
{
  "name": "two-stacks-web",
  "private": true,
  "scripts": {
    "lint": "eslint src",
    "build": "tsc -p tsconfig.build.json",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "5.6.3"
  }
}
F
put $r web/tsconfig.json <<'F'
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext"
  },
  "include": ["src"]
}
F
put $r web/tsconfig.build.json <<'F'
{
  "extends": "./tsconfig.json",
  "compilerOptions": { "outDir": "dist" }
}
F
put $r web/src/index.ts <<'F'
export const main = (): void => {};
F
put $r web/src/app.ts <<'F'
export const name = "two-stacks";
F
commit $r "2026-09-04T10:00:00+00:00" "feat(web): add client skeleton"

put $r api/app/routes.py <<'F'
def health() -> dict[str, str]:
    return {"status": "ok"}
F
commit $r "2026-09-06T10:00:00+00:00" "feat(api): add health route"

put $r api/tests/conftest.py <<'F'
import pytest  # noqa: F401
F
put $r api/tests/test_x.py <<'F'
from app.routes import health


def test_health() -> None:
    assert health() == {"status": "ok"}
F
commit $r "2026-09-08T10:00:00+00:00" "test(api): cover the health route"

put $r api/app/models.py <<'F'
from dataclasses import dataclass


@dataclass
class Item:
    name: str
F
commit $r "2026-09-10T10:00:00+00:00" "feat(api): add item model"

put $r web/src/api.ts <<'F'
export const fetchHealth = async (): Promise<string> => "ok";
F
put $r web/src/types.ts <<'F'
export type Item = { name: string };
F
commit $r "2026-09-12T10:00:00+00:00" "feat(web): add api client"

put $r docs/architecture.md <<'F'
# Architecture

Two areas, one repository. The api serves the web client.
F
put $r docs/decisions/0001-record-decisions.md <<'F'
# 0001 — record decisions

Accepted. Decisions live here as short markdown files.
F
commit $r "2026-09-15T10:00:00+00:00" "docs: describe the architecture"

put $r api/app/routes.py <<'F'
def health() -> dict[str, str]:
    return {"status": "ok"}


def echo(payload: dict[str, str] | None) -> dict[str, str]:
    return payload or {}
F
put $r api/tests/test_x.py <<'F'
from app.routes import echo, health


def test_health() -> None:
    assert health() == {"status": "ok"}


def test_echo_empty() -> None:
    assert echo(None) == {}
F
commit $r "2026-09-17T10:00:00+00:00" "fix(api): handle empty payloads (#12)"

put $r web/src/utils.ts <<'F'
export const identity = <T>(value: T): T => value;
F
put $r web/src/config.ts <<'F'
export const apiUrl = "http://localhost:8000";
F
put $r web/src/messages.json <<'F'
{ "hello": "Hello" }
F
commit $r "2026-09-20T10:00:00+00:00" "feat(web): add utils and config"

put $r api/app/services.py <<'F'
from app.models import Item


def rename(item: Item, name: str) -> Item:
    return Item(name=name)
F
commit $r "2026-09-23T10:00:00+00:00" "feat(api): add rename service"

put $r web/src/index.ts <<'F'
import { name } from "./app";

export const main = (): string => name;
F
commit $r "2026-09-26T10:00:00+00:00" "refactor(web): tidy the entrypoint"

# --- docs-only: no manifest at all
r=docs-only; new_repo $r
put $r README.md <<'F'
# docs-only

Documentation lives under `docs/`.
F
commit $r "2026-09-03T10:00:00+00:00" "docs: add readme"
put $r docs/guide.md <<'F'
# Guide

Start with the readme.
F
commit $r "2026-09-10T10:00:00+00:00" "docs: add guide"
put $r docs/faq.md <<'F'
# FAQ

Nothing yet.
F
commit $r "2026-09-18T10:00:00+00:00" "docs: add faq"

# --- dormant: a python project paused since january 2025
r=dormant; new_repo $r
i=0
for v in 0.1.0 0.1.1 0.2.0 0.2.1 0.3.0; do
  i=$((i+1))
  put $r pyproject.toml <<F
[project]
name = "dormant"
version = "$v"
F
  commit $r "2025-01-0${i}T10:00:00+00:00" "chore: release $v"
done

# --- with-secret: docs-only plus tracked configuration holding credentials
r=with-secret; new_repo $r
put $r README.md <<'F'
# with-secret

Documentation lives under `docs/`.
F
commit $r "2026-09-03T10:00:00+00:00" "docs: add readme"
put $r docs/guide.md <<'F'
# Guide

Start with the readme.
F
commit $r "2026-09-10T10:00:00+00:00" "docs: add guide"
put $r docs/faq.md <<'F'
# FAQ

Nothing yet.
F
commit $r "2026-09-18T10:00:00+00:00" "docs: add faq"
put $r config.yml <<'F'
service: billing
api_key: sk_live_ABCDEF1234567890abcdef
F
put $r config.dev.yml <<'F'
service: billing
F
put $r .env <<'F'
PASSWORD=hunter2hunter2
F
commit $r "2026-09-22T10:00:00+00:00" "chore: add runtime configuration"

# --- gates-runner: an aifier.yml with two areas, a passing, a failing and two null gates, a preflight
r=gates-runner; new_repo $r
put $r aifier.yml <<'F'
# generated by aifier init
project: gates-runner
forge: github
repo: acme/gates-runner
areas:
  root: { guide: AGENTS.md, stack: docs }
  api: { guide: api/AGENTS.md, stack: python }
gates:
  root:
    lint: "sh -c 'echo lint ok'"
    typecheck: null
    test: "sh -c 'echo boom && exit 3'"
    build: null
  api:
    lint: 'echo api lint from $(basename "$PWD")'
    typecheck: ~
    test: 'printf "one\ntwo\nthree\nfour\n"'
    build: null
preflight: ["test -f aifier.yml"]
ci:
  file: .github/workflows/ci.yml
  required_checks: [check]
F
put $r .github/workflows/ci.yml <<'F'
name: check
on: [push]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: sh -c 'echo lint ok'
      - run: printf 'one\n'
F
put $r api/README.md <<'F'
# api
F
commit $r "2026-09-25T10:00:00+00:00" "chore: declare gates"

echo "fixtures built under $TARGET"
