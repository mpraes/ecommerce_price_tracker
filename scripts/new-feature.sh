#!/usr/bin/env bash
# Open a feature branch off main, push it, and open a PR via gh.
#
# Usage:
#   scripts/new-feature.sh <branch-name> [base-branch]
#
# Branch name must be lowercase, kebab-case, e.g.:
#   scripts/new-feature.sh fix/redis-port-conflict
#   scripts/new-feature.sh feat/ci-workflow
#
# The script:
#   1. Verifies the working tree is clean and we're on main.
#   2. Fetches origin and fast-forwards main.
#   3. Creates and checks out <branch-name> from main.
#   4. (You do your work, commit.)
#   5. Pushes the branch and opens a PR with `gh pr create`.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <branch-name> [base-branch]" >&2
  echo "  branch-name:  e.g. fix/redis-port-conflict, feat/ci-workflow" >&2
  exit 64
fi

BRANCH="$1"
BASE="${2:-main}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required (https://cli.github.com)" >&2
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required (https://docs.astral.sh/uv/)" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "working tree is dirty; commit or stash first" >&2
  exit 1
fi

CURRENT="$(git branch --show-current)"
if [[ "$CURRENT" != "main" ]]; then
  echo "must be on main to start a new branch (currently on '$CURRENT')" >&2
  exit 1
fi

git fetch origin "$BASE"
git switch -C "$BRANCH" "origin/$BASE"

cat <<EOF
Created branch '$BRANCH' off origin/$BASE.

Next:
  1. make your changes
  2. commit:    git add -A && git commit -m "..."
  3. push:      git push -u origin $BRANCH
  4. open PR:   gh pr create --base $BASE --head $BRANCH --fill
EOF
