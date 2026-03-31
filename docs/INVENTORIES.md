# Inventory Management

This repository supports multiple independent inventory sets, each managing different infrastructure environments. For example:
- `home` - Home lab and local StechSolutions infrastructure
- `client_welca` - Client site infrastructure (Proxmox host on remote site)

Each inventory has its own:
- Inventory files (`inventory.yaml`, `group_vars/`, `host_vars/`)
- Vault secrets (`inventories/<inventory>/group_vars/all/vault.yaml`)
- Vault password file (`vault_pass_<inventory>.txt`)

## Directory Structure

```
infrastructure/
├── inventories/
│   ├── home/                      # Main/default inventory
│   │   ├── inventory.yaml
│   │   ├── group_vars/
│   │   │   ├── all/
│   │   │   │   ├── main.yaml      # Global defaults
│   │   │   │   ├── vault.yaml     # Encrypted secrets (auto-loaded)
│   │   │   │   └── vault.yaml.example
│   │   │   └── <group>.yaml
│   │   └── host_vars/
│   ├── client_welca/              # Client site inventory
│   │   ├── inventory.yaml
│   │   ├── group_vars/
│   │   │   ├── all/
│   │   │   │   ├── main.yaml
│   │   │   │   ├── vault.yaml     # Encrypted secrets (auto-loaded)
│   │   │   │   └── vault.yaml.example
│   │   │   └── <group>.yaml
│   │   ├── host_vars/
│   │   └── README.md
│   └── ...
├── docs/
│   ├── inventories/
│   │   ├── home/
│   │   │   └── setup.md
│   │   ├── client_welca/
│   │   │   └── setup.md
│   │   └── ...
│   └── ...
└── ...
```

## Default vs Per-Inventory Setup

### Using the Default Home Inventory
The default `ansible.cfg` points to `./inventories/home` and `./vault_pass.txt`. Simply run playbooks normally:

```bash
ansible-playbook playbooks/hosts_configure.yaml
```

### Using Per-Inventory Setup
To use a different inventory, either:

#### Option A: Use the helper script
```bash
source scripts/select-inventory.sh client_welca
ansible-playbook playbooks/hosts_configure.yaml
```

This exports `ANSIBLE_INVENTORY` and `ANSIBLE_VAULT_IDENTITY_LIST` which override the inventory and vault configuration from `ansible.cfg`.

#### Option B: Use CLI flags
```bash
ansible-playbook \
  -i inventories/client_welca \
  playbooks/hosts_configure.yaml \
  --vault-password-file vault_pass_client_welca.txt
```

## Inventory File Organization

### hierarchy_vars - Group Variables

Group variables in `group_vars/` apply settings hierarchically based on group membership. Variable precedence (highest to lowest):

1. Host variables (`host_vars/<hostname>.yaml`)
2. Variables from groups the host belongs to (in order of group dependency)
3. All group (`group_vars/all.yaml`)

**Key group variables files:**

- `all/main.yaml` - Global defaults (timezones, domains, SMTP, monitoring URLs)
- `all/vault.yaml` - Encrypted secrets, auto-loaded for all hosts
- `proxmox_nodes.yaml` - Proxmox hypervisor settings (qemu-guest-agent, node-exporter)
- `proxmox_containers.yaml` - LXC container settings
- `proxmox_pbs.yaml` - Proxmox Backup Server settings
- `proxmox_vms.yaml` - VM settings
- `pihole.yaml` - Pi-hole configuration
- `do_docker.yaml` - DigitalOcean Docker hosts
- `rpi.yaml` - Raspberry Pi devices

### Host Variables

Host variables in `host_vars/` override group settings per hostname. Directory structure:

```
host_vars/
├── docker-01.home.stechsolutions.ca/
│   ├── docker.yaml
│   ├── fileserver.yaml
│   └── docker_compose/
│       ├── media.yaml.j2
│       └── ...
├── docker-02.home.stechsolutions.ca/
│   ├── docker.yaml
│   ├── fileserver.yaml
│   └── docker_compose/
│       └── ...
├── pve3.home.stechsolutions.ca.yaml
└── ...
```

