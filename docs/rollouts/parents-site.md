# Parents-site rollout — three plans

> Living document tracking the rollout of `client_parents`: a new
> Ansible inventory plus on-site work at the parents' location.
> Update in place as the rollout progresses; remove sections as they
> ship and graduate to the regular per-inventory docs.

The work splits cleanly along three boundaries:

- **Plan A — Barn renter VLAN** is a manual UDM Pro Max change. No Ansible.
  Independent of everything else; can run any time.
- **Plan B — `client_parents` inventory + new Proxmox nodes.** Repo
  scaffolding plus standing up pve1 and pve2 as empty managed hosts.
  Required before Plan C.
- **Plan C — Migrate existing VMs, deploy Frigate, repurpose old node as
  PBS.** Depends on Plan B.

Shared facts that apply to Plans B and C:

- Site LAN is `10.200.2.0/24`. `10.50.50.3` is `vpn.arnie-karen`'s
  Tailscale address (not a LAN address).
- New Proxmox nodes / VMs sit on the LAN; Ansible reaches them via
  Tailscale subnet routing through the existing `vpn.arnie-karen` exit
  node — no Tailscale role on the new hosts.
- `vpn.arnie-karen` keeps `ansible_host: 10.50.50.3` (the tailnet
  address).
- Modeled on `inventories/client_welca` (internal naming, no ACME,
  `local-lvm` import storage, daily backups, ntfy notifications).
- Hostnames are placeholders; user will finalize before execution.
- UPS is an EcoFlow → no NUT support → `proxmox_nut_configure: false`
  across the inventory.
- Frigate hwaccel: Intel iGPU on pve2 → `preset-vaapi` + `/dev/dri`
  passthrough.

## Pre-work checklist (everything doable before traveling on-site)

Almost the entire rollout is doable remotely. The on-site list at the
end is short and bounded.

### Off-site — Plan A (UDM controller is reachable via Tailscale once
the subnet route is approved)
- Create VLAN 30 / `10.200.30.0/24` network in the controller.
- Create the firewall / traffic rules.
- Create the `barn-renter` SSID, tag to VLAN 30, assign to AP group.
- Pre-configure port profiles: trunk profile for the UDM port toward
  the barn run, trunk for the barn-switch uplink, access (VLAN 30) for
  tenant ports. Apply them when the physical link is in place.

### Off-site — Plan B (entire repo change set + the dry-run pass)
- Create `inventories/client_parents/` and all files in it
  (`inventory.yaml`, `group_vars/all/main.yaml`, `vault.yaml(.example)`,
  `proxmox_nodes.yaml`, `proxmox_vms.yaml`, host_vars for pve1/pve2 and
  vpn.arnie-karen, `proxmox_vms/hosts.yaml` skeleton).
- Generate the encrypted vault and the gitignored
  `vault_pass_client_parents.txt`.
- Add the `client_parents)` case to `scripts/select-inventory.sh`.
- Add the inventory entry to `docs/INVENTORIES.md`.
- Remove `vpn.arnie-karen` from `inventories/home/inventory.yaml` and
  delete `inventories/home/host_vars/vpn.arnie-karen.yaml`.
- Decide on / remove `secret_become_pass_arnie` from `home`'s vault
  (after the grep check).
- Run `ansible-inventory --list`, `--syntax-check`, and `--check`
  against the new inventory.
- Confirm `ansible -m ping vpn.arnie-karen` works against the new
  inventory while the VM is still on the old node — the host_vars +
  vault migration should be completely transparent.
- Approve the `10.200.2.0/24` subnet route in the Tailscale admin
  console (this enables remote access to the new nodes once they're
  up).

### Off-site — Plan C scaffolding (provided you can collect the camera
RTSP credentials remotely from the parents)
- Create `host_vars/<frigate>.yaml` with the 3 existing cameras
  pre-populated.
- Add `secret_camera_<name>_rtsp` for the 3 existing cameras to the
  vault.
- Scaffold `files/frigate/config.yml.j2` and the Frigate compose
  service via the `new-docker-service` skill.
- Pre-fill `host_vars/<pbs>.yaml` with placeholder IP and
  pre-write the `proxmox_storage` blocks for `<pve1>.yaml` /
  `<pve2>.yaml` as commented-out blocks ready to uncomment.

### Off-site — execution that's also remote (after on-site Phase 1)
- All Ansible playbook runs against pve1, pve2, vpn.arnie-karen,
  Frigate VM, PBS — over Tailscale.
