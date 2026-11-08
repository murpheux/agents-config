---
name: homelab
description: "Home network 10.10.2.0/24 changes — static IPs, Pi-hole DNS, SSH to nodes, adding hosts/services, home-lab security checks"
---

# Home lab runbook

Topology, hosts, services and endpoints are in AGENTS.md §5–§8. This skill adds the procedures.

## Adding a host / static IP
1. Pick the next free address in the `10.10.2.200+` DHCP-exclusion range — verify it's unused: `ping -c 2 <ip>`, `dig -x <ip> @10.10.2.9`, and the router DHCP table (`http://10.10.2.1/login.htm`).
2. Reserve it on `router1` (DHCP reservation) rather than only configuring it on the host.
3. Add A + CNAME records on **both** Pi-holes (`https://dns/admin`, `https://dns2/admin`) — Local DNS → DNS Records / CNAME Records. Keep them identical.
4. Verify: `dig @10.10.2.9 <name>` and `dig @10.10.2.7 <name>`.
5. If it runs Docker: create context `docker context create <host>-daemon --docker host=ssh://_ai_daemon@<host>` and add it to `~/.ssh/config`.

## SSH
- User `_ai_daemon`; keys via `~/.ssh/config` / `ssh-add -l`. Key-only auth, no root login, no password auth.
- Prefer Docker contexts over raw SSH for container work.

## Security checks to flag proactively
- Services bound to `0.0.0.0` without auth (MinIO console, Prometheus, cAdvisor, Kibana are plain HTTP on the LAN).
- Default credentials on router/switch/printers; UPnP enabled on `router1`; exposed admin UIs port-forwarded to WAN.
- TLS: gateway on `https://scarlet:4000` uses a private cert — trust it with `NODE_EXTRA_CA_CERTS`, never by disabling verification.
- Both DNS servers must stay in sync; a single Pi-hole failure should not break resolution.

## Package managers
`medusa` brew · `scarlet` pacman (+ yay for AUR) · `gru` apt · `cass` pamac/pacman (+ yay). Prefer containers over host installs.
