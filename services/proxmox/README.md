# Proxmox Role

## Proxmox Hosts Manual Configuration

The following steps are required to setup a new proxmox host manually.

- Install proxmox on the host.
    - Download the ISO and run through the installation process.
    - Install the OS as a ZFS mirror.
    - Set the hostname
    - Set the IP address
    - Set the DNS servers
    - Set the gateway
    - Set the root password
    - Set the timezone
- Login and configure the following so that the host can be managed by ansible.
    - Make sure it is accessible via SSH.
    - Configure the network interfaces as required.
    - Configure the required storage (ZFS pools)

## Prerequisites
To use password authentication to the proxmox server, `sshpass` needs to be installed on the local machine. To install `sshpass` on Ubuntu, run the following command:

```bash
sudo apt install sshpass
```
