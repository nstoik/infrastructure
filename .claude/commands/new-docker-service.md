Add a new Docker Compose service to the homelab infrastructure.

## Step 1: Gather information

Ask the user for:
- **Service name** (e.g., `it-tools`)
- **Docker image** (e.g., `corentinth/it-tools`)
- **Container port** (the port the container listens on internally)
- **Which docker host**:
  - `docker-01` (media/downloads) — `inventories/home/host_vars/docker-01.home.stechsolutions.ca/`
  - `docker-02` (tools/monitoring/misc) — `inventories/home/host_vars/docker-02.home.stechsolutions.ca/`
  - `docker-cloud-01` (cloud/external-facing services) — `inventories/home/host_vars/docker-cloud-01/`
- **Homepage group** (must match an existing group in `files/homepage/settings.yaml`, or create a new one)

Look up the latest pinned image tag from Docker Hub:
```bash
curl -s "https://hub.docker.com/v2/repositories/<org>/<image>/tags?page_size=10&ordering=last_updated" | python3 -c "import sys,json; [print(t['name']) for t in json.load(sys.stdin)['results']]"
```
Choose the most recent stable versioned tag (not `latest`, not `nightly`).

---

## Step 2: Create the Docker Compose template

**File:** `inventories/home/host_vars/<docker-host>.home.stechsolutions.ca/docker_compose/<service>.yaml.j2`

Use this structure as the template — copy the pattern from an existing simple service like `files.yaml.j2` (no volumes) or `vehicle.yaml.j2` (with volumes/DB):

```yaml
---
name: <service>

services:
  <container-name>:
    image: <org>/<image>:<pinned-tag>
    container_name: <container-name>
    networks:
      - traefik
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.<service>.rule=Host(`<service>.home.stechsolutions.ca`)"
      - "traefik.docker.network=traefik"
      - "traefik.http.services.<service>.loadbalancer.server.port=<container-port>"
      - "traefik.http.routers.<service>.entrypoints=websecure"
      - "traefik.http.routers.<service>.tls.certresolver=letsencrypt"
      - "homepage.group=<Homepage Group>"
      - "homepage.name=<Display Name>"
      - "homepage.description=<Short Description>"
      - "homepage.icon=<service>.png"
      - "homepage.href=https://<service>.home.stechsolutions.ca"
      - "homepage.siteMonitor=https://<service>.home.stechsolutions.ca"
      - "wud.tag.include=<tag-regex>"
      - "wud.link.template=https://hub.docker.com/r/<org>/<image>/tags"

networks:
  traefik:
    name: traefik
    external: true
```

**WUD tag regex patterns:**
- Semver (`v1.2.3` or `1.2.3`): `^v?\\d+\\.\\d+\\.\\d+$`
- Date-based (`2024.10.22-abc1234`): `^\\d{4}\\.\\d+\\.\\d+`
- Latest-only (no versioned tags): omit `wud.tag.include`, use `wud.watch.digest=true` instead

If the service needs persistent storage, add `volumes:` and a mount under `docker_mounts_subfolders` in `docker.yaml`.

---

## Step 3: Register the compose file

**File:** `inventories/home/host_vars/<docker-host>.home.stechsolutions.ca/docker.yaml`

Add to the `docker_compose_files` list:

```yaml
  - name: <service>-docker-compose.yaml
    compose_name: <service>
    state: present
    src: "{{ docker_compose_subpath }}/<service>.yaml.j2"
    dest: /home/{{ default_user }}/docker_compose/<service>-docker-compose.yaml
    mode: '0664'
```

If the service needs persistent storage, also add to `docker_mounts_subfolders`:

```yaml
  - name: <service>_data
    dest: /home/{{ default_user }}/docker_mounts/<service>/data
    mode: '0775'
    container_name: <container-name>
```

---

## Step 4: Add PiHole DNS entry

**File:** `inventories/home/group_vars/pihole.yaml`

Add an entry to `pihole_dns_entries` in alphabetical order by domain:

```yaml
  - domain: "<service>.home.stechsolutions.ca"
    target: "<docker-host>.home.stechsolutions.ca"
    add_hostname: true
```

---

## Step 5: Add homepage group to layout (if new group)

**File:** `files/homepage/settings.yaml`

If the `homepage.group` label used in Step 2 doesn't already exist in `settings.yaml`, add it under the appropriate tab:

```yaml
  <Homepage Group>:
    tab: Tools        # or Media, Monitoring, Infrastructure
    style: column
```

Existing tabs: `Tools`, `Media`, `Monitoring`, `Infrastructure`.

---

## Step 6: Validate

```bash
ansible-lint
```

Fix any issues before committing.

---

## Step 7: Commit and push

Stage and commit the changes. Split into multiple commits if it makes sense (e.g., separate commits for the compose file, DNS entry, and homepage layout). Reference the GitHub issue number if one exists.

Suggested deploy command once merged:
```bash
ansible-playbook playbooks/docker_compose.yaml --limit=<docker-host> --tags=docker.compose
```
