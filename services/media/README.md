# Media Services
This is the documentation for media services in my infrastructure.

## Hosts
- `docker-01.home.stechsolutions.ca`: This host runs docker containers for media services

## Services
- `downloader`: This service runs qBittorrent with VPN for downloading torrents securely. [qbittorrentvpn docker](https://github.com/nstoik/docker-qBittorrentvpn) is a forked version of an older image. This version focuses on using WireGuard for VPN connectivity.
- `qbit_manage`: This service manages qBittorrent downloads, including automatic rechecking, categorization, and notifications. It uses [qbit_manage](https://github.com/StuffAnThings/qbit_manage) with a user-defined configuration.
- `prowlarr`: This service is an indexer manager for torrent and usenet indexers. It integrates with download clients to automate the search and download process.
    - indexers that need to solve a captcha are configured to use flaresolverr for automatic solving.
- `profilarr`: This service manages profiles for media management applications like Radarr and Sonarr. It helps in organizing and maintaining consistent settings across multiple applications.
- `radarr`: This service manages movie downloads and organization. It integrates with download clients and indexers to automate the process of finding, downloading, and organizing movies.
- `sonarr`: This service manages TV show downloads and organization. It integrates with download clients and indexers to automate the process of finding, downloading, and organizing TV shows.
- `tautulli`: This service monitors Plex Media Server activity and provides detailed statistics and notifications about media consumption.

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
- Retention policies for completed downloads (including specific settings for private trackers)

### Radarr
Radarr is configured via its web interface.
- Access the web UI and set the initial username and password (stored in Bitwarden).
    - You will need to change the `<AuthenticationMethod>Forms</AuthenticationMethod>` to `External` in the `config.xml` file in order to login to the web UI.
    - Change the password and set it back to `Forms` authentication method.
- Change Certification Country to "Canada" in Settings -> Metadata.
- Add Download Client (qBittorrent VPN).
    - Set Post-Import Category to "radarr-finished"
    - Uncheck "Remove Completed"
- Add notifications using Ntfy.
    - one general one for all grabs
    - one alert one for issues
- Add root movie folder `/movies`.

### Sonarr
Sonarr is configured via its web interface.
- Access the web UI and set the initial username and password (stored in Bitwarden).
    - You will need to change the `<AuthenticationMethod>Forms</AuthenticationMethod>` to `External` in the `config.xml` file in order to login to the web UI.
    - Change the password and set it back to `Forms` authentication method.
- Add Download Client (qBittorrent VPN).
    - Set Post-Import Category to "sonarr-finished"
    - Uncheck "Remove Completed"
- Add notifications using Ntfy.
    - one general one for all grabs
    - one alert one for issues
- Add root TV show folder `/tv`.

### Prowlarr
Prowlarr is configured via its web interface.
- Access the web UI and set the initial username and password (stored in Bitwarden).
- Add the FlareSolverr connection in Prowlarr settings for automatic captcha solving (http://localhost:8191/ since the service is running in the same Docker network).
- Add the Sync Profiles for private trackers.
- Add Download Clients (qBittorrent VPN).
- Add notifications using Apprise.
    - one general one for all grabs
    - one alert one for issues
- Add indexers
- Add Applications
    - Radarr
    - Sonarr

### Profilarr
Profilarr is configured via its web interface.
- Access the web UI and set the initial username and password (stored in Bitwarden).
- Add the database (Dictionary/Database)
- Connect Radarr to Profilarr via the API key.
- Connect Sonarr to Profilarr via the API key.
- Confirm Media Management settings are correct (naming, folders, etc).
- Select the desired profiles to manage.
    - Starting with default 1080p Efficient as a start.

### Tautulli
Tautulli is configured via its web interface.
- Best case scenario, copy an existing Tautulli database from another installation to preserve all settings and history.
- The API key is stored in the Vault and is used in the homepage widget configuration.
- Set the Plex server connection if required
- Configure notifications using Apprise. You need to get the ntfy Access Token from the ntfy web UI.
    - one general one for all notifications
    - one alert one for issues
