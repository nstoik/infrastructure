# Proxmox Role

## Proxmox Hosts Manual Configuration

The following steps are required to setup a new proxmox host manually.

- Install proxmox on the host.
    - Download the ISO and run through the installation process.
    - Install the OS as a ZFS mirror (two disks required)
    - Set the hostname
    - Set the IP address
    - Set the DNS servers
    - Set the gateway
    - Set the root password
    - Set the timezone
- Login and configure the following so that the host can be managed by ansible.
    - Make sure it is accessible via SSH as root (other user is added by ansible)
    - Configure the network interfaces as required.
    - Configure the required storage (ZFS pools)
    - Configure the backup schedule
        - The backup storage is added by ansible
        - TODO: Backup configuration needs to be added to ansible when setting up the Proxmox Backup Server (PBS)

## Proxmox Hosts Ansible Configuration

Run the following command to configure the proxmox hosts. By default this will run against all the hosts in the `proxmox_nodes` group.

```bash
    ansible-playbook services/proxmox/pve_hosts.yaml
```

To setup the cloud images and templates on the proxmox hosts, run the following command.

```bash
    ansible-playbook services/proxmox/pve_hosts_templates.yaml
```

## Prerequisites
To use password authentication to the proxmox server, `sshpass` needs to be installed on the local machine. To install `sshpass` on Ubuntu, run the following command:

```bash
sudo apt install sshpass
```

## Proxmox VMs Ansible Configuration
VM configurations is specified in the `inventory\proxmox_vms\` folder and the individual files for each VM in the `inventory\host_vars\` folder.

### Adding VMs
Run the following command to create and configure the VMs on the proxmox hosts. This runs against all the hosts in the `proxmox_nodes` group.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add.yaml
```

To only add a specific VM, run the following command. The `pihole` and `proxmox_nodes` groups need to be specified to properly run the configuraiton. The `VM Name` should be replaced with the ansible name of the VM.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add.yaml --limit=pihole:proxmox_nodes:[VM Name]:
```

### Adding VM disks
To add virtual and passthrough disks on the VMs, update the VM configuration as required and run the following command. This runs against all the hosts in the `proxmox_nodes` group.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add_disks.yaml
```
To add disks for a specific VM, use host limits. This can be limitied to a specific proxmox node and VM. The `VM Name` should be replaced with the ansible name of the VM.

```bash
    ansible-playbook services/proxmox/proxmox_vms_add_disks.yaml --limit=pve3.home.stechsolutions.ca:[VM Name]:
```

### Removing VMs
To remove the VMs on the proxmox hosts, set the `state` variable for the VM to absent and run the following command. This is run against all the hosts in the `proxmox_nodes` group so the VM state (`absent`) needs to be properly set in the appropriate `inventory\proxmox_vms\` file.

```bash
    ansible-playbook services/proxmox/proxmox_vms_remove.yaml
```
