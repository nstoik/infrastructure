# Manual Configuration

While the purpose of this repository is to automate the configuration of the infrastructure, there are some steps that require manual configuration.

## 3D Printer

The 3D printer is not managed by Ansible. The configuration is done manually. The 3D printer is a Creality Ender 3 S1 Pro with a Raspberry Pi 3 B+ running MainsailOS.

The [3D Printer Repo](https://github.com/nstoik/3D-printer) stores the configuration backups of the 3D printer powered by Klipper-Backup.

- The `main` branch of the repo is the Klipper configuration.
- The `orcaslicer-config-folder` branch of the repo is the Orcaslicer configuration folder backed up to GitHub.

## FileStash

Once the FileStash docker container is running, the configuration needs to be done manually.

1. Navigate to the [web interface](https://filestash.home.stechsolutions.ca) and set the admin password that is saved in Bitwarden.
2. Navigate to the [Admin Console](https://filestash.home.stechsolutions.ca/admin/backend).
3. Add two `SFTP` backends and configure them to connect to:
   - `storage.home.stechsolutions.ca/mnt/storage`
   - `storage.home.stechsolutions.ca/mnt/zfs`
4. Use the default user as the username and the private key for the user as the password (typically the key from a desktop system that already has access configured).

## Open WebUI

Open WebUI provides a web interface for Ollama (local LLM backend at `10.10.1.100:11434`).

### Before first deploy — vault secrets

Two secrets are required before deploying:

```yaml
# In inventories/home/group_vars/all/vault.yaml
secret_openwebui_secret_key: <random string>     # signs all JWTs; generate with: openssl rand -hex 32
secret_openwebui_homepage_key: <leave blank>     # filled in after first deploy (see below)
```

Encrypt after editing:
```bash
ansible-vault encrypt inventories/home/group_vars/all/vault.yaml \
  --vault-id home@./vault_pass.txt --encrypt-vault-id home
```

### After first deploy — generate homepage API key

The first account created through the UI becomes admin. API keys are enabled by default.

1. Navigate to [Open WebUI](https://openwebui.home.stechsolutions.ca) and create your admin account.
2. Go to **Settings → Account → API Keys** and generate a new key.
3. Add the key to the vault as `secret_openwebui_homepage_key`.
4. Redeploy homepage to apply the key to the widget:
   ```bash
   ansible-playbook playbooks/hosts_configure.yaml --limit=docker-02 --tags=docker.compose
   ```

## Ntfy

The subscribed topics need to be added manually in the Ntfy clients (web or iOS app). The list of topics to subscribe to:

- AlertManager
- Healthchecks
- Proxmox
- scrutiny
- Uptime-Kuma
- media
- media-health
- qbit
- wud

## Proxmox

The proxmox hosts need to be bootstrapped to a point where they can be managed by Ansible. See the [Proxmox Service Documentation](./services/proxmox.md) for more information on initial setup.

## Rclone (AWS S3 Configuration)

Rclone is configured to use AWS S3 for storage. The following steps need to be done manually first to create the required user, access key, and secret key on AWS for Rclone to use.

### Setting up AWS IAM User and Policy

1. Create an IAM policy on AWS with the following permissions. An example policy file is located at [roles/aws/files/rclone-user-policy.json.example](../roles/aws/files/rclone-user-policy.json.example).
   - Modify the policy file to use the correct bucket name.
2. Create an IAM user on AWS.
3. Attach the policy created in step 1 to the user.
4. Create an access key and secret key for the user.

### Storing AWS Credentials in Vault

Add the access key and secret key to the relevant vault file:

```yaml
# In inventories/home/group_vars/all/vault.yaml or inventories/<inventory>/group_vars/all/vault.yaml
secret_rclone_user_aws_access_key: <your_access_key>
secret_rclone_user_aws_secret_key: <your_secret_key>
```

Encrypt the vault:
```bash
ansible-vault encrypt inventories/home/group_vars/all/vault.yaml \
  --vault-id home@./vault_pass.txt --encrypt-vault-id home
```

### Restoring from AWS S3 Deep-Archive

Restoring from AWS S3 Deep-Archive requires thawing the files first and then using Rclone to copy them back to the desired location.

#### Step 1: Find the encrypted path
```bash
rclone cryptdecode --reverse pictures: "Folder Name"

# Output example:
# "Folder Name"   emtv41nsarc0j44ompd7gpbjl25daacc954qek16gp07m7tj9igg/
```

#### Step 2: Initiate thaw from Deep-Archive
This will take up to 48 hours to complete. The `restore-days` option specifies the number of days to keep the restored files in S3.
The `restore-priority` option specifies the priority of the restore (Standard, Expedited, or Bulk).

```bash
rclone backend restore "pictures_raw:[ENCRYPTED_PATH]" -o restore-days=3 -o restore-priority=Bulk
```

Optionally run with `--dry-run` to see what would happen without actually performing the restore.

#### Step 3: Wait for thaw to complete
Check the status of the restoration:
```bash
rclone lsjson "pictures_raw:[ENCRYPTED_PATH]"
```

#### Step 4: Copy files after thaw completes
Once files are thawed:

```bash
mkdir /tmp/glacier_restore
rclone copy "pictures:[PATH]" /tmp/glacier_restore --progress
ls /tmp/glacier_restore
```

## Tailscale

Some Tailscale configuration is done manually via the Tailscale admin console at [Tailscale Admin Console](https://login.tailscale.com/admin).

### Access Control

A backup of the Tailscale Access Control file is stored in [files/tailscale/](../files/tailscale/). This file is configured to allow access to various hosts and services on the network with a default deny policy.

To update access controls:
1. Log in to the Tailscale admin console
2. Navigate to Access Control
3. Update the policy (backed up locally in the repo)
4. Deploy the changes

### Shared Exit Nodes

Any users that need to be added to the shared exit nodes must be added manually through the Tailscale admin console. Users also need to be added to the Access Control policy file.

### DNS Configuration

The split DNS settings for `home.stechsolutions.ca` need to be added via the Tailscale admin console under DNS settings.

The IP addresses of remote or static Tailscale nodes need to be manually added to the Cloudflare DNS settings for `tailscale.stechsolutions.ca`. This is done via the [Cloudflare Admin Console](https://dash.cloudflare.com/).

### Tags and --advertise-tags

Tags define which nodes have access to certain resources. When a node joins the Tailnet:

1. Create authkeys in the Tailscale admin console with specific tags
2. Store the authkey in the Ansible vault:
   ```yaml
   secret_ts_authkey: <authkey>
   ```
3. Nodes will automatically advertise the tags associated with the authkey

Example tags in use:
- `tag:proxmox` - Proxmox hypervisors
- `tag:docker` - Docker hosts
- `tag:storage` - Storage servers

## Uptime-Kuma

Uptime-Kuma is installed as a docker container by Ansible. Currently, the configuration is not automated and needs to be done manually (until an API is available).

To configure:
1. Access the Uptime-Kuma web interface (address from your dashboard)
2. Add monitors for each service/endpoint you want to track
3. Configure notification channels (Ntfy, Apprise, webhooks, etc.)
4. Set up dashboard groups and status pages

## NUT (Network UPS Tools)

NUT is installed and configured to monitor UPS devices. Once configured, you can use these commands from the command line of the NUT master host:

### Check UPS Status
```bash
upsc myups@localhost
```

### List Available Commands
```bash
upscmd -l myups@localhost
```

### Run Battery Tests
```bash
# Quick test
upscmd -u admin -p REPLACE_PASSWORD myups@localhost test.battery.start.quick

# Long test
upscmd -u admin -p REPLACE_PASSWORD myups@localhost test.battery.start.deep
```

### Web Interface
Access the NUT web interface (Peanut) at [peanut.home.stechsolutions.ca](https://peanut.home.stechsolutions.ca).

## Prometheus & Grafana

Prometheus and Grafana are configured via Ansible. However, some additional manual steps may be needed:

### Grafana Datasources
Check that Prometheus is configured as a datasource (should be auto-provisioned from [files/grafana/provisioning/](../files/grafana/provisioning/)).

### Grafana Dashboards
Dashboards in `files/grafana/provisioning/dashboards_json/` are **auto-provisioned** on deploy — no manual import needed. Current dashboards include:

- `node_exporter.json` — full host metrics (CPU, memory, disk, network)
- `cadvisor_docker.json` — Docker container metrics
- `pve.json` — Proxmox VE host metrics
- `traefik.json` — Traefik reverse proxy metrics
- `nut_exporter.json` — UPS/NUT metrics
- `pihole.json` — Pi-hole DNS metrics
- `tailscale-overview.json` — Tailscale network overview
- `tailscale-machine.json` — Per-machine Tailscale metrics
- `file_storage.json` — ZFS dataset capacity, usage, and I/O
- `zfs.json` — ZFS ARC stats and pool performance
- `zfs_health.json` — ZFS pool health status

To add a new dashboard: export JSON from Grafana, save it to `files/grafana/provisioning/dashboards_json/prometheus/`, and redeploy with `--tags docker.compose`.

### Alerting
- Prometheus scrape configs are in [files/prometheus/prometheus.yaml](../files/prometheus/prometheus.yaml)
- Alert rules are in [files/prometheus/rules/](../files/prometheus/rules/):
  - `alerts.yaml` — Prometheus self-monitoring
  - `node_alerts.yaml` — host hardware/OS alerts
  - `storage_alerts.yaml` — filesystem, ZFS pool, scrub, and snapshot alerts
  - `ups_alerts.yaml` — UPS/NUT alerts
  - `tailscale_alerts.yaml` — Tailscale network alerts
  - `traefik_alerts.yaml` — Traefik HTTP error rate alerts
- Alertmanager config is in [files/alertmanager/alertmanager.yaml.j2](../files/alertmanager/alertmanager.yaml.j2)

## ZFS Encryption and Automatic Key Loading

Documentation for ZFS encryption and automatic key loading configuration. See [INVENTORIES.md](./INVENTORIES.md) for details on ZFS dataset configuration.

For encrypted datasets that should NOT be automatically mounted (e.g., on remote hosts where you don't want the passphrase stored):

1. Configure in inventory with `canmount: noauto` and `encryption_keylocation: none`
2. To manually load the key on the host:
   ```bash
   sudo zfs load-key <dataset_name>  # Prompts for passphrase
   sudo zfs mount <dataset_name>
   ```

## See Also

- [SETUP.md](./SETUP.md) - Initial environment and dependency setup
- [USAGE.md](./USAGE.md) - Running playbooks and available commands
- [INVENTORIES.md](./INVENTORIES.md) - Inventory structure and variables
- [docs/services/](./services/) - Service-specific documentation
  - [Cloud Hosts](./services/cloud_hosts.md)
  - [Proxmox](./services/proxmox.md)
  - [Media Stack](./services/media.md)
