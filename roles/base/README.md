# Base Role

Sets up the base configuration for all managed hosts: packages, users, dotfiles, timezone, journald, and Prometheus node_exporter with optional ZFS metrics.

## Role Variables

### Package Management

| Variable | Default | Description |
|---|---|---|
| `base_apt_upgrade_packages` | `"yes"` | apt upgrade level: `dist`, `full`, `no`, `safe`, `yes` |
| `base_apt_update_packages` | `true` | Run apt update before installing packages |
| `base_packages` | `[git, jq, neofetch, ...]` | Additional packages to install |

### User Configuration

| Variable | Default | Description |
|---|---|---|
| `base_user_run_setup` | `true` | Whether to run user setup tasks |
| `base_users` | see below | List of users to create on the host |

Each entry in `base_users` supports:

| Key | Required | Default | Description |
|---|---|---|---|
| `name` | yes | — | Username |
| `password_prehashed` | yes | — | SHA-512 hashed password (`openssl passwd -6`) |
| `shell` | no | `/usr/bin/zsh` | Login shell |
| `groups` | no | `[sudo]` | List of groups to add the user to |
| `add_ssh_keys` | no | `false` | Add keys from `secret_ssh_keys[name]` in the vault |

The default `base_users` list creates a single user from `default_user` and `secret_user_password_prehashed`. Override in inventory to change the default user's settings or add additional users:

```yaml
base_users:
  - name: "{{ default_user }}"
    password_prehashed: "{{ secret_user_password_prehashed }}"
    shell: /bin/bash
    groups: [sudo]
    add_ssh_keys: true
  - name: nelson
    password_prehashed: "{{ secret_nelson_password_prehashed }}"
    shell: /usr/bin/zsh
    groups: [sudo]
    add_ssh_keys: true
```

SSH keys are stored in the vault under `secret_ssh_keys` as a dict keyed by username:

```yaml
secret_ssh_keys:
  nelson:
    - name: "Laptop"
      key: "ssh-ed25519 ..."
  welca:
    - name: "Nelson Welca"
      key: "ssh-ed25519 ..."
```

### Dotfiles

| Variable | Default | Description |
|---|---|---|
| `base_dotfiles.install` | `false` | Install dotfiles via dotbot |
| `base_dotfiles_repo` | `https://github.com/nstoik/dotfiles` | Dotfiles git repo |

### Prometheus node_exporter

The base role deploys and configures `prometheus-node-exporter`. On ZFS hosts, it also deploys a textfile collector script (`zpool_metrics.sh`) that runs every minute via a systemd timer and writes pool metrics to a `.prom` file.

| Variable | Default | Description |
|---|---|---|
| `base_node_exporter_zfs_collector` | `false` | Enable node_exporter's built-in ZFS collector |
| `base_node_exporter_textfile_dir` | `/var/lib/prometheus/node-exporter` | Directory for textfile collector `.prom` files |
| `base_node_exporter_mount_points_exclude` | see defaults | Regex of mountpoints to exclude from filesystem metrics. Default removes `/mnt` exclusion (to expose ZFS datasets) and adds `/export` (to avoid NFS re-export duplicates) |

#### ZFS Pool Metrics (textfile collector)

`zpool_metrics.sh` is deployed to all hosts where `base_node_exporter_zfs_collector: true`. It writes the following metrics to `zpool.prom`:

| Metric | Description |
|---|---|
| `zpool_size_bytes` | Total pool size |
| `zpool_allocated_bytes` | Allocated space |
| `zpool_free_bytes` | Free space |
| `zpool_capacity_percent` | Capacity usage percentage |
| `zpool_fragmentation_percent` | Pool fragmentation |
| `zpool_health{state}` | Pool health (0=online, 1=degraded, 2=faulted, 3=offline, 4=unavail, 5=removed) |
| `zpool_scrub_age_seconds` | Seconds since last completed scrub (-1 if never scrubbed) |
| `zpool_scrub_errors` | Errors found in last scrub |
| `zpool_read_errors` | Aggregate vdev read errors |
| `zpool_write_errors` | Aggregate vdev write errors |
| `zpool_checksum_errors` | Aggregate vdev checksum errors |

These metrics are consumed by the Prometheus alert rules in `files/prometheus/rules/storage_alerts.yaml`. ZFS snapshot metrics are handled separately by the `fileserver` role (`zfs_snapshot_metrics.sh`).

### Other Variables

| Variable | Default | Description |
|---|---|---|
| `base_timezone` | `America/Edmonton` | System timezone |
| `base_reboot_host_if_required` | `true` | Reboot after kernel/package updates if required |
| `base_docker_install` | `false` | Install Docker repository (full setup in docker role) |
| `base_journald` | see defaults | journald storage limits |
