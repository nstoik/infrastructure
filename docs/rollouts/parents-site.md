# Parents-site rollout — client_parents

> Living document tracking the rollout of `client_parents`.
> Remove sections as they ship and graduate to the regular per-inventory docs.

## Status summary

- **Plan A — Barn renter VLAN**: ✅ Complete. Fiber run, switches installed, VLAN 30 + firewall rules configured.
- **Plan B — `client_parents` inventory + new Proxmox nodes**: 🔲 Repo work not started. pve1 is physically up; pve2 (shop) not yet installed.
- **Plan C — Frigate, PBS**: 🔲 Pending Plan B. C.1 VM migration physically done; Tailscale/Ansible verification pending.

## Shared facts

- Server/device LAN: `10.200.1.0/24` (Proxmox nodes, cameras, network gear).
- WiFi/user LAN: `10.200.2.0/24` (separate, not managed here).
- Hosts:
  - `pve1.internal.arniekaren.ca` → `10.200.1.4` (house, up). System hostname is `pve`; inventory uses `pve1` with `ansible_host: 10.200.1.4` — no system rename needed.
  - `pve2.internal.arniekaren.ca` → `10.200.1.5` (shop, not yet installed).
  - PBS → TBD hostname and IP (old node, Plan C.3).
  - `vpn.arnie-karen` → Tailscale address unknown (VM currently offline).
- Domain `arniekaren.ca` not yet registered — internal names only for now.
- Ansible reaches pve1/pve2 via Tailscale subnet routing through `vpn.arnie-karen`. **Blocked until `vpn.arnie-karen` is back online.**
- Modeled on `inventories/client_welca` (no ACME, `local-zfs` storage, daily backups, ntfy notifications).
- UPS is an EcoFlow → `proxmox_nut_configure: false` across the inventory.
- Frigate hwaccel: Intel iGPU on pve2 → `preset-vaapi` + `/dev/dri` passthrough.

## Remaining pre-work checklist

### Off-site — Plan B repo work
- Create `inventories/client_parents/` and all files in it
  (`inventory.yaml`, `group_vars/all/main.yaml`, `vault.yaml(.example)`,
  `proxmox_nodes.yaml`, `proxmox_vms.yaml`, host_vars for pve1/pve2 and
  vpn.arnie-karen, `proxmox_vms/hosts.yaml` skeleton).
- Generate the encrypted vault and the gitignored `vault_pass_client_parents.txt`.
- Add the `client_parents)` case to `scripts/select-inventory.sh`.
- Add the inventory entry to `docs/INVENTORIES.md`.
- Remove `vpn.arnie-karen` from `inventories/home/inventory.yaml` and
  delete `inventories/home/host_vars/vpn.arnie-karen.yaml`.
- Remove `secret_become_pass_arnie` from `home`'s vault and `.vault.yaml.example`.
- Run `ansible-inventory --list`, `--syntax-check`, and `--check` against the new inventory.
- Confirm `ansible -m ping vpn.arnie-karen` works once VM is back online.
- Approve the `10.200.1.0/24` subnet route in the Tailscale admin console. **Blocked — vpn.arnie-karen currently offline.**

### Off-site — Plan C scaffolding
- Create `host_vars/<frigate>.yaml` with the 3 existing cameras pre-populated.
- Add `secret_camera_<name>_rtsp` for the 3 existing cameras to the vault.
- Scaffold `files/frigate/config.yml.j2` and the Frigate compose service via the `new-docker-service` skill.
- Pre-fill `host_vars/<pbs>.yaml` with placeholder IP and pre-write the
  `proxmox_storage` blocks for `pve1.yaml` / `pve2.yaml` as commented-out blocks.

### On-site — remaining
- Install pve2 (shop): rack, network, install Proxmox 9 with `local-zfs`, configure `vmbr0` on `10.200.1.0/24`, confirm root SSH.
- pve2 BIOS: enable VT-d / VT-x for iGPU passthrough. After Proxmox is up, finish remotely (`intel_iommu=on iommu=pt` in GRUB, blacklist `i915`, bind iGPU to `vfio-pci`).
- If recordings strategy is Option A: physically install recording drives in pve2.
- Install the 4 new cameras (when they arrive / on a later visit).
- Wipe-and-reinstall old node as PBS.

---

# Plan B — Bootstrap `client_parents` inventory + new Proxmox nodes

## Context

We're adding a new client inventory, `client_parents`, to manage two Proxmox nodes at
the parents' site. This plan stops at "two empty managed Proxmox hosts" and
"`vpn.arnie-karen` now managed from `client_parents` instead of `home`."

`vpn.arnie-karen` is migrated **at the inventory level** (not the VM level) here —
its host_vars and become password move from `home` to `client_parents`. The VMs are
already physically on pve1 (C.1 is done).