- VM migrations: `vzdump` on old node + `scp` + `qm restore` on pve1
  are all SSH operations.
- Frigate compose deploy: SSH/Ansible.
- 4 new cameras (Plan C.2b): adding each one to vault + host_vars +
  reloading is remote — only the camera **install itself** is on-site.

### On-site — the bounded list
- Rack pve1, pve2, network them.
- Install Proxmox 9 on pve1 and pve2 (unless the hardware has
  IPMI/iDRAC for remote install). At install time, **decide on
  `local-lvm` vs `local-zfs`** — match what the inventory's
  `proxmox_import_storage` is set to.
- pve2 BIOS: enable VT-d / VT-x. After Proxmox is up, the rest of the
  iGPU passthrough work (`intel_iommu=on iommu=pt` in GRUB, blacklist
  `i915`, bind `vfio-pci`) is SSH-able and can finish remotely.
- Initial `/etc/network/interfaces` and root SSH so the node is
  reachable via Tailscale subnet routing — once that's done, you can
  leave.
- If recordings strategy is Option A (passthrough): physically
  install the recording drives in pve2.
- (Pre-on-site, but easy to forget) confirm `vpn.arnie-karen` is
  advertising `10.200.2.0/24` over Tailscale and the route is
  approved — without this, the post-on-site Ansible runs can't reach
  the new nodes.
- Run the barn cable; place the Unifi switch at the barn; light up
  the trunk.
- Install the 4 new cameras (when they arrive / on a later visit).
- Wipe-and-reinstall the old node as PBS (unless it has remote
  console access, in which case this can also be remote).

---

# Plan A — Barn renter VLAN on UDM Pro Max

## Context

A renter at the barn needs network access. Their devices must be
isolated from the household LAN (cameras, Proxmox, HA, Frigate, family
wifi) — internet egress only. The barn is uplinked from the UDM Pro Max
to a Unifi switch at the barn; existing APs at the main building will
broadcast a new SSID covering the barn.

