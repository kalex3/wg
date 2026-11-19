# wg

Small WireGuard container, built from Alpine with no package manager, that other containers can share a network namespace with, so their traffic is forced through the tunnel.

## Usage

```sh
cp wg0.conf.example wg0.conf   # fill in keys, peers, endpoints
chmod 600 wg0.conf             # entrypoint settings live in wg.env
docker compose up -d --build
```

`compose.yml` starts `wg` plus an example `client` (plain Alpine) with `network_mode: service:wg`. Replace `client` with your own service and publish ports on `wg`, not on the client.

- The host needs the `wireguard` kernel module (included by default on all major distros)
- Traffic is only forced through the tunnel for destinations covered by the peers' `AllowedIPs`. Use `AllowedIPs = 0.0.0.0/0` to force everything, and `WG_KILLSWITCH=true` to reject traffic that would otherwise bypass that tunnel.
- With a full tunnel, replies to connections that arrive on a non-tunnel interface (published ports, neighbor containers) are sent back out the same way instead of into the tunnel. New outgoing connections still use the tunnel. The kill switch allows those replies and rejects everything else that is not going out the tunnel.
- The healthcheck passes when the interface is up. For a full tunnel it also requires the firewall rules, including the kill switch when `WG_KILLSWITCH` is set. It does not wait for a handshake, so a service that depends on `wg` being healthy is not blocked on a peer.
- With rootful Docker and `cap_drop: ALL`, the container's root cannot read a
  `600` config owned by another uid. Use `sudo chown root:root wg0.conf`.
- Shell as an unprivileged user: `docker compose exec -u nobody wg sh`.

## Example: Cloudflare WARP with wgcf

[wgcf](https://github.com/ViRb3/wgcf) generates a WireGuard profile for a free Cloudflare WARP account. With `wgcf` installed on the host:

```sh
wgcf register --accept-tos            # creates wgcf-account.toml (keep it private)
wgcf generate -p wg0.conf             # writes the WireGuard profile
sed -i '/^Endpoint/a PersistentKeepalive = 25' wg0.conf   # keeps an idle tunnel from expiring its NAT mapping
chmod 600 wg0.conf
docker compose up -d --build

# the client container now exits through WARP:
docker compose exec client wget -qO- https://www.cloudflare.com/cdn-cgi/trace   # warp=on
```

The profile is a full tunnel (`0.0.0.0/0, ::/0`) with `DNS =` set, so all traffic and DNS of containers using `network_mode: service:wg` goes through WARP.
## Environment variables

| Name                    | Default | Purpose                                                         |
| ----------------------- | ------- | --------------------------------------------------------------- |
| `WG_INTERFACE`          | `wg0`   | Config/interface name (`/etc/<name>.conf`)                      |
| `WG_RERESOLVE_INTERVAL` | `30`    | Seconds between endpoint re-resolution for stale peers, 0 = off |
| `WG_KILLSWITCH`         | `false` | Reject traffic that would bypass a full tunnel                  |
