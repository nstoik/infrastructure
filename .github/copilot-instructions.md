# Copilot Instructions for Infrastructure Project

## Overview
This is an Ansible-based infrastructure-as-code project managing a homelab and StechSolutions infrastructure across multiple Proxmox VMs, Docker hosts, Raspberry Pis, and cloud instances. The project uses Ansible Galaxy collections and custom roles to handle provisioning, configuration, and service deployment.

## Architecture Patterns

### Inventory Organization
- **Hierarchical groups** in `../inventory/inventory.yaml` define host relationships
- **Group variables** in `../inventory/group_vars/` apply settings hierarchically:
  - `all.yaml` - Global defaults (timezones, domains, SMTP, Prometheus/Grafana/Alertmanager URLs)
  - `proxmox_vms.yaml` - VM-specific settings (qemu-guest-agent, node-exporter)
  - `do_docker.yaml`, `rpi.yaml`, `pihole.yaml` - Group-specific configs
- **Host variables** in `../inventory/host_vars/` override group settings per hostname
  - Directory-based: `docker-02.home.stechsolutions.ca/fileserver.yaml` groups related vars
- **Variable precedence**: host_vars > group_vars (groups applied in dependency order)

### Role Structure
Each role in `../roles/` follows standard Ansible layout:
- `defaults/main.yaml` - Safe defaults (e.g., `docker_install: false` requires explicit enable)
- `tasks/main.yaml` - Primary task flow with conditional imports
- `handlers/` - Service restart handlers
- `templates/` and `files/` - Configuration templates (Jinja2) and static files

Key roles:
- **base** - SSH hardening, system packages, timezone (uses geerlingguy.security role)
- **docker** - Docker daemon setup, docker-compose, GPU support via nvidia-toolkit
- **fileserver** - NFS mounts/exports, disk partitioning, ZFS/snapraid
- **pihole** - DNS configuration (v6 installation pattern)
- **proxmox** - Hypervisor/container management

### Service Organization
`../services/` subdirectories contain service-specific playbooks and compose files:
- `cloud_hosts/` - DigitalOcean configuration
- `media/` - Media server stack (Plex, Sonarr, Radarr, qBittorrent, tdarr)
- `proxmox/` - Proxmox backup and management

## Configuration Patterns

### Conditional Role Inclusion
Roles are conditionally imported based on host variables (see `../playbooks/hosts_configure.yaml`):
```yaml
- name: Import docker role
  ansible.builtin.import_role:
    name: docker
  when:
    hostvars[inventory_hostname].docker_setup is defined and
    hostvars[inventory_hostname].docker_setup is true
  tags:
    - docker
```
**Pattern**: Check `<role>_setup: true` in host_vars to enable; use tag-based filtering for partial runs.

### Variable Prefixing Convention
Variables follow role-name prefixes for clarity:
- `docker_*` - Docker role variables (e.g., `docker_install`, `docker_compose_dir`)
- `fileserver_*` - Fileserver role variables (e.g., `fileserver_attached_disks`, `fileserver_nfs_exports`)
- `base_*` - Base role settings (e.g., `base_timezone`, `base_additional_packages`)
- `secret_*` - Vault-protected secrets (see below)

### External Collections
From `../requirements.yaml`:
- `community.general`, `community.docker`, `community.digitalocean`, `ansible.posix`, `community.aws`, `amazon.aws`
- Third-party security role: `geerlingguy.security` (SSH hardening, auto-updates)

## Secrets & Vault Management

- **File**: `../vault/vault.yaml` (encrypted, not in git)
- **Reference**: `../vault/vault.yaml.example` for structure
- **Common secrets**: SSH keys, DO/Cloudflare tokens, passwords, IPMI credentials
- **Usage**: Include in playbooks via `vars_files: - ../vault/vault.yaml`
- **Pre-commit hook**: `../git-init.sh` prevents unencrypted vault commits
- **Ansible config** (`../ansible.cfg`): `vault_password_file = ./vault_pass.txt`

## Playbook Invocation

- **Full configuration**: `ansible-playbook playbooks/hosts_configure.yaml`
- **Limit to host**: `ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02.home.stechsolutions.ca`
- **Tag-based filtering**: `ansible-playbook playbooks/hosts_configure.yaml --tags=fileserver.nfs-server`
- **Docker only**: `ansible-playbook playbooks/docker_compose.yaml`

## File Organization Examples

**Docker host setup** (`../inventory/host_vars/docker-02.home.stechsolutions.ca/`):
- `fileserver.yaml` - Disk mounts, NFS clients/exports
- Other YAML files for service-specific config (proxy, tdarr, monitoring volumes)

**Templates directory** (`../files/`): Jinja2 templates for services:
- `prometheus/prometheus.yaml` - Scrape configs
- `traefik/traefik-prod.yaml` - Reverse proxy routing
- `grafana/provisioning/` - Datasource/dashboard automation

## Development Workflow

1. **Environment setup**: `chmod +x setenv.sh && source setenv.sh` (loads vault password from `.env`)
2. **Install collections**: `ansible-galaxy install -r requirements.yaml`
3. **Validate**: `ansible-lint playbooks/*.yaml` and `yamllint inventory/`
4. **Dry run**: `ansible-playbook playbooks/hosts_configure.yaml --check`
5. **Execute**: Run playbook with appropriate `--limit` or `--tags`

## Key Conventions

- **Handlers**: Use `name: restart docker` format; handlers triggered by changed tasks
- **Tags**: Granular (e.g., `fileserver`, `fileserver.nfs-server`, `fileserver.ext4`)
- **Become**: All tasks use `ansible_become_password` from vault; no hardcoded sudo
- **Idempotency**: Roles designed to run multiple times safely (no state mutations without checks)
- **Jinja2 templates**: Use `{{ variable }}` syntax; filter undefined with `{{ var | default('fallback') }}`
