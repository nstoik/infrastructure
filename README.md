# Infrastructure
Infrastructure for my home lab and StechSolutions powered by Ansible.

This repository supports managing multiple independent infrastructure environments (inventories). Currently configured inventories:
- **home** - Home lab and local StechSolutions infrastructure (default)
- **client_welca** - Client site Proxmox infrastructure

## Quick Start

1. **[Installation & Setup](docs/SETUP.md)** - Install dependencies, configure vaults, and initialize your environment
2. **[Inventory Management](docs/INVENTORIES.md)** - Understand the inventory structure and how to manage multiple sites
3. **[Usage Guide](docs/USAGE.md)** - Run playbooks and configure infrastructure
4. **[Tags Reference](docs/TAGS.md)** - Fine-grained control with Ansible tags

## Documentation

Complete documentation is organized in the [docs/](docs/) directory:

- **[SETUP.md](docs/SETUP.md)** - Environment setup, vault configuration, dependencies
- **[INVENTORIES.md](docs/INVENTORIES.md)** - Inventory structure, variable management, creating new inventories
- **[USAGE.md](docs/USAGE.md)** - Available playbooks, running ansible, roles overview
- **[TAGS.md](docs/TAGS.md)** - Ansible tag reference for granular task control
- **[MANUAL_CONFIG.md](docs/MANUAL_CONFIG.md)** - Services requiring manual post-deployment configuration

### Service Documentation

- [Cloud Hosts](docs/services/cloud_hosts.md) - DigitalOcean droplet and DNS setup
- [Proxmox](docs/services/proxmox.md) - Proxmox hypervisor bootstrapping and management
- [Media Stack](docs/services/media.md) - Plex, Sonarr, Radarr, qBittorrent, tdarr, and related services

## Repository Structure

```
infrastructure/
├── docs/                      # Documentation (read this!)
│   ├── SETUP.md
│   ├── INVENTORIES.md
│   ├── USAGE.md
│   ├── TAGS.md
│   ├── MANUAL_CONFIG.md
│   ├── services/
│   └── inventories/
├── inventories/               # Inventory configurations
│   ├── home/                  # Default home inventory
│   │   ├── inventory.yaml
│   │   ├── group_vars/
│   │   └── host_vars/
│   └── client_welca/          # Client site inventory
│       ├── inventory.yaml
│       ├── group_vars/
│       └── host_vars/
├── vaults/                    # Per-inventory encrypted secrets
│   ├── home/vault.yaml        # Encrypted home secrets
│   └── client_welca/vault.yaml  # Encrypted client secrets
├── playbooks/                 # Ansible playbooks (including service-specific)
│   ├── proxmox/               # Proxmox PVE/PBS/VM management playbooks
│   └── cloud_hosts/           # DigitalOcean cloud host playbooks
├── roles/                     # Ansible roles
├── files/                     # Template and static files
├── scripts/                   # Helper scripts
└── ansible.cfg                # Ansible configuration
```

## Key Features

- **Multi-inventory support** - Manage multiple infrastructure environments with isolated vaults
- **Automated configuration** - IaC with Ansible across Proxmox, Docker, RPi, and cloud hosts
- **Encrypted secrets** - Vault-protected secrets per inventory, pre-commit hook prevents accidental commits
- **Flexible playbooks** - Run full configuration or specific tags for target updates
- **Comprehensive documentation** - Setup guides, usage examples, and service-specific docs
- **Reusable roles** - Modular roles for base system, Docker, Proxmox, fileserver, and more

## Getting Started

Start with [Installation & Setup](docs/SETUP.md) for step-by-step instructions.

## Common Commands

```bash
# Setup environment
source setenv.sh                              # Load env vars from .env
source scripts/select-inventory.sh home       # Select which inventory to use

# Install Ansible collections
ansible-galaxy install -r requirements.yaml

# Test configuration
ansible-playbook playbooks/hosts_configure.yaml --check

# Apply configuration
ansible-playbook playbooks/hosts_configure.yaml

# Configure specific host
ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02.home.stechsolutions.ca

# Run specific tags
ansible-playbook playbooks/hosts_configure.yaml --tags=docker,fileserver
```

See [USAGE.md](docs/USAGE.md) for more complete command examples and [TAGS.md](docs/TAGS.md) for available tags.

## License

See [LICENSE](LICENSE) file.
