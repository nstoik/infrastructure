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
pipx inject ansible-core boto3 botocore jmespath
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
- [rpi](playbooks/rpi)
    - [internet-monitor.yaml](playbooks/rpi/internet-monitor.yaml) - Configure an internet monitoring raspberry pi. Not used, kept for future reference.
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
- [nut](roles/nut/)
- [pihole](roles/pihole/)
- [proxmox](roles/proxmox/)
- [tailscale](roles/tailscale/)

## Services
The services directory contains the subfolders and playbooks for the various services I run on my infrastructure.

The services are:
- [Cloud Hosts](services/cloud_hosts/README.md)
- [Proxmox](services/proxmox/README.md)

## Files
The files directory contains files that are used by the roles and playbooks.

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
    - base.netplan - Configure netplan
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
- nut - Install and configure NUT (Network UPS Tools)
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
Inventory files are in the [inventory](inventory) directory:

# Manual Configuration
While the purpose of this repository is to automate the configuration of the infrastructure, there are some manual configurations that need to be done.

## 3D Printer
The 3D printer is not managed by Ansible. The configuration is done manually. The 3D printer is a Creality Ender 3 S1 Pro with a Raspberry Pi 3 B+ running MainsailOS.

The [3D Printer Repo](https://github.com/nstoik/3D-printer) stores the configuration backups of the 3D printer powered by Klipper-Backup.

- The `main` branch of the repo is the Klipper configuration.
- The `orcaslicer-config-folder` branch of the repo is the Orcaslicer configuration folder backed up to GitHub.

## FileStash
Once the FileStash docker container is running, the configuration needs to be done manually.
- Navigate to the [web interface](https://filestash.home.stechsolutions.ca) and set the admin password that is saved in Bitwarden.
- Navigate to the [Admin Console](https://filestash.home.stechsolutions.ca/admin/backend).
- Add two `SFTP` backends and configure them to connect to `storage.home.stechsolutions.ca/mnt/storage` and `storage.home.stechsolutions.ca/mnt/zfs`.
- The username is {{ default user }} and the password is the private key for the user (I used the private key from Nelson's Desktop as the storage server was already configured to accept that key).

## Ntfy
The subscribed topics need to be added manually in the Ntfy clients (web or iOS app). The list of topics to subscribe to are:
- AlertManager
- Healthchecks
- Proxmox
- SnapRAID
- Uptime-Kuma
- media
- media-health
- qbit
- wud

## Proxmox
The proxmox hosts need to be bootstrapped to a point where they can be managed by ansible. See the [Proxmox Hosts Manual Configuration](services/proxmox/README.md) for more information.

## Tdarr
The docker container is configured to be deployed via Ansible. However, the Tdarr server needs to be configured manually after the container is running.
- Navigate to the [web interface](https://tdarr.home.stechsolutions.ca)
- Set up the libraries for the media files (mounted as /movies and /tv in the container).
- Set the Transcode cache for each library to be /temp (mounted as /temp in the container).
- Set up the Flow transcode plugin. Current flow logic is as follows:
    - If the video is AV1, or 480p, or 576p, or Other, then ensure the audio stream has 2 channel AAC, remove data streams, and reorder data streams.
    - Otherwise, do the same checks but also set 10 bit video, set MKV as the container format, set the FFMPEG settings to HEVC, medium preset, quality 27, hardware encoding, and force encoding.
    - Set the custom FFMpeg command to use 7 threads
    - Then run the FFMpeg command
    - Then compare the file size and file duration to the original file to make sure it didn't change too drastically.
    - Then replace the original file.
    - Then notify either Radarr or Sonarr that the file has been replaced.
- Set the Cache Threshold to 25GB
- Set the job history size limit to 3 GB

## Rclone (AWS Config)
Rclone is configured to use AWS S3 for storage. The following steps need to be done manually first to create the required user, access key, and secret key on AWS for Rclone to use.

1. Create an IAM policy on AWS with the following permissions. An example policy file is located at [roles/aws/files/rclone-user-policy.json.example](roles/aws/files/rclone-user-policy.json.example). The policy file needs to be modified to use the correct bucket name.
2. Create an IAM user on AWS and attach the policy created in step 1 to the user.
3. Create an access key and secret key for the user.
4. Add the access key and secret key to the `vault/vault.yaml` file under the `secret_rclone_user_access_key` and `secret_rclone_user_secret_key`

### Restore with Rclone
Restoring from AWS S3 Deep-Archive requires thawing the files first and then using Rclone to copy them back to the desired location. An example set of commands is as follows:

First figure out the encrypted path of the files or folders that you want to restore. This gives the encrypted path for a folder in the pictures remote. The path in quotations doesn't need to escape spaces, Rclone handles that automatically.
``` bash
> rclone cryptdecode --reverse pictures: "Folder Name"

"Folder Name"   emtv41nsarc0j44ompd7gpbjl25daacc954qek16gp07m7tj9igg/
```

Then issue the command to thaw the files from AWS S3. This will take up to 48 hours to complete. This command will initiate the thawing process for the *_raw remote. 

The `restore-days` option specifies the number of days to keep the restored files in S3.
The `restore-priority` option specifies the priority of the restore operation.
You can optionally run with `--dry-run` to see what would happen without actually performing the restore.

``` bash
> rclone backend restore "pictures_raw:[ENCRYPTED_PATH]" -o restore-days=3 -o restore-priority=Bulk
```
Then you need to wait for the thawing process to complete before using Rclone to copy the files back to their original location. In future versions of rclone, there is a built-in restore-status command instead: `rclone backend restore-status remote`. To check the status of the files operation, you can use the following command:

``` bash
> rclone lsjson "pictures_raw:[ENCRYPTED_PATH]"
```
Once the files are thawed, you can use Rclone to copy and decode the files.
```bash
> mkdir /tmp/glacier_restore
> rclone copy "pictures:[PATH]" /tmp/glacier_restore --progress
> ls /tmp/glacier_restore
```


## TailScale
Some Tailscale configuration is done manually via the Tailscale admin console. The Tailscale admin console is located at [Tailscale Admin Console](https://login.tailscale.com/admin).

### Access Control
A backup of the Tailscale Access Control file is stored in the [files/tailscale](files/tailscale) directory. The Access Control file is configured to allow access to the various hosts and services on the network with a default deny policy.

### Shared Exit Nodes
Any users that need to be added to the shared exit nodes need to be done manually. The shared exit nodes are shared via the Tailscale admin console. The users also need to be added to the Access Control file.

### DNS
The split DNS settings for `home.stechsolutions.ca` need to be added via the Tailscale admin console.

The IP addresses of remote or static tailscale nodes need to be manually added to the Cloudflare DNS settings for `tailscale.stechsolutions.ca`. This is done via the Cloudflare admin console.

### Tags and --advertise-tags
--advertise-tags can be set to specify which tags should be assigned to the node when it is joined to the tailnet. The tag is tied to the tailscale_authkey. The authkey must have the tags associated with it when it is created in the tailscale admin console.

The auth key is then stored in the ansible vault.

## Uptime-Kuma
Uptime-Kuma is installed as a docker container by Ansible. Currently, the configuration is not automated and needs to be done manually (until an API for uptime-kuma is available).

# Testing and linting
Linting can be done with the following commands

```bash
yamllint .
ansible-lint
ansible-playbook site.yaml --syntax-check
```
# General Services Documentation
## Raspberry Pi
The following services are configured on Raspberry Pi devices.

### Internet Monitoring
Internet monitoring is configured using a speedtest docker container configured to run periodically. Either wifi or ethernet depending on the configuration. When using RPi 3B devices, the max ethernet speed is limited to 100Mbps and the max 2.4 Ghz wifi speed is limited to 30Mbps.

To set up the device, run the [rpi/internet_monitoring](roles/rpi/tasks/internet_monitoring.yaml) playbook.

## NUT
NUT is installed and configured to monitor the UPS device of the PVE3 proxmox host. Once configured, here are some commands to monitor and test the UPS from the command line of the PVE3 host.

```bash
# Check the status of the UPS
upsc myups@localhost

# List all commands available for the UPS
upscmd -l myups@localhost

# Run a quick test of the UPS
upscmd -u admin -p REPLACE_PASSWORD myups@localhost test.battery.start.quick

# Run a long test of the UPS
upscmd -u admin -p REPLACE_PASSWORD myups@localhost test.battery.start.deep
```

You can alternatively visit [peanut.home.stechsolutions.ca](https://peanut.home.stechsolutions.ca) to view a web interface for the NUT devices.

## Prometheus

Prometheus has been added to monitor the infrastructure. Prometheus is set up via docker and is configured to scrape the various services running on the infrastructure. The Prometheus configuration is located at [files/prometheus/](files/prometheus/).

### Configuration

The main configuration file for Prometheus is located at [files/prometheus/prometheus.yaml](files/prometheus/prometheus.yaml). This file contains the scrape configurations and alerting rules.

### Alertmanager

Prometheus is configured to use Alertmanager for alerting. The Alertmanager configuration is located at [files/prometheus/alertmanager.yaml.j2](files/prometheus/alertmanager.yaml.j2). This file contains the configuration for the alert receivers.

## ZFS
ZFS is used for the fileserver and proxmox/pbs hosts. It can be configured to use encrypted datasets. The ZFS datasets are configured in the [setup_zfs_pool.yaml](roles/fileserver/tasks/setup_zfs_pool.yaml) and [setup_zfs_datasets.yaml](roles/fileserver/tasks/setup_zfs_datasets.yaml) files.

### Encryption and manual loading of keys
For the most part, encrypted datasets are configured to use a passphrase and they are automatically loaded when the system boots.

A scenario where you don't want the dataset to be automatically loaded could be a remote host where you don't want the passphrase to be stored on the host. In this case, set the following in the zfs dataset configuration:
```yaml
canmount: noauto
encryption: true
encryption_passphrase: "location in the vault"
encryption_keylocation: "none"
```

This will configure the dataset to not be automatically mounted and the encryption key will not be stored on the host. Then to manually load the key, you can run the following command (prompting for the passphrase):
```bash
sudo zfs load-key <dataset_name>
sudo zfs mount <dataset_name>
```
