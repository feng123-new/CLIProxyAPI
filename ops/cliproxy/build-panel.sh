#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
output=$(realpath -m -- "${1:?Usage: bash build-panel.sh <management.html output path>}")
. "$root/bare/deployment.lock"

if [[ $(bun --version) != "$PANEL_BUN_VERSION" ]]; then
  printf 'Install Bun %s to build the pinned management panel.\n' "$PANEL_BUN_VERSION" >&2
  exit 1
fi

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
curl -fsSL --retry 2 --max-time 120 \
  "https://codeload.github.com/router-for-me/Cli-Proxy-API-Management-Center/tar.gz/$PANEL_UPSTREAM_COMMIT" \
  | tar -xz --strip-components=1 -C "$work"

(
  cd -- "$work"
  git apply "$root/panel.patch"
  bun install --frozen-lockfile
  VERSION="$MANAGEMENT_PANEL_VERSION" bun run build
)

printf '%s  %s\n' "$MANAGEMENT_PANEL_SHA256" "$work/dist/index.html" | sha256sum --check --status
install -m 644 "$work/dist/index.html" "$output"
sha256sum "$output"
