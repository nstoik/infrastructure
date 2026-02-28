# Media Services
This is the documentation for media services in my infrastructure.

## Hosts
- `docker-01.home.stechsolutions.ca`: This host runs docker containers for media services

## External Webpage and Access
The media services are accessible via the external webpage at [media.stechsolutions.ca](https://media.stechsolutions.ca). Access to the services is managed through Traefik reverse proxy with authentication. The username is 'user' and the password is 'NelsonPlex123!'.

## Services
- `downloader`: This service runs qBittorrent with VPN for downloading torrents securely. [qbittorrentvpn docker](https://github.com/nstoik/docker-qBittorrentvpn) is a forked version of an older image. This version focuses on using WireGuard for VPN connectivity.
- `qbit_manage`: This service manages qBittorrent downloads, including automatic rechecking, categorization, and notifications. It uses [qbit_manage](https://github.com/StuffAnThings/qbit_manage) with a user-defined configuration.
- `prowlarr`: This service is an indexer manager for torrent and usenet indexers. It integrates with download clients to automate the search and download process.
    - indexers that need to solve a captcha are configured to use flaresolverr for automatic solving.
- `profilarr`: This service manages profiles for media management applications like Radarr and Sonarr. It helps in organizing and maintaining consistent settings across multiple applications.
- `radarr`: This service manages movie downloads and organization. It integrates with download clients and indexers to automate the process of finding, downloading, and organizing movies.
- `sonarr`: This service manages TV show downloads and organization. It integrates with download clients and indexers to automate the process of finding, downloading, and organizing TV shows.
- `tautulli`: This service monitors Plex Media Server activity and provides detailed statistics and notifications about media consumption.
- `wrapperr`: This service sets up a Spotify Wrapped style dashboard for Plex Media Server using Tautulli data.
- `ombi`: This service provides a user-friendly interface for requesting media on Plex Media Server. It allows users to request movies and TV shows, which can then be approved and added to the server.
- `plex`: Plex Media Server hosting the media library (see Plex configuration below).
- `tdarr`: This service is a media transcoding and management tool that helps optimize media files for better performance and compatibility.

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
- Set the Plex server connection if required.
- Configure notifications using Ntfy. You need to get the ntfy Access Token from the ntfy web UI.
    - one general one for all notifications
    - one alert one for issues

### Wrapperr
Wrapperr is configured via its web interface.
- Best case scenario, copy the config files from an existing installation to preserve all settings.
- On first setup, set the Admin username and password (*Arr username and password stored in Bitwarden).
- Under Wrapperr Settings:
    - Set the Wrapper URL Base to `wrapperr`. This is to work with the external Traefik reverse proxy. (e.g., `https://media.stechsolutions.ca/wrapperr`)
    - Set the Timezone to America/Edmonton
    - Set the Start of Wrapped Period to January 1st of the current year.
    - Set the End of Wrapped Period to December 31st of the current year.
- Under Tautulli Setup:
    - Set the Tautulli server name, API key, domain, port, HTTPS setting.
- Under Wrapperr Setup:
    - Manually trigger the data fetch to populate the initial data.
- Under Users
    - Sync with Tautulli to import users.

### Ombi
Ombi is configured via its web interface.
- Best case scenario, copy an existing Ombi database from another installation to preserve all settings and requests.
- Log in is via Plex OAuth, so no separate username/password is required.
- Under Settings -> Configuration -> General
    - Ensure the base URL is set to `/ombi` to work with the external Traefik reverse proxy.
    - Set the API Key to the value stored in the Vault.
- Under Settings -> Configuration -> Customization
    - Set the Application URL to `https://media.stechsolutions.ca/ombi` to work with the external Traefik reverse proxy.
- Under Settings -> Configuration -> Issues
    - Enable issues
- Under Settings -> Configuration -> Users
    - Configure user roles and permissions as desired. Enable import from Plex and Plex Admin.
- Under Settings -> Configuration -> Authentication
    - Ensure Plex is set up as the authentication provider.
- Under Settings -> Media Servers
    - Ensure the Plex Media Server connection is set up.
    - Enable User Watchlist Requests
- Under Settings -> TV Shows
    - Configure Sonarr connection with API key.
- Under Settings -> Movies
    - Configure Radarr connection with API key.
- Under Settings -> Notifications -> Email
    - Configure email notifications as desired.
    - Currently using SMTP with Gmail SMTP server to personal email account.(TODO: Migrate to Mailgun or similar service)
- Under Settings -> Notifications -> Newsletter
    - Configure newsletter settings as desired.
- Keep using Discord for request notifications until Ombi supports Ntfy.

### Plex
- Docker: expose port `32400` (eg. `-p 32400:32400/tcp`).
- Router: forward TCP `32400` (or chosen external port) -> `<PLEX_HOST_IP>:32400`.
- Claim: set `PLEX_CLAIM` env var for first-boot server claim if needed.
- Plex UI: Settings → Server → Remote Access — enable manual port if not auto, enter external port, then retry until green.
- Integrations: configure Tautulli and Ombi to point to the Plex server and use API keys stored in the Vault.
- Enable GPU transcoding in Plex settings if using GPU passthrough in Docker.
- Set up media libraries and organize media files in the `/movies` and `/tv` directories as configured in Radarr and Sonarr.
- Set the LAN network in Plex settings so devices on the local network can connect without internet access.

### Tdarr
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

A second Tdarr node is configured with the same settings but is used as a worker node to offload the transcoding work from the main server. The second node is configured to connect to the main server and will automatically receive jobs when they are created. The second node uses a GPU for transcoding. It starts as paused so the node will only be used when manually unpaused for large transcoding tasks.