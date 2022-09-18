# infrastructure
 Infrasctructure for my home lab and StechSolutions

# Pipx installation
[Install Pipx](https://github.com/pypa/pipx#on-linux-install-via-pip-requires-pip-190-or-later)

Go through the steps to add it to the path and enable autocomplete.

# Ansible installation
Install Ansible via Pipx
```bash
pipx install ansible-core ansible-lint yamllint
```

# Ansible vault
There is a pre-commit hook to make sure an unencrypted vault is not committed.

On new desktops, run `./git-init.sh` to set up the pre-commit hook.

To encrypt a file, run `ansible-vault encrypt <file>`

To decrypt a file, run `ansible-vault decrypt <file>`

# Inventory
Inventory from DigtalOcean is dynamic using a plugin. The plugin configration is in the file `inventory/do_hosts.yaml`. When using this inventory, the `DO_API_TOKEN` environment variable must be set. The value is in the vault file.

# Testing and linting
Linting can be done with the following commands

```bash
yamllint
ansible-playbook digitalocean.yaml --syntax-check
```
