# infrastructure
Infrasctructure for my home lab and StechSolutions

The main file is site.yaml which is the main playbook for the whole infrastructure. It includes all the other playbooks and performs the following tasks:

- Configure the DigitalOcean cloud provider
    - Set the Tags
    - Set the firewall rules
- Configure a Netmaker server on a DigitalOcean droplet
    - Setup application
    - Configure CloudFlare DNS records

# Pipx installation
[Install Pipx](https://github.com/pypa/pipx#on-linux-install-via-pip-requires-pip-190-or-later)

Go through the steps to add it to the path and enable autocomplete.

# Ansible installation
Install Ansible via Pipx
```bash
pipx install ansible-core
pipx inject ansible-core ansible-lint
pipx install yamllint

```

# Ansible configuration and setup

Install the required collections from Ansible Galaxy
```bash
ansible-galaxy install -r requirements.yaml
```

# Ansible vault
There is a pre-commit hook to make sure an unencrypted vault is not committed.

On new desktops, run `./git-init.sh` to set up the pre-commit hook.

To encrypt a file, run `ansible-vault encrypt <file>`

To decrypt a file, run `ansible-vault decrypt <file>`

`vault_pass.txt` is the password for the vault. It is not checked into git. `ansible.cfg` has an entry for `vault_password_file` to point to this file.

# Inventory
Inventory from DigtalOcean is dynamic using a plugin. The plugin configration is in the file `inventory/do_hosts.yaml`. When using this inventory, the `DO_API_TOKEN` environment variable must be set. The value is in the vault file.

# Testing and linting
Linting can be done with the following commands

```bash
yamllint .
ansible-lint
ansible-playbook site.yaml --syntax-check
```
