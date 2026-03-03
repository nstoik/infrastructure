# Home Inventory

This is the default (home) inventory for the infrastructure. It contains all hosts for the home lab and local StechSolutions infrastructure.

## Selected Hosts

This inventory includes:
- Proxmox hypervisors and VMs (PVE, PBS)
- Docker hosts (docker-01, docker-02)
- Pi-hole DNS servers
- Storage servers
- DigitalOcean droplets

## Configuration

- **Inventory files:** `inventory.yaml`, `group_vars/`, `host_vars/`
- **Secrets vault:** `../../vaults/home/vault.yaml`
- **Vault password:** `../../vault_pass.txt`

## Using This Inventory

The home inventory is the default. When `ansible.cfg` points to `./inventories/home`, you can run playbooks without specifying an inventory:

```bash
source setenv.sh
ansible-playbook playbooks/hosts_configure.yaml
```

Or explicitly select it:
```bash
source scripts/select-inventory.sh home
ansible-playbook playbooks/hosts_configure.yaml
```

Or use CLI:
```bash
ansible-playbook -i inventories/home playbooks/hosts_configure.yaml --vault-password-file vault_pass.txt
```

## Adding Hosts

1. Add the host to `inventory.yaml` under appropriate group(s)
2. Create host variables in `host_vars/<hostname>/` or `host_vars/<hostname>.yaml`
3. Optionally add service-specific config files:
   ```
   host_vars/docker-03.home.stechsolutions.ca/
   ├── docker.yaml         # Docker configuration
   ├── fileserver.yaml     # Storage configuration
   └── docker_compose/     # docker-compose templates
       ├── media.yaml.j2
       ├── proxy.yaml.j2
       └── ...
   ```
4. Run the playbook limited to the new host:
```bash
ansible-playbook playbooks/hosts_configure.yaml --limit=docker-03.home.stechsolutions.ca --check
```

## Documentation

See the main [Inventory Management](../../docs/INVENTORIES.md) documentation for comprehensive information about inventory structure and management.
