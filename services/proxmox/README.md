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
    ansible-playbook services/proxmox/pve_hosts
```

To setup the cloud images and templates on the proxmox hosts, run the following command.

```bash
    ansible-playbook services/proxmox/setup
```

## Prerequisites
To use password authentication to the proxmox server, `sshpass` needs to be installed on the local machine. To install `sshpass` on Ubuntu, run the following command:

```bash
sudo apt install sshpass
```
