#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
project_dir=$(mktemp -d)
trap 'rm -rf "$project_dir"' EXIT
cd "$project_dir"
git init --quiet
git remote add origin https://github.com/example/ci-smoke.git
bash "$repo_dir/setup.sh" --go ci-smoke example.com/ci-smoke > setup.log
# A second setup must preserve the generated project and its Go module.
bash "$repo_dir/setup.sh" --go ci-smoke example.com/ci-smoke > setup-second.log
# Generated projects inherit the pinned action without copying cache internals.
for helper in setup-go-cache trim-go-cache; do
  if [ -e ".github/actions/$helper" ]; then
    echo "Unexpected generated Go helper: $helper" >&2
    exit 1
  fi
done
for workflow in .github/workflows/ci.yml .github/workflows/release.yml; do
  if ! LC_ALL=C grep -Eq '^[[:space:]]+- uses: ashtonian/go-ci-actions@[0-9a-f]{40}([[:space:]]|$)' "$workflow"; then
    echo "Missing commit-pinned shared Go action in $workflow" >&2
    exit 1
  fi
  if grep -Eq 'uses: \./\.github/actions/(setup-go-cache|trim-go-cache)' "$workflow"; then
    echo "Stale local Go helper in $workflow" >&2
    exit 1
  fi
done
go build ./...
go vet ./...
go test -race -count=1 ./...
if command -v actionlint >/dev/null 2>&1; then
  actionlint .github/workflows/*.yml
fi
if command -v golangci-lint >/dev/null 2>&1; then
  golangci-lint config verify
  golangci-lint run
fi
if command -v goreleaser >/dev/null 2>&1; then
  goreleaser check
fi
