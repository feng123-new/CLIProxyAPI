#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
asset=${1:?Usage: bash deploy-panel.sh <management.html path>}
. "$root/bare/deployment.lock"
printf '%s  %s\n' "$MANAGEMENT_PANEL_SHA256" "$asset" | sha256sum --check --status

remote=$(cat <<'REMOTE'
set -euo pipefail
umask 077
[[ $(hostname) == instance-20260422-102632 ]]
root=/opt/cliproxy-official
target=$root/static/management.html
new=$(mktemp "$root/static/.management.XXXXXX")
trap "rm -f -- $new" EXIT
cat > "$new"
[[ $(sha256sum "$new" | cut -d " " -f 1) == "$1" ]]
old_hash=$(sha256sum "$target" | cut -d " " -f 1)
if [[ $old_hash == "$1" ]]; then
  printf "Panel already at %s\n" "$1"
  exit 0
fi
install -d -m 700 "$root/backups"
backup=$root/backups/management-before-$(date -u +%Y%m%dT%H%M%SZ).html
install -m 600 "$target" "$backup"
chmod 644 "$new"
mv -T -- "$new" "$target"
printf "Installed panel %s; rollback copy %s\n" "$1" "$backup"
REMOTE
)
gcp-vm-shell "sudo -n bash -c '$remote' _ '$MANAGEMENT_PANEL_SHA256'" < "$asset"