## Files to create — all under `inventories/client_parents/`

### `inventory.yaml`
Mirror `inventories/client_welca/inventory.yaml`.
- `proxmox_nodes`: `pve1`, `pve2`
- `proxmox_pbs`: empty (added in Plan C)
- `proxmox_vms`: `ha`, `vpn.arnie-karen`, `frigate` (loaded from
  `proxmox_vms/hosts.yaml`). `ha` and `frigate` come into existence in Plan C;
  declaring them here is fine — they just won't resolve until hosts exist.
- `proxmox_containers`: empty.

### `group_vars/all/main.yaml`
Copy from `inventories/client_welca/group_vars/all/main.yaml` and adjust:
- `default_user: "arnie"`
- `default_user_email`: `nstoik@stechsolutions.ca`
- Two-user pattern: `arnie` primary + `nelson` with dotfiles + SSH keys
- `timezone`: `America/Edmonton`
- `allowed_users: [arnie, nelson]`, passworded sudo for `arnie`

### `group_vars/all/vault.yaml` + `vault.yaml.example`
Copy `inventories/client_welca/group_vars/all/vault.yaml.example` and rename the
`welca:` sub-key under `secret_ssh_keys` to `arnie:`.

Required secrets (Plan B only — camera secrets added in Plan C):
- `secret_user_password` and `secret_user_password_prehashed` for `arnie`.
  Migrated from `home`'s vault (`secret_become_pass_arnie`). Generate prehashed
  with `mkpasswd -m sha-512` if not already present.
- `secret_become_pass` (same value as above).
- `secret_nelson_password`, `secret_nelson_password_prehashed`.
- `secret_ssh_keys` with `arnie:` and `nelson:` sub-keys.
- `secret_ntfy_tokens.Proxmox` (fresh ntfy token for this site).

Encrypt:
```bash
ansible-vault encrypt inventories/client_parents/group_vars/all/vault.yaml \
  --vault-id client_parents@./vault_pass_client_parents.txt \
  --encrypt-vault-id client_parents
```

### `group_vars/proxmox_nodes.yaml`
Copy from welca. Key settings:
- `proxmox_import_storage: local-zfs`
- `proxmox_acme_setup: false`, `proxmox_backup_healthchecks_setup: false`, `scrutiny_collector_install: false`
- Cloud image template (Ubuntu 24.04, id 9001, recreate)
- ntfy targets → `https://ntfy.stechsolutions.ca/Proxmox`
- `proxmox_backups`: daily 04:30 to `local` with `id: backup-daily`
  (replaced with a PBS entry under a different id in Plan C — see C.3)
- `proxmox_users`: `arnie@pam` in Admins. No `prometheus@pve` (home-only).

### `group_vars/proxmox_vms.yaml`
Copy from welca (qemu-guest-agent package + service, vault become password).

### `host_vars/pve1.internal.arniekaren.ca.yaml` and `host_vars/pve2.internal.arniekaren.ca.yaml`
Modeled on `inventories/client_welca/host_vars/pve.internal.welca.ca.yaml`:
- `ansible_host: 10.200.1.4` (pve1) and `10.200.1.5` (pve2).
- `proxmox_nut_configure: false`.
- `proxmox_storage`: empty in Plan B; populated in Plan C once PBS is up.
  Shape mirrors `inventories/home/host_vars/pve3.home.stechsolutions.ca.yaml:9-18`
  — single shared namespace `proxmox-vms`, not per-host.
- Omit `neofetch` from custom package list (per existing welca comment).
- pve2 host_vars: note iGPU passthrough prereqs (see manual prereqs below).

### `host_vars/vpn.arnie-karen.yaml`
Move `inventories/home/host_vars/vpn.arnie-karen.yaml` to
`inventories/client_parents/host_vars/vpn.arnie-karen.yaml` and simplify to:
```yaml
ansible_host: <tailscale-ip>   # confirm once VM is back online; was 10.50.50.3
```
`ansible_user: arnie` and `ansible_become_password` come from `group_vars/all/main.yaml`.

**Tailscale stays manual.** Home's host_vars sets no `tailscale_setup` flag — the
subnet-router config has always been hand-rolled. Migrating the VM whole preserves
Tailscale state.

### `proxmox_vms/hosts.yaml` (skeleton in Plan B)
Mirror `inventories/client_welca/proxmox_vms/hosts.yaml`.

**Idempotency note** (`roles/proxmox/tasks/create_vm.yaml:10-13`): the clone step
short-circuits if `/etc/pve/qemu-server/<vmid>.conf` already exists. Listing
a migrated VM is safe — the create step no-ops.

