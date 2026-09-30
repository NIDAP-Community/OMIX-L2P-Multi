#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  cat >&2 <<'USAGE'
Usage: scripts/run-local-codeocean-workflow-debug.sh <image> [additional main.R arguments]

Mounts data/debug/codeocean-workflow as /data, matching a downstream Code
Ocean workflow connection. Defaults reproduce the L2P Multi App Panel values.
USAGE
  exit 2
fi

image="$1"
shift

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_root="$repo_root/data/debug/codeocean-workflow"
results_root="$repo_root/results/debug-codeocean-workflow"

if [[ ! -d "$fixture_root" ]]; then
  echo "Missing fixture directory: $fixture_root" >&2
  echo "See docs/local-codeocean-io-testing.md to create it." >&2
  exit 2
fi

mkdir -p "$results_root"

docker run --rm \
  -v "$repo_root/code:/code:ro" \
  -v "$fixture_root:/data:ro" \
  -v "$results_root:/results" \
  --entrypoint bash \
  "$image" \
  /code/run \
  --comparisons "B-A,C-A,B-C" \
  --species "Mouse" \
  "$@"
