# Media Services
This is the documentation for media services in my infrastructure.

## Hosts
- `docker-01.home.stechsolutions.ca`: This host runs docker containers for media services

## Services
- `downloader`: This service runs qBittorrent with VPN for downloading torrents securely. qbittorrentvpn is a forked version of an older image. This version focuses on using WireGuard for VPN connectivity.

## Configuration
Configuration for these services can be found in the respective `docker_compose` YAML files located in the host variable directories, such as:
- `inventory/host_vars/docker-01.home.stechsolutions.ca/docker_compose/downloader.yaml.j2`

### QBittorrent with VPN
On first setup, you need to get the auto generated password from the log file, and then change the webui password to the desired password (stored in Bitwarden).

