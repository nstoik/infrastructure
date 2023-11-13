# Netmaker
Ansible playbooks for setting up a [Netmaker](https://www.netmaker.io/) server on a DigitalOcean droplet.

Sets up and configures hosts to have the netclient program installed and connected to the required networks.

## Inventory
Hosts to have the netclient program are listed in the [netclients.yaml](inventory/netclients.yaml) inventory file along with the accompanying [group_vars/netclients.yaml](inventory/group_vars/netclients.yaml) file.

There is also a [netclients_manual.yaml](inventory/netclients_manual.yaml) inventory file. These hosts need to have the netclient setup manually so that they can be reached by Ansible over a Netmaker network. The accompanying [group_vars/netclients_manual.yaml](inventory/group_vars/netclients_manual.yaml) file specifies the ssh options so that Ansible can connect to the hosts using a jump host.

The host needs to be able to be ssh'd into using the `ansible_user`.The keys of the ansible runner need to be added to the `known_hosts` file of the host. From the ansible runner host, run the following command:
```bash
ssh-copy-id -o ProxyJump=jumphost user@remote_host
```

To manually install the netclient on a host, log into the Netmaker dashboard, go to the Hosts page and click the `Connect a Host` button. Follow the instructions to install the netclient on the host.

Then to join the new host to a network run the following command on the host. The `<token>` is from the Netmaker Dashboard and the `<host name>` is set in the [netclients_manual.yaml](inventory/netclients_manual.yaml) inventory file.
```bash
```bash
sudo netclient join --token <token> --name <host name>
```

## Configuration
The configuration of the Netmaker server is in the [vars/netmaker.yaml](vars/netmaker.yaml) file.

There are two different configurations that can be installed. The community version and the enterprise version. Which vervion is installed is controlled by the `netmaker_pro` boolean variable in the [vars/netmaker.yaml](vars/netmaker.yaml) file.

The setup runs through the steps as outlined in the [Netmaker documentation](https://netmaker.readthedocs.io/en/master/quick-start.html) but makes the following changes.

 * The configuration files (including the docker compose file) are stored in the `~/netmaker` directory on the host.

## Usage
1. The [netmaker.yaml](netmaker.yaml) playbook sets up a digitalocean droplet with all the prequesite software and then installs the Netmaker server. To run the playbook, run the following command:

    ```bash
    ansible-playbook services/netmaker/netmaker.yaml
    ```

    This also configures the Cloudflare DNS entries and the firewall reules on DigitalOcean.

2. The [netmaker_config.yaml](netmaker_config.yaml) playbook configures the Netmaker server. To run the playbook, run the following command:

    ```bash
    ansible-playbook services/netmaker/netmaker_config.yaml
    ```

    The following items are configured:
    * Creates an admin user for the Netmaker server
    * Sets up and configures the nmctl cli (see the [nmctl.yaml](tasks/nmctl.yaml) playbook) on the local machine and on the Netmaker server
    * Creates the following networks:
        * monitoring - for monitoring devices and nodes using prometheus and grafana
        * personal - for my personal devices. To connect back to my home network, or to route traffic through my home network.
        * farm network - for network connectivity to devices for the farm monitoring system
    * Creates enrollment keys for the networks
    * Installs and configures Netclient on the Netmaker server
    * Configures ingress gateway for all networks and creates the external clients

3. After the playbook has run, the Netmaker server is ready to use. From a web browser, go to the [netmaker dashboard](https://dashboard.netmaker.stechsolutions.ca)
    * Login credentials are stored in Bitwarden.

4. Manually install and connect the netclient on the hosts that need to be connected to the Netmaker server. The list of hosts is in the [netclients_manual.yaml](inventory/netclients_manual.yaml) inventory file.

5. The [netclients.yaml](netclients.yaml) playbook configures all the netclients. To run the playbook, run the following command:

    ```bash
    ansible-playbook services/netmaker/netclients.yaml
    ```


## Pro Usage
If the Pro version is installed, there is a [grafana dashboard](https://grafana.netmaker.stechsolutions.ca/) and a [prometheus instance](https://prometheus.netmaker.stechsolutions.ca/) that can be used to monitor the Netmaker server.

TODO: Modify the docker compose files to point to the external prometheus and grafana instances. Then remove the prometheus and grafana containers from the Netmaker server.

On first access, the Grafana user needs to be set up. The default login is `admin` and `admin` for the password. Then you need to set up a new password. Use the password stored in Bitwarden (the same as the Netmaker dashboard password).

The login for the grafana dashboard is `admin` and the password is stored in Bitwarden. The login for the prometheus instance is `Netmaker-Prometheus` and the password is the `secret_nm_license_key` (see the Ansbile vault).

You can see what the netmaker-exporter is sending by posting to the `prometheus\metrics` path using something like Postman. This uses basic auth with the username `Netmaker-Exporter` and the password is the `secret_nm_license_key` (see the Ansbile vault).

## Removal
To remove the Netmaker server completely set the following two varaiables in the [vars/netmaker.yaml](vars/netmaker.yaml) file to `absent`:

* netmaker_volume.state = absent
* netmaker_droplet.state = absent

Then run the [netmaker.yaml](netmaker.yaml) playbook again.

That will remove the droplet and the volume from DigitalOcean. It will remove the Cloudflare DNS entries. It will update the local known_hosts_ansible file to remove the entry for the Netmaker server.

The following things are not removed automatically
* DigitalOcean firewall rules
* nmctl installations on localhosts
* any netclient installations

## NMCTL
The [nmctl.yaml](tasks/nmctl.yaml) playbook installs the [nmctl command line tool](https://netmaker.readthedocs.io/en/master/nmctl.html). This tool can be used to interact with the Netmaker server from the command line.

The installation playbook will also configure the auto-completion for the nmctl command line tool.

The nmctl context file is stored in the `~/.nmctl` directory on the machine it is installed in.
