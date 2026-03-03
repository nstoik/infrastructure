# Ansible Tags Reference

Available ansible tags for specifying specific tasks to run in `playbooks/hosts_configure.yaml`:

## Base Role Tags

Configure system fundamentals: users, packages, timezone, security.

```bash
ansible-playbook playbooks/hosts_configure.yaml --tags=base
```

- `base` - Base role and all base tasks
- `base.apt` - Configure apt package manager and install packages
- `base.docker` - Configure Docker repositor
- `base.dotfiles` - Configure dotfiles
- `base.known_hosts` - Configure known_hosts file on the local machine
- `base.services` - Configure systemd services (started and enabled)
- `base.geerlingguy.security` - Configure security settings using the geerlingguy.security role
- `base.user` - Configure the default user
- `base.postfix` - Configure postfix mail server
- `base.timezone` - Configure the system timezone
- `base.netplan` - Configure netplan networking

## Cloudflare Tags

Configure Cloudflare DNS and related settings.

```bash
ansible-playbook playbooks/hosts_configure.yaml --tags=cloudflare
```

- `cloudflare` - All Cloudflare tasks
- `cloudflare.dns` - Configure Cloudflare DNS records

## DigitalOcean Tags

Configure DigitalOcean cloud infrastructure.

```bash
ansible-playbook playbooks/hosts_configure.yaml --tags=digitalocean
```

- `digitalocean` - All DigitalOcean tasks
- `digitalocean.tags` - Configure DigitalOcean droplet tags
- `digitalocean.firewall` - Configure DigitalOcean firewall rules
- `digitalocean.droplet` - Configure a DigitalOcean droplet
- `digitalocean.storage` - Work with DigitalOcean block storage and volumes
- `digitalocean.user` - Configure a user on a DigitalOcean droplet

## Docker Tags

Configure Docker daemon and services.

```bash
ansible-playbook playbooks/hosts_configure.yaml --tags=docker
```

- `docker` - All Docker tasks
- `docker.compose` - Set up services using docker-compose
- `docker.prune` - Prune the docker host of unused images and containers

## Fileserver Tags

Configure storage, filesystems, and network storage services.

```bash
ansible-playbook playbooks/hosts_configure.yaml --tags=fileserver
```

- `fileserver` - All fileserver tasks
- `fileserver.ext4` - Configure ext4 filesystems
- `fileserver.mergerfs` - Configure mergerfs pooling
- `fileserver.snapraid` - Configure snapraid parity on top of mergerfs
- `fileserver.zfs` - Configure ZFS pools and datasets
- `fileserver.nfs-server` - Configure NFS server
- `fileserver.nfs-client` - Configure NFS client mounts
- `fileserver.swap` - Configure swap file

## Additional Service Tags

- `healthchecks` - Configure Healthchecks.io monitoring
- `nut` - Install and configure NUT (Network UPS Tools)
- `pihole` - Configure Pi-hole DNS server
- `proxmox` - Configure Proxmox hypervisor and VM management
  - `proxmox.cloud_images` - Download cloud images for VM templates
  - `proxmox.container_images` - Download container images
  - `proxmox.container` - Configure LXC containers
    - `proxmox.container.create` - Create a new container
    - `proxmox.container.delete` - Delete a container
    - `proxmox.container.user` - Configure container user accounts
  - `proxmox.template` - Configure VM templates
  - `proxmox.vm` - Clone and configure VMs
    - `proxmox.vm.create` - Create a new VM
    - `proxmox.vm.delete` - Delete a VM
  - `proxmox.pve` - Configure Proxmox host itself
    - `proxmox.pve.permissions` - Configure Proxmox permissions
    - `proxmox.pve.users` - Configure Proxmox user accounts
    - `proxmox.pve.storage` - Configure Proxmox storage
- `scrutiny` - Configure Scrutiny SMART monitoring collector

## Tag Combinations

Run multiple related tags:

```bash
# Configure both base system and Docker
ansible-playbook playbooks/hosts_configure.yaml --tags=base,docker

# Configure storage and fileserver
ansible-playbook playbooks/hosts_configure.yaml --tags=fileserver,zfs

# Configure Proxmox hypervisor fully
ansible-playbook playbooks/hosts_configure.yaml --tags=proxmox
```

## Skipping Tags

Skip specific tasks:

```bash
# Configure everything except Docker
ansible-playbook playbooks/hosts_configure.yaml --skip-tags=docker

# Configure Docker but skip compose services
ansible-playbook playbooks/hosts_configure.yaml --tags=docker --skip-tags=docker.compose

# Configure everything except security hardening
ansible-playbook playbooks/hosts_configure.yaml --skip-tags=base.geerlingguy.security
```

## Tag Usage Best Practices

1. **Use specific tags for targeted updates:**
   ```bash
   # Update only package repositories and security settings
   ansible-playbook playbooks/hosts_configure.yaml --tags=base.apt,base.geerlingguy.security
   ```

2. **Combine with --limit for single host:**
   ```bash
   # Configure Docker on one host only
   ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02.home.stechsolutions.ca --tags=docker
   ```

3. **Use --check before applying changes:**
   ```bash
   # See what would be changed
   ansible-playbook playbooks/hosts_configure.yaml --tags=fileserver --check
   # Apply if satisfied
   ansible-playbook playbooks/hosts_configure.yaml --tags=fileserver
   ```

4. **View what tasks match a tag:**
   ```bash
   ansible-playbook playbooks/hosts_configure.yaml --tags=docker --list-tasks
   ```

## See Also

- [USAGE.md](./USAGE.md) - General playbook usage guide
- [INVENTORIES.md](./INVENTORIES.md) - Inventory and variable management
- [SETUP.md](./SETUP.md) - Initial environment setup