The repo has no Unifi/UDM automation (only a Traefik reverse-proxy
entry exposing the controller's web UI), so this is configured by hand
in the UDM controller. Capturing it here so it's tracked alongside the
rest of the parents' rollout.

## Network design (placeholders — adjust if collisions exist)

- VLAN ID: `30`, name `barn-renter`
- Subnet: `10.200.30.0/24`, gateway `10.200.30.1` (UDM)
- DHCP: `10.200.30.100–10.200.30.250`
- Upstream DNS: a public resolver (e.g. `1.1.1.1`, `9.9.9.9`). Do
  **not** point barn DHCP clients at the household Pi-hole or any
  internal resolver — that would re-introduce a path to internal
  networks.

## Physical / L2 layout

Run from main building feeds a Unifi switch at the barn:
- UDM port toward the barn run: trunk. VLAN 30 tagged. Native untagged
  off (manage the barn switch on its own management VLAN, not the main
  LAN).
- Barn switch uplink: trunk, mirrors the UDM side.
- Barn switch tenant ports: access (untagged) on VLAN 30.
- Wifi: new SSID `barn-renter` broadcast from existing main-building
  APs, tagged to VLAN 30. WPA2/WPA3 with a password delivered to the
  renter separately.

## Firewall / traffic rules

1. `BARN → MAIN LAN (10.200.2.0/24)`: drop.
2. `BARN → other internal VLANs / RFC1918`: drop.
3. `BARN → UDM gateway`: drop except DHCP/DNS to the gateway IP itself.
4. `BARN → Internet`: allow.
5. `MAIN LAN → BARN`: allow established/related only (so internal
   troubleshooting can be initiated from the main LAN, but the renter
   can't initiate inbound).

## Execution

All in the UDM Pro Max controller:
1. Create the VLAN/network with the values above.
2. Create the firewall/traffic rules.
3. Create the SSID, tag to VLAN 30, assign to the relevant AP group.
4. Configure the UDM port to the barn run as trunk; configure the barn
   switch uplink + tenant ports.

## Verification

- Laptop on `barn-renter` SSID gets a `10.200.30.x` lease.
- `ping 10.200.2.1` (UDM main-LAN) and `ping` of a Proxmox node both
  fail.
- `curl ifconfig.me` succeeds.
- From a main-LAN host, `ping`/SSH to a barn host succeeds (return
  path works for troubleshooting).

## Not in scope

- No UDM config files land in this repo. If a controller backup is
  worth archiving, store it in Bitwarden or a separate ops vault.

## Open items

- Confirm VLAN 30 isn't already used.
- Confirm the barn-switch uplink media (fibre/copper) and whether it's
  already run.

---

# Plan B — Bootstrap `client_parents` inventory + new Proxmox nodes

## Context

We're adding a new client inventory, `client_parents`, to manage two
greenfield Proxmox nodes at the parents' site. This plan stops at "two
empty managed Proxmox hosts" and "vpn.arnie-karen now managed from
`client_parents` instead of `home`." The old node and its VMs are
untouched; the migration of those VMs is Plan C.

`vpn.arnie-karen` is migrated **at the inventory level** (not the VM
level) here — its host_vars and become password move from `home` to
`client_parents` so the rest of the rollout works from the new
inventory. The actual VM moves to pve1 in Plan C.

## Files to create — all under `inventories/client_parents/`

### `inventory.yaml`
Mirror `inventories/client_welca/inventory.yaml`.
- `proxmox_nodes`: `pve1`, `pve2`
- `proxmox_pbs`: empty (added in Plan C)
- `proxmox_vms`: `ha`, `vpn.arnie-karen`, `frigate` (loaded from
  `proxmox_vms/hosts.yaml`). `ha` and `frigate` come into existence in
  Plan C; declaring them here is fine — they just won't resolve until
  hosts exist.
- `proxmox_containers`: empty.

### `group_vars/all/main.yaml`
Copy from `inventories/client_welca/group_vars/all/main.yaml` and
adjust:
- `default_user: "arnie"` (canonical user across the client; matches
  the existing `arnie` user on `vpn.arnie-karen`)
- `default_user_email`: `nstoik@stechsolutions.ca`
- Two-user pattern: `arnie` primary + `nelson` with dotfiles + SSH keys
- `timezone`: `America/Edmonton`
- security: `allowed_users: [arnie, nelson]`, passworded sudo for
  `arnie`

### `group_vars/all/vault.yaml` + `vault.yaml.example`
- Copy `inventories/client_welca/group_vars/all/vault.yaml.example`.
  The welca example contains exactly: `secret_user_password`,
  `secret_user_password_prehashed`, `secret_become_pass`,
  `secret_nelson_password`, `secret_nelson_password_prehashed`,
  `secret_ssh_keys` (with `welca:` and `nelson:` sub-keys),
  `secret_ntfy_tokens.Proxmox`. The only welca-specific element is
  the `welca:` sub-key under `secret_ssh_keys` — rename to `arnie:`.
- Encrypt the real `vault.yaml`:
  `ansible-vault encrypt … --vault-id client_parents@./vault_pass_client_parents.txt --encrypt-vault-id client_parents`
- Required secrets (Plan B only — camera secrets are added in Plan C):
  - `secret_user_password` and `secret_user_password_prehashed` for
    `arnie`. Migrated from `home`'s vault: `secret_become_pass_arnie`
    becomes `secret_become_pass` here. If `home` doesn't have a
    prehashed value, generate one with `mkpasswd -m sha-512`.
  - `secret_become_pass` (same value as above; the role consumes this
    name).
  - `secret_nelson_password`, `secret_nelson_password_prehashed`,
    `secret_ssh_keys` (welca pattern; with `arnie:` and `nelson:`
    sub-keys).
  - `secret_ntfy_tokens.Proxmox` (fresh ntfy token for this site).

### `group_vars/proxmox_nodes.yaml`
Copy from welca. Keep:
- `proxmox_import_storage: local-lvm`
- `proxmox_acme_setup: false`,
  `proxmox_backup_healthchecks_setup: false`,
  `scrutiny_collector_install: false`
- Cloud image template (Ubuntu 24.04, id 9001, recreate)
- ntfy targets/matchers → `https://ntfy.stechsolutions.ca/Proxmox`
  (covers backup-failure notifications via the matchers welca already
  defines — no extra setup)
- `proxmox_backups`: daily 04:30 to `local` with `id: backup-daily`
  (will be **replaced** with a PBS-targeted entry under a different
  id in Plan C — see C.3 for why a simple storage flip won't work)
- `proxmox_users`: primary user `arnie@pam` in Admins. **No
  `prometheus@pve`** — that's a home-only thing. Welca doesn't have it
  (`inventories/client_welca/group_vars/proxmox_nodes.yaml:79-84`).
  If we ever scrape these PVE hosts from a Prometheus elsewhere, add
  it then with `secret_pve_prometheus_user_password`.

### `group_vars/proxmox_vms.yaml`
Copy from welca (qemu-guest-agent package + service, vault become
password).

### `host_vars/<pve1>.yaml` and `host_vars/<pve2>.yaml`
Modeled on `inventories/client_welca/host_vars/pve.internal.welca.ca.yaml`:
- `ansible_host: 10.200.2.5` (pve1) and `10.200.2.6` (pve2)
  placeholders. Reached via Tailscale subnet route through
  `vpn.arnie-karen`.
- `proxmox_nut_configure: false` (EcoFlow UPS, no NUT support).
- `proxmox_storage`: empty in Plan B; populated in Plan C once PBS is
  up. The **shape** to mirror is home's
  `inventories/home/host_vars/pve3.home.stechsolutions.ca.yaml:9-18` —
  a single shared namespace `proxmox-vms` referenced by every PVE
  node in the cluster (not per-host).
- Custom package list (omit `neofetch` per the existing welca comment).
- pve2 needs the Intel iGPU prepped for VM passthrough at the host
  level (covered in manual prereqs below).

### `host_vars/vpn.arnie-karen.yaml`
Move `inventories/home/host_vars/vpn.arnie-karen.yaml` to
`inventories/client_parents/host_vars/vpn.arnie-karen.yaml` and
simplify to:
```yaml
ansible_host: 10.50.50.3
```
`ansible_user: arnie` and `ansible_become_password` come from
`group_vars/all/main.yaml` now that `default_user` is `arnie` and the
become password is `secret_become_pass`.

**Tailscale on this VM stays manual.** Verified: home's existing
host_vars sets no `tailscale_setup` flag, and the role in
`playbooks/hosts_configure.yaml:82-89` is gated on that flag — so the
exit/subnet-router config has always been hand-rolled. Migrating the
VM whole (Plan C.1) preserves Tailscale state, so manual remains the
simplest path. **Trade-off**: no IaC reproducibility for the
subnet-router config. If we later want it Ansible-managed, mirror
`inventories/home/host_vars/vpn.home.stechsolutions.ca.yaml:7-16`
(`tailscale_setup: true`, `tailscale_subnet_router: true`,
`tailscale_args` advertising `10.200.2.0/24`) AND add
`secret_ts_client_secret` to the vault. Out of scope for this
rollout.

### `proxmox_vms/hosts.yaml` (skeleton in Plan B)
Mirror `inventories/client_welca/proxmox_vms/hosts.yaml`. Plan B does
not run `proxmox_vms_add.yaml`; the file is just declarative.

**Idempotency verified** (`roles/proxmox/tasks/create_vm.yaml:10-13,22-23`):
the clone-from-template block short-circuits if the VM config file
`/etc/pve/qemu-server/<vmid>.conf` already exists. So listing a
migrated VM is safe — the create step no-ops.

**However**, `start_vm.yaml:78` runs `cloud-init status --wait` over
SSH on every listed VM regardless. This breaks on HAOS (no SSH).
**Conclusion:**
- Include `vpn.arnie-karen` in `proxmox_vms/hosts.yaml` (Linux VM,
  has SSH — safe).
- **Do NOT include `ha` if it's HAOS** (assume HAOS — see Plan C.1
  rationale). Declare `ha` only as a top-level `all.hosts` entry in
  `inventory.yaml` for tracking; do not put it in the `proxmox_vms`
  group.
- `frigate` is greenfield — full `proxmox_vm` block, runs through
  the playbook normally.

## Files to modify — outside the new inventory

### `scripts/select-inventory.sh`
Add a `client_parents)` case alongside `home)` and `client_welca)`,
matching the existing format including the echo line:
```bash
client_parents)
  export ANSIBLE_INVENTORY="./inventories/client_parents"
  export ANSIBLE_VAULT_IDENTITY_LIST="client_parents@./vault_pass_client_parents.txt"
  echo "Selected inventory: client_parents"
  ;;
```

### `vault_pass_client_parents.txt`
New gitignored file at repo root containing the vault password. The
existing `vault_pass*.txt` rule already covers it.

### `docs/INVENTORIES.md`
Add a one-line entry pointing to the new inventory.

### `inventories/home/inventory.yaml`
Remove the two `vpn.arnie-karen` references:
- Top-level host entry under `all.hosts` (line ~11)
- Entry under `nodes_remote.hosts` (line ~39)

### `inventories/home/host_vars/vpn.arnie-karen.yaml`
Delete.

### `inventories/home/group_vars/all/vault.yaml`
`ansible-vault edit` and remove `secret_become_pass_arnie`. Verified:
the only references in `home` are
`inventories/home/host_vars/vpn.arnie-karen.yaml:6` (deleted in this
plan) and `inventories/home/group_vars/all/vault.yaml.example:25`
(also remove from the example). Unconditional removal — no grep gate
needed.

## Manual prerequisites (before Ansible)

1. **BLOCKER — Tailscale subnet route.** Confirm `vpn.arnie-karen`
   advertises `10.200.2.0/24` over Tailscale and the route is
   approved in the admin console. Repo has no record of this being
   set up (only `vpn.home.stechsolutions.ca` advertises home subnets
   per `host_vars/vpn.home.stechsolutions.ca.yaml:14`). If not
   already in place: SSH to the VM and run
   `sudo tailscale up --advertise-routes=10.200.2.0/24 --advertise-exit-node=false …`
   (preserving any other existing flags), then approve in
   <https://login.tailscale.com/admin/machines>. **Without this, the
   homelab can't reach `10.200.2.x` to manage the new nodes.**
2. Install Proxmox 9 on both physical nodes (ZFS mirror root
   preferred). After install, confirm `local-lvm` actually exists —
   if the operator chose a ZFS-only layout, default storage is
   `local-zfs` and `proxmox_import_storage: local-lvm` will fail to
   import templates (consumed by `roles/proxmox/tasks/create_template.yaml:99,109`).
   Either keep `local-lvm` available at install time, or change the
   inventory to `proxmox_import_storage: local-zfs`.
3. Configure `/etc/network/interfaces` with `vmbr0` on
   `10.200.2.0/24`. Reference:
   `playbooks/proxmox/files/proxmox_interfaces.example`.
4. Prep pve2 for Intel iGPU passthrough: BIOS VT-d on,
   `intel_iommu=on iommu=pt` in GRUB, blacklist `i915` on the host,
   bind the iGPU to `vfio-pci` (use its PCI ID from `lspci -nn`),
   reboot. Confirm with `lspci -nnk` showing
   `Kernel driver in use: vfio-pci`. (`docs/services/proxmox.md:23-30`
   covers IOMMU/VFIO module loading but not blacklisting `i915` or
   binding by PCI ID — those are extra steps beyond what the doc
   describes.)
5. Confirm SSH-as-root works on both nodes.

## Execution

Two sub-phases. The pre-on-site phase only touches `vpn.arnie-karen`
(already up). The on-site phase touches pve1/pve2 once they're racked
and reachable.

**Pre-on-site (entirely remote — once Tailscale subnet routing is
confirmed):**
```bash
source setenv.sh
source scripts/select-inventory.sh client_parents
ansible-galaxy install -r requirements.yaml
ansible-inventory --list                                       # parse check
ansible-playbook playbooks/hosts_configure.yaml --syntax-check
ansible -m ping vpn.arnie-karen                                # confirms migrated host_vars works
ansible-playbook playbooks/hosts_configure.yaml --limit=vpn.arnie-karen --check
```

**Post-on-site (after pve1/pve2 are installed and reachable):**
```bash
ansible-playbook playbooks/hosts_configure.yaml --limit=proxmox_nodes --check
ansible-playbook playbooks/proxmox/pve_hosts.yaml
ansible-playbook playbooks/proxmox/pve_hosts_templates.yaml
```

Then re-run home's playbook to confirm no regressions:
```bash
source scripts/select-inventory.sh home
ansible-playbook playbooks/hosts_configure.yaml --check
```

## Verification

- pve1 and pve2 are reachable, configured, and idempotent on re-run.
- `ansible -m ping vpn.arnie-karen` from `client_parents` succeeds.
- `home` inventory parses cleanly with no `vpn.arnie-karen` references.
- pve2's iGPU shows `vfio-pci` driver bound at the host.

## Outcome

Two empty managed Proxmox hosts ready to receive VMs. `vpn.arnie-karen`
managed from `client_parents`. Old node still running HA + the live
`vpn.arnie-karen` VM unchanged.

## Open items

- Final hostnames for `pve1`, `pve2`.
- Real LAN addresses (placeholders are `.5`, `.6` on `10.200.2.0/24`)
  — confirm no DHCP-static collisions.
- Confirm install-time storage layout (`local-lvm` vs `local-zfs`)
  before setting `proxmox_import_storage`.

---

# Plan C — Migrate VMs, deploy Frigate, repurpose old node as PBS

## Context

With pve1 and pve2 stood up (Plan B), this plan moves the existing VMs
onto pve1, builds out Frigate on pve2 with the 3 existing cameras (and
incrementally adds 4 new cameras as they're installed), then wipes the
old node and brings it back as a Proxmox Backup Server.

VM migration is a manual Proxmox operation (vzdump + restore, or
`qm remote-migrate`), not Ansible. Ansible's job is to declare the
migrated VMs for tracking, provision the new Frigate VM, configure
guests, and bring up the PBS node.

## Sub-plan C.1 — Migrate HA + vpn.arnie-karen to pve1

### Manual proxmox ops

For each of HA and `vpn.arnie-karen`:
1. On the old node, take a vzdump backup (or use `qm remote-migrate`
   if both nodes are reachable and storage is compatible).
2. Transfer the backup to pve1.
3. `qm restore` on pve1, keeping the same VMID where possible.
4. Boot the migrated VM, verify networking (same IPs).
5. Power off the original on the old node — **don't delete yet**,
   keep as rollback until Plan C.3 is verified.

### Verification

- `ansible -m ping vpn.arnie-karen` from `client_parents`.
- HA web UI reachable; integrations and devices online.
- Tailscale subnet routing on `vpn.arnie-karen` still active (same VM,
  no auth changes needed).
- Ansible against the migrated VMs is idempotent: re-run
  `proxmox_vms_add.yaml --check` and confirm no-ops on `ha` and
  `vpn.arnie-karen` (or, per Plan B's caveat, drop them from
  `proxmox_vms/hosts.yaml` if the role would clobber them).

### `host_vars/<ha>.yaml` — assume HAOS

`home`'s inventory has **no** `host_vars` for the parents' HA install
(grep confirms no `ha*.yaml` under `inventories/home/host_vars/`),
which strongly suggests it's HAOS. Plan accordingly:
- Do **not** put `ha` in `proxmox_vms/hosts.yaml` (the role's
  `start_vm.yaml:78` runs `cloud-init status --wait` over SSH and
  HAOS has neither).
- Do **not** put `ha` in the `proxmox_vms` group in `inventory.yaml`.
- Declare it only as a top-level `all.hosts` entry in `inventory.yaml`
  for tracking (so docs/diagrams know it exists).
- Skip `host_vars/<ha>.yaml` entirely — there's nothing for Ansible
  to configure.

If on inspection it turns out to be HA Container on Linux, switch to
the Docker-VM pattern (`base_docker_install: true`, full host_vars,
add to `proxmox_vms` group). Decide at C.1 execution time, but the
default assumption is HAOS.

## Sub-plan C.2 — Provision Frigate on pve2 + onboard 3 existing cameras

### Files to create — under `inventories/client_parents/`

#### `host_vars/<frigate>.yaml`
```yaml
base_docker_install: true
base_docker_config: true

frigate_cameras_existing:
  - name: front_door            # placeholder names
    rtsp_url: "{{ secret_camera_front_door_rtsp }}"
  - name: backyard
    rtsp_url: "{{ secret_camera_backyard_rtsp }}"
  - name: driveway
    rtsp_url: "{{ secret_camera_driveway_rtsp }}"

frigate_cameras_pending: []   # populated as new cameras land

frigate_record_retention_days: 14   # confirm at execution
frigate_detect_objects: ["person", "car", "dog", "cat"]
frigate_hwaccel: "preset-vaapi"     # Intel iGPU via VAAPI
```

#### `proxmox_vms/hosts.yaml` (Frigate entry filled in)

Use welca's hosts.yaml schema. The cloud-init static IP is plumbed
via the `network:` block, mirroring welca line 31's pattern:
```yaml
- name: frigate
  node: pve2
  vmid: 200
  network:
    ip: "10.200.2.20"
    gateway: "10.200.2.1"
  proxmox_vm:
    template_id: 9001
    name: frigate
    name_fqdn: frigate
    cores: 8
    memory: 12288
    balloon: 8192
    disk_size: "64G"
    net0: "virtio,bridge=vmbr0"
    ipconfig0: "ip={{ network.ip }}/24,gw={{ network.gateway }}"
    start_onboot: true
  pci_devices:
    - host: "<pve2 iGPU PCI address from lspci -nn>"
      pcie: 1
  passthrough_disks: [...]   # see "Recordings storage" below
```

#### Recordings storage — hardware decision required

The proxmox role **cannot create new virtual disks of arbitrary size
on a storage pool** — `roles/proxmox/tasks/attach_disks.yaml:30-42`
only supports `passthrough_disks` (raw devices) and `virtual_disks`
referencing existing devices. The earlier sketch ("scsi1 1–2 TB on
local-lvm") wouldn't work without manual `qm set` first. Two viable
paths — pick at hardware-spec time:

**Option A (recommended, mirrors welca's `video.internal.welca.ca`):**
Pve2 includes one or two physical drives dedicated to recordings.
Passthrough into the Frigate VM via `passthrough_disks`; create a
ZFS pool inside the VM (`fileserver_setup_zfs: true`,
`fileserver_zfs_pools` list); mount at `/media/frigate`. Durable,
snapshottable, scales by adding drives. See
`inventories/client_welca/host_vars/video.internal.welca.ca.yaml`
for the exact pattern.

**Option B (simpler, if pve2 has no extra physical drives):**
Manually pre-create a virtual disk on `local-lvm` / `local-zfs`
**before** `proxmox_vms_add.yaml` runs:
`qm set 200 --scsi1 local-lvm:1024` (= 1024 GB). Reference the
existing device in `virtual_disks` of the host entry. Less elegant
but works on a single-drive pve2.

#### Vault additions
- `secret_camera_front_door_rtsp`, `secret_camera_backyard_rtsp`,
  `secret_camera_driveway_rtsp` (full RTSP URL with embedded
  credentials, kept secret to avoid exposing camera passwords).

### Frigate compose stack — locations

Repo convention (verified via
`inventories/home/host_vars/docker-02.home.stechsolutions.ca/docker_compose/scrutiny.yaml.j2`):
- **Compose service template** lives at
  `inventories/client_parents/host_vars/<frigate>/docker_compose/frigate.yaml.j2`
  (note the host-specific subdir under host_vars).
- **Frigate app config template** (`config.yml.j2`) lives at
  `files/frigate/config.yml.j2` and is referenced from the host_vars
  templated files list.

No Traefik labels — there's no reverse proxy at the parents' site
(client_welca doesn't run one either; `proxmox_acme_setup: false`,
no traefik dynamic configs in welca). Frigate's UI is reachable
directly on `10.200.2.20:5000` (or via Tailscale).

Use the `new-docker-service` skill at execution to scaffold both
files. The Frigate app config sketch:
```yaml
mqtt:
  enabled: false   # flip on once HA's broker is reachable
ffmpeg:
  hwaccel_args: "{{ frigate_hwaccel }}"
record:
  enabled: true
  retain:
    days: {{ frigate_record_retention_days }}
    mode: motion
detect:
  enabled: true
objects:
  track: {{ frigate_detect_objects }}
cameras:
{% for cam in (frigate_cameras_existing + frigate_cameras_pending) %}
  {{ cam.name }}:
    ffmpeg:
      inputs:
        - path: "{{ cam.rtsp_url }}"
          roles: [detect, record]
    detect:
      width: 1280
      height: 720
{% endfor %}
```

The compose service uses `/dev/dri:/dev/dri`,
`group_add: [<render gid from VM>]`, `shm_size: 256mb`, and volume
mounts for `/config`, `/media/frigate`, `/tmp/cache` (tmpfs). The
render GID inside the Frigate VM is not stable across distros /
package layouts — after the VM boots, run
`getent group render | cut -d: -f3` and pin that value into
`host_vars/<frigate>.yaml` (e.g. `frigate_render_gid: 109`).

### Execution

```bash
source scripts/select-inventory.sh client_parents
ansible-playbook playbooks/proxmox/proxmox_vms_add.yaml          # creates Frigate VM
ansible-playbook playbooks/proxmox/proxmox_vms_add_disks_and_pci.yaml  # iGPU + recordings disk
ansible-playbook playbooks/hosts_configure.yaml --limit=frigate  # base, docker
ansible-playbook playbooks/docker_compose.yaml --limit=frigate   # bring up the stack
```

If `vpn.arnie-karen` is declared in `proxmox_vms/hosts.yaml`,
`--check` first to confirm `proxmox_vms_add.yaml` no-ops on it before
applying.

### Verification

- Frigate web UI reachable on `10.200.2.20`, all 3 cameras live.
- Object detection events appearing for `person` / `car`.
- `intel_gpu_top` inside the Frigate VM shows render usage when
  Frigate is detecting.
- `/media/frigate` filling at the expected rate (sanity-check
  retention math).

### Sub-plan C.2b — onboard 4 new cameras (incremental follow-up)

Each new camera, as it's installed:
1. Add `secret_camera_<name>_rtsp` to the vault.
2. Append to `frigate_cameras_pending` in `host_vars/<frigate>.yaml`.
3. Re-run `playbooks/docker_compose.yaml --limit=frigate` to re-render
   `config.yml` and reload Frigate.

## Sub-plan C.3 — Old node → PBS

### Manual

1. Confirm migrated VMs have been stable for a reasonable period;
   power off and delete the originals on the old node.
2. Wipe the old node, install Proxmox Backup Server (per
   `docs/services/proxmox.md`).
3. Configure datastore + base networking on the new IP.

### Files to add / modify

- `inventories/client_parents/host_vars/<pbs>.yaml` — modeled on
  home's PBS host_vars: `ansible_host`, basic networking, datastore
  config.
- `inventories/client_parents/inventory.yaml` — add the PBS host to
  the `proxmox_pbs` group.
- `inventories/client_parents/host_vars/<pve1>.yaml` and `<pve2>.yaml`
  — add a `proxmox_storage` block pointing at the new PBS, using a
  single shared namespace `proxmox-vms` (mirrors home's
  `pve3.home.stechsolutions.ca.yaml:9-18`, **not** per-host).
- `inventories/client_parents/group_vars/proxmox_nodes.yaml` —
  switch `proxmox_backups` to PBS. **A simple storage-flip won't
  work**: `roles/proxmox/tasks/pve_create_backup.yaml:39` short-
  circuits if a backup with that `id` already exists in
  `pvesh get cluster/backup`. Two options:
  - **(Recommended)** Change the backup `id` to e.g.
    `backup-daily-pbs` AND set `storage: pbs`. The role then creates
    the new entry without touching the old. As a manual one-time
    cleanup, then run on a node:
    `pvesh delete cluster/backup/backup-daily` to remove the
    `local`-targeted entry.
  - Manually delete the existing entry first, then update inventory
    to keep id `backup-daily` but change `storage: pbs`. Same end
    state, requires manual step before the Ansible run.

### Execution

```bash
ansible-playbook playbooks/proxmox/pbs_hosts.yaml
ansible-playbook playbooks/proxmox/pve_hosts.yaml   # registers PBS storage + creates new backup entry
# Manual one-time cleanup (whichever path above was chosen):
ssh root@pve1 pvesh delete cluster/backup/backup-daily
```

### Verification

- Trigger a manual backup job on pve1; confirm it lands in the PBS
  datastore.
- Confirm scheduled daily backup at 04:30 lands the next morning.

### Cleanup

(Vault cleanup of `secret_become_pass_arnie` is handled in Plan B —
not duplicated here.)

## Files deliberately NOT changed (across all of Plan C)

- `inventories/home/proxmox_vms/`, `host_vars/vpn.home.stechsolutions.ca.yaml`,
  `group_vars/pihole.yaml` (HA + home VPN DNS entries).
- `playbooks/` and `roles/` — the existing `proxmox`, `tailscale`,
  `base`, and `docker` roles are reused as-is. No new roles needed.

## Open items (Plan C)

- Confirm at C.1 execution: HAOS (default assumption) vs HA Container
  on Linux. Affects whether `host_vars/<ha>.yaml` exists at all.
- Real camera names + RTSP URL/credentials for the 3 existing cameras
  (placeholder names: `front_door`, `backyard`, `driveway`).
- Recordings retention target (placeholder is 14 days) and the
  resulting recordings-disk sizing.
- **Recordings storage strategy** — Option A (passthrough disks +
  ZFS-in-VM) requires pve2 to ship with extra physical drives.
  Option B (pre-create virtual disk) doesn't. Hardware decision
  drives this — settle before pve2 is ordered.
- PBS datastore layout on the old hardware (single disk vs ZFS pool).
- Final hostname for the future PBS node.
- Real IP for the Frigate VM (placeholder `10.200.2.20`).
