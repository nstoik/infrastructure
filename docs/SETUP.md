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

### Bitwarden SSH Agent

SSH keys used to connect to managed hosts are stored in Bitwarden. Bitwarden is configured to act as the SSH agent, serving keys to Ansible during playbook runs.

Before running any playbooks, ensure Bitwarden is unlocked and the SSH agent is active. You can verify the agent is running with:

```bash
ssh-add -l
```

If the agent has no identities listed, unlock Bitwarden and enable the SSH agent in the Bitwarden desktop app settings. When a key is first requested each session, Bitwarden will prompt for approval in the desktop app — this must be accepted before the key will be served to the agent.

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

To encrypt a file, you must use `--vault-id` (not `--vault-password-file`) so the vault header is stamped with the correct inventory label. Using `--vault-password-file` will apply the default `home` label, causing decryption failures for other inventories.

```bash
ansible-vault encrypt inventories/<inventory>/group_vars/all/vault.yaml \
  --vault-id <inventory>@./vault_pass_<inventory>.txt \
  --encrypt-vault-id <inventory>
```

`--encrypt-vault-id` is required when multiple vault IDs are loaded (e.g. via `ANSIBLE_VAULT_IDENTITY_LIST`) to ensure the header is stamped with the correct label.

To decrypt a file, run:
```bash
ansible-vault decrypt inventories/<inventory>/group_vars/all/vault.yaml --vault-id <inventory>@./vault_pass_<inventory>.txt
```

The `ansible.cfg` is configured using `vault_identity_list` entries that point to the default home vault.

### 3. Generate Pre-hashed Passwords

Some vault variables require a pre-hashed password (e.g., `secret_user_password_prehashed`). Generate one using `openssl`:

```bash
openssl passwd -6 'your_password_here'
```

`-6` produces a SHA-512 crypt hash, which is the format Ansible's `user` module expects for the `password` field.

### 4. Environment Variables

Copy the example environment file to `.env` and fill in required values:

```bash
cp .env.example .env
```

The required values are stored in the ansible vault file `inventories/home/group_vars/all/vault.yaml` (and per-inventory vaults in `inventories/<inventory>/group_vars/all/vault.yaml`). You can copy values from the vault.yaml.example files as templates.

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
- `ANSIBLE_VAULT_IDENTITY_LIST` - Vault identity list (including the path to the vault password file) used for encrypting/decrypting secrets for that inventory

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
