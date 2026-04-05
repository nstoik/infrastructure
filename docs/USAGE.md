# Usage Guide

## Running Playbooks

Before running any playbook, ensure your shell environment is set up:

```bash
source setenv.sh
source scripts/select-inventory.sh home  # or your chosen inventory
```

## Available Playbooks

### Host Configuration
Main playbook for configuring and managing hosts:

```bash
ansible-playbook playbooks/hosts_configure.yaml
```

Configure a specific host:
```bash
ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02.home.stechsolutions.ca
```

Configure a specific group:
```bash
ansible-playbook playbooks/hosts_configure.yaml --limit=docker_hosts
```

Run only specific tags:
```bash
ansible-playbook playbooks/hosts_configure.yaml --tags=docker,fileserver
```

Dry run (check mode):
```bash
ansible-playbook playbooks/hosts_configure.yaml --check
```

### System Updates
Update base packages on all hosts:

```bash
ansible-playbook playbooks/base_update.yaml
```

Update dotfiles on all hosts:
```bash
ansible-playbook playbooks/dotfiles_update.yaml
```

### Service-Specific Playbooks
Configure services managed through dedicated playbooks:

```bash
# Configure Pi-hole servers
ansible-playbook playbooks/pihole.yaml

# Configure Docker Compose services
ansible-playbook playbooks/docker_compose.yaml

# Configure DigitalOcean cloud resources
ansible-playbook playbooks/digitalocean.yaml

# Configure Raspberry Pi devices
ansible-playbook playbooks/rpi/internet-monitor.yaml
```

## Roles

The `roles/` directory contains reusable role modules. Key roles:

- **base** - System hardening, packages, timezone, users
- **docker** - Docker daemon, docker-compose, GPU support
- **fileserver** - NFS, disk partitioning, ZFS, snapraid
- **pihole** - DNS server configuration
- **proxmox** - Hypervisor and VM management
- **cloudflare** - Cloudflare DNS integration
- **digitalocean** - DigitalOcean provider configuration
- **aws** - AWS cloud provider utilities
- **healthchecks** - Healthchecks.io monitoring
- **nut** - Network UPS Tools monitoring
- **tailscale** - Tailscale VPN client
- **rclone** - Rclone remote storage
- **sanoid** - ZFS snapshot management
- **scrutiny** - SMART/disk health monitoring

See role-specific READMEs in `roles/<role>/README.md` for detailed configuration.

## Configuration Files

### Main Configuration
The main configuration is done in two places:

1. **Inventory group variables:** `inventories/home/group_vars/all/main.yaml`
2. **Inventory group variables:** `inventories/home/group_vars/<group>.yaml`
3. **Host variables:** `inventories/home/host_vars/<hostname>.yaml`
4. **Vault secrets:** `inventories/home/group_vars/all/vault.yaml` (encrypted)

See [INVENTORIES.md](./INVENTORIES.md) for detailed structure and variable naming conventions.

## Available Ansible Tags

See [TAGS.md](./TAGS.md) for a complete reference of available tags for fine-grained control over tasks.

Quick examples:

```bash
# Run only Docker-related tasks
ansible-playbook playbooks/hosts_configure.yaml --tags=docker

# Run base system setup
ansible-playbook playbooks/hosts_configure.yaml --tags=base

# Run fileserver setup
ansible-playbook playbooks/hosts_configure.yaml --tags=fileserver

# Skip specific tag
ansible-playbook playbooks/hosts_configure.yaml --skip-tags=docker.compose
```

## Services

The `playbooks/` directory contains both general and service-specific playbooks:

- **Cloud Hosts** - DigitalOcean droplet and DNS configuration (`playbooks/cloud_hosts/`)
  - See [docs/services/cloud_hosts.md](./services/cloud_hosts.md)

- **Proxmox** - Proxmox node bootstrapping and backup management (`playbooks/proxmox/`)
  - See [docs/services/proxmox.md](./services/proxmox.md)

- **Media** - Media server stack (Plex, Sonarr, Radarr, etc.)
  - See [docs/services/media.md](./services/media.md)

## Testing and Linting

Validate your configuration before deployment:

```bash
# Check YAML syntax
yamllint .

# Lint Ansible code
ansible-lint

# Check playbook syntax
ansible-playbook playbooks/hosts_configure.yaml --syntax-check
```

## Troubleshooting

### Check Inventory
View the configured inventory structure:

```bash
ansible-inventory --graph
ansible-inventory --list
```

### Check Host Connectivity
Verify Ansible can reach all hosts:

```bash
ansible all -m ping
```

### Test a Specific Role
Run a single role in check mode:

```bash
ansible-playbook playbooks/hosts_configure.yaml -i inventories/home --limit=<hostname> --tags=<role> --check
```

### View Variable Values
Check what variables will be used for a host:

```bash
ansible-inventory --host <hostname>
```

## Quick Commands Reference

```bash
# Setup environment
chmod +x setenv.sh git-init.sh scripts/select-inventory.sh
source setenv.sh
source scripts/select-inventory.sh home

# Install collections
ansible-galaxy install -r requirements.yaml

# Configure all hosts
ansible-playbook playbooks/hosts_configure.yaml --check    # Dry run
ansible-playbook playbooks/hosts_configure.yaml            # Apply

# Configure specific host
ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02.home.stechsolutions.ca

# Lint everything
yamllint . && ansible-lint && ansible-playbook playbooks/hosts_configure.yaml --syntax-check

# Check connectivity
ansible all -m ping

# View current inventory
ansible-inventory --graph
```

See specific documentation files for detailed guides:
- [SETUP.md](./SETUP.md) - Installation and environment setup
- [INVENTORIES.md](./INVENTORIES.md) - Inventory structure and management
- [TAGS.md](./TAGS.md) - Ansible tag reference
- [MANUAL_CONFIG.md](./MANUAL_CONFIG.md) - Manual configuration steps
