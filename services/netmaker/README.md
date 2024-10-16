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
The configuration of the Netmaker server is in the [/services/netmaker/vars/](/services/netmaker/vars/) folder.

There are two different configurations that can be installed. The community version and the enterprise version. Which version is installed is controlled by the `netmaker_pro` boolean variable in the [vars/netmaker.yaml](vars/netmaker.yaml) file.

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

5. The [netclients.yaml](netclients.yaml) playbook configures all automatically connected netclients. To run the playbook, run the following command:

    ```bash
    ansible-playbook services/netmaker/netclients.yaml
    ```

6. The [netclients_manual.yaml](netclients_manual.yaml) playbook configures all manually connected netclients. To run the playbook, run the following command:

    ```bash
    ansible-playbook services/netmaker/netclients_manual.yaml
    ```

### Adding a new network
To add a new network, add the network to the [vars/netmaker.yaml](vars/netmaker.yaml) file. Then run the [netmaker_config.yaml](netmaker_config.yaml) playbook with the required tags. This will create the network and the enrollment key for the network.

Then add the network settings to the [netclients.yaml](inventory/netclients.yaml) inventory file (or any other inventory file or the [vars/networks.yaml](vars/networks.yaml) `netmaker_server_host_settings` section). 

Then run the [netclients.yaml](netclients.yaml) playbook with the requird tags. This will add the network to the netclients and configure it as required.


```bash
ansible-playbook services/netmaker/netmaker_config.yaml --tags="netmaker.network, netmaker.enrollment"

ansible-playbook services/netmaker/netclients.yaml --tags="netmaker.netclient"
```

## Manual Setup

### External Clients manual setup
There is some manual setup required for the external clients.

As of version 0.23.0, there can only be one DNS server specified in the [ext_clients.yaml](/services/netmaker/vars/ext_clients.yaml) configuration. This is a limiation of the NMCTL and the Netmaker server. After adding the configuration to the WireGuard app on a phone or laptop, simply edit the DNS settings and add the second DNS server (eg. 10.10.1.11 and 10.10.5.11)

If you want all network traffic to go through the external client, you can manually edit the WireGuard configuration file on the external client. Add `0.0.0.0/0` to the `AllowedIPs` section of the WireGuard configuration file.

For the `personal-home` external client, change the Endpoint address to the dynamic DNS address (eg. home.stechsolutions.ca).

### Internet Gateway
As of version 0.23.0, the internet gateway is not automatically set up. This needs to be done manually.

For example, login to the Netmaker dashboard, go to the `Networks` page, click on the `personal` network, click on the `Remote Access` tab, edit the `netmaker01` Gateway, and toggle the `Internet Gateway` switch in order to enable the internet gateway.

## Updating
To update the version of Netmaker follow the steps below.

1. Update the 'netmaker_version' variable in the [netmaker.yaml](vars/netmaker.yaml) configuration file in the netmaker services folder.
2. Check the GitHub releases page for the [Netmaker server](https://github.com/gravitl/netmaker/releases) and [Netclient](https://github.com/gravitl/netclient/releases) to see if there are any breaking changes. Make any required changes to the configuration files.
3. Run the following commands to update the Netmaker server and the Netclients on the hosts.

    ```bash
    ansible-playbook services/netmaker/netmaker.yaml --tags="netmaker"
    ansible-playbook services/netmaker/netmaker_config.yaml --tags="netmaker"
    ansible-playbook services/netmaker/netclients.yaml --tags="netmaker.netclient"
    ansible-playbook services/netmaker/netclients_manual.yaml --tags="netmaker.netclient"
    ```
4. Check the Netmaker dashboard to make sure everything is working as expected.

### Issues with Netclients when updating
When upgrading to v0.23.0, one of the netclients did not properly reconnect after the update.

```bash
arnie@vpn:~$ sudo netclient
Segmentation fault (core dumped)
```

In order to fix this, I had to clear out the /etc/netclient directory and then follow the steps listed above to manually install the netclient and join the network.

When rejoining the monitoring network, the VPN IP address changes so that had to be updated in the inventory file.

```bash
sudo rm -rf /etc/netclient/*
```




## Pro Usage
If the Pro version is installed, there is a [grafana dashboard](https://grafana.netmaker.stechsolutions.ca/) and a [prometheus instance](https://prometheus.netmaker.stechsolutions.ca/) that can be used to monitor the Netmaker server.

TODO: Modify the docker compose files to point to the external prometheus and grafana instances. Then remove the prometheus and grafana containers from the Netmaker server.

On first access, the Grafana user needs to be set up. The default login is `admin` and `admin` for the password. Then you need to set up a new password. Use the password stored in Bitwarden (the same as the Netmaker dashboard password).

The login for the grafana dashboard is `admin` and the password is stored in Bitwarden. The login for the prometheus instance is `Netmaker-Prometheus` and the password is the `secret_nm_license_key` (see the Ansbile vault).

You can see what the netmaker-exporter is sending by posting to the `prometheus\metrics` path using something like Postman. This uses basic auth with the username `Netmaker-Exporter` and the password is the `secret_nm_license_key` (see the Ansbile vault).

## Removal
To remove the Netmaker server completely set the following two varaiables in the [vars/netmaker.yaml](vars/netmaker.yaml) file to `absent`:

* netmaker_attached_volume.state = absent
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
