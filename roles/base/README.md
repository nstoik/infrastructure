# Base Role

Sets up the base configuration for all managed hosts: packages, users, dotfiles, timezone, journald, and Prometheus node_exporter with optional ZFS metrics.

## Role Variables

### Package Management

| Variable | Default | Description |
|---|---|---|
| `base_apt_upgrade_packages` | `"yes"` | apt upgrade level: `dist`, `full`, `no`, `safe`, `yes` |
| `base_apt_update_packages` | `true` | Run apt update before installing packages |
| `base_packages` | `[git, jq, neofetch, ...]` | Additional packages to install |

### GitHub Binary Installs

Binaries not available in apt can be installed from GitHub releases via the `base_github_binaries` list. Each entry is downloaded, extracted, and installed idempotently. A URL marker file at `/usr/local/share/<name>.url` tracks the installed version — the binary is reinstalled automatically when the URL changes. Deleting the marker file forces a reinstall without changing the URL.

| Variable | Default | Description |
|---|---|---|
| `base_github_binaries` | see `defaults/main.yaml` | List of GitHub-released binaries to install (defaults include gping and trippy) |

Each entry in `base_github_binaries` supports:

| Key | Required | Description |
|---|---|---|
| `name` | yes | Binary name, used for the URL marker file at `/usr/local/share/<name>.url` |
| `url` | yes | Download URL for the release archive (may reference `ansible_facts['architecture']`, `base_gping_arch`, or `base_trippy_arch`) |
| `dest` | yes | Final installed binary path (e.g. `/usr/local/bin/gping`) |
| `archive_binary` | yes | Path to the binary inside the extracted archive |
| `capabilities` | no | Linux capability string to set on the binary (e.g. `cap_net_raw+ep`) |

Example — adding a new binary:

```yaml
base_github_binaries:
  - name: myapp
    url: "https://github.com/org/myapp/releases/download/v1.0.0/myapp-{{ ansible_facts['architecture'] }}-linux.tar.gz"
    dest: /usr/local/bin/myapp
    archive_binary: myapp
```

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

Dotfiles are configured per-user via `base_users[].dotfiles`:

| Key | Required | Default | Description |
|---|---|---|---|
| `dotfiles.install` | no | `false` | Install dotfiles via dotbot for this user |
| `dotfiles.profile` | no | `server` | Dotbot profile to run |
| `dotfiles.repo` | no | `base_dotfiles_repo` | Git repo to clone |
| `dotfiles.dir` | no | `/home/<user>/dotfiles` | Local clone path |

| Variable | Default | Description |
|---|---|---|
| `base_dotfiles_repo` | `https://github.com/nstoik/dotfiles` | Default dotfiles repo (fallback when `dotfiles.repo` is not set per-user) |

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
