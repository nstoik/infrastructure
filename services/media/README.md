# Media Services
This is the documentation for media services in my infrastructure.

## Hosts
- `docker-01.home.stechsolutions.ca`: This host runs docker containers for media services

## Services
- `downloader`: This service runs qBittorrent with VPN for downloading torrents securely. [qbittorrentvpn docker](https://github.com/nstoik/docker-qBittorrentvpn) is a forked version of an older image. This version focuses on using WireGuard for VPN connectivity.
- `qbit_manage`: This service manages qBittorrent downloads, including automatic rechecking, categorization, and notifications. It uses [qbit_manage](https://github.com/StuffAnThings/qbit_manage) with a user-defined configuration.
- `prowlarr`: This service is an indexer manager for torrent and usenet indexers. It integrates with download clients to automate the search and download process
    - indexers that need to solve a captcha are configured to use flaresolverr for automatic solving.

## Configuration
Configuration for these services can be found in the respective `docker_compose` YAML files located in the host variable directories, such as:
- `inventory/host_vars/docker-01.home.stechsolutions.ca/docker_compose/downloader.yaml.j2`

### QBittorrent with VPN
On first setup, you need to get the auto generated password from the log file, and then change the webui password to the desired password (stored in Bitwarden).

### Qbit Manage
The configuration for qbit_manage is templated using Jinja2 and can be found [here](../../files/qbittorrentvpn/qbit_manage_config.yml.j2). Key configurations include:
- Commands to run (recheck, category update, tag update)
- Category definitions for organizing downloads
- Tracker tags for all in use trackers
- Notification settings using Apprise
- Retention policies for completed downloads (inlcluding specific settings for private trackers)

### Prowlarr
Prowlarr is configured via its web interface.
- Get the API key and add it in the secrets vault in Ansible.
- Add the FlareSolverr connection in Prowlarr settings for automatic captcha solving (http://localhost:8191/ since the service is running in the same Docker network).
- Add the Sync Profiles for private trackers.
- Add Download Clients (qBittorrent VPN).
- Add notifications using Apprise.
    - one general one for all grabs
    - one alert one for issues
- Add indexers


