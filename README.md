# Infrastructure
Infrasctructure for my home lab and StechSolutions powered by Ansible.

# Installation and Setup
Setup and installation instructions for a new development environment to modify the infrastructure or an environment to execute the playbooks.

## Pipx installation
[Install Pipx](https://github.com/pypa/pipx#on-linux-install-via-pip-requires-pip-190-or-later)

Go through the steps to add it to the path and enable autocomplete.

## Ansible installation
Install Ansible via Pipx
```bash
pipx install ansible-core
pipx inject ansible-core jmespath
pipx install ansible-lint
pipx inject ansible-lint jmespath
pipx install yamllint
```

## Ansible configuration and setup

Install the required collections from Ansible Galaxy
```bash
ansible-galaxy install -r requirements.yaml
```

## Ansible vault
There is a pre-commit hook to make sure an unencrypted vault is not committed.

On new development environments set up the pre-commit hook.

```bash
chmod +x git-init.sh
./git-init.sh
```

To encrypt a file, run `ansible-vault encrypt <file>`

To decrypt a file, run `ansible-vault decrypt <file>`

`vault_pass.txt` is the password for the vault. It is not checked into git. The actuall password is stored in Bitwarden.and can be read from there.

`ansible.cfg` has an entry for `vault_password_file` to point to this file.

## Environment variables
There is an example environment file in the root directory called `.env.example`. Copy this file to `.env` and fill in the required values. The required values are stored in the ansible vault file `vault/vault.yaml` and can be copied from there.

The environment variables should be set in the shell before running any of the playbooks. The easiest way to do this is to use the helper script `setenv.sh` which will read the values from the `.env` file and set them in the shell. 

The script needs to be execuatable.

```bash
chmod +x setenv.sh
source setenv.sh
```

# Usage
## Primary Usage
The main file is [site.yaml](site.yaml) which is the main playbook for the whole infrastructure. It includes the other playbooks and performs the following tasks:

- Configure the DigitalOcean cloud provider
    - Set the Tags
    - Set the firewall rules
- Configure a Netmaker server on a DigitalOcean droplet
    - Further info on the Netmaker service can be found [here](services/netmaker/README.md)

The main configuration is done in the [inventory/group_vars/all.yaml](inventory/group_vars/all.yaml) and the [vault/vault.yaml](vault/vault.yaml) (this file is encrypted) files.

## Playbooks
The playbooks directory contains the different playbooks that can be run.

The playbooks are:
- [site.yaml](site.yaml) - The main playbook for the whole infrastructure
- [pihole.yaml](playbooks/pihole.yaml) - Configure pihole server

## Roles
The roles directory contains roles that are used by the playbooks.

The roles are:
- [base](roles/base/)
- [cloudflare](roles/cloudflare/)
- [digitalocean](roles/digitalocean/)
- [netmaker](roles/netmaker/)
- [pihole](roles/pihole/)
- [proxmox](roles/proxmox/)


## Services
The services directory contains the subfolders and playbooks for the various services I run on my infrastructure.

The services are:
- [Netmaker](services/netmaker/README.md)
- [Proxmox](services/proxmox/README.md)

## Ansible Tags
The following ansible tags are available to specify specific tasks to run.

- base - Base role and tasks for all hosts
    - base.apt - Configure apt and install packages
    - base.docker - Configure docker
    - base.dotfiles - Configure dotfiles
    - base.known_hosts - Configure known hosts file on the local machine
    - base.services - Configure systemd services (started and enabled)
    - base.geerlingguy.security - Configure security settings using the geerlingguy.security role
    - base.user - Configure the default user
- cloudflare - Configure Cloudflare
    - cloudflare.dns - Configure Cloudflare DNS
- digitalocean - Configure the DigitalOcean cloud provider
    - digitalocean.tags - Configure the DigitalOcean tags
    - digitalocean.firewall - Configure the DigitalOcean firewall
    - digitalocean.droplet - Configure a DigitalOcean droplet
    - digitalocean.storage - Work with DigitalOcean block storage and volumes
    - digitalocean.user - Configure a user on a DigitalOcean droplet
- netmaker - Configure a Netmaker server
    - netmaker.full_setup - Complete the full setup of a Netmaker server
    - netmaker.nmctl - Install the nmctl command line tool
    - netmaker.network - Configure the Netmaker networks
    - netmaker.enrollment - Configure the Netmaker enrollment keys
    - netmaker.netclient - Configure the Netmaker netclient
        - netmaker.netclient.docker - Configure the Netmaker netclient using docker
        - netmaker.netclient.systemd - Configure the Netmaker netclient using systemd
        - netmaker.netclient.join - Join the Netmaker netclient to the network
    - netmaker.ext_client - Configure external clients
    - netmaker.acl - Configure the Netmaker ACLs
- pihole - Configure a pihole server
- proxmox - Configure the proxmox nodes and vms
    - proxmox.cloud_images - Download cloud images
    - proxmox.template - Configure the proxmox template
    - proxmox.vm - Clone and configure VMs on the proxmox nodes
        - proxmox.vm.create - Create a VM on the proxmox node
        - proxmox.vm.delete - Delete a VM on the proxmox node
    - proxmox.pve - Configure proxmox hosts
        - proxmox.pve.permissions - Configure proxmox permissions
        - proxmox.pve.users - Configure proxmox users
        - proxmox.pve.storage - Configure proxmox storage

# Inventory
Inventory files are as follows in the [inventory](inventory) directory:

- [proxmox_vms](inventory/proxmox_vms) - Inventory for the proxmox vms
    - [hosts.yaml](inventory/proxmox_vms/hosts.yaml) - Inventory for the proxmox vms
- [do_hosts.yaml](inventory/do_hosts.yaml) - Dynamic inventory for DigitalOcean
    - Inventory from DigtalOcean is dynamic using a plugin.
    - When using this inventory, the `DO_API_TOKEN` environment variable must be set. See [Environment variables](#environment-variables) for more information.
- [netclients.yaml](inventory/netclients.yaml) - Inventory for the netclients
- [netclients_manual.yaml](inventory/netclients_manual.yaml) - Inventory for the netclients
    - This inventory is used for hosts that have to first have netclient installed manually so they can be reached by Ansible.


# Testing and linting
Linting can be done with the following commands

```bash
yamllint .
ansible-lint
ansible-playbook site.yaml --syntax-check
```
