# Cloud Hosts
Located at `playbooks/cloud_hosts/`, this directory contains playbooks to create/destroy cloud hosts on DigitalOcean.


## Configuration
The configuration for the cloud hosts is stored in the [droplet.yaml](../../playbooks/cloud_hosts/vars/droplet.yaml) file.

## Usage
To create the cloud hosts as specified in the configuration file, run the following command:
```bash
ansible-playbook playbooks/cloud_hosts/create_host.yaml
```

This calls the create_droplet file for each droplet specified. It also creates any block storage volumes specified in the configuration file.

The second half of the [create_host.yaml](../../playbooks/cloud_hosts/create_host.yaml) runs against all DigitalOcean droplets to create the user if neeeded. Since root login is disabled afterwards, this skips the user creation if the host is unreachable via the root user. If the play is run 5 times within 10 minutes, fail2ban will ban the IP address (probably the local machine). You can unban the IP by logging in through the web console and running `fail2ban-client set sshd unbanip <ip>`.

## DigitalOcean Firewalls

Firewalls are tag-based and defined in [roles/digitalocean/vars/main.yml](../../roles/digitalocean/vars/main.yml) (`digitalocean_tags`, `digitalocean_firewall`). A droplet only receives a firewall's inbound rules if it carries the matching tag in its `tags:` list in [droplet.yaml](../../playbooks/cloud_hosts/vars/droplet.yaml). Apply changes with:

```bash
ansible-playbook playbooks/digitalocean.yaml --tags digitalocean.tags,digitalocean.firewall
```

Tagging/untagging a droplet (after editing `droplet.yaml`) is applied with:

```bash
ansible-playbook playbooks/cloud_hosts/create_host.yaml --tags digitalocean.droplet
```

## Plex Direct Connect Relay (temporary, CGNAT workaround)

**Why this exists:** the Proxmox server (and `docker-01`, which runs Plex) was temporarily relocated to a network behind Starlink, which uses CGNAT. CGNAT means the router no longer has a unique public IP, so the previous approach — forwarding port `32400` on the home router — no longer has any effect (see the [Plex section](./media.md#plex) for the normal, non-CGNAT setup).

**How it works:** `docker-01` was never enrolled in Tailscale directly. Instead, this relies on the existing home subnet router (`vpn.home.stechsolutions.ca`, host_vars at `inventories/home/host_vars/vpn.home.stechsolutions.ca.yaml`) which advertises `10.10.1.0/24,10.10.5.0/24` over Tailscale, and `docker-cloud-01` which already runs with `--accept-routes`. Since Tailscale tunnels are outbound-initiated, this keeps working through CGNAT without any inbound port-forward at the home network's edge.

`docker-cloud-01`'s Traefik instance terminates the public connection and forwards it over that existing Tailscale path. Everything is gated behind a single flag, `plex_relay_enabled`, set in `inventories/home/host_vars/docker-cloud-01/docker.yaml`:

- `files/traefik/traefik-prod.yaml.j2` — declares the `plex` entryPoint on `:32400` only `{% if plex_relay_enabled %}`. This file is shared with `docker-02`, which never sets the flag, so it never gets this entryPoint (`default(false)`).
- `files/traefik/dynamic/plex.yaml.j2` — TCP router/service (`HostSNI(\`*\`)` passthrough, no TLS) forwarding to `docker-01.home.stechsolutions.ca:32400`, also wrapped in the same `{% if plex_relay_enabled %}` guard.
- `inventories/home/host_vars/docker-cloud-01/docker_compose/proxy.yaml.j2` — publishes `32400:32400` on the Traefik container, same guard. This is the real kill switch: without the host port published, nothing listens on 32400 at all, regardless of the DO firewall or Traefik's internal router.
- `roles/digitalocean/vars/main.yml` / `playbooks/cloud_hosts/vars/droplet.yaml` — add the `Plex` tag and `StechSolutions-Plex` firewall (inbound TCP 32400 from anywhere), and tag `docker-cloud-01` with it permanently, the same way `HTTPS` and `SSH` are always-on. The firewall being open with nothing listening behind it is a no-op, so this doesn't need to track the flag.

### Toggling on/off

Flip `plex_relay_enabled` in `inventories/home/host_vars/docker-cloud-01/docker.yaml`, then apply it:

```bash
ansible-playbook playbooks/docker_compose.yaml --limit docker-cloud-01
```

Setting it to `false` and running this un-publishes port 32400 and removes the Traefik entrypoint/router content — equivalent to the manual revert steps below, without editing multiple files by hand.

**Plex-side manual config:** Settings → Network → Custom server access URLs → `http://<docker-cloud-01 public IP>:32400`. This is required because Plex can't auto-detect a port mapping that lives on a separate VPS.

**Verifying it's working:** from a machine that is *not* using a Tailscale exit node (otherwise the request may loop through the tailnet instead of testing the real public path):

```bash
curl http://<docker-cloud-01 public IP>:32400/identity
```

A `200` response with an XML `MediaContainer` body containing your Plex server's `machineIdentifier` confirms the DO firewall, Traefik TCP router, and the Tailscale hop back to `docker-01` are all working. On a remote client, check the connection details show "Direct" rather than "Relayed".

**Known issue — Plex treats relayed streams as local:** the subnet router (`vpn`, `10.10.5.28`) SNATs forwarded tailnet traffic to its own LAN IP, which is on the same subnet as `docker-01`. Plex therefore sees every relayed stream as coming from `10.10.5.28`, classifies it as a LAN client, and skips the remote bitrate limits. Clients then request original quality, saturate the home upload, and buffer/drop quality — it looks a lot like Plex Relay. This was observed during the Aug–Oct 2026 relay period. Traefik can't fix this (the rewrite happens at `vpn`), and the real viewer IP can't be preserved either (Traefik's TCP passthrough opens a new connection and Plex doesn't support PROXY protocol). Options if the relay is needed again:

- **Recommended:** enroll `docker-01` in Tailscale directly (`tailscale_setup: true`, `tag:server`, without `--accept-routes`) and point `files/traefik/dynamic/plex.yaml.j2` at `docker-01`'s Tailscale name. Plex then sees `docker-cloud-01`'s `100.x` IP and treats the streams as remote. The existing `tag:server` → `tag:server` grant already allows it. Also set Plex → Settings → Network → LAN Networks explicitly to `10.10.1.0/24,10.10.5.0/24`, then confirm relayed streams show as remote in the Plex dashboard.
- Disable SNAT on `vpn` (`--snat-subnet-routes=false`) and add a return route for `100.64.0.0/10` via `10.10.5.28` on the home router. Affects all tailnet access to the home network.
- An iptables SNAT exemption on `vpn` for just this traffic, plus a host route on `docker-01`. Fragile — Tailscale rewrites its own iptables chains on restart.

**Reverting once the server moves back home:**

1. Set `plex_relay_enabled: false` in `inventories/home/host_vars/docker-cloud-01/docker.yaml` and run the command from [Toggling on/off](#toggling-onoff) above. This un-publishes port 32400 and removes the Traefik entrypoint/router — no need to delete the firewall or tag definitions.
2. In Plex, clear Settings → Network → Custom server access URLs.
3. Re-enable the port forward (`32400` -> `docker-01`) on the home router, now that it has a routable public IP again.