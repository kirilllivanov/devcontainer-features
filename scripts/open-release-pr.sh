#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"
branch="automated-documentation-update-${GITHUB_RUN_ID}"
git switch --create "$branch"
git add src/*/README.md
if git diff --cached --quiet; then
    exit 0
fi
git commit -m "Update generated Feature documentation [skip ci]"
git push origin "$branch"
gh pr create \
    --title "Update generated Feature documentation" \
    --body "Automated documentation generated while publishing Dev Container Features."
