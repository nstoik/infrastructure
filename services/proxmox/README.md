# Proxmox Role

## Proxmox Hosts Manual Configuration

The following steps are required to setup a new proxmox host manually.

- Install proxmox on the host.
    - Download the ISO and run through the installation process.
    - For Proxmox, install the OS as a ZFS mirror (two disks required). For PBS, the OS can be installed on a single disk.
    - Set the hostname
    - Set the IP address
    - Set the DNS servers
    - Set the gateway
    - Set the root password
    - Set the timezone
- Login and configure the following so that the host can be managed by ansible.
    - Make sure it is accessible via SSH as root (other user is added by ansible)
    - Configure the network interfaces as required.
        - [Example for Proxmox](files/proxmox_interfaces.example) network configuration
        - [Example for PBS](files/pbs_interfaces.example) network configuration
    - Configure the required storage (ZFS pools)
- After the ansible configuration is run, the following steps are required to complete the setup.
    - For Homepage configuration, on both Proxmox and PBS, create an API token for the `homepage` user. 
    - Enter that token into the `vault/vault.yaml` file under the appropriate ssection.
    - Then add the required permission to the token.
        - For Proxmox, it needs to have the `PVEAuditor` role on the `/` path.
        - For PBS, it needs to have the `Audit` role on the `/` path.
    - Then rerun the ansible playbook to apply the token to the HomePage docker container.

## Proxmox Hosts Ansible Configuration

Run the following command to configure the PBS hosts. By default, this will run against all the hosts in the `proxmox_pbs` group.

```bash
    ansible-playbook services/proxmox/pbs_hosts.yaml
```


Run the following command to configure the proxmox hosts. By default this will run against all the hosts in the `proxmox_nodes` group.

```bash
    ansible-playbook services/proxmox/pve_hosts.yaml
```

Template cloud images and template container images are downloaded. The template cloud images can have the `state` variable of `present`, `absent`, or `recreate`. The `recreate` state will delete the template and recreate it. Container templates are just downloaded. 

To setup the cloud images and templates on the proxmox hosts, run the following command. By default this will run against all Proxmox hosts
```bash
    ansible-playbook services/proxmox/pve_hosts_templates.yaml
```

To see the available template images, run the following command on the proxmox host.
```bash
    pveam available
```

## Prerequisites
To use password authentication to the proxmox server, `sshpass` needs to be installed on the local machine. To install `sshpass` on Ubuntu, run the following command:

```bash
sudo apt install sshpass
```

## Proxmox VMs Ansible Configuration
VM configurations is specified in the `inventory\proxmox_vms\` folder, the `inventory\proxmox_containers\` folder,  and the individual files for each VM in the `inventory\host_vars\` folder.

### Adding VMs
Run the following command to create and configure the VMs and containers on the proxmox hosts. This runs against all the hosts in the `proxmox_nodes` group.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add.yaml
```

To only add a specific VM or container, run the following command. The `pihole` and `proxmox_nodes` groups need to be specified to properly run the configuraiton. The `VM Name` should be replaced with the ansible name of the VM.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add.yaml --limit=pihole:proxmox_nodes:[VM Name]:
```

### Adding VM disks
To add virtual and passthrough disks on the VMs, update the VM configuration as required and run the following command. This runs against all the hosts in the `proxmox_nodes` group. Currently only VMs are supported, not containers with disks.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add_disks.yaml
```
To add disks for a specific VM, use host limits. This can be limitied to a specific proxmox node and VM. The `VM Name` should be replaced with the ansible name of the VM.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add_disks.yaml --limit=pve3.home.stechsolutions.ca:[VM Name]:
```

### Removing VMs
To remove the VMs or containers on the proxmox hosts, set the `state` variable for the VM to absent and run the following command. This is run against all the hosts in the `proxmox_nodes` group so the VM state (`absent`) needs to be properly set in the appropriate `inventory\proxmox_vms\` file , or `inventory\proxmox_containers\` file..

```bash
    ansible-playbook services/proxmox/proxmox_vms_remove.yaml
```