## Variable Naming Convention

Variables follow role-name prefixes for clarity:

- `docker_*` - Docker role variables (e.g., `docker_install`, `docker_compose_dir`)
- `fileserver_*` - Fileserver role variables (e.g., `fileserver_attached_disks`)
- `base_*` - Base role settings (e.g., `base_timezone`)
- `secret_*` - Vault-protected secrets (e.g., `secret_user_password`)

## Creating a New Inventory

To add a new inventory (e.g., client_welca):

### 1. Create the inventory directory structure:
```bash
mkdir -p inventories/client_welca/group_vars/all
mkdir -p inventories/client_welca/host_vars
```

### 2. Create `inventories/client_welca/inventory.yaml`:
Start with the scaffold or copy and adapt from `inventories/home/inventory.yaml`:

```yaml
---
# Client site inventory

[all:children]
proxmox_nodes
docker_hosts

[proxmox_nodes:children]
pbs

[proxmox_nodes]
pve-client.example.com

[pbs]
pbs-client.example.com

[docker_hosts]
docker-client.example.com
```

### 3. Create group variables:
Copy and adapt `inventories/home/group_vars/all/main.yaml` to `inventories/client_welca/group_vars/all/main.yaml`:

```yaml
---
# Global settings for client_welca

base_timezone: America/Toronto
domain_name: client.example.com
# ... adjust other global settings
```

### 4. Create host variables:
Create per-host variables in `inventories/client_welca/host_vars/` similar to `inventories/home/host_vars/`.

### 5. Create vault:
```bash
# Copy the template
cp inventories/client_welca/group_vars/all/vault.yaml.example inventories/client_welca/group_vars/all/vault.yaml

# Edit with client-specific secrets
nano inventories/client_welca/group_vars/all/vault.yaml

# Encrypt the vault (must use --vault-id to stamp the correct label)
ansible-vault encrypt inventories/client_welca/group_vars/all/vault.yaml \
  --vault-id client_welca@./vault_pass_client_welca.txt \
  --encrypt-vault-id client_welca
```

### 6. Create vault password file:
```bash
# Store the vault password securely (NOT in git)
echo 'vault_password' > vault_pass_client_welca.txt
chmod 600 vault_pass_client_welca.txt
```

### 7. Test the new inventory:
```bash
source scripts/select-inventory.sh client_welca
ansible inventory --graph
```

## Example: Adding a New Host to Home Inventory

1. Add to `inventories/home/inventory.yaml`:
```yaml
[docker_hosts]
docker-03.home.stechsolutions.ca
```

2. Create host variables in `inventories/home/host_vars/docker-03.home.stechsolutions.ca/`:
```
docker.yaml         # Docker role settings
docker_compose/     # Compose file templates
  media.yaml.j2
  proxy.yaml.j2
```

3. Run the playbook limited to the new host:
```bash
ansible-playbook playbooks/hosts_configure.yaml --limit=docker-03.home.stechsolutions.ca --check
```

## Vault Management

Each inventory should have an encrypted `inventories/<inventory>/group_vars/all/vault.yaml` file containing secrets:

- SSH keys, API tokens, passwords
- IPMI/Proxmox credentials
- Service-specific secrets

**Important:** 
- Never commit unencrypted `vault.yaml` files (Git pre-commit hook prevents this)
- Store `vault_pass_<inventory>.txt` securely outside of Git
- Add vault password files to `.gitignore` (already configured)

To rotate secrets:
```bash
ansible-vault view inventories/home/group_vars/all/vault.yaml --vault-password-file vault_pass.txt
ansible-vault edit inventories/home/group_vars/all/vault.yaml --vault-password-file vault_pass.txt
```

See [SETUP.md](../SETUP.md) for vault encryption details.
