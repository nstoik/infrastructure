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
The main configuration is done in the [inventory/group_vars/all.yaml](inventory/group_vars/all.yaml) and the [vault/vault.yaml](vault/vault.yaml) (this file is encrypted) files.

## Playbooks
The playbooks directory contains the different playbooks that can be run.

The playbooks are:
- [base_update.yaml](playbooks/base_update.yaml) - Update the base packages on all hosts
- [digitalocean.yaml](playbooks/digitalocean.yaml) - Configure DigitalOcean configuration as specified.
- [docker_compose.yaml](playbooks/docker_compose.yaml) - Run the docker role on the docker hosts.
- [dotfiles_update.yaml](playbooks/dotfiles_update.yaml) - Update the dotfiles on all hosts
- [hosts_configure.yaml](playbooks/hosts_configure.yaml) - Configure the hosts. This defaults to all hosts but can be limited to specific hosts.
    - eg. `ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02.home.stechsolutions.ca`
- [pihole.yaml](playbooks/pihole.yaml) - Configure pihole server

## Roles
The roles directory contains roles that are used by the playbooks.

The roles are:
- [base](roles/base/)
- [cloudflare](roles/cloudflare/)
- [digitalocean](roles/digitalocean/)
- [docker](roles/docker/)
- [fileserver](roles/fileserver/)
- [healthchecks](roles/healthchecks/)
- [ntfy](roles/ntfy/)
- [pihole](roles/pihole/)
- [proxmox](roles/proxmox/)


## Services
The services directory contains the subfolders and playbooks for the various services I run on my infrastructure.

The services are:
- [Cloud Hosts](services/cloud_hosts/README.md)
- [Proxmox](services/proxmox/README.md)

## Files
The files directory contains files that are used by certain roles or hosts.

- [homepage](files/homepage) - Homepage files
    - [bookmarks.yaml](files/homepage/bookmarks.yaml) - Bookmarks for the homepage
    - [docker.yaml](files/homepage/docker.yaml) - Docker configuration for the homepage
    - [services.yaml](files/homepage/services.yaml) - Services for the homepage
    - [settings.yaml](files/homepage/settings.yaml) - Settings for the homepage
    - [widgets.yaml](files/homepage/widgets.yaml) - Widgets for the homepage
- [ntfy](files/ntfy) - Ntfy configuration files
    - [server.yaml](files/ntfy/server.yaml) - Ntfy server configuration
- [traefik](files/traefik) - Traefik configuration files
    - [dynamic.yaml](files/traefik/dynamic.yaml) - Traefik dynamic configuration for https proxy
        - [unifi.yaml](files/traefik/dynamic/unifi.yaml) - Unifi router file
    - [traefik-dev.yaml](files/traefik/traefik-dev.yaml) - Traefik configuration for development
    - [traefik-prod-no-file-provider.yaml](files/traefik/traefik-prod-no-file-provider.yaml) - Traefik configuration for production without a file provider for dynamic configuration.
    - [traefik-prod.yaml](files/traefik/traefik-prod.yaml) - Traefik configuration for production

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
    - base.postfix - Configure postfix
    - base.timezone - Configure the timezone
- cloudflare - Configure Cloudflare
    - cloudflare.dns - Configure Cloudflare DNS
- digitalocean - Configure the DigitalOcean cloud provider
    - digitalocean.tags - Configure the DigitalOcean tags
    - digitalocean.firewall - Configure the DigitalOcean firewall
    - digitalocean.droplet - Configure a DigitalOcean droplet
    - digitalocean.storage - Work with DigitalOcean block storage and volumes
    - digitalocean.user - Configure a user on a DigitalOcean droplet
- docker - Configure docker
    - docker.compose - Set up services using docker compose
    - docker.prune - Prune the docker host of unused images and containers
- fileserver - Configure a fileserver
    - fileserver.ext4 - Configure an ext4 filesystem
    - fileserver.mergerfs - Configure mergerfs
    - fileserver.snapraid - Configure snapraid on top of mergerfs
    - fileserver.zfs - Configure zfs
    - fileseerver.nfs-server - Configure an NFS server
    - fileserver.nfs-client - Configure an NFS client
    - fileserver.swap - Configure swap file
