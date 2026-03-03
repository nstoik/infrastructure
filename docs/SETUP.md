# Installation and Setup

Setup and installation instructions for a new development environment to modify the infrastructure or an environment to execute the playbooks.

## Prerequisites

### Pipx Installation
[Install Pipx](https://github.com/pypa/pipx#on-linux-install-via-pip-requires-pip-190-or-later)

Go through the steps to add it to the path and enable autocomplete.

### Ansible Installation
Install Ansible and required tools via Pipx:

```bash
pipx install ansible-core
pipx inject ansible-core boto3 botocore jmespath
pipx install ansible-lint
pipx inject ansible-lint jmespath
pipx install yamllint
```

## Repository Setup

### 1. Install Ansible Collections
Install the required collections from Ansible Galaxy:

```bash
ansible-galaxy install -r requirements.yaml
```

### 2. Configure Vault Access

There is a pre-commit hook to ensure that vault files are not accidentally committed unencrypted.

#### For the home inventory (default):
```bash
chmod +x git-init.sh
./git-init.sh
```

The `vault_pass.txt` file contains the password for the home vault. It is not checked into git; the actual password is stored in Bitwarden and can be read from there.

#### For per-inventory setups:
For each additional inventory (e.g., client_welca), create a corresponding vault password file:

```bash
# Create vault_pass_<inventory>.txt for each inventory
# Store these securely, outside git
```

To encrypt a file, run:
```bash
ansible-vault encrypt <file> --vault-password-file ./vault_pass_<inventory>.txt
```

To decrypt a file, run:
```bash
ansible-vault decrypt <file> --vault-password-file ./vault_pass_<inventory>.txt
```

The `ansible.cfg` has entries for `vault_password_file` to point to the default home vault.

### 3. Environment Variables

Copy the example environment file to `.env` and fill in required values:

```bash
cp .env.example .env
```

The required values are stored in the ansible vault file `vaults/home/vault.yaml` (and per-inventory vaults in `vaults/<inventory>/vault.yaml`). You can copy values from the vault.yaml.example files as templates.

Set environment variables in your shell before running playbooks:

```bash
chmod +x setenv.sh
source setenv.sh
```

## Inventory Management

This repository supports multiple independent inventory sets (e.g., `home` and `client_welca`), each with their own secrets vault.

### Selecting an Inventory

Use the helper script to set environment variables. It must be `source`d (not executed directly) so the exports persist in your current shell:

```bash
chmod +x scripts/select-inventory.sh
source scripts/select-inventory.sh home
# or
source scripts/select-inventory.sh client_welca
```

This sets:
- `ANSIBLE_INVENTORY` - Path to the inventory files
- `ANSIBLE_VAULT_PASSWORD_FILE` - Path to the vault password file

Alternatively, run playbooks with explicit flags:

```bash
ansible-playbook -i inventories/client_welca playbooks/hosts_configure.yaml --vault-password-file ./vault_pass_client_welca.txt
```

See [INVENTORIES.md](./INVENTORIES.md) for detailed inventory structure and setup.

## Code Quality

Validate the configuration with linting:

```bash
yamllint .
ansible-lint
ansible-playbook playbooks/hosts_configure.yaml --syntax-check
```

## Deploying Changes

For dry runs to test changes:

```bash
ansible-playbook playbooks/hosts_configure.yaml --check
```

For actual deployment, run playbooks with appropriate `--limit` or `--tags`:

```bash
# Configure a specific host
ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02.home.stechsolutions.ca

# Configure all docker hosts
ansible-playbook playbooks/hosts_configure.yaml --limit=docker_hosts

# Run only specific tags
ansible-playbook playbooks/hosts_configure.yaml --tags=docker,fileserver
```

See [USAGE.md](./USAGE.md) for available playbooks and tags.
