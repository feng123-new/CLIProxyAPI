#!/usr/bin/env bash
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
panel=${1:?Usage: bash install.sh <management.html path>}
target=/opt/cliproxy-official

if [[ $EUID != 0 || $(hostname) != instance-20260422-102632 ]]; then
  printf 'Run this installer as root on the services VM.\n' >&2
  exit 1
fi
if [[ -e "$target" || -L "$target" || -n $(ss -ltnH 'sport = :8317') ]]; then
  printf 'The deployment directory or TCP port 8317 is already in use.\n' >&2
  exit 1
fi

. "$source_dir/deployment.lock"
umask 077
printf '%s  %s\n' "$MANAGEMENT_PANEL_SHA256" "$panel" | sha256sum --check --status
docker pull "$CLI_PROXY_IMAGE"

install -d -m 700 "$target" "$target/config" "$target/auths" "$target/static" "$target/secrets" "$target/plugins"
install -m 600 "$source_dir/compose.yaml" "$source_dir/deployment.lock" -t "$target"
install -m 644 "$panel" "$target/static/management.html"

management_key=$(openssl rand -hex 32)
client_api_key=$(openssl rand -hex 32)
cat > "$target/config/config.yaml" <<EOF
config-version: 8
server:
  host: "127.0.0.1"
  port: 8317
management:
  allow-remote: false
  secret-key: "$management_key"
  disable-control-panel: false
  disable-auto-update-panel: true
oauth:
  auth-dir: "/root/.cli-proxy-api"
  providers:
    aistudio:
      ws-auth: true
access:
  api-keys:
    - "$client_api_key"
plugins:
  enabled: false
EOF
printf 'MANAGEMENT_KEY=%s\nCLIENT_API_KEY=%s\n' "$management_key" "$client_api_key" > "$target/secrets/initial-credentials.txt"

cd -- "$target"
docker compose --env-file deployment.lock config --quiet
docker compose --env-file deployment.lock up -d