- healthchecks - Configure healthchecks
- pihole - Configure a pihole server
- proxmox - Configure the proxmox nodes and vms
    - proxmox.cloud_images - Download cloud images
    - proxmox.container_images - Download container images
    - proxmox.container - Configure containers on the proxmox nodes
        - proxmox.container.create - Create a container on the proxmox node
        - proxmox.container.delete - Delete a container on the proxmox node
        - proxmox.container.user - Configure a user on a container
    - proxmox.template - Configure the proxmox templates
    - proxmox.vm - Clone and configure VMs on the proxmox nodes
        - proxmox.vm.create - Create a VM on the proxmox node
        - proxmox.vm.delete - Delete a VM on the proxmox node
    - proxmox.pve - Configure proxmox hosts
        - proxmox.pve.permissions - Configure proxmox permissions
        - proxmox.pve.users - Configure proxmox users
        - proxmox.pve.storage - Configure proxmox storage

# Inventory
Inventory files are as follows in the [inventory](inventory) directory:

- [group_vars](inventory/group_vars/) - Inventory for each group
    - [all.yaml](inventory/group_vars/all.yaml) - Inventory for all hosts
    - [do_ansible.yaml](inventory/group_vars/do_ansible.yaml) - Inventory for the DigitalOcean VMs that are managed by Ansible
    - [do_docker.yaml](inventory/group_vars/do_docker.yaml) - Inventory for the DigitalOcean VMs that are used for Docker
    - [pihole.yaml](inventory/group_vars/pihole.yaml) - Inventory for the pihole servers
    - [proxmox_nodes.yaml](inventory/group_vars/proxmox_nodes.yaml) - Inventory for the proxmox nodes
    - [proxmox_vms.yaml](inventory/group_vars/proxmox_vms.yaml) - Inventory for the proxmox vms
- [host_vars](inventory/host_vars/) - Inventory for each host
    - [docker-02.home.stechsolutions.ca](inventory/host_vars/docker-02.home.stechsolutions.ca) - Folder for multiple inventory files for the docker-02 host
    - [docker-cloud-01](inventory/host_vars/docker-cloud-01) - Folder for multiple inventory files for the docker-cloud-01 host
- [proxmox_containers](inventory/proxmox_containers) - Inventory for the proxmox containers
    - [hosts.yaml](inventory/proxmox_containers/hosts.yaml) - Inventory for the proxmox containers
- [proxmox_vms](inventory/proxmox_vms) - Inventory for the proxmox vms
    - [docker_hosts.yaml](inventory/proxmox_vms/docker_hosts.yaml) - Inventory for the docker hosts running on proxmox
    - [hosts.yaml](inventory/proxmox_vms/hosts.yaml) - Inventory for the proxmox vms
- [do_hosts.yaml](inventory/do_hosts.yaml) - Dynamic inventory for DigitalOcean
    - Inventory from DigtalOcean is dynamic using a plugin.
    - When using this inventory, the `DO_API_TOKEN` environment variable must be set. See [Environment variables](#environment-variables) for more information.
- [inventory.yaml](inventory/inventory.yaml) - Main inventory file
    - This file includes the main inventory hosts and groups


# Manual Configuration
While the purpose of this repository is to automate the configuration of the infrastructure, there are some manual configurations that need to be done.

## Ntfy
The subscribed topics need to be added manually in the Ntfy clients (web or iOS app). The list of topics to subscribe to are:
- Healthchecks
- SnapRAID
- Uptime-Kuma
- wud

## Proxmox
The proxmox hosts need to be bootstrapped to a point where they can be managed by ansible. See the [Proxmox Hosts Manual Configuration](services/proxmox/README.md) for more information.

## Uptime-Kuma
Uptime-Kuma is installed as a docker container by Ansible. Currently, the configuration is not automated and needs to be done manually (until an API for uptime-kuma is available).

## 3D Printer
The 3D printer is not managed by Ansible. The configuration is done manually. The 3D printer is a Creality Ender 3 S1 Pro with a Raspberry Pi 3 B+ running MainsailOS.

The [3D Printer Repo](https://github.com/nstoik/3D-printer) stores the configuration backups of the 3D printer powered by Klipper-Backup.

- The `main` branch of the repo is the Klipper configuation.
- The `orcaslicer-backup` branch of the repo is the Orcaslicer configuration.

# Testing and linting
Linting can be done with the following commands

```bash
yamllint .
ansible-lint
ansible-playbook site.yaml --syntax-check
```
