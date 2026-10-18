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
