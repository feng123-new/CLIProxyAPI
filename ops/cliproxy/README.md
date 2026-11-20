# CLIProxyAPI operations

The `services` VPS runs CLIProxyAPI at `127.0.0.1:8317` from
`/opt/cliproxy-official`. Cloudflare Tunnel `daily-vm-apps` publishes the API
at `https://cliproxy.520958.xyz/v1` and the admin panel at
`https://cliproxy.520958.xyz/management.html`. The panel uses the management
key and the client API uses its separate API key.

## Antigravity verification

If Google returns `VALIDATION_REQUIRED` with a supported verification link,
the Antigravity quota card offers **Open Google verification**. Open the
link with the matching Google account, complete Google's prompts, then
refresh that account's quota. The next successful refresh clears the action.

## Source and build

The [maintenance source](https://github.com/feng123-new/CLIProxyAPI/tree/main/ops/cliproxy)
contains `panel.patch` against the upstream Management Center revision in
`bare/deployment.lock`. The lock also identifies the running core image and
the expected checksum of the built panel. Build the single HTML file on WSL
with Bun, Git and curl installed.

```bash
bash build-panel.sh /tmp/management.html
bash deploy-panel.sh /tmp/management.html
```

The deployment script verifies the artifact and swaps the panel file inside
the existing read-only directory mount. It saves the previous HTML under
`/opt/cliproxy-official/backups/` and returns its path. Roll back by installing
that backup as `static/management.html` with mode `0644` from the VPS, then
load the panel again with a fresh browser tab.

For a new bare deployment, copy `bare/` and the verified HTML to the services
VM and run `sudo bash bare/install.sh /path/to/management.html`. For a running
deployment, `bare/compose.yaml` is the reference Compose definition. The
existing configuration, authorization files and plugins are on the VPS in
`config/`, `auths/` and `plugins/` respectively. Keep these runtime directories,
credentials and logs out of the public repository. Use `op-secrets edit` to
store any local credentials in the WSL secret store.

After deployment, open the panel, exercise both single and bulk quota refresh,
and check `https://cliproxy.520958.xyz/healthz`. A working quota response and
unrelated errors must display without the Google verification action.
