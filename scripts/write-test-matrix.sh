#!/bin/sh
set -eu

PROJECT_ROOT="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT must point to the GitHub Actions output file}"

images="$(sh "$PROJECT_ROOT/test/features/run.sh" --list-images-json)"
printf 'images=%s\n' "$images" >>"$GITHUB_OUTPUT"
