# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Does

Ansible-based infrastructure-as-code managing a homelab (`home` inventory) and client sites (e.g., `client_welca`) across Proxmox VMs, Docker hosts, Raspberry Pis, and DigitalOcean cloud instances.

## Common Commands

```bash
# Environment setup (required before running playbooks)
source setenv.sh                              # Load .env into shell
source scripts/select-inventory.sh home       # Set inventory + vault identity (must be sourced, not executed)

# Install Galaxy collections
ansible-galaxy install -r requirements.yaml

# Lint / validate
ansible-lint
yamllint .
ansible-playbook playbooks/hosts_configure.yaml --syntax-check

# Dry run
ansible-playbook playbooks/hosts_configure.yaml --check

# Apply (full or targeted)
ansible-playbook playbooks/hosts_configure.yaml
ansible-playbook playbooks/hosts_configure.yaml --limit=<hostname>
ansible-playbook playbooks/hosts_configure.yaml --tags=docker,fileserver

# Vault operations
ansible-vault edit vaults/home/vault.yaml
ansible-vault encrypt vaults/<inventory>/vault.yaml --vault-password-file vault_pass_<inventory>.txt
```

## Repository Structure

```
inventories/<name>/         # Per-inventory: inventory.yaml, group_vars/, host_vars/
vaults/<name>/vault.yaml    # Encrypted secrets per inventory (committed to git)
vault_pass*.txt             # Vault passwords (gitignored, stored in Bitwarden)
playbooks/                  # Playbooks (flat) + service subdirs
  hosts_configure.yaml      # Main entrypoint — runs all roles conditionally
  proxmox/                  # Proxmox PVE/PBS/VM management
  cloud_hosts/              # DigitalOcean droplet management
roles/                      # Custom roles (base, docker, fileserver, proxmox, etc.)
roles/galaxy/               # Galaxy-installed roles (gitignored)
collections/                # Galaxy-installed collections (gitignored)
files/                      # Jinja2 templates and static config files
scripts/select-inventory.sh # Helper to switch active inventory + vault
```

## Architecture: How It All Fits Together

### Inventory → Vault → Playbook flow

Every playbook loads its vault via:
```yaml
vars_files:
  - "{{ inventory_dir }}/../../vaults/{{ inventory_dir | basename }}/vault.yaml"
```
`inventory_dir` is an Ansible magic variable (absolute path), so this expression resolves correctly regardless of playbook depth or active inventory.

### Role enablement pattern

Roles in `hosts_configure.yaml` are conditionally imported based on a `<role>_setup: true` flag in host_vars. Roles are **not** applied unless explicitly opted in:
```yaml
- name: Import docker role
  ansible.builtin.import_role:
    name: docker
  when:
    hostvars[inventory_hostname].docker_setup is defined and
    hostvars[inventory_hostname].docker_setup is true
```

### Variable precedence (highest → lowest)
1. `host_vars/<hostname>/` — per-host overrides
2. `group_vars/<group>.yaml` — group settings (applied in dependency order)
3. `group_vars/all.yaml` — global defaults

Variables follow role-name prefixes: `docker_*`, `fileserver_*`, `base_*`, `secret_*` (vault).

### Multi-inventory support

- Default inventory: `inventories/home` (set in `ansible.cfg`)
- Switch inventory: `source scripts/select-inventory.sh <name>` — sets `ANSIBLE_INVENTORY` and `ANSIBLE_VAULT_IDENTITY_LIST`
- Each inventory has an independent vault with a matching vault ID label (e.g., `home@./vault_pass.txt`)
- Vault files are AES-256 encrypted and safe to commit; only password files (`vault_pass*.txt`) are gitignored

### Vault security

A pre-commit hook (installed by `./git-init.sh`) blocks committing unencrypted vault files. Run `./git-init.sh` once after cloning to install it.

## Key Playbooks

| Playbook | Purpose |
|---|---|
| `playbooks/hosts_configure.yaml` | Main: configures all hosts using conditional role imports |
| `playbooks/docker_compose.yaml` | Deploy/update Docker Compose services |
| `playbooks/proxmox/pve_hosts.yaml` | Configure Proxmox PVE nodes |
| `playbooks/proxmox/pbs_hosts.yaml` | Configure Proxmox Backup Server |
| `playbooks/proxmox/proxmox_vms_add.yaml` | Create/configure VMs and LXC containers |
| `playbooks/cloud_hosts/create_host.yaml` | Provision DigitalOcean droplets |

## Ansible Tags

Tags follow a `role` and `role.subtask` pattern. Key tags for `hosts_configure.yaml`:

- `base`, `base.apt`, `base.dotfiles`, `base.user`, `base.geerlingguy.security`
- `docker`, `docker.compose`, `docker.prune`
- `fileserver`, `fileserver.zfs`, `fileserver.nfs-server`, `fileserver.nfs-client`, `fileserver.mergerfs`, `fileserver.snapraid`
- `proxmox`, `proxmox.pve`, `proxmox.vm`, `proxmox.container`
- `tailscale`, `healthchecks`, `pihole`, `scrutiny`, `nut`

See [docs/TAGS.md](docs/TAGS.md) for the full reference.

## Documentation

- [docs/SETUP.md](docs/SETUP.md) — initial setup, vault config, dependencies
- [docs/INVENTORIES.md](docs/INVENTORIES.md) — inventory structure, adding new inventories/hosts
- [docs/USAGE.md](docs/USAGE.md) — playbook usage and examples
- [docs/TAGS.md](docs/TAGS.md) — complete tag reference
- [docs/MANUAL_CONFIG.md](docs/MANUAL_CONFIG.md) — steps that require manual post-deploy work
- [docs/services/proxmox.md](docs/services/proxmox.md) — Proxmox bootstrapping and VM management
- [docs/services/cloud_hosts.md](docs/services/cloud_hosts.md) — DigitalOcean cloud host setup
