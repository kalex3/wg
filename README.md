# wg

Small Alpine-based WireGuard container that other containers can share a network namespace with, so their traffic is forced through the tunnel.

## Usage

```sh
cp wg0.conf.example wg0.conf   # fill in keys, peers, endpoints
chmod 600 wg0.conf
docker compose up -d --build
```

`compose.yml` starts `wg` plus an example `client` (plain Alpine) with `network_mode: service:wg`. Replace `client` with your own service and publish ports on `wg`, not on the client.

- The host needs the `wireguard` kernel module (included by default on all major distros)
- Traffic is only forced through the tunnel for destinations covered by the peers' `AllowedIPs`. Use `AllowedIPs = 0.0.0.0/0` (and optionally the kill switch in `wg0.conf.example`) to force everything.
- With rootful Docker and `cap_drop: ALL`, the container's root cannot read a
  `600` config owned by another uid. Use `sudo chown root:root wg0.conf`.
- Shell as the unprivileged user: `docker compose exec -u user -w /home/user wg sh`.

## Example: Cloudflare WARP with wgcf

[wgcf](https://github.com/ViRb3/wgcf) generates a WireGuard profile for a free Cloudflare WARP account. With `wgcf` installed on the host:

```sh
wgcf register --accept-tos            # creates wgcf-account.toml (keep it private)
wgcf generate -p wg0.conf             # writes the WireGuard profile
sed -i '/^Endpoint/a PersistentKeepalive = 25' wg0.conf   # keeps the handshake fresh for the healthcheck
chmod 600 wg0.conf
docker compose up -d --build

# the client container now exits through WARP:
docker compose exec client wget -qO- https://www.cloudflare.com/cdn-cgi/trace   # warp=on
```

The profile is a full tunnel (`0.0.0.0/0, ::/0`) with `DNS =` set, so all traffic and DNS of containers using `network_mode: service:wg` goes through WARP. `scripts/wgcf-test.sh` automates this check (pass an existing profile as the first argument to avoid registering a new device).

## Environment variables

| Name                    | Default | Purpose                                                         |
| ----------------------- | ------- | --------------------------------------------------------------- |
| `WG_INTERFACE`          | `wg0`   | Config/interface name (`/etc/wireguard/<name>.conf`)            |
| `WG_RERESOLVE_INTERVAL` | `30`    | Seconds between endpoint re-resolution for stale peers, 0 = off |
| `WG_HANDSHAKE_MAX_AGE`  | `180`   | Max handshake age (s) for the healthcheck                       |