**However**, `start_vm.yaml:78` runs `cloud-init status --wait` over SSH on every
listed VM. This breaks on HAOS. Conclusion:
- Include `vpn.arnie-karen` (Linux VM, has SSH — safe).
- **Do NOT include `ha`** (assume HAOS). Declare `ha` only as a top-level
  `all.hosts` entry in `inventory.yaml` for tracking.
- `frigate` is greenfield — full `proxmox_vm` block, runs normally.

## Files to modify — outside the new inventory

### `scripts/select-inventory.sh`
```bash
client_parents)
  export ANSIBLE_INVENTORY="./inventories/client_parents"
  export ANSIBLE_VAULT_IDENTITY_LIST="client_parents@./vault_pass_client_parents.txt"
  echo "Selected inventory: client_parents"
  ;;
```

### `vault_pass_client_parents.txt`
New gitignored file at repo root. Already covered by existing `vault_pass*.txt` rule.

### `docs/INVENTORIES.md`
Add a one-line entry pointing to the new inventory.

### `inventories/home/inventory.yaml`
Remove the two `vpn.arnie-karen` references (top-level `all.hosts` and `nodes_remote.hosts`).

### `inventories/home/host_vars/vpn.arnie-karen.yaml`
Delete.

### `inventories/home/group_vars/all/vault.yaml` + `vault.yaml.example`
Remove `secret_become_pass_arnie` from both files.

## Manual prerequisites (before Ansible runs against pve1/pve2)

1. **BLOCKER — Tailscale subnet route.** Confirm `vpn.arnie-karen` advertises
   `10.200.1.0/24` and the route is approved in the admin console. Without this,
   Ansible can't reach `10.200.1.x`.
   ```bash
   sudo tailscale up --advertise-routes=10.200.1.0/24 --advertise-exit-node=false …
   ```
   Then approve at <https://login.tailscale.com/admin/machines>.
2. pve2 (shop): rack, install Proxmox 9 with `local-zfs` root, configure `vmbr0`
   on `10.200.1.5/24`, confirm root SSH reachable.
3. pve2 iGPU passthrough: BIOS VT-d on, `intel_iommu=on iommu=pt` in GRUB,
   blacklist `i915`, bind iGPU to `vfio-pci`. Confirm with
   `lspci -nnk | grep vfio-pci`.

## Execution

**Remote — once Tailscale is confirmed:**
```bash
source setenv.sh
source scripts/select-inventory.sh client_parents
ansible-galaxy install -r requirements.yaml
ansible-inventory --list
ansible-playbook playbooks/hosts_configure.yaml --syntax-check
ansible -m ping vpn.arnie-karen
ansible-playbook playbooks/hosts_configure.yaml --limit=vpn.arnie-karen --check
```

**After pve1/pve2 are reachable:**
```bash
ansible-playbook playbooks/hosts_configure.yaml --limit=proxmox_nodes --check
ansible-playbook playbooks/proxmox/pve_hosts.yaml
ansible-playbook playbooks/proxmox/pve_hosts_templates.yaml
```

Re-run home's playbook to confirm no regressions:
```bash
source scripts/select-inventory.sh home
ansible-playbook playbooks/hosts_configure.yaml --check
```

## Verification

- pve1 and pve2 are reachable, configured, and idempotent on re-run.
- `ansible -m ping vpn.arnie-karen` from `client_parents` succeeds.
- `home` inventory parses cleanly with no `vpn.arnie-karen` references.
- pve2's iGPU shows `vfio-pci` driver bound at the host.

## Open items

- Confirm `vpn.arnie-karen` Tailscale IP once VM is back online.
- pve2 (shop) physical install pending.

---

# Plan C — Deploy Frigate, repurpose old node as PBS

## Context

With Plan B complete, this plan provisions Frigate on pve2, onboards cameras, and
repurposes the old node as PBS. VM migration (C.1) is physically done — HA and
`vpn.arnie-karen` are on pve1.

## Sub-plan C.1 — Inventory verification (physical migration done)

VMs are already on pve1. Once Tailscale is restored:
- `ansible -m ping vpn.arnie-karen` from `client_parents`.
- HA web UI reachable; integrations and devices online.
- Re-run `proxmox_vms_add.yaml --check` to confirm no-ops on `vpn.arnie-karen`.

**`ha` host_vars:** Assume HAOS (no `ha*.yaml` in home's inventory confirms this).
Do not put `ha` in `proxmox_vms/hosts.yaml` or the `proxmox_vms` group. Declare
only as a top-level `all.hosts` entry for tracking. If it turns out to be HA
Container on Linux, add full host_vars and include in `proxmox_vms` group.

## Sub-plan C.2 — Provision Frigate on pve2 + onboard 3 existing cameras

### Files to create

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

#### `proxmox_vms/hosts.yaml` — Frigate entry
```yaml
- name: frigate
  node: pve2
  vmid: 200
  network:
    ip: "10.200.1.20"
    gateway: "10.200.1.1"
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
  passthrough_disks: [...]   # see recordings storage below
```

#### Recordings storage — hardware decision required

`roles/proxmox/tasks/attach_disks.yaml:30-42` only supports `passthrough_disks`
(raw devices) and `virtual_disks` (existing devices) — it cannot create new virtual
disks. Two options:

**Option A (recommended):** pve2 ships with dedicated recording drives. Passthrough
into the Frigate VM via `passthrough_disks`; create ZFS pool inside the VM and mount
at `/media/frigate`. See `inventories/client_welca/host_vars/video.internal.welca.ca.yaml`.

**Option B (simpler):** Manually pre-create a virtual disk before `proxmox_vms_add.yaml`:
`qm set 200 --scsi1 local-zfs:1024`. Then reference in `virtual_disks`.

#### Vault additions
- `secret_camera_front_door_rtsp`, `secret_camera_backyard_rtsp`, `secret_camera_driveway_rtsp`

### Frigate compose + config

- Compose template: `inventories/client_parents/host_vars/<frigate>/docker_compose/frigate.yaml.j2`
- App config template: `files/frigate/config.yml.j2`
- No Traefik — UI reachable directly on `10.200.1.20:5000` or via Tailscale.
- Use the `new-docker-service` skill to scaffold both files.

Frigate config sketch:
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

The compose service uses `/dev/dri:/dev/dri`, `group_add: [<render gid>]`,
`shm_size: 256mb`. After VM boots, run `getent group render | cut -d: -f3` and pin
the render GID into `host_vars/<frigate>.yaml` as `frigate_render_gid`.

### Execution

```bash
source scripts/select-inventory.sh client_parents
ansible-playbook playbooks/proxmox/proxmox_vms_add.yaml
ansible-playbook playbooks/proxmox/proxmox_vms_add_disks_and_pci.yaml
ansible-playbook playbooks/hosts_configure.yaml --limit=frigate
ansible-playbook playbooks/docker_compose.yaml --limit=frigate
```

Run `proxmox_vms_add.yaml --check` first to confirm no-ops on `vpn.arnie-karen`.

### Verification

- Frigate web UI reachable on `10.200.1.20`, all 3 cameras live.
- Object detection events appearing for `person` / `car`.
- `intel_gpu_top` inside the VM shows render usage.
- `/media/frigate` filling at the expected rate.

### Sub-plan C.2b — Onboard 4 new cameras (incremental)

Each new camera as it's installed:
1. Add `secret_camera_<name>_rtsp` to the vault.
2. Append to `frigate_cameras_pending` in `host_vars/<frigate>.yaml`.
3. Re-run `playbooks/docker_compose.yaml --limit=frigate`.

## Sub-plan C.3 — Old node → PBS

### Manual steps

1. Confirm migrated VMs stable; power off and delete originals on old node.
2. Wipe old node, install Proxmox Backup Server (see `docs/services/proxmox.md`).
3. Configure datastore + networking on new IP.

### Files to add / modify

- `host_vars/<pbs>.yaml` — `ansible_host`, datastore config (modeled on home's PBS).
- `inventory.yaml` — add PBS host to `proxmox_pbs` group.
- `host_vars/pve1.internal.arniekaren.ca.yaml` and `pve2` — add `proxmox_storage`
  block pointing at PBS, single shared namespace `proxmox-vms`
  (mirrors `inventories/home/host_vars/pve3.home.stechsolutions.ca.yaml:9-18`).
- `group_vars/proxmox_nodes.yaml` — switch backups to PBS. **Cannot simply flip
  storage** (`pve_create_backup.yaml:39` short-circuits if id already exists).
  Recommended: use a new id `backup-daily-pbs` with `storage: pbs`, then manually
  delete the old entry: `pvesh delete cluster/backup/backup-daily`.

### Execution

```bash
ansible-playbook playbooks/proxmox/pbs_hosts.yaml
ansible-playbook playbooks/proxmox/pve_hosts.yaml
ssh root@pve1 pvesh delete cluster/backup/backup-daily   # one-time cleanup
```

### Verification

- Trigger a manual backup; confirm it lands in the PBS datastore.
- Confirm scheduled daily backup at 04:30 lands the next morning.

## Open items (Plan C)

- Confirm HA is HAOS vs HA Container on Linux (determines host_vars approach).
- Real camera names + RTSP credentials for the 3 existing cameras.
- Recordings retention target (placeholder 14 days) and disk sizing.
- **Recordings storage strategy** — Option A requires extra physical drives in pve2; decide before ordering hardware.
- PBS hostname and IP (old node).
- Final IP for Frigate VM (placeholder `10.200.1.20`).
- PBS datastore layout (single disk vs ZFS pool).
